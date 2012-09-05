local self = {}
GCompute.Type = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
	self.Nullable = false
end

--- Returns a boolean indicating whether this type can be converted to destinationType
-- @param destinationType The Type to be converted to
-- @param typeConversionMethod The type conversion methods to try
-- @return A boolean indicating whether this type can be converted to destinationType
function self:CanConvertTo (destinationType, typeConversionMethod)
	if destinationType:IsAlias () then
		destinationType = destinationType:UnwrapAlias ()
	end
	if not destinationType:IsType () then
		GCompute.Error ("Type:CanConvertTo : " .. destinationType:ToString () .. " is not a type.")
		return false
	end
	if typeConversionMethod & GCompute.TypeConversionMethod.Identity != 0 and
	   self:Equals (destinationType) then
		return true
	end
	if typeConversionMethod & GCompute.TypeConversionMethod.Downcast != 0 and
	   self:IsBaseType (destinationType) then
		return true
	end
	if typeConversionMethod & GCompute.TypeConversionMethod.ImplicitCast != 0 and
	   self:CanImplicitCastTo (destinationType) then
		return true
	end
	if typeConversionMethod & GCompute.TypeConversionMethod.ExplicitCast != 0 and
	   self:CanExplicitCastTo (destinationType) then
		return true
	end
	if typeConversionMethod & GCompute.TypeConversionMethod.Constructor != 0 and
	   destinationType:CanConstructFrom (self) then
		return true
	end
	return false
end

function self:CanConstructFrom (sourceType)
	GCompute.Error ("Type:CanConstructFrom : Not implemented for " .. self:ToString ())
	return false
end

function self:CanExplicitCastTo (destinationType)
	GCompute.Error ("Type:CanImplicitCastTo : Not implemented for " .. self:ToString ())
	return false
end

function self:CanImplicitCastTo (destinationType)
	GCompute.Error ("Type:CanImplicitCastTo : Not implemented for " .. self:ToString ())
	return false
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Types", self)
	return memoryUsageReport
end

function self:CreateDefaultValue ()
	return nil
end

function self:Equals (otherType)
	GCompute.Error ("Type:Equals : Not implemented for " .. self:ToString ())
end

--- Returns an array of types from which this type inherits. The returned array is only a copy.
-- @return An array of types from which this type inherits. The returned array is only a copy.
function self:GetBaseTypes ()
	GCompute.Error ("Type:GetBaseTypes : Not implemented for " .. self:ToString ())
end

function self:GetTypeDefinition ()
	GCompute.Error ("Type:GetTypeDefinition : Not implemented for " .. self:ToString ())
end

function self:IsArrayType ()
	return false
end

function self:IsBaseType (supertype)
	GCompute.Error ("Type:IsBaseType not implemented for " .. self:ToString ())
end

function self:IsBaseTypeOf (subtype)
	return subtype:IsBaseType (self)
end

function self:IsFunctionType ()
	return false
end

function self:IsInferredType ()
	return false
end

function self:IsNullable ()
	return self.Nullable
end

function self:IsReference ()
	return false
end

function self:IsReferenceType ()
	return false
end

--- Returns whether this type is a superset of all other types
-- @return A boolean indicating whether this type is a superset of all other types
function self:IsTop ()
	return false
end

function self:IsType ()
	return true
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsTypeDefinition ()
	return false
end

function self:Resolve (globalNamespace, localNamespace)
end

function self:SetNullable (nullable)
	self.Nullable = nullable
end

--- Unwraps a ReferenceType
--@return The Type contained by this ReferenceType or this Type if this is not a ReferenceType
function self:UnwrapReference ()
	return self
end