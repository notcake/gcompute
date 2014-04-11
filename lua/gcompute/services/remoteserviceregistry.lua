local self = {}
GCompute.Services.RemoteServiceRegistry = GCompute.MakeConstructor (self)

function self:ctor ()
	self.ServiceHostConstructors   = {}
	self.ServiceClientConstructors = {}
end

function self:CanCreateServiceClient (serviceName)
	return self.ServiceClientConstructors [serviceName] ~= nil
end

function self:CanCreateServiceHost (serviceName)
	return self.ServiceHostConstructors [serviceName] ~= nil
end

function self:CreateServiceClient (serviceName, ...)
	local constructor = self.ServiceClientConstructors [serviceName]
	if not constructor then return nil end
	return constructor (...)
end

function self:CreateServiceHost (serviceName, ...)
	local constructor = self.ServiceHostConstructors [serviceName]
	if not constructor then return nil end
	return constructor (...)
end

function self:GetServiceClientConstructor (serviceName)
	return self.ServiceClientConstructors (serviceName)
end

function self:GetServiceHostConstructor (serviceName)
	return self.ServiceHostConstructors (serviceName)
end

function self:RegisterServiceClient (serviceName, constructor)
	self.ServiceClientConstructors [serviceName] = constructor
end

function self:RegisterServiceHost (serviceName, constructor)
	self.ServiceHostConstructors [serviceName] = constructor
end

GCompute.Services.RemoteServiceRegistry = GCompute.Services.RemoteServiceRegistry ()