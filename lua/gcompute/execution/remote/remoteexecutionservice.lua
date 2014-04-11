local self = {}
GCompute.Execution.RemoteExecutionService = GCompute.MakeConstructor (self, GCompute.Execution.IExecutionService)

function self:ctor ()
end

function self:CanCreateExecutionContext (authId, hostId, languageName)
	if not self:GetRemoteExecutionService () then return nil, GCompute.ReturnCode.NoCarrier end
	
	return self:GetRemoteExecutionService ():CanCreateExecutionContext (authId, hostId, languageName)
end

function self:CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
	if not self:GetRemoteExecutionService () then return nil, GCompute.ReturnCode.NoCarrier end
	
	return self:GetRemoteExecutionService ():CreateExecutionContext (authId, hostId, languageName, contextOptions, callback)
end

function self:GetHostEnumerator ()
	if not self:GetRemoteExecutionService () then return GLib.NullEnumerator () end
	return self:GetRemoteExecutionService ():GetHostEnumerator ()
end

function self:GetLanguageEnumerator ()
	if not self:GetRemoteExecutionService () then return GLib.NullEnumerator () end
	return self:GetRemoteExecutionService ():GetLanguageEnumerator ()
end

-- Internal, do not call
function self:GetRemoteExecutionService ()
	if GCompute.Execution.GComputeRemoteExecutionService:IsAvailable () then
		return GCompute.Execution.GComputeRemoteExecutionService
	elseif GCompute.Execution.LuadevExecutionService:IsAvailable () then
		return GCompute.Execution.LuadevExecutionService
	end
	
	return nil
end

GCompute.Execution.RemoteExecutionService = GCompute.Execution.RemoteExecutionService ()