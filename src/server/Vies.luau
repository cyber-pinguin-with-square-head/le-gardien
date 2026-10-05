--!strict
-- Vies (charte §7 et §10).
-- Solo : vies de la difficulté. Coop : 1 vie chacun + banque partagée ; une erreur pioche
-- d'abord dans la banque, sinon le joueur perd sa vie et devient spectateur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Reglages = require(Config:WaitForChild("Reglages"))
local Partie = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Partie"))

local Vies = {}

-- Appelé quand plus aucun joueur n'a de vie (=> pièce secrète)
Vies.SurElimination = function() end

function Vies.Ajouter(joueur: Player)
	if Partie.Vies[joueur] then return end
	Partie.Vies[joueur] = if Partie.Mode == "Coop" then Reglages.Coop.ViesParJoueur else Partie.Difficulte.Vies
end

function Vies.PeutJouer(joueur: Player): boolean
	return (Partie.Vies[joueur] or 0) > 0
end

function Vies.Perdre(joueur: Player)
	if Partie.Banque > 0 then
		Partie.Banque -= 1
	else
		Partie.Vies[joueur] = math.max((Partie.Vies[joueur] or 0) - 1, 0)
	end
	Partie.Diffuser()

	for _, j in Players:GetPlayers() do
		if Vies.PeutJouer(j) then return end
	end
	Vies.SurElimination()
end

return Vies
