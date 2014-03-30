local self = {}
GCompute.ClassNamespace = GCompute.MakeConstructor (self, GCompute.Namespace)

function self:ctor ()
	self.Constructors  = {}
	self.ImplicitCasts = {}
	self.ExplicitCasts = {}
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self.Members)
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self.Constructors)
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self.ExplicitCasts)
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self.ImplicitCasts)
	for _, member in self:GetEnumerator () do
		member:ComputeMemoryUsage (memoryUsageReport)
	end
	for constructor in self:GetConstructorEnumerator () do
		constructor:ComputeMemoryUsage (memoryUsageReport)
	end
	for implicitCast in self:GetImplicitCastEnumerator () do
		implicitCast:ComputeMemoryUsage (memoryUsageReport)
	end
	for explicitCast in self:GetExplicitCastEnumerator () do
		explicitCast:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

-- Class Namespace
function self:AddConstructor (parameterList)
	local constructorDefinition = GCompute.ConstructorDefinition (self.Definition and self.Definition:GetName () or "<anonymous>", parameterList)
	self:SetupMemberHierarchy (constructorDefinition)
	constructorDefinition:SetReturnType (self.Definition:GetClassType ())
	constructorDefinition:SetMemberStatic (true)
	
	self.Constructors [#self.Constructors + 1] = constructorDefinition
	
	return constructorDefinition
end

--- Adds an explicit type cast operator to this class namespace
-- @param destinationType The destination type, as a string, DeferredObjectResolution or Type
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddExplicitCast (destinationType, nativeFunction)
	local explicitCast = GCompute.ExplicitCastDefinition ("explicit operator")
	self:SetupMemberHierarchy (explicitCast)
	explicitCast:SetReturnType (destinationType)
	explicitCast:SetNativeFunction (nativeFunction)
	
	self.ExplicitCasts [#self.ExplicitCasts + 1] = explicitCast
	
	return explicitCast
end

--- Adds an implicit type cast operator to this class namespace
-- @param destinationType The destination type, as a string, DeferredObjectResolution or Type
-- @param nativeFunction (Optional) A function that performs the cast
function self:AddImplicitCast (destinationType, nativeFunction)
	local implicitCast = GCompute.ImplicitCastDefinition ("implicit operator")
	self:SetupMemberHierarchy (implicitCast)
	implicitCast:SetReturnType (destinationType)
	implicitCast:SetNativeFunction (nativeFunction)
	
	self.ImplicitCasts [#self.ImplicitCasts + 1] = implicitCast
	
	return implicitCast
end

function self:GetConstructor (index)
	return self.Constructors [index]
end

function self:GetConstructorCount ()
	return #self.Constructors
end

function self:GetConstructorEnumerator ()
	return GLib.ArrayEnumerator (self.Constructors)
end

function self:GetExplicitCast (index)
	return self.ExplicitCasts [index]
end

function self:GetExplicitCastCount ()
	return #self.ExplicitCasts
end

function self:GetExplicitCastEnumerator ()
	return GLib.ArrayEnumerator (self.ExplicitCasts)
end

function self:GetImplicitCast (index)
	return self.ImplicitCasts [index]
end

function self:GetImplicitCastCount ()
	return #self.ImplicitCasts
end

function self:GetImplicitCastEnumerator ()
	return GLib.ArrayEnumerator (self.ImplicitCasts)
end

function self:IsClassNamespace ()
	return true
end

--- Returns whether this namespace has no members
-- @return A boolean indicating whether this namespace has no members
function self:IsEmpty ()
	return #self.Constructors == 0 and next (self.Members) == nil and #self.ImplicitCasts == 0 and #self.ExplicitCasts == 0
end

function self:ResolveTypes (objectResolver, errorReporter)
	-- Resolve constructor types
	for constructor in self:GetConstructorEnumerator () do
		constructor:ResolveTypes (objectResolver, errorReporter)
	end
	
	-- Resolve members
	for _, member in self:GetEnumerator () do
		member:ResolveTypes (objectResolver, errorReporter)
	end
	
	-- Resolve implicit cast destination types
	for implicitCast in self:GetImplicitCastEnumerator () do
		implicitCast:ResolveTypes (objectResolver, errorReporter)
	end
	
	-- Resolve explicit cast destination types
	for explicitCast in self:GetExplicitCastEnumerator () do
		explicitCast:ResolveTypes (objectResolver, errorReporter)
	end
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
	for constructor in self:GetConstructorEnumerator () do
		constructor:Visit (namespaceVisitor, ...)
	end
	for _, member in self:GetEnumerator () do
		member:Visit (namespaceVisitor, ...)
	end
	for implicitCast in self:GetImplicitCastEnumerator () do
		implicitCast:Visit (namespaceVisitor, ...)
	end
	for explicitCast in self:GetExplicitCastEnumerator () do
		explicitCast:Visit (namespaceVisitor, ...)
	end
end