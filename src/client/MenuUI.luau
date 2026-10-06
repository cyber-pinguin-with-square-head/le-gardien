--!strict
-- Menu principal style FNaF (charte §9) : fond caméra qui défile avec glitchs,
-- titre qui grésille, boutons texte. Écrans : principal, chapitre (flèches),
-- jours (1 facile / 2 normal / 3 difficile), consignes, options, crédits.
-- Héberger / Rejoindre : coop via serveurs réservés (voir server/LobbySystem).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Interface = require(Config:WaitForChild("Interface"))
local Difficultes = require(Config:WaitForChild("Difficultes"))
local Chapitres = require(Config:WaitForChild("Chapitres"))
local Lore = require(Config:WaitForChild("Lore"))
local Version = require(Shared:WaitForChild("Version"))
local Options = require(script.Parent:WaitForChild("Options"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Echelle = require(script.Parent:WaitForChild("Echelle"))

local MenuUI = {}

-- Appelé quand le joueur valide les consignes : (idChapitre, numeroJour)
MenuUI.SurLancer = function(_idChapitre: string, _jour: number) end

local M = Interface.Menu
local POLICE = Interface.Hud.Police
local BLANC = Color3.fromRGB(220, 220, 220)

local gui: ScreenGui
local ecrans: { [string]: Frame } = {}
local fond: ImageLabel
local assets: { [string]: string } = {}
local chapitreIndex = 1
local jourChoisi = 1
local fondFige: string? = nil -- clé d'image imposée (écrans chapitre / jours)
local majReference: () -> () = function() end
local titreMenu: TextLabel
local messageLabel: TextLabel
local rng = Random.new()

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
		BackgroundTransparency = 1, Font = POLICE, TextSize = taille, TextColor3 = BLANC,
		Text = t, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, taille + 10), ZIndex = 6,
	}, parent)
	for k, v in props or {} do
		(l :: any)[k] = v
	end
	return l
end

-- Bouton texte façon FNaF : « >> » et couleur rouge au survol
local function bouton(parent: Instance, t: string, ordre: number, action: () -> ()): TextButton
	local b = creer("TextButton", {
		BackgroundTransparency = 1, Font = POLICE, TextSize = 30, TextColor3 = BLANC, Text = t,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = ordre,
		AutoButtonColor = false, ZIndex = 6,
	}, parent)
	b.MouseEnter:Connect(function()
		b.Text = ">> " .. t
		b.TextColor3 = M.CouleurSurvol
	end)
	b.MouseLeave:Connect(function()
		b.Text = t
		b.TextColor3 = BLANC
	end)
	b.Activated:Connect(function()
		Audio.Jouer("Clic")
		action()
	end)
	return b
end

local function colonne(nom: string, position: UDim2, taille: UDim2): Frame
	local f = creer("Frame", {
		Name = nom, Position = position, Size = taille, BackgroundTransparency = 1, Visible = false, ZIndex = 5,
	}, gui)
	creer("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	Echelle.Appliquer(f)
	ecrans[nom] = f
	return f
end

local function montrer(nom: string)
	for n, f in ecrans do
		f.Visible = n == nom
	end
	-- Sur le choix du chapitre / des jours : fond = image du chapitre, titre caché
	local chapitre = Chapitres.Liste[chapitreIndex]
	local surChapitre = nom == "Chapitre" or nom == "Jours"
	fondFige = if surChapitre then chapitre.ImageFond else nil
	if surChapitre then
		fond.Image = assets[chapitre.ImageFond] or ""
	end
	if titreMenu then titreMenu.Visible = nom ~= "Consignes" and not surChapitre end
end

-- Fond : images de pièces qui défilent, coupées par de la neige et des glitchs
local function animerFond()
	local cles = {}
	for _, c in M.FondCles do
		if (assets[c] or "") ~= "" then table.insert(cles, c) end
	end
	local glitchs = {}
	for _, c in M.GlitchCles do
		if (assets[c] or "") ~= "" then table.insert(glitchs, c) end
	end
	if #cles == 0 then return end
	task.spawn(function()
		while gui.Parent do
			if not fondFige then
				fond.Image = assets[cles[rng:NextInteger(1, #cles)]]
			end
			task.wait(M.DureeFond)
			if #glitchs > 0 and rng:NextNumber() < M.ChanceGlitch then
				local avant = fond.Image
				fond.Image = assets[glitchs[rng:NextInteger(1, #glitchs)]]
				task.wait(M.DureeGlitch)
				fond.Image = avant
				task.wait(0.4)
			end
		end
	end)
end

local function construireDecor()
	creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0 }, gui)
	fond = creer("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop,
		ImageColor3 = Color3.fromRGB(150, 160, 150), ImageTransparency = 0.35, ZIndex = 1,
	}, gui)
	-- Assombrit la gauche, là où est le texte
	local voile = creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2 }, gui)
	creer("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.55, 0.45), NumberSequenceKeypoint.new(1, 0.85) }),
	}, voile)
	-- Scanlines
	for i = 0, 119 do
		creer("Frame", {
			Size = UDim2.new(1, 0, 0.4 / 120, 0), Position = UDim2.fromScale(0, i / 120),
			BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3,
		}, gui)
	end
	-- Scintillement global
	local scint = creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 }, gui)
	local connexion
	connexion = RunService.RenderStepped:Connect(function()
		if not gui.Parent then connexion:Disconnect() return end
		scint.BackgroundTransparency = 1 - rng:NextNumber(0, 0.06)
	end)

	-- Titre qui grésille
	local titre = texte(gui, "LE GARDIEN\nD'ANOMALIES", 64, {
		Position = UDim2.new(0, 70, 0, 60), Size = UDim2.fromOffset(700, 150), TextColor3 = M.CouleurTitre,
		TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 6, Font = Enum.Font.SpecialElite,
	})
	titreMenu = titre
	task.spawn(function()
		while gui.Parent do
			task.wait(rng:NextNumber(0.05, 2.5))
			titre.TextTransparency = rng:NextNumber(0.2, 0.7)
			titre.Position = UDim2.new(0, 70 + rng:NextInteger(-3, 3), 0, 60)
			task.wait(rng:NextNumber(0.03, 0.12))
			titre.TextTransparency = 0
			titre.Position = UDim2.new(0, 70, 0, 60)
		end
	end)

	-- Phrase d'ambiance en bas + version
	local phrase = texte(gui, "", 18, {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 70, 1, -30), Size = UDim2.fromOffset(700, 24),
		TextTransparency = 0.4, ZIndex = 6,
	})
	task.spawn(function()
		while gui.Parent do
			phrase.Text = Lore.PhrasesMenu[rng:NextInteger(1, #Lore.PhrasesMenu)]
			task.wait(9)
		end
	end)
	texte(gui, "v" .. Version.VERSION, 14, {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -16), Size = UDim2.fromOffset(120, 18),
		TextXAlignment = Enum.TextXAlignment.Right, TextTransparency = 0.6, ZIndex = 6,
	})
end

local function construirePrincipal()
	local f = colonne("Principal", UDim2.new(0, 70, 0, 260), UDim2.fromOffset(500, 300))
	bouton(f, "JOUER EN SOLO", 1, function() montrer("Chapitre") end)
	bouton(f, "HÉBERGER UNE PARTIE", 2, function()
		MenuUI.AfficherMessage("Création de la partie…")
		Remotes.Get("Heberger"):FireServer()
	end)
	bouton(f, "REJOINDRE UNE PARTIE", 3, function() montrer("Rejoindre") end)
	bouton(f, "OPTIONS", 4, function() montrer("Options") end)
	bouton(f, "CRÉDITS", 5, function() montrer("Credits") end)
end

-- Gros bouton centré (flèches, jours)
local function grosBouton(parent: Instance, t: string, taille: number, props: { [string]: any }, action: () -> ()): TextButton
	local b = creer("TextButton", {
		BackgroundTransparency = 1, Font = Enum.Font.SpecialElite, TextSize = taille, TextColor3 = BLANC,
		Text = t, AutoButtonColor = false, ZIndex = 8,
	}, parent)
	for k, v in props do (b :: any)[k] = v end
	b.MouseEnter:Connect(function() b.TextColor3 = M.CouleurSurvol end)
	b.MouseLeave:Connect(function() b.TextColor3 = BLANC end)
	b.Activated:Connect(function()
		Audio.Jouer("Clic")
		action()
	end)
	return b
end

-- Choix du chapitre avec des flèches
local function construireChapitre()
	local f = creer("Frame", { Name = "Chapitre", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 7 }, gui)
	ecrans.Chapitre = f
	local numero = texte(f, "", 26, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(600, 36),
		TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 0.3, ZIndex = 8,
	})
	local nom = texte(f, "", 72, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(800, 90),
		TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.SpecialElite, ZIndex = 8,
	})
	local choisir: TextButton

	local function maj()
		local c = Chapitres.Liste[chapitreIndex]
		numero.Text = `CHAPITRE {c.Numero}`
		nom.Text = c.Nom
		choisir.Text = if c.Disponible then "[ CHOISIR ]" else "BIENTÔT"
		choisir.Active = c.Disponible
		fond.Image = assets[c.ImageFond] or ""
		fondFige = c.ImageFond
	end
	local function decaler(d: number)
		chapitreIndex = (chapitreIndex - 1 + d) % #Chapitres.Liste + 1
		maj()
	end

	grosBouton(f, "<", 90, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.2, 0.46), Size = UDim2.fromOffset(100, 120) }, function() decaler(-1) end)
	grosBouton(f, ">", 90, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8, 0.46), Size = UDim2.fromOffset(100, 120) }, function() decaler(1) end)
	choisir = grosBouton(f, "", 30, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(300, 50) }, function()
		if Chapitres.Liste[chapitreIndex].Disponible then montrer("Jours") end
	end)
	grosBouton(f, "< RETOUR", 24, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 70, 1, -70), Size = UDim2.fromOffset(200, 40), TextXAlignment = Enum.TextXAlignment.Left }, function()
		montrer("Principal")
	end)
	f:GetPropertyChangedSignal("Visible"):Connect(function()
		if f.Visible then maj() end
	end)
	maj()
end

-- Les 3 jours du chapitre apparaissent sur le fond
local function construireJours()
	local f = creer("Frame", { Name = "Jours", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 7 }, gui)
	ecrans.Jours = f
	local entete = texte(f, "", 26, {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromOffset(800, 36),
		TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 0.3, ZIndex = 8,
	})
	local rangee: Frame = creer("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(900, 200),
		BackgroundTransparency = 1, ZIndex = 8,
	}, f)
	Echelle.Appliquer(rangee)
	creer("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 40), SortOrder = Enum.SortOrder.LayoutOrder,
	}, rangee)
	local elements: { GuiObject } = {}

	local function construire()
		for _, e in elements do e:Destroy() end
		table.clear(elements)
		local c = Chapitres.Liste[chapitreIndex]
		entete.Text = `CHAPITRE {c.Numero} — {c.Nom}`
		for _, j in c.Jours do
			local d = Difficultes.Liste[j.Difficulte]
			local bloc = creer("Frame", { Size = UDim2.fromOffset(260, 200), BackgroundTransparency = 1, LayoutOrder = j.Numero, ZIndex = 8 }, rangee)
			table.insert(elements, bloc)
			local b = grosBouton(bloc, `JOUR {j.Numero}`, 56, { Size = UDim2.new(1, 0, 0, 80) }, function()
				jourChoisi = j.Numero
				majReference()
				montrer("Consignes")
			end)
			texte(bloc, string.upper(d.Nom), 22, {
				Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8,
			})
			texte(bloc, `{d.Vies} fautes · {d.NombreCameras} caméras`, 16, {
				Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center,
				TextTransparency = 0.45, ZIndex = 8,
			})
			-- Apparition en fondu, l'un après l'autre
			b.TextTransparency = 1
			task.delay(0.15 * j.Numero, function()
				TweenService:Create(b, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
			end)
		end
	end

	grosBouton(f, "< RETOUR", 24, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 70, 1, -70), Size = UDim2.fromOffset(200, 40), TextXAlignment = Enum.TextXAlignment.Left }, function()
		montrer("Chapitre")
	end)
	f:GetPropertyChangedSignal("Visible"):Connect(function()
		if f.Visible then construire() end
	end)
end

-- Note de l'employeur (tutoriel + lore)
local function construireConsignes()
	local C = Lore.Consignes
	local f = creer("Frame", {
		Name = "Consignes", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 760, 0.86, 0), BackgroundColor3 = Color3.fromRGB(14, 14, 14), BackgroundTransparency = 0.05,
		BorderSizePixel = 0, Visible = false, ZIndex = 7,
	}, gui)
	creer("UIStroke", { Color = Color3.fromRGB(90, 90, 90), Thickness = 1 }, f)
	f.Size = UDim2.new(0, 760, 0, 620)
	Echelle.Appliquer(f)
	creer("UIPadding", { PaddingTop = UDim.new(0, 26), PaddingBottom = UDim.new(0, 26), PaddingLeft = UDim.new(0, 34), PaddingRight = UDim.new(0, 34) }, f)
	local defil = creer("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -70), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 8,
	}, f)
	creer("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, defil)

	local lignes: { TextLabel } = {}
	local function ligne(t: string, taille: number, ordre: number, props: { [string]: any }?): TextLabel
		local l = texte(defil, t, taille, { LayoutOrder = ordre, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -10, 0, 0), ZIndex = 9 })
		for k, v in props or {} do (l :: any)[k] = v end
		return l
	end
	local entete = ligne(C.Entete, 26, 1, { Font = Enum.Font.SpecialElite })
	local reference = ligne(C.Reference, 15, 2, { TextTransparency = 0.45 })
	local signature = ligne(C.Signature, 19, 1000, { TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.SpecialElite })
	local paragraphes: { TextLabel } = {}

	-- Remplit la note avec le message du jour choisi
	majReference = function()
		reference.Text = string.gsub(C.Reference, "{JOUR}", tostring(jourChoisi))
		for _, l in paragraphes do l:Destroy() end
		table.clear(paragraphes)
		for i, p in Lore.Intros[jourChoisi] or C.Paragraphes do
			table.insert(paragraphes, ligne(p, 19, 10 + i))
		end
		table.clear(lignes)
		table.insert(lignes, entete)
		table.insert(lignes, reference)
		for _, l in paragraphes do table.insert(lignes, l) end
		table.insert(lignes, signature)
		defil.CanvasPosition = Vector2.zero
	end
	majReference()

	local valider = creer("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(360, 52),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25), BorderSizePixel = 0, Font = POLICE, TextSize = 24,
		TextColor3 = BLANC, Text = C.Bouton, ZIndex = 9,
	}, f)
	creer("UIStroke", { Color = Color3.fromRGB(150, 30, 30), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, valider)
	local retour = creer("TextButton", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromOffset(140, 52),
		BackgroundTransparency = 1, Font = POLICE, TextSize = 20, TextColor3 = BLANC, Text = "< RETOUR",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9,
	}, f)
	retour.Activated:Connect(function() montrer("Jours") end)
	valider.Activated:Connect(function()
		MenuUI.SurLancer(Chapitres.Liste[chapitreIndex].Id, jourChoisi)
	end)

	ecrans.Consignes = f
	-- Apparition ligne par ligne à chaque ouverture
	f:GetPropertyChangedSignal("Visible"):Connect(function()
		if not f.Visible then return end
		valider.Visible = false
		for _, l in lignes do l.TextTransparency = 1 end
		task.spawn(function()
			for _, l in lignes do
				local cible = if l.TextSize == 15 then 0.45 else 0
				TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = cible }):Play()
				task.wait(0.18)
			end
			valider.Visible = true
		end)
	end)
end

local function construireOptions()
	local f = colonne("Options", UDim2.new(0, 70, 0, 260), UDim2.fromOffset(500, 300))
	local volume = texte(f, "", 26, { LayoutOrder = 1 })
	local function maj()
		volume.Text = `VOLUME   {math.floor(Options.Volume * 100)} %`
		Audio.MajVolume()
	end
	maj()
	bouton(f, "+ PLUS FORT", 2, function() Options.ChangerVolume(0.1) maj() end)
	bouton(f, "- MOINS FORT", 3, function() Options.ChangerVolume(-0.1) maj() end)
	bouton(f, "< RETOUR", 10, function() montrer("Principal") end)
end

local function construireCredits()
	local f = colonne("Credits", UDim2.new(0, 70, 0, 260), UDim2.fromOffset(600, 300))
	texte(f, "UN JEU DE AKUMA", 30, { LayoutOrder = 1 })
	texte(f, "Conception, images, histoire : Akuma", 18, { LayoutOrder = 2, TextTransparency = 0.3 })
	texte(f, "Développé avec Roblox Studio", 18, { LayoutOrder = 3, TextTransparency = 0.3 })
	bouton(f, "< RETOUR", 10, function() montrer("Principal") end)
end

local function construireRejoindre()
	local f = colonne("Rejoindre", UDim2.new(0, 70, 0, 260), UDim2.fromOffset(600, 320))
	texte(f, "CODE DE LA PARTIE", 22, { LayoutOrder = 1, TextTransparency = 0.3 })
	local saisie = creer("TextBox", {
		Size = UDim2.fromOffset(320, 56), BackgroundColor3 = Color3.fromRGB(15, 15, 15), BorderSizePixel = 0,
		Font = POLICE, TextSize = 34, TextColor3 = BLANC, PlaceholderText = "ABC123",
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90), Text = "", ClearTextOnFocus = false, LayoutOrder = 2, ZIndex = 6,
	}, f)
	creer("UIStroke", { Color = Color3.fromRGB(150, 30, 30), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, saisie)
	saisie:GetPropertyChangedSignal("Text"):Connect(function()
		local propre = string.sub(string.upper(saisie.Text), 1, 6)
		if propre ~= saisie.Text then saisie.Text = propre end
	end)
	bouton(f, "REJOINDRE", 3, function()
		MenuUI.AfficherMessage("Recherche de la partie…")
		Remotes.Get("Rejoindre"):FireServer(saisie.Text)
	end)
	bouton(f, "< RETOUR", 10, function() montrer("Principal") end)
end

-- Message d'état du lobby (création, erreurs…) en bas de l'écran
function MenuUI.AfficherMessage(t: string)
	if not messageLabel then return end
	messageLabel.Text = t
	messageLabel.Visible = true
	local actuel = t
	task.delay(5, function()
		if messageLabel.Text == actuel then messageLabel.Visible = false end
	end)
end

function MenuUI.Init(niveau: any)
	if gui then return end
	for _, piece in niveau.Pieces do
		assets[piece.Base.Cle] = piece.Base.Image
		for _, a in piece.Anomalies do
			assets[a.Cle] = a.Image
		end
	end

	gui = creer("ScreenGui", {
		Name = "Menu", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 30,
		ZIndexBehavior = Enum.ZIndexBehavior.Global, Enabled = false,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))

	construireDecor()
	construirePrincipal()
	construireChapitre()
	construireJours()
	construireConsignes()
	construireOptions()
	construireCredits()
	construireRejoindre()
	messageLabel = texte(gui, "", 20, {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.fromOffset(700, 28),
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(235, 225, 190), Visible = false, ZIndex = 12,
	})
	Remotes.Get("MessageLobby").OnClientEvent:Connect(MenuUI.AfficherMessage)
	animerFond()

end

function MenuUI.Afficher(visible: boolean)
	gui.Enabled = visible
	if visible then montrer("Principal") end
	Audio.Boucle("MusiqueMenu", visible)
end

return MenuUI
