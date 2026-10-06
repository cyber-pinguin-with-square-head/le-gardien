--!strict
-- Cycle de partie (charte §7, §8) : menu -> nuit 23h-5h -> victoire / défaites.
-- Solo pour l'instant : le lobby coop (étape h) appellera lancer(..., "Coop").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Reglages = require(Config:WaitForChild("Reglages"))
local Server = ServerScriptService:WaitForChild("Server")
local Partie = require(Server:WaitForChild("Partie"))
local Vies = require(Server:WaitForChild("Vies"))
local AnomalySystem = require(Server:WaitForChild("AnomalySystem"))
local ReportSystem = require(Server:WaitForChild("ReportSystem"))
local LobbySystem = require(Server:WaitForChild("LobbySystem"))

local rng = Random.new()

-- Durée du screamer = durée de l'animation (planches) + petite marge
local function dureeScreamer(): number
	local s = Partie.Niveau.PieceSecrete.Screamer
	return s.NombreImages / s.Fps + 0.5
end

local function lancerScreamer(raison: string)
	local generation = Partie.Generation
	Partie.ChangerPhase("Screamer", raison)
	task.delay(dureeScreamer(), function()
		if Partie.Generation == generation and Partie.Phase == "Screamer" then
			Partie.ChangerPhase("GameOver")
		end
	end)
end

-- Vies à 0 (charte §8) : screamer direct puis Game Over
local function surElimination()
	if Partie.Phase ~= "EnCours" then return end
	lancerScreamer("Erreurs")
end

-- EASTER EGG (charte §8) : en changeant de caméra, le joueur atterrit parfois dans la
-- pièce secrète. Il ne peut plus changer de cam. Allumer = screamer ; tenir
-- DureeEsquive s dans le noir = retour sur la caméra 1. Personnel : les autres
-- joueurs continuent de jouer.
local function entrerPieceSecrete(joueur: Player)
	local generation = Partie.Generation
	Partie.Perso[joueur] = "PieceSecrete"
	Partie.Regards[joueur] = nil
	AnomalySystem.SurChangementRegard()
	Partie.Diffuser()
	task.delay(Reglages.PieceSecrete.DureeEsquive, function()
		if Partie.Generation ~= generation or Partie.Perso[joueur] ~= "PieceSecrete" then return end
		Partie.Perso[joueur] = nil
		Partie.Diffuser() -- le client repart sur la cam 1
	end)
end

local function allumerLampe(joueur: Player)
	if Partie.Perso[joueur] ~= "PieceSecrete" or Partie.Phase ~= "EnCours" then return end
	local generation = Partie.Generation
	Partie.Perso[joueur] = "Screamer"
	Partie.Diffuser()
	task.delay(dureeScreamer(), function()
		if Partie.Generation ~= generation then return end
		Partie.Perso[joueur] = nil
		-- Solo : fin de partie. Coop : le joueur devient spectateur.
		Partie.Vies[joueur] = 0
		for _, j in Players:GetPlayers() do
			if Vies.PeutJouer(j) then
				Partie.Diffuser()
				return
			end
		end
		Partie.ChangerPhase("GameOver", "PieceSecrete")
	end)
end

-- Défaite par négligence : seuil atteint => screamer immédiat (charte §8)
local function negligence()
	if Partie.Phase ~= "EnCours" then return end
	lancerScreamer("Negligence")
end

-- Horloge : 23:00 -> 05:00 en Reglages.Nuit.DureeReelleSecondes (en pause hors EnCours)
local function demarrerHorloge()
	local n = Reglages.Nuit
	local minutesJeu = ((n.HeureFin - n.HeureDebut) % 24) * 60
	local secondesParMinute = n.DureeReelleSecondes / minutesJeu
	local generation = Partie.Generation
	task.spawn(function()
		local ecoulees = 0
		while ecoulees < minutesJeu do
			task.wait(secondesParMinute)
			if Partie.Generation ~= generation then return end
			if Partie.Phase == "EnCours" then
				ecoulees += 1
				Partie.Minute += 1
				if Partie.Minute >= 60 then
					Partie.Minute = 0
					Partie.Heure = (Partie.Heure + 1) % 24
				end
				Partie.Diffuser()
			end
		end
		if Partie.Generation == generation and Partie.Phase == "EnCours" then
			Partie.ChangerPhase("Victoire")
		end
	end)
end

local function lancer(chapitre: any, jour: any, mode: string)
	Partie.Creer(jour.Difficulte, chapitre.Niveau, mode, chapitre.Id, jour.Numero)
	for _, joueur in Players:GetPlayers() do
		Vies.Ajouter(joueur)
	end
	AnomalySystem.Demarrer()
	demarrerHorloge()
	Partie.Diffuser()

	local noms = {}
	for _, cam in Partie.Cameras do
		table.insert(noms, `{cam.Numero}:{cam.IdPiece}`)
	end
	print(`[Partie] {Partie.Difficulte.Id} / {Partie.Mode} — {#Partie.Cameras} caméras : {table.concat(noms, ", ")}`)
end

Vies.SurElimination = surElimination
AnomalySystem.SurSeuil = negligence
ReportSystem.Init()

Players.PlayerAdded:Connect(function(joueur)
	if Partie.Phase ~= "Menu" and Partie.Phase ~= "Salon" then Vies.Ajouter(joueur) end
end)

Players.PlayerRemoving:Connect(function(joueur)
	Partie.Regards[joueur] = nil
	Partie.Vies[joueur] = nil
	ReportSystem.Retirer(joueur)
	AnomalySystem.SurChangementRegard()
end)

-- Le client demande l'état quand il est prêt (évite de rater l'envoi)
Remotes.Get("DemanderEtat").OnServerEvent:Connect(function(joueur)
	Remotes.Get("EtatPartie"):FireClient(joueur, Partie.EtatPublic(joueur))
end)

-- Menu, Héberger / Rejoindre, salle d'attente coop : voir LobbySystem
LobbySystem.Init(lancer)

-- Intention client : « je regarde la cam X » (validée côté serveur)
Remotes.Get("RegarderCamera").OnServerEvent:Connect(function(joueur, idPiece)
	if typeof(idPiece) ~= "string" or not Partie.EstCamera(idPiece) then return end
	if Partie.Perso[joueur] then return end -- bloqué dans la pièce secrète
	-- Easter egg : seulement sur un VRAI changement de caméra, en cours de nuit
	local change = Partie.Regards[joueur] ~= nil and Partie.Regards[joueur] ~= idPiece
	if change and Partie.Phase == "EnCours" and rng:NextNumber() < Reglages.PieceSecrete.ChanceParChangementCamera then
		entrerPieceSecrete(joueur)
		return
	end
	Partie.Regards[joueur] = idPiece
	AnomalySystem.SurChangementRegard()
end)

Remotes.Get("AllumerLampe").OnServerEvent:Connect(allumerLampe)

-- Pour l'outil de test (Studio)
local outils = Instance.new("BindableEvent")
outils.Name = "ForcerPieceSecrete"
outils.Parent = Server
outils.Event:Connect(entrerPieceSecrete)
