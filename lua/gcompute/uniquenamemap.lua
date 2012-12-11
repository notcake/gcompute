local self = {}
GCompute.UniqueNameMap = GCompute.MakeConstructor (self)

function self:ctor ()
	self.NameMap = GCompute.WeakKeyTable ()
	self.UsedNames = {}
end

function self:AddObject (object)
	if self.NameMap [object] then return end
	
	local baseName = object:GetName ()
	
	if not self.UsedNames [baseName] then
		self.NameMap [object] = baseName
		self.UsedNames [baseName] = true
	else
		local i = 0
		while self.UsedNames [baseName .. "_" .. tostring (i)] do
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

function self:GetObjectName (object)
	if not self.NameMap [object] then
		self:AddObject (object)
	end
	
	return self.NameMap [object]
end

function self:ReserveName (name)
	self.UsedNames [name] = true
end