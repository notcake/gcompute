local self = {}
GCompute.ObjectResolver = GCompute.MakeConstructor (self)

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

function self:ctor (rootNamespaceSet)
	-- Root Namespaces
	self.RootNamespaceSet = rootNamespaceSet
end

-- Root Namespaces
function self:GetRootNamespaceSet ()
	return self.RootNamespaceSet
end

function self:SetRootNamespaceSet (rootNamespaceSet)
	self.RootNamespaceSet = rootNamespaceSet
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Resolvers", self)
	memoryUsageReport:CreditTableStructure ("Object Resolvers", self.RootNamespaces)
	
	return memoryUsageReport
end

-- AST node resolution
function self:ResolveASTNode (astNode, recursive, localDefinition, fileId)
	if astNode:Is ("Identifier") then
		self:ResolveIdentifier (astNode, recursive, localDefinition, fileId)
	elseif astNode:Is ("NameIndex") then
		self:ResolveNameIndex (astNode, recursive, localDefinition, fileId)
	elseif astNode:Is ("FunctionType") then
		self:ResolveFunctionType (astNode, recursive, localDefinition, fileId)
	elseif astNode:Is ("TypeArgumentList") then
		self:ResolveTypeArgumentList (astNode, recursive, localDefinition, fileId)
	end
end

function self:ResolveIdentifier (astNode, recursive, localDefinition, fileId)
	self:ResolveUnqualifiedIdentifier (astNode:GetResolutionResults (), astNode, localDefinition, fileId)
end

function self:ResolveNameIndex (astNode, recursive, localDefinition, fileId)
	if recursive then
		self:ResolveASTNode (astNode:GetLeftExpression (), recursive, localDefinition, fileId)
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
				self:ResolveMember (rightResults, right:GetName (), leftDefinition, fileId)
			end
		end
	else
		astNode:AddErrorMessage ("Unknown AST node on right of NameIndex (" .. right:GetNodeType () .. ")")
	end
end

function self:ResolveFunctionType (astNode, recursive, localDefinition, fileId)
	if recursive then
		self:ResolveASTNode (astNode:GetReturnTypeExpression (), recursive, localDefinition, fileId)
		for i = 1, astNode:GetParameterList ():GetParameterCount () do
			local parameterType = astNode:GetParameterList ():GetParameterType (i)
			self:ResolveASTNode (parameterType, recursive, localDefinition, fileId)
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

function self:ResolveTypeArgumentList (astNode, recursive, localDefinition, fileId)
	for argument in astNode:GetEnumerator () do
		self:ResolveASTNode (argument, recursive, localDefinition, fileId)
		
		local resolutionResults = argument:GetResolutionResults ()
		if resolutionResults then
			resolutionResults:FilterToConcreteTypes ()
			resolutionResults:FilterByLocality ()
		end
	end
end

-- Internal, do not call
--- Looks up the member specified in the given namespace's corresponding namespace set
-- @param resolutionResults The ResolutionResults in which to store results
-- @param name The name of the member to look up
-- @param referenceDefinition The namespace whose location is used to look up the specified member (nil means the root namespace)
function self:ResolveGlobal (resolutionResults, name, typeArgumentList, referenceDefinition, fileId)
	local typeArgumentCount = typeArgumentList and typeArgumentList:GetArgumentCount () or 0
	for translatedNamespace in self.RootNamespaceSet:GetTranslatedEnumerator (referenceDefinition) do
		local member = translatedNamespace and translatedNamespace:GetMember (name)
		if member then
			if typeArgumentList then
				if member:IsOverloadedClass () or member:IsClass () or
				   member:IsOverloadedMethod () or member:IsMethod () then
					for definition in member:GetGroupEnumerator () do
						if definition:GetTypeParameterList ():MatchesArgumentCount (typeArgumentCount) then
							resolutionResults:AddResult (GCompute.ResolutionResult (definition:CreateTypeCurriedDefinition (typeArgumentList), GCompute.ResolutionResultType.Global))
						end
					end
				end
			else
				resolutionResults:AddResult (GCompute.ResolutionResult (member, GCompute.ResolutionResultType.Global))
			end
		end
	end
	
	return resolutionResults
end

function self:ResolveLocal (resolutionResults, name, localDefinition, fileId)
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

function self:ResolveMember (resolutionResults, name, objectDefinition, fileId)
	if objectDefinition:GetNamespace ():MemberExists (name) then
		resolutionResults:AddResult (GCompute.ResolutionResult (objectDefinition:GetNamespace ():GetMember (name), GCompute.ResolutionResultType.Other))
	end
end

function self:ResolveUnqualifiedIdentifier (resolutionResults, identifier, localDefinition, fileId)
	self:ResolveLocal  (resolutionResults, identifier:GetName (), localDefinition, fileId)
	
	local name = identifier:GetName ()
	local typeArgumentList = identifier:GetTypeArgumentList ()
	if typeArgumentList then
		self:ResolveASTNode (typeArgumentList, true, localDefinition, fileId)
		typeArgumentList = typeArgumentList:ToTypeArgumentList ()
	end
	
	-- Check usings
	local usingSource = localDefinition
	while usingSource do
		if usingSource:IsNamespace () or usingSource:IsClass () then
			for i = 1, usingSource:GetUsingCount () do
				local targetDefinition = usingSource:GetUsing (i):GetNamespace ()
				if targetDefinition then
					self:ResolveGlobal (resolutionResults, name, typeArgumentList, targetDefinition, fileId)
				end
			end
		end
	
		usingSource = usingSource:GetDeclaringObject ()
	end
	
	-- Check root
	self:ResolveGlobal (resolutionResults, name, typeArgumentList, nil, fileId)
end