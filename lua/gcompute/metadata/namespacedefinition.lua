local self = {}
GCompute.NamespaceDefinition = GCompute.MakeConstructor (self, GCompute.INamespace)

--- @param name The name of this namespace
function self:ctor (name)
	self.NamespaceType = GCompute.NamespaceType.Unknown

	self.Usings = {}
	self.Members = {}
	self.MemberMetadata = {}
	
	self.ConstructorAST = nil
	self.Constructor = nil
	
	self.UniqueNameMap = nil
	
	self.MergedLocalScope = nil
end

--- Adds an alias to this namespace definition
-- @param name The name of the alias
-- @param objectName The name of the object the alias points to
-- @return The new AliasDefinition
function self:AddAlias (name, objectName)
	if not self.Members [name] then
		self.Members [name] = GCompute.AliasDefinition (name, objectName)
		self.Members [name]:SetContainingNamespace (self)
		self.MemberMetadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Alias)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
	end
	return self.Members [name]
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
		self.MemberMetadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Method)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
	end
	return self.Members [name]:AddFunction (parameterList, typeParameterList)
end

--- Adds a member variable to this namespace definition
-- @param name The name of the member variable
-- @param typeName The type of the member variable, as a string or TypeReference
-- @return The new VariableDefinition
function self:AddMemberVariable (name, typeName)
	if not self.Members [name] then
		self.Members [name] = GCompute.VariableDefinition (name, typeName)
		self.Members [name]:SetContainingNamespace (self)
		self.MemberMetadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Field)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
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
		if self:GetNamespaceType () == GCompute.NamespaceType.Global then
			self.Members [name]:SetNamespaceType (self:GetNamespaceType ())
		end
		self.MemberMetadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Namespace)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
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
		self.MemberMetadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Type)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
	end
	return self.Members [name]:AddType (typeParameterList)
end

function self:AddTypeParameter (name)
	if not self.Members [name] then
		self.Members [name] = GCompute.TypeParameterDefinition (name)
		self.Members [name]:SetContainingNamespace (self)
		self.MemberMetadata [name] = GCompute.MemberInfo (name, GCompute.MemberTypes.Type)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
	end
	return self.Members [name]
end

function self:Clear ()
	self.Members = {}
	self.MemberMetadata = {}
	
	if self.UniqueNameMap then
		self.UniqueNameMap:Clear ()
	end
	
	if self.MergedLocalScope then
		self.MergedLocalScope:Clear ()
	end
end

--- Adds a using directive to this namespace definition
-- @param qualifiedName The name of the namespace to be used
function self:AddUsing (qualifiedName)
	local usingDirective = GCompute.UsingDirective (qualifiedName)
	self.Usings [#self.Usings + 1] = usingDirective
	return usingDirective
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	
	if self.MergedLocalScope then
		self.MergedLocalScope:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:CreateStaticMemberAccessNode ()
	if self:IsRoot () then return nil end
	return GCompute.AST.StaticMemberAccess (self:GetContainingNamespace ():CreateStaticMemberAccessNode (), self:GetName ())
end

--- Returns a function which handles runtime namespace initialization
-- @return A function which handles runtime namespace initialization
function self:GetConstructor ()
	return self.Constructor or GCompute.NullCallback
end

function self:GetEnumerator ()
	local next, tbl, key = pairs (self.Members)
	return function ()
		key = next (tbl, key)
		return key, tbl [key], self.MemberMetadata [key]
	end
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
	return self.MemberMetadata [name]
end

function self:GetMemberRuntimeName (memberDefinition)
	if not self.UniqueNameMap then return memberDefinition:GetName () end
	return self.UniqueNameMap:GetObjectName (memberDefinition)
end

function self:GetMergedLocalScope ()
	return self.MergedLocalScope
end

function self:GetNamespaceType ()
	return self.NamespaceType
end

function self:GetRuntimeName (invalidParameter)
	if invalidParameter then
		GCompute.Error ("MergedNamespaceDefinition:GetRuntimeName : This function does not do what you think it does.")
	end
	
	GCompute.Error ("NamespaceDefinition:GetRuntimeName : Not implemented.")
end

function self:GetType ()
	return GCompute.Types.Namespace
end

function self:GetUniqueNameMap ()
	if not self.UniqueNameMap then
		self.UniqueNameMap = GCompute.UniqueNameMap ()
	end
	return self.UniqueNameMap
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

function self:IsRoot ()
	return self:GetContainingNamespace () == nil
end

--- Returns whether a member with the given name exists
-- @param name The name of the member whose existance is being checked
-- @return A boolean indicating whether a member with the given name exists
function self:MemberExists (name)
	return self.MemberMetadata [name] and true or false
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	for name, memberDefinition in pairs (self.Members) do
		memberDefinition:ResolveTypes (globalNamespace, errorReporter)
	end
end

function self:ResolveUsings (globalNamespace)
	for i = 1, self:GetUsingCount () do
		self:GetUsing (i):Resolve (globalNamespace)
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
	self.Constructor = function ()
		executionContext:PushResumeAST (constructorAST)
	end
end

function self:SetMergedLocalScope (mergedLocalScope)
	self.MergedLocalScope = mergedLocalScope
end

function self:SetNamespaceType (namespaceType)
	self.NamespaceType = namespaceType
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Namespace (" .. GCompute.NamespaceType [self.NamespaceType] .. ")] " .. (self:GetName () or "[Unnamed]")
	
	if not self:IsEmpty () or self:GetUsingCount () > 0 then
		namespaceDefinition = namespaceDefinition .. "\n{"
		
		local newlineRequired = self:GetUsingCount () > 0
		for i = 1, self:GetUsingCount () do
			namespaceDefinition = namespaceDefinition .. "\n    " .. self:GetUsing (i):ToString ()
		end
		
		if self.MergedLocalScope and not self.MergedLocalScope:IsEmpty () then
			if newlineRequired then namespaceDefinition = namespaceDefinition .. "\n    " end
			namespaceDefinition = namespaceDefinition .. "\n    " .. self.MergedLocalScope:ToString ():gsub ("\n", "\n    ")
			newlineRequired = true
		end
		
		if next (self.Members) then
			if newlineRequired then namespaceDefinition = namespaceDefinition .. "\n    " end
			newlineRequired = true
		end
		for name, memberDefinition in pairs (self.Members) do
			namespaceDefinition = namespaceDefinition .. "\n    " .. memberDefinition:ToString ():gsub ("\n", "\n    ")
		end
		namespaceDefinition = namespaceDefinition .. "\n}"
	else
		namespaceDefinition = namespaceDefinition .. " { }"
	end
	
	return namespaceDefinition
end