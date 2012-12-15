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

function self:ResolveGlobal (resolutionResults, name, globalNamespace, usingNamespace)
	local currentUsingSource = usingNamespace
	while currentUsingSource do
		for i = 1, currentUsingSource:GetUsingCount () do
			local usingDirective = currentUsingSource:GetUsing (i)
			if usingDirective:GetNamespace () and usingDirective:GetNamespace ():MemberExists (name) then
				resolutionResults:AddResult (GCompute.ResolutionResult (usingDirective:GetNamespace ():GetMember (name), GCompute.ResolutionResultType.Global))
			end
		end
	
		currentUsingSource = currentUsingSource:GetContainingNamespace ()
	end
	
	if globalNamespace:MemberExists (name) then
		resolutionResults:AddResult (GCompute.ResolutionResult (globalNamespace:GetMember (name), GCompute.ResolutionResultType.Global))
	end
	
	return resolutionResults
end

function self:ResolveLocal (resolutionResults, name, localNamespace)
	local localDistance = 0
	local containingNamespace = localNamespace
	while containingNamespace do
		if containingNamespace:MemberExists (name) then
			resolutionResults:AddResult (
				GCompute.ResolutionResult (
					containingNamespace:GetMember (name),
					GCompute.ResolutionResultType.Local
				):SetLocalDistance (localDistance)
			)
		end
		
		containingNamespace = containingNamespace:GetContainingNamespace ()
		localDistance = localDistance + 1
	end
	
	return resolutionResults
end

function self:ResolveMember (resolutionResults, name, containingNamespace)
	if containingNamespace:MemberExists (name) then
		resolutionResults:AddResult (GCompute.ResolutionResult (containingNamespace:GetMember (name), GCompute.ResolutionResultType.Other))
	end
end

function self:ResolveUnqualifiedIdentifier (resolutionResults, name, globalNamespace, localNamespace)
	self:ResolveLocal  (resolutionResults, name, localNamespace)
	self:ResolveGlobal (resolutionResults, name, globalNamespace, localNamespace)
end

-- AST node resolution
function self:ResolveASTNode (astNode, recursive, globalNamespace, localNamespace)
	if astNode:Is ("Identifier") then
		self:ResolveIdentifier (astNode, recursive, globalNamespace, localNamespace)
	elseif astNode:Is ("NameIndex") then
		self:ResolveNameIndex (astNode, recursive, globalNamespace, localNamespace)
	elseif astNode:Is ("FunctionType") then
		self:ResolveFunctionType (astNode, recursive, globalNamespace, localNamespace)
	end
end

function self:ResolveIdentifier (astNode, recursive, globalNamespace, localNamespace)
	self:ResolveUnqualifiedIdentifier (astNode:GetResolutionResults (), astNode:GetName (), globalNamespace, localNamespace)
end

function self:ResolveNameIndex (astNode, recursive, globalNamespace, localNamespace)
	if recursive then
		self:ResolveASTNode (astNode:GetLeftExpression (), recursive, globalNamespace, localNamespace)
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
			local leftNamespace = leftResults:GetFilteredResult (i):GetObject ():UnwrapAlias ()
			if leftNamespace:IsNamespace () or leftNamespace:IsTypeDefinition () then
				self:ResolveMember (rightResults, right:GetName (), leftNamespace)
			end
		end
	else
		astNode:AddErrorMessage ("Unknown AST node on right of NameIndex (" .. identifier:GetNodeType () .. ")")
	end
end

function self:ResolveFunctionType (astNode, recursive, globalNamespace, localNamespace)
	if recursive then
		self:ResolveASTNode (astNode:GetReturnTypeExpression (), recursive, globalNamespace, localNamespace)
		for i = 1, astNode:GetParameterList ():GetParameterCount () do
			local parameterType = astNode:GetParameterList ():GetParameterType (i)
			self:ResolveASTNode (parameterType, recursive, globalNamespace, localNamespace)
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
	
	astNode:GetResolutionResults ():AddResult (
		GCompute.ResolutionResult (
			GCompute.FunctionType (
				returnResults:GetFilteredResult (1) and returnResults:GetFilteredResult (1):GetObject () or GCompute.NullType (),
				astNode:GetParameterList ():ToParameterList ()
			),
			GCompute.ResolutionResultType.Other
		)
	)
end

GCompute.ObjectResolver = GCompute.ObjectResolver ()