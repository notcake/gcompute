if not GCompute.Languages then
	GCompute.Languages = {}
end
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