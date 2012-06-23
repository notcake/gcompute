local self = {}
self.__Type = "RangeForLoop"
GCompute.AST.RangeForLoop = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.LoopVariable = nil -- VariableDeclaration or QualifiedIdentifier
	self.Range = {}
	
	self.NamespaceDefinition = nil
	self.Body = nil
end

function self:AddValue (n)
	self.Range [#self.Range + 1] = { n }
	if n then n:SetParent (self) end
end

function self:AddRange (startValue, endValue, increment)
	self.Range [#self.Range + 1] = { startValue, endValue, increment }
	if startValue then startValue:SetParent (self) end
	if endValue then endValue:SetParent (self) end
	if increment then increment:SetParent (self) end
end

function self:Evaluate (executionContext)
end

function self:GetBody ()
	return self.Body
end

function self:GetLoopVariable ()
	return self.LoopVariable
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:SetBody (statement)
	self.Body = statement
	if self.Body then self.Body:SetParent (self) end
end

function self:SetLoopVariable (loopVariable)
	self.LoopVariable = loopVariable
	if self.LoopVariable then self.LoopVariable:SetParent (self) end
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:ToString ()
	local loopVariable = self.LoopVariable and self.LoopVariable:ToString () or "[Unknown Identifier]"
	local range = ""
	
	for _, rangeEntry in ipairs (self.Range) do
		if range ~= "" then range = range .. ", " end
		if #rangeEntry == 1 then
			range = range .. rangeEntry [1]:ToString ()
		else
			range = range .. rangeEntry [1]:ToString () .. ":" .. rangeEntry [2]:ToString ()
			if rangeEntry [3] then
				range = range .. ":" .. rangeEntry [3]:ToString ()
			end
		end
	end
	
	local bodyStatement = "    [Unknown Statement]"
	
	if self.Body then
		if self.Body:Is ("Block") then
			bodyStatement = self.Body:ToString ()
		else
			bodyStatement = "    " .. self.Body:ToString ():gsub ("\n", "\n    ")
		end
	end
	return "for (" .. loopVariable .. " = " .. range .. ")\n" .. bodyStatement
end