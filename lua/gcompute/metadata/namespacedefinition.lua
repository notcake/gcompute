local self = {}
GCompute.NamespaceDefinition = GCompute.MakeConstructor (self, GCompute.MetadataObject)

--- @param name The name of this namespace
function self:ctor (name)
	self.Usings = {}
	self.Members = {}
	self.Metadata = {}
end

--- Adds a child namespace to this namespace definition
-- @param name The name of the child namespace
-- @return The new NamespaceDefinition
function self:AddNamespace (name)
	if not self.Members [name] then
		self.Members [name] = GCompute.NamespaceDefinition (name)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Namespace)
	end
	return self.Members [name]
end

--- Adds a member variable to this namespace definition
-- @param name The name of the member variable
-- @param typeName The type of the member variable, as a string or TypeReference
-- @return The new VariableDefinition
function self:AddMember (name, typeName)
	if not self.Members [name] then
		self.Members [name] = GCompute.VariableDefinition (name, typeName)
		self.Members [name]:SetContainingNamespace (self)
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Member)
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
		self.Metadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.TypeInfo)
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
	end
	return self.Members [name]:AddFunction (parameterList, typeParameterList)
end

--- Adds a using directive to this namespace definition
-- @param qualifiedName The name of the namespace to be used
function self:AddUsing (qualifiedName)
	self.Usings [#self.Usings + 1] = GCompute.UsingDirective (qualifiedName)
end

--- Returns the metadata of a member object
-- @param name The name of the member object
-- @return The MemberInfo object for the given member object
function self:GetMemberMetadata (name)
	return self.Metadata [name]
end