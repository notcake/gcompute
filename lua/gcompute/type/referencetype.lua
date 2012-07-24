local self = {}
GCompute.ReferenceType = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (innerType)
	self.InnerType = innerType
	
	if self.InnerType and self.InnerType:IsDeferredNameResolution () then
		if not self.InnerType:GetObject () then
			GCompute.Error ("ReferenceType constructor was passed a failed or unresolved DeferredNameResolution (" .. self.InnerType:ToString () .. ").")
		end
		self.InnerType = self.InnerType:GetObject ()
	end
	
	if not self.InnerType then
	elseif self.InnerType:IsType () then
		if self.InnerType:IsReference () then
			GCompute.Error ("ReferenceType constructor cannot be passed a ReferenceType (" .. self.InnerType:ToString () .. ")")
			self.InnerType = nil
		end
	else
		GCompute.Error ("ReferenceType constructor must be passed a Type or nil, got " .. self.InnerType:ToString ())
		self.InnerType = nil
	end
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

function self:Equals (other)
	if self == other then return true end
	if not other:IsReference () then return false end
	return self:UnwrapReference ():Equals (other:UnwrapReference ())
end

function self:GetFullName ()
	if self.InnerType then
		return self.InnerType:GetFullName () .. " &"
	end
	return "[nil] &"
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