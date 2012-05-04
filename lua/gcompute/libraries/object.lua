local G = GCompute.GlobalScope
local T = G:AddType ("Object")
T:ClearBaseTypes ()
G:AddTypeReference ("object", "Object")

local F = nil

F = T:GetMembers ():AddMemberFunction ("GetHashCode", "int")
F.Native = function (executionContext, obj)
	return tonumber (util.CRC (tostring (obj)))
end

F = T:GetMembers ():AddMemberFunction ("GetType", "Type")
F.Native = function (executionContext, obj)
	return T
end

F = T:GetMembers ():AddMemberFunction ("ToString", "string")
F.Native = function (executionContext, obj)
	if type (obj) == "table" and type (obj.ToString) == "function" then
		return obj:ToString ()
	end
	return tostring (obj)
end