--!strict
-- Réglages globaux. Aucune valeur d'équilibrage ne doit être en dur dans les systèmes.
-- PROVISOIRE = proposition en attente de validation d'Akuma (charte §12).

local Reglages = {}

Reglages.NiveauParDefaut = "Maison"

-- Nuit (charte §7 / §12)
Reglages.Nuit = {
	HeureDebut = 23, -- 23:00
	HeureFin = 5, -- 05:00
	DureeReelleSecondes = 540, -- validé : 1h de jeu = 1 min 30 => 9 min
}

-- Clignement d'œil (charte §6) — durées en secondes
Reglages.Clignement = {
	DureeFermeture = 0.09, -- 80-100 ms
	DureeNoir = 0.06, -- 40-80 ms
	DureeOuverture = 0.15, -- 120-180 ms
	IntervalleMin = 3, -- clignements naturels toutes les 3 à 8 s
	IntervalleMax = 8,
	ChanceDoubleClignement = 0.15, -- PROVISOIRE
	PauseDoubleClignement = 0.12, -- PROVISOIRE
	DelaiMaxForce = 0.3, -- délai max avant un clignement demandé par le serveur (PROVISOIRE)
	NoirMaxAttente = 0.35, -- le client garde les yeux fermés au max ce temps en attendant le serveur
	AttenteMaxServeur = 2.0, -- le serveur abandonne (et retente) si tout le monde n'a pas fermé les yeux
	TentativesMax = 5, -- nombre de retentatives d'un changement d'image
	BaisseLuminosite = 0.35, -- assombrissement autour du clignement (0 = aucun)
}

-- Signalement (charte §5)
Reglages.Signalement = {
	DureeAnalyseMin = 2,
	DureeAnalyseMax = 3,
	PerteVieSiPieceSaine = true, -- validé
	DelaiMinEntreSignalements = 1, -- anti-spam serveur (secondes)
	DureeAffichageResultat = 2, -- message « corrigé / erreur » à l'écran
}

-- Caméras (charte §4)
Reglages.Camera = {
	DureeTransitionStatique = 0.2,
}

-- Coop (charte §10, validé) : 1 vie perso + banque partagée, puis spectateur
Reglages.Coop = {
	JoueursMax = 4,
	ViesParJoueur = 1,
	BanqueVies = 3,
}

-- Escalade (charte §5) : chance qu'une nouvelle anomalie soit une AnomalieVisible,
-- augmente avec le nombre d'ajouts/retraits NON signalés dans la maison
Reglages.Escalade = {
	ChanceVisibleBase = 0.05, -- PROVISOIRE
	BonusParNonSignalee = 0.15, -- PROVISOIRE
	ChanceVisibleMax = 0.8, -- PROVISOIRE
}

-- Pièce secrète (charte §8)
-- Easter egg : à chaque changement de caméra, infime chance d'atterrir dans la pièce
-- secrète au lieu de la caméra cliquée. Allumer = screamer. Tenir dans le noir = retour cam 1.
Reglages.PieceSecrete = {
	ChanceParChangementCamera = 0.001, -- 0,1 %
	DureeEsquive = 10, -- secondes à tenir dans le noir sans allumer
}

return Reglages
