--!strict
-- Options du joueur (côté client uniquement). Pas de sauvegarde pour l'instant.

local Options = {
	Volume = 1, -- 0 à 1, appliqué aux sons du jeu
}

function Options.ChangerVolume(delta: number)
	Options.Volume = math.clamp(math.floor((Options.Volume + delta) * 10 + 0.5) / 10, 0, 1)
end

return Options
