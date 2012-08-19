local Global = GCompute.GlobalNamespace
local Object = Global:AddType ("Object")

GCompute.Types.Top = Object
GCompute.Types.Object = Object
GCompute.Types.Namespace = Object

function Object:IsTop ()
	return true
end

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
			return Object
		end
	)
	
Object:AddFunction ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			if type (self) == "table" and type (self.ToString) == "function" then
				return self:ToString ()
			end
			return tostring (self)
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