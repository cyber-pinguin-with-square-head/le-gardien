--!strict
-- Textes d'histoire affichés au joueur (charte §2). Le fond de l'histoire est dans
-- HISTOIRE.txt : ici on ne dit JAMAIS les choses clairement, on suggère.

local Lore = {}

-- Cadre de la note de la propriétaire (le texte du jour est dans Lore.Intros).
-- {JOUR} est remplacé par le numéro du jour. Paragraphes = texte de secours.
Lore.Consignes = {
	Entete = "À L'ATTENTION DU GARDIEN DE NUIT",
	Reference = "14, Alder Lane   ·   Service de 23h00 à 05h00   ·   Jour {JOUR}",
	Paragraphes = {
		"Bonsoir. Votre prédécesseur a quitté son poste sans prévenir. Vous prenez sa place dès ce soir, depuis la guérite.",
		"Ma maison compte 12 pièces. Je tiens à ce qu'elle reste EXACTEMENT dans l'état où elle se trouve. Exactement.",
		"Changez de caméra avec le panneau en bas à droite. Apprenez chaque pièce par cœur : le moindre écart compte.",
		"Si un objet a été AJOUTÉ, RETIRÉ, ou si vous voyez quelque chose qui n'a rien à faire là, appuyez sur ANOMALIE et choisissez le bon signalement. Une analyse confirmera. Un signalement erroné est une faute, et je ne peux pas couvrir toutes vos fautes.",
		"N'allumez aucune lumière. Les caméras sont infrarouges : la lumière ruinerait leur définition.",
		"Évitez de fixer trop longtemps une même caméra. Clignez des yeux normalement.",
		"Si vous vous réveillez dans une pièce sans fenêtre : restez calme, ne cherchez pas l'interrupteur, attendez.",
		"Ne venez pas me chercher. C'est moi qui vous appellerai.",
	},
	Signature = "— La propriétaire",
	Bouton = "PRENDRE MON SERVICE",
}

-- Message de la propriétaire avant chaque jour (textes d'Akuma : OG-Image/JourX-Intro.txt).
-- Jour 3 : le fichier d'Akuma est une copie du Jour 2 -> même texte en attendant.
Lore.Intros = {
	[1] = {
		"Bonsoir,",
		"Votre prédécesseur a décidé de mettre fin à son contrat. Nous souhaiterions travailler avec vous dès ce soir. Paiement tous les jours après votre service.",
		"Le travail consiste à assurer la sécurité via les caméras de la guérite.",
		"Vous pourrez contrôler les 8 caméras en bas à droite de votre dispositif.",
		"Si vous pensez qu'un objet a été retiré ou ajouté, ou si… vous voyez quelque chose d'inhabituel, servez-vous des boutons en bas à gauche : ils pourraient vous être utiles.",
		"L'analyse ne prend que quelques secondes. Si votre signalement s'avère erroné, cela pourrait constituer une faute assez grave de votre part, alors faites attention.",
		"Pour des raisons de sécurité, ne vous amusez pas à allumer les lumières. De plus, les caméras sont infrarouges et cela risquerait de compromettre leurs enregistrements.",
		"Respirez calmement, clignez des yeux normalement, tout se passera bien. Aucune relève n'est prévue le lendemain matin : à partir de 5 h, quittez les lieux.",
		"Je vous tiendrai au courant pour la suite…",
		"Cordialement,",
	},
	[2] = {
		"Bonsoir,",
		"Comme prévu, c'est votre dernière journée.",
		"J'ai installé 2 nouvelles caméras avec Billy. Il m'a semblé bizarre toute la journée, il m'a parlé d'une porte inconnue. Je ne sais pas quoi en penser… Peut-être que le travail n'est pas assez stimulant et que son imagination lui a fait voir des choses.",
		"J'espère que vous garderez les pieds sur terre… Enfin, même si c'est votre dernier jour, j'aimerais potentiellement vous placer sur d'autres missions par la suite.",
		"La météo d'aujourd'hui est assez mauvaise, les éclairs ont fait disjoncter le tableau général. Il est possible que cela arrive ce soir. Si c'est le cas, il faudra tout simplement longer la maison jusqu'à la cabane en bois, où se trouve le tableau électrique, tirer l'interrupteur vers le haut et… rester dans la lumière. La nuit est assez noire…",
		"Cordialement,",
	},
	[3] = {
		"Bonsoir,",
		"Comme prévu, c'est votre dernière journée.",
		"J'ai installé 2 nouvelles caméras avec Billy. Il m'a semblé bizarre toute la journée, il m'a parlé d'une porte inconnue. Je ne sais pas quoi en penser… Peut-être que le travail n'est pas assez stimulant et que son imagination lui a fait voir des choses.",
		"J'espère que vous garderez les pieds sur terre… Enfin, même si c'est votre dernier jour, j'aimerais potentiellement vous placer sur d'autres missions par la suite.",
		"La météo d'aujourd'hui est assez mauvaise, les éclairs ont fait disjoncter le tableau général. Il est possible que cela arrive ce soir. Si c'est le cas, il faudra tout simplement longer la maison jusqu'à la cabane en bois, où se trouve le tableau électrique, tirer l'interrupteur vers le haut et… rester dans la lumière. La nuit est assez noire…",
		"Cordialement,",
	},
}

-- Cassettes laissées par l'ancien gardien (Danny). Une par jour.
-- Son = ID audio à remplir quand la voix sera enregistrée (sinon sous-titres seuls).
-- Chaque ligne : { texte, secondes d'affichage }
Lore.Cassettes = {
	[1] = {
		Titre = "CASSETTE 1 — « LISEZ-MOI » (au feutre)",
		Son = "",
		Lignes = {
			{ "*clic* … ça tourne ? Ouais, ça tourne.", 3 },
			{ "Salut le nouveau. Ou la nouvelle. Moi c'est Danny. Le gardien de nuit. Enfin… celui d'avant, si t'écoutes ça.", 6 },
			{ "Je te préviens, je suis vachement plus cool que notre employeuse.", 4 },
			{ "Madame. Jamais vue en vrai. Juste sa voix au téléphone. Toujours calme, toujours polie. Le genre de voix à qui on dit oui sans réfléchir.", 7 },
			{ "Elle m'a dit de jamais allumer les lumières. Que ça pourrait foutre en l'air la « définition des caméras ».", 6 },
			{ "La définition des caméras ! *rire* Je m'en fous, des caméras.", 4 },
			{ "De toute façon, des gamins se sont amusés à casser les ampoules des lampadaires la nuit dernière. Niveau lumière, on est servis.", 7 },
			{ "J'ai mis du faux feuillage sur la guérite. Au moins les gosses viendront pas me réveiller pendant ma sieste.", 6 },
			{ "Bref. Si un truc bouge dans la maison, tu le signales. C'est tout ce qu'elle veut. Facile.", 5 },
			{ "… Ah, et compte les pièces. Pour rire. Moi j'en compte douze. *clic*", 5 },
		},
	},
	-- PROPOSITIONS (à valider par Akuma)
	[2] = {
		Titre = "CASSETTE 2",
		Son = "",
		Lignes = {
			{ "*clic* Deuxième cassette.", 3 },
			{ "Les gamins sont pas revenus. Les ampoules non plus. Personne les a changées.", 5 },
			{ "Madame a appelé à trois heures pile. Elle savait que j'avais dormi.", 5 },
			{ "Elle a juste dit : « Vous avez cligné des yeux, monsieur Reyes. »", 5 },
			{ "Ouais. Comme tout le monde. Qu'est-ce que ça peut lui faire ?", 4 },
			{ "… Le cadre du couloir. J'ai cligné. Il était plus là. Je l'ai pas vu partir, il était juste… plus là.", 7 },
			{ "Signale tout. Même quand t'es pas sûr. *clic*", 4 },
		},
	},
	[3] = {
		Titre = "CASSETTE 3",
		Son = "",
		Lignes = {
			{ "*clic* … j'ai recompté.", 3 },
			{ "Treize. Il y a une porte au sous-sol. Elle est sur aucun plan.", 5 },
			{ "Madame dit que je me trompe. Madame dit que la maison a douze pièces. Elle l'a répété trois fois, toujours aussi calme.", 7 },
			{ "J'ai pris la lampe torche ce soir. Je veux juste voir.", 4 },
			{ "Si la prochaine cassette est vide, alors…", 3 },
			{ "*grésillement*", 3 },
		},
	},
}

-- Phrases courtes affichées en bas du menu, au hasard (ambiance)
Lore.PhrasesMenu = {
	"La maison compte 12 pièces.",
	"Ne fixez pas la caméra.",
	"C'est elle qui vous appellera.",
	"Danny a tenu onze nuits.",
	"Rien ne doit bouger.",
	"Ne cherchez pas l'interrupteur.",
}

return Lore
