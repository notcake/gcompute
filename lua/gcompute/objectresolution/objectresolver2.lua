local self = {}
GCompute.ObjectResolver2 = GCompute.MakeConstructor (self)

--[[
	ObjectResolver
	
	Populates ObjectResolutionResults
	
	Identifier:
		<local>
		<member>
		Global Namespace.<member>
		
	NameIndex:
		Namespace.<member>
		Type.<member>
		Variable.<member>
	
	FunctionType:
		Type (Type ...)
]]

function self:ctor ()
	-- Root Namespaces
	self.RootNamespaces = {}
end

-- Root Namespaces
function self:AddRootNamespace (namespaceDefinition)
	self.RootNamespaces [#self.RootNamespaces + 1] = namespaceDefinition
end

function self:GetRootNamespace (index)
	return self.RootNamespaces [index]
end

function self:GetRootNamespaceCount ()
	return #self.RootNamespaces
end

function self:GetRootNamespaceEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.RootNamespaces [i]
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Resolvers", self)
	memoryUsageReport:CreditTableStructure ("Object Resolvers", self.RootNamespaces)
	
	return memoryUsageReport
end

-- AST node resolution
function self:ResolveASTNode (astNode, recursive, localDefinition)
	if astNode:Is ("Identifier") then
		self:ResolveIdentifier (astNode, recursive, localDefinition)
	elseif astNode:Is ("NameIndex") then
		self:ResolveNameIndex (astNode, recursive, localDefinition)
	elseif astNode:Is ("FunctionType") then
		self:ResolveFunctionType (astNode, recursive, localDefinition)
	end
end

function self:ResolveIdentifier (astNode, recursive, localDefinition)
	self:ResolveUnqualifiedIdentifier (astNode:GetResolutionResults (), astNode:GetName (), localDefinition)
end

function self:ResolveNameIndex (astNode, recursive, localDefinition)
	if recursive then
		self:ResolveASTNode (astNode:GetLeftExpression (), recursive, localDefinition)
	end
	
	local leftResults = astNode:GetLeftExpression ():GetResolutionResults ()
	if not leftResults then
		astNode:AddErrorMessage ("NameIndex's left expression has not been resolved! (" .. astNode:ToString () .. ")")
		leftResults = GCompute.ResolutionResults ()
	end
	
	leftResults:FilterByLocality ()
	
	local right = astNode:GetIdentifier ()
	local rightResults = astNode:GetResolutionResults ()
	if not right then
		astNode:AddErrorMessage ("NameIndex is missing an Identifier (" .. astNode:ToString () .. ")")
	elseif right:Is ("Identifier") then
		for i = 1, leftResults:GetFilteredResultCount () do
			local leftDefinition = leftResults:GetFilteredResult (i):GetObject ():UnwrapAlias ()
			if leftDefinition:HasNamespace () then
				self:ResolveMember (rightResults, right:GetName (), leftDefinition)
			end
		end
	else
		astNode:AddErrorMessage ("Unknown AST node on right of NameIndex (" .. right:GetNodeType () .. ")")
	end
end

function self:ResolveFunctionType (astNode, recursive, localDefinition)
	if recursive then
		self:ResolveASTNode (astNode:GetReturnTypeExpression (), recursive, localDefinition)
		for i = 1, astNode:GetParameterList ():GetParameterCount () do
			local parameterType = astNode:GetParameterList ():GetParameterType (i)
			self:ResolveASTNode (parameterType, recursive, localDefinition)
		end
	end
	
	local returnResults = astNode:GetReturnTypeExpression ():GetResolutionResults ()
	returnResults:FilterToConcreteTypes ()
	if returnResults:GetFilteredResultCount () == 0 then
		astNode:GetReturnTypeExpression ():AddErrorMessage ("Cannot resolve " .. astNode:GetReturnTypeExpression ():ToString () .. " - no matching concrete types found.\n" .. returnResults:ToString ())
	elseif returnResults:GetFilteredResultCount () > 1 then
		astNode:GetReturnTypeExpression ():AddErrorMessage ("Cannot resolve " .. astNode:GetReturnTypeExpression ():ToString () .. " - too many matching concrete types found.\n" .. returnResults:ToString ())
	end
	
	for i = 1, astNode:GetParameterList ():GetParameterCount () do
		local parameterType = astNode:GetParameterList ():GetParameterType (i)
		local parameterResults = parameterType:GetResolutionResults ()
		parameterResults:FilterToConcreteTypes ()
		if parameterResults:GetFilteredResultCount () == 0 then
			parameterType:AddErrorMessage ("Cannot resolve " .. parameterType:ToString () .. " - no matching concrete types found.\n" .. parameterResults:ToString ())
		elseif parameterResults:GetFilteredResultCount () > 1 then
			parameterType:AddErrorMessage ("Cannot resolve " .. parameterType:ToString () .. " - too many matching concrete types found.\n" .. parameterResults:ToString ())
		end
	end
end

-- Internal, do not call
--- Looks up the member specified in the given namespace's corresponding namespace set
-- @param resolutionResults The ResolutionResults in which to store results
-- @param name The name of the member to look up
-- @param namespaceDefinition The namespace whose location is used to look up the specified member
function self:ResolveGlobal (resolutionResults, name, namespaceDefinition)
	for rootNamespace in self:GetRootNamespaceEnumerator () do
		local correspondingNamespace = namespaceDefinition:GetCorrespondingDefinition (rootNamespace)
		correspondingNamespace = correspondingNamespace and correspondingNamespace:GetNamespace ()
		local member = correspondingNamespace and correspondingNamespace:GetMember (name)
		if member then
			resolutionResults:AddResult (GCompute.ResolutionResult (member, GCompute.ResolutionResultType.Global))
		end
	end
	
	return resolutionResults
end

function self:ResolveLocal (resolutionResults, name, localDefinition)
	local localDistance = 0
	while localDefinition do
		local member = localDefinition:GetNamespace ():GetMember (name)
		if member then
			resolutionResults:AddResult (
				GCompute.ResolutionResult (
					member,
					GCompute.ResolutionResultType.Local
				):SetLocalDistance (localDistance)
			)
		end
		
		-- Check file static namespaces
		if localDefinition:HasFileStaticNamespace (fileId) then
			member = localDefinition:GetFileStaticNamespace (fileId):GetMember (name)
			if member then
				resolutionResults:AddResult (
					GCompute.ResolutionResult (
						member,
						GCompute.ResolutionResultType.Local
					):SetLocalDistance (localDistance)
				)
			end
		end
		
		localDefinition = localDefinition:GetDeclaringObject ()
		localDistance = localDistance + 1
	end
	
	return resolutionResults
end

function self:ResolveMember (resolutionResults, name, objectDefinition)
	if objectDefinition:GetNamespace ():MemberExists (name) then
		resolutionResults:AddResult (GCompute.ResolutionResult (objectDefinition:GetNamespace ():GetMember (name), GCompute.ResolutionResultType.Other))
	end
end

function self:ResolveUnqualifiedIdentifier (resolutionResults, name, localDefinition)
	self:ResolveLocal  (resolutionResults, name, localDefinition)
	
	-- Check usings
	local usingSource = localDefinition
	while usingSource do
		if usingSource:IsNamespace () or usingSource:IsClass () then
			for i = 1, usingSource:GetUsingCount () do
				local targetDefinition = usingSource:GetUsing (i):GetNamespace ()
				if targetDefinition then
					self:ResolveGlobal (resolutionResults, name, targetDefinition)
				end
			end
		end
	
		usingSource = usingSource:GetDeclaringObject ()
	end
	
	-- Check root
	self:ResolveGlobal (resolutionResults, name, self.RootNamespaces [1])
end