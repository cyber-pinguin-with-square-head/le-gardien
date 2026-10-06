--!strict
-- Point d'entrée client : menu, puis écran caméra quand le serveur lance la partie.
-- Le client n'envoie que des intentions (charte §11).
--
-- RÈGLE D'OR côté client : l'image de la caméra regardée n'est JAMAIS changée yeux
-- ouverts. Elle se resynchronise seulement pendant le noir d'un clignement ou une
-- neige statique (changement de cam, fin d'analyse).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Version = require(Shared:WaitForChild("Version"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Reglages = require(Config:WaitForChild("Reglages"))

local Client = script.Parent
local CameraView = require(Client:WaitForChild("CameraView"))
local CameraPanel = require(Client:WaitForChild("CameraPanel"))
local BlinkController = require(Client:WaitForChild("BlinkController"))
local ReportUI = require(Client:WaitForChild("ReportUI"))
local Screamers = require(Client:WaitForChild("Screamers"))
local MenuUI = require(Client:WaitForChild("MenuUI"))
local CassetteUI = require(Client:WaitForChild("CassetteUI"))
local SalonUI = require(Client:WaitForChild("SalonUI"))
local Audio = require(Client:WaitForChild("Audio"))

print(`[Client] Le Gardien d'anomalies v{Version.VERSION} — Rojo OK`)

-- Interface Roblox par défaut masquée (sauf le chat, utile en coop)
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local niveau = require(Config:WaitForChild("Niveaux"):WaitForChild(Reglages.NiveauParDefaut))
local persoPrecedent: string? = nil
local etat: any = nil
local camActuelle: any = nil
local generationAffichee = -1
local derniereHeure = -1
local phasePrecedente = ""

-- Remet l'image affichée à jour (uniquement écran masqué)
local function synchroniser()
	if etat and etat.Images and camActuelle then
		CameraView.Synchroniser(etat.Images[camActuelle.IdPiece])
	end
end

local function choisirCamera(cam: any, forcer: boolean?)
	if not forcer and camActuelle and camActuelle.IdPiece == cam.IdPiece then return end
	camActuelle = cam
	Remotes.Get("RegarderCamera"):FireServer(cam.IdPiece)
	CameraPanel.SetActive(cam.IdPiece)
	CameraView.Afficher(cam, etat.Images[cam.IdPiece])
end

-- Nouvelle partie : (re)construit l'écran caméra
local function construireJeu()
	camActuelle = nil
	derniereHeure = -1
	niveau = require(Config:WaitForChild("Niveaux"):WaitForChild(etat.Niveau))
	CameraView.Init(niveau)
	local gui = CameraView.GetGui()
	CameraPanel.Construire(gui, etat.Cameras, choisirCamera)
	ReportUI.Init(gui)
	CassetteUI.Init(gui, etat.Jour)
	choisirCamera(etat.Cameras[1])
end

local function appliquerEtat()
	local phase = etat.Phase
	Screamers.SetPhase(phase, etat.Perso, etat.Stats)
	Audio.Boucle("AmbianceNuit", phase == "EnCours" and etat.Perso == nil)

	if phase == "Menu" or phase == "Salon" then
		MenuUI.Afficher(phase == "Menu")
		SalonUI.Afficher(phase == "Salon", etat)
		BlinkController.SetActif(false)
		if CameraView.GetGui() then CameraView.SetVisible(false) end
		CassetteUI.Arreter()
		phasePrecedente = phase
		persoPrecedent = nil
		return
	end

	MenuUI.Afficher(false)
	SalonUI.Afficher(false)
	if etat.Generation ~= generationAffichee then
		generationAffichee = etat.Generation
		construireJeu()
	end
	CameraView.SetVisible(true)
	CameraView.SetHeure(etat.Heure, etat.Minute)
	if etat.Minute == 0 and etat.Heure ~= derniereHeure then
		if derniereHeure ~= -1 then Audio.Jouer("ChangementHeure") end
	end
	derniereHeure = etat.Heure
	CameraView.SetVies(etat.Vies, etat.Banque, etat.Mode)
	local enJeu = phase == "EnCours" and etat.Perso == nil
	BlinkController.SetActif(enJeu)
	ReportUI.SetActif(enJeu and etat.Vies > 0)

	-- Sorti vivant de la pièce secrète : on repart sur la caméra 1
	if persoPrecedent == "PieceSecrete" and enJeu then
		choisirCamera(etat.Cameras[1], true)
	end
	phasePrecedente = phase
	persoPrecedent = etat.Perso
end

Remotes.Get("EtatPartie").OnClientEvent:Connect(function(nouvelEtat)
	etat = nouvelEtat
	appliquerEtat()
end)

-- Le serveur a changé l'image d'une pièce
Remotes.Get("ImagePiece").OnClientEvent:Connect(function(idPiece: string, cle: string)
	if not etat or not etat.Images then return end
	etat.Images[idPiece] = cle
	-- Affiché seulement si l'écran est déjà noir ; sinon au prochain noir/statique
	if BlinkController.EstNoir() and camActuelle and camActuelle.IdPiece == idPiece then
		synchroniser()
	end
end)

BlinkController.Init()
BlinkController.SurNoir(synchroniser)
Screamers.Init(niveau)
MenuUI.Init(niveau)
SalonUI.Init()
MenuUI.SurLancer = function(idChapitre: string, jour: number)
	Remotes.Get("LancerPartie"):FireServer(idChapitre, jour)
end

-- Raccourcis clavier (PC) : 1-9, 0, -, = pour les caméras 1 à 12 ; E = ANOMALIE ;
-- une fois les choix ouverts, 1/2/3 = type de signalement ; Échap = fermer.
local TOUCHES_CAMERAS = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero,
	Enum.KeyCode.Minus, Enum.KeyCode.Equals,
}
UserInputService.InputBegan:Connect(function(input, traite)
	if traite or not etat or etat.Phase ~= "EnCours" or etat.Perso then return end
	local touche = input.KeyCode
	if touche == Enum.KeyCode.E then
		ReportUI.Basculer()
		return
	end
	if touche == Enum.KeyCode.Escape and ReportUI.ChoixOuverts() then
		ReportUI.Basculer()
		return
	end
	local index = table.find(TOUCHES_CAMERAS, touche)
	if not index then return end
	if ReportUI.ChoixOuverts() then
		if index <= 3 then ReportUI.Choisir(index) end
		return
	end
	local cam = etat.Cameras[index]
	if cam then choisirCamera(cam) end
end)

-- Fin d'analyse : courte neige statique qui masque le retour à l'image de base
ReportUI.SurFin = function(_info)
	task.spawn(CameraView.FlashStatique, 0.25, synchroniser)
end

Remotes.Get("DemanderEtat"):FireServer()
