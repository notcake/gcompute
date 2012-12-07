local self = {}
GCompute.ReferenceType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (innerType)
	self.InnerType = innerType
	
	if self.InnerType and self.InnerType:IsDeferredObjectResolution () then
		if not self.InnerType:GetObject () then
			GCompute.Error ("ReferenceType constructor was passed a failed or unresolved DeferredObjectResolution (" .. self.InnerType:ToString () .. ").")
		end
		self.InnerType = self.InnerType:GetObject ()
	end
	
	if not self.InnerType then
	elseif self.InnerType:IsType () then
		if self.InnerType:IsReference () then
			GCompute.Error ("ReferenceType constructor cannot be passed a ReferenceType (" .. self.InnerType:ToString () .. ")")
			self.InnerType = self.InnerType:UnwrapReference ()
		end
	elseif self.InnerType:IsAlias () then
	else
		GCompute.Error ("ReferenceType constructor must be passed a Type or nil, got " .. self.InnerType:ToString ())
		self.InnerType = nil
	end
end

function self:CanExplicitCastTo (destinationType)
	if not self.InnerType then return false end
	
	local innerType = self.InnerType:UnwrapAlias ()
	return innerType:CanExplicitCastTo (destinationType)
end

function self:CanImplicitCastTo (destinationType)
	if not self.InnerType then return false end

	local innerType = self.InnerType:UnwrapAlias ()
	if innerType:Equals (destinationType) then return true end
	if innerType:IsBaseType (destinationType) then return true end
	return innerType:CanImplicitCastTo (destinationType)
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Types", self)
	if self.InnerType then
		self.InnerType:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:Equals (otherType)
	otherType = otherType:UnwrapAlias ()
	if self == otherType then return true end
	if not otherType:IsReference () then return false end
	return self:UnwrapReference ():Equals (otherType:UnwrapReference ())
end

function self:GetFullName ()
	if self.InnerType then
		return self.InnerType:GetFullName () .. " &"
	end
	return "[nil] &"
end

function self:IsBaseType (supertype)
	return false
end

function self:IsReference ()
	return true
end

function self:IsReferenceType ()
	return true
end

function self:ToString ()
	return self:GetFullName ()
end

--- Unwraps a ReferenceType
--@return The Type contained by this ReferenceType or this Type if this is not a ReferenceType
function self:UnwrapReference ()
	return self.InnerType
end