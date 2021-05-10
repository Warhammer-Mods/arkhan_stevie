STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC or {}
local mod = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC
mod.name = "Arkhan Raise Dead Mechanic Stevie"

out(mod.name .. " script file loaded");

mod.activated = 0; -- To run or not to run?

-- Define dictionary containing units and properties to populate Raising Dead mercenary pool with
-- To be expanded to cover modded units
mod.units_to_add_globally = {
	["vanilla"] = {
		{ ["name"] = "wh2_dlc09_tmb_mon_dire_wolves",         ["count"] = 2, ["replenishment_chance"] = 100, ["max_count"] = 4, ["max_replenishment"] = 1, ["level"] = 0, ["technology_required"] = "", ["partial_replenishment"] = false },
		{ ["name"] = "wh2_dlc09_tmb_mon_fell_bats",           ["count"] = 2, ["replenishment_chance"] = 100, ["max_count"] = 4, ["max_replenishment"] = 1, ["level"] = 0, ["technology_required"] = "", ["partial_replenishment"] = false },
		{ ["name"] = "wh2_dlc09_tmb_inf_crypt_ghouls",        ["count"] = 2, ["replenishment_chance"] = 100, ["max_count"] = 4, ["max_replenishment"] = 1, ["level"] = 0, ["technology_required"] = "", ["partial_replenishment"] = false },
		{ ["name"] = "wh2_dlc09_tmb_inf_skeleton_warriors_0", ["count"] = 2, ["replenishment_chance"] = 100, ["max_count"] = 5, ["max_replenishment"] = 1, ["level"] = 0, ["technology_required"] = "", ["partial_replenishment"] = false },
		{ ["name"] = "wh2_dlc09_tmb_inf_skeleton_spearmen_0", ["count"] = 1, ["replenishment_chance"] = 100, ["max_count"] = 3, ["max_replenishment"] = 1, ["level"] = 0, ["technology_required"] = "", ["partial_replenishment"] = false }
	}
};

function mod:arkhan_populate_mercenary_pools()
	local faction_name = "wh2_dlc09_tmb_followers_of_nagash";

	-- Main action
	-- Iterating through all regions (provinces) first
	local all_regions = cm:model():world():region_manager():region_list();

	for i = 0, all_regions:num_items() - 1 do
		local region = all_regions:item_at(i);

		-- Populating province mercenary pool
		for i1, domain in pairs(mod.units_to_add_globally) do
			for i2 in pairs(domain) do
				local unit = domain[i2];
				out(mod.name .. ": adding " .. unit.name .. " to " .. region:name() );
				cm:add_unit_to_province_mercenary_pool(
					region,                     -- REGION_SCRIPT_INTERFACE
					unit.name,                  -- unit
					unit.count,                 -- count
					unit.replenishment_chance,  -- replenishment chance
					unit.max_count,             -- max units
					unit.max_replenishment,     -- max per turn
					unit.level,                 -- xp
					faction_name,               -- faction restriction (is it really needed?)
					"",                         -- subculture restriction
					unit.technology_required,   -- tech restriction
					unit.partial_replenishment  -- partial replenishment
				);
			end
		end
	end
	
	return true;
end

cm:add_first_tick_callback(
	function()
		out(mod.name .. ": FIRST TICK REGISTERED");
		if ( cm:is_new_game() == true or mod.activated == 0 ) then
			out(mod.name .. ": populating mercenary pools for Followers of Nagash");
			mod:arkhan_populate_mercenary_pools();
			mod.activated = 1;
		end
	end
)

--------------------------------------------------------------
----------------------- SAVING / LOADING ---------------------
--------------------------------------------------------------
cm:add_saving_game_callback(
	function(context)
		out(mod.name .. ": SAVING");
		cm:save_named_value("stephen_arkhan_raise_dead_mechanic", mod.activated, context);
	end
);

cm:add_loading_game_callback(
	function(context)
		out(mod.name .. ": LOADING")
		mod.activated = cm:load_named_value("stephen_arkhan_raise_dead_mechanic", mod.activated, context);
	end
);
