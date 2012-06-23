local self = {}
self.__Type = "CaseLabel"
GCompute.AST.CaseLabel = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.CaseExpression = nil
end

function self:Evaluate (executionContext)
end

function self:GetCaseExpression ()
	return self.CaseExpression
end

function self:SetCaseExpression (caseExpression)
	self.CaseExpression = caseExpression
	if self.CaseExpression then self.CaseExpression:SetParent (self) end
end

function self:ToString ()
	return self.CaseExpression and ("case " .. self.CaseExpression:ToString () .. ":") or "default:"
end