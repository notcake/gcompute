local self = {}
self.__Type = "IteratorForLoop"
GCompute.AST.IteratorForLoop = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Variables = {} -- VariableDeclarations or QualifiedIdentifiers
	self.VariableCount = 0
	self.IteratorExpression = nil
	
	self.NamespaceDefinition = GCompute.NamespaceDefinition ()
	self.Body = nil
end

function self:AddVariable (variable)
	self.VariableCount = self.VariableCount + 1
	self.Variables [self.VariableCount] = variable
	if variable then variable:SetParent (self) end
end

function self:AddVariables (variables)
	for _, variable in ipairs (variables) do
		self:AddVariable (variable)
	end
end

function self:Evaluate (executionContext)
end

function self:GetBody ()
	return self.Body
end

function self:GetIteratorExpression()
	return self.IteratorExpression
end

function self:GetNamespace ()
	return self.NamespaceDefinition
end

function self:GetVariable (index)
	return self.Variables [index]
end

function self:GetVariableCount ()
	return self.VariableCount
end

function self:SetBody (statement)
	self.Body = statement
	if self.Body then self.Body:SetParent (self) end
end

function self:SetIteratorExpression (iteratorExpression)
	self.IteratorExpression = iteratorExpression
	if self.IteratorExpression then self.IteratorExpression:SetParent (self) end
end

function self:SetNamespace (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:SetVariable (index, variable)
	self.Variables [index] = variable
	if variable then variable:SetParent (self) end
end

function self:ToString ()
	local variables = ""
	for i = 1, self.VariableCount do
		if variables ~= "" then
			variables = variables .. ", "
		end
		variables = variables .. self.Variables [i]:ToString ()
	end
	local iteratorExpression = self.IteratorExpression and self.IteratorExpression:ToString () or "[Unknown Expression]"
	
	local bodyStatement = "    [Unknown Statement]"
	
	if self.Body then
		if self.Body:Is ("Block") then
			bodyStatement = self.Body:ToString ()
		else
			bodyStatement = "    " .. self.Body:ToString ():gsub ("\n", "\n    ")
		end
	end
	return "foreach (" .. variables .. " in " .. iteratorExpression .. ")\n" .. bodyStatement
end