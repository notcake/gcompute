local self = {}
GCompute.NameResolver = GCompute.MakeConstructor (self)

--[[
	<identifier>:
		<local>
		<member>
		Global Namespace.<member>
		
	<x>.<identifier>:
		Namespace.<member>
		Type.<member>
		Type Instance.<member>
]]

function self:ctor ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Name Resolvers", self)
	return memoryUsageReport
end

function self:LookupQualifiedIdentifier (leftNamespace, name, resolutionResults)
	resolutionResults = resolutionResults or GCompute.NameResolutionResults ()
	
	if leftNamespace:MemberExists (name) then
		resolutionResults:AddGlobalResult (leftNamespace:GetMember (name))
	end
	
	return resolutionResults
end

function self:LookupUnqualifiedIdentifier (name, globalNamespace, localNamespace, resolutionResults)
	resolutionResults = resolutionResults or GCompute.NameResolutionResults ()
	
	self:LookupLocal (name, globalNamespace, localNamespace, resolutionResults)
	self:LookupGlobal (name, globalNamespace, localNamespace, resolutionResults)
	
	return resolutionResults
end

function self:LookupGlobal (name, globalNamespace, localNamespace, resolutionResults)
	resolutionResults = resolutionResults or GCompute.NameResolutionResults ()
	
	local currentUsingSource = localNamespace
	while currentUsingSource do
		for i = 1, currentUsingSource:GetUsingCount () do
			local usingDirective = currentUsingSource:GetUsing (i)
			if usingDirective:GetNamespace () and usingDirective:GetNamespace ():MemberExists (name) then
				resolutionResults:AddGlobalResult (usingDirective:GetNamespace ():GetMember (name))
			end
		end
	
		currentUsingSource = currentUsingSource:GetContainingNamespace ()
	end
	
	if globalNamespace:MemberExists (name) then
		resolutionResults:AddGlobalResult (globalNamespace:GetMember (name))
	end
	
	return resolutionResults
end

function self:LookupLocal (name, globalNamespace, localNamespace, resolutionResults)
	resolutionResults = resolutionResults or GCompute.NameResolutionResults ()
	
	local containingNamespace = localNamespace
	while containingNamespace do
		if containingNamespace:MemberExists (name) then
			resolutionResults:AddLocalResult (containingNamespace:GetMember (name))
		end
		
		containingNamespace = containingNamespace:GetContainingNamespace ()
	end
	
	return resolutionResults
end

function self:ResolveASTNode (astNode, errorReporter, globalNamespace, localNamespace)
	if not astNode then return GCompute.NameResolutionResults () end

	local resolutionResults = nil
	if astNode:Is ("NameIndex") then
		-- TODO: Merge with SimpleNameResolver's NameIndex processing
		local leftResults = self:ResolveASTNode (astNode:GetLeftExpression (), errorReporter, globalNamespace, localNamespace)
		local identifier = astNode:GetIdentifier ()
		if not identifier then
			errorReporter:Error ("NameIndex is missing an Identifier (" .. astNode:ToString () .. ").")
		elseif identifier:Is ("Identifier") then
			if leftResults and leftResults:GetResult (1) then
				resolutionResults = self:LookupQualifiedIdentifier (leftResults:GetResult (1), identifier:GetName ())
			else
				errorReporter:Error ("Failed to resolve left hand side of NameIndex (" .. astNode:ToString () .. ")")
			end
		else
			errorReporter:Error ("Unknown AST node on right of NameIndex (" .. identifier:GetNodeType () .. ")")
		end
	elseif astNode:Is ("Identifier") then
		resolutionResults = self:LookupUnqualifiedIdentifier (astNode:GetName (), globalNamespace, localNamespace)
	elseif astNode:Is ("FunctionType") then
		-- TODO: Make this class set ResolvedObjects, or merge with SimpleNameResolver
		resolutionResults = GCompute.NameResolutionResults ()
		
		local returnResults = self:ResolveASTNode (astNode:GetReturnTypeExpression (), errorReporter, globalNamespace, localNamespace)
		for i = 1, astNode:GetParameterList ():GetParameterCount () do
			local parameterType = astNode:GetParameterList ():GetParameterType (i)
			if parameterType then
				self:ResolveASTNode (parameterType, errorReporter, globalNamespace, localNamespace)
			end
		end
		
		-- TODO: This is WRONG, fix it.
		local returnType = returnResults:GetResult (1)
		if returnType:IsOverloadedTypeDefinition () then
			returnType = returnType:GetType (1)
		end
		
		local functionType = GCompute.FunctionType (returnType, astNode:GetParameterList ():ToParameterList ())
		resolutionResults:AddGlobalResult (functionType)
	else
		errorReporter:Error ("NameResolver cannot handle " .. astNode:GetNodeType () .. " AST node.")
	end
	astNode.ResolutionResults = resolutionResults or astNode.ResolutionResults
	return resolutionResults
end

GCompute.DefaultNameResolver = GCompute.NameResolver ()