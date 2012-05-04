local G = GCompute.GlobalScope

local Number = G:AddType ("Number")
	:SetInheritable (false)
	:SetPrimitiveType (true)
	:SetScopeType (false)

local Integer = G:AddType ("Integer")
	:SetInheritable (false)
	:SetPrimitiveType (true)
	:SetScopeType (false)

G:AddTypeReference ("float", "Number")
G:AddTypeReference ("int", "Integer")

local F = nil

-- Integers
F = Integer:GetMembers ():AddMemberFunction ("GetHashCode", "int")
F.Native = function (executionContext, n)
	return n
end

F = Integer:GetMembers ():AddMemberFunction ("ToHex", "string")
F.Native = function (executionContext, n)
	return string.format ("%x", n)
end

-- Floats

-- Native
GCompute.Number = GCompute.Number or {}
GCompute.Number.ToHex = function (n)
	return string.format ("%x", n)
end