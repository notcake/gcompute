local self = {}
GCompute.NamespaceDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param name The name of this namespace
function self:ctor (name)
	self.Usings = {}
	
	self.Namespace = GCompute.Namespace ()
	self.Namespace:SetDefinition (self)
	-- Namespace hierarchy data will get set later automatically
	
	self.Constructors     = {}
	
	self.UniqueNameMap    = nil
	self.MergedLocalScope = nil
end

-- Namespace
local forwardedFunctions =
{
	"AddAlias",
	"AddClass",
	"AddEvent",
	"AddMethod",
	"AddNamespace",
	"AddProperty",
	"AddTypeParameter",
	"AddVariable",
	"GetEnumerator",
	"GetMember",
	"GetNamespaceType",
	"IsEmpty",
	"MemberExists",
	"SetNamespaceType"
}

for _, functionName in ipairs (forwardedFunctions) do
	self [functionName] = function (self, ...)
		local namespace = self:GetNamespace ()
		return namespace [functionName] (namespace, ...)
	end
end

--- Adds a runtime initialization function for this namespace
-- @param constructor A runtime initialization function for this namespace
function self:AddConstructor (constructor)
	local constructor = GCompute.MethodDefinition ()
	constructor:SetNativeFunction (constructor)
	
	self.Constructors [#self.Constructors + 1] = constructor
end

--- Adds a runtime initialization function AST for this namespace
-- @param constructorAST A runtime initialization function AST for this namespace
function self:AddConstructorAST (blockStatement)
	local constructor = GCompute.MethodDefinition ()
	constructor:SetBlockStatement (blockStatement)
	
	self.Constructors [#self.Constructors + 1] = constructor
end

--- Adds a using directive to this namespace definition
-- @param qualifiedName The name of the namespace to be used
function self:AddUsing (qualifiedName)
	local usingDirective = GCompute.UsingDirective (qualifiedName)
	self.Usings [#self.Usings + 1] = usingDirective
	return usingDirective
end

function self:Clear ()
	self.Namespace:Clear ()
	
	if self.UniqueNameMap then
		self.UniqueNameMap:Clear ()
	end
	
	if self.MergedLocalScope then
		self.MergedLocalScope:Clear ()
	end
end

function self:CreateStaticMemberAccessNode ()
	if self:IsGlobalNamespace () then return nil end
	if not self:GetDeclaringObject () then return nil end
	return GCompute.AST.StaticMemberAccess (self:GetDeclaringObject ():CreateStaticMemberAccessNode (), self:GetName ())
end

--- Returns a function which handles runtime namespace initialization
-- @return A function which handles runtime namespace initialization
function self:GetConstructor ()
	return function ()
		for _, method in ipairs (self.Constructors) do
			local nativeFunction = method:GetNativeFunction ()
			if not nativeFunction then
				nativeFunction = function ()
					executionContext:GetStdOut ():WriteLine ("Warning: Static constructor for " .. self:GetFullName () .. " has not been native-compiled!")
					local astRunner = GCompute.ASTRunner ()
					astRunner:PushNode (method:GetBlockStatement ())
					astRunner:PushState (0)
					astRunner:SetYieldEnabled (false)
					astRunner:Execute ()
				end
			end
			nativeFunction ()
		end
	end
end

function self:GetMemberRuntimeName (memberDefinition)
	if not self.UniqueNameMap then return memberDefinition:GetName () end
	return self.UniqueNameMap:GetObjectName (memberDefinition)
end

function self:GetMergedLocalScope ()
	return self.MergedLocalScope
end

function self:GetUniqueNameMap ()
	self.UniqueNameMap = self.UniqueNameMap or GCompute.UniqueNameMap ()
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

function self:ResolveUsings (globalNamespace)
	for i = 1, self:GetUsingCount () do
		self:GetUsing (i):Resolve (globalNamespace)
	end
end

function self:SetMergedLocalScope (mergedLocalScope)
	self.MergedLocalScope = mergedLocalScope
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	self.Namespace:ComputeMemoryUsage (memoryUsageReport)
	
	if self.MergedLocalScope then
		self.MergedLocalScope:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.UniqueNameMap then
		self.UniqueNameMap:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:GetType ()
	return GCompute.TypeSystem:GetObject ()
end

function self:IsNamespace ()
	return true
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	self:GetNamespace ():ResolveTypes (globalNamespace, errorReporter)
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Namespace (" .. GCompute.NamespaceType [self:GetNamespace ():GetNamespaceType ()] .. ")] " .. (self:GetName () or "[Unnamed]")
	
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
		
		if not self:GetNamespace ():IsEmpty () then
			if newlineRequired then namespaceDefinition = namespaceDefinition .. "\n    " end
			newlineRequired = true
		end
		for _, memberDefinition in self:GetNamespace ():GetEnumerator () do
			namespaceDefinition = namespaceDefinition .. "\n    " .. memberDefinition:ToString ():gsub ("\n", "\n    ")
		end
		namespaceDefinition = namespaceDefinition .. "\n}"
	else
		namespaceDefinition = namespaceDefinition .. " { }"
	end
	
	return namespaceDefinition
end