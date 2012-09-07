local self = {}
GCompute.Token = GCompute.MakeConstructor (self, GCompute.Containers.LinkedListNode)

function self:ctor ()
	self.TokenType    = GCompute.TokenType.Unknown
	
	self.Line         = 0
	self.Character    = 0
	self.EndLine      = 0
	self.EndCharacter = 0
end