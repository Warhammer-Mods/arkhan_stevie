STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC or {}
local mod = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC

--[[ Increment build number each time a change to mercenary pools below is made.
     Mercenary pool entries are additive, meaning any existing entries within a
     save file will be overridden and their pool fully replenished, and old entries
     no longer presented in the table below will continue to exist as usual.
]]
mod.build = 1;

-- Define dictionary containing units and properties to populate Raising Dead mercenary pool with
-- To be expanded to cover modded units
mod.units_table = {
	vanilla = {
		wh2_dlc09_tmb_mon_dire_wolves = {
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 4,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		wh2_dlc09_tmb_mon_fell_bats = {
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 4,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		wh2_dlc09_tmb_inf_crypt_ghouls = {
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 4,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		steve_ark_skeleton_warriors = {
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 5,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		steve_ark_skeleton_spearmen = {
			["count"] = 1,
			["replenishment_chance"] = 100,
			["max_count"] = 3,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		}
	},
	modded = {
		-- TODO: add modded units
		-- rename "modded" to actual mod name
		-- each mod goes into its separate subtable
	}
}
