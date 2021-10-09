local arkhan_tmb_tomb_king_unlocks = "tech_arkhan_lord";
local arkhan_tmb_tomb_king_unlocks_techs = {
		["tech_arkhan_lord_top_left"] = {
			forename = "names_name_159753853",
			surname = "",
			subtype = "arkhan_tmb_tomb_king_grief"
		},
		["tech_arkhan_lord_top_right"] = {
			forename = "names_name_159753854",
			surname = "",
			subtype = "arkhan_tmb_tomb_king_sacrament"
		},
		["tech_arkhan_lord_extra_left_lord_unlock"] = {
			forename = "names_name_159753855",
			surname = "",
			subtype = "arkhan_tmb_tomb_king_madness"
		},
		["tech_arkhan_lord_extra_right_lord_unlock"] = {
			forename = "names_name_159753856",
			surname = "",
			subtype = "arkhan_tmb_tomb_king_terror"
		}
};

local function STEPHEN_DynastyTree_ResearchCompleted(context)
		local faction = context:faction();
		local tech_key = context:technology();

		if faction:is_human() == true and faction:culture() == "wh2_dlc09_tmb_tomb_kings" then
			-- SPAWN LORDS
			if tech_key:starts_with(arkhan_tmb_tomb_king_unlocks) then
				local lord = arkhan_tmb_tomb_king_unlocks_techs[tech_key];

				if lord ~= nil then
					cm:spawn_character_to_pool(
						faction:name(),
						lord.forename,
						lord.surname,
						"",
						"",
						18,
						true,
						"general",
						lord.subtype,
						true,
						""
					);
				end
			end
		end
end

cm:add_first_tick_callback(function()
		core:add_listener(
			"STEPHEN_DynastyTree_ResearchCompleted",
			"ResearchCompleted",
			true,
			function(context)
				STEPHEN_DynastyTree_ResearchCompleted(context);
			end,
			true
		);
end)
