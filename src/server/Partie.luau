--!strict
-- État de la partie en cours. Le serveur est l'unique autorité (charte §11).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Reglages = require(Config:WaitForChild("Reglages"))
local Difficultes = require(Config:WaitForChild("Difficultes"))
local Remotes = require(Shared:WaitForChild("Remotes"))

export type Camera = { Numero: number, IdPiece: string, Nom: string }
-- Phases : Menu, Salon (attente coop), EnCours, Screamer, GameOver, Victoire
export type Phase = string

local Partie = {}

Partie.Niveau = nil :: any
Partie.Difficulte = nil :: any
Partie.Mode = "Solo" -- "Solo" ou "Coop" (fixé par le lobby, étape h)
Partie.Phase = "Menu" :: Phase
Partie.Generation = 0 -- change à chaque partie : arrête les boucles de la précédente
Partie.Raison = nil :: string? -- cause de la fin (Erreurs / Negligence)
Partie.Cameras = {} :: { Camera }
Partie.ImagesActuelles = {} :: { [string]: string } -- idPiece -> clé de l'image affichée
Partie.Regards = {} :: { [Player]: string } -- joueur -> idPiece regardée
Partie.Vies = {} :: { [Player]: number }
Partie.Perso = {} :: { [Player]: string } -- événement personnel : "PieceSecrete" / "Screamer"
Partie.Chapitre = ""
Partie.Stats = { Apparues = 0, Corrigees = 0, Erreurs = 0 } -- bilan de fin de nuit
-- Type de serveur (fixé par LobbySystem) : "Hub" (public, menu seulement),
-- "Solo" / "Coop" (serveur réservé), "Studio" (tests : tout en local)
Partie.Serveur = { Type = "Studio", Code = "", HoteId = 0 }
Partie.Jour = 1
Partie.Banque = 0
Partie.Heure = Reglages.Nuit.HeureDebut
Partie.Minute = 0

local piecesParId: { [string]: any } = {}
local rng = Random.new()

local function melanger<T>(t: { T })
	for i = #t, 2, -1 do
		local j = rng:NextInteger(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

-- Prépare une nouvelle partie : tirage des pièces + ordre des caméras mélangé (charte §7)
function Partie.Creer(idDifficulte: string, idNiveau: string, mode: string, idChapitre: string?, jour: number?)
	local niveau = require(Config:WaitForChild("Niveaux"):WaitForChild(idNiveau)) :: any
	local diff = Difficultes.Liste[idDifficulte]
	assert(diff, `Difficulté inconnue : {idDifficulte}`)

	piecesParId = {}
	local jouables = {}
	for _, piece in niveau.Pieces do
		piecesParId[piece.Id] = piece
		if piece.Jouable then
			table.insert(jouables, piece)
		end
	end
	melanger(jouables)

	Partie.Generation += 1
	Partie.Niveau = niveau
	Partie.Difficulte = diff
	Partie.Mode = mode
	Partie.Phase = "EnCours"
	Partie.Raison = nil
	Partie.Cameras = {}
	Partie.ImagesActuelles = {}
	Partie.Regards = {}
	Partie.Vies = {}
	Partie.Perso = {}
	Partie.Stats = { Apparues = 0, Corrigees = 0, Erreurs = 0 }
	Partie.Chapitre = idChapitre or idNiveau
	Partie.Jour = jour or 1
	Partie.Banque = if mode == "Coop" then Reglages.Coop.BanqueVies else 0
	Partie.Heure = Reglages.Nuit.HeureDebut
	Partie.Minute = 0

	local nombre = if diff.PiecesAleatoires then diff.NombreCameras else #jouables
	for i = 1, math.min(nombre, #jouables) do
		local piece = jouables[i]
		table.insert(Partie.Cameras, { Numero = i, IdPiece = piece.Id, Nom = piece.Nom })
		Partie.ImagesActuelles[piece.Id] = piece.Base.Cle
	end
end

function Partie.GetPiece(idPiece: string): any
	return piecesParId[idPiece]
end

function Partie.EstCamera(idPiece: string): boolean
	return Partie.ImagesActuelles[idPiece] ~= nil
end

-- Joueurs qui regardent actuellement une pièce (règle d'or, charte §6)
function Partie.Spectateurs(idPiece: string): { Player }
	local liste = {}
	for joueur, id in Partie.Regards do
		if id == idPiece and joueur.Parent == Players then
			table.insert(liste, joueur)
		end
	end
	return liste
end

-- Retour au menu (ou à la salle d'attente en coop) : la partie en cours est abandonnée
function Partie.Reinitialiser(phase: string?)
	Partie.Generation += 1
	Partie.Phase = phase or "Menu"
	Partie.Raison = nil
	Partie.Regards = {}
	Partie.Perso = {}
end

-- Ce que le client a le droit de savoir (jamais le seuil de mort)
function Partie.EtatPublic(joueur: Player)
	if Partie.Phase == "Menu" or Partie.Phase == "Salon" or not Partie.Niveau then
		local joueurs = {}
		for _, j in Players:GetPlayers() do
			table.insert(joueurs, { Nom = j.DisplayName, Hote = j.UserId == Partie.Serveur.HoteId })
		end
		return {
			Phase = if Partie.Phase == "Salon" then "Salon" else "Menu",
			Generation = Partie.Generation,
			Code = Partie.Serveur.Code,
			Joueurs = joueurs,
			EstHote = joueur.UserId == Partie.Serveur.HoteId,
			JoueursMax = Reglages.Coop.JoueursMax,
		}
	end
	return {
		Generation = Partie.Generation,
		Niveau = Partie.Niveau.Id,
		Mode = Partie.Mode,
		Phase = Partie.Phase,
		Raison = Partie.Raison,
		Cameras = Partie.Cameras,
		Images = Partie.ImagesActuelles,
		Heure = Partie.Heure,
		Minute = Partie.Minute,
		Vies = Partie.Vies[joueur] or 0,
		Perso = Partie.Perso[joueur],
		Chapitre = Partie.Chapitre,
		Jour = Partie.Jour,
		Banque = Partie.Banque,
		Stats = Partie.Stats,
	}
end

-- Envoie l'état à tous les joueurs
function Partie.Diffuser()
	local remote = Remotes.Get("EtatPartie")
	for _, joueur in Players:GetPlayers() do
		remote:FireClient(joueur, Partie.EtatPublic(joueur))
	end
end

function Partie.ChangerPhase(phase: Phase, raison: string?)
	Partie.Phase = phase
	if raison then Partie.Raison = raison end
	Partie.Diffuser()
end

return Partie
