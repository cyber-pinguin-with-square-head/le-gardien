--!strict
-- Cassettes de Danny, l'ancien gardien : une par jour, écoutable pendant la nuit
-- (sous-titres + voix quand elle sera enregistrée). L'écouter distrait de la
-- surveillance : c'est voulu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Lore = require(Config:WaitForChild("Lore"))
local Interface = require(Config:WaitForChild("Interface"))
local Options = require(script.Parent:WaitForChild("Options"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Echelle = require(script.Parent:WaitForChild("Echelle"))

local CassetteUI = {}

local bouton: TextButton
local sousTitre: TextLabel
local son: Sound?
local lecture = 0 -- incrémenté à chaque lecture/arrêt pour couper l'ancienne

local function arreter()
	lecture += 1
	if son then
		son:Destroy()
		son = nil
	end
	if sousTitre then sousTitre.Visible = false end
	if bouton then bouton.Text = "▶ CASSETTE" end
end

local function jouer(cassette: any)
	arreter()
	local id = lecture
	bouton.Text = "■ STOP"
	if cassette.Son ~= "" then
		local s = Instance.new("Sound")
		s.SoundId = cassette.Son
		s.Volume = Options.Volume
		s.Parent = SoundService
		s:Play()
		son = s
	end
	task.spawn(function()
		sousTitre.Visible = true
		sousTitre.Text = cassette.Titre
		task.wait(2)
		for _, ligne in cassette.Lignes do
			if lecture ~= id then return end
			sousTitre.Text = ligne[1]
			task.wait(ligne[2])
		end
		if lecture == id then arreter() end
	end)
end

function CassetteUI.Init(parent: Instance, jour: number)
	arreter()
	local cassette = Lore.Cassettes[jour]
	if not cassette then return end

	bouton = Instance.new("TextButton")
	bouton.Name = "Cassette"
	bouton.Position = UDim2.fromOffset(24, 56)
	bouton.Size = UDim2.fromOffset(170, 32)
	bouton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	bouton.BackgroundTransparency = 0.3
	bouton.BorderSizePixel = 0
	bouton.Font = Interface.Hud.Police
	bouton.TextSize = 17
	bouton.TextColor3 = Interface.Hud.CouleurTexte
	bouton.Text = "▶ CASSETTE"
	bouton.ZIndex = 20
	bouton.Parent = parent
	Echelle.Appliquer(bouton)

	sousTitre = Instance.new("TextLabel")
	sousTitre.Name = "SousTitre"
	sousTitre.AnchorPoint = Vector2.new(0.5, 1)
	sousTitre.Position = UDim2.new(0.5, 0, 1, -110)
	sousTitre.Size = UDim2.new(0.6, 0, 0, 70)
	sousTitre.BackgroundColor3 = Color3.new(0, 0, 0)
	sousTitre.BackgroundTransparency = 0.35
	sousTitre.BorderSizePixel = 0
	sousTitre.Font = Interface.Hud.Police
	sousTitre.TextSize = 19
	sousTitre.TextWrapped = true
	sousTitre.TextColor3 = Color3.fromRGB(235, 225, 190)
	sousTitre.Visible = false
	sousTitre.ZIndex = 25
	sousTitre.Parent = parent

	bouton.Activated:Connect(function()
		Audio.Jouer("Cassette")
		if bouton.Text == "■ STOP" then
			arreter()
		else
			jouer(cassette)
		end
	end)
end

CassetteUI.Arreter = arreter

return CassetteUI
