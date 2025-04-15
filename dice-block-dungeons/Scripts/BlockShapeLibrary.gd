# region shape patterns
const SHAPES = {
	"L": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 0 },
			{ "pos": Vector2i(0, -1), "tile": 0 },
			{ "pos": Vector2i(0, -2), "tile": 1 },
			{ "pos": Vector2i(1, 0), "tile": 1 }
		],
		"offset": Vector2(-64, -64)
	},
	"J": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 0 },
			{ "pos": Vector2i(0, -1), "tile": 0 },
			{ "pos": Vector2i(0, -2), "tile": 1 },
			{ "pos": Vector2i(-1, 0), "tile": 1 }
		],
		"offset": Vector2(-64, -64)
	},
	"Corner": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 0 },
			{ "pos": Vector2i(0, 1), "tile": 0 },
			{ "pos": Vector2i(1, 0), "tile": 1 },  # ← e.g. die slot here
		],
		"offset": Vector2(-64, -64)
	},
	"3": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 1 },
			{ "pos": Vector2i(1, 0), "tile": 0 },
			{ "pos": Vector2i(2, 0), "tile": 0 }
		],
		"offset": Vector2(-64, -64)
	},
	"Z": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 1 },
			{ "pos": Vector2i(1, 0), "tile": 0 }, # ← e.g. die slot here
			{ "pos": Vector2i(0, 1), "tile": 0 },
			{ "pos": Vector2i(-1, 1), "tile": 1 } # ← e.g. die slot here
		],
		"offset": Vector2(-64, -64)
	},
	"S": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 1 },
			{ "pos": Vector2i(-1, 0), "tile": 0 }, # ← e.g. die slot here
			{ "pos": Vector2i(0, 1), "tile": 0 },
			{ "pos": Vector2i(1, 1), "tile": 1 } # ← e.g. die slot here
		],
		"offset": Vector2(-64, -64)
	},
	"T_1": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 0 },
			{ "pos": Vector2i(1, 0), "tile": 1 }, # ← e.g. die slot here
			{ "pos": Vector2i(0, 1), "tile": 0 },
			{ "pos": Vector2i(-1, 0), "tile": 1 } # ← e.g. die slot here
		],
		"offset": Vector2(-64, 0)
	},
	"T_2": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 0 },
			{ "pos": Vector2i(1, 0), "tile": 0 }, # ← e.g. die slot here
			{ "pos": Vector2i(0, 1), "tile": 1 },
			{ "pos": Vector2i(-1, 0), "tile": 1 } # ← e.g. die slot here
		],
		"offset": Vector2(-64, 0)
	},
	"Square": {
		"tiles": [
			{ "pos": Vector2i(0, 0), "tile": 1 },
			{ "pos": Vector2i(0, -1), "tile": 0 }, # ← e.g. die slot here
			{ "pos": Vector2i(-1, 0), "tile": 0 },
			{ "pos": Vector2i(-1, -1), "tile": 1 } # ← e.g. die slot here
		],
		"offset": Vector2(0, 0)
	},
}
# endregion
