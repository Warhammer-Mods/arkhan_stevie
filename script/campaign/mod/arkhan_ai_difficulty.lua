local ae = ae;

local arkhan_ai_difficulty_modifiers = {
	["easy"] = "arkhan_difficulty_AI_easy",
	["normal"] = "arkhan_difficulty_AI_normal",
	["hard"] = "arkhan_difficulty_AI_hard",
	["very hard"] = "arkhan_difficulty_AI_very_hard",
	["legendary"] = "arkhan_difficulty_AI_legendary"
};

local faction_str = "wh2_dlc09_tmb_followers_of_nagash"

function ae:setup_ai_arkhan_modifiers()

	local faction = cm:model():world():faction_by_key(faction_str);
	local difficulty_str = cm:get_difficulty(true);

	if faction:is_human() then
		self.log( "Not setting the AI difficulty modifier for human faction." );
		return false;
	else
		if arkhan_ai_difficulty_modifiers[difficulty_str] ~= nil then
			local difficulty_effect = arkhan_ai_difficulty_modifiers[difficulty_str];
			if faction:is_quest_battle_faction() == false and faction:has_effect_bundle(difficulty_effect) == false then
				cm:apply_effect_bundle(difficulty_effect, faction:name(), 0);
				self:log( "Permanently applied [",  difficulty_effect, "] to [", faction:name(), "]" );
				return true;
			end
		end
	end
end


cm:add_first_tick_callback(
	function()
		ae:log( "Setting up Arkhan AI difficulty modifiers…" );
		ae:setup_ai_arkhan_modifiers();
	end
);
