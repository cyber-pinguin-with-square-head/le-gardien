--!strict
-- Affichage de l'image d'une caméra + filtre « caméra de surveillance » (charte §4).
-- Règle d'or (§6) : ce module n'affiche que ce que le serveur dit ; il ne décide jamais
-- d'un changement d'image d'une pièce.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Reglages = require(Config:WaitForChild("Reglages"))
local Interface = require(Config:WaitForChild("Interface"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Echelle = require(script.Parent:WaitForChild("Echelle"))

local CameraView = {}

local gui: ScreenGui
local image: ImageLabel
local manquant: TextLabel
local titre: TextLabel
local viesLabel: TextLabel
local cleAffichee: string? = nil
local statique: Frame
local statiqueImage: ImageLabel
local assets: { [string]: string } = {} -- clé d'image -> rbxassetid
local cameraActuelle: any = nil
local heureTexte = "23:00"
local enTransition = false
local connexionScintillement: RBXScriptConnection? = nil

local function creer(classe: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(classe)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function pleinEcran(): UDim2
	return UDim2.fromScale(1, 1)
end

-- Grain animé : texture en tuile décalée au hasard (rien si texture pas encore uploadée)
local function construireBruit(parent: Instance)
	local textures = {}
	for _, id in Interface.Textures.Bruit do
		if id ~= "" then table.insert(textures, id) end
	end
	if #textures == 0 then return end

	local bruit = creer("ImageLabel", {
		Name = "Bruit", Size = UDim2.fromScale(1.5, 1.5), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(256, 256),
		ImageTransparency = Interface.Filtre.BruitTransparence, ZIndex = 3,
	}, parent)
	local rng = Random.new()
	task.spawn(function()
		while bruit.Parent do
			bruit.Image = textures[rng:NextInteger(1, #textures)]
			bruit.Position = UDim2.fromOffset(-rng:NextInteger(0, 255), -rng:NextInteger(0, 255))
			task.wait(Interface.Filtre.BruitVitesse)
		end
	end)
end

local function construireScanlines(parent: Instance)
	local conteneur = creer("Frame", {
		Name = "Scanlines", Size = pleinEcran(), BackgroundTransparency = 1, ZIndex = 4,
	}, parent)
	local n = Interface.Filtre.ScanlinesNombre
	for i = 0, n - 1 do
		creer("Frame", {
			Size = UDim2.new(1, 0, 0.4 / n, 0), Position = UDim2.fromScale(0, i / n),
			BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
			BackgroundTransparency = Interface.Filtre.ScanlinesTransparence, ZIndex = 4,
		}, conteneur)
	end
end

local function construireVignette(parent: Instance)
	if Interface.Textures.Vignette ~= "" then
		creer("ImageLabel", {
			Name = "Vignette", Size = pleinEcran(), BackgroundTransparency = 1,
			Image = Interface.Textures.Vignette, ScaleType = Enum.ScaleType.Stretch, ZIndex = 5,
		}, parent)
		return
	end
	-- Repli : 4 bords en dégradé noir -> transparent
	local bords = {
		{ UDim2.fromScale(1, 0.18), UDim2.fromScale(0, 0), 90 },
		{ UDim2.fromScale(1, 0.18), UDim2.fromScale(0, 0.82), -90 },
		{ UDim2.fromScale(0.12, 1), UDim2.fromScale(0, 0), 0 },
		{ UDim2.fromScale(0.12, 1), UDim2.fromScale(0.88, 0), 180 },
	}
	for _, b in bords do
		local f = creer("Frame", {
			Size = b[1], Position = b[2], BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0, BackgroundTransparency = Interface.Filtre.VignetteTransparenceRepli, ZIndex = 5,
		}, parent)
		creer("UIGradient", {
			Rotation = b[3],
			Transparency = NumberSequence.new(0, 1),
		}, f)
	end
end

local function construireScintillement(parent: Instance)
	local voile = creer("Frame", {
		Name = "Scintillement", Size = pleinEcran(), BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0, BackgroundTransparency = 1, ZIndex = 6,
	}, parent)
	local rng = Random.new()
	connexionScintillement = RunService.RenderStepped:Connect(function()
		voile.BackgroundTransparency = 1 - rng:NextNumber(0, Interface.Filtre.ScintillementAmplitude)
	end)
end

local function construireHud(parent: Instance)
	local hud = Interface.Hud
	titre = creer("TextLabel", {
		Name = "Titre", Position = UDim2.fromOffset(24, 18), Size = UDim2.fromOffset(600, 30),
		BackgroundTransparency = 1, Font = hud.Police, TextSize = 22, TextColor3 = hud.CouleurTexte,
		TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, ZIndex = 10, Text = "",
	}, parent)
	local rec = creer("TextLabel", {
		Name = "Rec", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 18),
		Size = UDim2.fromOffset(110, 30), BackgroundTransparency = 1, Font = hud.Police, TextSize = 22,
		TextColor3 = hud.CouleurRec, TextXAlignment = Enum.TextXAlignment.Right, Text = "● REC", ZIndex = 10,
	}, parent)
	viesLabel = creer("TextLabel", {
		Name = "Vies", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 50),
		Size = UDim2.fromOffset(300, 26), BackgroundTransparency = 1, Font = hud.Police, TextSize = 18,
		TextColor3 = hud.CouleurTexte, TextXAlignment = Enum.TextXAlignment.Right,
		TextStrokeTransparency = 0.6, TextTransparency = 0.25, ZIndex = 10, Text = "",
	}, parent)
	task.spawn(function()
		while rec.Parent do
			rec.TextTransparency = if rec.TextTransparency == 0 then 1 else 0
			task.wait(hud.RecPeriode)
		end
	end)
end

local function construireStatique(parent: Instance)
	statique = creer("Frame", {
		Name = "Statique", Size = pleinEcran(), BackgroundColor3 = Color3.fromRGB(120, 120, 120),
		BorderSizePixel = 0, Visible = false, ZIndex = 50,
	}, parent)
	statiqueImage = creer("ImageLabel", {
		Size = UDim2.fromScale(1.5, 1.5), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(256, 256), Image = Interface.Textures.NeigeStatique, ZIndex = 51,
	}, statique)
end

local function majTitre()
	if not cameraActuelle then return end
	titre.Text = string.format("CAM %02d — %s   %s", cameraActuelle.Numero, string.upper(cameraActuelle.Nom), heureTexte)
end

local function appliquerImage(cle: string)
	cleAffichee = cle
	local id = assets[cle] or ""
	image.Image = id
	manquant.Visible = id == ""
	manquant.Text = `IMAGE MANQUANTE\n{cle}`
end

-- Construit l'écran (reconstruit à chaque nouvelle partie)
function CameraView.Init(niveau: any)
	if gui then
		gui:Destroy()
		if connexionScintillement then connexionScintillement:Disconnect() end
		cameraActuelle = nil
		cleAffichee = nil
		enTransition = false
	end
	for _, piece in niveau.Pieces do
		assets[piece.Base.Cle] = piece.Base.Image
		for _, a in piece.Anomalies do
			assets[a.Cle] = a.Image
		end
	end

	gui = creer("ScreenGui", {
		Name = "EcranCamera", IgnoreGuiInset = true, ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 1,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))

	creer("Frame", { Name = "Fond", Size = pleinEcran(), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 1 }, gui)
	image = creer("ImageLabel", {
		Name = "Image", Size = pleinEcran(), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit, ImageColor3 = Interface.Filtre.TeinteImage, ZIndex = 2,
	}, gui)
	manquant = creer("TextLabel", {
		Name = "Manquant", Size = pleinEcran(), BackgroundColor3 = Color3.fromRGB(18, 22, 18),
		BorderSizePixel = 0, Font = Interface.Hud.Police, TextSize = 28, TextColor3 = Color3.fromRGB(120, 140, 120),
		Visible = false, ZIndex = 2,
	}, gui)

	local filtre = creer("Frame", { Name = "Filtre", Size = pleinEcran(), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 }, gui)
	construireBruit(filtre)
	construireScanlines(filtre)
	construireVignette(filtre)
	construireScintillement(filtre)
	construireHud(gui)
	Echelle.Appliquer(titre)
	Echelle.Appliquer(viesLabel)
	construireStatique(gui)
end

-- Neige statique plein écran pendant `duree` ; `pendant` est appelé quand l'écran est couvert
function CameraView.FlashStatique(duree: number, pendant: (() -> ())?)
	if enTransition then
		if pendant then pendant() end
		return
	end
	enTransition = true
	statique.Visible = true
	Audio.Jouer("StatiqueCamera")
	if pendant then pendant() end
	local rng = Random.new()
	local fin = os.clock() + duree
	while os.clock() < fin do
		statique.BackgroundColor3 = Color3.fromHSV(0, 0, rng:NextNumber(0.25, 0.6))
		statiqueImage.Position = UDim2.fromOffset(-rng:NextInteger(0, 255), -rng:NextInteger(0, 255))
		task.wait()
	end
	statique.Visible = false
	enTransition = false
end

-- Changement de caméra par le joueur : coupure de neige statique (~0,2 s)
function CameraView.Afficher(camera: any, cle: string)
	CameraView.FlashStatique(Reglages.Camera.DureeTransitionStatique, function()
		cameraActuelle = camera
		appliquerImage(cle)
		majTitre()
	end)
end

-- À n'appeler QUE quand l'écran est masqué (noir du clignement / statique) : règle d'or
function CameraView.Synchroniser(cle: string)
	if cle ~= cleAffichee then
		appliquerImage(cle)
	end
end

function CameraView.GetCleAffichee(): string?
	return cleAffichee
end

function CameraView.SetVies(vies: number, banque: number, mode: string)
	local texte = "VIES " .. string.rep("■ ", vies)
	if mode == "Coop" then
		texte ..= `  ·  BANQUE {banque}`
	end
	if vies <= 0 then
		texte = "ÉLIMINÉ — SPECTATEUR"
	end
	viesLabel.Text = texte
end

function CameraView.SetVisible(visible: boolean)
	gui.Enabled = visible
end

function CameraView.SetHeure(heure: number, minute: number)
	heureTexte = string.format("%02d:%02d", heure, minute)
	majTitre()
end

function CameraView.GetGui(): ScreenGui
	return gui
end

return CameraView
