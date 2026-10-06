--!strict
-- Sons du jeu. IDs à remplir après upload (vide = silence, rien ne casse).
-- La liste à fournir est dans Manques.txt.

local A_REMPLIR = ""

return {
	-- Effets ponctuels
	StatiqueCamera = { Id = A_REMPLIR, Volume = 0.4 }, -- coupure au changement de caméra
	Clic = { Id = A_REMPLIR, Volume = 0.5 }, -- boutons du menu / panneau
	AnalyseBip = { Id = A_REMPLIR, Volume = 0.4 }, -- pendant l'analyse
	Correct = { Id = A_REMPLIR, Volume = 0.5 }, -- anomalie corrigée
	Erreur = { Id = A_REMPLIR, Volume = 0.6 }, -- vie perdue
	ChangementHeure = { Id = A_REMPLIR, Volume = 0.3 }, -- à chaque heure pile
	Victoire = { Id = A_REMPLIR, Volume = 0.6 }, -- 05:00
	Cassette = { Id = A_REMPLIR, Volume = 0.4 }, -- clic du magnétophone

	-- Boucles
	AmbianceNuit = { Id = A_REMPLIR, Volume = 0.25 }, -- bourdonnement des caméras pendant la nuit
	MusiqueMenu = { Id = A_REMPLIR, Volume = 0.5 },
	MusiqueStress = { Id = A_REMPLIR, Volume = 0.6 }, -- pièce secrète
}
