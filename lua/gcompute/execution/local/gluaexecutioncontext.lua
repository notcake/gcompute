local self = {}
GCompute.Execution.GLuaExecutionContext = GCompute.MakeConstructor (self, GCompute.Execution.LocalExecutionContext)

function self:ctor (ownerId, contextOptions)
	local globalEnvironment = debug.getfenv (function () end)
	self.Environment = globalEnvironment
	
	if self:IsEasyContext () then
		self.Environment = {}
		
		-- Metatables
		self.Environment._R = debug.getregistry ()
		
		-- IEEE floating point
		self.Environment.inf = math.huge
		self.Environment.nan = 0 / 0
		
		debug.setmetatable (self.Environment,
			{
				__index = function (self, key)
					local v = rawget (self, key) or globalEnvironment [key]
					if v ~= nil then return v end
					
					-- Entity ID match
					local entIndex = string.match (key, "^_([0-9]+)$")
					if entIndex then return Entity (entIndex) end
					
					-- Player name match
					for _, v in ipairs (player.GetAll ()) do
						if GLib.UTF8.MatchTransliteration (v:Nick (), key) then
							return v
						end
					end
				end,
				__newindex = function (self, key, value)
					globalEnvironment [key] = value
				end
			}
		)
	end
end

-- ExecutionContext
function self:GetExecutionInstanceConstructor  ()
	return GCompute.Execution.GLuaExecutionInstance
end

-- GLuaExecutionContext
function self:GetEnvironment ()
	return self.Environment
end