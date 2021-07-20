local ardm = ardm

-- General module info

local table_name = "vanilla"

--[[ Please use only whole (integer) numbers.
		 Increment build number each time a change to mercenary pools below is made.
		 This defines if the game should update pools records for existing savegames.
     Mercenary pool entries are additive, meaning any existing entries within a
     save file will be overridden and their pool fully replenished, and old entries
     no longer presented in the table below will continue to exist as usual.
]]
local table_build_number = 2

--[[ Deployment mode of units. Following modes are supported:
		 "default": spawn units globally upon game start
		 "own_provinces": spawn units for own provinces only once fully conquered. Note: units will stay even if the province is lost.
]]
local table_deployment_mode = "default"

--[[ Define dictionary containing units and properties
		 to populate global Raising Dead mercenary pool with.
		 Defaults will be used for missing fields:
			count = 1,
			replenishment_chance = 100,
			max_count = 1,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"

		 TODO: To be finalized
]]
ardm:register_table({
	name = table_name,
	build_number = table_build_number,
	deployment_mode = table_deployment_mode,
	units = {
		wh2_dlc09_tmb_mon_dire_wolves = {
			count = 1,
			replenishment_chance = 75,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		wh2_dlc09_tmb_mon_fell_bats = {
			count = 1,
			replenishment_chance = 80,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		wh2_dlc09_tmb_inf_crypt_ghouls = {
			count = 1,
			replenishment_chance = 70,
			max_count = 4,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
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
		}
	}
})

-- Registering multiple tables within a single submod/file is possible.
-- Below is an example of inline table definition.
-- TODO: Define dictionary containing units and properties
ardm:register_table({
	name = "vanilla",
	build_number = 2,
	deployment_mode = "own_provinces",
	units = {
		wh2_dlc09_tmb_mon_dire_wolves = {
			count = 3,
			replenishment_chance = 90,
			max_count = 6,
			max_replenishment = 1,
			level = 1,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		wh2_dlc09_tmb_mon_fell_bats = {
			count = 3,
			replenishment_chance = 95,
			max_count = 6,
			max_replenishment = 1,
			level = 1,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		wh2_dlc09_tmb_inf_crypt_ghouls = {
			count = 2,
			replenishment_chance = 85,
			max_count = 6,
			max_replenishment = 1,
			level = 1,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		wh2_dlc09_tmb_inf_skeleton_warriors_0 = {
			count = 1,
			replenishment_chance = 75,
			max_count = 6,
			max_replenishment = 1,
			level = 1,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		},
		wh2_dlc09_tmb_inf_skeleton_spearmen_0 = {
			count = 1,
			replenishment_chance = 65,
			max_count = 4,
			max_replenishment = 1,
			level = 1,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		}
	}
})
