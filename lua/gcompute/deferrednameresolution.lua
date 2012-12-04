local self = {}
GCompute.DeferredNameResolution = GCompute.MakeConstructor (self, GCompute.IObject)

--- @param name The name to be resolved as a string or syntax tree node
function self:ctor (name, nameResolver, globalNamespace, localNamespace)
	self.Name = name
	self.ParsedName = name
	
	self.NameResolver = nameResolver or GCompute.DefaultNameResolver
	self.GlobalNamespace = globalNamespace or GCompute.GlobalNamespace
	self.LocalNamespace = localNamespace
	self.ErrorReporter = GCompute.DefaultErrorReporter
	
	self.Object = nil
	self.Resolved = false
	self.ResolutionFailed = false
	
	if name == nil then
		GCompute.Error ("DeferredNameResolution constructed with a nil value.")
		self.Name = "nil"
		self.ParsedName = GCompute.TypeParser:Root ("nil")
	elseif type (name) == "string" then
		self.ParsedName = GCompute.TypeParser:Root (name)
	elseif name:IsASTNode () then
		self.Name = self.ParsedName:ToString ()
	else
		GCompute.Error ("DeferredNameResolution constructed with an unknown object (" .. name:ToString () .. ")")
	end
end

function self:ComputeMemoryUsage (memoryUsageReport, poolName)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure (poolName or "Deferred Name Resolutions", self)
	memoryUsageReport:CreditString (poolName or "Deferred Name Resolutions", self.Name)
	
	if self.ParsedName then
		self.ParsedName:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:GetErrorReporter ()
	return self.ErrorReporter
end

function self:GetFullName ()
	if self.ResolutionFailed then
		return "[Failed] " .. self.Name
	end
	if not self:IsResolved () then
		return "[Unresolved] " .. self.Name
	end
	return self.Object:GetFullName ()
end

function self:GetGlobalNamespace ()
	return self.GlobalNamespace
end

function self:GetLocalNamespace ()
	return self.LocalNamespace
end

function self:GetName ()
	return self.Name
end

function self:GetObject ()
	if not self:IsResolved () then
		GCompute.Error ("DeferredNameResolution:GetObject : " .. self:GetFullName () .. " has not been resolved yet.")
	end
	return self.Object
end

function self:GetParsedName ()
	return self.ParsedName
end

function self:IsDeferredNameResolution ()
	return true
end

function self:IsFailedResolution ()
	return self.ResolutionFailed
end

function self:IsResolved ()
	return self.Resolved
end

--- Resolves the name stored in this DeferredNameResolution
function self:Resolve ()
	self.NameResolver:ResolveASTNode (self.ParsedName, self.ErrorReporter, self.GlobalNamespace, self.LocalNamespace)
	
	-- Should only have 1 match
	local matches = {}
	local resolutionResults = self.ParsedName.ResolutionResults
	
	if not resolutionResults then
		self.ErrorReporter:Error ("Cannot resolve " .. self.Name .. ": compiler bug.")
		self:SetResolvedObject (nil)
		return
	end
	
	if resolutionResults:GetLocalResultCount () > 0 then
		resolutionResults:FilterLocalResults ()
		resolutionResults:ClearGlobalResults ()
		resolutionResults:ClearMemberResults ()
	end
	
	for i = 1, resolutionResults:GetResultCount () do
		matches [#matches + 1] = resolutionResults:GetResult (i)
	end
	
	if #matches == 0 then
		self.ErrorReporter:Error ("Cannot resolve " .. self.ParsedName:GetFormattedLocation () .. ": " .. self.Name .. ": no matches found.")
		self:SetResolvedObject (nil)
		
	elseif #matches == 1 then
		if matches [1]:IsObjectDefinition () and matches [1]:IsOverloadedTypeDefinition () then
			matches [1] = matches [1]:GetType (1)
		end
		self:SetResolvedObject (matches [1])
	else
		self.ErrorReporter:Error ("Cannot resolve " .. self.ParsedName:GetFormattedLocation () .. ": " .. self.Name .. ": too many matches.")
		self.ErrorReporter:Error (self.ParsedName.ResolutionResults:ToString ())
		self:SetResolvedObject (nil)
	end
	
	return self:GetObject () or self
end

function self:SetErrorReporter (errorReporter)
	self.ErrorReporter = errorReporter or GCompute.DefaultErrorReporter
end

function self:SetGlobalNamespace (globalNamespace)
	self.GlobalNamespace = globalNamespace
end

function self:SetLocalNamespace (localNamespace)
	self.LocalNamespace = localNamespace
end

function self:SetResolvedObject (object)
	self.Object = object
	self.Resolved = true
	self.ResolutionFailed = object == nil
end

function self:ToString ()
	if self.ResolutionFailed then
		return "[Failed to resolve] " .. self.Name
	elseif not self:IsResolved () then
		return "[Unresolved] " .. self.Name
	end
	return self.Object:GetFullName ()
end