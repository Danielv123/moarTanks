data:extend(
{
	{
		type = "recipe",
		name = "advanced-flame-thrower-ammo",
		category = "crafting",
		energy_required = 1,
		subgroup = "ammo",
		order = "b[advanced-flame-thrower-ammo]",
		enabled = "false",
		icon = "__moarTanks__/graphics/advanced-flame-thrower-ammo.png",
		ingredients =
		{
			{type="item", name="copper-plate", amount=5},
			{type="item", name="sulfur", amount=5},
			{type="item", name="alien-artifact", amount=1},
			{type="item", name="flame-thrower-ammo", amount=10},
		},
		results=
		{
			{type="item", name="advanced-flame-thrower-ammo", amount=1}
		}
	},
	{
		type = "recipe",
		name = "flame-tank",
		category = "crafting",
		energy_required = 1,
		subgroup = "transport",
		order = "b[flame-tank]",
		enabled = "false",
		icon = "__moarTanks__/graphics/tank.png",
		ingredients =
		{
			{type="item", name="iron-plate", amount=25},
			{type="item", name="copper-plate", amount=10},
			{type="item", name="flame-thrower", amount=1},
		},
		results=
		{
			{type="item", name="flame-tank", amount=1}
		}
	},
}
)