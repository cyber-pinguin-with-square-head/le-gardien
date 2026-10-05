--!strict
-- Point d'entrée client : reçoit l'état de la partie et branche tous les modules.
-- Le client n'envoie que des intentions (charte §11).
--
-- RÈGLE D'OR côté client : l'image de la caméra regardée n'est JAMAIS changée yeux
-- ouverts. Elle se resynchronise seulement pendant le noir d'un clignement ou une
-- neige statique (changement de cam, fin d'analyse).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Version = require(Shared:WaitForChild("Version"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Client = script.Parent
local CameraView = require(Client:WaitForChild("CameraView"))
local CameraPanel = require(Client:WaitForChild("CameraPanel"))
local BlinkController = require(Client:WaitForChild("BlinkController"))
local ReportUI = require(Client:WaitForChild("ReportUI"))
local Screamers = require(Client:WaitForChild("Screamers"))

print(`[Client] Le Gardien d'anomalies v{Version.VERSION} — Rojo OK`)

local etat: any = nil
local camActuelle: any = nil

-- Remet l'image affichée à jour (uniquement écran masqué)
local function synchroniser()
	if etat and camActuelle then
		CameraView.Synchroniser(etat.Images[camActuelle.IdPiece])
	end
end

local function choisirCamera(cam: any)
	if camActuelle and camActuelle.IdPiece == cam.IdPiece then return end
	camActuelle = cam
	Remotes.Get("RegarderCamera"):FireServer(cam.IdPiece)
	CameraPanel.SetActive(cam.IdPiece)
	CameraView.Afficher(cam, etat.Images[cam.IdPiece])
end

local function appliquerEtat()
	CameraView.SetHeure(etat.Heure, etat.Minute)
	CameraView.SetVies(etat.Vies, etat.Banque, etat.Mode)
	local enJeu = etat.Phase == "EnCours"
	BlinkController.SetActif(enJeu)
	ReportUI.SetActif(enJeu and etat.Vies > 0)
	Screamers.SetPhase(etat.Phase, etat.Raison)
end

Remotes.Get("EtatPartie").OnClientEvent:Connect(function(nouvelEtat)
	local premiere = etat == nil
	etat = nouvelEtat
	if premiere then
		local niveau = require(Config:WaitForChild("Niveaux"):WaitForChild(etat.Niveau))
		CameraView.Init(niveau)
		local gui = CameraView.GetGui()
		CameraPanel.Construire(gui, etat.Cameras, choisirCamera)
		ReportUI.Init(gui)
		BlinkController.Init()
		Screamers.Init(niveau)
		choisirCamera(etat.Cameras[1])
	end
	appliquerEtat()
end)

-- Le serveur a changé l'image d'une pièce
Remotes.Get("ImagePiece").OnClientEvent:Connect(function(idPiece: string, cle: string)
	if not etat then return end
	etat.Images[idPiece] = cle
	-- Affiché seulement si l'écran est déjà noir ; sinon au prochain noir/statique
	if BlinkController.EstNoir() and camActuelle and camActuelle.IdPiece == idPiece then
		synchroniser()
	end
end)

BlinkController.SurNoir(synchroniser)

-- Fin d'analyse : courte neige statique qui masque le retour à l'image de base
ReportUI.SurFin = function(_info)
	task.spawn(CameraView.FlashStatique, 0.25, synchroniser)
end

Remotes.Get("DemanderEtat"):FireServer()
