--!strict
-- Panneau de caméras en bas à droite (charte §9) : uniquement les caméras de la partie,
-- dans l'ordre mélangé envoyé par le serveur.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Interface = require(Config:WaitForChild("Interface"))

local CameraPanel = {}

local boutons: { [string]: TextButton } = {}

function CameraPanel.Construire(parent: Instance, cameras: { any }, surChoix: (any) -> ())
	local p = Interface.Panneau
	local cadre = Instance.new("Frame")
	cadre.Name = "PanneauCameras"
	cadre.AnchorPoint = Vector2.new(1, 1)
	cadre.Position = UDim2.new(1, -20, 1, -20)
	cadre.AutomaticSize = Enum.AutomaticSize.XY
	cadre.BackgroundColor3 = Color3.new(0, 0, 0)
	cadre.BackgroundTransparency = 0.4
	cadre.BorderSizePixel = 0
	cadre.ZIndex = 20
	cadre.Parent = parent

	local pad = Instance.new("UIPadding")
	for _, cote in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(pad :: any)[cote] = UDim.new(0, p.Espacement)
	end
	pad.Parent = cadre

	local grille = Instance.new("UIGridLayout")
	grille.CellSize = p.TailleBouton
	grille.CellPadding = UDim2.fromOffset(p.Espacement, p.Espacement)
	grille.FillDirectionMaxCells = p.Colonnes
	grille.SortOrder = Enum.SortOrder.LayoutOrder
	grille.Parent = cadre

	for _, cam in cameras do
		local b = Instance.new("TextButton")
		b.Name = cam.IdPiece
		b.LayoutOrder = cam.Numero
		b.BackgroundColor3 = p.CouleurBouton
		b.BorderSizePixel = 0
		b.Font = Interface.Hud.Police
		b.TextSize = 18
		b.TextColor3 = Interface.Hud.CouleurTexte
		b.Text = string.format("CAM %02d", cam.Numero)
		b.AutoButtonColor = true
		b.ZIndex = 21
		b.Parent = cadre
		b.Activated:Connect(function()
			surChoix(cam)
		end)
		boutons[cam.IdPiece] = b
	end
end

function CameraPanel.SetActive(idPiece: string)
	for id, b in boutons do
		b.BackgroundColor3 = if id == idPiece then Interface.Panneau.CouleurActive else Interface.Panneau.CouleurBouton
	end
end

return CameraPanel
