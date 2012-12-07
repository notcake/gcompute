local self = {}
GCompute.IObject = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:GetFullName ()
	ErrorNoHalt ("IObject:GetFullName : Not implemented for " .. self:ToString () .. "\n")
end

--- Gets whether this object is an alias for another object
-- @return A boolean indicating whether this object is an alias for another object
function self:IsAlias ()
	return false
end

function self:IsASTNode ()
	return false
end

function self:IsType ()
	return false
end

function self:IsDeferredObjectResolution ()
	return false
end

function self:IsObjectDefinition ()
	return false
end

function self:IsNamespace ()
	return false
end

--- Returns the target of this AliasDefinition or this IObject if this is not an AliasDefinition
-- @return The target of this AliasDefinition
function self:UnwrapAlias ()
	return self
end