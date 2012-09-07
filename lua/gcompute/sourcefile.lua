local self = {}
GCompute.SourceFile = GCompute.MakeConstructor (self)

local nextAnonymousId = 0

--[[
	SourceFile
	
		SourceFiles have a one to one relationship with CompilationUnits.
		A SourceFile will create a CompilationUnit if it doesn't already have one
		when GetCompilationUnit is called.
]]

--[[
	Events:
		CacheableChanged (cacheable)
			Fired when this source file's cacheability has changed.
		IdChanged (oldId, newId)
			Fired when this source file's id has changed.
		PathChanged (oldPath, newPath)
			Fired when this source file's path has changed.
]]

function self:ctor ()
	self.Id = ""
	self.Path = ""
	
	self.Code = ""
	self.CodeHash = 0
	
	self.CompilationUnit = nil
	
	self.Cacheable = true
	self.ExpiryTime = 0
	
	GCompute.EventProvider (self)
	
	self:AssignId ()
	self:ResetExpiryTime ()
	
	GCompute.SourceFileCache:Add (self)
end

function self:AssignId ()
	local id = "@dynamic_" .. tostring (nextAnonymousId)
	nextAnonymousId = nextAnonymousId + 1
	self:SetId (id)
end

function self:CanCache ()
	return self.Cacheable
end

function self:ComputeCodeHash ()
	self.CodeHash = tonumber (util.CRC (self.Code))
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Source Files", self)
	memoryUsageReport:CreditString ("Source Files", self.Path)
	memoryUsageReport:CreditString ("Source Code", self.Code)
	
	if self.CompilationUnit then
		self.CompilationUnit:ComputeMemoryUsage (memoryUsageReport)
	end
	return memoryUsageReport
end

function self:dtor ()
	GCompute.SourceFileCache:Remove (self)
end

function self:GetCode ()
	return self.Code
end

function self:GetCodeHash ()
	return self.CodeHash
end

--- Returns the CompilationUnit associated with this SourceFile and creates one if it doesn't already exist
-- @return The CompilationUnit associated with this SourceFile
function self:GetCompilationUnit ()
	if not self.CompilationUnit then
		self.CompilationUnit = GCompute.CompilationUnit (self)
	end
	
	return self.CompilationUnit
end

function self:GetExpiryTime ()
	return self.ExpiryTime
end

function self:GetId ()
	return self.Id
end

function self:GetPath ()
	return self.Path
end

function self:HasExpired ()
	return SysTime () >= self.ExpiryTime
end

function self:HasPath ()
	return self.Path and self.Path ~= nil or false
end

function self:ResetExpiryTime (timespan)
	timespan = timespan or 300 -- Default expiry time is 5 minutes
	
	self.ExpiryTime = SysTime () + timespan
end

function self:SetCacheable (cacheable)
	if self.Cacheable == cacheable then return end
	self.Cacheable = cacheable
	
	self:DispatchEvent ("CacheableChanged", cacheable)
end

function self:SetCode (code)
	self.Code = code
	self:ComputeCodeHash ()
end

function self:SetId (id)
	if not id or id == "" then self:AssignId () return end
	if self.Id == id then return end
	
	local oldId = self.Id
	self.Id = id
	
	self:DispatchEvent ("IdChanged", oldId, self.Id)
end

function self:SetPath (path)
	path = path or ""
	if self.Path == path then return end
	
	local oldPath = self.Path
	self.Path = path
	
	self:DispatchEvent ("PathChanged", oldPath, self.Path)
	
	if self:HasPath () then
		self:SetId (path)
	else
		self:AssignId ()
	end
end