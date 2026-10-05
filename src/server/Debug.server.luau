--!strict
-- Outils de test, actifs UNIQUEMENT dans Roblox Studio (jamais en jeu publié).
-- ServerStorage.Debug:Invoke("etat") / ("anomalie", idPiece?) / ("vie") / ("heure", h)

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Server = ServerScriptService:WaitForChild("Server")
local Partie = require(Server:WaitForChild("Partie"))
local Vies = require(Server:WaitForChild("Vies"))
local AnomalySystem = require(Server:WaitForChild("AnomalySystem"))

local f = Instance.new("BindableFunction")
f.Name = "Debug"
f.Parent = ServerStorage

f.OnInvoke = function(commande: string, arg: any): any
	if commande == "etat" then
		local actives = {}
		for _, cam in Partie.Cameras do
			local a = AnomalySystem.Get(cam.IdPiece)
			if a then table.insert(actives, `{cam.IdPiece}={a.Cle}`) end
		end
		local regards = {}
		for j, id in Partie.Regards do table.insert(regards, `{j.Name}->{id}`) end
		local vies = {}
		for j, v in Partie.Vies do table.insert(vies, `{j.Name}={v}`) end
		return string.format("phase=%s heure=%02d:%02d vies=[%s] banque=%d regards=[%s] actives=[%s]",
			Partie.Phase, Partie.Heure, Partie.Minute, table.concat(vies, ","), Partie.Banque,
			table.concat(regards, ","), table.concat(actives, ","))
	elseif commande == "anomalie" then
		if arg then
			local a = Partie.GetPiece(arg).Anomalies[1]
			if not a then return "pas d'anomalie pour cette pièce" end
			AnomalySystem.Changer(arg, a.Cle, function()
				print(`[Debug] {a.Cle} appliquée`)
			end)
			return "programmée : " .. a.Cle
		end
		AnomalySystem.TenterApparition()
		return "tentative lancée"
	elseif commande == "vie" then
		Vies.Perdre(Players:GetPlayers()[1])
		return "vie retirée"
	end
	return "commande inconnue"
end
