local self = {}
GCompute.UsingDirective = GCompute.MakeConstructor (self)

function self:ctor (namespaceName)
	self.ResolutionScope = nil

	self.Namespace = nil
	self.NamespaceName = namespaceName
	self.Resolved = false
end

function self:GetResolutionScope ()
	return self.ResolutionScope
end

function self:IsResolved ()
	return self.Resolved
end

function self:Resolve ()
	local parseTree = GCompute.TypeParser (self.NamespaceName).ParseTree
	GCompute.CompileTimeScopeLookup
end

function self:SetResolutionScope (resolutionScope)
	if self.ResolutionScope and self.ResolutionScope ~= resolutionScope then GCompute.Error ("Resolution scope already set!") end

	self.ResolutionScope = resolutionScope
end