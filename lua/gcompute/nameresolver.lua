local self = {}
GCompute.NameResolver = GCompute.MakeConstructor (self)

--[[
	First identifier:
		All local scopes first
		Class, then base classes
		Global scope, all usings
		
	Second identifier:
		Namespace -> obvious
		Type -> obvious
		Type instance -> type members?
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
		resolutionResults:AddGlobalResult (leftNamespace:GetMember (name), leftNamespace:GetMemberMetadata (name))
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
				resolutionResults:AddGlobalResult (usingDirective:GetNamespace ():GetMember (name), usingDirective:GetNamespace ():GetMemberMetadata (name))
			end
		end
	
		currentUsingSource = currentUsingSource:GetContainingNamespace ()
	end
	
	if globalNamespace:MemberExists (name) then
		resolutionResults:AddGlobalResult (globalNamespace:GetMember (name), globalNamespace:GetMemberMetadata (name))
	end
	
	return resolutionResults
end

function self:LookupLocal (name, globalNamespace, localNamespace, resolutionResults)
	resolutionResults = resolutionResults or GCompute.NameResolutionResults ()
	
	local containingNamespace = localNamespace
	while containingNamespace do
		if containingNamespace:MemberExists (name) then
			resolutionResults:AddLocalResult (containingNamespace:GetMember (name), containingNamespace:GetMemberMetadata (name))
		end
		
		containingNamespace = containingNamespace:GetContainingNamespace ()
	end
	
	return resolutionResults
end

function self:ResolveASTNode (astNode, errorReporter, globalNamespace, localNamespace)
	local resolutionResults = nil
	if astNode:Is ("NamespaceIndex") then
	elseif astNode:Is ("ObjectIndex") then
	elseif astNode:Is ("NameIndex") then
		local leftResults = self:ResolveASTNode (astNode:GetLeftExpression (), errorReporter, globalNamespace, localNamespace)
		local identifier = astNode:GetIdentifier ()
		if identifier:Is ("Identifier") then
			if leftResults and leftResults:GetResult (1) then
				resolutionResults = self:LookupQualifiedIdentifier (leftResults:GetResult (1).Result, identifier:GetName ())
			end
		else
			errorReporter:Error ("Unknown AST node on right of NameIndex (" .. astNode:GetNodeType () .. ")")
		end
	elseif astNode:Is ("Identifier") then
		resolutionResults = self:LookupUnqualifiedIdentifier (astNode:GetName (), globalNamespace, localNamespace)
	end
	astNode.ResolutionResults = resolutionResults or astNode.ResolutionResults
	return resolutionResults
end

GCompute.DefaultNameResolver = GCompute.NameResolver ()