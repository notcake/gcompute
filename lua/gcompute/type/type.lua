local self = {}
GCompute.Type = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor ()
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Types", self)
	return memoryUsageReport
end

function self:GetTypeDefinition ()
	GCompute.Error ("Type:GetTypeDefinition not implemented for " .. self:ToString ())
end

function self:IsArrayType ()
	return false
end

function self:IsFunctionType ()
	return false
end

function self:IsInferredType ()
	return false
end

function self:IsReference ()
	return false
end

function self:IsReferenceType ()
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

--- Unwraps a ReferenceType
--@return The Type contained by this ReferenceType or this Type if this is not a ReferenceType
function self:UnwrapReference ()
	return self
end