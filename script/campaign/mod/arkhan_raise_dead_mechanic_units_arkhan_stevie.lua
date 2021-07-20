local ardm = ardm

ardm:register_table({
	name = "arkhan_stevie",
	build_number = 2,
	deployment_mode = "default",
	units = {
		wh_main_vmp_inf_skeleton_warriors_0 = {
			count = 2,
			replenishment_chance = 100,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_western_sylvania_castle_templehof",
				"wh_main_western_sylvania_fort_oberstyre",
				"wh_main_western_sylvania_schwartzhafen",
				"wh_main_eastern_sylvania_castle_drakenhof",
				"wh_main_eastern_sylvania_eschen",
				"wh_main_eastern_sylvania_waldenhof"
			}
		},
		wh_main_vmp_inf_skeleton_warriors_1 = {
			count = 2,
			replenishment_chance = 100,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_western_sylvania_castle_templehof",
				"wh_main_western_sylvania_fort_oberstyre",
				"wh_main_western_sylvania_schwartzhafen",
				"wh_main_eastern_sylvania_castle_drakenhof",
				"wh_main_eastern_sylvania_eschen",
				"wh_main_eastern_sylvania_waldenhof"
			}
		},
		steve_ark_crypt_horror = {
			count = 2,
			replenishment_chance = 50,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_southern_badlands_agrul_migdhal",
				"wh_main_southern_badlands_galbaraz",
				"wh_main_southern_badlands_gor_gazan",
				"wh_main_southern_badlands_gronti_mingol"
			}
		},
		steve_ark_vargheist = {
			count = 2,
			replenishment_chance = 50,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_southern_badlands_agrul_migdhal",
				"wh_main_southern_badlands_galbaraz",
				"wh_main_southern_badlands_gor_gazan",
				"wh_main_southern_badlands_gronti_mingol"
			}
		},
		steve_ark_terrorgheist = {
			count = 2,
			replenishment_chance = 25,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh_main_southern_badlands_agrul_migdhal",
				"wh_main_southern_badlands_galbaraz",
				"wh_main_southern_badlands_gor_gazan",
				"wh_main_southern_badlands_gronti_mingol"
			}
		},
		steve_ark_zmb_gunner_mob = {
			count = 2,
			replenishment_chance = 25,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh2_main_vampire_coast_pox_marsh",
				"wh2_main_vampire_coast_the_awakening",
				"wh2_main_vampire_coast_the_blood_swamps"
			}
		},
		steve_ark_zmb_handgunner_mob = {
			count = 2,
			replenishment_chance = 25,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh2_main_vampire_coast_pox_marsh",
				"wh2_main_vampire_coast_the_awakening",
				"wh2_main_vampire_coast_the_blood_swamps"
			}
		},
		steve_ark_prometheans_gunnery_mob = {
			count = 2,
			replenishment_chance = 25,
			max_count = 2,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = {
				"wh2_main_vampire_coast_pox_marsh",
				"wh2_main_vampire_coast_the_awakening",
				"wh2_main_vampire_coast_the_blood_swamps"
			}
		},
		steve_ark_skeleton_warriors = {
			count = 1,
			replenishment_chance = 60,
			max_count = 5,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		steve_ark_skeleton_spearmen = {
			count = 0,
			replenishment_chance = 55,
			max_count = 3,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
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
