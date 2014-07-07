local self = {}
GCompute.Execution.LuadevExecutionInstance = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionInstance)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor (luadevExecutionContext, instanceOptions)
end

-- Control
function self:Compile ()
	if self:IsCompiling () then return end
	if self:IsCompiled  () then return end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiling)
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiled )
end

function self:Start ()
	if self:IsStarted    () then return end
	if self:IsTerminated () then return end
	
	-- CanStartExecution event
	if not self:DispatchEvent ("CanStartExecution") == false then return end
	
	if not self:IsCompiled () then
		self:Compile ()
	end
	
	-- Run the code
	self:Run (self:GetHostId ())
end

-- Internal, do not call
function self:Run (hostId)
	-- Owner
	local ownerId = self:GetOwnerId ()
	local owner = GCompute.PlayerMonitor:GetUserEntity (ownerId)
	if owner and not owner:IsValid () then owner = nil end
	
	if istable (hostId) then
		-- Array of hosts
		local hosts = {}
		
		-- Convert to array of players
		for _, hostId in ipairs (hostId) do
			local host = GCompute.PlayerMonitor:GetUserEntity (hostId)
			if not host or not host:IsValid () then
				-- Not a player, pass it through again
				self:Run (hostId)
			else
				hosts [#hosts + 1] = host
			end
		end
		
		if #hosts == 0 then return end
		
		local info =
		{
			target = "clients",
			ply    = owner
		}
		self:CallWithSources (luadev.RunInternal, info, hosts)
	end
	
	local hostId = self:GetHostId ()
	if hostId == "Server" then
		-- Server
		self:CallWithSources (luadev.RunOnServer, nil, owner)
	elseif hostId == "Clients" then
		-- All clients
		self:CallWithSources (luadev.RunOnClients, nil, owner)
	elseif hostId == "Shared" then
		-- Server and all clients
		self:CallWithSources (luadev.RunOnShared, nil, owner)
	else
		-- Single client
		local host = GCompute.PlayerMonitor:GetUserEntity (hostId)
		if not host or not host:IsValid () then return end
		
		self:CallWithSources (luadev.RunOnClient, nil, host, owner)
	end
end

function self:CallWithSources (f, ...)
	for _, code in self:GetSourceFileEnumerator () do
		f (code, ...)
	end
end