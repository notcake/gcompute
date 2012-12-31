local self = {}
GCompute.Namespace = GCompute.MakeConstructor (self)

function self:ctor ()
	-- System
	self.GlobalNamespace    = nil
	
	-- Hierarchy
	self.Definition         = nil
	self.Module             = nil
	self.DeclaringMethod    = nil
	self.DeclaringNamespace = nil
	self.DeclaringObject    = nil
	self.DeclaringType      = nil
	
	-- Namespace
	self.NamespaceType      = GCompute.NamespaceType.Unknown
	self.Members            = {}
end

-- System
function self:GetGlobalNamespace ()
	return self.GlobalNamespace
end

function self:SetGlobalNamespace (globalNamespace)
	if self.GlobalNamespace == globalNamespace then return end
	self.GlobalNamespace = globalNamespace
	for _, member in self:GetLazyEnumerator () do
		member:SetGlobalNamespace (globalNamespace)
	end
end

-- Hierarchy
function self:GetDeclaringMethod ()
	return self.DeclaringMethod
end

function self:GetDeclaringNamespace ()
	return self.DeclaringNamespace
end

function self:GetDeclaringObject ()
	return self.DeclaringObject
end

function self:GetDeclaringType ()
	return self.DeclaringType
end

function self:GetDefinition ()
	return self.Definition
end

function self:GetModule ()
	return self.Module
end

function self:SetDeclaringMethod (declaringMethod)
	if self.DeclaringMethod == declaringMethod then return end
	self.DeclaringMethod = declaringMethod
	if self.Definition and self.Definition:IsMethod () then return end
	for _, member in self:GetLazyEnumerator () do
		member:SetDeclaringMethod (declaringMethod)
	end
end

function self:SetDeclaringNamespace (declaringNamespace)
	if self.DeclaringNamespace == declaringNamespace then return end
	self.DeclaringNamespace = declaringNamespace
	if self.Definition and self.Definition:IsNamespace () then return end
	for _, member in self:GetLazyEnumerator () do
		member:SetDeclaringNamespace (declaringNamespace)
	end
end

function self:SetDeclaringObject (declaringObject)
	self.DeclaringObject = declaringObject
end

function self:SetDeclaringType (declaringType)
	if self.DeclaringType == declaringType then return end
	self.DeclaringType = declaringType
	if self.Definition and self.Definition:IsClass () then return end
	for _, member in self:GetLazyEnumerator () do
		member:SetDeclaringType (declaringType)
	end
end

function self:SetDefinition (objectDefinition)
	if self.Definition == objectDefinition then return end
	self.Definition = objectDefinition
	
	for _, member in self:GetLazyEnumerator () do
		self:SetupMemberHierarchy (member)
	end
end

function self:SetModule (module)
	if self.Module == module then return end
	self.Module = module
	
	for _, member in self:GetLazyEnumerator () do
		member:SetModule (module)
	end
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self.Members)
	for _, member in self:GetLazyEnumerator () do
		member:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

-- Namespace
--- Adds an alias to this namespace
-- @param name The name of the alias
-- @param object The (name of the) object to which the alias points
-- @return The new AliasDefinition
function self:AddAlias (name, object)
	if not self.Members [name] then
		self.Members [name] = GCompute.AliasDefinition (name, object)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]
end

--- Adds a class to this namespace
-- @param name The name of the class
-- @param typeParameterList A TypeParameterList describing the parameters the class takes or nil if the class is non-parametric
-- @return The new ClassDefinition
function self:AddClass (name, typeParameterList)
	if not self.Members [name] then
		self.Members [name] = GCompute.OverloadedClassDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]:AddClass (typeParameterList)
end

--- Adds an event to this namespace
-- @param name The name of the event
-- @param callbackType The type of the callback function
-- @return The new EventDefinition
function self:AddEvent (name, callbackType)
	if not self.Members [name] then
		self.Members [name] = GCompute.EventDefinition (name, callbackType)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]
end

--- Adds a method to this namespace
-- @param name The name of the method
-- @param parameters A ParameterList describing the parameters the method takes or nil
-- @param typeParameters A TypeParameterList describing the type parameters the method takes or nil
-- @return The new MethodDefinition
function self:AddMethod (name, parameterList, typeParameterList)
	if not self.Members [name] then
		self.Members [name] = GCompute.OverloadedMethodDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]:AddMethod (parameterList, typeParameterList)
end

--- Adds a namespace to this namespace
-- @param name The name of the child namespace
-- @return The new NamespaceDefinition
function self:AddNamespace (name)
	if not self.Members [name] then
		self.Members [name] = GCompute.NamespaceDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
		if self:GetNamespaceType () == GCompute.NamespaceType.Global then
			self.Members [name]:SetNamespaceType (self:GetNamespaceType ())
		end
	end
	return self.Members [name]
end

--- Adds a property to this namespace
-- @param name The name of the property
-- @param type The type of the property
-- @return The new PropertyDefinition
function self:AddProperty (name, type)
	if not self.Members [name] then
		self.Members [name] = GCompute.PropertyDefinition (name, type)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]
end

function self:AddTypeParameter (name)
	if not self.Members [name] then
		self.Members [name] = GCompute.TypeParameterDefinition (name)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]
end

--- Adds a variable to this namespace
-- @param name The name of the variable
-- @param type The type of the variable
-- @return The new VariableDefinition
function self:AddVariable (name, type)
	if not self.Members [name] then
		self.Members [name] = GCompute.VariableDefinition (name, type)
		self:SetupMemberHierarchy (self.Members [name])
	end
	return self.Members [name]
end

function self:Clear ()
	self.Members = {}
end

function self:GetEnumerator ()
	local next, tbl, key = pairs (self.Members)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function self:GetLazyEnumerator ()
	local next, tbl, key = pairs (self.Members)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

function self:GetMember (member)
	return self.Members [member]
end

function self:GetNamespaceType ()
	return self.NamespaceType
end

function self:IsClassNamespace ()
	return false
end

function self:IsEmpty ()
	return next (self.Members) == nil
end

function self:MemberExists (name)
	return self.Members [name] and true or false
end

function self:ResolveTypes (objectResolver, errorReporter)
	for _, member in self:GetLazyEnumerator () do
		member:ResolveTypes (objectResolver, errorReporter)
	end
end

function self:SetNamespaceType (namespaceType)
	self.NamespaceType = namespaceType
end

function self:SetupMemberHierarchy (memberDefinition)
	memberDefinition:SetGlobalNamespace (self.GlobalNamespace)
	memberDefinition:SetModule (self.Module)
	memberDefinition:SetDeclaringMethod (self.Definition and self.Definition:IsMethod () and self.Definition or self:GetDeclaringMethod ())
	memberDefinition:SetDeclaringNamespace (self.Definition and self.Definition:IsNamespace () and self.Definition or self:GetDeclaringNamespace ())
	memberDefinition:SetDeclaringObject (self.Definition)
	memberDefinition:SetDeclaringType (self.Definition and self.Definition:IsClass () and self.Definition or self:GetDeclaringType ())
end

function self:ToString ()
	if self:IsEmpty () then return "{ }" end
	
	local namespace = "{"
	for name, member in pairs (self.Members) do
		namespace = namespace .. "\n    " .. member:ToString ():gsub ("\n", "\n    ")
	end
	namespace = namespace .. "\n}"
	
	return namespace
end

function self:Visit (namespaceVisitor, ...)
	for _, member in self:GetLazyEnumerator () do
		member:Visit (namespaceVisitor, ...)
	end
end