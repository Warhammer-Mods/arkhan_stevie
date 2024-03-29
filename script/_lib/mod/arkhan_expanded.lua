-- local inspect = require "inspect"

---Arkhan Raise Dead mechanic
---@author Mortarch of Sacrement <83952869+Zalbardeon@users.noreply.github.com>, im-mortal <im.mortal@me.com>
---@version 0.5.4-dev
---@class STEPHEN_ARKHAN_EXPANDED
---@alias arkhan_expanded STEPHEN_ARKHAN_EXPANDED
---Legacy alias
---@alias ardm STEPHEN_ARKHAN_EXPANDED
local STEPHEN_ARKHAN_EXPANDED = {
	__tostring = function() return "STEPHEN_ARKHAN_EXPANDED"; end,

	units_table = {
	--[[ SCHEMA
		deployment_mode = {
			domain = {
				name                    string,
				build_number            number,
				deployment_mode         string,
				units = {
					unit = {
						name                  string,
						count                 number,
						replenishment_chance  number,
						max_count             number,
						max_replenishment     number,
						level                 number,
						technology_required   string,
						partial_replenishment boolean,
						regions = {           table|string
							region              string
						}
					}
				}
			}
		}
	]]
	}

}

local mod = STEPHEN_ARKHAN_EXPANDED;
setmetatable(mod, mod);

mod.name = "Arkhan the Black: Expanded";

---@class _unit
---@field name string
---@field count number
---@field replenishment_chance number
---@field max_count number
---@field max_replenishment number
---@field level number
---@field technology_required string
---@field partial_replenishment boolean
---@field regions string | table
mod._unit = {
	name                  = "",
	count                 = 1,
	replenishment_chance  = 100,
	max_count             = 1,
	max_replenishment     = 1,
	level                 = 0,
	technology_required   = "",
	partial_replenishment = false,
	regions               = "global"
}

mod._cache = {}
mod._cache_meta = {
	--set corresponding table's keys weak
	__mode = "k"
}
setmetatable(mod._cache, mod._cache_meta)

mod.settings = {
	faction_key    = "wh2_dlc09_tmb_followers_of_nagash",
	subculture_key = "",

	deployment_modes = {
		default       = true,  --All regions on start, aka "global"
		own_provinces = true   --Only own provinces once fully taken
	},

	region_keywords = {
		global = {
			global = true,
			any    = true,
			all    = true
		}
	}

}

mod.state = {};

local s = mod.settings;
local cache = mod._cache;

---Mod logger function.
---If `1` passed as the first parameter, output using `script_error()`.
---@param e any
---@vararg any
---@return nil
function mod.log(e, ...)
	local arg = {...};
	local message = mod.name .. ": ";
	if e ~= 1 then
		message = message .. tostring(e);
	end
	for _, v in ipairs(arg) do
		message = message .. tostring(v);
	end
	if (e == 1) then
		out("ERROR:\t" ..  message);
		script_error(message);
	else
		out(message);
	end
end

---Helper function to check if an element present in a set.
---@param set table
---@param key string|table
---@return boolean
function mod:setContains(set, key)
	if is_table(set) then
		if is_table(key) then
			for _, v in pairs(key) do
				if set[v] then
					return set[v];
				elseif is_table(set[v]) then
					self:setContains(set[v], key)
				end
			end
		elseif is_string(key) and set[key] ~= nil then
			if set[key] then
				return set[key];
			elseif is_table(set[key]) then
				self:setContains(set[key], key)
			end
		end
	end
end

---Helper function to recursively `setmetatable()` for all tables in a passed table
---getmetatable(table).name and tostring(table) all return table's name
---Overengineering FTW
---@param table table
---@param name string
---@return table
function mod:setmetatable(table, name)
	if is_table(table) then
		for k, v in pairs(table) do
			if is_table(v) then
				setmetatable(v, {__tostring = function () return k end, name = k});
				self:setmetatable(v, k);
			end
		end
		if ( is_string(name) ) then
			setmetatable(table, {__tostring = function () return name end, name = name});
		end
		return getmetatable(table);
	else
		return false;
	end
end

---Register and initialize a module table in a module script file
---@param units_table table
---@return boolean
function mod:register_table(units_table)

	local debug_info = debug.getinfo(2, "S"); --TODO: No other way to get filename?
	local file_path = debug_info.source;

	if not is_table(units_table) then
		self.log( 1, "Invalid arguments for ardm:register_table() were passed in [", file_path, "]" );
		return false;
	end

	--Make sure values are uniform
	local domain = string.lower(tostring(units_table.name));
	local dep    = string.lower(tostring(units_table.deployment_mode));
	local build  = math.floor( math.abs(units_table.build_number)) or 0;

	local units  = units_table.units;

	--Check for mandatory parameters
	if (
		#domain < 1 or
		#dep < 1 or
		not next(units)
	) then
		self.log( 1, "Invalid arguments for ardm.register_table() were passed in [", file_path, "]" );
		return false;
	end

	self.log("Registering [", domain, "] table with deployment mode [", dep, "]…");

	self.units_table[dep] = self.units_table[dep] or {name = dep}; --Make sure model tables exist from now on
	self.units_table[dep][domain] = self.units_table[dep][domain] or {};
	local b = self.units_table[dep][domain].build_number;

	if ( b ~= nil and b >= build ) then

		self.log( 1,
			"A unit table for deployment mode [",
			dep, "] is already registered for module [",
			domain, "], aborting…"
		);
		return false;

	elseif not self:setContains(s.deployment_modes, dep) then

		self.log( 1,
			"Deployment mode [",
			dep, "] is not recognized as valid for module [",
			domain, "], aborting…"
		);
		return false;

	else

		self.units_table[dep][domain] = {
			name = domain,
			build_number = build,
			deployment_mode = dep,
			units = units
		};

		self.log("Successfully registered [", domain, "] table with deployment mode [", dep, "]!");

	end

end

---Main province mercenary pool population function
---@param units_table table
---@param region_restriction? REGION_SCRIPT_INTERFACE
---@return boolean
function mod:populateMercenaryPools(units_table, region_restriction)
	self.log( tostring(mod), ":populateMercenaryPools() initialized" );
	local deployment_mode;
	local plural = "";

	if not is_table(units_table) then
		self.log( 1, "[", units_table, "] is not a table" );
		return false;
	elseif next(units_table) == false then
		self.log( 1, "[", units_table, "] is empty" );
		return false;
	elseif ( region_restriction ~= nil and region_restriction:is_null_interface() ) then
		self.log( 1, "[", region_restriction, "] is not a valid region object" );
		return false;
	else
		deployment_mode = string.lower(tostring(getmetatable(units_table).name));
		if region_restriction ~= nil then plural = "s"; end
		self.log( "Populating mercenary pool", plural, " using [", deployment_mode, "] deployment mode…" );
	end

	local region_manager = cm:model():world():region_manager();
	local region = region_restriction or nil;

	---Wrapper function for CA's cm:add_unit_to_province_mercenary_pool()
	---to reduce its whopping number of eleven arguments
	---with a few additional checks and an exit status
	---@param region_interface REGION_SCRIPT_INTERFACE
	---@param unit _unit
	---@param faction_key string
	---@param subculture_key string
	---@return boolean
	local function addUnitToProvinceMercenaryPool(region_interface, unit, faction_key, subculture_key)
		if ( region_interface:is_null_interface() == false and is_table(unit) ) then

			--self.log( "proceeding with region [", region:name(), "]" );
			cm:add_unit_to_province_mercenary_pool(
				region_interface,            --REGION_SCRIPT_INTERFACE
				unit.name,                   --unit
				unit.count,                  --count
				unit.replenishment_chance,   --replenishment chance
				unit.max_count,              --max units
				unit.max_replenishment,      --max per turn
				unit.level,                  --xp
				faction_key,                 --faction restriction
				subculture_key,              --subculture restriction
				unit.technology_required,    --tech restriction
				unit.partial_replenishment   --partial replenishment
			);
			self.log( "added unit [", unit.name, "] to region [", region_interface:name(), "]" );

			return true;

		else

			self.log( 1, "Invalid parameters passed to addUnitToProvinceMercenaryPool()" )
			return false;

		end

	end

	local function addUnitToGlobalMercenaryPools(unit)
		self.log( "Adding [", unit.name, "] to mercenary pools globally…" );

		---Builds and caches a list of regions, one from each province.
		---Since `cm:add_unit_to_province_mercenary_pool()` takes region object as an input,
		---passing all regions from a province is suboptimal.
		---@return table
		local function cacheUniqueRegionsList()
			self.log( "Caching world regions…" );
			local all_regions = region_manager:region_list();
			local provinces, unique_regions = {}, {};

			--Traversing through world regions list and building the province list
			for i = 0, all_regions:num_items() - 1 do
				local region = all_regions:item_at(i);
				local province = region:province_name();

				provinces[province] = provinces[province] or {regions = {}};
				table.insert(provinces[province]["regions"], region:name());
			end

			--Caching the first region from each province
			for _, province in pairs(provinces) do
				table.insert(unique_regions, province["regions"][1])
			end

			cache.unique_regions = unique_regions;
			return unique_regions;
		end

		--Traversing through world regions list
		local unique_regions = cache.unique_regions or cacheUniqueRegionsList();

		for _, region in pairs(unique_regions) do
			region = region_manager:region_by_key(region);
			addUnitToProvinceMercenaryPool(region, unit, s.faction_key, s.subculture_key);
		end

	end

	---Parse units options and add to region
	---@param units table
	---@param region_restriction? REGION_SCRIPT_INTERFACE
	local function addUnits(units, region_restriction)

		self.log( "addUnits() called");

		if region_restriction and region_restriction:is_null_interface() then
			region_restriction = nil;
		elseif (
			not is_table(units) and
			not next(units)
		) then
			self.log( 1, "Invalid arguments passed for addUnits()" )
			return false;
		end

		for i, unit in pairs(units) do

			--Set unit defaults
			getmetatable(unit).__index = function(key) return self._unit[key] end;
			getmetatable(unit).__tostring = function() return getmetatable(unit).name end;
			unit.name = tostring(unit) or i; --Make sure unit.name is set

			self.log( "Processing unit [", unit.name, "]…" );

			if is_string(unit.regions) then

				if self:setContains(s.region_keywords.global, unit.regions) then --GLOBAL

					if region_restriction == nil then
						addUnitToGlobalMercenaryPools(unit);
					else
						addUnitToProvinceMercenaryPool(region_restriction, unit, s.faction_key, s.subculture_key);
					end

				elseif region_manager:region_by_key(unit.regions):is_null_interface() == false then

					local region = region_manager:region_by_key(unit.regions);
					addUnitToProvinceMercenaryPool(region, unit, s.faction_key, s.subculture_key);

				end

			elseif is_table(unit.regions) then

				self.log( "Adding [", unit.name, "] to a predefined region list…" );

				for _, v in pairs(unit.regions) do

					if region_manager:region_by_key(v):is_null_interface() == false then

						local region = region_manager:region_by_key(v);

						if (
							region_restriction == nil or
							region_restriction:name() == region:name()
						) then
							self.log("proceeding with region [", region:name(), "]…")
							addUnitToProvinceMercenaryPool(region, unit, s.faction_key, s.subculture_key);
						end

					elseif self:setContains(s.region_keywords.global, v) then

						if region_restriction == nil then
							addUnitToGlobalMercenaryPools(unit);
						else
							addUnitToProvinceMercenaryPool(region_restriction, unit, s.faction_key, s.subculture_key);
						end

					else
						self.log( 1, "region [", v, "] is not recognized as game region or a keyword" );
					end

				end

			else

				self.log( 1, "an error has occured" );

			end

		end

		return true;

	end

	self.log( "Processing [", deployment_mode, "] units table…");

	--Traversing through units table.
	--`domain` represents semantic grouping of units into base game units, `vanilla`,
	--and any other 3rd-party units possibly added by modules
	for _, domain in pairs(units_table) do

		if is_table(domain) then

			local build_saved_named_value = "raise_dead.modules." .. domain.name .. "." .. getmetatable(units_table).name;

			if deployment_mode == "default" then

				build_saved_named_value = build_saved_named_value .. ".build_number";
				local build_saved = mod.state[build_saved_named_value] or 0;

				self.log(domain.name, ".build_saved = " .. build_saved)

				if ( build_saved == 0 or domain.build_number ~= nil and domain.build_number > build_saved ) then
					self.log( "Processing [", domain.name, "]@", domain.build_number or build_saved, " units…" );

					if addUnits(domain.units, region) then
						mod.state[build_saved_named_value] = domain.build_number;
					end

				else

					self.log(
						"Not processing [",
						domain.name, "]@",
						domain.build_number or build_saved,
						" as it has already been deployed!"
					);

				end

			elseif deployment_mode == "own_provinces" and region:is_null_interface() == false then

				build_saved_named_value = build_saved_named_value .. "." .. region:province_name() .. ".build_number";
				local build_saved = mod.state[build_saved_named_value] or 0;

				self.log(domain.name, ".build_saved = ", build_saved)

				if ( build_saved == 0 or domain.build_number ~= nil and domain.build_number > build_saved ) then
					self.log( "Processing [", domain.name, "]@", domain.build_number or build_saved, " units…" );

					if addUnits(domain.units, region) then
						mod.state[build_saved_named_value] = domain.build_number;
					end

				else

					self.log(
						"Not processing [",
						domain.name, "]@",
						domain.build_number or build_saved,
						" as it has already been deployed!"
					);

				end

			end

			self.log( "Processed [", domain.name, "] units" );

		end

	end

	self.log( "Done!" );

	return true;

end

function mod:init()
	self.log( "FIRST TICK REGISTERED" );
	self:setmetatable(mod.units_table, "units_table");
end

---@diagnostic disable-next-line: lowercase-global
function get_arkhan_expanded()
	return core:get_static_object("arkhan_expanded");
end
core:add_static_object( "arkhan_expanded", mod, false );
_G.arkhan_expanded = get_arkhan_expanded();

--legacy `ardm` object
--TODO: Depreciated
---@diagnostic disable-next-line: lowercase-global
function get_ardm()
	return core:get_static_object("ardm");
end
core:add_static_object( "ardm", mod, false );
_G.ardm = get_ardm();


----------------------------------
--------------EVENTS--------------
----------------------------------

--Run only in a campaign
if core:is_campaign() then

	cm:add_first_tick_callback(
		function(context)

			mod:init();

			mod.log( "populating default/global mercenary pools for ", s.faction_key );
			mod:populateMercenaryPools(mod.units_table.default);

			local arkhan = context:world():faction_by_key(s.faction_key);
			local faction_regions = arkhan:region_list();

			for i = 0, faction_regions:num_items() - 1 do
				local region = faction_regions:item_at(i);
				if arkhan:holds_entire_province(region:province_name(), false) then
					mod:populateMercenaryPools(mod.units_table.own_provinces, region);
				end
			end

		end
	)

	core:add_listener(
		tostring(mod) .. "_ProvinceTaken",
		"RegionFactionChangeEvent",
		function(context)
			local region = context:region();
			local owner = region:owning_faction();
			local province = region:province_name();
			if owner:name() == s.faction_key then
				mod.log("Region [", region:name(), "] taken!")
				if owner:holds_entire_province(province, false) then
					mod.log("Province [", province, "] is under control!")
				end
			end
			return owner:name() == s.faction_key and owner:holds_entire_province(province, false);
		end,
		function(context)
			local region = context:region();
			mod.log( "Fired [", tostring(mod), "_ProvinceTaken] event!" );
			mod:populateMercenaryPools(mod.units_table.own_provinces, region);
		end,
		true
	);

----------------------------------
-------- SAVING / LOADING --------
----------------------------------

	cm:add_saving_game_callback(
		function(context)
			cm:save_named_value(tostring(mod) .. "_state", mod.state, context);
		end
	);

	cm:add_loading_game_callback(
		function(context)
			if cm:is_new_game() == false then
				mod.state = cm:load_named_value(tostring(mod) .. "_state", mod.state, context);
			end
		end
	);

end
