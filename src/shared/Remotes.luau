--!strict
-- Déclaration centralisée des RemoteEvents.
-- Le serveur les crée, le client les attend. Utilisation : Remotes.Get("NomDuRemote")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NOM_DOSSIER = "Remotes"

-- Liste unique des remotes du jeu (sens indiqué en commentaire)
local NOMS = {
	-- Client -> Serveur (intentions uniquement)
	"DemanderEtat", -- () je suis prêt, envoie-moi l'état de la partie
	"RegarderCamera", -- (idPiece) je regarde cette caméra
	"YeuxFermes", -- (jetonClignement) mes yeux sont fermés (noir complet)
	"Signaler", -- (typeAnomalie) signalement sur la caméra regardée
	"AllumerLampe", -- () pièce secrète : le joueur allume la lampe torche
	-- Serveur -> Client
	"EtatPartie", -- (etat) heure, vies, liste des caméras...
	"ImagePiece", -- (idPiece, cleImage) l'image d'une pièce a changé
	"DemanderClignement", -- (jetonClignement) cligne dès que possible
	"FinClignement", -- (jetonClignement) tu peux rouvrir les yeux
	"ResultatSignalement", -- (resultat) début/fin d'analyse, bon/mauvais
}

local Remotes = {}

local dossier: Folder

if RunService:IsServer() then
	dossier = Instance.new("Folder")
	dossier.Name = NOM_DOSSIER
	for _, nom in NOMS do
		local remote = Instance.new("RemoteEvent")
		remote.Name = nom
		remote.Parent = dossier
	end
	dossier.Parent = ReplicatedStorage
else
	dossier = ReplicatedStorage:WaitForChild(NOM_DOSSIER) :: Folder
end

function Remotes.Get(nom: string): RemoteEvent
	assert(table.find(NOMS, nom), `Remote inconnu : {nom}`)
	return dossier:WaitForChild(nom) :: RemoteEvent
end

return Remotes
