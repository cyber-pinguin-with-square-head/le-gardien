--!strict
-- Apparition des anomalies + RÈGLE D'OR (charte §5 et §6).
-- Une image de pièce ne change que si personne ne la regarde, ou si TOUS ceux qui la
-- regardent ont les yeux fermés (noir complet du clignement). Le client a en plus une
-- sécurité : il n'affiche jamais un changement yeux ouverts (voir Demarrage.client).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Reglages = require(Shared:WaitForChild("Config"):WaitForChild("Reglages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Partie = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Partie"))

type Attente = {
	IdPiece: string,
	Cle: string,
	Demandes: { [Player]: boolean }, -- joueurs à qui on a demandé de cligner
	Fermes: { [Player]: boolean }, -- joueurs qui ont confirmé « yeux fermés »
	Expire: number,
	Essais: number,
	SurApplique: (() -> ())?,
	SurAbandon: (() -> ())?,
}

local AnomalySystem = {}

-- Appelé quand le nombre de pièces anormales atteint le seuil (défaite par négligence)
AnomalySystem.SurSeuil = function() end

local actives: { [string]: any } = {} -- idPiece -> anomalie (config) visible actuellement
local enCours: { [string]: boolean } = {} -- changement programmé, pas encore appliqué
local bloquees: { [string]: number } = {} -- pièces en cours d'analyse (compteur)
local derniersRetraits: { [string]: number } = {}
local attentes: { [number]: Attente } = {}
local jetonSuivant = 0
local rng = Random.new()

local remoteImage = Remotes.Get("ImagePiece")
local remoteDemande = Remotes.Get("DemanderClignement")
local remoteFin = Remotes.Get("FinClignement")

local function appliquer(idPiece: string, cle: string)
	Partie.ImagesActuelles[idPiece] = cle
	remoteImage:FireAllClients(idPiece, cle)
end

-- Libère les yeux des joueurs qui attendaient ce jeton
local function liberer(jeton: number)
	local a = attentes[jeton]
	if not a then return end
	attentes[jeton] = nil
	for joueur in a.Fermes do
		if joueur.Parent then remoteFin:FireClient(joueur, jeton) end
	end
end

local function verifier(jeton: number)
	local a = attentes[jeton]
	if not a then return end
	local tousFermes = true
	for _, joueur in Partie.Spectateurs(a.IdPiece) do
		if not a.Fermes[joueur] then
			tousFermes = false
			-- Nouveau spectateur arrivé entre-temps : on lui demande aussi de cligner
			if not a.Demandes[joueur] then
				a.Demandes[joueur] = true
				remoteDemande:FireClient(joueur, jeton)
			end
		end
	end
	if tousFermes then
		appliquer(a.IdPiece, a.Cle)
		liberer(jeton)
		if a.SurApplique then a.SurApplique() end
	end
end

-- Programme un changement d'image en respectant la règle d'or
function AnomalySystem.Changer(idPiece: string, cle: string, surApplique: (() -> ())?, surAbandon: (() -> ())?, essais: number?)
	jetonSuivant += 1
	attentes[jetonSuivant] = {
		IdPiece = idPiece, Cle = cle, Demandes = {}, Fermes = {},
		Expire = os.clock() + Reglages.Clignement.AttenteMaxServeur,
		Essais = essais or 1, SurApplique = surApplique, SurAbandon = surAbandon,
	}
	verifier(jetonSuivant)
end

-- Délais dépassés : on rouvre les yeux de tout le monde et on retente plus tard
RunService.Heartbeat:Connect(function()
	local maintenant = os.clock()
	for jeton, a in attentes do
		if maintenant > a.Expire then
			liberer(jeton)
			if a.Essais < Reglages.Clignement.TentativesMax and Partie.Phase == "EnCours" then
				task.delay(1, AnomalySystem.Changer, a.IdPiece, a.Cle, a.SurApplique, a.SurAbandon, a.Essais + 1)
			elseif a.SurAbandon then
				a.SurAbandon()
			end
		end
	end
end)

Remotes.Get("YeuxFermes").OnServerEvent:Connect(function(joueur, jeton)
	if typeof(jeton) ~= "number" then return end
	local a = attentes[jeton]
	if a and a.Demandes[joueur] then
		a.Fermes[joueur] = true
		verifier(jeton)
	end
end)

-- À appeler quand un joueur change de caméra ou quitte : peut débloquer un changement
function AnomalySystem.SurChangementRegard()
	for jeton in attentes do
		verifier(jeton)
	end
end

function AnomalySystem.Get(idPiece: string): any
	return actives[idPiece]
end

function AnomalySystem.Bloquer(idPiece: string, bloque: boolean)
	bloquees[idPiece] = math.max((bloquees[idPiece] or 0) + (if bloque then 1 else -1), 0)
end

function AnomalySystem.DernierRetrait(idPiece: string): number
	return derniersRetraits[idPiece] or 0
end

-- Bon signalement : retour immédiat à l'image de base (seule exception, masquée par l'analyse)
function AnomalySystem.Retirer(idPiece: string)
	actives[idPiece] = nil
	derniersRetraits[idPiece] = os.clock()
	appliquer(idPiece, Partie.GetPiece(idPiece).Base.Cle)
end

function AnomalySystem.Compter(): (number, number)
	local total, nonSignalees = 0, 0
	for _, a in actives do
		total += 1
		if a.Type ~= "AnomalieVisible" then nonSignalees += 1 end
	end
	return total, nonSignalees
end

-- Choisit une pièce + une anomalie. Escalade : plus il y a d'ajouts/retraits non
-- signalés, plus une AnomalieVisible a de chances d'apparaître (charte §5).
function AnomalySystem.TenterApparition()
	if Partie.Phase ~= "EnCours" then return end
	local _, nonSignalees = AnomalySystem.Compter()
	local e = Reglages.Escalade
	local chanceVisible = math.min(e.ChanceVisibleBase + e.BonusParNonSignalee * nonSignalees, e.ChanceVisibleMax)
	local veutVisible = rng:NextNumber() < chanceVisible

	local options, autres = {}, {}
	for _, cam in Partie.Cameras do
		local id = cam.IdPiece
		if actives[id] or enCours[id] or (bloquees[id] or 0) > 0 then continue end
		for _, a in Partie.GetPiece(id).Anomalies do
			if a.DansTirage == false then continue end
			local estVisible = a.Type == "AnomalieVisible"
			table.insert(if estVisible == veutVisible then options else autres, { Id = id, Anomalie = a })
		end
	end
	if #options == 0 then options = autres end
	if #options == 0 then return end

	local choix = options[rng:NextInteger(1, #options)]
	enCours[choix.Id] = true
	AnomalySystem.Changer(choix.Id, choix.Anomalie.Cle, function()
		enCours[choix.Id] = nil
		if Partie.Phase ~= "EnCours" then return end
		actives[choix.Id] = choix.Anomalie
		local total = AnomalySystem.Compter()
		if total >= Partie.Difficulte.SeuilMort then
			AnomalySystem.SurSeuil()
		end
	end, function()
		enCours[choix.Id] = nil
	end)
end

function AnomalySystem.Demarrer()
	table.clear(actives)
	table.clear(enCours)
	table.clear(bloquees)
	task.spawn(function()
		local d = Partie.Difficulte
		while Partie.Phase == "EnCours" do
			task.wait(rng:NextNumber(d.IntervalleAnomalieMin, d.IntervalleAnomalieMax))
			if Partie.Phase ~= "EnCours" then break end
			AnomalySystem.TenterApparition()
		end
	end)
end

return AnomalySystem
