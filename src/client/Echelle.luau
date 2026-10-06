--!strict
-- Adapte la taille de l'interface à l'écran (téléphone, tablette, grand écran).
-- Référence : 1280x720. On ajoute un UIScale aux blocs d'interface (pas aux fonds plein écran).

local Workspace = game:GetService("Workspace")

local Echelle = {}

local MIN, MAX = 0.55, 1.4
local echelles: { UIScale } = {}

local function calculer(): number
	local camera = Workspace.CurrentCamera
	if not camera then return 1 end
	local v = camera.ViewportSize
	return math.clamp(math.min(v.X / 1280, v.Y / 720), MIN, MAX)
end

function Echelle.Appliquer(objet: GuiObject)
	local u = Instance.new("UIScale")
	u.Scale = calculer()
	u.Parent = objet
	table.insert(echelles, u)
end

local function maj()
	local e = calculer()
	for i = #echelles, 1, -1 do
		local u = echelles[i]
		if u.Parent then
			u.Scale = e
		else
			table.remove(echelles, i)
		end
	end
end

local function brancher()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(maj)
	end
	maj()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(brancher)
brancher()

return Echelle
