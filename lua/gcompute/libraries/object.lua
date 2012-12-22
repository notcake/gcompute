local Global = GCompute.GlobalNamespace
local Object = Global:AddClass ("Object")
Object:GetClassType ():SetTop (true)
GCompute.TypeSystem:SetObject (Object)

Object:AddMethod ("GetHashCode")
	:SetReturnType ("int")
	:SetNativeFunction (
		function (self)
			return tonumber (util.CRC (tostring (self)))
		end
	)

Object:AddMethod ("GetType")
	:SetReturnType ("Type")
	:SetNativeFunction (
		function (self)
			return self:GetType ()
		end
	)

Object:AddMethod ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			return "{" .. self:GetType ():GetFullName () .. "}"
		end
	)

Object:AddMethod ("operator==", "Object other")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, other)
			return self == other
		end
	)
	
Object:AddMethod ("operator!=", "Object other")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, other)
			return self ~= other
		end
	)