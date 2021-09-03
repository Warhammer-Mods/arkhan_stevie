--- Arkhan Raise Dead mechanic
---@author Mortarch of Sacrement <83952869+Zalbardeon@users.noreply.github.com>, im-mortal <im.mortal@me.com>
---@version 0.4.2-dev
---@class STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC
---@alias ardm STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC

local STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC = {
	__tostring = function() return "stephen_ardm"; end,

	_unit = {
		prototype = {
			count = 1,
			replenishment_chance = 100,
			max_count = 1,
			max_replenishment = 1,
			level = 0,
			technology_required = "",
			partial_replenishment = false,
			regions = "global"
		}
	},

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
	},

	name = "Arkhan Raise Dead Mechanic Stevie",

	settings = {
		faction_key = "wh2_dlc09_tmb_followers_of_nagash",
		subculture_key = "",

		deployment_modes = {
			default       = true,  -- All regions on start, aka "global"
			own_provinces = true   -- Only own provinces once fully taken
		},

		region_keywords = {
			global = {
				global = true,
				any    = true,
				all    = true
			}
			-- TODO: is adding to "sea" regions possible?
		}

	}

}

local mod = STEPHEN_ARKHAN_RAISE_DEAD_MECHANIC;
setmetatable(mod, mod);

local s = mod.settings;

--- Mod logger function.
--- If `1` passed as the first parameter, output using `script_error()`.
---@param e any
---@vararg any
---@return nil
function mod:log(e, ...)
	local arg = {...};
	local message = self.name .. ": ";
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

--- Recursive table logger
---@param e any
---@return nil
function mod:deepPrint(e)

	if e == nil then
		self:log( 1, "passed nil to deepPrint()" );
		return false;
	end

	local function recurse(input, indent)
		indent = indent or "";
		if is_table(input) then
			indent = indent .. "\t";
			for key, value in pairs(input) do
				self:log(indent, key);
				recurse(value, indent);
			end
		else
			self:log(indent, tostring(input))
		end
	end
	recurse(e);
end

--- Helper function to check if an element present in a set.
--- Is *not* recursive
--- Was it really necessary?
---@param set table
---@param key string|table
---@return boolean
function mod:setContains(set, key)
	if is_table(set) then
		if is_table(key) then
			for k, v in pairs(key) do
				if set[v] then
					return set[v];
				end
			end
		elseif is_string(key) and set[key] ~= nil then
			return set[key];
		end
	end
end

--- Helper function to recursively `setmetatable()` for all tables in a passed table
--- getmetatable(table).name and tostring(table) all return table's name
--- Overengineering FTW
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

--- Register and initialize a module table in a module script file
---@param units_table table
---@return boolean
function mod:register_table(units_table)

	local debug_info = debug.getinfo(2, "S"); -- TODO: No other way to get filename?
	local file_path = debug_info.source;

	if not is_table(units_table) then
		self:log( 1, "Invalid arguments for ardm:register_table() were passed in [", file_path, "]" );
		return false;
	end

	-- Make sure values are uniform
	local domain = string.lower(tostring(units_table.name));
	local dep    = string.lower(tostring(units_table.deployment_mode));
	local build  = math.floor( math.abs(units_table.build_number)) or 0;

	local units  = units_table.units;

	-- Check for mandatory parameters
	if (
		#domain < 1 or
		#dep < 1 or
		not next(units)
	) then
		self:log( 1, "Invalid arguments for ardm.register_table() were passed in [", file_path, "]" );
		return false;
	end

	self:log("Registering [", domain, "] table with deployment mode [", dep, "]…");

	self.units_table[dep] = self.units_table[dep] or {name = dep}; --Make sure model tables exist from now on
	self.units_table[dep][domain] = self.units_table[dep][domain] or {};
	local b = self.units_table[dep][domain].build_number;

	if ( b ~= nil and b >= build ) then

		self:log( 1, "A unit table for deployment mode [", dep, "] is already registered for module [", domain, "], aborting…" );
		return false;

	elseif not self:setContains(s.deployment_modes, dep) then

		self:log( 1, "Deployment mode [", dep, "] is not recognized as valid for module [", domain, "], aborting…" );
		return false;

	else

		self.units_table[dep][domain] = {
			name = domain,
			build_number = build,
			deployment_mode = dep,
			units = units
		};

		self:log("Successfully registered [", domain, "] table with deployment mode [", dep, "]!");

	end

end

---Builds a list of regions, one from each province.
---Since `cm:add_unit_to_province_mercenary_pool()` takes region object as an input,
---passing all regions from a province is suboptimal.
---@return nil
function mod:uniqueRegionList()
	local region_manager = cm:model():world():region_manager();
	local all_regions = region_manager:region_list();
	local provinces = {};
	self.unique_regions = {};

	-- Traversing through world regions list and building the province list
	for i = 0, all_regions:num_items() - 1 do
		local region = all_regions:item_at(i);
		local province = region:province_name();

		provinces[province] = provinces[province] or {regions = {}};
		table.insert(provinces[province]["regions"], region:name());
	end

	-- Caching the first region from each province
	for _, province in pairs(provinces) do
		table.insert(self.unique_regions, province["regions"][1])
	end

end

---Main population function
---@param units_table table
---@param region_restriction? CA_REGION
---@return boolean
function mod:populateMercenaryPools(units_table, region_restriction)
	self:log( tostring(mod), ":populateMercenaryPools() initialized" );
	local deployment_mode;
	local plural = "";

	if not is_table(units_table) then
		self:log( 1, "[", units_table, "] is not a table" );
		return false;
	elseif next(units_table) == false then
		self:log( 1, "[", units_table, "] is empty" );
		return false;
	elseif ( region_restriction ~= nil and region_restriction:is_null_interface() ) then
		self:log( 1, "[", region_restriction, "] is not a valid region object" );
		return false;
	else
		deployment_mode = string.lower(tostring(getmetatable(units_table).name));
		if region_restriction ~= nil then plural = "s"; end
		self:log( "Populating mercenary pool", plural, " using [", deployment_mode, "] deployment mode…" );
	end

	local region_manager = cm:model():world():region_manager();
	local region = region_restriction or nil;

	--- Wrapper function for CA's cm:add_unit_to_province_mercenary_pool()
	--- to reduce its whopping number of eleven arguments to just two
	--- with a few additional checks and an exit status
	---@param region CA_REGION
	---@param unit table
	---@return boolean
	local function addUnitToProvinceMercenaryPool(region, unit)
		if ( region:is_null_interface() == false and is_table(unit) ) then

			--self:log( "proceeding with region [", region:name(), "]" );
			cm:add_unit_to_province_mercenary_pool(
				region,                      -- REGION_SCRIPT_INTERFACE
				unit.name,                   -- unit
				unit.count,                  -- count
				unit.replenishment_chance,   -- replenishment chance
				unit.max_count,              -- max units
				unit.max_replenishment,      -- max per turn
				unit.level,                  -- xp
				s.faction_key,               -- faction restriction
				s.subculture_key,            -- subculture restriction
				unit.technology_required,    -- tech restriction
				unit.partial_replenishment   -- partial replenishment
			);
			self:log( "added unit [", unit.name, "] to region [", region:name(), "]" );

			return true;

		else

			self:log( 1, "Invalid parameters passed to addUnitToProvinceMercenaryPool()")
			return false;

		end

	end

	local function addUnitToGlobalMercenaryPools(unit)
		self:log( "Adding [", unit.name, "] to mercenary pools globally…" );

		-- Traversing through world regions list
		for _, region in pairs(self.unique_regions) do
			local region = region_manager:region_by_key(region);
			addUnitToProvinceMercenaryPool(region, unit);
		end

	end

	--- Parse units options and add to region
	---@param units table
	---@param region_restriction? CA_REGION
	local function addUnits(units, region_restriction)

		self:log( "addUnits() called");

		if region_restriction and region_restriction:is_null_interface() then
			region_restriction = nil;
		elseif (
			not is_table(units) and
			not next(units)
		) then
			self:log( 1, "Invalid arguments passed for addUnits()" )
			return false;
		end

		for i, unit in pairs(units) do

			-- Set unit defaults
			getmetatable(unit).__index = function(key) return self._unit.prototype[key] end;
			getmetatable(unit).__tostring = function() return getmetatable(unit).name end;
			unit.name = tostring(unit) or i; -- Make sure unit.name is set

			self:log( "Processing unit [", unit.name, "]…" );

			if is_string(unit.regions) then

				if self:setContains(s.region_keywords.global, unit.regions) then -- GLOBAL

					if region_restriction == nil then
						addUnitToGlobalMercenaryPools(unit);
					else
						addUnitToProvinceMercenaryPool(region_restriction, unit);
					end

				elseif region_manager:region_by_key(unit.regions):is_null_interface() == false then

					local region = region_manager:region_by_key(unit.regions);
					addUnitToProvinceMercenaryPool(region, unit);

				end

			elseif is_table(unit.regions) then

				self:log( "Adding [", unit.name, "] to a predefined region list…" );

				for _, v in pairs(unit.regions) do

					if region_manager:region_by_key(v):is_null_interface() == false then

						local region = region_manager:region_by_key(v);

						if (
							region_restriction == nil or
							region_restriction:name() == region:name()
						) then
							self:log("proceeding with region [", region:name(), "]…")
							addUnitToProvinceMercenaryPool(region, unit);
						end

					elseif self:setContains(s.region_keywords.global, v) then

						if region_restriction == nil then
							addUnitToGlobalMercenaryPools(unit);
						else
							addUnitToProvinceMercenaryPool(region_restriction, unit);
						end

					else
						self:log( 1, "region [", v, "] is not recognized as game region or a keyword" );
					end

				end

			else

				self:log( 1, "an error has occured" );

			end

		end

		return true;

	end

	self:log( "Processing [", deployment_mode, "] units table…");

	--Traversing through units table.
	--`domain` represents semantic grouping of units into base game units, `vanilla`,
	--and any other 3rd-party units possibly added by modules
	for _, domain in pairs(units_table) do

		if is_table(domain) then

			local build_saved_named_value = tostring(self) ..
				".modules." .. domain.name .. "." .. getmetatable(units_table).name;

			if deployment_mode == "default" then

				build_saved_named_value = build_saved_named_value .. ".build_number";
				local build_saved = cm:get_saved_value(build_saved_named_value) or 0;

				self:log(domain.name, ".build_saved = " .. build_saved)

				if ( build_saved == 0 or domain.build_number ~= nil and domain.build_number > build_saved ) then
					self:log( "Processing [", domain.name, "]@", domain.build_number or build_saved, " units…" );

					if addUnits(domain.units, region) then
						cm:set_saved_value(build_saved_named_value, domain.build_number);
					end

				else

					self:log(
						"Not processing [",
						domain.name, "]@",
						domain.build_number or build_saved,
						" as it has already been deployed!"
					);

				end

			elseif deployment_mode == "own_provinces" and region:is_null_interface() == false then

				build_saved_named_value = build_saved_named_value .. "." .. region:province_name() .. ".build_number";
				local build_saved = cm:get_saved_value(build_saved_named_value) or 0;

				self:log(domain.name, ".build_saved = ", build_saved)

				if ( build_saved == 0 or domain.build_number ~= nil and domain.build_number > build_saved ) then
					self:log( "Processing [", domain.name, "]@", domain.build_number or build_saved, " units…" );

					if addUnits(domain.units, region) then
						cm:set_saved_value(build_saved_named_value, domain.build_number);
					end

				else

					self:log(
						"Not processing [",
						domain.name, "]@",
						domain.build_number or build_saved,
						" as it has already been deployed!"
					);

				end

			end

			self:log( "Processed [", domain.name, "] units" );

		end

	end

	self:log( "Done!" );

	return true;

end

function mod:init()
	mod:log( "FIRST TICK REGISTERED" );
	mod:log( "Caching region list…" );
	self:uniqueRegionList();
	mod:setmetatable(mod.units_table, "units_table");
end

---@diagnostic disable-next-line: lowercase-global
function _G.get_ardm()
	return core:get_static_object("ardm");
end

core:add_static_object( "ardm", mod, false );

_G.ardm = _G.get_ardm();


----------------------------------
--------------EVENTS--------------
----------------------------------

-- Run only in a campaign
if core:is_campaign() then

	cm:add_first_tick_callback(
		function(context)

			mod:init();

			mod:log( "populating default/global mercenary pools for ", s.faction_key );
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
				mod:log("Region [", region:name(), "] taken!")
				if owner:holds_entire_province(province, false) then
					mod:log("Province [", province, "] is under control!")
				end
			end
			return owner:name() == s.faction_key and owner:holds_entire_province(province, false);
		end,
		function(context)
			local region = context:region();
			mod:log( "Fired [", tostring(mod), "_ProvinceTaken] event!" );
			mod:populateMercenaryPools(mod.units_table.own_provinces, region);
		end,
		true
	);

end
