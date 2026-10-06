--!strict
-- Héberger / Rejoindre / Solo (charte §10) avec des serveurs réservés.
--
--   Serveur PUBLIC  = « Hub » : uniquement le menu. Jouer / Héberger / Rejoindre
--                     téléportent vers un serveur réservé.
--   Serveur RÉSERVÉ = « Solo » (1 joueur) ou « Coop » (salle d'attente + code).
--   Roblox STUDIO   = la téléportation n'existe pas : tout se joue sur place
--                     (Héberger ouvre directement une salle d'attente locale).
--
-- Les codes de partie (6 caractères) sont stockés dans MemoryStore pour 6 h.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Reglages = require(Config:WaitForChild("Reglages"))
local Chapitres = require(Config:WaitForChild("Chapitres"))
local Partie = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Partie"))

local LobbySystem = {}

local ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" -- sans 0/O/1/I (lisibilité)
local DUREE_CODE = 6 * 3600
local rng = Random.new()
-- MemoryStore n'existe que dans un jeu publié : on l'ouvre seulement au besoin
local codesMap: MemoryStoreSortedMap? = nil
local function codes(): MemoryStoreSortedMap
	if not codesMap then
		codesMap = MemoryStoreService:GetSortedMap("CodesCoop")
	end
	return codesMap :: MemoryStoreSortedMap
end
local enTeleportation: { [Player]: boolean } = {}
local lancer: (chapitre: any, jour: any, mode: string) -> () = function() end

local function message(joueur: Player, texte: string)
	Remotes.Get("MessageLobby"):FireClient(joueur, texte)
end

local function nouveauCode(): string
	local t = {}
	for i = 1, 6 do
		local k = rng:NextInteger(1, #ALPHABET)
		t[i] = string.sub(ALPHABET, k, k)
	end
	return table.concat(t)
end

-- Vérifie chapitre + jour envoyés par le client
local function valider(idChapitre: any, numeroJour: any): (any, any)
	if typeof(idChapitre) ~= "string" or typeof(numeroJour) ~= "number" then return nil, nil end
	local chapitre = Chapitres.Get(idChapitre)
	if not chapitre or not chapitre.Disponible then return nil, nil end
	return chapitre, Chapitres.GetJour(chapitre, numeroJour)
end

local function teleporter(joueurs: { Player }, codeAcces: string, donnees: any)
	for _, j in joueurs do enTeleportation[j] = true end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = codeAcces
	options:SetTeleportData(donnees)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, joueurs, options)
	end)
	if not ok then
		for _, j in joueurs do
			enTeleportation[j] = nil
			message(j, "Téléportation impossible. Réessayez.")
		end
		warn("[Lobby] Téléportation échouée : " .. tostring(err))
	end
end

-- Partie solo dans un serveur réservé rien que pour le joueur
local function teleporterSolo(joueur: Player, chapitre: any, jour: any)
	local ok, codeAcces = pcall(function()
		return (TeleportService:ReserveServer(game.PlaceId))
	end)
	if not ok then
		message(joueur, "Impossible de créer la partie. Réessayez.")
		return
	end
	message(joueur, "Ouverture de la maison…")
	teleporter({ joueur }, codeAcces, { Mode = "Solo", Chapitre = chapitre.Id, Jour = jour.Numero })
end

local function heberger(joueur: Player)
	if enTeleportation[joueur] then return end
	local t = Partie.Serveur.Type
	if t == "Studio" then
		-- Pas de téléportation en Studio : salle d'attente locale pour tester
		Partie.Serveur.Code = "STUDIO"
		Partie.Serveur.HoteId = joueur.UserId
		Partie.Mode = "Coop"
		Partie.Reinitialiser("Salon")
		Partie.Diffuser()
		return
	end
	if t == "Coop" then return end

	local ok, codeAcces = pcall(function()
		return (TeleportService:ReserveServer(game.PlaceId))
	end)
	if not ok then
		message(joueur, "Impossible de créer la partie. Réessayez.")
		return
	end
	local code = nouveauCode()
	local okStock = pcall(function()
		codes():SetAsync(code, { Acces = codeAcces, Hote = joueur.UserId }, DUREE_CODE)
	end)
	if not okStock then
		message(joueur, "Impossible d'enregistrer le code. Réessayez.")
		return
	end
	message(joueur, "Préparation de la partie…")
	teleporter({ joueur }, codeAcces, { Mode = "Coop", Code = code, Hote = joueur.UserId })
end

local function rejoindre(joueur: Player, code: any)
	if enTeleportation[joueur] then return end
	if typeof(code) ~= "string" then return end
	code = string.upper((string.gsub(code, "%s", "")))
	if #code ~= 6 or string.find(code, "[^" .. ALPHABET .. "]") then
		message(joueur, "Code invalide (6 caractères).")
		return
	end
	if Partie.Serveur.Type == "Studio" then
		message(joueur, "Rejoindre ne fonctionne pas dans Studio (pas de téléportation).")
		return
	end
	local ok, infos = pcall(function()
		return codes():GetAsync(code)
	end)
	if not ok or not infos then
		message(joueur, "Aucune partie avec ce code.")
		return
	end
	message(joueur, "Connexion à la partie…")
	teleporter({ joueur }, infos.Acces, { Mode = "Coop", Code = code, Hote = infos.Hote })
end

local function lancerPartie(joueur: Player, idChapitre: any, numeroJour: any)
	local chapitre, jour = valider(idChapitre, numeroJour)
	if not chapitre or not jour then return end
	local t = Partie.Serveur.Type

	if Partie.Phase == "Salon" then
		-- Coop : seul l'hôte lance
		if joueur.UserId ~= Partie.Serveur.HoteId then return end
		lancer(chapitre, jour, "Coop")
	elseif Partie.Phase == "Menu" then
		if t == "Hub" then
			if not enTeleportation[joueur] then teleporterSolo(joueur, chapitre, jour) end
		else
			lancer(chapitre, jour, "Solo") -- Studio ou serveur solo réservé
		end
	end
end

local function retourMenu(_joueur: Player)
	if Partie.Phase ~= "GameOver" and Partie.Phase ~= "Victoire" then return end
	Partie.Reinitialiser(if Partie.Mode == "Coop" then "Salon" else "Menu")
	Partie.Diffuser()
end

local function quitterSalon(joueur: Player)
	if Partie.Serveur.Type == "Studio" then
		Partie.Serveur.Code = ""
		Partie.Serveur.HoteId = 0
		Partie.Mode = "Solo"
		Partie.Reinitialiser("Menu")
		Partie.Diffuser()
		return
	end
	-- Retour sur un serveur public (le hub)
	enTeleportation[joueur] = true
	local ok = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { joueur })
	end)
	if not ok then
		enTeleportation[joueur] = nil
		message(joueur, "Impossible de quitter. Réessayez.")
	end
end

-- Premier joueur arrivé dans un serveur réservé : on lit ce qu'il apporte
local function configurerServeurReserve(joueur: Player)
	if Partie.Serveur.Type ~= "Reserve" then return end
	local donnees = joueur:GetJoinData().TeleportData
	if typeof(donnees) ~= "table" then
		Partie.Serveur.Type = "Solo"
		return
	end
	if donnees.Mode == "Coop" then
		Partie.Serveur.Type = "Coop"
		Partie.Serveur.Code = tostring(donnees.Code or "")
		Partie.Serveur.HoteId = tonumber(donnees.Hote) or joueur.UserId
		Partie.Mode = "Coop"
		Partie.Reinitialiser("Salon")
		Partie.Diffuser()
	else
		Partie.Serveur.Type = "Solo"
		local chapitre, jour = valider(donnees.Chapitre, donnees.Jour)
		if chapitre and jour then
			lancer(chapitre, jour, "Solo")
		end
	end
end

function LobbySystem.Init(fonctionLancer: (chapitre: any, jour: any, mode: string) -> ())
	lancer = fonctionLancer

	if RunService:IsStudio() then
		Partie.Serveur.Type = "Studio"
	elseif game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		Partie.Serveur.Type = "Reserve" -- précisé à l'arrivée du premier joueur
	else
		Partie.Serveur.Type = "Hub"
	end

	Remotes.Get("Heberger").OnServerEvent:Connect(heberger)
	Remotes.Get("Rejoindre").OnServerEvent:Connect(rejoindre)
	Remotes.Get("LancerPartie").OnServerEvent:Connect(lancerPartie)
	Remotes.Get("RetourMenu").OnServerEvent:Connect(retourMenu)
	Remotes.Get("QuitterSalon").OnServerEvent:Connect(quitterSalon)

	Players.PlayerAdded:Connect(function(joueur)
		configurerServeurReserve(joueur)
		-- Sécurité : jamais plus de JoueursMax en coop
		if Partie.Serveur.Type == "Coop" and #Players:GetPlayers() > Reglages.Coop.JoueursMax then
			joueur:Kick("La partie est complète.")
			return
		end
		if Partie.Phase == "Salon" then Partie.Diffuser() end
	end)
	Players.PlayerRemoving:Connect(function(joueur)
		enTeleportation[joueur] = nil
		-- L'hôte part : le plus ancien joueur restant devient hôte
		if Partie.Serveur.Type ~= "Hub" and joueur.UserId == Partie.Serveur.HoteId then
			for _, j in Players:GetPlayers() do
				if j ~= joueur then
					Partie.Serveur.HoteId = j.UserId
					break
				end
			end
		end
		task.defer(function()
			if Partie.Phase == "Salon" then Partie.Diffuser() end
		end)
	end)
	TeleportService.TeleportInitFailed:Connect(function(joueur)
		enTeleportation[joueur] = nil
		message(joueur, "Téléportation échouée. Réessayez.")
	end)
end

return LobbySystem
