local self = {}
GCompute.GLua.LuaCompiler = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Upvalues = {}
	self.UpvalueHeader = nil
end

function self:AddUpvalue (name, value)
	if not GLib.Lua.IsValidVariableName (name) then
		GCompute.Error ("LuaCompiler:AddUpValue : " .. name .. " is not a valid identifier!")
		return
	end
	
	if self.Upvalues [name] == nil then
		self.UpvalueHeader = nil
	end
	self.Upvalues [name] = value
end

function self:GetUpvalueEnumerator ()
	return GLib.KeyValueEnumerator (self.Upvalues)
end

function self:Compile (code, sourceId)
	local fullCode = self:GetUpvalueHeader () .. " return function () " .. code .. "\nend"
	
	local functionFactory = CompileString (fullCode, sourceId, false)
	
	if type (functionFactory) == "string" then
		return nil, functionFactory
	end
	
	local _upvalues = upvalues
	upvalues = self.Upvalues
	local f = functionFactory ()
	upvalues = _upvalues
	
	if not f then
		return nil, "IMPOSSIBRU"
	end
	
	return f
end

-- Internal, do not call
function self:GetUpvalueHeader ()
	if not self.UpvalueHeader then
		local upvalueItems = {}
		for upvalueName, _ in pairs (self.Upvalues) do
			upvalueItems [#upvalueItems + 1] = "local " .. upvalueName .. " = upvalues." .. upvalueName
		end
		
		self.UpvalueHeader = table.concat (upvalueItems, " ")
	end
	
	return self.UpvalueHeader
end