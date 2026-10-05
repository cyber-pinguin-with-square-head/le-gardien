--!strict
-- Démarrage serveur : crée les remotes et vérifie la cohérence de la config.
-- Les erreurs de config sont affichées en rouge dans la console au lancement.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")

local Version = require(Shared:WaitForChild("Version"))
require(Shared:WaitForChild("Remotes")) -- crée les RemoteEvents
local Reglages = require(Config:WaitForChild("Reglages"))
local Difficultes = require(Config:WaitForChild("Difficultes"))
local Niveau = require(Config:WaitForChild("Niveaux"):WaitForChild(Reglages.NiveauParDefaut))

local TYPES_VALIDES = { ObjetAjoute = true, ObjetRetire = true, AnomalieVisible = true }

local erreurs: { string } = {}
local function erreur(msg: string)
	table.insert(erreurs, msg)
end

-- Pièces : IDs uniques, types d'anomalies valides, placeholders
local ids: { [string]: boolean } = {}
local nbJouables, nbImages, nbPlaceholders, nbSansAnomalie = 0, 0, 0, 0
for _, piece in Niveau.Pieces do
	if ids[piece.Id] then erreur(`Pièce en double : {piece.Id}`) end
	ids[piece.Id] = true
	if piece.Jouable then
		nbJouables += 1
		if #piece.Anomalies == 0 then nbSansAnomalie += 1 end
	end
	nbImages += 1
	if piece.Base.Image == "" then nbPlaceholders += 1 end
	for _, a in piece.Anomalies do
		if not TYPES_VALIDES[a.Type] then erreur(`{a.Cle} : type inconnu {a.Type}`) end
		nbImages += 1
		if a.Image == "" then nbPlaceholders += 1 end
	end
end

-- Difficultés : cohérence avec le nombre de pièces
for _, id in Difficultes.Ordre do
	local d = Difficultes.Liste[id]
	if not d then
		erreur(`Difficulté manquante : {id}`)
		continue
	end
	if d.NombreCameras > nbJouables then
		erreur(`{id} : {d.NombreCameras} caméras demandées, {nbJouables} pièces jouables`)
	end
	if not d.PiecesAleatoires and d.NombreCameras ~= nbJouables then
		erreur(`{id} : sans tirage, NombreCameras doit valoir {nbJouables}`)
	end
	if d.IntervalleAnomalieMin > d.IntervalleAnomalieMax then
		erreur(`{id} : IntervalleAnomalieMin > Max`)
	end
end

print(`[Serveur] Le Gardien d'anomalies v{Version.VERSION} — Rojo OK`)
print(`[Config] Niveau « {Niveau.Nom} » : {nbJouables} pièces jouables, {nbImages} images ({nbPlaceholders} à uploader), {nbSansAnomalie} pièces sans anomalie`)

if #erreurs == 0 then
	print("[Config] Aucune erreur ✔")
else
	for _, e in erreurs do
		warn(`[Config] ERREUR : {e}`)
	end
end
