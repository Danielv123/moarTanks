data:extend(
{
  {
    type = "technology",
    name = "flame-tank",
    icon = "__moarTanks__/graphics/factorio flame tanktech.png",
	prerequisites = {"flame-thrower", "tanks"},
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "flame-tank"
      },
    },
    unit =
    {
      count = 30,
      ingredients =
      {
        {"science-pack-1", 2},
        {"science-pack-2", 1},
      },
      time = 120
    },
    order = "e-f-a"
  },
  {
    type = "technology",
    name = "advanced-flammables",
    icon = "__moarTanks__/graphics/advanced_flammables_tech.png",
	prerequisites = {"flame-tank", "alien-technology"},
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "advanced-flame-thrower-ammo"
      },
    },
    unit =
    {
      count = 100,
      ingredients =
      {
        {"science-pack-1", 2},
        {"science-pack-2", 1},
		{"science-pack-3", 1},
		{"alien-science-pack", 3},
      },
      time = 80
    },
    order = "e-f-a"
  },
}
)