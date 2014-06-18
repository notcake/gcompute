local self = {}
GCompute.Lexing.Token = GCompute.MakeConstructor (self, GCompute.Containers.LinkedListNode)

function GCompute.Lexing.Token ()
	return
	{
		List         = nil,
		Next         = nil,
		Previous     = nil,
		Value        = nil,
		
		TokenType    = GCompute.Lexing.TokenType.Unknown,
		
		Line         = 0,
		Character    = 0,
		EndLine      = 0,
		EndCharacter = 0,
		
		ToString     = self.ToString
	}
end

function self:ctor ()
	self.TokenType    = GCompute.Lexing.TokenType.Unknown
	
	self.Line         = 0
	self.Character    = 0
	self.EndLine      = 0
	self.EndCharacter = 0
end

function self:ToString ()
	if self.AST then
		return "*\"" .. GLib.String.Escape (self.Value) .. "\"*"
	end
	return "\"" .. GLib.String.Escape (self.Value) .. "\""
end