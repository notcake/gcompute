local self = {}
GCompute.MergedLocalScope = GCompute.MakeConstructor (self)

function self:ctor ()
	self.MemberSet = GCompute.WeakKeyTable ()
	self.Members = GCompute.WeakValueTable ()
	
	self.UniqueNameMap = nil
end

function self:AddMember (memberDefinition)
	if self.MemberSet [memberDefinition] then return end
	if not self.UniqueNameMap then
		self.UniqueNameMap = GCompute.UniqueNameMap ()
		self.UniqueNameMap:ReserveName ("ToString")
	end
	
	self.MemberSet [memberDefinition] = true
	self.Members [#self.Members + 1] = memberDefinition
	
	self.UniqueNameMap:AddObject (memberDefinition)
end

function self:Clear ()
	self.MemberSet = GCompute.WeakKeyTable ()
	self.Members = GCompute.WeakValueTable ()
	
	if self.UniqueNameMap then
		self.UniqueNameMap:Clear ()
	end
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Merged Local Scopes", self)
	memoryUsageReport:CreditTableStructure ("Merged Local Scopes", self.MemberSet)
	memoryUsageReport:CreditTableStructure ("Merged Local Scopes", self.Members)
	
	if self.UniqueNameMap then
		self.UniqueNameMap:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:Contains (memberDefinition)
	return self.MemberSet [memberDefinition] or false
end

function self:CreateStackFrame ()
	local stackFrame = {}
	stackFrame.ToString = function (self)
		local str = "{"
		for k, v in pairs (self) do
			str = str .. "\n    " .. tostring (k) .. " = " .. tostring (v)
		end
		str = str .. "\n}"
		return str
	end
	
	for _, memberDefinition in ipairs (self.Members) do
		local runtimeName = self:GetRuntimeName (memberDefinition)
		stackFrame [runtimeName] = memberDefinition:CreateRuntimeObject ()
	end
	
	return stackFrame
end

function self:GetRuntimeName (object)
	if not self.RuntimeNameMap then return object:GetName () end
	return self.RuntimeNameMap:GetObjectName (object)
end

function self:IsEmpty ()
	return #self.Members == 0
end

function self:ToString ()
	local localScope = "[Merged Local Scope]"
	
	if self:IsEmpty () then
		localScope = localScope .. " { }"
	else
		localScope = localScope .. "\n{"
		
		for _, memberDefinition in ipairs (self.Members) do
			localScope = localScope .. "\n    " .. memberDefinition:GetType ():GetFullName () .. " " .. memberDefinition:GetName () .. " (" .. self:GetRuntimeName (memberDefinition) .. ")"
		end
		
		localScope = localScope .. "\n}"
	end
	
	return localScope
end