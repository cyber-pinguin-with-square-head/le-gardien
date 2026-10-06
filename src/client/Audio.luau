--!strict
-- Lecture des sons définis dans Config/Sons. Un ID vide = rien ne se passe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sons"))
local Options = require(script.Parent:WaitForChild("Options"))

local Audio = {}

local boucles: { [string]: Sound } = {}

function Audio.Jouer(nom: string)
	local s = (Sons :: any)[nom]
	if not s or s.Id == "" then return end
	local son = Instance.new("Sound")
	son.SoundId = s.Id
	son.Volume = s.Volume * Options.Volume
	son.Parent = SoundService
	son:Play()
	son.Ended:Once(function() son:Destroy() end)
end

-- Démarre / arrête une boucle (ambiance, musique)
function Audio.Boucle(nom: string, active: boolean)
	local s = (Sons :: any)[nom]
	if not s or s.Id == "" then return end
	local son = boucles[nom]
	if active then
		if not son then
			son = Instance.new("Sound")
			son.SoundId = s.Id
			son.Looped = true
			son.Parent = SoundService
			boucles[nom] = son
		end
		son.Volume = s.Volume * Options.Volume
		if not son.IsPlaying then son:Play() end
	elseif son then
		son:Stop()
	end
end

-- À appeler quand le volume change dans les options
function Audio.MajVolume()
	for nom, son in boucles do
		son.Volume = (Sons :: any)[nom].Volume * Options.Volume
	end
end

return Audio
