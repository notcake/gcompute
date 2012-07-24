local self = {}
GCompute.IObject = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:IsASTNode ()
	return false
end

function self:IsType ()
	return false
end

function self:IsDeferredNameResolution ()
	return false
end

function self:IsObjectDefinition ()
	return false
end