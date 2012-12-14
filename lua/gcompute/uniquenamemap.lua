local self = {}
GCompute.UniqueNameMap = GCompute.MakeConstructor (self)

function self:ctor ()
	self.NameMap = GCompute.WeakKeyTable ()
	
	self.ChainedNameMaps = {}
	self.UsedNames = {}
end

function self:AddChainedNameMap (uniqueNameMap)
	self.ChainedNameMaps [uniqueNameMap] = true
end

function self:AddObject (object, preferredName)
	if self.NameMap [object] then return end
	
	local baseName = preferredName or object:GetName ()
	
	if not self:IsNameInUse (baseName) then
		self.NameMap [object] = baseName
		self.UsedNames [baseName] = true
	else
		local i = 0
		while self:IsNameInUse (baseName .. "_" .. tostring (i)) do
			i = i + 1
		end
		self.NameMap [object] = baseName .. "_" .. tostring (i)
		self.UsedNames [baseName .. "_" .. tostring (i)] = true
	end
end

function self:Clear ()
	self.NameMap = GCompute.WeakKeyTable ()
	self.UsedNames = {}
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Unique Name Maps", self)
	memoryUsageReport:CreditTableStructure ("Unique Name Maps", self.NameMap)
	memoryUsageReport:CreditTableStructure ("Unique Name Maps", self.UsedNames)
	
	return memoryUsageReport
end

function self:GetObjectName (object, preferredName)
	if not self.NameMap [object] then
		self:AddObject (object, preferredName)
	end
	
	return self.NameMap [object]
end

function self:IsNameInUse (name)
	if self.UsedNames [name] then return true end
	for uniqueNameMap, _ in pairs (self.ChainedNameMaps) do
		if uniqueNameMap:IsNameInUse (name) then return true end
	end
	return false
end

function self:ReserveName (name)
	self.UsedNames [name] = true
end