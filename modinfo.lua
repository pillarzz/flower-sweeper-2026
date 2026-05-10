name = "Clean Sweeper Expanded"
version = "6.5"
description = [[
You can change the appearances/type for more prefabs with the Clean Sweeper. 

This includes by default: 
+ Flowers, Evil Flowers 
+ Ferns, Potted Fern
+ Succulents, Potted Succulent
+ Marble Shrub, Birchnut Trees, Cacti
+ Carnival Event Decor: Miniature Tree, Cawnival Statuette, Midsummer Night Light
+ Shell Bells (variation, not octave)

Optional (default off): 
+ Evergreen <=> Lumpy Evergreen
+ Grass <=> Reeds
+ Sapling <=> Twiggy Tree
+ Mushroom <=> Mushtree
+ Berrybushes (Types with configuration options) 
+ Potted Plants (DST) (workshop Id: 1311366056)

Version: ]] .. version
author = "krylincy"
api_version = 10
forumthread = ""
icon_atlas = "preview-flower.xml"
icon = "preview-flower.tex"
dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

configuration_options = {
	{
		name = "randomSelection",
		label = "Sweep Order",
		hover = "How to find next type. 'Sequence' is like the skins sweep works, 'Random' well … is random.",
		options = {
			{ description = "Sequence", data = 0 },
			{ description = "Random", data = 1 },
		},
		default = 0,
	},
	{
		name = "rosePercent",
		label = "Rose Chance",
		hover = "The chance to spawn a rose instead of regular flower. Game default is 1%. Only relevant with 'Random Order'.",
		options = {
			{ description = "1%", data = 0.01 },
			{ description = "2%", data = 0.02 },
			{ description = "3%", data = 0.03 },
			{ description = "4%", data = 0.04 },
			{ description = "5%", data = 0.05 },
			{ description = "6%", data = 0.06 },
			{ description = "7%", data = 0.07 },
			{ description = "8%", data = 0.08 },
			{ description = "9%", data = 0.09 },
			{ description = "10%", data = 0.1 },
		},
		default = 0.01,
	},
	{
		name = "changeEvergreens",
		label = "Sweep Evergreen",
		hover = "Change from Evergreen to Lumpy Evergreen and vice versa.",
		options = {
			{ description = "No", data = 0 },
			{ description = "Yes", data = 1 },
		},
		default = 0,
	},
	{
		name = "changeReeds",
		label = "Reeds and Grass",
		hover = "Change from Reeds to Grass and vice versa.",
		options = {
			{ description = "No", data = 0 },
			{ description = "Yes", data = 1 },
		},
		default = 0,
	},
	{
		name = "changeTwiggy",
		label = "Sweep Sapling",
		hover = "Change from Sapling to Twiggy Tree and vice versa.",
		options = {
			{ description = "No", data = 0 },
			{ description = "Yes", data = 1 },
		},
		default = 0,
	},
	{
		name = "changeMushrooms",
		label = "Sweep Mushrooms",
		hover = "Change from Mushroom to Mushtree and vice versa.",
		options = {
			{ description = "No", data = 0 },
			{ description = "Yes", data = 1 },
		},
		default = 0,
	},
	{
		name = "pottedPlantsMod",
		label = "Sweep Potted Plants (Mod)",
		hover = "Allow to sweep the mod's potted plants.",
		options = {
			{ description = "No", data = 0 },
			{ description = "Yes", data = 1 },
		},
		default = 0,
	},
}
