if not GCompute.Languages then
	GCompute.Languages = {}
end
local Languages = GCompute.Languages
Languages.Languages = {}

function Languages.Create (Name)
	local Language = Languages.Language (Name)
	Language.Name = Name
	return Language
end

function Languages.Get (Name)
	return Languages.Languages [Name]
end