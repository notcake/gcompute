local self = {}
GCompute.ObjectDefinition = GCompute.MakeConstructor (self, GCompute.IObject)

--- @param name The name of this object
function self:ctor (name)
	-- System
	self.GlobalNamespace      = nil
	
	-- Hierarchy
	self.Name                 = name
	self.Module               = nil
	self.DeclaringMethod      = nil
	self.DeclaringNamespace   = nil
	self.DeclaringObject      = nil
	self.DeclaringType        = nil
	
	-- Children
	self.Namespace            = nil
	self.FileStaticNamespaces = nil
	
	-- Member
	self.MemberVisibility     = GCompute.MemberVisibility.Public
	self.FileStatic           = false
	self.MemberStatic         = false
	self.LocalStatic          = false
	
	-- Attributes
	self.Attributes          = {}
	
	-- Definition
end

-- System
function self:GetGlobalNamespace ()
	return self.GlobalNamespace
end

function self:IsGlobalNamespace ()
	return self:GetGlobalNamespace () == self
end

function self:SetGlobalNamespace (globalNamespace)
	if self.GlobalNamespace == globalNamespace then return self end
	self.GlobalNamespace = globalNamespace
	if self:GetNamespace () then
		self:GetNamespace ():SetGlobalNamespace (globalNamespace)
	end
	for _, namespace in self:GetFileStaticNamespaceEnumerator () do
		namespace:SetGlobalNamespace (globalNamespace)
	end
	return self
end

-- Hierarchy
function self:GetDeclaringMethod ()
	return self.DeclaringMethod
end

--- Gets the NamespaceDefinition or ClassDefinition containing this object
-- @return The NamespaceDefinition or ClassDefinition containing this object
function self:GetDeclaringNamespace ()
	return self.DeclaringNamespace
end

function self:GetDeclaringObject ()
	return self.DeclaringObject
end

function self:GetDeclaringType ()
	return self.DeclaringType
end

--- Gets the fully qualified name of this object
-- @return The fully qualified name of this object
function self:GetFullName ()
	local declaringObject = self:GetDeclaringObject ()
	
	if not declaringObject or declaringObject:IsGlobalNamespace () then
		return self:GetShortName ()
	end
	
	return declaringObject:GetFullName () .. "." .. self:GetShortName ()
end

function self:GetModule ()
	return self.Module
end

--- Gets the name of this object
-- @return The name of this object
function self:GetName ()
	return self.Name
end

function self:GetRelativeName (referenceDefinition)
	local declaringObject = self:GetDeclaringObject ()
	
	if not declaringObject or declaringObject:IsGlobalNamespace () then
		return self:GetRelativeShortName (referenceDefinition)
	end
	
	-- Check referenceDefinition's parents
	local reference = referenceDefinition
	while reference do
		if declaringObject == reference then
			return self:GetRelativeShortName (referenceDefinition)
		end
		reference = reference:GetDeclaringObject ()
	end
	
	return declaringObject:GetRelativeName (referenceDefinition) .. "." .. self:GetRelativeShortName (referenceDefinition)
end

--- Gets the relative short name of this object
-- @return The relative short name of this object
function self:GetRelativeShortName (referenceDefinition)
	return self:GetName () or "[Unnamed]"
end

--- Gets the short name of this object
-- @return The short name of this object
function self:GetShortName ()
	return self:GetName () or "[Unnamed]"
end

function self:SetDeclaringMethod (declaringMethod)
	if self.DeclaringMethod == declaringMethod then return self end
	self.DeclaringMethod = declaringMethod
	if not self:IsMethod () then
		if self:GetNamespace () then
			self:GetNamespace ():SetDeclaringMethod (declaringMethod)
		end
		for _, namespace in self:GetFileStaticNamespaceEnumerator () do
			namespace:SetDeclaringMethod (declaringMethod)
		end
	end
	return self
end

function self:SetDeclaringNamespace (declaringNamespace)
	if self.DeclaringNamespace == declaringNamespace then return self end
	self.DeclaringNamespace = declaringNamespace
	if self:GetNamespace () then
		self:GetNamespace ():SetDeclaringNamespace (declaringNamespace)
	end
	for _, namespace in self:GetFileStaticNamespaceEnumerator () do
		namespace:SetDeclaringNamespace (declaringNamespace)
	end
	return self
end

function self:SetDeclaringObject (declaringObject)
	if self.DeclaringObject == declaringObject then return self end
	self.DeclaringObject = declaringObject
	if self:GetNamespace () then
		self:GetNamespace ():SetDeclaringObject (declaringObject)
	end
	for _, namespace in self:GetFileStaticNamespaceEnumerator () do
		namespace:SetDeclaringObject (declaringObject)
	end
	return self
end

function self:SetDeclaringType (declaringType)
	if self.DeclaringType == declaringType then return self end
	self.DeclaringType = declaringType
	if self:GetNamespace () then
		self:GetNamespace ():SetDeclaringType (declaringType)
	end
	for _, namespace in self:GetFileStaticNamespaceEnumerator () do
		namespace:SetDeclaringType (declaringType)
	end
	return self
end

function self:SetModule (module)
	if self.Module == module then return self end
	self.Module = module
	if self:GetNamespace () then
		self:GetNamespace ():SetModule (module)
	end
	return self
end

-- Children
function self:GetFileStaticNamespace (fileId)
	self.FileStaticNamespaces = self.FileStaticNamespaces or {}
	if not self.FileStaticNamespaces [fileId] then
		local namespace = GCompute.Namespace ()
		self.FileStaticNamespaces [fileId] = namespace
		namespace:SetDefinition (self)
		namespace:SetGlobalNamespace (self:GetGlobalNamespace ())
		namespace:SetDeclaringMethod (self:GetDeclaringMethod ())
		namespace:SetDeclaringNamespace (self:GetDeclaringNamespace ())
		namespace:SetDeclaringObject (self:GetDeclaringObject ())
		namespace:SetDeclaringType (self:GetDeclaringType ())
	end
	return self.FileStaticNamespaces [fileId]
end

function self:GetFileStaticNamespaceEnumerator ()
	if not self.FileStaticNamespaces then return GCompute.NullCallback end
	
	return GLib.KeyValueEnumerator (self.FileStaticNamespaces)
end

function self:GetNamespace ()
	return self.Namespace
end

function self:HasFileStaticNamespace (fileId)
	if not self.FileStaticNamespaces then return false end
	return self.FileStaticNamespaces [fileId] and true or false
end

function self:HasNamespace ()
	return self:GetNamespace () ~= nil
end

-- Member
function self:GetMemberVisibility ()
	return self.MemberVisibility
end

function self:IsPrivate ()
	return self.MemberVisibility == GCompute.MemberVisibility.Private
end

function self:IsProtected ()
	return self.MemberVisibility == GCompute.MemberVisibility.Protected
end

function self:IsPublic ()
	return self.MemberVisibility == GCompute.MemberVisibility.Public
end

--- Gets whether this object is inaccessible from code in other files
-- @return A boolean indicating whether this object is inaccessible from code in other files
function self:IsFileStatic ()
	return self.FileStatic
end

--- Gets whether this local object's state is preserved between function calls
-- @return A boolean indicating whether this object's state is preserved between function calls
function self:IsLocalStatic ()
	return self.LocalStatic
end

--- Gets whether this object is shared between all instances of a type
-- @return A boolean indicating whether this object is shared between all instances of a type
function self:IsMemberStatic ()
	return self.MemberStatic
end

--- Sets whether this object is inaccessible from code in other files
-- @param fileStatic A boolean indicating whether this object is inaccessible from code in other files
function self:SetFileStatic (fileStatic)
	self.FileStatic = fileStatic
	return self
end

--- Sets whether this local object's state is preserve between function calls
-- @param localStatic A boolean indicating whether this object's state is preserved between function calls
function self:SetLocalStatic (localStatic)
	self.LocalStatic = localStatic
	return self
end

--- Sets whether this object is shared between all instances of a type
-- @param memberStatic A boolean indicating whether this object is shared between all instances of a type
function self:SetMemberStatic (memberStatic)
	self.MemberStatic = memberStatic
	return self
end

function self:SetMemberVisibility (memberVisibility)
	self.MemberVisibility = memberVisibility
	return self
end

-- Attributes
function self:AddAttribute (attribute)
	self.Attributes [#self.Attributes + 1] = attribute
end

function self:GetAttribute (index)
	return self.Attributes [index]
end

function self:GetAttributeCount ()
	return #self.Attributes
end

function self:GetAttributeEnumerator ()
	return GLib.ArrayEnumerator (self.Attributes)
end

function self:RemoveAttribute (index)
	table.remove (self.Attributes, index)
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Definitions", self)
	if self:GetNamespace () then
		self:GetNamespace ():CreditTableStructure ("Object Definitions", self)
	end
	
	return memoryUsageReport
end

--- Returns true if this ObjectDefinition has unbound type parameters
-- @return A boolean indicating whether this ObjectDefinition has unbound type parameters
function self:ContainsUnboundTypeParameters ()
	GCompute.Error ("ObjectDefinition:ContainsUnboundTypeParameters : Not implemented (" .. self:GetFullName () .. ")")
end

function self:CreateRuntimeObject ()
	GCompute.Error ("ObjectDefinition:CreateRuntimeObject : Not implemented (" .. self:GetFullName () .. ")")
end

function self:GetCorrespondingDefinition (globalNamespace)
	if not self:GetDeclaringObject () then
		return globalNamespace
	end
	
	local declaringObject = self:GetDeclaringObject ():GetCorrespondingDefinition (globalNamespace)
	if not declaringObject then return nil end
	if not declaringObject:GetNamespace () then return nil end
	
	return declaringObject:GetNamespace ():GetMember (self:GetName ())
end

function self:GetDisplayText ()
	return self:GetName ()
end

function self:GetFullRuntimeName ()
	local declaringObject = self:GetDeclaringObject ()
	
	if not declaringObject or declaringObject:IsGlobalNamespace () then
		return self:GetRuntimeName ()
	end
	
	return declaringObject:GetFullRuntimeName () .. "." .. self:GetRuntimeName ()
end

function self:GetRuntimeName (invalidParameter)
	if invalidParameter then
		GCompute.Error ("MergedNamespaceDefinition:GetRuntimeName : This function does not do what you think it does.")
	end
	
	local declaringObject = self:GetDeclaringObject ()
	if not declaringObject then return self:GetShortName () end
	
	return declaringObject:GetUniqueNameMap ():GetObjectName (self, self:GetShortName ())
end

--- Returns the Type of this object
-- @return A Type representing the type of this object
function self:GetType ()
	GCompute.Error (self.Name .. ":GetType : Not implemented.")
	return nil
end

--- Gets whether this object is a ClassDefinition
-- @return A boolean indicating whether this object is a ClassDefinition
function self:IsClass ()
	return false
end

--- Gets whether this object is a ConstructorDefinition
-- @return A boolean indicating whether this object is a ConstructorDefinition
function self:IsConstructor ()
	return false
end

--- Gets whether this object is an EventDefinition
-- @return A boolean indicating whether this object is a EventDefinition
function self:IsEvent ()
	return false
end

--- Gets whether this object is a MethodDefinition
-- @return A boolean indicating whether this object is a MethodDefinition
function self:IsMethod ()
	return false
end

--- Gets whether this object is a NamespaceDefinition
-- @return A boolean indicating whether this object is a NamespaceDefinition
function self:IsNamespace ()
	return false
end

--- Gets whether this object is an ObjectDefinition
-- @return A boolean indicating whether this object is an ObjectDefinition
function self:IsObjectDefinition ()
	return true
end

--- Gets whether this object is an OverloadedClassDefinition
-- @return A boolean indicating whether this object is an OverloadedClassDefinition
function self:IsOverloadedClass ()
	return false
end

--- Gets whether this object is an OverloadedMethodDefinition
-- @return A boolean indicating whether this object is an OverloadedMethodDefinition
function self:IsOverloadedMethod ()
	return false
end

--- Gets whether this object is a PropertyDefinition
-- @return A boolean indicating whether this object is a PropertyDefinition
function self:IsProperty ()
	return false
end

--- Gets whether this object is a TypeParameterDefinition
-- @return A boolean indicating whether this object is a TypeParameterDefinition
function self:IsTypeParameter ()
	return false
end

--- Gets whether this object is a VariableDefinition
-- @return A boolean indicating whether this object is a VariableDefinition
function self:IsVariable ()
	return false
end

--- Resolves all types
function self:ResolveNames (objectResolver, compilerMessageSink)
	GCompute.AliasResolver (objectResolver, compilerMessageSink):Process (self)
	self:ResolveTypes (objectResolver, compilerMessageSink)
end

function self:ResolveTypes (objectResolver, compilerMessageSink)
	GCompute.Error (self:GetFullName () .. ":ResolveTypes : Not implemented.")
end

--- Returns a string representing this ObjectDefinition
-- @return A string representing this ObjectDefinition
function self:ToString ()
	return self:GetName ()
end

function self:Visit (namespaceVisitor, ...)
	GCompute.Error (self:GetFullName () .. ":Visit : Not implemented.")
end