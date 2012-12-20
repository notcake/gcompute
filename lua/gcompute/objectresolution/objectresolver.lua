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

function self:ctor ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Resolvers", self)
	return memoryUsageReport
end

function self:ResolveGlobal (resolutionResults, name, globalDefinition, usingDefinition)
	local currentUsingSource = usingDefinition
	while currentUsingSource do
		if currentUsingSource:IsNamespace () or currentUsingSource:IsClass () then
			for i = 1, currentUsingSource:GetUsingCount () do
				local usingDirective = currentUsingSource:GetUsing (i)
				local usingNamespace = usingDirective:GetNamespace () and usingDirective:GetNamespace ():GetNamespace ()
				if usingNamespace:MemberExists (name) then
					resolutionResults:AddResult (GCompute.ResolutionResult (usingNamespace:GetMember (name), GCompute.ResolutionResultType.Global))
				end
			end
		end
	
		currentUsingSource = currentUsingSource:GetDeclaringObject ()
	end
	
	if globalDefinition:GetNamespace ():MemberExists (name) then
		resolutionResults:AddResult (GCompute.ResolutionResult (globalDefinition:GetNamespace ():GetMember (name), GCompute.ResolutionResultType.Global))
	end
	
	return resolutionResults
end

function self:ResolveLocal (resolutionResults, name, localDefinition)
	local localDistance = 0
	while localDefinition do
		if localDefinition:GetNamespace ():MemberExists (name) then
			resolutionResults:AddResult (
				GCompute.ResolutionResult (
					localDefinition:GetNamespace ():GetMember (name),
					GCompute.ResolutionResultType.Local
				):SetLocalDistance (localDistance)
			)
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

function self:ResolveUnqualifiedIdentifier (resolutionResults, name, globalDefinition, localDefinition)
	self:ResolveLocal  (resolutionResults, name, localDefinition)
	self:ResolveGlobal (resolutionResults, name, globalDefinition, localDefinition)
end

-- AST node resolution
function self:ResolveASTNode (astNode, recursive, globalDefinition, localDefinition)
	if astNode:Is ("Identifier") then
		self:ResolveIdentifier (astNode, recursive, globalDefinition, localDefinition)
	elseif astNode:Is ("NameIndex") then
		self:ResolveNameIndex (astNode, recursive, globalDefinition, localDefinition)
	elseif astNode:Is ("FunctionType") then
		self:ResolveFunctionType (astNode, recursive, globalDefinition, localDefinition)
	end
end

function self:ResolveIdentifier (astNode, recursive, globalDefinition, localDefinition)
	self:ResolveUnqualifiedIdentifier (astNode:GetResolutionResults (), astNode:GetName (), globalDefinition, localDefinition)
end

function self:ResolveNameIndex (astNode, recursive, globalDefinition, localDefinition)
	if recursive then
		self:ResolveASTNode (astNode:GetLeftExpression (), recursive, globalDefinition, localDefinition)
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

function self:ResolveFunctionType (astNode, recursive, globalDefinition, localDefinition)
	if recursive then
		self:ResolveASTNode (astNode:GetReturnTypeExpression (), recursive, globalDefinition, localDefinition)
		for i = 1, astNode:GetParameterList ():GetParameterCount () do
			local parameterType = astNode:GetParameterList ():GetParameterType (i)
			self:ResolveASTNode (parameterType, recursive, globalDefinition, localDefinition)
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

GCompute.ObjectResolver = GCompute.ObjectResolver ()