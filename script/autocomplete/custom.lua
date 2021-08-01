----------------------------------------
-----------CUSTOM ADDITIONS-------------
----------------------------------------

-- Game APIs not covered by PJ

----------------------------------------
-----------------CORE-------------------
----------------------------------------

---Retrieves a unique integer number. Each number is 1 higher than the previous unique number, with the sequence starting at 1.
---This functionality is useful for scripts that need to generate unique identifiers. The ascending sequence is not saved into a campaign savegame.
---An optional string classification may be provided. For each classification a new ascending integer is created and maintained.
---@param object_name string
---@param object object
---@param classification string
---@param is_overwrite boolean
---@return nil
function CORE:add_static_object(object_name, object, classification, is_overwrite) end

---Returns the static object previously registered with the supplied string name and optional classification using `core:add_static_object`,
---if any such object has been registered, or nil if no object was found.
---@param object_name string
---@return object
function CORE:get_static_object(object_name) end

----------------------------------------
-----------CAMPAIGN MANAGER-------------
----------------------------------------

-- First Tick

---Registers a function to be called before any other first tick callbacks.
---Callbacks registered with this function will be called regardless of what mode the campaign is being loaded in.
---@param callback function
function CM:add_pre_first_tick_callback(callback) end

-- Province and Faction Mechanics

--- Adds one or more units of a specified type to the mercenary pool in a province.
--- These units can then be recruitable by that faction (or potentially other factions) using gameplay mechanics such as Raising Dead.
---@param region CA_REGION
---@param unitkey string
---@param count number
---@param replenishment_chance number
---@param max_count number
---@param max_replenishment_per_turn number
---@param level number
---@param faction_restriction string
---@param subculture_restriction string
---@param tech_restriction string
---@param partial_replenishment boolean
function CM:add_unit_to_province_mercenary_pool(region, unitkey, count, replenishment_chance, max_count, max_replenishment_per_turn, level, faction_restriction, subculture_restriction, tech_restriction, partial_replenishment) end

--- Adds one or more of a specified unit to the specified province mercenary pool.
--- The province is specified by a region within it.
--- Unlike with cm:add_unit_to_province_mercenary_pool, the unit type must already be represented in the pool.
---@param region_key string
---@param unitkey string
---@param count number
function CM:add_units_to_province_mercenary_pool_by_region(region_key, unitkey, count) end

