local self = {}
GCompute.TypeParser = GCompute.MakeConstructor (self)

function self:ctor (input)
	self.Input    = input
	self.Position = 1
end

function self:Root ()
	self:AcceptWhitespace ()
	
	local expression = self:Type ()
	if not expression then
		expression = GCompute.AST.Error ("Expected <identifier>, got " .. self:PeekFormatted ())
		expression:SetStartCharacter (self.Position - 1)
	end
	if self.Position <= #self.Input then
		expression:AddErrorMessage ("Expected '.', '<', '[' or '(', got " .. self:PeekFormatted ())
			:SetStartCharacter (self.Position - 1)
	end
	return expression
end

function self:Type ()
	return self:IndexOrParametricIndexOrArrayOrFunction ()
end

local validOperators =
{
	["."] = true,
	["<"] = true,
	["["] = true,
	["("] = true
}
function self:IndexOrParametricIndexOrArrayOrFunction ()
	-- left.identifier
	-- left.identifier < parametric type argument list >
	-- left [ array dimensions ]
	-- left ( function argument list )
	local leftExpression = self:Identifier ()
	if not leftExpression then return nil end
	
	self:AcceptWhitespace ()
	
	local nextSymbol = self:Peek ()
	while validOperators [nextSymbol] do
		self:Accept (nextSymbol)
		self:AcceptWhitespace ()
		
		if nextSymbol == "." then
			local nameIndex = GCompute.AST.NameIndex ()
			nameIndex:SetLeftExpression (leftExpression)
			local identifier = self:Identifier ()
			if not identifier then
				identifier = GCompute.AST.Identifier ()
				identifier:AddErrorMessage ("Expected <identifier> after '.', got " .. self:PeekFormatted () .. ".")
					:SetStartCharacter (self.Position - 1)
			end
			nameIndex:SetIdentifier (identifier)
			leftExpression = nameIndex
		elseif nextSymbol == "(" then
			local functionType = GCompute.AST.FunctionType ()
			functionType:SetReturnTypeExpression (leftExpression)
			
			local parameterList = self:ParameterList ()
			functionType:SetParameterList (parameterList)
			if not self:Accept (")") then
				functionType:AddErrorMessage ("Expected ')' to close function parameter list, got " .. self:PeekFormatted () .. ".")
					:SetStartCharacter (self.Position - 1)
			end
			
			leftExpression = functionType
		elseif nextSymbol == "<" then
			local typeArgumentList = self:TypeArgumentList ()
			typeArgumentList:SetStartCharacter (self.Position - 2)
			if leftExpression:Is ("NameIndex") or leftExpression:Is ("Identifier") then
				if leftExpression:GetTypeArgumentList () then
					leftExpression:GetTypeArgumentList ():AppendArgumentList (typeArgumentList)
				else
					leftExpression:SetTypeArgumentList (typeArgumentList)
				end
			else
				typeArgumentList:AddErrorMessage ("Type argument lists can only be applied to qualified or unqualified names.")
			end
			if not self:Accept (">") then
				leftExpression:AddErrorMessage ("Expected '>' to close type argument list, got " .. self:PeekFormatted () .. ".")
					:SetStartCharacter (self.Position - 1)
			end
			typeArgumentList:SetEndCharacter (self.Position - 2)
		else
			leftExpression:AddErrorMessage ("Unhandled operator '" .. nextSymbol .. "'")
				:SetStartCharacter (self.Position - 2)
		end
		self:AcceptWhitespace ()
		
		nextSymbol = self:Peek ()
	end
	
	return leftExpression
end

function self:ParameterList ()
	local parameterList = GCompute.AST.ParameterList ()
	local type, name = self:Parameter ()
	if not type then
		return parameterList
	end
	
	parameterList:AddParameter (type, name)
	
	self:AcceptWhitespace ()
	while self:Accept (",") do
		self:AcceptWhitespace ()
		
		type, name = self:Parameter ()
		if not type then break end
		parameterList:AddParameter (type, name)
		
		self:AcceptWhitespace ()
	end
	
	return parameterList
end

function self:Parameter ()
	local type = self:Type ()
	self:AcceptWhitespace ()
	local name = self:AcceptPattern ("[a-zA-Z_][a-zA-Z0-9_]*") or self:Accept ("...")
	return type, name
end

function self:TypeParameterList ()
	local typeParameterList = GCompute.AST.TypeParameterList ()
	local name = self:TypeParameter ()
	if not name then
		return typeParameterList
	end
	
	typeParameterList:AddParameter (name)
	
	self:AcceptWhitespace ()
	while self:Accept (",") do
		self:AcceptWhitespace ()
		
		name = self:TypeParameter ()
		if not name then break end
		typeParameterList:AddParameter (name)
		
		self:AcceptWhitespace ()
	end
	
	return typeParameterList
end

function self:TypeParameter ()
	-- Must return a string, not an AST node
	return self:AcceptPattern ("[a-zA-Z_][a-zA-Z0-9_]*")
end

function self:TypeArgumentList ()
	local typeArgumentList = GCompute.AST.TypeArgumentList ()
	
	local type = self:Type ()
	if not type then
		return typeArgumentList
	end
	
	typeArgumentList:AddArgument (type)
	
	self:AcceptWhitespace ()
	while self:Accept (",") do
		self:AcceptWhitespace ()
		
		type = self:Type ()
		if not type then break end
		typeArgumentList:AddArgument (type)
		
		self:AcceptWhitespace ()
	end
	
	return typeArgumentList
end

function self:Identifier ()
	local name = self:AcceptPattern ("[a-zA-Z_][a-zA-Z0-9_]*")
	if not name then return nil end
	
	return GCompute.AST.Identifier (name)
end

function self:Accept (token)
	if self.Input:sub (self.Position, self.Position + #token - 1) == token then
		self.Position = self.Position + #token
		return token
	end
	return nil
end

local anchoredPatterns = {}
function self:AcceptPattern (pattern)
	if not anchoredPatterns [pattern] then
		anchoredPatterns [pattern] = "^" .. pattern
	end
	pattern = anchoredPatterns [pattern]
	
	local startPos, endPos = self.Input:find (pattern, self.Position)
	if startPos then
		self.Position = endPos + 1
		return self.Input:sub (startPos, endPos)
	end
	return nil
end

function self:AcceptWhitespace ()
	return self:AcceptPattern ("[ \t\r\n]+")
end

function self:Peek ()
	local startPos, endPos = self.Input:find ("^[a-zA-Z_][a-zA-Z0-9_]*", self.Position)
	if not startPos then
		if self.Input:sub (self.Position, self.Position + 2) == "..." then
			return "..."
		end
		return self.Input:sub (self.Position, self.Position)
	else
		return self.Input:sub (startPos, endPos)
	end
end

function self:PeekFormatted ()
	local nextSymbol = self:Peek ()
	if nextSymbol then
		if nextSymbol:len () == 0 then
			return "<eof>"
		elseif nextSymbol:len () == 1 then
			return "'" .. GCompute.String.Escape (nextSymbol) .. "'"
		else
			return "\"" .. GCompute.String.Escape (nextSymbol) .. "\""
		end
	else
		return "<eof>"
	end
end