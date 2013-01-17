local self = {}
GCompute.CodeEditor.ITokenSink = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Token (startCharacter, endCharacter, tokenType, tokenValue)
end