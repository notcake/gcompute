local self = {}
GCompute.MergedNamespaceDefinition = GCompute.MakeConstructor (self, GCompute.INamespace)

--- @param name The name of this namespace
function self:ctor (name)
	self.NamespaceType = GCompute.NamespaceType.Unknown
	
	self.SourceNamespaces = {}
	
	self.Members = {}
	self.MemberMetadata = {}
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

--- Creates a runtime namespace with its metadata stripped out
-- @return A runtime namespace without metadata
function self:CreateRuntimeObject ()
	local uniqueNameMap = self:GetUniqueNameMap ()
	local runtimeNamespace = {}
	for name, memberDefinition in pairs (self.Members) do
		if memberDefinition:IsOverloadedFunctionDefinition () then
			for functionDefinition in memberDefinition:GetEnumerator () do
				local runtimeName = uniqueNameMap:GetObjectName (functionDefinition)
				print ("Global: " .. functionDefinition:GetFullName () .. ", as " .. (self:IsRoot () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
				runtimeNamespace [runtimeName] = functionDefinition:CreateRuntimeObject ()
			end
		elseif memberDefinition:IsOverloadedTypeDefinition () then
			for typeDefinition in memberDefinition:GetEnumerator () do
				local runtimeName = uniqueNameMap:GetObjectName (typeDefinition)
				print ("Global: " .. typeDefinition:GetFullName () .. ", as " .. (self:IsRoot () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
				runtimeNamespace [runtimeName] = typeDefinition:CreateRuntimeObject ()
			end
		else
			local runtimeName = uniqueNameMap:GetObjectName (memberDefinition)
			print ("Global: " .. memberDefinition:GetFullName () .. ", as " .. (self:IsRoot () and "" or self:GetFullRuntimeName () .. ".") .. runtimeName)
			
			runtimeNamespace [runtimeName] = memberDefinition:CreateRuntimeObject ()
		end
	end
	
	for _, sourceNamespace in ipairs (self.SourceNamespaces) do
		for name, memberDefinition, metadata in sourceNamespace:GetEnumerator () do
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
		return key, tbl [key], self.MemberMetadata [key]
	end
end

function self:GetFullRuntimeName ()
	local containingNamespace = self:GetContainingNamespace ()
	if not containingNamespace then return self:GetRuntimeName () end
	
	if containingNamespace:GetContainingNamespace () then
		return containingNamespace:GetFullRuntimeName () .. "." .. self:GetRuntimeName ()
	end
	
	return self:GetRuntimeName ()
end

--- Returns the definition object of a member object
-- @param name The name of the member object
-- @return The definition object for the given member object
function self:GetMember (name)
	self:ResolveMember (name)
	return self.Members [name]
end

--- Returns the metadata of a member object
-- @param name The name of the member object
-- @return The MemberInfo object for the given member object
function self:GetMemberMetadata (name)
	self:ResolveMember (name)
	return self.MemberMetadata [name]
end

function self:GetMemberRuntimeName (memberDefinition)
	if not self.UniqueNameMap then return memberDefinition:GetName () end
	return self.UniqueNameMap:GetObjectName (memberDefinition)
end

function self:GetNamespaceType ()
	return self.NamespaceType
end

function self:GetRuntimeName (invalidParameter)
	if invalidParameter then
		GCompute.Error ("MergedNamespaceDefinition:GetRuntimeName : This function does not do what you think it does.")
	end
	
	local containingNamespace = self:GetContainingNamespace ()
	if not containingNamespace then return self:GetShortName () end
	
	return containingNamespace:GetUniqueNameMap ():GetObjectName (self)
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

function self:IsRoot ()
	return self:GetContainingNamespace () == nil
end

--- Returns whether a member with the given name exists
-- @param name The name of the member whose existance is being checked
-- @return A boolean indicating whether a member with the given name exists
function self:MemberExists (name)
	self:ResolveMember (name)
	return self.MemberMetadata [name] and true or false
end

--- Looks up a member with the given name in all of the source namespaces and adds it to this MergedNamespaceDefinition's list of members
-- @param name The name of the member to be looked up
function self:ResolveMember (name)
	if self.MemberMetadata [name] then return end

	local matchNamespaces = {}
	local matchObjects = {}
	local matchMetadata = {}
	for _, namespaceDefinition in pairs (self.SourceNamespaces) do
		if namespaceDefinition:MemberExists (name) and
			not namespaceDefinition:GetMember (name):IsFileStatic () then
			matchNamespaces [#matchNamespaces + 1] = namespaceDefinition
			matchObjects [#matchObjects + 1] = namespaceDefinition:GetMember (name)
			matchMetadata [#matchMetadata + 1] = namespaceDefinition:GetMemberMetadata (name)
		end
	end
	
	if #matchObjects == 0 then return end
	
	-- assume that they are all the same type
	local memberType = matchMetadata [1]:GetMemberType ()
	self.MemberMetadata [name] = matchMetadata [1]
	if memberType == GCompute.MemberTypes.Field then
		self.Members [name] = matchObjects [1]
	elseif memberType == GCompute.MemberTypes.Method then
		self.Members [name] = GCompute.MergedOverloadedFunctionDefinition (name)
		for _, overloadedFunctionDefinition in ipairs (matchObjects) do
			self.Members [name]:AddSourceOverloadedFunction (overloadedFunctionDefinition)
		end
	elseif memberType == GCompute.MemberTypes.Type then
		self.Members [name] = GCompute.MergedOverloadedTypeDefinition (name)
		for _, overloadedTypeDefinition in ipairs (matchObjects) do
			self.Members [name]:AddSourceOverloadedType (overloadedTypeDefinition)
		end
	elseif memberType == GCompute.MemberTypes.Namespace then
		self.Members [name] = GCompute.MergedNamespaceDefinition (name)
		self.Members [name]:SetNamespaceType (matchObjects [1]:GetNamespaceType ())
		for _, namespaceDefinition in ipairs (matchObjects) do
			self.Members [name]:AddSourceNamespace (namespaceDefinition)
		end
	elseif memberType == GCompute.MemberTypes.Alias then
		self.Members [name] = matchObjects [1]
	else
		ErrorNoHalt ("GCompute.MergedNamespaceDefinition:ResolveMember : Unhandled member type " .. tostring (memberType) .. " (" .. tostring (GCompute.MemberTypes [memberType]) .. ") on " .. tostring (name) .. ".\n")
	end
	
	if self.Members [name] then
		self.Members [name]:SetContainingNamespace (self)
		self.Members [name]:SetMetadata (self.MemberMetadata [name])
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