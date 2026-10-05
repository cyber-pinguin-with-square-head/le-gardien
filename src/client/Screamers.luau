--!strict
-- Pièce secrète, screamer et écrans de fin (charte §8).
-- Le screamer v6 est joué depuis des planches d'images (vidéo convertie) + son.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Interface = require(Shared:WaitForChild("Config"):WaitForChild("Interface"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Screamers = {}

local gui: ScreenGui
local fond: ImageLabel
local boutonLampe: TextButton
local texte: TextLabel
local animation: ImageLabel
local config: any
local imageNoir = ""
local phaseActuelle = ""

local function label(parent: Instance, taille: number): TextLabel
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Interface.Hud.Police
	t.TextSize = taille
	t.TextColor3 = Color3.fromRGB(220, 220, 220)
	t.ZIndex = 5
	t.Parent = parent
	return t
end

function Screamers.Init(niveau: any)
	config = niveau.PieceSecrete.Screamer
	for _, p in niveau.Pieces do
		if p.Id == "PieceSecrete" then imageNoir = p.Base.Image end
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "PieceSecrete"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	fond = Instance.new("ImageLabel")
	fond.Size = UDim2.fromScale(1, 1)
	fond.BackgroundColor3 = Color3.new(0, 0, 0)
	fond.BorderSizePixel = 0
	fond.ScaleType = Enum.ScaleType.Fit
	fond.Image = imageNoir
	fond.Parent = gui

	animation = Instance.new("ImageLabel")
	animation.Size = UDim2.fromScale(1, 1)
	animation.BackgroundColor3 = Color3.new(0, 0, 0)
	animation.BorderSizePixel = 0
	animation.ScaleType = Enum.ScaleType.Fit
	animation.ImageRectSize = config.TailleImage
	animation.Visible = false
	animation.ZIndex = 3
	animation.Parent = gui

	-- Bouton style FNaF en bas de l'écran
	boutonLampe = Instance.new("TextButton")
	boutonLampe.AnchorPoint = Vector2.new(0.5, 1)
	boutonLampe.Position = UDim2.new(0.5, 0, 1, -40)
	boutonLampe.Size = UDim2.fromOffset(420, 60)
	boutonLampe.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	boutonLampe.BorderSizePixel = 0
	boutonLampe.Font = Interface.Hud.Police
	boutonLampe.TextSize = 24
	boutonLampe.TextColor3 = Color3.fromRGB(230, 230, 230)
	boutonLampe.Text = "ALLUMER LA LAMPE TORCHE"
	boutonLampe.ZIndex = 4
	boutonLampe.Parent = gui
	local trait = Instance.new("UIStroke")
	trait.Color = Color3.fromRGB(200, 200, 200)
	trait.Thickness = 2
	trait.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trait.Parent = boutonLampe
	boutonLampe.Activated:Connect(function()
		boutonLampe.Visible = false
		Remotes.Get("AllumerLampe"):FireServer()
	end)

	texte = label(gui, 48)

	-- Préchargement des planches pour que le screamer soit fluide
	task.spawn(function()
		local liste = {}
		for _, id in config.Planches do
			if id ~= "" then
				local img = Instance.new("ImageLabel")
				img.Image = id
				table.insert(liste, img)
			end
		end
		if #liste > 0 then ContentProvider:PreloadAsync(liste) end
	end)
end

local function jouerScreamer()
	animation.Visible = true
	boutonLampe.Visible = false
	texte.Text = ""
	if config.Son ~= "" then
		local son = Instance.new("Sound")
		son.SoundId = config.Son
		son.Volume = 1
		son.Parent = SoundService
		son:Play()
		son.Ended:Once(function() son:Destroy() end)
	end
	local parPlanche = config.Colonnes * config.Lignes
	local debut = os.clock()
	local connexion
	connexion = RunService.RenderStepped:Connect(function()
		local i = math.floor((os.clock() - debut) * config.Fps)
		if i >= config.NombreImages or phaseActuelle ~= "Screamer" then
			connexion:Disconnect()
			return
		end
		local planche = config.Planches[i // parPlanche + 1] or ""
		local k = i % parPlanche
		if planche == "" then
			-- Repli tant que les planches ne sont pas uploadées : flash rouge
			animation.Image = ""
			animation.BackgroundColor3 = if i % 4 < 2 then Color3.fromRGB(160, 0, 0) else Color3.new(0, 0, 0)
		else
			animation.Image = planche
			animation.ImageRectOffset = Vector2.new((k % config.Colonnes) * config.TailleImage.X, (k // config.Colonnes) * config.TailleImage.Y)
		end
	end)
end

-- Appelé à chaque changement de phase reçu du serveur
function Screamers.SetPhase(phase: string, raison: string?)
	if phase == phaseActuelle then return end
	phaseActuelle = phase
	gui.Enabled = phase ~= "EnCours"
	animation.Visible = false
	boutonLampe.Visible = false
	texte.Text = ""
	fond.Image = ""

	if phase == "PieceSecrete" then
		fond.Image = imageNoir
		boutonLampe.Visible = true
	elseif phase == "Screamer" then
		jouerScreamer()
	elseif phase == "GameOver" then
		texte.TextColor3 = Color3.fromRGB(200, 30, 30)
		texte.Text = "GAME OVER"
	elseif phase == "Esquive" then
		texte.TextColor3 = Color3.fromRGB(200, 200, 200)
		texte.Text = "…il est reparti."
	elseif phase == "Victoire" then
		texte.TextColor3 = Color3.fromRGB(220, 220, 220)
		texte.Text = "05:00\nFIN DE LA NUIT"
	end
end

return Screamers
