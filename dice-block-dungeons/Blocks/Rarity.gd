# Rarity.gd
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC
}

const RARITY_WEIGHTS = {
	Rarity.COMMON: 60,
	Rarity.UNCOMMON: 25,
	Rarity.RARE: 10,
	Rarity.EPIC: 5
}

const RARITY_NAMES = {
	Rarity.COMMON: "Common",
	Rarity.UNCOMMON: "Uncommon",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic"
}
