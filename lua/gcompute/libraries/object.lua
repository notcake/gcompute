local Global = GCompute.GlobalNamespace
local Object = Global:AddType ("Object")
Object:SetIsTop (true)

Global:GetTypeSystem ():SetObject (Object)

Object:AddFunction ("GetHashCode")
	:SetReturnType ("int")
	:SetNativeFunction (
		function (self)
			return tonumber (util.CRC (tostring (self)))
		end
	)

Object:AddFunction ("GetType")
	:SetReturnType ("Type")
	:SetNativeFunction (
		function (self)
			return self:GetType ()
		end
	)

Object:AddFunction ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			return "{Object}"
		end
	)

Object:AddFunction ("operator==", { { "Object", "other" } })
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, other)
			return self == other
		end
	)
	
Object:AddFunction ("operator!=", { { "Object", "other" } })
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self, other)
			return self ~= other
		end
	)