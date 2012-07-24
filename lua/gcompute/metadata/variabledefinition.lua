local self = {}
GCompute.VariableDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this variable
-- @param typeName The type of this variable as a string or DeferredNameResolution or Type
function self:ctor (name, typeName)
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	if type (typeName) == "string" then
		self.Type = GCompute.DeferredNameResolution (typeName)
	elseif typeName:IsDeferredNameResolution () then
		self.Type = typeName
	elseif typeName:IsType () then
		self.Type = typeName
	else
		GCompute.Error ("VariableDefinition:ctor : typeName must be a string, DeferredNameResolution or Type")
	end
end

--- Resolves the type of this variable
function self:ResolveTypes (globalNamespace)
	self.Type:Resolve (globalNamespace, self:GetContainingNamespace ())
end

--- Returns the type of this object
-- @return A Type representing the type of this object
function self:GetType ()
	return self.Type
end

--- Returns a string representing this VariableDefinition
-- @return A string representing this VariableDefinition
function self:ToString ()
	local type = self.Type and self.Type:ToString () or "[Unknown Type]"
	return "[Variable] " .. type .. " " .. (self:GetName () or "[Unnamed]")
end