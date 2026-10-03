--!strict
-- Script de test : confirme que Rojo synchronise le code client
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

print(`[Client] Le Gardien v{Version.VERSION} — Rojo OK`)
