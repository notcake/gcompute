local self = {}
self.__Type = "Return"
GCompute.AST.Return = GCompute.AST.MakeConstructor (self, GCompute.AST.Control)

function self:ctor ()
	self.ReturnExpression = nil
end

function self:Evaluate (executionContext)
	if self.ReturnExpression then
		executionContext:Return (self.ReturnExpression:Evaluate (executionContext))
	else
		executionContext:Return ()
	end
end

function self:GetReturnExpression ()
	return self.ReturnExpression
end

function self:SetReturnExpression (expression)
	self.ReturnExpression = expression
	if self.ReturnExpression then self.ReturnExpression:SetParent (self) end
end

function self:ToString ()
	if self.ReturnExpression then
		return "return " .. self.ReturnExpression:ToString ()
	end
	return "return"
end