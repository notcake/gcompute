local self = {}
GCompute.TypeParser = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:Root (str)
	local pos = self:AcceptWhitespace (1, str)
	local expression, newPos = self:IndexOrParametricIndexOrArrayOrFunction (pos, str)
	if not expression then
		if str:len () == 0 then
			self:Error (1, str, "Input is the empty string")
		else
			self:Error (pos, str, "Expected <identifier>, got " .. self:PeekFormatted (pos, str))
		end
		return nil
	end
	return expression
end

function self:Type (pos, str)
	if self:Peek (pos, str) == "(" then
		-- tuple?
	end
end

local validOperators =
{
	["."] = true,
	["<"] = true,
	["["] = true,
	["("] = true
}
function self:IndexOrParametricIndexOrArrayOrFunction (pos, str)
	-- left.identifier
	-- left.identifier < parametric type argument list >
	-- left [ array dimensions ]
	-- left ( function argument list )
	local leftExpression, newPos = self:Identifier (pos, str)
	if not leftExpression then return nil end
	pos = newPos
	
	pos = self:AcceptWhitespace (pos, str)
	local nextSymbol, newPos = nil, nil
	nextSymbol, newPos = self:Peek (pos, str)
	while validOperators [nextSymbol] do
		pos = newPos
		pos = self:AcceptWhitespace (pos, str)
		
		if nextSymbol == "." then
			local nameIndex = GCompute.AST.NameIndex ()
			nameIndex:SetLeftExpression (leftExpression)
			local identifier, newPos = self:Identifier (pos, str)
			if not identifier then
				self:Error (pos, str, "Expected <identifier> after '.', got " .. self:PeekFormatted (pos, str))
			else
				pos = newPos
			end
			nameIndex:SetIdentifier (identifier)
			leftExpression = nameIndex
		else
			self:Error (pos, str, "Unhandled operator " .. self:PeekFormatted (pos, str))
		end
		pos = self:AcceptWhitespace (pos, str)
		nextSymbol, newPos = self:Peek (pos, str)
	end
	
	if pos <= str:len () then
		self:Error (pos, str, "Expected '.', '<', '[' or '(', got " .. self:PeekFormatted (pos, str))
	end
	
	return leftExpression
end

function self:Identifier (pos, str)
	local startPos, endPos = str:find ("^[a-zA-Z_][a-zA-Z0-9_]*", pos)
	if not startPos then return nil, nil end
	
	return GCompute.AST.Identifier (str:sub (startPos, endPos)), endPos + 1
end

local whitespace =
{
	[" "] = true,
	["\t"] = true,
	["\r"] = true,
	["\n"] = true
}
function self:AcceptWhitespace (pos, str)
	while whitespace [str:sub (pos, pos)] do
		pos = pos + 1
	end
	return pos
end

function self:Error (pos, str, message)
	ErrorNoHalt ("GCompute.TypeParser : Parsing \"" .. str .. "\": char " .. pos .. ": " .. message .. "\n")
end

function self:Peek (pos, str)
	local startPos, endPos = str:find ("^[a-zA-Z_][a-zA-Z0-9_]*", pos)
	if not startPos then
		return str:sub (pos, pos), pos + 1
	else
		return str:sub (startPos, endPos), endPos + 1
	end
end

function self:PeekFormatted (pos, str)
	local nextSymbol = self:Peek (pos, str)
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

GCompute.TypeParser = GCompute.TypeParser ()