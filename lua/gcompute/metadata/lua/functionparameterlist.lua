local self = {}
GCompute.Lua.FunctionParameterList = GCompute.MakeConstructor (self, GCompute.ParameterList)

function self:ctor (_, f)
	self.Function = f
	
	local upvalueName, upvalue = debug.getupvalue (self.Function, 1)
	if upvalueName == "metatable" and
	   type (upvalue) == "table" and
	   type (upvalue.ctor) == "function" then
		f = upvalue.ctor
	end
	
	local info = debug.getinfo (f)
	for i = 1, info.nparams do
		local parameterName = debug.getlocal (f, i)
		if parameterName ~= "self" then
			self:AddParameter (nil, parameterName or "_")
		end
	end
	
	if info.isvararg then
		self:AddParameter (nil, "...")
	end
end

-- Internal, do not call
function self:GetName (functionName, ...)
	local parameterList = ""
	for i = 1, self.ParameterCount do
		if parameterList ~= "" then
			parameterList = parameterList .. ", "
		end
		local parameterType = self.ParameterTypes [i]
		local parameterName = self.ParameterNames [i]
		parameterType = parameterType and parameterType [functionName] (parameterType, ...)
		if parameterType then
			parameterList = parameterList .. parameterType .. " "
		end
		parameterList = parameterList .. parameterName
	end
	return "(" .. parameterList .. ")"
end