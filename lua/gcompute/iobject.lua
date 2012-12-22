local self = {}
GCompute.IObject = GCompute.MakeConstructor (self)

function self:ctor ()
end

function self:GetFullName ()
	GCompute.Error ("IObject:GetFullName : Not implemented for " .. self:ToString ())
	return "[Nothing]"
end

--- Gets whether this object is an alias for another object
-- @return A boolean indicating whether this object is an alias for another object
function self:IsAlias ()
	return false
end

function self:IsASTNode ()
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

--- Gets whether this object is a Type
-- @return A boolean indicating whether this object is a Type
function self:IsType ()
	return false
end

function self:ToType ()
	A = self
	GCompute.Error ("IObject:ToType : " .. self:GetFullName () .. " is not a Type!")
	return nil
end

--- Returns the target of this AliasDefinition or this IObject if this is not an AliasDefinition
-- @return The target of this AliasDefinition
function self:UnwrapAlias ()
	return self
end

function self:UnwrapAliasAndReference ()
	local lastUnwrapped = nil
	local unwrapped = self
	repeat
		lastUnwrapped = unwrapped
		unwrapped = unwrapped:UnwrapAlias ()
		if unwrapped:IsType () then
			unwrapped = unwrapped:UnwrapReference ()
		end
	until lastUnwrapped == unwrapped
	return unwrapped
end