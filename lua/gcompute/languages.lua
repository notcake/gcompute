GCompute.Languages = GCompute.Languages or {}
local Languages = GCompute.Languages
Languages.Languages = {}

function Languages.Create (name)
	local Language = Languages.Language (name)
	Languages.Languages [name] = Language
	return Language
end

function Languages.Get (name)
	return Languages.Languages [name]
end

function Languages.GetEnumerator ()
	local next, tbl, key = pairs (Languages.Languages)
	return function ()
		key = next (tbl, key)
		return tbl [key]
	end
end