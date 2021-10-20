package = "arkhan_stevie"
version = "develop-1"
source = {
   url = "git+https://github.com/Warhammer-Mods/arkhan_stevie.git",
   tag = "develop"
}
description = {
   detailed = "This mod for Total War™ Warhammer II® makes changes to Arkhan's faction by giving him access to The Lore of Vampires, Raise Dead campaign mechanic, and much more. It also adds additional units with unique unit cards, over 20 new technologies and access to Bloodline Lords & Scrap Upgrades via the submods.",
   homepage = "https://github.com/Warhammer-Mods/arkhan_stevie"
}
dependencies = {
   "lua ~> 5.1",
   "lua-globals",
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
