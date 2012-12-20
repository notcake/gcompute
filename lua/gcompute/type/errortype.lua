local self = {}
GCompute.ErrorType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor ()
end

function self:CanExplicitCastTo (destinationType)
	return false
end

function self:CanImplicitCastTo (destinationType)
	return false
end

function self:Equals (otherType)
	return false
end

function self:GetFullName ()
	return "<error-type>"
end

function self:GetClassDefinition ()
	return nil
end

function self:IsBaseType (supertype)
	return false
end

function self:IsErrorType ()
	return true
end

function self:ToString ()
	return "<error-type>"
end