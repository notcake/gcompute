local self = {}
self.__Type = "SwitchStatement"
GCompute.AST.SwitchStatement = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.SwitchExpression = nil -- Expression or VariableDeclaration

	self.CaseCount = 0
	self.CaseExpressions = {}
	self.CaseBodies = {}
	
	self.NamespaceDefinition = nil
end

function self:AddCase (caseExpression, caseBody)
	self.CaseCount = self.CaseCount + 1
	self.CaseExpressions [self.CaseCount] = caseExpression
	self.CaseBodies [self.CaseCount] = caseBody
	if caseExpression then caseExpression:SetParent (self) end
	if caseBody then caseBody:SetParent (self) end
end

function self:Evaluate (executionContext)
end

function self:GetCaseCount ()
	return self.CaseCount
end

function self:GetCaseBody (index)
	return self.CaseBodies [index]
end

function self:GetCaseExpression (index)
	return self.CaseExpressions [index]
end

function self:GetDefinition ()
	return self.NamespaceDefinition
end

function self:GetSwitchExpression ()
	return self.SwitchExpression
end

function self:SetCaseBody (index, blockStatement)
	self.CaseBodies [index] = blockStatement
	if blockStatement then blockStatement:SetParent (self) end
end

function self:SetCaseExpression (index, caseExpression)
	self.CaseExpressions [index] = Expression
	if caseExpression then caseExpression:SetParent (self) end
end

function self:SetDefinition (namespaceDefinition)
	self.NamespaceDefinition = namespaceDefinition
end

function self:SetSwitchExpression (switchExpression)
	self.SwitchExpression = switchExpression
	if self.SwitchExpression then self.SwitchExpression:SetParent (self) end
end

function self:ToString ()
	local switchExpression = self.SwitchExpression and self.SwitchExpression:ToString () or "[Unknown Expression]"
	local body = ""
	
	for i = 1, self.CaseCount do
		local caseExpression = self.CaseExpressions [i] and self.CaseExpressions [i]:ToString ()
		if caseExpression then
			body = body .. "\ncase " .. caseExpression .. ":"
		else
			body = body .. "\ndefault:"
		end
		body = body .. "\n    " .. self.CaseBodies [i]:ToString ():gsub ("\n", "\n    ")
	end
	
	body = body:gsub ("\n", "\n    ")
	return "switch (" .. switchExpression .. ")\n{" .. body .. "\n}"
end