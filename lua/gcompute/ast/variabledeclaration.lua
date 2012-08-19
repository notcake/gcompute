local self = {}
self.__Type = "VariableDeclaration"
GCompute.AST.VariableDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.TypeExpression = nil
	self.Name = "[Unknown Identifier]"
	self.RightExpression = nil
	
	self.Type = nil
	
	self.VariableDefinition = nil
	
	self.Static = false
	self.Local = false
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	
	if self.TypeExpression then
		self.TypeExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.RightExpression then
		self.RightExpression:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:ExecuteAsAST (astRunner, state)
	self.AssignmentPlan:ExecuteAsAST (astRunner, self, state)
end

function self:GetName ()
	return self.Name
end

function self:GetRightExpression ()
	return self.RightExpression
end

function self:GetType ()
	return self.Type
end

function self:GetTypeExpression ()
	return self.TypeExpression
end

function self:GetVariableDefinition ()
	return self.VariableDefinition
end

function self:IsLocal ()
	return self.Local
end

function self:IsStatic ()
	return self.Static
end

function self:SetName (name)
	self.Name = name
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:SetLocal (isLocal)
	self.Local = isLocal
end

function self:SetStatic (static)
	self.Static = static
end

function self:SetTypeExpression (typeExpression)
	self.TypeExpression = typeExpression
	if self.TypeExpression then
		self.TypeExpression:SetParent (self)
	end
	self.Type = GCompute.DeferredNameResolution (self.TypeExpression)
end

function self:SetVariableDefinition (variableDefinition)
	self.VariableDefinition = variableDefinition
end

function self:ToString ()
	local typeExpression = self.TypeExpression and self.TypeExpression:ToString () or "[Unknown Type]"
	local variableDeclaration = "[VariableDeclaration]\n"
	if self.Local then
		variableDeclaration = variableDeclaration .. "local "
	end
	if self.Static then
		variableDeclaration = variableDeclaration .. "static "
	end
	variableDeclaration = variableDeclaration .. typeExpression .. " " .. self.Name
	if self.RightExpression then
		variableDeclaration = variableDeclaration .. " = " .. self.RightExpression:ToString ()
	end
	return variableDeclaration
end

function self:Visit (astVisitor, ...)
	local astOverride = astVisitor:VisitStatement (self, ...)
	if astOverride then astOverride:Visit (astVisitor, ...) return astOverride end
	
	if self:GetTypeExpression () then
		self:SetTypeExpression (self:GetTypeExpression ():Visit (astVisitor, ...) or self:GetTypeExpression ())
	end
	if self:GetRightExpression () then
		self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	end
end