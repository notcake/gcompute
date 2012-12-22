local self = {}
GCompute.DeferredObjectResolution = GCompute.MakeConstructor (self, GCompute.IObject)

function self:ctor (name, objectType, globalNamespace, localNamespace)
	self.Name = name
	self.AST  = name
	self.DesiredObjectType = objectType or GCompute.ResolutionObjectType.All
	
	self.GlobalNamespace = globalNamespace or GCompute.GlobalNamespace
	self.LocalNamespace  = localNamespace
	
	self.Resolved = false
	self.ResolutionFailed = false
	
	if name == nil then
		GCompute.Error ("DeferredObjectResolution constructed with a nil value.")
		self.Name = "nil"
		self.AST = GCompute.AST.Identifier ("nil")
	elseif type (name) == "string" then
		self.AST = GCompute.TypeParser (name):Root ()
	elseif name:IsASTNode () then
		self.Name = self.AST:ToString ()
	else
		GCompute.Error ("DeferredObjectResolution constructed with an unknown object.")
	end
	
	local compilerMessages = self.AST and self.AST:GetMessages ()
	if compilerMessages then
		ErrorNoHalt ("In \"" .. (self.Name or self.AST:ToString ()) .. "\":\n" .. compilerMessages:ToString () .. "\n")
	end
end

function self:ComputeMemoryUsage (memoryUsageReport, poolName)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure (poolName or "Deferred Object Resolutions", self)
	memoryUsageReport:CreditString (poolName or "Deferred Object Resolutions", self.Name)
	
	if self.AST then
		self.AST:ComputeMemoryUsage (memoryUsageReport)
	end
	
	return memoryUsageReport
end

function self:GetAST ()
	return self.AST
end

function self:GetCorrespondingDefinition (globalNamespace, typeSystem)
	GCompute.Error ("DeferredObjectResolution:GetCorrespondingDefinition : This should never be called (" .. self:GetFullName () .. ")!")
end

function self:GetDesiredObjectType ()
	return self.DesiredObjectType
end

function self:GetFullName ()
	return self:ToString ()
end

function self:GetGlobalNamespace ()
	return self.GlobalNamespace
end

function self:GetObject ()
	if not self:IsResolved () then
		GCompute.Error ("DeferredObjectResolution:GetObject : " .. self.AST:ToString () .. " has not been resolved yet.")
	end
	return self.Object
end

function self:GetLocalNamespace ()
	return self.LocalNamespace
end

function self:GetName ()
	return self.Name
end

function self:GetRelativeName (referenceDefinition)
	return self:GetFullName ()
end

function self:IsDeferredObjectResolution ()
	return true
end

function self:IsFailedResolution ()
	return self.ResolutionFailed
end

function self:IsResolved ()
	return self.Resolved
end

function self:Resolve ()
	if self.Resolved then
		return self.Object
	end
	
	GCompute.ObjectResolver:ResolveASTNode (self.AST, true, self.GlobalNamespace, self.LocalNamespace)
	
	local results = self.AST:GetResolutionResults ()
	results:FilterByType (self.DesiredObjectType)
	results:FilterByLocality ()
	
	if results:GetFilteredResultCount () == 0 then
		self.AST:AddErrorMessage ("Cannnot resolve " .. self.AST:ToString () .. " - no suitable matches found.\n" .. results:ToString ())
		
		self.Resolved = true
		self.ResolutionFailed = true
	elseif results:GetFilteredResultCount () > 1 then
		self.AST:AddErrorMessage ("Cannnot resolve " .. self.AST:ToString () .. " - too many matches found.\n" .. results:ToString ())
		
		self.Resolved = true
		self.ResolutionFailed = true
	else
		self.Object = results:GetFilteredResult (1):GetObject ()
		
		self.Resolved = true
	end
	
	return self.Object
end

function self:SetGlobalNamespace (globalNamespace)
	self.GlobalNamespace = globalNamespace
end

function self:SetLocalNamespace (localNamespace)
	self.LocalNamespace = localNamespace
end

function self:ToString ()
	if self.ResolutionFailed then
		return "[Unresolvable] " .. self.Name
	elseif not self:IsResolved () then
		return "[Unresolved] " .. self.Name
	end
	return "[Resolved] " .. self.Object:GetFullName ()
end