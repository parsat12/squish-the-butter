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
		Color = Color3.fromRGB(255, 236, 128),
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
		Color = Color3.fromRGB(255, 246, 183),
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
		Color = Color3.fromRGB(255, 194, 46),
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
		Color = Color3.fromRGB(126, 220, 255),
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
		Color = Color3.fromRGB(77, 64, 140),
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

GameConfig.Beebohs = {
	BlueBlob = {
		Name = "Blue Blob Beeboh",
		Rarity = "Common",
		CoinsPerSecond = 1,
		Color = Color3.fromRGB(64, 166, 255),
	},
	LemonSquish = {
		Name = "Lemon Squish Beeboh",
		Rarity = "Common",
		CoinsPerSecond = 1,
		Color = Color3.fromRGB(255, 229, 74),
	},
	StrawberrySquish = {
		Name = "Strawberry Squish Beeboh",
		Rarity = "Uncommon",
		CoinsPerSecond = 3,
		Color = Color3.fromRGB(255, 91, 126),
	},
	PicklePop = {
		Name = "Pickle Pop Beeboh",
		Rarity = "Uncommon",
		CoinsPerSecond = 3,
		Color = Color3.fromRGB(91, 199, 91),
	},
	JellyCube = {
		Name = "Jelly Cube Beeboh",
		Rarity = "Rare",
		CoinsPerSecond = 8,
		Color = Color3.fromRGB(126, 220, 255),
	},
	GlowOrb = {
		Name = "Glow Orb Beeboh",
		Rarity = "Rare",
		CoinsPerSecond = 8,
		Color = Color3.fromRGB(132, 255, 191),
	},
	MetalBeeboh = {
		Name = "Metal Beeboh",
		Rarity = "Rare",
		CoinsPerSecond = 10,
		Color = Color3.fromRGB(166, 174, 184),
	},
	LavaLamp = {
		Name = "Lava Lamp Beeboh",
		Rarity = "Epic",
		CoinsPerSecond = 20,
		Color = Color3.fromRGB(255, 105, 74),
	},
	CloudPuff = {
		Name = "Cloud Puff Beeboh",
		Rarity = "Epic",
		CoinsPerSecond = 20,
		Color = Color3.fromRGB(207, 235, 255),
	},
	ClearBeeboh = {
		Name = "Clear Beeboh",
		Rarity = "Epic",
		CoinsPerSecond = 25,
		Color = Color3.fromRGB(200, 245, 255),
	},
	GoldfishBowl = {
		Name = "Goldfish Bowl Beeboh",
		Rarity = "Legendary",
		CoinsPerSecond = 60,
		Color = Color3.fromRGB(255, 173, 51),
	},
	ButterKing = {
		Name = "Butter King Beeboh",
		Rarity = "Legendary",
		CoinsPerSecond = 60,
		Color = Color3.fromRGB(255, 210, 68),
	},
	GalaxyOrb = {
		Name = "Galaxy Orb Beeboh",
		Rarity = "Mythic",
		CoinsPerSecond = 200,
		Color = Color3.fromRGB(147, 101, 255),
	},
	SecretSentientButter = {
		Name = "Secret Sentient Butter Beeboh",
		Rarity = "Mythic",
		CoinsPerSecond = 200,
		Color = Color3.fromRGB(255, 72, 139),
	},
}

return GameConfig
