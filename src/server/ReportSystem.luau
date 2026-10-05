--!strict
-- Signalements (charte §5) : le client envoie un type, le serveur valide tout.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Reglages = require(Shared:WaitForChild("Config"):WaitForChild("Reglages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Server = ServerScriptService:WaitForChild("Server")
local Partie = require(Server:WaitForChild("Partie"))
local Vies = require(Server:WaitForChild("Vies"))
local AnomalySystem = require(Server:WaitForChild("AnomalySystem"))

local TYPES = { ObjetAjoute = true, ObjetRetire = true, AnomalieVisible = true }

local ReportSystem = {}

local dernier: { [Player]: number } = {}
local enAnalyse: { [Player]: boolean } = {}
local rng = Random.new()
local remoteResultat = Remotes.Get("ResultatSignalement")

local function terminer(joueur: Player, idPiece: string, typ: string, debut: number)
	AnomalySystem.Bloquer(idPiece, false)
	enAnalyse[joueur] = nil
	if Partie.Phase ~= "EnCours" or not joueur.Parent then return end

	local anomalie = AnomalySystem.Get(idPiece)
	local resultat
	if anomalie and anomalie.Type == typ then
		AnomalySystem.Retirer(idPiece)
		resultat = "Correct"
	elseif not anomalie and AnomalySystem.DernierRetrait(idPiece) > debut then
		resultat = "DejaTraite" -- un coéquipier l'a corrigée pendant l'analyse
	elseif not anomalie and not Reglages.Signalement.PerteVieSiPieceSaine then
		resultat = "RienTrouve"
	else
		resultat = "Erreur"
	end

	remoteResultat:FireClient(joueur, { Etape = "Fin", Resultat = resultat, IdPiece = idPiece })
	if resultat == "Erreur" then
		Vies.Perdre(joueur)
	end
end

function ReportSystem.Init()
	Remotes.Get("Signaler").OnServerEvent:Connect(function(joueur, typ)
		if Partie.Phase ~= "EnCours" or not Vies.PeutJouer(joueur) then return end
		if typeof(typ) ~= "string" or not TYPES[typ] then return end
		if enAnalyse[joueur] then return end
		local maintenant = os.clock()
		if dernier[joueur] and maintenant - dernier[joueur] < Reglages.Signalement.DelaiMinEntreSignalements then return end
		local idPiece = Partie.Regards[joueur]
		if not idPiece then return end

		enAnalyse[joueur] = true
		dernier[joueur] = maintenant
		AnomalySystem.Bloquer(idPiece, true) -- pas de nouvelle anomalie ici pendant l'analyse
		local s = Reglages.Signalement
		local duree = rng:NextNumber(s.DureeAnalyseMin, s.DureeAnalyseMax)
		remoteResultat:FireClient(joueur, { Etape = "Analyse", Duree = duree, IdPiece = idPiece })
		task.delay(duree, terminer, joueur, idPiece, typ, maintenant)
	end)
end

function ReportSystem.Retirer(joueur: Player)
	dernier[joueur] = nil
	enAnalyse[joueur] = nil
end

return ReportSystem
