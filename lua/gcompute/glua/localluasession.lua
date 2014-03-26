local self = {}
GCompute.LocalLuaSession = GCompute.MakeConstructor (self)

function self:ctor ()
	self.G = {}
	setmetatable (self.G,
		{
			__index = function (self, key)
				if _G [key] ~= nil then return _G [key] end
				
				for _, v in ipairs (player.GetAll ()) do
					if GLib.UTF8.MatchTransliteration (v:Nick (), key) then
						return v
					end
				end
				
				return nil
			end,
			__newindex = function (self, key, value)
				_G [key] = value
			end
		}
	)
end

function self:dtor ()
end

function self:EvaluateExpression (sourceId, upvalues, expression, luaOutputSink)
	upvalues = upvalues or ""
	upvalues = string.gsub (upvalues, "[\r\n]", " ")
	luaOutputSink = luaOutputSink or GCompute.LuaOutputSink ()
end

function self:Execute (sourceId, upvalues, code, luaOutputSink)
	upvalues = upvalues or ""
	upvalues = string.gsub (upvalues, "[\r\n]", " ")
	luaOutputSink = luaOutputSink or GCompute.LuaOutputSink ()
	
	local outputUpvalues = ""
	outputUpvalues = outputUpvalues .. "local error       = error "
	outputUpvalues = outputUpvalues .. "local ErrorNoHalt = ErrorNoHalt "
	outputUpvalues = outputUpvalues .. "local Msg         = Msg "
	outputUpvalues = outputUpvalues .. "local MsgN        = MsgN "
	outputUpvalues = outputUpvalues .. "local MsgC        = MsgC "
	outputUpvalues = outputUpvalues .. "local print       = print "
	code = upvalues .. " " .. outputUpvalues .. " " .. code
	
	local f = CompileString (code, sourceId, false)
	if type (f) == "string" then
		luaOutputSink:SyntaxError (sourceId, f)
		return { Success = false }
	end
	
	local _error       = error
	local _ErrorNoHalt = ErrorNoHalt
	local _Msg         = Msg
	local _MsgN        = MsgN
	local _MsgC        = MsgC
	local _print       = print
	
	local function makeOutputter (outputFunction, separator)
		return function (...)
			local args = {...}
			for i = 1, table.maxn (args) do
				args [i] = tostring (args [i])
			end
			outputFunction (table.concat (args, separator))
		end
	end
	error = makeOutputter (
		function (text)
			-- luaOutputSink:Error (sourceId, GLib.GetLocalId (), text, GLib.Lua.StackTrace ())
			_error (text)
		end
	)
	ErrorNoHalt = makeOutputter (
		function (text)
			luaOutputSink:Error (sourceId, GLib.GetLocalId (), text, GLib.Lua.StackTrace ())
			_ErrorNoHalt (text)
		end
	)
	Msg = makeOutputter (
		function (text)
			luaOutputSink:Output (sourceId, GLib.GetLocalId (), text, GLib.Colors.SandyBrown)
		end
	)
	MsgN = makeOutputter (
		function (text)
			luaOutputSink:Output (sourceId, GLib.GetLocalId (), text .. "\n", GLib.Colors.SandyBrown)
		end
	)
	MsgC = function (color, ...)
		local args = {...}
		for i = 1, table.maxn (args) do
			args [i] = tostring (args [i])
		end
		
		luaOutputSink:Output (sourceId, GLib.GetLocalId (),
			table.concat (args),
			type (color) == "table" and
			type (color.r) == "number" and
			type (color.g) == "number" and
			type (color.b) == "number" and
			type (color.a) == "number" and
			color or GLib.Colors.White
		)
	end
	print = makeOutputter (
		function (text)
			luaOutputSink:Output (sourceId, GLib.GetLocalId (), text .. "\n", GLib.Colors.White)
		end,
		"\t"
	)
	
	local ret = {
		xpcall (f,
			function (message)
				luaOutputSink:Error (sourceId, GLib.GetLocalId (), message, GLib.Lua.StackTrace ())
				_ErrorNoHalt (message)
			end
		)
	}
	ret.Success = ret [1]
	table.remove (ret, 1)
	
	error       = _error
	ErrorNoHalt = _ErrorNoHalt
	Msg         = _Msg
	MsgN        = _MsgN
	MsgC        = _MsgC
	print       = _print
	
	return ret
end

-- Internal, do not call