GCompute.String = GCompute.String or {}
local String = GCompute.String

function GCompute.String.ConsoleEscape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GCompute.String.ConsoleEscape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\q")
		:gsub ("\'", "\\s")
end

function GCompute.String.Escape (str)
	if type (str) ~= "string" then
		ErrorNoHalt ("GCompute.String.Escape: Expected string, got " .. type (str) .. " instead.\n")
		return ""
	end
	return str
		:gsub ("\\", "\\\\")
		:gsub ("\r", "\\r")
		:gsub ("\n", "\\n")
		:gsub ("\t", "\\t")
		:gsub ("\"", "\\\"")
		:gsub ("\'", "\\\'")
end

-- GCompute bindings