--!strict
-- Salle d'attente coop (charte §10) : code à partager, joueurs (max 4), l'hôte choisit
-- le chapitre et le jour puis lance la nuit. Même style que le menu.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Interface = require(Config:WaitForChild("Interface"))
local Chapitres = require(Config:WaitForChild("Chapitres"))
local Difficultes = require(Config:WaitForChild("Difficultes"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Echelle = require(script.Parent:WaitForChild("Echelle"))

local SalonUI = {}

local POLICE = Interface.Hud.Police
local BLANC = Color3.fromRGB(220, 220, 220)
local ROUGE = Interface.Menu.CouleurSurvol

local gui: ScreenGui
local codeLabel: TextLabel
local listeJoueurs: Frame
local choixHote: Frame
local attente: TextLabel
local chapitreLabel: TextLabel
local boutonsJours: { TextButton } = {}
local chapitreIndex = 1
local jourChoisi = 1

local function creer(classe: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(classe)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function texte(parent: Instance, t: string, taille: number, props: { [string]: any }?): TextLabel
	local l = creer("TextLabel", {
		BackgroundTransparency = 1, Font = POLICE, TextSize = taille, TextColor3 = BLANC, Text = t,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, taille + 10),
	}, parent)
	for k, v in props or {} do (l :: any)[k] = v end
	return l
end

local function bouton(parent: Instance, t: string, taille: number, props: { [string]: any }, action: () -> ()): TextButton
	local b = creer("TextButton", {
		BackgroundTransparency = 1, Font = POLICE, TextSize = taille, TextColor3 = BLANC, Text = t, AutoButtonColor = false,
	}, parent)
	for k, v in props do (b :: any)[k] = v end
	b.MouseEnter:Connect(function() b.TextColor3 = ROUGE end)
	b.MouseLeave:Connect(function() b:SetAttribute("_", nil) b.TextColor3 = if b:GetAttribute("Choisi") then ROUGE else BLANC end)
	b.Activated:Connect(action)
	return b
end

local function majChoix()
	local c = Chapitres.Liste[chapitreIndex]
	chapitreLabel.Text = `CHAPITRE {c.Numero} — {c.Nom}`
	for i, b in boutonsJours do
		local j = c.Jours[i]
		b.Visible = j ~= nil
		if j then
			local d = Difficultes.Liste[j.Difficulte]
			b.Text = `JOUR {j.Numero}  ·  {string.upper(d.Nom)}`
			b:SetAttribute("Choisi", j.Numero == jourChoisi)
			b.TextColor3 = if j.Numero == jourChoisi then ROUGE else BLANC
		end
	end
end

function SalonUI.Init()
	if gui then return end
	gui = creer("ScreenGui", {
		Name = "Salon", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 30, Enabled = false,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))
	creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 6), BorderSizePixel = 0 }, gui)
	for i = 0, 119 do
		creer("Frame", {
			Size = UDim2.new(1, 0, 0.4 / 120, 0), Position = UDim2.fromScale(0, i / 120),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 2,
		}, gui)
	end

	texte(gui, "SALLE D'ATTENTE", 48, { Position = UDim2.fromOffset(70, 60), Size = UDim2.fromOffset(700, 60), Font = Enum.Font.SpecialElite, ZIndex = 5 })
	codeLabel = texte(gui, "", 30, { Position = UDim2.fromOffset(70, 130), Size = UDim2.fromOffset(700, 40), TextColor3 = Color3.fromRGB(235, 225, 190), ZIndex = 5 })
	texte(gui, "Partagez ce code à vos amis : menu > Rejoindre une partie.", 16, {
		Position = UDim2.fromOffset(70, 172), Size = UDim2.fromOffset(700, 22), TextTransparency = 0.45, ZIndex = 5,
	})

	-- Liste des joueurs (4 emplacements)
	listeJoueurs = creer("Frame", { Position = UDim2.fromOffset(70, 230), Size = UDim2.fromOffset(420, 200), BackgroundTransparency = 1, ZIndex = 5 }, gui)
	creer("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, listeJoueurs)

	-- Choix de l'hôte
	choixHote = creer("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -70, 0, 230), Size = UDim2.fromOffset(520, 320),
		BackgroundTransparency = 1, ZIndex = 5,
	}, gui)
	local ligneChapitre = creer("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 5 }, choixHote)
	bouton(ligneChapitre, "<", 36, { Size = UDim2.fromOffset(40, 50), ZIndex = 6 }, function()
		chapitreIndex = (chapitreIndex - 2) % #Chapitres.Liste + 1
		jourChoisi = 1
		majChoix()
	end)
	chapitreLabel = texte(ligneChapitre, "", 24, {
		Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -80, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.SpecialElite, ZIndex = 6,
	})
	bouton(ligneChapitre, ">", 36, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(40, 50), ZIndex = 6 }, function()
		chapitreIndex = chapitreIndex % #Chapitres.Liste + 1
		jourChoisi = 1
		majChoix()
	end)
	for i = 1, 3 do
		local b = bouton(choixHote, "", 24, { Position = UDim2.fromOffset(0, 60 + (i - 1) * 44), Size = UDim2.new(1, 0, 0, 40), ZIndex = 6 }, function()
			jourChoisi = i
			majChoix()
		end)
		boutonsJours[i] = b
	end
	local lancer = bouton(choixHote, "[ LANCER LA NUIT ]", 30, {
		Position = UDim2.fromOffset(0, 210), Size = UDim2.new(1, 0, 0, 56), Font = Enum.Font.SpecialElite, ZIndex = 6,
	}, function()
		local c = Chapitres.Liste[chapitreIndex]
		if c.Disponible then
			Remotes.Get("LancerPartie"):FireServer(c.Id, jourChoisi)
		end
	end)
	creer("UIStroke", { Color = Color3.fromRGB(150, 30, 30), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, lancer)

	Echelle.Appliquer(listeJoueurs)
	Echelle.Appliquer(choixHote)
	attente = texte(gui, "En attente de l'hôte…", 24, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -70, 0, 240), Size = UDim2.fromOffset(520, 34),
		TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = 0.3, ZIndex = 5,
	})

	bouton(gui, "< QUITTER", 24, {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 70, 1, -50), Size = UDim2.fromOffset(200, 40),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
	}, function()
		Remotes.Get("QuitterSalon"):FireServer()
	end)

	majChoix()
end

function SalonUI.Afficher(visible: boolean, etat: any?)
	gui.Enabled = visible
	if not visible or not etat then return end
	codeLabel.Text = `CODE : {etat.Code}`
	for _, c in listeJoueurs:GetChildren() do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	for i = 1, etat.JoueursMax do
		local j = etat.Joueurs[i]
		texte(listeJoueurs, if j then (if j.Hote then "★ " else "• ") .. j.Nom else "— libre —", 24, {
			LayoutOrder = i, TextTransparency = if j then 0 else 0.6, ZIndex = 6,
		})
	end
	choixHote.Visible = etat.EstHote
	attente.Visible = not etat.EstHote
end

return SalonUI
