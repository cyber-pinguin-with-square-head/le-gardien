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

	Menu = {
		-- Images de fond (clés de Maison.luau) qui défilent derrière le menu
		FondCles = { "Porche_Base", "Couloir_Base", "Salon_Base", "Cuisine_Base", "Garage_Base" },
		-- Images « glitch » montrées une fraction de seconde (style FNaF)
		GlitchCles = { "Porche_Visible1", "Garage_Visible1", "Cuisine_Visible1", "Buanderie_Visible1" },
		DureeFond = 7, -- secondes par image de fond
		ChanceGlitch = 0.3, -- chance d'un glitch à chaque changement
		DureeGlitch = 0.12,
		CouleurTitre = Color3.fromRGB(225, 225, 225),
		CouleurSurvol = Color3.fromRGB(200, 40, 40),
	},

	Panneau = {
		Colonnes = 3,
		TailleBouton = UDim2.fromOffset(78, 40),
		Espacement = 6,
		CouleurBouton = Color3.fromRGB(25, 25, 25),
		CouleurActive = Color3.fromRGB(70, 110, 70),
	},
}
