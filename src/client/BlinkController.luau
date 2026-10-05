--!strict
-- Clignement d'œil réaliste (charte §6) : deux paupières aux bords flous, fermeture rapide,
-- noir complet bref, réouverture plus lente. Clignements naturels aléatoires + clignements
-- demandés par le serveur (le noir est alors prolongé jusqu'à son feu vert, synchro coop).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Reglages = require(Shared:WaitForChild("Config"):WaitForChild("Reglages"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BlinkController = {}

local actif = false
local occupe = false
local noir = false
local enFile: { number } = {} -- jetons serveur pas encore servis
local courants: { number } = {} -- jetons pour lesquels on tient les yeux fermés
local liberes: { [number]: boolean } = {}
local surNoir: { () -> () } = {}
local rng = Random.new()

local haut: Frame, bas: Frame, solide: Frame, voile: Frame

local OUVERT_HAUT, FERME_HAUT = UDim2.fromScale(0, 0), UDim2.fromScale(0, 0.62)
local OUVERT_BAS, FERME_BAS = UDim2.fromScale(0, 1), UDim2.fromScale(0, 0.38)

local function construire()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Paupieres"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local function paupiere(nom: string, ancre: Vector2, pos: UDim2, degrade: NumberSequence): Frame
		local f = Instance.new("Frame")
		f.Name = nom
		f.AnchorPoint = ancre
		f.Position = pos
		f.Size = UDim2.fromScale(1, 0.62)
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.Parent = gui
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = degrade
		g.Parent = f
		return f
	end
	-- Bords flous : le bord libre de chaque paupière est en dégradé
	haut = paupiere("Haut", Vector2.new(0, 1), OUVERT_HAUT,
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.82, 0), NumberSequenceKeypoint.new(1, 1) }))
	bas = paupiere("Bas", Vector2.new(0, 0), OUVERT_BAS,
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.18, 0), NumberSequenceKeypoint.new(1, 0) }))

	voile = Instance.new("Frame") -- légère baisse de luminosité autour du clignement
	voile.Name = "Voile"
	voile.Size = UDim2.fromScale(1, 1)
	voile.BackgroundColor3 = Color3.new(0, 0, 0)
	voile.BackgroundTransparency = 1
	voile.BorderSizePixel = 0
	voile.Parent = gui

	solide = Instance.new("Frame") -- garantit le noir à 100 %
	solide.Name = "Noir"
	solide.Size = UDim2.fromScale(1, 1)
	solide.BackgroundColor3 = Color3.new(0, 0, 0)
	solide.BorderSizePixel = 0
	solide.Visible = false
	solide.ZIndex = 5
	solide.Parent = gui
end

local function tween(inst: Instance, duree: number, style: Enum.EasingStyle, dir: Enum.EasingDirection, props: { [string]: any })
	TweenService:Create(inst, TweenInfo.new(duree, style, dir), props):Play()
end

local function toutLibere(): boolean
	for _, j in courants do
		if not liberes[j] then return false end
	end
	return true
end

local function cycle()
	occupe = true
	local c = Reglages.Clignement

	-- Fermeture rapide
	tween(haut, c.DureeFermeture, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = FERME_HAUT })
	tween(bas, c.DureeFermeture, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Position = FERME_BAS })
	tween(voile, c.DureeFermeture, Enum.EasingStyle.Sine, Enum.EasingDirection.In, { BackgroundTransparency = 1 - c.BaisseLuminosite })
	task.wait(c.DureeFermeture)

	-- Noir complet : on prévient le serveur pour les jetons en attente
	solide.Visible = true
	noir = true
	courants = enFile
	enFile = {}
	for _, j in courants do
		Remotes.Get("YeuxFermes"):FireServer(j)
	end
	for _, cb in surNoir do task.spawn(cb) end

	task.wait(c.DureeNoir)
	local limite = os.clock() + c.NoirMaxAttente
	while #courants > 0 and not toutLibere() and os.clock() < limite do
		task.wait()
	end
	for _, cb in surNoir do cb() end -- dernière synchro juste avant de rouvrir
	for _, j in courants do liberes[j] = nil end
	courants = {}
	noir = false
	solide.Visible = false

	-- Réouverture plus lente
	tween(haut, c.DureeOuverture, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Position = OUVERT_HAUT })
	tween(bas, c.DureeOuverture, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { Position = OUVERT_BAS })
	tween(voile, c.DureeOuverture * 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
	task.wait(c.DureeOuverture)
	occupe = false

	-- Une demande serveur est arrivée pendant le clignement : on recommence
	if #enFile > 0 then
		task.spawn(cycle)
	end
end

local function cligner()
	if not occupe then
		task.spawn(cycle)
	end
end

function BlinkController.Init()
	construire()

	Remotes.Get("DemanderClignement").OnClientEvent:Connect(function(jeton: number)
		if noir then
			-- Déjà dans le noir : on confirme tout de suite et on prolonge
			table.insert(courants, jeton)
			Remotes.Get("YeuxFermes"):FireServer(jeton)
			return
		end
		table.insert(enFile, jeton)
		task.delay(rng:NextNumber(0, Reglages.Clignement.DelaiMaxForce), cligner)
	end)

	Remotes.Get("FinClignement").OnClientEvent:Connect(function(jeton: number)
		liberes[jeton] = true
	end)

	-- Clignements naturels, jamais réguliers, parfois doubles
	task.spawn(function()
		local c = Reglages.Clignement
		while true do
			task.wait(rng:NextNumber(c.IntervalleMin, c.IntervalleMax))
			if actif and not occupe then
				cycle()
				if rng:NextNumber() < c.ChanceDoubleClignement then
					task.wait(c.PauseDoubleClignement)
					if actif then cycle() end
				end
			end
		end
	end)
end

function BlinkController.SetActif(valeur: boolean)
	actif = valeur
end

function BlinkController.EstNoir(): boolean
	return noir
end

-- Fonction appelée à chaque noir complet (pour synchroniser l'image affichée)
function BlinkController.SurNoir(cb: () -> ())
	table.insert(surNoir, cb)
end

return BlinkController
