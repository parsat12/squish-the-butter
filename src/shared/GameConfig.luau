local GameConfig = {}

GameConfig.Rarities = {
	Common = {
		Name = "Common",
		Order = 1,
		Color = Color3.fromRGB(235, 235, 235),
	},
	Uncommon = {
		Name = "Uncommon",
		Order = 2,
		Color = Color3.fromRGB(97, 214, 111),
	},
	Rare = {
		Name = "Rare",
		Order = 3,
		Color = Color3.fromRGB(76, 166, 255),
	},
	Epic = {
		Name = "Epic",
		Order = 4,
		Color = Color3.fromRGB(183, 102, 255),
	},
	Legendary = {
		Name = "Legendary",
		Order = 5,
		Color = Color3.fromRGB(255, 173, 51),
	},
	Mythic = {
		Name = "Mythic",
		Order = 6,
		Color = Color3.fromRGB(255, 72, 139),
	},
}

GameConfig.Butter = {
	Plain = {
		Name = "Plain Butter",
		Order = 1,
		Cost = 50,
		Odds = {
			Common = 80,
			Uncommon = 18,
			Rare = 2,
		},
	},
	Salted = {
		Name = "Salted Butter",
		Order = 2,
		Cost = 250,
		Odds = {
			Common = 60,
			Uncommon = 30,
			Rare = 9,
			Epic = 1,
		},
	},
	Golden = {
		Name = "Golden Butter",
		Order = 3,
		Cost = 1500,
		Odds = {
			Common = 35,
			Uncommon = 40,
			Rare = 20,
			Epic = 4.5,
			Legendary = 0.5,
		},
	},
	Rainbow = {
		Name = "Rainbow Butter",
		Order = 4,
		Cost = 8000,
		Odds = {
			Common = 15,
			Uncommon = 30,
			Rare = 35,
			Epic = 17,
			Legendary = 2.8,
			Mythic = 0.2,
		},
	},
	Cosmic = {
		Name = "Cosmic Butter",
		Order = 5,
		Cost = 50000,
		Odds = {
			Common = 5,
			Uncommon = 15,
			Rare = 35,
			Epic = 32,
			Legendary = 11,
			Mythic = 2,
		},
	},
}

GameConfig.Needohs = {
	BlueBlob = {
		Name = "Blue Blob Needoh",
		Rarity = "Common",
		CoinsPerSecond = 1,
	},
	LemonSquish = {
		Name = "Lemon Squish Needoh",
		Rarity = "Common",
		CoinsPerSecond = 1,
	},
	StrawberrySquish = {
		Name = "Strawberry Squish Needoh",
		Rarity = "Uncommon",
		CoinsPerSecond = 3,
	},
	PicklePop = {
		Name = "Pickle Pop Needoh",
		Rarity = "Uncommon",
		CoinsPerSecond = 3,
	},
	JellyCube = {
		Name = "Jelly Cube Needoh",
		Rarity = "Rare",
		CoinsPerSecond = 8,
	},
	GlowOrb = {
		Name = "Glow Orb Needoh",
		Rarity = "Rare",
		CoinsPerSecond = 8,
	},
	LavaLamp = {
		Name = "Lava Lamp Needoh",
		Rarity = "Epic",
		CoinsPerSecond = 20,
	},
	CloudPuff = {
		Name = "Cloud Puff Needoh",
		Rarity = "Epic",
		CoinsPerSecond = 20,
	},
	GoldfishBowl = {
		Name = "Goldfish Bowl Needoh",
		Rarity = "Legendary",
		CoinsPerSecond = 60,
	},
	ButterKing = {
		Name = "Butter King Needoh",
		Rarity = "Legendary",
		CoinsPerSecond = 60,
	},
	GalaxyOrb = {
		Name = "Galaxy Orb Needoh",
		Rarity = "Mythic",
		CoinsPerSecond = 200,
	},
	SecretSentientButter = {
		Name = "Secret Sentient Butter Needoh",
		Rarity = "Mythic",
		CoinsPerSecond = 200,
	},
}

return GameConfig
