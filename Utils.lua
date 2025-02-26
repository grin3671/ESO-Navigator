local Nav = Navigator
local Utils = Nav.Utils or {}

local _lang

local function CurrentLanguage()
	if _lang == nil then 
		_lang = GetCVar("language.2")
		_lang = string.lower(_lang)
	end 
	return _lang
end

CurrentLanguage()

local accents = {
	["à"] = "a",
	["á"] = "a",
	["â"] = "a",
	["ã"] = "a",
	["ä"] = "a",
	["å"] = "a",
	["ą"] = "a",

	["ß"] = "ss",

	["ĥ"] = "h",

	["ç"] = "c",
	["æ"] = "ae",

	["è"] = "e",
	["é"] = "e",
	["ê"] = "e",
	["ë"] = "e",
	["ę"] = "e",

	["ì"] = "i",
	["í"] = "i",
	["î"] = "i",
	["ï"] = "i",
	["ı"] = "i",
	["į"] = "i",

	["ł"] = "l",

	["ñ"] = "n",

	-- ["ð"] = "d",
	["š"] = "s",

	["þ"] = "p",

	["ò"] = "o",
	["ó"] = "o",
	["ô"] = "o",
	["õ"] = "o",
	["ö"] = "o",
	["ō"] = "o",
	["ð"] = "o",
	["ø"] = "o",
	["ǫ"] = "o",

	["ẅ"] = "w",

	["ş"] = "s",
	-- ["š"] = "s",

	["ù"] = "u",
	["ú"] = "u",
	["û"] = "u",
	["ü"] = "u",
	["ų"] = "u",

	["ý"] = "y",
	["ÿ"] = "y",
	["ŷ"] = "y",


	["À"] = "A",
	["Á"] = "A",
	["Â"] = "A",
	["Ã"] = "A",
	["Ä"] = "A",
	["Å"] = "A",
	["Ą"] = "A",

	["ẞ"] = "B",

	["Ĥ"] = "H",

	["Ç"] = "C",
	["Æ"] = "Ae",

	["È"] = "E",
	["É"] = "E",
	["Ê"] = "E",
	["Ë"] = "E",
	["Ę"] = "E",

	["Ì"] = "I",
	["Í"] = "I",
	["Î"] = "I",
	["Ï"] = "I",
	["Į"] = "I",

	["Ł"] = "L",

	["Ñ"] = "N",

	["Ð"] = "D",
	["Š"] = "S",
	["Ş"] = "S",

	["Þ"] = "P",

	["Ò"] = "O",
	["Ó"] = "O",
	["Ô"] = "O",
	["Õ"] = "O",
	["Ö"] = "O",
	["Ø"] = "O",
	["Ǫ"] = "O",

	["Ẅ"] = "W",

	["Ù"] = "U",
	["Ú"] = "U",
	["Û"] = "U",
	["Ü"] = "U",
	["Ų"] = "U",

	["Ý"] = "Y",
	["Ÿ"] = "Y",
	["Ŷ"] = "Y",
}

function Utils.SimplifyAccents(str)
	if (not str) or (str == "") then return str end
	-- str = zo_strgsub(str, "[%z\1-\127\194-\244][\128-\191]*", tableAccents)
	for k, v in pairs(accents) do
		str = zo_strgsub(str, k, v)
	end
	return str
end

function Utils.trim(s)
	s = string.gsub(s, "^%s*(.-)%s*$", "%1")
	return s
end

function Utils.tableConcat(t1, t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end


function Utils.FormatSimpleName(str)
	if str == nil or str == "" then return str end
	local lang = string.lower(CurrentLanguage())
	if lang == "en" then
		return str
	else
		return zo_strformat("<<!AC:1>>", str)
	end 
end 

function Utils.DisplayName(name)
	return Navigator.DisplayName(name)
	--elseif _lang == "ru" then
	--	r = r:gsub("^Дорожное святилище ", "ДС ", 1)
	--end
end

function Utils.SearchName(name)
	local r = Navigator.SearchName(name)
	--elseif _lang == "ru" then
	--	r = r:gsub("Дорожное святилище ", "", 1):gsub("^Подземелье: ", "", 1):gsub("^Испытание: ", "", 1)
	--end
	r = r:gsub(" II$", " II 2", 1):gsub(" I$", " I 1", 1)
	return r
end

function Utils.SortName(obj)
	local name = type(obj) == "table" and obj.name or obj
	return Navigator.SortName(name)
	--name = string.lower(Utils.DisplayName(name))
	--name = Utils.RemoveAccents(name)
	--
	--if Nav.saved.ignoreDefiniteArticlesInSort then
	--	if _lang == "en" then
	--		name = name:gsub("^The ", "", 1)
	--	elseif _lang == "fr" then
	--		name = name:gsub("^le ", "", 1):gsub("^la ", "", 1):gsub("^l'", "", 1):gsub("^les ", "", 1)
	--	end
	--end
	--
	--return Utils.trim(name)
end

function Utils.shallowCopy(t)
	if type(t) == "table" then
		local t2 = {}
		for k,v in pairs(t) do
			t2[k] = v
		end
		setmetatable(t2, Utils.shallowCopy(getmetatable(t)))
		return t2
	else
		return t
	end
end

function Utils.deepCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[Utils.deepCopy(k)] = Utils.deepCopy(v) end
    return res
end

function Utils.tableContains(table, element)
    for _, value in pairs(table) do
      if value == element then
        return true
      end
    end
    return false
end

Nav.Utils = Utils