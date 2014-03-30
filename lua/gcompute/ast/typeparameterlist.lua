local self = {}
self.__Type = "TypeParameterList"
GCompute.AST.TypeParameterList = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.ParameterCount = 0
	self.ParameterNames = {}
end

function self:AddParameter (parameterName)
	self.ParameterCount = self.ParameterCount + 1
	self.ParameterNames [self.ParameterCount] = parameterName
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self)
	memoryUsageReport:CreditTableStructure ("Syntax Trees", self.ParameterNames)
	
	return memoryUsageReport
end

function self:GetChildEnumerator ()
	return GCompute.NullCallback
end

--- Returns an iterator function for this type parameter list
-- @return An iterator function for this type parameter list
function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.ParameterNames)
end

function self:GetParameterCount ()
	return self.ParameterCount
end

function self:GetParameterName (parameterId)
	return self.ParameterNames [parameterId]
end

function self:IsEmpty ()
	return self.ParameterCount == 0
end

function self:SetParameterName (parameterId, parameterName)
	self.ParameterNames [parameterId] = parameterName
end

-- Converts this AST.TypeParameterList to a TypeParameterList.
function self:ToTypeParameterList ()
	local typeParameterList = GCompute.TypeParameterList ()
	for parameterName in self:GetEnumerator () do
		typeParameterList:AddParameter (parameterName)
	end
	return typeParameterList
end

function self:ToString ()
	local typeParameterList = ""
	for i = 1, self.ParameterCount do
		if typeParameterList ~= "" then
			typeParameterList = typeParameterList .. ", "
		end
		local parameterName = self.ParameterNames [i] or "[Nothing]"
		typeParameterList = typeParameterList .. " " .. parameterName
	end
	return "<" .. typeParameterList .. ">"
end

function self:Visit (astVisitor, ...)
	local astOverride = astVisitor:VisitTypeParameterList (self, ...)
	if astOverride then return astOverride:Visit (astVisitor, ...) or astOverride end
end