local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Array = Expression2:AddType ("array")
Array:SetNullable (false)
Array:SetNativelyAllocated (true)

Array:AddConstructor ({ { "object", "..." } })
	:SetNativeFunction (
		function (...)
			local array =
			{
				Values = {},
				Types  = {}
			}
			for _, object in ipairs ({...}) do
				array.Values [#array.Values + 1] = object:Unbox ()
				array.Types  [#array.Types  + 1] = object:GetType ()
			end
			return array
		end
	)

local inToString = {}

Array:AddFunction ("ToString")
	:SetReturnType ("string")
	:SetNativeFunction (
		function (self)
			if inToString [self] then
				return "{array}"
			end
			
			inToString [self] = true
			
			local str = "[" .. #self.Values .. "] {"
			for i = 1, 16 do
				if i > #self.Values then break end
				if i > 1 then
					str = str .. ", "
				end
				str = str .. self.Types [i]:GetFunctionTable ().Virtual.ToString (self.Values [i])
			end
			str = str .. "}"
			
			inToString [self] = false
			
			return str
		end
	)

Array:AddFunction ("count")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (self)
			return #self.Values
		end
	)

Array:AddFunction ("pushNumber", { { "number", "val" } })
	:SetNativeFunction (
		function (self, val)
			self.Values [#self.Values + 1] = val
			self.Types  [#self.Types  + 1] = executionContext:GetRuntimeNamespace ().Expression2.number [".Type"]
		end
	)

Array:AddFunction ("operator[]", { { "number", "index" } }, { "T" })
	:SetReturnType ("T")
	:SetNativeString ("%self% [%arg:index%]")
	:SetTypeCurryerFunction (
		function (functionDefinition, typeArgumentList)
			functionDefinition:SetNativeFunction (
				function (self, index)
					local sourceType = self.Types [index]
					local destinationType = typeArgumentList:GetArgument (1):UnwrapAlias ()
					if not sourceType then
						return destinationType:CreateDefaultValue ()
					end
					if sourceType:Equals (destinationType) then
						return self.Values [index]
					end
					if destinationType:IsBaseTypeOf (sourceType) then
						return sourceType:RuntimeDowncastTo (destinationType, self.Values [index])
					end
					return destinationType:CreateDefaultValue ()
				end
			)
		end
	)

Array:AddFunction ("operator[]", { { "number", "index" }, { "T", "val" } }, { "T" })
	:SetReturnType ("T")
	:SetNativeString ("%self% [%arg:index%] = %arg:val%")
	:SetTypeCurryerFunction (
		function (functionDefinition, typeArgumentList)
			if typeArgumentList:GetArgument (1):UnwrapAlias ():IsNativelyAllocated () then
				functionDefinition:SetNativeFunction (
					function (self, index, value)
						self.Types [index] = typeArgumentList:GetArgument (1)
						self.Values [index] = value
					end
				)
			else
				functionDefinition:SetNativeFunction (
					function (self, index, value)
						self.Types [index] = value:GetType ()
						self.Values [index] = typeArgumentList:GetArgument (1):RuntimeUpcastTo (value:GetType (), value)
					end
				)
			end
		end
	)