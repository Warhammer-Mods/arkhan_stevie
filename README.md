# Arkhan Raise Dead Mechanic Stevie
A mod for Total War: Warhammer 2 that enables Raise Dead campaign mechanic for the Followers of Nagash faction (Arkhan the Black).

## Features
- Enables Raising Dead Feature for the Followers of Nagash for campaign map
  - Raise Dead is available for all provinces with varying units available in each
- Carefully picked list of units for lore-friendly experience
  - Vanilla units are fully covered, submods for modded units are also available
- With Arkhan the Black growing more powerful with his mastery of the Dark Arts, he gets more potent undead monsters at his disposal
  - As Followers of Nagash prepare for their Master to return by taking the world piece by piece, the corrupted ground under Arkhan's feet itself awakens more powerful hordes imbued with Nagash's power to surge the world of the living and treacherous undead

## Notes
- Province mercenary pools for Arkhan will be populated upon new game start or loading an existing save
- Additionally, an extended set of units will be added to conquered provinces
  - The mod will keep mercenary pools of respective provinces up to date even if loaded mid-game or after (sub)mod updates.
- Just like Raise Dead mechanic feature of other factions, you may have to wait a few turns for new units to appear
  - This includes units that require certain buildings/technologies to unlock first

## Submods
TBA

## Public API
- `ardm:register_table(table)`
  - `table`:
```lua
{
  name = "string",             -- an arbitrary name for the table
  build_number = number,       -- build number, incremented with each update to the table
  deployment_mode = "string",  -- unit spawn behaviour, see below
  units = {
    main_units_table_unit_key = {        -- unit key from "main_units_tables"
      count = number,                      -- how many units to initially spawn
      replenishment_chance = number,       -- replenishment chance per turn in percent
      max_count = number,                  -- number of units in a pool before they stop replenish
      max_replenishment = number,          -- how many units may possibly be replenished per turn
      level = number,                      -- unit experience (rank), from 0 to 9
      technology_required = "string",      -- technology key from "technologies_tables", researching which shall grant access to Raising this unit(s)
      partial_replenishment = boolean,     -- is eligible for partial replenishment per turn
      regions = "string"|{                 -- target region(s)
        "table",
        "of",
        "region",
        "keys"
      }
  }
}
```

Where:
  - `deployment_mode` is one of the following:
    - `default` spawns units on new game start or loading an existing save if `build_number` is greater than that of an earlier deployed table of the same name.
    - `own_provinces` spawns units on taking a whole province, overwriting existing units in pools of the same key.
  - `regions` is either a string or a table:
    - as `string`:
      - `global` | `all` | `any`
        spawns the unit globally to all provinces;
    - as `table`:
      - a list of region key strings from `regions_tables` db:
        `{"region_key_1", "region_key_2"}`

Other options are quite self-explanatory.

## Example submod
`script/campaign/mod/my_example_submod.lua`:
```lua
local ardm = ardm

ardm:register_table({
  name = "arkhans_pets",
  build_number = 1,
  deployment_mode = "default",
  units = {
    wh2_dlc09_tmb_mon_dire_wolves = {
      count = 1,
      replenishment_chance = 75,
      max_count = 4,
      max_replenishment = 1,
      level = 0,
      technology_required = "some_technology_key",
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
    wh_main_vmp_mon_terrorgheist = {
      count = 0,
      replenishment_chance = 3,
      max_count = 1,
      max_replenishment = 1,
      level = 0,
      technology_required = "",
      partial_replenishment = true,
      regions = {
        "wh2_main_great_mortis_delta_black_pyramid_of_nagash",
        "wh2_main_the_broken_teeth_nagashizar",
        "wh_main_desolation_of_nagash_spitepeak"
      }
    }
  })

  ardm:register_table({
    name = "arkhans_pets",
    build_number = 1,
    deployment_mode = "own_provinces",
    units = {
      wh2_dlc09_tmb_mon_dire_wolves = {
        count = 3,
        replenishment_chance = 90,
        max_count = 4,
        max_replenishment = 1,
        level = 1,
        technology_required = "",
        partial_replenishment = false,
        regions = "global"
      },
      wh2_dlc09_tmb_mon_fell_bats = {
        count = 3,
        replenishment_chance = 100,
        max_count = 4,
        max_replenishment = 1,
        level = 1,
        technology_required = "",
        partial_replenishment = false,
        regions = "global"
      },
      wh_main_vmp_mon_terrorgheist = {
        count = 1,
        replenishment_chance = 13,
        max_count = 1,
        max_replenishment = 1,
        level = 1,
        technology_required = "",
        partial_replenishment = true,
        regions = {
          "wh2_main_great_mortis_delta_black_pyramid_of_nagash",
          "wh2_main_the_broken_teeth_nagashizar",
          "wh_main_desolation_of_nagash_spitepeak"
        }
      }
    }
})
```
