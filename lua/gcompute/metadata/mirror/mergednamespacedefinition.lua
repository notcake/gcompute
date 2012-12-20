local self = {}
GCompute.MergedNamespaceDefinition = GCompute.MakeConstructor (self, GCompute.INamespace)

--- @param name The name of this namespace
function self:ctor (name)
	self.NamespaceType = GCompute.NamespaceType.Unknown
	
	self.SourceNamespaces = {}
	
	self.Members = {}
	self.Statics = {}
	
	self.UniqueNameMap = nil
end

--- Adds a source namespace from which members will be obtained
-- @param namespaceDefinition Source namespace definition from which members will be obtained
function self:AddSourceNamespace (namespaceDefinition)
	self.SourceNamespaces [#self.SourceNamespaces + 1] = namespaceDefinition
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Namespace Definitions", self)
	return memoryUsageReport
end

--- Creates a runtime namespace
-- @return A runtime namespace
function self:CreateRuntimeObject ()
	local uniqueNameMap = self:GetUniqueNameMap ()
	local runtimeNamespace = {}
	for name, memberDefinition in pairs (self.Members) do
		if memberDefinition:IsOverloadedFunctionDefinition () then
			for functionDefinition in memberDefinition:GetEnumerator () do
				local runtimeName = uniqueNameMap:GetObjectName (functionDefinition)
				print ("Global: " .. functionDefinition:GetFullName () .. ", as " .. (self:IsGlobalNamespace () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
				runtimeNamespace [runtimeName] = functionDefinition:CreateRuntimeObject ()
			end
		elseif memberDefinition:IsOverloadedClass () then
			for typeDefinition in memberDefinition:GetEnumerator () do
				local runtimeName = uniqueNameMap:GetObjectName (typeDefinition)
				print ("Global: " .. typeDefinition:GetFullName () .. ", as " .. (self:IsGlobalNamespace () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
				runtimeNamespace [runtimeName] = typeDefinition:CreateRuntimeObject ()
			end
		else
			local runtimeName = uniqueNameMap:GetObjectName (memberDefinition)
			print ("Global: " .. memberDefinition:GetFullName () .. ", as " .. (self:IsGlobalNamespace () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
			
			runtimeNamespace [runtimeName] = memberDefinition:CreateRuntimeObject ()
		end
	end
	
	for _, sourceNamespace in ipairs (self.SourceNamespaces) do
		for name, memberDefinition in sourceNamespace:GetEnumerator () do
			if memberDefinition:IsFileStatic () then
				local runtimeName = uniqueNameMap:GetObjectName (memberDefinition)
				print ("Static: " .. name .. ", as " .. runtimeName)
				runtimeNamespace [runtimeName] = memberDefinition:CreateRuntimeObject ()
			end
		end
	end
	
	print ("Created runtime object for " .. self:GetFullName () .. ".")
	return runtimeNamespace
end

function self:CreateStaticMemberAccessNode ()
	if self:IsGlobalNamespace () then return nil end
	return GCompute.AST.StaticMemberAccess (self:GetDeclaringNamespace ():CreateStaticMemberAccessNode (), self:GetName ())
end

--- Returns a function which handles runtime namespace initialization
-- @return A function which handles runtime namespace initialization
function self:GetConstructor (name)
	return function (executionContext)
		local callbackChain = GCompute.CallbackChain ()
		for _, namespaceDefinition in ipairs (self.SourceNamespaces) do
			callbackChain:Then (
				function (callback, errorCallback)
					namespaceDefinition:GetConstructor () (executionContext)
					callback ()
				end
			)
		end
		callbackChain:Execute ()
	end
end

function self:GetEnumerator ()
	local next, tbl, key = pairs (self.Members)
	return function ()
		key = next (tbl, key)
		return key, tbl [key]
	end
end

--- Returns the definition object of a member object
-- @param name The name of the member object
-- @return The definition object for the given member object
function self:GetMember (name)
	self:ResolveMember (name)
	return self.Members [name]
end

function self:GetMemberRuntimeName (memberDefinition)
	if not self.UniqueNameMap then return memberDefinition:GetName () end
	return self.UniqueNameMap:GetObjectName (memberDefinition)
end

function self:GetNamespaceType ()
	return self.NamespaceType
end

function self:GetType ()
	return self:GetTypeSystem ():GetObject ()
end

function self:GetUniqueNameMap ()
	if not self.UniqueNameMap then
		self.UniqueNameMap = GCompute.UniqueNameMap ()
	end
	return self.UniqueNameMap
end

function self:IsGlobalNamespace ()
	return self:GetDeclaringNamespace () == nil
end

--- Returns whether a member with the given name exists
-- @param name The name of the member whose existance is being checked
-- @return A boolean indicating whether a member with the given name exists
function self:MemberExists (name)
	self:ResolveMember (name)
	return self.Members [name] and true or false
end

--- Looks up a member with the given name in all of the source namespaces and adds it to this MergedNamespaceDefinition's list of members
-- @param name The name of the member to be looked up
function self:ResolveMember (name)
	if self.Members [name] then return end

	local matchNamespaces = {}
	local matchObjects = {}
	for _, namespaceDefinition in pairs (self.SourceNamespaces) do
		if namespaceDefinition:MemberExists (name) and
			not namespaceDefinition:GetMember (name):IsFileStatic () then
			matchNamespaces [#matchNamespaces + 1] = namespaceDefinition
			matchObjects [#matchObjects + 1] = namespaceDefinition:GetMember (name)
		end
	end
	
	if #matchObjects == 0 then return end
	
	-- assume that they are all the same type
	if matchObjects [1]:IsVariable () then
		self.Members [name] = matchObjects [1]
	elseif matchObjects [1]:IsOverloadedFunctionDefinition () then
		self.Members [name] = GCompute.MergedOverloadedFunctionDefinition (name)
		self.Members [name]:SetDeclaringNamespace (self)
		for _, overloadedFunctionDefinition in ipairs (matchObjects) do
			self.Members [name]:AddSourceOverloadedFunction (overloadedFunctionDefinition)
		end
	elseif matchObjects [1]:IsOverloadedClass () then
		self.Members [name] = GCompute.MergedOverloadedClassDefinition (name)
		self.Members [name]:SetDeclaringNamespace (self)
		for _, overloadedClassDefinition in ipairs (matchObjects) do
			self.Members [name]:AddSourceOverloadedType (overloadedClassDefinition)
		end
	elseif matchObjects [1]:IsNamespace () then
		self.Members [name] = GCompute.MergedNamespaceDefinition (name)
		self.Members [name]:SetDeclaringNamespace (self)
		self.Members [name]:SetNamespaceType (matchObjects [1]:GetNamespaceType ())
		for _, namespaceDefinition in ipairs (matchObjects) do
			self.Members [name]:AddSourceNamespace (namespaceDefinition)
		end
	elseif matchObjects [1]:IsAlias () then
		self.Members [name] = matchObjects [1]
	else
		ErrorNoHalt ("GCompute.MergedNamespaceDefinition:ResolveMember : Unhandled member type on " .. matchObjects [1]:GetFullName () .. ".\n")
	end
end

function self:SetNamespaceType (namespaceType)
	self.NamespaceType = namespaceType
end

--- Returns a string representation of this namespace
-- @return A string representing this namespace
function self:ToString ()
	local namespaceDefinition = "[Merged Namespace (" .. GCompute.NamespaceType [self.NamespaceType] .. ")] " .. (self:GetName () or "[Unnamed]")
	
	if next (self.Members) then
		namespaceDefinition = namespaceDefinition .. "\n{\n"
		for name, memberDefinition in pairs (self.Members) do
			namespaceDefinition = namespaceDefinition .. "    " .. memberDefinition:ToString ():gsub ("\n", "\n    ") .. "\n"
		end
		namespaceDefinition = namespaceDefinition .. "}"
	end
	
	return namespaceDefinition
end