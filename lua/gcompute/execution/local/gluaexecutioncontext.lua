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
		
		if ownerId == self:GetHostId () then
			self.Environment.PROPERTY = function (a, ...)
				local code = GLib.StringBuilder ()
				
				local propertyNames
				if istable (a) then
					propertyNames = a
				else
					propertyNames = { a, ... }
				end
				
				for _, propertyName in ipairs (propertyNames) do
					code:Append ("function self:Get" .. propertyName .. " ()\r\n")
					code:Append ("\treturn self." .. propertyName .. "\r\n")
					code:Append ("end\r\n")
					code:Append ("\r\n")
				end
				for _, propertyName in ipairs (propertyNames) do
					local variableName = string.lower (string.sub (propertyName, 1, 1)) .. string.sub (propertyName, 2)
					code:Append ("function self:Set" .. propertyName .. " (" .. variableName .. ")\r\n")
					code:Append ("\tif self." .. propertyName .. " == " .. variableName .. " then return self end\r\n")
					code:Append ("\t\r\n")
					code:Append ("\tself." .. propertyName .. " = " .. variableName .. "\r\n")
					code:Append ("\t\r\n")
					code:Append ("\tself:DispatchEvent (\"" .. propertyName .. "Changed\", self." .. propertyName .. ")\r\n")
					code:Append ("\t\r\n")
					code:Append ("\treturn self\r\n")
					code:Append ("end\r\n")
					code:Append ("\r\n")
				end
				
				code = code:ToString ()
				
				MsgN ("Code copied to clipboard.")
				SetClipboardText (code)
				
				return code
			end
		end
		
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