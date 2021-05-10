STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC or {}
local mod = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC

-- Define dictionary containing units and properties to populate Raising Dead mercenary pool with
-- To be expanded to cover modded units
mod.units = {
	["vanilla"] = {
		{
			["name"] = "wh2_dlc09_tmb_mon_dire_wolves",
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 4,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		{
			["name"] = "wh2_dlc09_tmb_mon_fell_bats",
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 4,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		{
			["name"] = "wh2_dlc09_tmb_inf_crypt_ghouls",
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 4,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		{
			["name"] = "wh2_dlc09_tmb_inf_skeleton_warriors_0",
			["count"] = 2,
			["replenishment_chance"] = 100,
			["max_count"] = 5,
			["max_replenishment"] = 1,
			["level"] = 0,
			["technology_required"] = "",
			["partial_replenishment"] = false,
			["regions"] = "global"
		},
		{
			["name"] = "wh2_dlc09_tmb_inf_skeleton_spearmen_0",
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
	["modded"] = {
		-- TODO: add modded units
		-- rename "modded" to actual mod name
		-- each mod goes into its separate subtable
	}
}