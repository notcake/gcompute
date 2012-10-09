local self = {}
GCompute.LanguageDetector = GCompute.MakeConstructor (self)

function self:ctor ()
	self.PathPatterns = {}
	self.DefaultLanguage = "GLua"
end

function self:AddPathPattern (language, pattern)
	pattern = pattern:lower ()
	
	self.PathPatterns [#self.PathPatterns + 1] =
	{
		Pattern = pattern,
		Language = language
	}
end

function self:DetectLanguage (sourceFile)
	if not sourceFile:HasPath () then
		return self:DetectLanguageByContents (sourceFile)
	end
	local path = sourceFile:GetPath ():lower ()
	for i = 1, #self.PathPatterns do
		if string.find(path, self.PathPatterns [i].Pattern) then
			return self.PathPatterns [i].Language
		end
	end
	return self:DetectLanguageByContents (sourceFile)
end

function self:DetectLanguageByContents (sourceFile)
	return self:GetDefaultLanguage ()
end

function self:GetDefaultLanguage ()
	if type (self.DefaultLanguage) == "string" then
		return GCompute.Languages.Get (self.DefaultLanguage) or GCompute.Languages.Get ("GLua")
	end
	return self.DefaultLanguage
end

function self:SetDefaultLanguage (defaultLanguage)
	self.DefaultLanguage = defaultLanguage
end

GCompute.LanguageDetector = GCompute.LanguageDetector ()