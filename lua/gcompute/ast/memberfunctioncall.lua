local self = {}
self.__Type = "MemberFunctionCall"
GCompute.AST.MemberFunctionCall = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	self.Identifier = nil
	self.TypeArgumentList = nil
	
	self.ArgumentList = GCompute.AST.ArgumentList ()
	
	self.FunctionCall = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditString ("Syntax Trees", self.Identifier)
	
	if self.Identifier then
		self.Identifier:ComputeMemoryUsage (memoryUsageReport)
	end
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

function self:GetArgumentTypes (includeLeft)
	if includeLeft == nil then includeLeft = true end
	local argumentTypes = self.ArgumentList:GetArgumentTypes ()
	
	if includeLeft then
		table.insert (argumentTypes, 1, self.LeftExpression:GetType ())
	end
	return argumentTypes
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

function self:GetIdentifier ()
	return self.Identifier
end

function self:GetTypeArgumentList ()
	return self.TypeArgumentList
end

function self:SetArgumentList (argumentList)
	self.ArgumentList = argumentList
	if self.ArgumentList then self.ArgumentList:SetParent (self) end
end

function self:SetIdentifier (identifier)
	self.Identifier = identifier
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetTypeArgumentList (typeArgumentList)
	self.TypeArgumentList = typeArgumentList
	if self.TypeArgumentList then self.TypeArgumentList:SetParent (self) end
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local identifier = self.Identifier and self.Identifier:ToString () or "[Nothing]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	local typeArgumentList = self.TypeArgumentList and self.TypeArgumentList:ToString () or nil
	
	return leftExpression .. ":" .. identifier .. (typeArgumentList and (" " .. typeArgumentList) or "") .. " " .. argumentList
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	if self.TypeArgumentList then
		self:SetTypeArgumentList (self:GetTypeArgumentList ():Visit (astVisitor, ...) or self:GetTypeArgumentList ())
	end
	self:SetArgumentList (self:GetArgumentList ():Visit (astVisitor, ...) or self:GetArgumentList ())
	
	return astVisitor:VisitExpression (self, ...)
end