GCompute.Expression2 = {}
local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")

GCompute:AddEventListener ("ThreadCreated",
	function (_, process, thread)
		local tls = thread:GetThreadLocalStorage ()
		tls.Expression2 = tls.Expression2 or {}
		tls.Expression2.InToString = {}
	end
)

function GCompute.Expression2.CreateContainer ()
	return GCompute.Expression2.Container ()
end

function GCompute.Expression2.AddContainerIndexer (classDefinition, keyType)
	keyType = keyType or "number"
	
	classDefinition:AddMethod ("operator[]", keyType .. " index", { "T" })
		:SetReturnType ("T")
		:SetNativeString ("%self% [%arg:index%]")
		:SetTypeCurryerFunction (
			function (methodDefinition, typeArgumentList)
				methodDefinition:SetNativeFunction (
					function (self, index)
						local sourceType      = self.Types [index]
						local destinationType = typeArgumentList:GetArgument (1)
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

	classDefinition:AddMethod ("operator[]", keyType .. " index, T val", { "T" })
		:SetReturnType ("T")
		:SetNativeString ("%self% [%arg:index%] = %arg:val%")
		:SetTypeCurryerFunction (
			function (methodDefinition, typeArgumentList)
				if typeArgumentList:GetArgument (1):IsNativelyAllocated () then
					methodDefinition:SetNativeFunction (
						function (self, index, value)
							self.Types [index] = typeArgumentList:GetArgument (1)
							self.Values [index] = value
							return value
						end
					)
				else
					methodDefinition:SetNativeFunction (
						function (self, index, value)
							self.Types [index] = value:GetType ()
							self.Values [index] = typeArgumentList:GetArgument (1):RuntimeUpcastTo (value:GetType (), value)
							return value
						end
					)
				end
			end
		)
end