local self = {}
GCompute.Other.Expression2Namespace = GCompute.MakeConstructor (self, GCompute.NamespaceDefinition)

local operatorMap =
{
	["op:ass"]  = "operator=",
	["op:idx"]  = "operator[]",
	
	["op:eq"]   = "operator==",
	["op:neq"]  = "operator!=",
	["op:geq"]  = "operator>=",
	["op:gth"]  = "operator>",
	["op:leq"]  = "operator<=",
	["op:lth"]  = "operator<",
	
	["op:add"]  = "operator+",
	["op:sub"]  = "operator-",
	["op:neg"]  = "operator-",
	["op:mul"]  = "operator*",
	["op:div"]  = "operator/",
	["op:exp"]  = "operator^",
	["op:mod"]  = "operator%",
	
	["op:and"]  = "operator&&",
	["op:or"]   = "operator||",
	
	["op:not"]  = "operator!",
	["op:band"] = "operator&",
	["op:bor"]  = "operator&",
	["op:bshl"] = "operator<<",
	["op:bshr"] = "operator>>",
	["op:bxor"] = "operator^",
	
	["op:inc"]  = "operator++",
	["op:dec"]  = "operator--",
}

function self:ctor ()
	if not wire_expression_types then return end
	if not wire_expression2_funcs then return end
	
	-- Types
	local types = {}
	for name, data in pairs (wire_expression_types) do
		types [data [1]] = self:AddClass (name:lower ())
	end
	
	local objectType = GCompute.GlobalNamespace:GetMember ("object"):ToType ()
	local voidType = GCompute.GlobalNamespace:GetMember ("void"):ToType ()
	
	-- Functions
	for name, data in pairs (wire_expression2_funcs) do
		local returnType = types [data [2]] and types [data [2]]:GetClassType () or voidType
		local methodName, parameters = string.match (name, "([^%(]*)%(([^%)]*)%)")
		methodName = operatorMap [methodName] or methodName
		
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
				parameterList:AddParameter (objectType, "...")
			else
				local parameterName = nil
				parameterName = data.argnames and data.argnames [i + (class ~= self and 1 or 0)]
				parameterList:AddParameter (types [match] and types [match]:GetClassType () or variantType or objectType, parameterName)
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