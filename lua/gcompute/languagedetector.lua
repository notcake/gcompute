local self = {}
GCompute.LanguageDetector = GCompute.MakeConstructor (self)

function self:ctor ()
	self.PathPatterns = {}
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
	return GCompute.Languages.Get ("Expression 2")
end

GCompute.LanguageDetector = GCompute.LanguageDetector ()