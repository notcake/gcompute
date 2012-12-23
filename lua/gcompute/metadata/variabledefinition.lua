local self = {}
GCompute.VariableDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this variable
-- @param typeName The type of this variable as a string or DeferredObjectResolution or Type
function self:ctor (name, typeName)
	self.Type = nil
	
	self:SetType (typeName)
end

-- Variable
--- Sets the type of this object
-- @param type The Type of this object as a string or DeferredObjectResolution or Type
function self:SetType (type)
	self.Type = GCompute.ToDeferredTypeResolution (type, self:GetGlobalNamespace (), self:GetDeclaringObject ())
	return self
end

-- Definition
function self:CreateRuntimeObject ()
	return self.Type:UnwrapAlias ():CreateDefaultValue ()
end

--- Returns the type of this object
-- @return A Type representing the type of this object
function self:GetType ()
	return self.Type
end

function self:IsVariable ()
	return true
end

--- Resolves the type of this variable
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	if not self.Type then return end
	
	if self.Type:IsDeferredObjectResolution () then
		self.Type:Resolve (globalNamespace, self:GetDeclaringObject ())
		if self.Type:IsFailedResolution () then
			self.Type:GetAST ():GetMessages ():PipeToErrorReporter (errorReporter)
			self.Type = GCompute.ErrorType ()
		else
			self.Type = self.Type:GetObject ():ToType ()
		end
	end
end

--- Returns a string representing this VariableDefinition
-- @return A string representing this VariableDefinition
function self:ToString ()
	local type = self.Type and self.Type:GetFullName () or "[Unknown Type]"
	return "[Variable] " .. type .. " " .. (self:GetName () or "[Unnamed]")
end