local Parser = Parser

function Parser:Root ()
	self:PushParseItem ("decl")
	self:PopParseItem ()
end