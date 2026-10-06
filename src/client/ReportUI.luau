--!strict
-- Bouton ANOMALIE + 3 choix + phase d'analyse (charte §5). Le client n'envoie que le type ;
-- le serveur décide du résultat.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Reglages = require(Config:WaitForChild("Reglages"))
local Interface = require(Config:WaitForChild("Interface"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Echelle = require(script.Parent:WaitForChild("Echelle"))

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
local remoteBranche = false

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
	style(bouton, if game:GetService("UserInputService").KeyboardEnabled then "⚠ ANOMALIE  [E]" else "⚠ ANOMALIE")
	bouton.Parent = parent
	Echelle.Appliquer(bouton)

	choixCadre = Instance.new("Frame")
	choixCadre.Name = "Choix"
	-- Enfant du bouton : suit sa position et son échelle (mobile)
	choixCadre.AnchorPoint = Vector2.new(0, 1)
	choixCadre.Position = UDim2.new(0, 0, 0, -10)
	choixCadre.Size = UDim2.fromOffset(240, 3 * 46 + 2 * 6)
	choixCadre.BackgroundTransparency = 1
	choixCadre.Visible = false
	choixCadre.ZIndex = 20
	choixCadre.Parent = bouton
	local liste = Instance.new("UIListLayout")
	liste.SortOrder = Enum.SortOrder.LayoutOrder
	liste.Padding = UDim.new(0, 6)
	liste.Parent = choixCadre

	local clavier = game:GetService("UserInputService").KeyboardEnabled
	for i, c in CHOIX do
		local b = Instance.new("TextButton")
		b.Name = c.Type
		b.LayoutOrder = i
		b.Size = UDim2.new(1, 0, 0, 46)
		b.ZIndex = 21
		style(b, if clavier then `{i} · {c.Texte}` else c.Texte)
		b.Parent = choixCadre
		b.Activated:Connect(function()
			ReportUI.Choisir(i)
		end)
	end

	bouton.Activated:Connect(ReportUI.Basculer)

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
	Echelle.Appliquer(resultat)

	enAnalyse = false
	if remoteBranche then return end
	remoteBranche = true
	Remotes.Get("ResultatSignalement").OnClientEvent:Connect(function(info)
		if not analyse.Parent then return end
		if info.Etape == "Analyse" then
			enAnalyse = true
			analyse.Visible = true
			task.spawn(function()
				local points = 0
				while enAnalyse do
					points = (points + 1) % 4
					Audio.Jouer("AnalyseBip")
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
			if info.Resultat == "Correct" then Audio.Jouer("Correct") elseif info.Resultat == "Erreur" then Audio.Jouer("Erreur") end
			resultat.Text = m[1]
			resultat.TextColor3 = m[2]
			resultat.Visible = true
			task.delay(Reglages.Signalement.DureeAffichageResultat, function()
				resultat.Visible = false
			end)
		end
	end)
end

-- Ouvre / ferme les 3 choix (bouton ou touche E)
function ReportUI.Basculer()
	if enAnalyse or not actif or not choixCadre then return end
	Audio.Jouer("Clic")
	choixCadre.Visible = not choixCadre.Visible
end

function ReportUI.ChoixOuverts(): boolean
	return choixCadre ~= nil and choixCadre.Visible
end

-- Envoie le signalement n°i (1 = ajouté, 2 = retiré, 3 = visible)
function ReportUI.Choisir(i: number)
	if not choixCadre then return end
	choixCadre.Visible = false
	local c = CHOIX[i]
	if not c or enAnalyse or not actif then return end
	Audio.Jouer("Clic")
	Remotes.Get("Signaler"):FireServer(c.Type)
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
