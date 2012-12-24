local self = {}
GCompute.Type = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
	-- System
	self.GlobalNamespace    = nil
	
	-- Hierarchy
	self.Definition        = nil
	self.Namespace          = nil
	
	-- Type
	self.Top                = false
	self.Bottom             = false
	
	self.Nullable           = false
	
	self.Primitive          = false
	self.NativelyAllocated  = false
	
	-- Runtime function tables
	self.FunctionTable      = {}
	self.FunctionTableValid = false
end

-- System
function self:GetGlobalNamespace ()
	return self.GlobalNamespace
end

function self:SetGlobalNamespace (globalNamespace)
	self.GlobalNamespace = globalNamespace
	return self
end

-- Hierarchy
function self:GetDefinition ()
	return self.Definition
end

function self:GetNamespace ()
	return self.Namespace
end

-- Inheritance
function self:GetBaseType (index)
	GCompute.Error ("Type:GetBaseType : Not implemented for " .. self:ToString ())
end

function self:GetBaseTypeCount (index)
	GCompute.Error ("Type:GetBaseTypeCount : Not implemented for " .. self:ToString ())
end

function self:GetBaseTypeEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self:GetBaseType (i)
	end
end

--- Returns whether this type derives from the specified type
-- @param type The type to be checked
-- @return A boolean indicating whether this type derives from baseType
function self:IsBaseType (type)
	if self:IsTop () or self:IsBottom () then return false end
	
	for baseType in self:GetBaseTypeEnumerator () do
		baseType = baseType:UnwrapAlias ()
		if baseType:IsType () and (baseType:Equals (type) or baseType:IsBaseType (type)) then
			return true
		end
	end
	
	return false
end

function self:IsBaseTypeOf (subtype)
	return subtype:IsBaseType (self)
end

-- Type
--- Returns a boolean indicating whether this type can be converted to destinationType
-- @param destinationType The Type to be converted to
-- @param typeConversionMethod The type conversion methods to try
-- @return A boolean indicating whether this type can be converted to destinationType
function self:CanConvertTo (destinationType, typeConversionMethod)
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
	GCompute.Error ("Type:CreateDefaultValue : Not implemented (" .. self:GetFullName () .. ")")
end

function self:Equals (otherType)
	GCompute.Error ("Type:Equals : Not implemented (" .. self:GetFullName () .. ")")
end

function self:GetFullName ()
	return "[Type]"
end

function self:GetCorrespondingDefinition (globalNamespace)
	GCompute.Error ("Type:GetCorrespondingDefinition : Not implemented (" .. self:GetFullName () .. ")")
	return nil
end

--- Gets the type's runtime function table
-- @return The type's runtime function table
function self:GetFunctionTable ()
	if not self.FunctionTableValid then
		self:BuildFunctionTable ()
	end
	return self.FunctionTable
end

function self:GetRelativeName (referenceDefinition)
	return self:GetFullName ()
end

function self:GetTypeParameterList ()
	return GCompute.EmptyTypeParameterList
end

--- Invalidates the type's cached runtime function table
function self:InvalidateFunctionTable ()
	self.FunctionTableValid = false
end

function self:IsArrayType ()
	return false
end

function self:IsBottom ()
	return self.Bottom
end

function self:IsConcreteType ()
	return true
end

function self:IsErrorType ()
	return false
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

function self:IsOverloadedClass ()
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

function self:IsTypeParameter ()
	return false
end

function self:IsVoid ()
	return self.Bottom
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

function self:SetBottom (isBottom)
	self.Bottom = isBottom
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

function self:SetTop (isTop)
	self.Top = isTop
end

function self:SubstituteTypeParameters (substitutionMap)
	return substitutionMap:GetReplacement (self) or self
end

function self:ToString ()
	return self:GetFullName ()
end

function self:ToType ()
	return self
end

--- Unwraps a ReferenceType
--@return The Type contained by this ReferenceType or this Type if this is not a ReferenceType
function self:UnwrapReference ()
	return self
end

-- Internal, do not call
function self:BuildFunctionTable ()
	if self.FunctionTableValid then return end
	self.FunctionTableValid = true
	
	self.FunctionTable = {}
	self.FunctionTable.Static = {}
	self.FunctionTable.Virtual = {}
	
	-- Merge in base function tables
	for baseType in self:GetBaseTypeEnumerator () do
		local baseFunctionTable = baseType:GetFunctionTable ()
		
		-- Merge in static function tables
		for typeName, functionTable in pairs (baseFunctionTable.Static) do
			self.FunctionTable.Static [typeName] = self.FunctionTable.Static [typeName] or {}
			for methodName, functionTableEntry in pairs (functionTable) do
				self.FunctionTable.Static [typeName] [methodName] = functionTableEntry
			end
		end
		
		-- Merge in virtual function table
		for methodName, functionTableEntry in pairs (baseFunctionTable.Virtual) do
			self.FunctionTable.Virtual [methodName] = functionTableEntry
		end
	end
	
	local fullName = self:GetFullName ()
	self.FunctionTable.Static [fullName] = self.FunctionTable.Static [fullName] or {}
	
	local definition = self:GetDefinition ()
	if definition then
		-- Add functions
		for _, memberDefinition in definition:GetEnumerator () do
			if memberDefinition:IsOverloadedMethod () then
				for methodDefinition in memberDefinition:GetEnumerator () do
					self.FunctionTable.Static [fullName] [methodDefinition:GetRuntimeName ()] = methodDefinition:GetNativeFunction () or methodDefinition
				end
			elseif memberDefinition:IsMethod () then
				self.FunctionTable.Static [fullName] [memberDefinition:GetRuntimeName ()] = memberDefinition:GetNativeFunction () or memberDefinition
			end
		end
		
		-- Add explicit casts
		for explicitCast in definition:GetExplicitCastEnumerator () do
			self.FunctionTable.Static [fullName] [explicitCast:GetRuntimeName ()] = explicitCast:GetNativeFunction () or explicitCast
		end
		
		-- Add implicit casts
		for implicitCast in definition:GetImplicitCastEnumerator () do
			self.FunctionTable.Static [fullName] [implicitCast:GetRuntimeName ()] = implicitCast:GetNativeFunction () or implicitCast
		end
	end
	
	-- Merge our static function table into the virtual function table
	for methodName, functionTableEntry in pairs (self.FunctionTable.Static [fullName]) do
		self.FunctionTable.Virtual [methodName] = functionTableEntry
	end
end