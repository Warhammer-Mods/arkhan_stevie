#!/usr/bin/env lua
---------------------------------------------------------------------------------------------------------------------------------------
-- Display list of globals used by your Lua script
---------------------------------------------------------------------------------------------------------------------------------------
-- Version: 2019-03-28
-- License: MIT (see at the end of this file)
--
-- Reads your Lua script from STDIN
-- Writes list of globals to STDOUT (if the script is syntactically correct)
-- Writes parsing error to STDERR   (if the script is not syntactically correct)
--
-- Usage examples (both Windows and Linux):
--
--    How to display all the globals access (both read and write)
--       lua show_globals.lua RW < your_script.lua
--
--    How to display only write access to globals
--       lua show_globals.lua W < your_script.lua

local Lua_version = "Lua 5.1"  -- set here Lua version "your_script.lua" was written for

local read_write_access = (arg[1] or "RW"):upper()  -- what type of access (read/write/both) should be displayed
read_write_access = {R = read_write_access:find"R", W = read_write_access:find"W"}
assert(read_write_access.R or read_write_access.W, "First argument must be R, W or RW")

local parser
do

   local
      byte, sub, find, char, rep, match, gsub, upper, reverse, pairs, ipairs, tonumber, tostring, type, unpack, table_concat, math_min, huge
      =
      string.byte, string.sub, string.find, string.char, string.rep, string.match, string.gsub, string.upper, string.reverse,
      pairs, ipairs, tonumber, tostring, type, table.unpack or unpack, table.concat, math.min, math.huge

   local scanner

   do
      local keyword_types = {
         ["nil"]       = "literal value",
         ["false"]     = "literal value",
         ["true"]      = "literal value",
         ["not"]       = "operator",
         ["and"]       = "operator",
         ["or"]        = "operator",
         ["repeat"]    = "operator",
         ["until"]     = "operator",
         ["while"]     = "operator",
         ["do"]        = "operator",
         ["end"]       = "operator",
         ["if"]        = "operator",
         ["then"]      = "operator",
         ["elseif"]    = "operator",
         ["else"]      = "operator",
         ["for"]       = "operator",
         ["in"]        = "operator",
         ["local"]     = "operator",
         ["break"]     = "operator",
         ["return"]    = "operator",
         ["function"]  = "operator",
      }
      local keyword_values = { ["false"] = false, ["true"] = true }  -- ["nil"] = nil

      local escapes = { a = "\a", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", v = "\v", ["\\"] = "\\", ['"'] = '"', ["'"] = "'", ["\n"] = "\n" }

      local type_of_characters = {   -- some characters are omitted intentionally
         [" "]  = "lexem delimiter",
         ["\n"] = "lexem delimiter",
         ["\t"] = "lexem delimiter",
         ["\f"] = "lexem delimiter",
         ["\v"] = "lexem delimiter",

         ["#"] = "operator",
         ["("] = "operator", [")"] = "operator", ["{"] = "operator", ["}"] = "operator", ["]"] = "operator",
         ["+"] = "operator", ["*"] = "operator", ["%"] = "operator", ["^"] = "operator",
         [","] = "operator", [";"] = "operator",

         ["&"] = "bitwise operator",
         ["|"] = "bitwise operator",

         ["'"] = "quote", ['"'] = "quote",

         ["<"] = "comparison", [">"] = "comparison", ["="] = "comparison", ["~"] = "comparison",

         _ = "alpha",
      }
      for j = 1, 26 do
         type_of_characters[char(64 + j)] = "alpha"  -- A-Z
         type_of_characters[char(96 + j)] = "alpha"  -- a-z
      end
      for j = 0, 9 do
         type_of_characters[char(48 + j)] = "digit"  -- 0-9
      end

      local all_scanners = {}

      local all_supported_versions = { ["51"] = true, ["52"] = true, ["53"] = true, ["54"] = true }

      function scanner(version)
         version = gsub(version, "%D", "")
         local scanner_for_version = all_scanners[version]
         if not scanner_for_version then

            if not all_supported_versions[version] then
               error("There is no scanner for this version available", 2)
            end

            local version_53_plus = version == "53" or version == "54"
            local version_52_plus = version_53_plus or version == "52"

            local feature_floating_point_hex_numbers = version_52_plus
            local feature_goto_is_keyword            = version_52_plus
            local feature_prohibit_unknown_escapes   = version_52_plus
            local feature_backslash_z                = version_52_plus
            local feature_backslash_x                = version_52_plus
            local feature_backslash_u                = version_53_plus
            local feature_int64                      = version_53_plus

            function scanner_for_version(lua_code)

               local pos = 1                 -- position of first unread character
               local current_line_no = 1
               local current_line_start_pos = 1

               local function get_current_line_col()
                  return
                     current_line_no,
                     pos - current_line_start_pos + 1,
                     pos
               end

               local function read_character()
                  -- returns next_character (any variant of newline is converted to "\n")
                  -- returns nil (when EOF)
                  local character = sub(lua_code, pos, pos)
                  if pos == 1 and character == "#" then
                     repeat  -- skip shebang
                        pos = pos + 1
                        character = sub(lua_code, pos, pos)
                     until character == "\n" or character == "\r" or character == ""
                  end
                  if character ~= "" then
                     pos = pos + 1
                     if character == "\n" or character == "\r" then
                        local newline = character
                        character = sub(lua_code, pos, pos)
                        if (character == "\n" or character == "\r") and newline ~= character then
                           pos = pos + 1
                        end
                        current_line_no = current_line_no + 1
                        current_line_start_pos = pos
                        character = "\n"
                     end
                     return character
                  end
               end

               local function read_string_literal(line_no, col_no, quote, is_comment)
                  -- current position is just after opening quote
                  -- returns true
                  -- returns nil, error_message    (in case of error)
                  if quote == '"' or quote == "'" then
                     local unfinished
                     while true do
                        local character = read_character()
                        if not character or character == "\n" then
                           unfinished = true
                           break
                        end
                        if character == quote then
                           break
                        end
                        if character == "\\" then
                           character = read_character()
                           local line_no, col_no = get_current_line_col()
                           col_no = col_no - 2
                           if not character then
                              unfinished = true
                              break
                           end
                           local code = byte(character)
                           if code >= 48 and code <= 57 then
                              character = code - 48
                              for _ = 1, 2 do
                                 code = byte(lua_code, pos)
                                 if not code or code < 48 or code > 57 then
                                    break
                                 end
                                 read_character()
                                 character = character * 10 + code - 48
                              end
                              if character > 255 then
                                 return nil, "Syntax error: decimal escape too large at line "..line_no.." col "..col_no
                              end
                           else
                              local unescaped = escapes[character]
                              if character == "z" and feature_backslash_z then
                                 while find(lua_code, "^%s", pos) do
                                    read_character()
                                 end
                                 unescaped = true
                              elseif character == "x" and feature_backslash_x then
                                 local character = match(lua_code, "^%x%x", pos)
                                 if not character then
                                    return nil, "Syntax error: two hexadecimal digits expected after '\\x' at line "..line_no.." col "..col_no
                                 end
                                 unescaped = true
                                 read_character()
                                 read_character()
                              elseif character == "u" and feature_backslash_u then
                                 if read_character() ~= "{" then
                                    return nil, "Syntax error: '{' is expected after '\\u' at line "..line_no.." col "..col_no
                                 end
                                 local digit_code
                                 unescaped = 0
                                 repeat
                                    character = read_character()
                                    if character ~= "}" then
                                       digit_code = character and byte(upper(character)) or 0
                                       if digit_code < 48 or digit_code > 90 or digit_code > 57 and digit_code < 65 then
                                          return nil, "Syntax error: '{XXX}' is expected after '\\u' at line "..line_no.." col "..col_no
                                       end
                                       unescaped = unescaped * 16 + tonumber(character, 16)
                                       if unescaped > 0x10FFFF then
                                          return nil, "Syntax error: UTF-8 value too large at line "..line_no.." col "..col_no
                                       end
                                    end
                                 until character == "}"
                                 if not digit_code then
                                    return nil, "Syntax error: hexadecimal digit is expected after '\\u{' at line "..line_no.." col "..col_no
                                 end
                              end
                              if feature_prohibit_unknown_escapes and not unescaped then
                                 return nil, "Syntax error: invalid escape sequence at line "..line_no.." col "..col_no
                              end
                           end
                        end
                     end
                     if unfinished then
                        return nil, "Syntax error: unfinished string literal at line "..line_no.." col "..col_no
                     end
                  else
                     quote = "]"..rep("=", #quote - 2).."]"
                     local next_character = sub(lua_code, pos, pos)
                     if next_character == "\n" or next_character == "\r" then
                        read_character()
                     end
                     local quote_start_pos, quote_end_pos = find(lua_code, quote, pos, true)
                     if not quote_start_pos then
                        return nil, "Syntax error: unfinished long "..(is_comment and "comment" or "string literal").." at line "..line_no.." col "..col_no
                     end
                     while pos < quote_start_pos do
                        read_character()
                     end
                     pos = quote_end_pos + 1
                  end
                  return true
               end

               local function scan_next_lexem()
                  -- returns {lexem.type == "EOF"}  (in case of EOF)
                  -- returns nil, error_message     (in case of error)
                  -- returns lexem record consisting of the following fields:
                  --    type                           subtype                             additional fields
                  --    ----------------------------   ---------------------------------   -----------------
                  --    "identifier"                                                       line  col  pos
                  --    "literal value"                "boolean"/"nil"/"string"/"number"   line  col  pos
                  --    "comment"                      "short"/"long"                      line  col  pos
                  --    (all operators and keywords)                                       line  col  pos
                  --    "EOF"                                                              line  col  pos
                  local line_no, col_no, lexem_start_pos, character, character_type
                  repeat
                     line_no, col_no, lexem_start_pos = get_current_line_col()
                     character = read_character()
                     character_type = type_of_characters[character]
                  until character_type ~= "lexem delimiter"
                  if character then
                     local next_character = sub(lua_code, pos, pos)
                     local next_next_character = sub(lua_code, pos + 1, pos + 1)
                     local code = byte(character)
                     if character_type == "alpha" then  -- A-Za-z_
                        character, pos = match(lua_code, "^([A-Za-z_%d]+)()", pos - 1)
                        local keyword_type = keyword_types[character]
                        if keyword_type == "literal value" then
                           -- constants of types "boolean"/"nil"
                           local value = keyword_values[character]
                           return { type = keyword_type, subtype = type(value), line = line_no, col = col_no, pos = lexem_start_pos }
                        elseif keyword_type or character == "goto" and feature_goto_is_keyword then
                           -- keywords
                           return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                        else
                           -- identifiers
                           return { type = "identifier", value = character, line = line_no, col = col_no, pos = lexem_start_pos }
                        end
                     elseif character_type == "operator" or character_type == "bitwise operator" and feature_int64 then
                        -- punctuation
                        return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                     elseif character_type == "quote" then
                        local ok, error_message = read_string_literal(line_no, col_no, character)
                        if ok then
                           return { type = "literal value", subtype = "string", line = line_no, col = col_no, pos = lexem_start_pos }
                        else
                           return nil, error_message
                        end
                     elseif character_type == "comparison" then
                        if next_character == "=" or character == next_character and character ~= "~" and feature_int64 then
                           character = character..next_character
                           pos = pos + 1
                        end
                        if character == "~" and not feature_int64 then
                           return nil, "Syntax error at line "..line_no.." col "..col_no
                        end
                        return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                     elseif character == "0" and (next_character == "x" or next_character == "X") then
                        local hex_pos = pos + 1
                        if feature_floating_point_hex_numbers then
                           character, pos = match(lua_code, "^([%.%x]*)()", hex_pos)
                           local ok = find(character, "^%x*%.?%x*$") and character ~= "." and character ~= ""
                           if upper(sub(lua_code, pos, pos)) == "P" then
                              pos = match(lua_code, "^[%+%-]?%d+()", pos + 1)
                           end
                           if not (ok and pos) then
                              return nil, "Syntax error: malformed hexadecimal number at line "..line_no.." col "..col_no
                           end
                           return { type = "literal value", subtype = "number", line = line_no, col = col_no, pos = lexem_start_pos }
                        else
                           pos = match(lua_code, "^%x+()", hex_pos)
                           if not pos then
                              return nil, "Syntax error: malformed hexadecimal number at line "..line_no.." col "..col_no
                           end
                           return { type = "literal value", subtype = "number", line = line_no, col = col_no, pos = lexem_start_pos }
                        end
                     elseif character == "." and next_character == "." then
                        if next_next_character == "." then
                           pos = pos + 2
                           return { type = "...", line = line_no, col = col_no, pos = lexem_start_pos }
                        else
                           pos = pos + 1
                           return { type = "..", line = line_no, col = col_no, pos = lexem_start_pos }
                        end
                     elseif character == "." or character_type == "digit" then
                        local starting_pos = pos - 1
                        character, pos = match(lua_code, "^([%.%d]+)()", starting_pos)
                        if character == "." then
                           return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                        else
                           local ok = match(character, "^%d*%.?%d*$")
                           if upper(sub(lua_code, pos, pos)) == "E" then
                              pos = match(lua_code, "^[%+%-]?%d+()", pos + 1)
                           end
                           if not (ok and pos) then
                              return nil, "Syntax error: malformed number at line "..line_no.." col "..col_no
                           end
                           return { type = "literal value", subtype = "number", line = line_no, col = col_no, pos = lexem_start_pos }
                        end
                     elseif character == "[" then
                        if next_character == "[" or next_character == "=" then
                           local equal_ctr = -1
                           repeat
                              equal_ctr = equal_ctr + 1
                              character = read_character()
                              if character ~= "[" and character ~= "=" then
                                 return nil, "Syntax error at line "..line_no.." col "..col_no
                              end
                           until character == "["
                           local ok, error_message = read_string_literal(line_no, col_no, "["..rep("=", equal_ctr).."[")
                           if ok then
                              return { type = "literal value", subtype = "string", line = line_no, col = col_no, pos = lexem_start_pos }
                           else
                              return nil, error_message
                           end
                        else
                           return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                        end
                     elseif character == "-"  then
                        if next_character == "-" then
                           pos = pos + 1
                           local equal_ctr
                           if next_next_character == "[" then
                              equal_ctr = -1
                              repeat
                                 equal_ctr = equal_ctr + 1
                                 local next_pos = pos + 1 + equal_ctr
                                 character = sub(lua_code, next_pos, next_pos)
                                 if character ~= "[" and character ~= "=" then
                                    equal_ctr = nil
                                 end
                              until not equal_ctr or character == "["
                           end
                           if equal_ctr then
                              pos = pos + 2 + equal_ctr
                              local ok, error_message = read_string_literal(line_no, col_no, rep("=", equal_ctr + 2), true)
                              if ok then
                                 return { type = "comment", subtype = "long", line = line_no, col = col_no, pos = lexem_start_pos }
                              else
                                 return nil, error_message
                              end
                           else
                              pos = pos + #match(lua_code, "[^\r\n]*", pos)
                              return { type = "comment", subtype = "short", line = line_no, col = col_no, pos = lexem_start_pos }
                           end
                        end
                        return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                     elseif character == "/" then
                        if next_character == "/" and feature_int64 then
                           pos = pos + 1
                           character = "//"
                        end
                        return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                     elseif character == ":" then
                        if next_character == ":" and feature_goto_is_keyword then
                           pos = pos + 1
                           character = "::"
                        end
                        return { type = character, line = line_no, col = col_no, pos = lexem_start_pos }
                     else
                        return nil, "Syntax error at line "..line_no.." col "..col_no
                     end
                  else
                     return { type = "EOF", line = line_no, col = col_no, pos = lexem_start_pos }
                  end
               end

               return scan_next_lexem

            end

            all_scanners[version] = scanner_for_version
         end
         return scanner_for_version
      end
   end

   local function find_def(vars, name)
      -- returns subtype("local"/"upvalue"/"global"), def(only for "local"/"upvalue")
      -- vars[1] = parent_vars/nil, vars[2] = is_function_body, vars[name] = def
      local subtype = "local"
      repeat
         local def = vars[name]
         if def then
            return subtype, def
         end
         if vars[2] then
            subtype = "upvalue"
         end
         vars = vars[1]
      until not vars
      return "global"
   end

   local binary_operator_predecessors = {
      -- binary operators are preceded in Lua grammar only by the following lexems (ignoring comments):
      ["identifier"] = true,
      ["literal value"] = true,
      ["..."] = true,
      ["end"] = true,
      [")"] = true,
      ["}"] = true,
      ["]"] = true,
   }

   -- Priorities are positive numbers
   -- The same priority level must not be shared between unary and binary operators
   -- The same priority level must not be shared between left-associative and right-associative binary operators
   local binary_operators = {
      -- priorities of binary operators
      ["or"] = 1,
      ["and"] = 2,
      ["<"] = 3, [">"] = 3, ["<="] = 3, [">="] = 3, ["~="] = 3, ["=="] = 3,
      ["|"] = 4,
      ["~"] = 5,
      ["&"] = 6,
      ["<<"] = 7, [">>"] = 7,
      [".."] = 8,
      ["+"] = 9, ["-"] = 9,
      ["*"] = 10, ["/"] = 10, ["//"] = 10, ["%"] = 10,
      ["^"] = 12
   }
   local unary_operators = {
      -- priorities of unary operators
      ["not"] = 11, ["#"] = 11, ["unary -"] = 11, ["unary ~"] = 11
   }
   local right_associative_priorities = {
      -- precedences of right associative binary operators:
      [8] = true,  --  .. concatenation
      [12] = true, --  ^  exponentiation
   }

   local all_parsers = {}

   local all_supported_versions = { ["51"] = true, ["52"] = true, ["53"] = true, ["54"] = true }

   function parser(version)
      version = gsub(version, "%D", "")
      local parser_for_version = all_parsers[version]
      if not parser_for_version then

         if not all_supported_versions[version] then
            error("There is no parser for this version available", 2)
         end

         local version_52_plus = version == "52" or version == "53" or version == "54"

         local feature_break_is_last_statement  = version == "51"
         local feature_empty_statement          = version_52_plus
         local feature_ENV                      = version_52_plus

         local lua_scanner = scanner(version)

         function parser_for_version(lua_code, global_catcher)
            -- returns true
            -- returns nil, error_message (in case of parsing error)

            local get_next_lexem_from_scanner = lua_scanner(lua_code)

            local error_message

            local next_lexem, next_next_lexem
            local last_lexem, before_last_lexem
            local prev_non_comment_lexem_type

            local function read_lexem()
               -- returns nil in case of error (error_message is set)
               -- lexem.type == "EOF" (when EOF)
               local lexem
               if next_lexem then
                  lexem, next_lexem, next_next_lexem = next_lexem, next_next_lexem
               else
                  repeat
                     lexem, error_message = get_next_lexem_from_scanner()
                     if not lexem then
                        return
                     end
                     local lexem_type = lexem.type
                     local is_comment = lexem_type == "comment"
                     if not is_comment then
                        if (lexem_type == "-" or lexem_type == "~") and not binary_operator_predecessors[prev_non_comment_lexem_type] then
                           lexem_type = "unary "..lexem_type
                           lexem.type = lexem_type
                        end
                        prev_non_comment_lexem_type = lexem_type
                     end
                  until not is_comment
               end
               before_last_lexem, last_lexem = last_lexem, lexem
               return lexem
            end

            local function unread_last_lexem()
               last_lexem, next_lexem, next_next_lexem = before_last_lexem, last_lexem, next_lexem
            end

            local function get_lexem_coordinates_as_text(lexem)
               if lexem.type == "EOF" then
                  return "EOF"
               else
                  return "line "..lexem.line.." col "..lexem.col
               end
            end

            local read_chunk, read_exp, read_explist

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_table_constructor(vars)
            --------------------------------------------------------------------------------------------------------------------------------------------
               -- opening curly brace is already read
               unread_last_lexem()
               local result = read_lexem()  -- this is the opening curly brace
               result.type = "table constructor"
               local array_of_table_items = {}
               result.items = array_of_table_items
               local lexem = read_lexem()
               if not lexem then
                  return
               end
               local lexem_type = lexem.type
               while lexem_type ~= "}" do
                  local index_exp, field_exp, value_exp
                  if lexem_type == "[" then
                     index_exp = read_exp(vars)
                     if not index_exp then
                        return
                     end
                     lexem = read_lexem()
                     if not lexem then
                        return
                     end
                     if lexem.type ~= "]" then
                        error_message = "Syntax error: ']' is expected at "..get_lexem_coordinates_as_text(lexem)
                        return
                     end
                     lexem = read_lexem()
                     if not lexem then
                        return
                     end
                     if lexem.type ~= "=" then
                        error_message = "Syntax error: '=' is expected at "..get_lexem_coordinates_as_text(lexem)
                        return
                     end
                     value_exp = read_exp(vars)
                     if not value_exp then
                        return
                     end
                  else
                     if lexem_type == "identifier" then
                        local next_lexem = read_lexem()
                        if not next_lexem then
                           return
                        end
                        if next_lexem.type == "=" then
                           field_exp = lexem
                           field_exp.subtype = "field"
                        else
                           unread_last_lexem()
                        end
                     end
                     if not field_exp then
                        unread_last_lexem()
                     end
                     value_exp = read_exp(vars)
                     if not value_exp then
                        return
                     end
                  end
                  array_of_table_items[#array_of_table_items + 1] = { index = index_exp, field = field_exp, value = value_exp }
                  lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  lexem_type = lexem.type
                  if lexem_type == "," or lexem_type == ";" then
                     lexem = read_lexem()
                     if not lexem then
                        return
                     end
                     lexem_type = lexem.type
                  elseif lexem_type ~= "}" then
                     error_message = "Syntax error: ',' or ';' or '}' is expected at "..get_lexem_coordinates_as_text(lexem)
                     return
                  end
               end
               return result
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_funcbody(vars, invisible_self_argument)
            --------------------------------------------------------------------------------------------------------------------------------------------
               local result = read_lexem()
               if not result then
                  return
               end
               if result.type ~= "(" then
                  error_message = "Syntax error: '(' is expected at "..get_lexem_coordinates_as_text(result)
                  return
               end
               result.type = "function definition"
               local arguments = {}
               if invisible_self_argument then
                  arguments[1] = { type = "identifier", subtype = "definition", value = "self", line = result.line, col = result.col, pos = result.pos }
               end
               result.arguments = arguments
               local is_vararg = false
               local after_separator = true
               local visible_argument
               while true do
                  local lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  local lexem_type = lexem.type
                  if lexem_type == ")" and not (after_separator and visible_argument) then
                     local body = read_chunk(vars, false, arguments, true)
                     if not body then
                        return
                     end
                     result.body = body
                     local closing_lexem = read_lexem()
                     if not closing_lexem then
                        return
                     end
                     if closing_lexem.type ~= "end" then
                        error_message = "Syntax error: 'end' is expected at "..get_lexem_coordinates_as_text(closing_lexem)
                        return
                     end
                     result.is_vararg = is_vararg
                     return result
                  elseif lexem_type == "," and not after_separator and not is_vararg then
                     after_separator = true
                  elseif (lexem_type == "identifier" or lexem_type == "...") and after_separator then
                     arguments[#arguments + 1] = lexem
                     visible_argument = true
                     after_separator = false
                     is_vararg = lexem_type == "..."
                  else
                     error_message = "Syntax error in function argument list at "..get_lexem_coordinates_as_text(lexem)
                     return
                  end
               end
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_prefixexp(vars, pure_global_LHS)
            --------------------------------------------------------------------------------------------------------------------------------------------
               -- returns prefixexp_subtree, exp_type, first_lexem_of_prefixexp
               --    exp_type:  1 = rvalue (neither lvalue nor funccall)
               --               3 = funccall
               --               5 = lvalue
               local exp_type, write_access
               local first_lexem = read_lexem()
               if not first_lexem then
                  return
               end
               local lexem_type = first_lexem.type
               if lexem_type == "(" then
                  exp_type = 1
                  first_lexem.type = "(expression)"
                  local expression = read_exp(vars)
                  if not expression then
                     return
                  end
                  first_lexem.expression = expression
                  local lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  if lexem.type ~= ")" then
                     error_message = "Syntax error: ')' is expected at "..get_lexem_coordinates_as_text(lexem)
                     return
                  end
               elseif lexem_type == "identifier" then
                  exp_type = 5
                  first_lexem.subtype, first_lexem.def = find_def(vars, first_lexem.value)
                  if global_catcher and first_lexem.subtype == "global" then
                     global_catcher(first_lexem)
                     if pure_global_LHS then
                        write_access = true
                     end
                  end
               else
                  error_message = "Syntax error at "..get_lexem_coordinates_as_text(first_lexem)
                  return
               end
               local result = first_lexem
               while true do
                  local lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  lexem_type = lexem.type
                  if lexem_type == "[" then
                     write_access = false
                     -- [index]
                     exp_type = 5
                     lexem.type = "table[index]"
                     lexem.table = result
                     local exp = read_exp(vars)
                     if not exp then
                        return
                     end
                     lexem.index = exp
                     local next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     if next_lexem.type ~= "]" then
                        error_message = "Syntax error: ']' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                     end
                     result = lexem
                  elseif lexem_type == "." then
                     write_access = false
                     -- .field
                     exp_type = 5
                     lexem.type = "object.field"
                     lexem.object = result
                     local next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     if next_lexem.type ~= "identifier" then
                        error_message = "Syntax error: an identifier is expected at"..get_lexem_coordinates_as_text(next_lexem)
                        return
                     end
                     next_lexem.subtype = "field"
                     lexem.field = next_lexem
                     result = lexem
                  elseif lexem_type == ":" or lexem_type == "(" or lexem_type == "{" or lexem_type == "literal value" and lexem.subtype == "string" then
                     write_access = false
                     -- function call
                     exp_type = 3
                     if lexem_type == ":" then
                        lexem.object = result
                        result = lexem
                        lexem = read_lexem()
                        if not lexem then
                           return
                        end
                        if lexem.type ~= "identifier" then
                           error_message = "Syntax error: an identifier is expected after ':' at "..get_lexem_coordinates_as_text(lexem)
                           return
                        end
                        lexem.subtype = "field"
                        result.method = lexem
                        lexem = read_lexem()
                        if not lexem then
                           return
                        end
                        lexem_type = lexem.type
                        if not (lexem_type == "(" or lexem_type == "{" or lexem_type == "literal value" and lexem.subtype == "string") then
                           error_message = "Syntax error: '(' is expected at "..get_lexem_coordinates_as_text(lexem)
                           return
                        end
                     else
                        if lexem_type == "(" then
                           lexem.object = result
                           result = lexem
                        else
                           result = { object = result, line = lexem.line, col = lexem.col }
                        end
                     end
                     result.type = "funccall"
                     if lexem_type == "(" then
                        lexem = read_lexem()
                        if not lexem then
                           return
                        end
                        if lexem.type == ")" then
                           result.arguments = {}
                        else
                           unread_last_lexem()
                           local arguments = read_explist(vars)
                           if not arguments then
                              return
                           end
                           result.arguments = arguments
                           lexem = read_lexem()
                           if not lexem then
                              return
                           end
                           if lexem.type ~= ")" then
                              error_message = "Syntax error: ')' is expected at "..get_lexem_coordinates_as_text(lexem)
                              return
                           end
                        end
                     elseif lexem_type == "{" then
                        -- read table constructor
                        local table_constructor_exp = read_table_constructor(vars)
                        if not table_constructor_exp then
                           return
                        end
                        result.arguments = { table_constructor_exp }
                     else  -- literal string as single argument
                        result.arguments = { lexem }
                     end
                  else
                     unread_last_lexem()
                     if write_access then
                        global_catcher()  -- mark write access
                     end
                     return result, exp_type, first_lexem
                  end
               end
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_term(vars)
            --------------------------------------------------------------------------------------------------------------------------------------------
               -- term is an expression having root operator (last operator to be executed) different from "exp ::= exp binop exp"
               local lexem = read_lexem()
               if not lexem then
                  return
               end
               local lexem_type = lexem.type
               if lexem_type == "literal value" then
                  return lexem
               elseif lexem_type == "..." then
                  lexem.subtype, lexem.def = find_def(vars, lexem_type)
                  return lexem
               elseif lexem_type == "{" then
                  return read_table_constructor(vars)
               elseif lexem_type == "function" then
                  return read_funcbody(vars)
               else
                  local unary_oper_priority = unary_operators[lexem_type]
                  if unary_oper_priority then
                     local argument, ends_with_prefixexp = read_exp(vars, unary_oper_priority)
                     if not argument then
                        return
                     end
                     lexem.argument = argument
                     return lexem, ends_with_prefixexp
                  else
                     unread_last_lexem()
                     return read_prefixexp(vars)  -- second returned value is always truthy
                  end
               end
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_chain_of_binary_operators_with_specified_priority(vars, first_term, first_binary_operator, chain_priority)
            --------------------------------------------------------------------------------------------------------------------------------------------
               -- parse expression consisting of binary operators with specified priority
               first_binary_operator.left_argument = first_term
               local is_right_associative = right_associative_priorities[chain_priority]
               local term, ends_with_prefixexp = read_term(vars)
               if not term then
                  return
               end
               first_binary_operator.right_argument = term
               local last_binary_operator = first_binary_operator
               while true do
                  local binary_operator = read_lexem()
                  if not binary_operator then
                     return
                  end
                  local priority = binary_operators[binary_operator.type]
                  if not priority or priority < chain_priority then
                     unread_last_lexem()
                     return is_right_associative and first_binary_operator or last_binary_operator, ends_with_prefixexp
                  elseif priority > chain_priority then
                     term, ends_with_prefixexp = read_chain_of_binary_operators_with_specified_priority(vars, last_binary_operator.right_argument, binary_operator, priority)
                     if not term then
                        return
                     end
                     last_binary_operator.right_argument = term
                  else
                     term, ends_with_prefixexp = read_term(vars)
                     if not term then
                        return
                     end
                     binary_operator.right_argument = term
                     if is_right_associative then
                        binary_operator.left_argument = last_binary_operator.right_argument
                        last_binary_operator.right_argument = binary_operator
                     else
                        binary_operator.left_argument = last_binary_operator
                     end
                     last_binary_operator = binary_operator
                  end
               end
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            function read_exp(vars, outer_priority)
            --------------------------------------------------------------------------------------------------------------------------------------------
               local fake_operator, ends_with_prefixexp = read_chain_of_binary_operators_with_specified_priority(vars, nil, {}, outer_priority or 0)
               if not fake_operator then
                  return
               end
               return fake_operator.right_argument, ends_with_prefixexp
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            function read_explist(vars, min_qty, max_qty)
            --------------------------------------------------------------------------------------------------------------------------------------------
               min_qty, max_qty = min_qty or 1, max_qty or huge
               local rvalues = { }
               local exp, ends_with_prefixexp
               repeat
                  exp, ends_with_prefixexp = read_exp(vars)
                  if not exp then
                     return
                  end
                  rvalues[#rvalues + 1] = exp
                  local qty = #rvalues
                  local lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  local is_comma = qty < max_qty and lexem.type == ","
                  if qty < min_qty and not is_comma then
                     error_message = "Syntax error: ',' is expected at "..get_lexem_coordinates_as_text(lexem)
                     return
                  end
               until not is_comma
               unread_last_lexem()
               return rvalues, ends_with_prefixexp
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_namelist(vars, name_separator)
            --------------------------------------------------------------------------------------------------------------------------------------------
               name_separator = name_separator or ","
               local identifiers, global_write_access = {}
               repeat
                  local lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  if lexem.type ~= "identifier" then
                     error_message = "Syntax error: an identifier is expected at "..get_lexem_coordinates_as_text(lexem)
                     return
                  end
                  if name_separator == "," then
                     if vars then
                        vars[lexem.value] = lexem
                     end
                     lexem.subtype = "definition"
                  elseif identifiers[1] then
                     lexem.subtype = "field"
                     global_write_access = false
                  else
                     lexem.subtype, lexem.def = find_def(vars, lexem.value)
                     if global_catcher and lexem.subtype == "global" then
                        global_catcher(lexem)
                        global_write_access = true
                     end
                  end
                  identifiers[#identifiers + 1] = lexem
                  lexem = read_lexem()
                  if not lexem then
                     return
                  end
               until lexem.type ~= name_separator
               unread_last_lexem()
               if global_write_access then
                  global_catcher()  -- mark write access
               end
               return identifiers
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            local function read_statement(vars, inside_loop)
            --------------------------------------------------------------------------------------------------------------------------------------------
               local lexem = read_lexem()
               if not lexem then
                  return
               end
               local lexem_type = lexem.type
               if lexem_type == "break" then
                  if not inside_loop then
                     error_message = "Syntax error: 'break' must be inside loop at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  return lexem, feature_break_is_last_statement and "Syntax error: statement after 'break' at "
               elseif lexem_type == "do" then
                  local chunk = read_chunk(vars, inside_loop)
                  if not chunk then
                     return
                  end
                  lexem.body = chunk
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "end" then
                     error_message = "Syntax error: 'end' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  return lexem
               elseif lexem_type == "for" then
                  local names = read_namelist()
                  if not names then
                     return
                  end
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  lexem_type = next_lexem.type
                  if lexem_type == "in" or lexem_type == "=" and not names[2] then
                     -- for namelist in explist do chunk end
                     -- for Name `=` exp `,` exp [`,` exp] do chunk end
                     lexem.variables = names
                     local numeric_for = lexem_type == "="
                     lexem.subtype = numeric_for and "numeric" or "generic"
                     local expressions = read_explist(vars, numeric_for and 2, 3)
                     if not expressions then
                        return
                     end
                     lexem.expressions = expressions
                     next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     if next_lexem.type ~= "do" then
                        error_message = "Syntax error: 'do' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                        return
                     end
                     local body = read_chunk(vars, true, names)
                     if not body then
                        return
                     end
                     lexem.body = body
                     next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     if next_lexem.type ~= "end" then
                        error_message = "Syntax error: 'end' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                        return
                     end
                     return lexem
                  end
                  error_message = "Syntax error in 'for' loop at "..get_lexem_coordinates_as_text(next_lexem)
                  return
               elseif lexem_type == "if" then
                  -- if exp then chunk {elseif exp then chunk} [else chunk] end
                  local conditions = {}
                  lexem.conditions = conditions
                  local chunks = {}  -- chunks array is one element longer than conditions array when "else" clause is present
                  lexem.chunks = chunks
                  while true do
                     local exp = read_exp(vars)
                     if not exp then
                        return
                     end
                     conditions[#conditions + 1] = exp
                     local next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     if next_lexem.type ~= "then" then
                        error_message = "Syntax error: 'then' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                        return
                     end
                     local chunk = read_chunk(vars, inside_loop)
                     if not chunk then
                        return
                     end
                     chunks[#conditions] = chunk
                     next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     local lexem_type = next_lexem.type
                     if lexem_type == "end" or lexem_type == "else" then
                        if lexem_type == "else" then
                           chunk = read_chunk(vars, inside_loop)
                           if not chunk then
                              return
                           end
                           chunks[#chunks + 1] = chunk
                           next_lexem = read_lexem()
                           if not next_lexem then
                              return
                           end
                           if next_lexem.type ~= "end" then
                              error_message = "Syntax error: 'end' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                              return
                           end
                        end
                        return lexem
                     elseif lexem_type ~= "elseif" then
                        error_message = "Syntax error: 'end' or 'else' or 'elseif' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                        return
                     end
                  end
               elseif lexem_type == "local" then
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type == "function" then
                     -- local function Name funcbody
                     lexem.type = "local function"
                     next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     if next_lexem.type ~= "identifier" then
                        error_message = "Syntax error: an identifier is expected at "..get_lexem_coordinates_as_text(next_lexem)
                        return
                     end
                     next_lexem.subtype = "definition"
                     vars[next_lexem.value] = next_lexem
                     lexem.variable = next_lexem
                     local func_def = read_funcbody(vars)
                     if not func_def then
                        return
                     end
                     lexem.func_def = func_def
                     return lexem
                  else
                     unread_last_lexem()
                     -- local namelist [`=` explist]
                     local new_vars = {}
                     local names = read_namelist(new_vars)
                     if not names then
                        return
                     end
                     lexem.variables = names
                     next_lexem = read_lexem()
                     if not next_lexem then
                        return
                     end
                     local expressions, ends_with_prefixexp
                     if next_lexem.type == "=" then
                        expressions, ends_with_prefixexp = read_explist(vars)
                        if not expressions then
                           return
                        end
                     else
                        unread_last_lexem()
                     end
                     for k, v in pairs(new_vars) do
                        vars[k] = v
                     end
                     lexem.expressions = expressions  -- lexem.expressions may be nil for local variables without initialization
                     lexem.ends_with_prefixexp = ends_with_prefixexp
                     return lexem
                  end
               elseif lexem_type == "repeat" then
                  -- repeat chunk until exp
                  local body, chunk_vars = read_chunk(vars, true)
                  if not body then
                     return
                  end
                  lexem.body = body
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "until" then
                     error_message = "Syntax error: 'until' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  local expression, ends_with_prefixexp = read_exp(chunk_vars)
                  if not expression then
                     return
                  end
                  lexem.expression = expression
                  lexem.ends_with_prefixexp = ends_with_prefixexp
                  return lexem
               elseif lexem_type == "return" then
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  lexem_type = next_lexem.type
                  unread_last_lexem()
                  if lexem_type == "EOF" or lexem_type == "end" or lexem_type == "until" or lexem_type == "elseif" or lexem_type == "else" then
                     lexem.expressions = {}
                  else
                     local expressions = read_explist(vars)
                     if not expressions then
                        return
                     end
                     lexem.expressions = expressions
                  end
                  return lexem, "Syntax error: statement after 'return' at "
               elseif lexem_type == "while" then
                  -- while exp do chunk end
                  local expression = read_exp(vars)
                  if not expression then
                     return
                  end
                  lexem.expression = expression
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "do" then
                     error_message = "Syntax error: 'do' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  local body = read_chunk(vars, true)
                  if not body then
                     return
                  end
                  lexem.body = body
                  next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "end" then
                     error_message = "Syntax error: 'end' is expected at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  return lexem
               elseif lexem_type == "function" then
                  -- function Name {`.` Name} [`:` Name] funcbody
                  local invisible_self_argument
                  local names = read_namelist(vars, ".")
                  if not names then
                     return
                  end
                  lexem.name_chain = names
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type == ":" then
                     local method = read_lexem()
                     if not method then
                        return
                     end
                     if method.type ~= "identifier" then
                        error_message = "Syntax error: an identifier is expected at "..get_lexem_coordinates_as_text(method)
                        return
                     end
                     method.subtype = "field"
                     lexem.method = method
                     invisible_self_argument = true
                  else
                     unread_last_lexem()
                  end
                  local func_def = read_funcbody(vars, invisible_self_argument)
                  if not func_def then
                     return
                  end
                  lexem.func_def = func_def
                  return lexem
               elseif lexem_type == "::" then
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "identifier" then
                     error_message = "Syntax error: label name is expected after '::' at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  lexem.label_identifier = next_lexem
                  next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "::" then
                     error_message = "Syntax error: '::' is expected after label name at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  return lexem
               elseif lexem_type == "goto" then
                  local next_lexem = read_lexem()
                  if not next_lexem then
                     return
                  end
                  if next_lexem.type ~= "identifier" then
                     error_message = "Syntax error: label name is expected after 'goto' at "..get_lexem_coordinates_as_text(next_lexem)
                     return
                  end
                  lexem.label_identifier = next_lexem
                  return lexem
               elseif lexem_type == ";" and feature_empty_statement then
                  return lexem
               else
                  local starts_with_parenthesis = lexem_type == "("
                  unread_last_lexem()
                  local prefixexp, exp_type, first_lexem = read_prefixexp(vars, true)  -- either lvalue or funccall
                  if not prefixexp then
                     return
                  end
                  if exp_type > 4 then
                     -- lvalue found
                     local lvalues = { prefixexp }
                     while true do
                        lexem = read_lexem()
                        if not lexem then
                           return
                        end
                        lexem_type = lexem.type
                        if lexem_type == "=" then
                           local rvalues, ends_with_prefixexp = read_explist(vars)
                           if not rvalues then
                              return
                           end
                           lexem.lvalues = lvalues
                           lexem.rvalues = rvalues
                           lexem.starts_with_parenthesis = starts_with_parenthesis
                           lexem.ends_with_prefixexp = ends_with_prefixexp
                           return lexem
                        elseif lexem_type == "," then
                           prefixexp, exp_type, first_lexem = read_prefixexp(vars, true)
                           if not prefixexp then
                              return
                           end
                           if exp_type < 4 then
                              error_message = "Syntax error: L-value is expected at "..get_lexem_coordinates_as_text(first_lexem)
                              return
                           end
                           lvalues[#lvalues + 1] = prefixexp
                        else
                           error_message = "Syntax error: '=' or ',' is expected at "..get_lexem_coordinates_as_text(lexem)
                           return
                        end
                     end
                  elseif exp_type > 2 then
                     -- funccall found
                     prefixexp.starts_with_parenthesis = starts_with_parenthesis
                     prefixexp.ends_with_prefixexp = true
                     return prefixexp
                  end
                  error_message = "Syntax error: L-value or function call is expected at "..get_lexem_coordinates_as_text(first_lexem)
                  return
               end
            end

            --------------------------------------------------------------------------------------------------------------------------------------------
            function read_chunk(vars, inside_loop, additional_variables, is_function)
            --------------------------------------------------------------------------------------------------------------------------------------------
               vars = { vars, is_function }
               if additional_variables then
                  for _, def in ipairs(additional_variables) do
                     vars[def.value or "..."] = def
                  end
               end
               local statements = {}
               local after_last_statement
               while true do
                  local lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  unread_last_lexem()
                  local lexem_type = lexem.type
                  if lexem_type == "EOF" or lexem_type == "end" or lexem_type == "until" or lexem_type == "elseif" or lexem_type == "else" then
                     return statements, vars
                  end
                  if after_last_statement then
                     error_message = after_last_statement..get_lexem_coordinates_as_text(lexem)
                     return
                  end
                  lexem, after_last_statement = read_statement(vars, inside_loop)
                  if not lexem then
                     return
                  end
                  if lexem.type ~= ";" then
                     statements[#statements + 1] = lexem
                  end
                  lexem = read_lexem()
                  if not lexem then
                     return
                  end
                  if lexem.type ~= ";" then
                     unread_last_lexem()
                  end
               end
            end

            local vars =
               feature_ENV
               and { _ENV = { type = "identifier", subtype = "definition", value = "_ENV", line = 1, col = 1, pos = 1 } }
               or nil
            local array_of_statements = read_chunk(vars, false, {{ type = "...", subtype = "definition", line = 1, col = 1, pos = 1 }}, true)
            if not array_of_statements then
               return nil, error_message
            end
            local lexem = read_lexem()
            if not lexem then
               return nil, error_message
            end
            if lexem.type ~= "EOF" then
               return nil, "EOF is expected at "..get_lexem_coordinates_as_text(lexem)
            end
            return true

         end

         all_parsers[version] = parser_for_version
      end
      return parser_for_version
   end
end


local program = io.read"*a"
local globals = {}
local global_names = {}
do
   local last_global_name, last_global_coord

   local function flush_last_global_name(write_access)
      if last_global_name then
         table.insert(globals[last_global_name][write_access and "W" or "R"], last_global_coord)
         last_global_name, last_global_coord = nil
      end
   end

   local function global_catcher(lexem)
      if not lexem then
         flush_last_global_name(true)
      else
         flush_last_global_name()
         last_global_name = lexem.value
         if not globals[last_global_name] then
            globals[last_global_name] = {R = {}, W = {}}
            table.insert(global_names, last_global_name)
         end
         last_global_coord = lexem.line..":"..lexem.col
      end
   end

   assert(parser(Lua_version)(program, global_catcher))

   flush_last_global_name()
end
table.sort(global_names)
for _, name in ipairs(global_names) do
   for _, access_type in ipairs{"W", "R"} do
      if read_write_access[access_type] then
         local list_line_col = table.concat(globals[name][access_type], ", ")
         if list_line_col ~= "" then
            print(({R = "read", W = "write"})[access_type], name, list_line_col)
         end
      end
   end
end

--[[

MIT License

Copyright (c) 2019  Egor Skriptunoff

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
