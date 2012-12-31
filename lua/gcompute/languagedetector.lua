local self = {}
GCompute.LanguageDetector = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Extensions   = {}
	self.PathPatterns = {}
	self.DefaultLanguage = "GLua"
end

function self:AddExtension (language, extension)
	extension = extension:lower ()
	
	self.Extensions [extension] = language
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
	return self:DetectLanguageByPath (sourceFile:GetPath ()) or
	       self:DetectLanguageByContents (sourceFile)
end

function self:DetectLanguageByPath (path)
	path = path:lower ()
	
	local extension = path:match ("%.([^%.]*)$") or ""
	if self.Extensions [extension:lower ()] then
		return self.Extensions [extension:lower ()]
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