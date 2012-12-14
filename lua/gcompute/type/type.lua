local self = {}
GCompute.Type = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
	self.Nullable = false
	
	self.Bottom = false
	self.Top = false
	
	self.Primitive = false
	self.NativelyAllocated = false
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
		return false, GCompute.TypeConversionMethod.None
	end
	if bit.band (typeConversionMethod, GCompute.TypeConversionMethod.Identity) ~= 0 and
	   self:UnwrapReference ():Equals (destinationType) then
		return true, GCompute.TypeConversionMethod.Identity
	end
	if bit.band (typeConversionMethod, GCompute.TypeConversionMethod.Downcast) ~= 0 and
	   self:UnwrapReference ():IsBaseType (destinationType) then
		return true, GCompute.TypeConversionMethod.Downcast
	end
	if bit.band (typeConversionMethod, GCompute.TypeConversionMethod.ImplicitCast) ~= 0 and
	   self:CanImplicitCastTo (destinationType) then
		return true, GCompute.TypeConversionMethod.ImplicitCast
	end
	if bit.band (typeConversionMethod, GCompute.TypeConversionMethod.ExplicitCast) ~= 0 and
	   self:CanExplicitCastTo (destinationType) then
		return true, GCompute.TypeConversionMethod.ExplicitCast
	end
	if bit.band (typeConversionMethod, GCompute.TypeConversionMethod.Constructor) ~= 0 and
	   destinationType:CanConstructFrom (self) then
		return true, GCompute.TypeConversionMethod.Constructor
	end
	return false, GCompute.TypeConversionMethod.None
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

--- Returns true if this Type has unbound type parameters
-- @return A boolean indicating whether this Type has unbound type parameters
function self:ContainsUnboundTypeParameters ()
	GCompute.Error ("Type:ContainsTypeParameterUsage : Not implemented (" .. self:GetFullName () .. ")")
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

function self:GetDeclaringFunction ()
	return nil
end

function self:GetDeclaringType ()
	return nil
end

function self:GetTypeDefinition ()
	GCompute.Error ("Type:GetTypeDefinition : Not implemented for " .. self:ToString ())
end

function self:GetTypeParameterList ()
	return GCompute.EmptyTypeParameterList
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

function self:IsBottom ()
	return self.Bottom
end

function self:IsConcreteType ()
	return true
end

function self:IsFunctionType ()
	return false
end

function self:IsInferredType ()
	return false
end

function self:IsNativelyAllocated ()
	return self.NativelyAllocated
end

function self:IsNullable ()
	return self.Nullable
end

function self:IsOverloadedTypeDefinition ()
	return false
end

function self:IsPrimitive ()
	return self.Primitive
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
	return self.Top
end

function self:IsType ()
	return true
end

--- Gets whether this object is a TypeDefinition
-- @return A boolean indicating whether this object is a TypeDefinition
function self:IsTypeDefinition ()
	return false
end

function self:IsTypeParameter ()
	return false
end

function self:RuntimeDowncastTo (destinationType, value)
	if self:IsNativelyAllocated () == destinationType:IsNativelyAllocated () then return value end
	if self:IsNativelyAllocated () then
		-- Box
		return GCompute.RuntimeObject ():Box (value, self)
	else
		-- Unbox
		return value:Unbox ()
	end
end

function self:RuntimeUpcastTo (destinationType, value)
	if self:IsNativelyAllocated () == destinationType:IsNativelyAllocated () then return value end
	if self:IsNativelyAllocated () then
		-- Box
		return GCompute.RuntimeObject ():Box (value, self)
	else
		-- Unbox
		return value:Unbox ()
	end
end

function self:SetIsBottom (isBottom)
	self.Bottom = isBottom
end

function self:SetIsTop (isTop)
	self.Top = isTop
end

function self:SetNativelyAllocated (nativelyAllocated)
	self.NativelyAllocated = nativelyAllocated
	if not self.NativelyAllocated and self:IsPrimitive () then
		self:SetPrimitive (false)
	end
end

function self:SetNullable (nullable)
	self.Nullable = nullable
end

function self:SetPrimitive (primitive)
	self.Primitive = primitive
	if self.Primitive and not self:IsNativelyAllocated () then
		self:SetNativelyAllocated (true)
	end
end

function self:SubstituteTypeParameters (substitutionMap)
	GCompute.Error ("Type:SubstituteTypeParameters : Not implemented for " .. self:ToString ())
end

--- Unwraps a ReferenceType
--@return The Type contained by this ReferenceType or this Type if this is not a ReferenceType
function self:UnwrapReference ()
	return self
end