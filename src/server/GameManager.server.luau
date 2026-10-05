--!strict
-- Cycle de partie (charte §7, §8) : création, horloge 23h -> 5h, victoire, défaites,
-- pièce secrète. Le menu / lobby (étapes g, h) choisira plus tard difficulté et mode.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Reglages = require(Config:WaitForChild("Reglages"))
local Difficultes = require(Config:WaitForChild("Difficultes"))
local Server = ServerScriptService:WaitForChild("Server")
local Partie = require(Server:WaitForChild("Partie"))
local Vies = require(Server:WaitForChild("Vies"))
local AnomalySystem = require(Server:WaitForChild("AnomalySystem"))
local ReportSystem = require(Server:WaitForChild("ReportSystem"))

-- Durée du screamer = durée de l'animation (planches) + petite marge
local function dureeScreamer(): number
	local s = Partie.Niveau.PieceSecrete.Screamer
	return s.NombreImages / s.Fps + 0.5
end

local function lancerScreamer(raison: string)
	Partie.ChangerPhase("Screamer", raison)
	task.delay(dureeScreamer(), function()
		if Partie.Phase == "Screamer" then
			Partie.ChangerPhase("GameOver")
		end
	end)
end

-- Défaite par erreurs : pièce secrète, bouton « Allumer la lampe torche » (charte §8)
local function pieceSecrete()
	if Partie.Phase ~= "EnCours" then return end
	Partie.ChangerPhase("PieceSecrete", "Erreurs")
	task.delay(Reglages.PieceSecrete.DureeEsquive, function()
		if Partie.Phase == "PieceSecrete" then
			-- Suite après l'esquive : à définir par Akuma (Questions.txt)
			Partie.ChangerPhase("Esquive")
		end
	end)
end

-- Défaite par négligence : seuil atteint => screamer immédiat (charte §8)
local function negligence()
	if Partie.Phase ~= "EnCours" then return end
	lancerScreamer("Negligence")
end

-- Horloge : 23:00 -> 05:00 en Reglages.Nuit.DureeReelleSecondes
local function demarrerHorloge()
	local n = Reglages.Nuit
	local minutesJeu = ((n.HeureFin - n.HeureDebut) % 24) * 60
	local secondesParMinute = n.DureeReelleSecondes / minutesJeu
	task.spawn(function()
		for _ = 1, minutesJeu do
			task.wait(secondesParMinute)
			if Partie.Phase ~= "EnCours" then return end
			Partie.Minute += 1
			if Partie.Minute >= 60 then
				Partie.Minute = 0
				Partie.Heure = (Partie.Heure + 1) % 24
			end
			Partie.Diffuser()
		end
		if Partie.Phase == "EnCours" then
			Partie.ChangerPhase("Victoire")
		end
	end)
end

-- Provisoire : sans menu, on lance directement Normal en solo
Partie.Creer(Difficultes.ParDefaut, Reglages.NiveauParDefaut, "Solo")
Vies.SurElimination = pieceSecrete
AnomalySystem.SurSeuil = negligence
ReportSystem.Init()

local function ajouterJoueur(joueur: Player)
	Vies.Ajouter(joueur)
end
Players.PlayerAdded:Connect(ajouterJoueur)
for _, j in Players:GetPlayers() do
	ajouterJoueur(j)
end

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

-- Intention client : « je regarde la cam X » (validée côté serveur)
Remotes.Get("RegarderCamera").OnServerEvent:Connect(function(joueur, idPiece)
	if typeof(idPiece) ~= "string" or not Partie.EstCamera(idPiece) then return end
	Partie.Regards[joueur] = idPiece
	AnomalySystem.SurChangementRegard()
end)

Remotes.Get("AllumerLampe").OnServerEvent:Connect(function()
	if Partie.Phase == "PieceSecrete" then
		lancerScreamer("Erreurs")
	end
end)

AnomalySystem.Demarrer()
demarrerHorloge()

local noms = {}
for _, cam in Partie.Cameras do
	table.insert(noms, `{cam.Numero}:{cam.IdPiece}`)
end
print(`[Partie] {Partie.Difficulte.Id} / {Partie.Mode} — {#Partie.Cameras} caméras : {table.concat(noms, ", ")}`)
