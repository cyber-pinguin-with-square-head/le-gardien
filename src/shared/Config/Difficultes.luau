--!strict
-- Difficultés (charte section 7). Valeurs marquées PROVISOIRE = à équilibrer / confirmer.

export type Difficulte = {
	Id: string,
	Nom: string,
	Vies: number,
	NombreCameras: number, -- pièces jouées dans la partie
	PiecesAleatoires: boolean, -- true = tirage parmi les pièces jouables
	SeuilMort: number, -- pièces anormales simultanées => screamer (jamais affiché)
	IntervalleAnomalieMin: number, -- secondes entre deux tentatives d'apparition (PROVISOIRE)
	IntervalleAnomalieMax: number,
}

local Difficultes: { [string]: Difficulte } = {
	Facile = {
		Id = "Facile", Nom = "Facile",
		Vies = 5, NombreCameras = 8, PiecesAleatoires = true, SeuilMort = 6,
		IntervalleAnomalieMin = 40, IntervalleAnomalieMax = 60, -- PROVISOIRE
	},
	Normal = {
		Id = "Normal", Nom = "Normal",
		Vies = 3, NombreCameras = 10, -- 10 retenu, à confirmer (charte §12)
		PiecesAleatoires = true, SeuilMort = 6,
		IntervalleAnomalieMin = 30, IntervalleAnomalieMax = 45, -- PROVISOIRE
	},
	Difficile = {
		Id = "Difficile", Nom = "Difficile",
		Vies = 3, NombreCameras = 12, PiecesAleatoires = false, SeuilMort = 6,
		IntervalleAnomalieMin = 20, IntervalleAnomalieMax = 35, -- PROVISOIRE
	},
}

-- Ordre d'affichage dans le menu
local ORDRE = { "Facile", "Normal", "Difficile" }

return {
	Liste = Difficultes,
	Ordre = ORDRE,
	ParDefaut = "Normal",
}
