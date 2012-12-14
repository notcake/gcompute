local self = {}
self.__Type = "ArrayIndexAssignment"
GCompute.AST.ArrayIndexAssignment = GCompute.AST.MakeConstructor (self, GCompute.AST.ArrayIndex)

function self:ctor ()
	self.RightExpression = nil
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.LeftExpression then
		self.LeftExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.TypeArgumentList then
		self.TypeArgumentList:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.ArgumentList then
		self.ArgumentList:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.LeftExpression
		elseif i == 2 then
			return self.ArgumentList
		elseif i == 3 then
			return self.RightExpression
		elseif i == 4 then
			return self.TypeArgumentList
		end
		return nil
	end
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	local rightExpression = self.RightExpression and self.RightExpression:ToString () or "[Nothing]"
	
	if self.TypeArgumentList then
		return leftExpression .. " " .. self.TypeArgumentList:ToString () .. " [" .. string.sub (argumentList, 2, -2) .. "] = " .. rightExpression
	end
	return leftExpression .. " [" .. string.sub (argumentList, 2, -2) .. "] = " .. rightExpression
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	if self.TypeArgumentList then
		self:SetTypeArgumentList (self:GetTypeArgumentList ():Visit (astVisitor, ...) or self:GetTypeArgumentList ())
	end
	self:SetArgumentList (self:GetArgumentList ():Visit (astVisitor, ...) or self:GetArgumentList ())
	self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	
	return astVisitor:VisitExpression (self, ...)
end