local self = {}
self.__Type = "New"
GCompute.AST.New = GCompute.AST.MakeConstructor (self, GCompute.AST.Expression)

function self:ctor ()
	self.LeftExpression = nil
	
	self.ArgumentList = GCompute.AST.ArgumentList ()
	
	self.NativelyAllocated = false
	
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
	if state == 0 and not self.NativelyAllocated then
		astRunner:PushValue (GCompute.RuntimeObject (self:GetType ()))
	end
	self.FunctionCall:ExecuteAsAST (astRunner, state)
end

function self:GetArgumentList ()
	return self.ArgumentList
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

function self:IsNativelyAllocated ()
	return self.NativelyAllocated
end

function self:SetArgumentList (argumentList)
	self.ArgumentList = argumentList
	if self.ArgumentList then self.ArgumentList:SetParent (self) end
end

function self:SetLeftExpression (leftExpression)
	self.LeftExpression = leftExpression
	if self.LeftExpression then self.LeftExpression:SetParent (self) end
end

function self:SetNativelyAllocated (nativelyAllocated)
	self.NativelyAllocated = nativelyAllocated
end

function self:ToString ()
	local leftExpression = self.LeftExpression and self.LeftExpression:ToString () or "[Nothing]"
	local argumentList = self.ArgumentList and self.ArgumentList:ToString () or "([Nothing])"
	
	return "new " .. leftExpression .. " " .. argumentList
end

function self:Visit (astVisitor, ...)
	self:SetLeftExpression (self:GetLeftExpression ():Visit (astVisitor, ...) or self:GetLeftExpression ())
	self:SetArgumentList (self:GetArgumentList ():Visit (astVisitor, ...) or self:GetArgumentList ())
	
	return astVisitor:VisitExpression (self, ...)
end