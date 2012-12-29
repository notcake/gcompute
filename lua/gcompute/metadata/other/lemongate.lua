local self = {}
GCompute.Other.LemonGateNamespace = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition)

function self:ctor ()
	if not LemonGate then return end
	
	local language = GCompute.Languages.Get ("Lemon Gate")
	if not language:IsDataAvailable () then
		language:RequestData (self)
		return
	end
	
	self:ImportData ()
end

-- Internal, do not call
function self:ImportData ()
	-- Types
	local types = {}
	for name, data in pairs (LemonGate.TypeTable) do
		types [data [2]] = self:AddClass (name)
	end
	
	-- Set up inheritance
	local variant = self:GetMember ("variant")
	local variantType = nil
	variant = variant and variant:GetClass (1)
	if variant then
		variantType = variant:GetClassType ()
		for _, class in pairs (types) do
			if class ~= variant then
				class:AddBaseType (variantType)
			end
		end
	end
	
	local objectType = GCompute.GlobalNamespace:GetMember ("object"):ToType ()
	local voidType = GCompute.GlobalNamespace:GetMember ("void"):ToType ()
	
	-- Functions
	for name, data in pairs (LemonGate.FunctionTable) do
		local returnType = types [data [2]] and types [data [2]]:GetClassType () or voidType
		local methodName, parameters = string.match (name, "([^%(]*)%(([^%)]*)%)")
		
		local class = self
		if parameters:find (":") then
			class = types [parameters:sub (1, parameters:find (":") - 1)]
			parameters = parameters:sub (parameters:find (":") + 1)
		end
		
		local parameterList = GCompute.ParameterList ()
		local i = 1
		while i <= #parameters do
			local match = nil
			for j = 3, 1, -1 do
				local typeId = parameters:sub (i, i + j - 1)
				if types [typeId] or typeId == "..." then
					match = typeId
					break
				end
			end
			match = match or parameters:sub (i, i)
			if match == "..." then
				parameterList:AddParameter (variantType or objectType, "...")
			else
				parameterList:AddParameter (types [match] and types [match]:GetClassType () or variantType or objectType)
			end
			i = i + #match
		end
		
		if class == self and self:GetMember (methodName) and self:GetMember (methodName):IsOverloadedClass () then
			self:GetMember (methodName):GetClass (1)
				:AddConstructor (parameterList)
		else
			class:GetNamespace ():AddMethod (methodName, parameterList)
				:SetReturnType (returnType)
		end
	end
end