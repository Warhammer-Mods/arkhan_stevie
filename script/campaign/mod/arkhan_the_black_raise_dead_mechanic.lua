STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC or {}
local mod = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC
mod.name = "Arkhan Raise Dead Mechanic Stevie"

out(mod.name .. " script file loaded");

--[[ Increment build number each time a change to mercenary pools is made.
		 Mercenary pool entries are additive, meaning any existing entries within
		 a save file will be overridden and their pool fully replenished, and old
		 entries no longer presented in the table below will continue to exist as usual.
]]
mod.build = 1;

-- Defaults
mod.build_stored = 0;

function mod:arkhan_populate_mercenary_pools()
	local faction_name = "wh2_dlc09_tmb_followers_of_nagash";
	local subculture_name = "";

	-- Main action
	-- Iterating through all regions first
	-- Each province gets its own pool shared by all regions within its boundaries
	local region_manager = cm:model():world():region_manager();
	local all_regions = region_manager:region_list();

	function mod:add_unit_to_province_mercenary_pool(region, unit)
		if region:is_null_interface() == false then
			out( mod.name .. ": proceeding with region " .. region:name() );
			cm:add_unit_to_province_mercenary_pool(
				region,                     -- REGION_SCRIPT_INTERFACE
				unit.name,                  -- unit
				unit.count,                 -- count
				unit.replenishment_chance,  -- replenishment chance
				unit.max_count,             -- max units
				unit.max_replenishment,     -- max per turn
				unit.level,                 -- xp
				faction_name,               -- faction restriction (is it really needed?)
				subculture_name,            -- subculture restriction
				unit.technology_required,   -- tech restriction
				unit.partial_replenishment  -- partial replenishment
			);
			out( mod.name .. ": added unit " .. unit.name .. " to region " .. region:name() );
			return true;
		else
			return false;
		end
	end

	for i = 0, all_regions:num_items() - 1 do
		local region;
		mod.units_table = mod.units_table or {};

		-- Populating province mercenary pool
		for _, domain in pairs(mod.units_table) do
			for i2 in pairs(domain) do
				local unit = domain[i2];
				if ( unit.regions == "global" or
				     unit.regions == "all" or
				     unit.regions == "any" )
				then
					region = all_regions:item_at(i);
					mod:add_unit_to_province_mercenary_pool(region, unit);
				elseif type(unit.region) == "table" then
					for _, region in pairs(unit.region) do
						region = region_manager:region_by_key(region);
						mod:add_unit_to_province_mercenary_pool(region, unit);
					end
				end
			end
		end
	end

	return true;
end

cm:add_first_tick_callback(
	function()
		out(mod.name .. ": FIRST TICK REGISTERED");
		if ( cm:is_new_game() == true or mod.build > mod.build_stored ) then
			out(mod.name .. ": populating mercenary pools for Followers of Nagash");
			mod:arkhan_populate_mercenary_pools();
		end
	end
)

--------------------------------------------------------------
----------------------- SAVING / LOADING ---------------------
--------------------------------------------------------------
cm:add_saving_game_callback(
	function(context)
		out(mod.name .. ": SAVING");
		cm:save_named_value("stephen_arkhan_raise_dead_mechanic_build", mod.build, context);
	end
);

cm:add_loading_game_callback(
	function(context)
		out(mod.name .. ": LOADING")
		mod.build_stored = cm:load_named_value("stephen_arkhan_raise_dead_mechanic_build", mod.build_stored, context);
	end
);
