local self = {}
GCompute.TypeParser = GCompute.MakeConstructor (self, GCompute.Parser)
GCompute.StaticTypeParser = self

local symbols = {
	"->", ".", ",", "(", ")", "[", "]", "<", ">"
}

function self:ctor (typeName)
	self.Tokens = GCompute.Containers.LinkedList ()
	
	local i = 1
	while i <= typeName:len () do
		local wasSymbol = false
		for j = 1, #symbols do
			if typeName:sub (i, i + symbols [j]:len () - 1) == symbols [j] then
				local token = self.Tokens:AddLast (symbols [j])
				token.TokenType = GCompute.TokenType.Operator
				token.Line = 1
				token.Character = i
				i = i + symbols [j]:len ()
				wasSymbol = true
				break
			end
		end
		if not wasSymbol then
			if typeName:sub (i, i) == " " or
				typeName:sub (i, i) == "\t" then
				i = i + 1
			else
				local identifier = typeName:match ("^[a-zA-Z_][a-zA-Z0-9_]*", i)
				if identifier then
					local token = self.Tokens:AddLast (identifier)
					token.TokenType = GCompute.TokenType.Identifier
					token.Line = 1
					token.Character = i
					i = i + identifier:len ()
				else
					local number = typeName:match ("^[0-9]+", i)
					if number then
						local token = self.Tokens:AddLast (number)
						token.TokenType = GCompute.TokenType.Number
						token.Line = 1
						token.Character = i
						i = i + number:len ()
					else
						GCompute.Error ("TypeParser:ctor : Unknown character '" .. typeName:sub (i, i) .. "' in type name \"" .. typeName .. "\".")
						i = i + 1
					end
				end
			end
		end
	end
	
	self.ParseTree = self:Parse (self.Tokens)
end

function self:Root ()
	self.ParseTree = self:Type ()
end

function self:Type ()
	return self:TypeFunction ()
end

function self:TypeFunction ()
	return self:RecurseRight (self.TypeScoped, {["->"] = true})
end

function self:TypeScoped ()
	return self:RecurseLeft (self.TypeArray, {["."] = true})
end

function self:TypeArray ()
	local elementType = self:TypeTuple ()
	
	while self:Accept ("[") do
		local array = GCompute.Containers.Tree ("array")
		array:AddNode (elementType)
		
		local arguments = self:List (self.ArrayRank)
		arguments.Value = "args"
		array:AddNode (arguments)
		
		if not self:Accept ("]") then
			self:ExpectedToken ("]")
			return array
		end
		
		elementType = array
	end
	
	return elementType
end

function self:TypeArrayRank ()
	if self:Peek () == "," or
		self:Peek () == "]" then
		return GCompute.Containers.Tree ("any")
	end
	
	local number = self:AcceptType (GCompute.TokenType.Number)
	if number then
		return GCompute.Containers.Tree (number)
	end
end

function self:TypeTuple ()
	if self:Accept ("(") then
		local tuple = GCompute.Containers.Tree ("tuple")
		
		local arguments = self:List (self.Type)
		arguments.Value = "args"
		tuple:AddNode (arguments)
		if not self:Accept (")") then
			self:ExpectedToken (")")
		end
		
		return tuple
	end
	return self:TypeTemplate ()
end

function self:TypeTemplate ()
	local typeName = self:TypeName ()
	if not self:Accept ("<") then
		return typeName
	end
	local parametricType = GCompute.Containers.Tree ("parametric_type")
	parametricType:AddNode (typeName)
	if self:Accept (">") then
		self:SyntaxError ("Empty parametric type argument lists are not allowed.")
		return parametricType
	else
		local arguments = self:List (self.Type)
		arguments.Value = "args"
		parametricType:AddNode (arguments)
		if not self:Accept (">") then
			self:ExpectedToken (">")
		end
	end
	return parametricType
end

function self:TypeName ()
	local typeName = self:AcceptType (GCompute.TokenType.Identifier)
	if not typeName then
		return nil
	end
	
	local tree = GCompute.Containers.Tree ("name")
	tree:Add (typeName)
	
	return tree
end