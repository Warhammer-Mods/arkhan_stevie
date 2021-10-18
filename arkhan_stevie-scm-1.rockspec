package = "arkhan_stevie"
version = "scm-1"
source = {
   url = "git+https://github.com/Warhammer-Mods/arkhan_stevie.git"
}
description = {
   detailed = "![Arkhan the Black: Expanded – Logo](https://github.com/Warhammer-Mods/assets/blob/master/mods/arkhan_stevie/steam_workshop.png?raw=1)",
   homepage = "https://github.com/Warhammer-Mods/arkhan_stevie"
}
dependencies = {
   "lua ~> 5.1",
   "tw-lua-autocomplete"
}
build = {
   type = "builtin",
   modules = {
      ["script._lib.mod.arkhan_expanded"] = "script/_lib/mod/arkhan_expanded.lua",
      ["script.campaign.mod.arkhan_ai_difficulty"] = "script/campaign/mod/arkhan_ai_difficulty.lua",
      ["script.campaign.mod.arkhan_raise_dead_mechanic_units_arkhan_stevie"] = "script/campaign/mod/arkhan_raise_dead_mechanic_units_arkhan_stevie.lua",
      ["script.campaign.mod.arkhan_raise_dead_mechanic_units_vanilla"] = "script/campaign/mod/arkhan_raise_dead_mechanic_units_vanilla.lua",
      ["script.campaign.mod.arkhan_tmb_tomb_king_unlocks"] = "script/campaign/mod/arkhan_tmb_tomb_king_unlocks.lua"
   }
}
