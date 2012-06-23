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
	self.GlobalNamespaceDefinition = GCompute.GlobalNamespace
end

function self:GetGlobalNamespace ()
	return self.GlobalNamespaceDefinition
end

function self:SetGlobalNamespace (globalNamespaceDefinition)
	self.GlobalNamespaceDefinition = globalNamespaceDefinition
end

function self:LookupQualifiedIdentifier (leftNamespace, name, nameResolutionResults)
	nameResolutionResults = nameResolutionResults or GCompute.NameResolutionResults ()
	
	if leftNamespace:MemberExists (name) then
		nameResolutionResults:AddGlobalResult (leftNamespace:GetMember (name), leftNamespace:GetMemberMetadata (name))
	end
	
	return nameResolutionResults
end

function self:LookupUnqualifiedIdentifier (referenceNamespace, name, nameResolutionResults)
	nameResolutionResults = nameResolutionResults or GCompute.NameResolutionResults ()
	
	self:LookupLocal (referenceNamespace, name, nameResolutionResults)
	self:LookupGlobal (referenceNamespace, name, nameResolutionResults)
	
	return nameResolutionResults
end

function self:LookupGlobal (referenceNamespace, name, nameResolutionResults)
	nameResolutionResults = nameResolutionResults or GCompute.NameResolutionResults ()
	
	local currentUsingSource = referenceNamespace
	while currentUsingSource do
		for i = 1, currentUsingSource:GetUsingCount () do
			local usingDirective = currentUsingSource:GetUsing (i)
			print ("Checking " .. usingDirective:ToString () .. " for " .. name)
			if usingDirective:GetNamespace () and usingDirective:GetNamespace ():MemberExists (name) then
				nameResolutionResults:AddGlobalResult (usingDirective:GetNamespace ():GetMember (name), usingDirective:GetNamespace ():GetMemberMetadata (name))
			end
		end
	
		currentUsingSource = currentUsingSource:GetContainingNamespace ()
	end
	
	if self.GlobalNamespaceDefinition:MemberExists (name) then
		nameResolutionResults:AddGlobalResult (self.GlobalNamespaceDefinition:GetMember (name), self.GlobalNamespaceDefinition:GetMemberMetadata (name))
	end
	
	return nameResolutionResults
end

function self:LookupLocal (referenceNamespace, name, nameResolutionResults)
	nameResolutionResults = nameResolutionResults or GCompute.NameResolutionResults ()
	
	local containingNamespace = referenceNamespace
	while containingNamespace do
		if containingNamespace:MemberExists (name) then
			nameResolutionResults:AddLocalResult (containingNamespace:GetMember (name), containingNamespace:GetMemberMetadata (name))
		end
		
		containingNamespace = containingNamespace:GetContainingNamespace ()
	end
	
	return nameResolutionResults
end