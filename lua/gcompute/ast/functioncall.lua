local self = {}
self.__Type = "FunctionCall"
GCompute.AST.FunctionCall = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	
	self.ArgumentList = GCompute.AST.ArgumentList ()
	
	self.FunctionCall = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.ArgumentList then
		self.ArgumentList:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	self.FunctionCall:ExecuteAsAST (astRunner, state)
end

function self:GetArgumentList ()
	return self.ArgumentList
end

function self:GetArgumentTypes ()
	return self.ArgumentList:GetArgumentTypes ()
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		elseif i == 2 then
			return self.ArgumentList
		end
		return nil
	end
end

function self:GetLeftExpression ()
	return self.LeftExpression
end

function self:SetArgumentList (argumentList)
	self.ArgumentList = argumentList
	if self.ArgumentList then self.ArgumentList:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Unknown Expression]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	
	return leftExpression .. " " .. argumentList
end

function self:ToTypeNode (typeSystem)
	local functionType = GCompute.AST.FunctionType ()
	functionType:SetTypeSystem (typeSystem)
	functionType:SetStartToken (self:GetStartToken ())
	functionType:SetEndToken (self:GetEndToken ())
	functionType:SetReturnTypeExpression (self:GetLeftExpression ():ToTypeNode ())
	functionType:SetParameterList (self:GetArgumentList ():ToTypeNode ())
	return functionType
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	self:SetArgumentList (self:GetArgumentList ():Visit (astVisitor, ...) or self:GetArgumentList ())
	
	return astVisitor:VisitExpression (self, ...)
end