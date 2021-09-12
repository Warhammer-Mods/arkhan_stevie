---@diagnostic disable: lowercase-global

---Appends a line to the screen.
---
---Specific to [Draw Debug Logs](https://steamcommunity.com/sharedfiles/filedetails/?id=1929093751)
---@vararg any
function dout(...) end

---Clears any previous lines and shows only this line.
---
---Specific to [Draw Debug Logs](https://steamcommunity.com/sharedfiles/filedetails/?id=1929093751)
---@vararg any
function ddraw(...) end

---Appends to a `ddump.txt` file that will be created inside `steamapps\common\Total War WARHAMMER II`.
---
---Specific to [Draw Debug Logs](https://steamcommunity.com/sharedfiles/filedetails/?id=1929093751)
---@vararg any
function ddump (...) end

--Weird stuff

eight_peaks_check = function(faction_name) end
is_karak_eight_peaks_owner_faction = function(faction_name) end
