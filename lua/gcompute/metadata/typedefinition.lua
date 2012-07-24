local self = {}
GCompute.TypeDefinition = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition, GCompute.Type)

--- @param The name of this type
-- @param typeParameterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
function self:ctor (name, typeParameterList)
	self.ImplicitCasts = {}
	self.ExplicitCasts = {}
	
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	
	if #self.TypeParameterList > 0 then
		self.TypeParameterList = GCompute.TypeParameterList (self.TypeParameterList)
	end
	
	for name in self.TypeParameterList:GetEnumerator () do
		self:AddMemberVariable (name, "Type")
	end
end

--- Adds a type cast operator to this type definition
-- @param destinationTypeName The destination type, as a string, DeferredNameResolution or Type
-- @param implicit A boolean indicating whether the cast is implicit (true) or explicit (false)
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddCast (destinationTypeName, implicit, nativeFunction)
	if type (destinationTypeName) == "string" then
		destinationTypeName = GCompute.DeferredNameResolution (destinationTypeName)
	end

	local cast = GCompute.FunctionDefinition ((implicit and "implicit" or "explicit") .. " operator " .. destinationTypeName:GetFullName ())
	cast:SetContainingNamespace (self)
	cast:SetReturnType (destinationTypeName)
	cast:SetNativeFunction (nativeFunction)
	
	if implicit then
		self.ImplicitCasts [#self.ImplicitCasts + 1] = cast
	else
		self.ExplicitCasts [#self.ExplicitCasts + 1] = cast
	end
	
	return cast
end

--- Adds an implicit type cast operator to this type definition
-- @param destinationTypeName The destination type, as a string, DeferredNameResolution or Type
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddImplicitCast (destinationTypeName, nativeFunction)
	return self:AddCast (destinationTypeName, true, nativeFunction)
end

--- Adds an explicit type cast operator to this type definition
-- @param destinationTypeName The destination type, as a string, DeferredNameResolution or Type
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddExplicitCast (destinationTypeName, nativeFunction)
	return self:AddCast (destinationTypeName, false, nativeFunction)
end

--- Adds a child type to this type definition
-- @param name The name of the child type
-- @return The new TypeDefinition
function self:AddNamespace (name)
	return self:AddType (name)
end

--- Gets the short name of this type
-- @return The short name of this type
function self:GetShortName ()
	if self:GetTypeParameterList ():IsEmpty () then
		return self:GetName () or "[Unnamed]"
	else
		return (self:GetName () or "[Unnamed]") .. " " .. self:GetTypeParameterList ():ToString ()
	end
end

--- Gets the type definition for this type
-- @return The TypeDefinition for this type
function self:GetTypeDefinition ()
	return self
end

--- Gets the type parameter list of this type
-- @return The type parameter list of this type
function self:GetTypeParameterList ()
	return self.TypeParameterList
end

--- Returns whether this namespace definition has no members
-- @return A boolean indicating whether this namespace definition has no members
function self:IsEmpty ()
	return next (self.Members) == nil and #self.ImplicitCasts == 0 and #self.ExplicitCasts == 0
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsTypeDefinition ()
	return true
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace)
	for name, memberDefinition in pairs (self.Members) do
		memberDefinition:ResolveTypes (globalNamespace)
	end
	for _, implicitCastDefinition in ipairs (self.ImplicitCasts) do
		implicitCastDefinition:ResolveTypes (globalNamespace)
	end
	for _, explicitCastDefinition in ipairs (self.ExplicitCasts) do
		explicitCastDefinition:ResolveTypes (globalNamespace)
	end
end

--- Returns a string representation of this type
-- @return A string representing this type
function self:ToString ()
	local typeDefinition = "[Type] " .. (self:GetName () or "[Unnamed]")
	if not self:GetTypeParameterList ():IsEmpty () then
		typeDefinition = typeDefinition .. self:GetTypeParameterList ():ToString ()
	end
	
	if not self:IsEmpty () then
		typeDefinition = typeDefinition .. "\n{\n"
		for name, memberDefinition in pairs (self.Members) do
			typeDefinition = typeDefinition .. "    " .. memberDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
	
		if #self.ImplicitCasts + #self.ExplicitCasts > 0 and next (self.Members) then
			typeDefinition = typeDefinition .. "    \n"
		end
		for _, implicitCastDefinition in ipairs (self.ImplicitCasts) do
			typeDefinition = typeDefinition .. "    " .. implicitCastDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		for _, explicitCastDefinition in ipairs (self.ExplicitCasts) do
			typeDefinition = typeDefinition .. "    " .. explicitCastDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		
		typeDefinition = typeDefinition .. "}"
	end
	
	return typeDefinition
end