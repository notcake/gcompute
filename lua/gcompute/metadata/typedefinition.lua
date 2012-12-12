local self = {}
GCompute.TypeDefinition = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition, GCompute.Type)

--- @param The name of this type
-- @param typeParameterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
function self:ctor (name, typeParameterList)
	self.BaseTypes = {}
	
	self.Constructors = {}
	self.ImplicitCasts = {}
	self.ExplicitCasts = {}
	
	self.TypeParameterList = typeParameterList or GCompute.EmptyTypeParameterList
	
	if #self.TypeParameterList > 0 then
		self.TypeParameterList = GCompute.TypeParameterList (self.TypeParameterList)
	end
	
	for name in self.TypeParameterList:GetEnumerator () do
		self:AddAlias (name, "Object")
	end
	
	self:SetNullable (true)
end

--- Adds a base type to this type definition
-- @param baseType The base type to be added, as a string, DeferredObjectResolution or Type
function self:AddBaseType (baseType)
	if type (baseType) == "string" then
		baseType = GCompute.DeferredObjectResolution (baseType, GCompute.ResolutionObjectType.Type, nil, self)
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
-- @param destinationType The destination type, as a string, DeferredObjectResolution or Type
-- @param implicit A boolean indicating whether the cast is implicit (true) or explicit (false)
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddCast (destinationType, implicit, nativeFunction)
	if type (destinationType) == "string" then
		destinationType = GCompute.DeferredObjectResolution (destinationType, GCompute.ResolutionObjectType.Type, nil, self)
	end

	local fullName = destinationType:IsDeferredObjectResolution () and destinationType:GetName () or destinationType:GetFullName ()
	local cast = GCompute.FunctionDefinition ((implicit and "implicit" or "explicit") .. " operator " .. fullName)
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

function self:AddConstructor (parameterList)
	local constructorDefinition = GCompute.ConstructorDefinition (self:GetName (), parameterList)
	constructorDefinition:SetReturnType (self)
	constructorDefinition:SetContainingNamespace (self)
	constructorDefinition:SetMemberStatic (true)
	
	self.Constructors [#self.Constructors + 1] = constructorDefinition
	
	return constructorDefinition
end

--- Adds an implicit type cast operator to this type definition
-- @param destinationTypeName The destination type, as a string, DeferredObjectResolution or Type
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddImplicitCast (destinationTypeName, nativeFunction)
	return self:AddCast (destinationTypeName, true, nativeFunction)
end

--- Adds an explicit type cast operator to this type definition
-- @param destinationTypeName The destination type, as a string, DeferredObjectResolution or Type
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

function self:CanConstructFrom (sourceType)
	local argumentTypeArray = { sourceType }
	for _, constructorDefinition in ipairs (self.Constructors) do
		if constructorDefinition:GetType ():CanAcceptArgumentTypes (argumentTypeArray) then
			return true
		end
	end
	return false
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

function self:CreateDefaultValue ()
	if self:IsNullable () then return nil end
	return nil
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

function self:GetConstructor (index)
	return self.Constructors [index]
end

function self:GetConstructorCount ()
	return #self.Constructors
end

function self:GetConstructorEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Constructors [i]
	end
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

--- Returns the Type of this object
-- @return A Type representing the type of this object
function self:GetType ()
	return GCompute.Types.Type
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

function self:IsConcreteType ()
	-- TODO: Fix this for nested types
	return self.TypeParameterList:IsEmpty ()
end

--- Returns whether this namespace definition has no members
-- @return A boolean indicating whether this namespace definition has no members
function self:IsEmpty ()
	return #self.Constructors == 0 and next (self.Members) == nil and #self.ImplicitCasts == 0 and #self.ExplicitCasts == 0
end

--- Gets whether this object is a MergedTypeDefinition
-- @return A boolean indicating whether this object is a MergedTypeDefinition
function self:IsMergedTypeDefinition ()
	return false
end

function self:IsNamespace ()
	return false
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsTypeDefinition ()
	return true
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	-- Resolve base types
	for k, baseType in ipairs (self.BaseTypes) do
		if baseType:IsDeferredObjectResolution () then
			baseType:Resolve ()
			if baseType:IsFailedResolution () then
				GCompute.Error ("TypeDefinition:ResolveTypes : Failed to resolve base type of " .. self:GetFullName () .. " : " .. baseType:GetFullName ())
				baseType:GetAST ():GetMessages ():PipeToErrorReporter (GCompute.DefaultErrorReporter)
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
	
	-- Resolve constructor types
	for _, constructorDefinition in ipairs (self.Constructors) do
		constructorDefinition:ResolveTypes (globalNamespace, errorReporter)
	end
	
	-- Resolve members
	for name, memberDefinition in pairs (self.Members) do
		memberDefinition:ResolveTypes (globalNamespace, errorReporter)
	end
	
	-- Resolve implicit cast destination types
	for _, implicitCastDefinition in ipairs (self.ImplicitCasts) do
		implicitCastDefinition:ResolveTypes (globalNamespace, errorReporter)
	end
	
	-- Resolve explicit cast destination types
	for _, explicitCastDefinition in ipairs (self.ExplicitCasts) do
		explicitCastDefinition:ResolveTypes (globalNamespace, errorReporter)
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
		local newlineRequired = false
		
		if #self.Constructors > 0 then
			typeDefinition = typeDefinition .. "    // Constructors\n"
			newlineRequired = true
		end
		for _, constructorDefinition in ipairs (self.Constructors) do
			typeDefinition = typeDefinition .. "    " .. constructorDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		
		if next (self.Members) then
			if newlineRequired then typeDefinition = typeDefinition .. "    \n" end
			newlineRequired = true
		end
		for name, memberDefinition in pairs (self.Members) do
			typeDefinition = typeDefinition .. "    " .. memberDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		
		if #self.ImplicitCasts > 0 or #self.ExplicitCasts > 0 then
			if newlineRequired then typeDefinition = typeDefinition .. "    \n" end
			typeDefinition = typeDefinition .. "    // Casts\n"
			newlineRequired = true
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