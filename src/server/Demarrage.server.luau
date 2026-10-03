--!strict
-- Script de test : confirme que Rojo synchronise le code serveur
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

print(`[Serveur] Le Gardien v{Version.VERSION} — Rojo OK`)
