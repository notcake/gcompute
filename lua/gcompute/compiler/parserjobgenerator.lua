local self = {}
GCompute.ParserJobGenerator = GCompute.MakeConstructor (self)

local openingSymbols =
{
	["{"] = "}",
	["["] = "]",
	["("] = ")"
}
local closingSymbols = {}
for k, v in pairs (openingSymbols) do
	closingSymbols [v] = k
end

function self:ctor (compilationUnit, tokens)
	self.CompilationUnit = compilationUnit
	self.Tokens = tokens
	
	self.JobQueue = {}
	self.Stack = GCompute.Containers.Stack ()
	
	self.OpeningSymbols = openingSymbols
	self.ClosingSymbols = closingSymbols
	self.BlockSymbol = "{"
end

function self:AddJob (startToken, endToken)
	self.JobQueue [#self.JobQueue + 1] = { Start = startToken, End = endToken }
end

function self:Process (callback)
	callback = callback or GCompute.NullCallback

	for token in self.Tokens:GetEnumerator () do
		local symbol = token.Value
		if token.TokenType ~= GCompute.TokenType.Operator then
		elseif self.OpeningSymbols [symbol] then
			self.Stack:Push (token)
		elseif self.ClosingSymbols [symbol] then
			local expectedOpeningSymbol = self.ClosingSymbols [symbol]
			if self.Stack.Top.Value == expectedOpeningSymbol then
				if self.Stack.Top.Value == self.BlockSymbol then
					self:AddJob (self.Stack.Top.Next, token.Previous)
				end
				self.Stack:Pop ()
			else
				self.CompilationUnit:Error ("'" .. symbol .. "' without preceding matching '" .. expectedOpeningSymbol .. "'.", token.Line, token.Character)
			end
		end
	end
	while not self.Stack:IsEmpty () do
		local token = self.Stack:Pop ()
		self.CompilationUnit:Error ("'" .. token.Value .. "' without matching '" .. self.OpeningSymbols [token.Value] .. "'.", token.Line, token.Character)
	end
	self:AddJob (self.Tokens.First, self.Tokens.Last)
	
	callback (self.JobQueue)
end