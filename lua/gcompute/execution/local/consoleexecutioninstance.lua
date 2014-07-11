local self = {}
GCompute.Execution.ConsoleExecutionInstance = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionInstance)

--[[
	Events:
		CanStartExecution ()
			Fired when this instance is about to start execution.
		StateChanged (state)
			Fired when this instance's state has changed.
]]

function self:ctor (consoleExecutionContext, instanceOptions)
end

-- Control
function self:Compile ()
	if self:IsCompiling () then return end
	if self:IsCompiled  () then return end
	
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiling)
	self:SetState (GCompute.Execution.ExecutionInstanceState.Compiled)
end

function self:Start ()
	if self:IsStarted    () then return end
	if self:IsTerminated () then return end
	
	-- CanStartExecution event
	if self:DispatchEvent ("CanStartExecution") == false then return end
	
	if not self:IsCompiled () then
		self:Compile ()
	end
	
	-- Run the code
	self:SetState (GCompute.Execution.ExecutionInstanceState.Running)
	
	for _, commands in self:GetSourceFileEnumerator () do
		if SERVER then
			game.ConsoleCommand (commands .. "\n")
		elseif CLIENT then
			LocalPlayer ():ConCommand (commands)
		end
	end
end