local self = {}
GCompute.ErrorType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor ()
end

function self:CanConstructFrom (sourceType)
	return false
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

function self:GetBaseTypeCount ()
	return 0
end

function self:GetBaseType (index)
	return nil
end

function self:GetCorrespondingDefinition (globalNamespace)
	return self
end

function self:GetFullName ()
	return "<error-type>"
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