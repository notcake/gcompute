local Global = GCompute.GlobalNamespace
local Object = Global:AddType ("Object")

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