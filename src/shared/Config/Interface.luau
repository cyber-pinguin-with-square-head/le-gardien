--!strict
-- Réglages visuels de l'écran caméra (charte §4 et §9).
-- Textures générées dans Assets/UI/ : IDs à remplir après upload (vide = repli en code).

local A_REMPLIR = ""

return {
	Textures = {
		Bruit = { A_REMPLIR, A_REMPLIR, A_REMPLIR }, -- Assets/UI/Bruit1..3.png
		NeigeStatique = A_REMPLIR, -- Assets/UI/NeigeStatique.png
		Vignette = A_REMPLIR, -- Assets/UI/Vignette.png
	},

	Filtre = {
		BruitTransparence = 0.88, -- grain : plus haut = plus discret
		BruitVitesse = 0.05, -- secondes entre deux images de grain
		ScanlinesNombre = 160,
		ScanlinesTransparence = 0.82,
		VignetteTransparenceRepli = 0.35, -- vignette en dégradé si pas de texture
		ScintillementAmplitude = 0.04, -- variation de luminosité
		TeinteImage = Color3.fromRGB(215, 230, 215), -- léger vert caméra
	},

	Hud = {
		Police = Enum.Font.Code,
		CouleurTexte = Color3.fromRGB(230, 230, 230),
		CouleurRec = Color3.fromRGB(220, 30, 30),
		RecPeriode = 0.6, -- clignotement du point REC
	},

	Panneau = {
		Colonnes = 3,
		TailleBouton = UDim2.fromOffset(78, 40),
		Espacement = 6,
		CouleurBouton = Color3.fromRGB(25, 25, 25),
		CouleurActive = Color3.fromRGB(70, 110, 70),
	},
}
