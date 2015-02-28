local self = {}
GCompute.Execution.RemoteExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

--[[
	Events:
		CanCreateExecutionContext (authId, hostId, languageName)
			Fired when an execution context is about to be created.
		ExecutionContextCreated (IExecutionContext executionContext)
			Fired when an execution context has been created.
			
]]

function self:ctor ()
	GCompute.EventProvider (self)
end

-- IExecutionService
function self:CanCreateExecutionContext (authId, hostId, languageName)
	if not self:GetRemoteExecutionService () then return nil, GCompute.ReturnCode.NoCarrier end
	
	local allowed, denialReason = self:GetRemoteExecutionService ():CanCreateExecutionContext (authId, hostId, languageName)
	if not allowed then return false, denialReason end
	
	-- CanCreateExecutionContext event
	allowed, denialReason = self:DispatchEvent ("CanCreateExecutionContext", authId, hostId, languageName)
	if allowed == false then return false, denialReason end
	
	return true
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if not self:GetRemoteExecutionService () then return false, GCompute.ReturnCode.NoCarrier end
	
	local executionContext, denialReason = self:GetRemoteExecutionService ():CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	
	-- ExecutionContextCreated event
	if executionContext then
		self:DispatchEvent ("ExecutionContextCreated", executionContext)
	end
	
	return executionContext, denialReason
end

function self:GetHostEnumerator ()
	if not self:GetRemoteExecutionService () then return GLib.NullEnumerator () end
	return self:GetRemoteExecutionService ():GetHostEnumerator ()
end

function self:GetLanguageEnumerator ()
	if not self:GetRemoteExecutionService () then return GLib.NullEnumerator () end
	return self:GetRemoteExecutionService ():GetLanguageEnumerator ()
end

-- RemoteExecutionService
function self:GetRemoteExecutionService ()
	if GCompute.Execution.GComputeRemoteExecutionService:IsAvailable () then
		return GCompute.Execution.GComputeRemoteExecutionService
	elseif GCompute.Execution.LuadevExecutionService:IsAvailable () then
		return GCompute.Execution.LuadevExecutionService
	end
	
	return nil
end

function self:IsAvailable ()
	return self:GetRemoteExecutionService () ~= nil
end

GCompute.Execution.RemoteExecutionService = GCompute.Execution.RemoteExecutionService ()