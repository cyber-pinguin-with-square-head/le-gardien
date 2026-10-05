--!strict
-- Bouton ANOMALIE + 3 choix + phase d'analyse (charte §5). Le client n'envoie que le type ;
-- le serveur décide du résultat.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Reglages = require(Config:WaitForChild("Reglages"))
local Interface = require(Config:WaitForChild("Interface"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ReportUI = {}

-- Appelé à la fin de l'analyse (le client masque l'écran pour resynchroniser l'image)
ReportUI.SurFin = function(_info: any) end

local CHOIX = {
	{ Type = "ObjetAjoute", Texte = "OBJET AJOUTÉ" },
	{ Type = "ObjetRetire", Texte = "OBJET RETIRÉ" },
	{ Type = "AnomalieVisible", Texte = "ANOMALIE VISIBLE" },
}

local MESSAGES = {
	Correct = { "ANOMALIE CORRIGÉE", Color3.fromRGB(120, 220, 120) },
	Erreur = { "ERREUR — UNE VIE PERDUE", Color3.fromRGB(230, 60, 60) },
	DejaTraite = { "DÉJÀ TRAITÉE", Color3.fromRGB(200, 200, 200) },
	RienTrouve = { "AUCUNE ANOMALIE DÉTECTÉE", Color3.fromRGB(200, 200, 200) },
}

local bouton: TextButton
local choixCadre: Frame
local analyse: Frame
local analyseTexte: TextLabel
local resultat: TextLabel
local enAnalyse = false
local actif = true

local function style(b: TextButton, texte: string)
	b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	b.BackgroundTransparency = 0.15
	b.BorderSizePixel = 0
	b.Font = Interface.Hud.Police
	b.TextSize = 20
	b.TextColor3 = Interface.Hud.CouleurTexte
	b.Text = texte
	local trait = Instance.new("UIStroke")
	trait.Color = Color3.fromRGB(150, 30, 30)
	trait.Thickness = 2
	trait.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trait.Parent = b
end

function ReportUI.Init(parent: Instance)
	bouton = Instance.new("TextButton")
	bouton.Name = "BoutonAnomalie"
	bouton.AnchorPoint = Vector2.new(0, 1)
	bouton.Position = UDim2.new(0, 20, 1, -20)
	bouton.Size = UDim2.fromOffset(200, 52)
	bouton.ZIndex = 20
	style(bouton, "⚠ ANOMALIE")
	bouton.Parent = parent

	choixCadre = Instance.new("Frame")
	choixCadre.Name = "Choix"
	choixCadre.AnchorPoint = Vector2.new(0, 1)
	choixCadre.Position = UDim2.new(0, 20, 1, -82)
	choixCadre.Size = UDim2.fromOffset(240, 3 * 46 + 2 * 6)
	choixCadre.BackgroundTransparency = 1
	choixCadre.Visible = false
	choixCadre.ZIndex = 20
	choixCadre.Parent = parent
	local liste = Instance.new("UIListLayout")
	liste.Padding = UDim.new(0, 6)
	liste.Parent = choixCadre

	for _, c in CHOIX do
		local b = Instance.new("TextButton")
		b.Name = c.Type
		b.Size = UDim2.new(1, 0, 0, 46)
		b.ZIndex = 21
		style(b, c.Texte)
		b.Parent = choixCadre
		b.Activated:Connect(function()
			choixCadre.Visible = false
			if enAnalyse or not actif then return end
			Remotes.Get("Signaler"):FireServer(c.Type)
		end)
	end

	bouton.Activated:Connect(function()
		if enAnalyse or not actif then return end
		choixCadre.Visible = not choixCadre.Visible
	end)

	-- Écran d'analyse : voile + texte qui clignote
	analyse = Instance.new("Frame")
	analyse.Name = "Analyse"
	analyse.Size = UDim2.fromScale(1, 1)
	analyse.BackgroundColor3 = Color3.new(0, 0, 0)
	analyse.BackgroundTransparency = 0.55
	analyse.BorderSizePixel = 0
	analyse.Visible = false
	analyse.ZIndex = 30
	analyse.Parent = parent
	analyseTexte = Instance.new("TextLabel")
	analyseTexte.Size = UDim2.fromScale(1, 1)
	analyseTexte.BackgroundTransparency = 1
	analyseTexte.Font = Interface.Hud.Police
	analyseTexte.TextSize = 32
	analyseTexte.TextColor3 = Interface.Hud.CouleurTexte
	analyseTexte.Text = "ANALYSE EN COURS"
	analyseTexte.ZIndex = 31
	analyseTexte.Parent = analyse

	resultat = Instance.new("TextLabel")
	resultat.AnchorPoint = Vector2.new(0.5, 0)
	resultat.Position = UDim2.new(0.5, 0, 0, 90)
	resultat.Size = UDim2.fromOffset(600, 40)
	resultat.BackgroundTransparency = 1
	resultat.Font = Interface.Hud.Police
	resultat.TextSize = 28
	resultat.TextStrokeTransparency = 0.4
	resultat.Visible = false
	resultat.ZIndex = 32
	resultat.Parent = parent

	Remotes.Get("ResultatSignalement").OnClientEvent:Connect(function(info)
		if info.Etape == "Analyse" then
			enAnalyse = true
			analyse.Visible = true
			task.spawn(function()
				local points = 0
				while enAnalyse do
					points = (points + 1) % 4
					analyseTexte.Text = "ANALYSE EN COURS" .. string.rep(".", points)
					analyse.BackgroundTransparency = 0.5 + math.random() * 0.15
					task.wait(0.25)
				end
			end)
		elseif info.Etape == "Fin" then
			ReportUI.SurFin(info)
			enAnalyse = false
			analyse.Visible = false
			local m = MESSAGES[info.Resultat] or MESSAGES.RienTrouve
			resultat.Text = m[1]
			resultat.TextColor3 = m[2]
			resultat.Visible = true
			task.delay(Reglages.Signalement.DureeAffichageResultat, function()
				resultat.Visible = false
			end)
		end
	end)
end

function ReportUI.EnAnalyse(): boolean
	return enAnalyse
end

function ReportUI.SetActif(valeur: boolean)
	actif = valeur
	bouton.Visible = valeur
	if not valeur then choixCadre.Visible = false end
end

return ReportUI
