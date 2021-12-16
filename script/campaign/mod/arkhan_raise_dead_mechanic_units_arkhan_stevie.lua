local ardm = ardm

ardm:register_table({
	name = "arkhan_stevie",
	build_number = 2,
	deployment_mode = "default",
	units = {
		xereus_tmb_inf_grave_guard = {
			count = 2,
			replenishment_chance = 80,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_western_sylvania_castle_templehof",
				"wh_main_eastern_sylvania_castle_drakenhof"
			}
		},
		xereus_tmb_inf_grave_guard_great = {
			count = 2,
			replenishment_chance = 80,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_western_sylvania_castle_templehof",
				"wh_main_eastern_sylvania_castle_drakenhof"
			}
		},
		xereus_tmb_mon_crypt_horror = {
			count = 2,
			replenishment_chance = 50,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_southern_badlands_agrul_migdhal"
			}
		},
		xereus_tmb_mon_vargheist = {
			count = 2,
			replenishment_chance = 50,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_southern_badlands_agrul_migdhal"
			}
		},
		xereus_tmb_mon_terrorgheist = {
			count = 2,
			replenishment_chance = 25,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_southern_badlands_agrul_migdhal"
			}
		},
		xereus_tmb_inf_zmb_gunner_mob = {
			count = 2,
			replenishment_chance = 25,
			max_count = 8,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh2_main_vampire_coast_the_awakening"
			}
		},
		xereus_tmb_inf_zmb_handgunner_mob = {
			count = 2,
			replenishment_chance = 25,
			max_count = 8,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh2_main_vampire_coast_the_awakening"
			}
		},
		xereus_tmb_mon_prometheans_gunnery_mob = {
			count = 2,
			replenishment_chance = 25,
			max_count = 6,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh2_main_vampire_coast_the_awakening"
			}
		},
		xereus_tmb_inf_skeleton_warriors = {
			count = 1,
			replenishment_chance = 100,
			max_count = 10,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_western_sylvania_castle_templehof",
				"wh_main_eastern_sylvania_castle_drakenhof"
			}
		},
		xereus_tmb_inf_skeleton_spearmen = {
			count = 0,
			replenishment_chance = 100,
			max_count = 10,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_western_sylvania_castle_templehof",
				"wh_main_eastern_sylvania_castle_drakenhof"
			}
		}
	}
})

-- Registering multiple tables within a single submod/file is possible.
-- Below is an example of inline table definition.
-- TODO: Define dictionary containing units and properties
ardm:register_table({
		name = "arkhan_stevie",
		build_number = 1,
		deployment_mode = "own_provinces",
		units = {
		}
})
