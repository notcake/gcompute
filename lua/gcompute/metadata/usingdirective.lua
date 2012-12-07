local self = {}
GCompute.UsingDirective = GCompute.MakeConstructor (self)

function self:ctor (namespaceName)
	self.DeferredObjectResolution = nil
	self.NamespaceName = nil
	self.Namespace = nil
	
	if type (namespaceName) == "string" then
		self.DeferredObjectResolution = GCompute.DeferredObjectResolution (namespaceName, GCompute.ResolutionObjectType.Namespace)
		self.NamespaceName = namespaceName
	elseif namespaceName:IsDeferredObjectResolution () then
		self.DeferredObjectResolution = namespaceName
		self.NamespaceName = namespaceName:GetName ()
		self.Namespace = namespaceName:IsResolved () and namespaceName:GetObject () or nil
	else
		GCompute.Error ("UsingDirective constructed with unknown object.")
	end
end

function self:GetNamespace ()
	if not self:IsResolved () then
		GCompute.Error ("UsingDirective:GetNamespace : " .. self:ToString () .. " has not been resolved yet.")
	end
	return self.Namespace
end

function self:GetQualifiedName ()
	return self.NamespaceName
end

function self:IsResolved ()
	return self.Namespace and true or false
end

function self:Resolve ()
	if self:IsResolved () then return end
	
	local deferredObjectResolution = self.DeferredObjectResolution
	if deferredObjectResolution:IsResolved () then return end
	
	deferredObjectResolution:Resolve ()
	if deferredObjectResolution:IsFailedResolution () then
		deferredObjectResolution:GetAST ():GetMessages ():PipeToErrorReporter (GCompute.DefaultErrorReporter)
	else
		self.Namespace = deferredObjectResolution:GetObject ()
		if self.Namespace:IsObjectDefinition () then
			self.Namespace = self.Namespace:UnwrapAlias ()
		end
	end
end

function self:SetNamespace (namespaceDefinition)
	self.Namespace = namespaceDefinition
end

function self:SetQualifiedName (namespaceName)
	self.NamespaceName = namespaceName
end

function self:ToString ()
	return "using " .. self.NamespaceName .. ";"
end