local self = {}
GCompute.NamespaceDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this namespace
function self:ctor (name)
	self.Usings = {}
	self.Members = {}
	self.Metadata = {}
	
	self.ConstructorAST = nil
	self.Constructor = nil
end

--- Adds an alias to this namespace definition
-- @param name The name of the alias
-- @param objectName The name of the object the alias points to
-- @return The new AliasDefinition
function self:AddAlias (name, objectName)
	if not self.Members [name] then
		self.Members [name] = GCompute.AliasDefinition (name, objectName)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Alias)
		self.Members [name]:SetMetadata (self.Metadata [name])
	end
	return self.Members [name]
end

--- Adds a child namespace to this namespace definition
-- @param name The name of the child namespace
-- @return The new NamespaceDefinition
function self:AddNamespace (name)
	if not self.Members [name] then
		self.Members [name] = GCompute.NamespaceDefinition (name)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Namespace)
		self.Members [name]:SetMetadata (self.Metadata [name])
	end
	return self.Members [name]
end

--- Adds a member variable to this namespace definition
-- @param name The name of the member variable
-- @param typeName The type of the member variable, as a string or TypeReference
-- @return The new VariableDefinition
function self:AddMemberVariable (name, typeName)
	if not self.Members [name] then
		self.Members [name] = GCompute.VariableDefinition (name, typeName)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Field)
		self.Members [name]:SetMetadata (self.Metadata [name])
	end
	return self.Members [name]
end

--- Adds a type to this namespace definition
-- @param name The name of the type
-- @param typeParameterList A TypeParameterList describing the parameters the type takes or nil if the type is non-parametric
-- @return The new TypeDefinition
function self:AddType (name, typeParameterList)
	if not self.Members [name] then
		self.Members [name] = GCompute.OverloadedTypeDefinition (name)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Type)
		self.Members [name]:SetMetadata (self.Metadata [name])
	end
	return self.Members [name]:AddType (typeParameterList)
end

--- Adds a function to this namespace definition
-- @param name The name of the function
-- @param parameters A ParameterList describing the parameters the function takes or nil
-- @param typeParameters A TypeParameterList describing the type parameters the function takes or nil
-- @return The new FunctionDefinition
function self:AddFunction (name, parameterList, typeParameterList)
	if not self.Members [name] then
		self.Members [name] = GCompute.OverloadedFunctionDefinition (name)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Method)
		self.Members [name]:SetMetadata (self.Metadata [name])
	end
	return self.Members [name]:AddFunction (parameterList, typeParameterList)
end

--- Adds a using directive to this namespace definition
-- @param qualifiedName The name of the namespace to be used
function self:AddUsing (qualifiedName)
	self.Usings [#self.Usings + 1] = GCompute.UsingDirective (qualifiedName)
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	return memoryUsageReport
end

--- Returns a function which handles runtime namespace initialization
-- @return A function which handles runtime namespace initialization
function self:GetConstructor ()
	return self.Constructor or GCompute.NullCallback
end

--- Returns the definition object of a member object
-- @param name The name of the member object
-- @return The definition object for the given member object
function self:GetMember (name)
	return self.Members [name]
end

--- Returns the metadata of a member object
-- @param name The name of the member object
-- @return The MemberInfo object for the given member object
function self:GetMemberMetadata (name)
	return self.Metadata [name]
end

--- Returns the UsingDirective identified by the given index
-- @param index The index of the UsingDirective
-- @return The UsingDirective with the given index or nil
function self:GetUsing (index)
	return self.Usings [index]
end

--- Returns the number of using directives this namespace definition has
-- @return The number of using directives this namespace definition has
function self:GetUsingCount ()
	return #self.Usings
end

--- Returns whether this namespace definition has no members
-- @return A boolean indicating whether this namespace definition has no members
function self:IsEmpty ()
	return next (self.Members) == nil
end

--- Gets whether this object is a NamespaceDefinition
-- @return A boolean indicating whether this object is a NamespaceDefinition
function self:IsNamespace ()
	return true
end

--- Returns whether a member with the given name exists
-- @param name The name of the member whose existance is being checked
-- @return A boolean indicating whether a member with the given name exists
function self:MemberExists (name)
	return self.Metadata [name] and true or false
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace)
	for name, memberDefinition in pairs (self.Members) do
		memberDefinition:ResolveTypes (globalNamespace)
	end
end

--- Sets the runtime initialization function for this namespace
-- @param constructor The runtime initialization function for this namespace
function self:SetConstructor (constructor)
	self.ConstructorAST = nil
	self.Constructor = constructor
end

--- Sets the runtime initialization function AST for this namespace
-- @param constructorAST The runtime initialization function AST for this namespace
function self:SetConstructorAST (constructorAST)
	self.ConstructorAST = constructorAST
	self.Constructor = function (executionContext)
		local astRunner = GCompute.ASTRunner (self.ConstructorAST)
		astRunner:Execute (executionContext)
	end
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Namespace] " .. (self:GetName () or "[Unnamed]")
	
	if not self:IsEmpty () or self:GetUsingCount () > 0 then
		namespaceDefinition = namespaceDefinition .. "\n{\n"
		for i = 1, self:GetUsingCount () do
			namespaceDefinition = namespaceDefinition .. "    " .. self:GetUsing (i):ToString () .. "\n"
		end
		if self:GetUsingCount () > 0 then
			namespaceDefinition = namespaceDefinition .. "    \n"
		end
		for name, memberDefinition in pairs (self.Members) do
			namespaceDefinition = namespaceDefinition .. "    " .. memberDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		namespaceDefinition = namespaceDefinition .. "}"
	end
	
	return namespaceDefinition
end