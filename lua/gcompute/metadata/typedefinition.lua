local self = {}
GCompute.TypeDefinition = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition, GCompute.Type)

--- @param The name of this type
-- @param typeParameterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
function self:ctor (name, typeParameterList)
	self.BaseTypes = {}

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

--- Adds a base type to this type definition
-- @param baseType The base type to be added, as a string, DeferredNameResolution or Type
function self:AddBaseType (baseType)
	if type (baseType) == "string" then
		baseType = GCompute.DeferredNameResolution (baseType, nil, nil, self)
	end
	
	-- Check for cycles, duplicate base types
	if baseType:IsType () then
		if baseType:Equals (self) then
			GCompute.Error ("TypeDefinition:AddBaseType : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because they are the same type.")
			return
		elseif baseType:IsBaseType (self) then
			GCompute.Error ("TypeDefinition:AddBaseType : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because " .. baseType:GetFullName () .. " inherits from " .. self:GetFullName () .. ".")
			return
		elseif self:IsBaseType (baseType) then
			GCompute.Error ("TypeDefinition:AddBaseType : " .. baseType:GetFullName () .. " is already a base type of " .. self:GetFullName () .. ".")
			return
		end
	end
	
	self.BaseTypes [#self.BaseTypes + 1] = baseType
end

--- Adds a type cast operator to this type definition
-- @param destinationType The destination type, as a string, DeferredNameResolution or Type
-- @param implicit A boolean indicating whether the cast is implicit (true) or explicit (false)
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddCast (destinationType, implicit, nativeFunction)
	if type (destinationType) == "string" then
		destinationType = GCompute.DeferredNameResolution (destinationType, nil, nil, self)
	end

	local cast = GCompute.FunctionDefinition ((implicit and "implicit" or "explicit") .. " operator " .. destinationType:GetFullName ())
	cast:SetContainingNamespace (self)
	cast:SetReturnType (destinationType)
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

function self:CanExplicitCastTo (destinationType)
	for _, functionDefinition in ipairs (self.ExplicitCasts) do
		if functionDefinition:GetReturnType ():Equals (destinationType) then
			return true
		end
	end
	return false
end

function self:CanImplicitCastTo (destinationType)
	for _, functionDefinition in ipairs (self.ImplicitCasts) do
		if functionDefinition:GetReturnType ():Equals (destinationType) then
			return true
		end
	end
	return false
end

function self:CreateRuntimeObject ()
	return {}
end

function self:Equals (otherType)
	otherType = otherType:UnwrapAlias ()
	if self == otherType then return true end
	return false
end

function self:GetBaseTypes ()
	if #self.BaseTypes == 0 then
		if self:IsTop () then return {} end
		return { GCompute.Types.Top }
	end
	return self.BaseTypes
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

--- Returns whether this type derives from baseType
-- @param baseType The base type to be checked
-- @return A boolean indicating whether this type derives from baseType
function self:IsBaseType (baseType)
	baseType = baseType:UnwrapAlias ()
	if baseType:GetFullName () == "Object" then return true end
	
	for _, type in ipairs (self.BaseTypes) do
		if type:Equals (baseType) or type:IsBaseType (baseType) then
			return true
		end
	end
	return false
end

--- Returns whether this namespace definition has no members
-- @return A boolean indicating whether this namespace definition has no members
function self:IsEmpty ()
	return next (self.Members) == nil and #self.ImplicitCasts == 0 and #self.ExplicitCasts == 0
end

--- Gets whether this object is a MergedTypeDefinition
-- @return A boolean indicating whether this object is a MergedTypeDefinition
function self:IsMergedTypeDefinition ()
	return false
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsTypeDefinition ()
	return true
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace)
	-- Resolve base types
	for k, baseType in ipairs (self.BaseTypes) do
		if baseType:IsDeferredNameResolution () then
			baseType:Resolve ()
			if baseType:IsFailedResolution () then
				GCompute.Error ("TypeDefinition:ResolveTypes : Failed to resolve base type of " .. self:GetFullName () .. " : " .. baseType:GetFullName ())
			elseif baseType:GetObject ():Equals (self) then
				GCompute.Error ("TypeDefinition:ResolveTypes : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because they are the same type.")
			elseif baseType:GetObject ():IsBaseType (self) then
				GCompute.Error ("TypeDefinition:ResolveTypes : Cannot add base type " .. baseType:GetFullName () .. " to " .. self:GetFullName () .. " because " .. baseType:GetFullName () .. " inherits from " .. self:GetFullName () .. ".")
			elseif self:IsBaseType (baseType:GetObject ()) then
				GCompute.Error ("TypeDefinition:ResolveTypes : " .. baseType:GetFullName () .. " is already a base type of " .. self:GetFullName () .. ".")
			else
				self.BaseTypes [k] = baseType:GetObject ()
			end
		end
	end
	
	-- Resolve members
	for name, memberDefinition in pairs (self.Members) do
		memberDefinition:ResolveTypes (globalNamespace)
	end
	
	-- Resolve implicit cast destination types
	for _, implicitCastDefinition in ipairs (self.ImplicitCasts) do
		implicitCastDefinition:ResolveTypes (globalNamespace)
	end
	
	-- Resolve explicit cast destination types
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