--!strict
-- Niveau 1 : la maison américaine (charte sections 3 et 4).
-- Ajouter un niveau = copier ce fichier + ses images, sans toucher aux systèmes.
--
-- IMAGES : les IDs Roblox ne sont pas encore connus. Chaque image a :
--   Cle     = nom selon la convention de la charte (<IdPiece>_Base / _Add<N> / _Remove<N> / _Visible<N>)
--   Image   = "rbxassetid://..." à remplir après upload (vide = placeholder)
--   Fichier = fichier source dans OG-Image/ (pour savoir quoi uploader)
-- La liste des images à uploader est dans Manques.txt.

export type TypeAnomalie = "ObjetAjoute" | "ObjetRetire" | "AnomalieVisible"

export type Anomalie = {
	Type: TypeAnomalie,
	Cle: string,
	Image: string,
	Fichier: string,
	DansTirage: boolean?, -- false = ne sort jamais au hasard (déclenchement spécial). nil = true
	Note: string?,
}

export type Piece = {
	Id: string,
	Nom: string,
	Jouable: boolean, -- false = jamais dans les caméras (pièce secrète)
	Base: { Cle: string, Image: string, Fichier: string },
	Anomalies: { Anomalie },
}

local A_REMPLIR = "" -- placeholder : ID d'asset pas encore uploadé

-- Raccourcis pour garder le fichier lisible
local function base(id: string, fichier: string)
	return { Cle = id .. "_Base", Image = A_REMPLIR, Fichier = fichier }
end

local function anomalie(id: string, typ: TypeAnomalie, n: number, fichier: string): Anomalie
	local suffixe = if typ == "ObjetAjoute" then "Add" elseif typ == "ObjetRetire" then "Remove" else "Visible"
	return { Type = typ, Cle = `{id}_{suffixe}{n}`, Image = A_REMPLIR, Fichier = fichier }
end

local Maison = {}

Maison.Id = "Maison"
Maison.Nom = "La maison"

Maison.Pieces = {
	{
		Id = "Buanderie", Nom = "Buanderie", Jouable = true,
		Base = base("Buanderie", "Buanderie/Buanderie.png"),
		Anomalies = {
			anomalie("Buanderie", "ObjetAjoute", 1, "Buanderie/Buanderie-add1.png"),
			anomalie("Buanderie", "ObjetRetire", 1, "Buanderie/Buanderie-remove1.png"),
			anomalie("Buanderie", "AnomalieVisible", 1, "Buanderie/Buanderie-Anomalie1.png"),
		},
	},
	{
		Id = "Chambre1", Nom = "Chambre 1", Jouable = true,
		Base = base("Chambre1", "Chambre1/Chambre1.png"),
		Anomalies = {
			anomalie("Chambre1", "ObjetAjoute", 1, "Chambre1/Chambre1-add1.png"),
			anomalie("Chambre1", "ObjetRetire", 1, "Chambre1/Chambre1-remove1.png"),
			-- Chambre1/Videos1 (mp3, porte ouverte, vidéo) : usage à définir par Akuma
		},
	},
	{
		Id = "Chambre2", Nom = "Chambre 2", Jouable = true,
		Base = base("Chambre2", "Chambre2/chambre2.png"),
		Anomalies = {
			anomalie("Chambre2", "ObjetAjoute", 1, "Chambre2/chambre2-add1.png"),
			anomalie("Chambre2", "ObjetRetire", 1, "Chambre2/chambre2-remove1.png"),
			-- chambre2-destroying1 / chambre2-event1 : type à définir par Akuma
		},
	},
	{
		Id = "Couloir", Nom = "Couloir", Jouable = true,
		Base = base("Couloir", "Couloir/Couloir.png"),
		Anomalies = {
			anomalie("Couloir", "ObjetAjoute", 1, "Couloir/Couloir-add1.png"),
			anomalie("Couloir", "ObjetRetire", 1, "Couloir/Couloir-remove1.png"),
		},
	},
	{
		Id = "Cuisine", Nom = "Cuisine", Jouable = true,
		Base = base("Cuisine", "Cuisine/Cuisine.png"),
		Anomalies = {
			anomalie("Cuisine", "ObjetAjoute", 1, "Cuisine/Cuisine-add1.png"),
			anomalie("Cuisine", "ObjetRetire", 1, "Cuisine/Cuisine-remove1.png"),
			(function()
				local a = anomalie("Cuisine", "AnomalieVisible", 1, "Cuisine/Cuisine-anomalie1.png")
				a.Note = "Idée Akuma : attend un clignement puis frappe la caméra (cam buguée). Non validé."
				return a
			end)(),
		},
	},
	{
		Id = "EscalierSousSol", Nom = "Escalier du sous-sol", Jouable = true,
		Base = base("EscalierSousSol", "Escalier sous sol/Escalier sous sol.png"),
		Anomalies = {
			anomalie("EscalierSousSol", "ObjetAjoute", 1, "Escalier sous sol/Escalier sous sol-add1.png"),
			anomalie("EscalierSousSol", "ObjetRetire", 1, "Escalier sous sol/Escalier sous sol-remove1.png"),
			(function()
				local a = anomalie("EscalierSousSol", "AnomalieVisible", 1, "Escalier sous sol/Escalier sous sol-anomalie1.png")
				a.DansTirage = false
				a.Note = "Idée Akuma : seulement si une anomalie non repérée + cam du sous-sol buguée. Non validé."
				return a
			end)(),
		},
	},
	{
		Id = "Garage", Nom = "Garage", Jouable = true,
		Base = base("Garage", "Garage/Garage.png"),
		Anomalies = {
			anomalie("Garage", "ObjetAjoute", 1, "Garage/Garage-add1.png"),
			anomalie("Garage", "ObjetRetire", 1, "Garage/Garage-remove1.png"),
			anomalie("Garage", "AnomalieVisible", 1, "Garage/Garage-anomalie1.png"),
			anomalie("Garage", "AnomalieVisible", 2, "Garage/Garage-anomalie2.png"),
			anomalie("Garage", "AnomalieVisible", 3, "Garage/Garage-anomalie3.png"),
		},
	},
	{
		Id = "Porche", Nom = "Porche", Jouable = true,
		Base = base("Porche", "Porche/Porche.png"),
		Anomalies = {
			anomalie("Porche", "ObjetAjoute", 1, "Porche/Porche-add1.png"),
			anomalie("Porche", "ObjetRetire", 1, "Porche/Porche-remove1.png"),
			anomalie("Porche", "AnomalieVisible", 1, "Porche/Porche-anomalie1.png"),
		},
	},
	{
		Id = "SalleDeBain1", Nom = "Salle de bain 1", Jouable = true,
		Base = base("SalleDeBain1", "Salle de bain1/Salledebain1.png"),
		Anomalies = {
			anomalie("SalleDeBain1", "ObjetAjoute", 1, "Salle de bain1/Salledebain1-Add1.png"),
			anomalie("SalleDeBain1", "ObjetAjoute", 2, "Salle de bain1/Salledebain1-Add2.png"),
			anomalie("SalleDeBain1", "ObjetRetire", 1, "Salle de bain1/Salledebain1-Remove1.png"),
			anomalie("SalleDeBain1", "ObjetRetire", 2, "Salle de bain1/Salledebain1-Remove2.png"),
		},
	},
	{
		Id = "SalleDeBain2", Nom = "Salle de bain 2", Jouable = true,
		Base = base("SalleDeBain2", "Salle de bain2/salledebain2.png"),
		Anomalies = {}, -- images d'anomalies manquantes
	},
	{
		Id = "Salon", Nom = "Salon", Jouable = true,
		Base = base("Salon", "Salon/Salon.png"),
		Anomalies = {}, -- images d'anomalies manquantes
	},
	{
		Id = "SousSol", Nom = "Sous-sol", Jouable = true,
		Base = base("SousSol", "Sous sol/Sous Sol.png"),
		Anomalies = {}, -- images d'anomalies manquantes
	},
	{
		Id = "PieceSecrete", Nom = "", Jouable = false,
		Base = base("PieceSecrete", "SecretRoom/Default.png"),
		Anomalies = {},
	},
} :: { Piece }

-- Assets de la séquence de défaite (pièce secrète, charte §8)
-- Noir = Base de PieceSecrete (Default.png). Bouton « Allumer la lampe torche » => screamer.
-- La vidéo v6 (payante à importer) est convertie en planches d'images + son :
-- chaque planche contient Colonnes x Lignes images de la vidéo, jouées à Fps.
Maison.PieceSecrete = {
	Screamer = {
		Planches = {
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche01.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche02.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche03.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche04.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche05.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche06.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche07.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche08.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche09.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche10.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche11.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche12.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche13.png
		A_REMPLIR, -- Assets/Screamer/Screamer_v6_Planche14.png
		},
		Colonnes = 2,
		Lignes = 3,
		TailleImage = Vector2.new(512, 288), -- taille d'une image dans la planche (pixels)
		NombreImages = 84,
		Fps = 15,
		Son = A_REMPLIR, -- Assets/Screamer/Screamer_v6_Son.ogg
	},
	MusiqueStress = { Son = A_REMPLIR, Fichier = "(à fournir)" },
}

return Maison
