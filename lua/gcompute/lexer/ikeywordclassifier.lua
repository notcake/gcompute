local self = {}
GCompute.Lexing.IKeywordClassifier = GCompute.MakeConstructor (self)

function self:ctor ()
end

-- Returns () -> (string, KeywordType)
function self:GetKeywordEnumerator ()
	GCompute.Error ("IKeywordClassifier:GetKeywordEnumerator : Not implemented.")
end

function self:GetKeywordType (keyword)
	GCompute.Error ("IKeywordClassifier:GetKeywordType : Not implemented.")
end

function self:IsKeyword (tokenString)
	GCompute.Error ("IKeywordClassifier:IsKeyword : Not implemented.")
end