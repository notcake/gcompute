local self = {}
GCompute.LanguageDetector = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Extensions   = {}
	self.PathPatterns = {}
	self.DefaultLanguage = "GLua"
end

function self:AddExtension (language, extension)
	extension = string.lower (extension)
	
	self.Extensions [extension] = language
end

function self:AddPathPattern (language, pattern)
	pattern = string.lower (pattern)
	
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
	return self:DetectLanguageByPath (sourceFile:GetPath ()) or
	       self:DetectLanguageByContents (sourceFile)
end

function self:DetectLanguageByPath (path)
	path = string.lower (path)
	
	local extension = string.match (path, "%.([^%.]*)$") or ""
	if self.Extensions [string.lower (extension)] then
		return self.Extensions [string.lower (extension)]
	end
	for i = 1, #self.PathPatterns do
		if string.find (path, self.PathPatterns [i].Pattern) then
			return self.PathPatterns [i].Language
		end
	end
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