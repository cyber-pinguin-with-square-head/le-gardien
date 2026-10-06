--!strict
-- Chapitres et jours (menu « Jouer »). Un chapitre = un niveau (Config/Niveaux).
-- Chaque chapitre a 3 jours ; le jour fixe la difficulté.

export type Jour = { Numero: number, Difficulte: string }
export type Chapitre = {
	Id: string,
	Numero: number,
	Nom: string,
	Niveau: string, -- nom du module dans Config/Niveaux
	Disponible: boolean,
	ImageFond: string, -- clé d'image du niveau affichée derrière le choix
	Jours: { Jour },
}

local JOURS_STANDARD: { Jour } = {
	{ Numero = 1, Difficulte = "Facile" },
	{ Numero = 2, Difficulte = "Normal" },
	{ Numero = 3, Difficulte = "Difficile" },
}

local Chapitres: { Chapitre } = {
	{
		Id = "Maison", Numero = 1, Nom = "LA MAISON", Niveau = "Maison", Disponible = true,
		ImageFond = "Porche_Base", Jours = JOURS_STANDARD,
	},
	{
		-- Teaser : pas encore de niveau
		Id = "Inconnu", Numero = 2, Nom = "???", Niveau = "", Disponible = false,
		ImageFond = "", Jours = {},
	},
}

local Module = {}
Module.Liste = Chapitres

function Module.Get(id: string): Chapitre?
	for _, c in Chapitres do
		if c.Id == id then return c end
	end
	return nil
end

function Module.GetJour(chapitre: Chapitre, numero: number): Jour?
	for _, j in chapitre.Jours do
		if j.Numero == numero then return j end
	end
	return nil
end

return Module
