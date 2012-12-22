local self = {}
GCompute.MirrorNamespaceDefinition = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition)

--- @param name The name of this namespace
function self:ctor (name)
	self.Namespace = GCompute.MirrorNamespace ()
	self.Namespace:SetDefinition (self)
	-- Namespace hierarchy data will get set later automatically
	
	self.SourceNamespaces = {}
end

-- Mirror Namespace
--- Adds a source namespace from which members will be obtained
-- @param namespaceDefinition Source namespace definition from which members will be obtained
function self:AddSourceNamespace (namespaceDefinition)
	self.SourceNamespaces [#self.SourceNamespaces + 1] = namespaceDefinition
	self.Namespace:AddSourceNamespace (namespaceDefinition:GetNamespace ())
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self.SourceNamespaces)
	self.Namespace:ComputeMemoryUsage (memoryUsageReport)
	
	if self.MergedLocalScope then
		self.MergedLocalScope:ComputeMemoryUsage (memoryUsageReport)
	end
	if self.UniqueNameMap then
		self.UniqueNameMap:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

--- Creates a runtime namespace
-- @return A runtime namespace
function self:CreateRuntimeObject ()
	local uniqueNameMap = self:GetUniqueNameMap ()
	local runtimeNamespace = {}
	for _, memberDefinition in self:GetNamespace ():GetEnumerator () do
		if memberDefinition:IsOverloadedMethod () then
			for method in memberDefinition:GetEnumerator () do
				local runtimeName = uniqueNameMap:GetObjectName (method)
				print ("Global: " .. method:GetFullName () .. ", as " .. (self:IsGlobalNamespace () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
				runtimeNamespace [runtimeName] = method:CreateRuntimeObject ()
			end
		elseif memberDefinition:IsOverloadedClass () then
			for class in memberDefinition:GetEnumerator () do
				local runtimeName = uniqueNameMap:GetObjectName (class)
				print ("Global: " .. class:GetFullName () .. ", as " .. (self:IsGlobalNamespace () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
				runtimeNamespace [runtimeName] = class:CreateRuntimeObject ()
			end
		else
			local runtimeName = uniqueNameMap:GetObjectName (memberDefinition)
			print ("Global: " .. memberDefinition:GetFullName () .. ", as " .. (self:IsGlobalNamespace () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
			
			runtimeNamespace [runtimeName] = memberDefinition:CreateRuntimeObject ()
		end
	end
	
	for _, sourceNamespace in ipairs (self.SourceNamespaces) do
		for _, memberDefinition in sourceNamespace:GetNamespace ():GetEnumerator () do
			if memberDefinition:IsFileStatic () then
				local runtimeName = uniqueNameMap:GetObjectName (memberDefinition)
				print ("Static: " .. memberDefinition:GetFullName () .. ", as " .. runtimeName)
				runtimeNamespace [runtimeName] = memberDefinition:CreateRuntimeObject ()
			end
		end
	end
	
	print ("Created runtime object for " .. self:GetFullName () .. ".")
	return runtimeNamespace
end

function self:CreateStaticMemberAccessNode ()
	if self:IsGlobalNamespace () then return nil end
	return GCompute.AST.StaticMemberAccess (self:GetDeclaringObject ():CreateStaticMemberAccessNode (), self:GetName ())
end

--- Returns a function which handles runtime namespace initialization
-- @return A function which handles runtime namespace initialization
function self:GetConstructor (name)
	return function ()
		for _, namespaceDefinition in ipairs (self.SourceNamespaces) do
			namespaceDefinition:GetConstructor () ()
		end
	end
end

function self:GetMemberRuntimeName (memberDefinition)
	if not self.UniqueNameMap then return memberDefinition:GetName () end
	return self.UniqueNameMap:GetObjectName (memberDefinition)
end

function self:GetType ()
	return GCompute.TypeSystem:GetObject ()
end

function self:GetUniqueNameMap ()
	self.UniqueNameMap = self.UniqueNameMap or GCompute.UniqueNameMap ()
	return self.UniqueNameMap
end

--- Resolves the types in this namespace
function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	self:GetNamespace ():ResolveTypes (globalNamespace, errorReporter)
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespace = self:GetNamespace ()
	local namespaceDefinition = "[Mirror Namespace (" .. GCompute.NamespaceType [namespace:GetNamespaceType ()] .. ")] " .. (self:GetName () or "[Unnamed]")
	
	if namespace:IsEmpty () then
		namespaceDefinition = namespaceDefinition .. " { }"
	else
		namespaceDefinition = namespaceDefinition .. "\n{\n"
		for _, memberDefinition in namespace:GetEnumerator () do
			namespaceDefinition = namespaceDefinition .. "    " .. memberDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		namespaceDefinition = namespaceDefinition .. "}"
	end
	
	return namespaceDefinition
end