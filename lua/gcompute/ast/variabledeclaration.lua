local self = {}
self.__Type = "VariableDeclaration"
GCompute.AST.VariableDeclaration = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.TypeExpression = nil
	self.Name = "[Unknown Identifier]"
	self.RightExpression = nil
	
	self.Type = nil
	
	self.VariableDefinition = nil
	
	self.Auto = false
	self.Local = false
	self.Static = false
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

function self:GetChildEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		if i == 1 then
			return self.TypeExpression
		elseif i == 2 then
			return self.RightExpression
		end
		return nil
	end
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

function self:IsAuto ()
	return self.Auto
end

function self:IsLocal ()
	return self.Local
end

function self:IsStatic ()
	return self.Static
end

function self:SetAuto (auto)
	self.Auto = auto
end

function self:SetLocal (isLocal)
	self.Local = isLocal
end

function self:SetName (name)
	self.Name = name
end

function self:SetRightExpression (rightExpression)
	self.RightExpression = rightExpression
	if self.RightExpression then self.RightExpression:SetParent (self) end
end

function self:SetStatic (static)
	self.Static = static
end

function self:SetType (type)
	self.Type = type
	
	if self.VariableDefinition then
		self.VariableDefinition:SetType (type)
	end
end

function self:SetTypeExpression (typeExpression)
	if self.TypeExpression == typeExpression then return end
	
	self.TypeExpression = typeExpression
	if self.TypeExpression then
		self.TypeExpression:SetParent (self)
	end
	self.Type = self.TypeExpression and GCompute.DeferredObjectResolution (self.TypeExpression, GCompute.ResolutionObjectType.Type) or nil
end

function self:SetVariableDefinition (variableDefinition)
	self.VariableDefinition = variableDefinition
end

function self:ToString ()
	local typeExpression = self.TypeExpression and self.TypeExpression:ToString () or nil
	typeExpression = self.Type and self.Type:GetFullName () or "[Unknown Type]"
	local variableDeclaration = "[VariableDeclaration]\n"
	if self.Local then
		variableDeclaration = variableDeclaration .. "local "
	end
	if self.Static then
		variableDeclaration = variableDeclaration .. "static "
	end
	if self.Auto then
		variableDeclaration = variableDeclaration .. "auto "
	end
	variableDeclaration = variableDeclaration .. typeExpression .. " " .. (self.Name or "[Unnamed]")
	if self.RightExpression then
		variableDeclaration = variableDeclaration .. " = " .. self.RightExpression:ToString ()
	end
	return variableDeclaration
end

function self:Visit (astVisitor, ...)
	if self:GetTypeExpression () then
		self:SetTypeExpression (self:GetTypeExpression ():Visit (astVisitor, ...) or self:GetTypeExpression ())
	end
	if self:GetRightExpression () then
		self:SetRightExpression (self:GetRightExpression ():Visit (astVisitor, ...) or self:GetRightExpression ())
	end
	
	local astOverride = astVisitor:VisitStatement (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
end