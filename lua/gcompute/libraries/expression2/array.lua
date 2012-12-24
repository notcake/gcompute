local Expression2 = GCompute.GlobalNamespace:AddNamespace ("Expression2")
local Array = Expression2:AddClass ("array")
Array:SetNullable (false)
Array:SetNativelyAllocated (true)

Array:AddConstructor ("object ...")
	:SetNativeFunction (
		function (...)
			local array = GCompute.Expression2.CreateContainer ()
			for _, object in ipairs ({...}) do
				array.Values [#array.Values + 1] = object:Unbox ()
				array.Types  [#array.Types  + 1] = object:GetType ()
			end
			return array
		end
	)

Array:AddMethod ("clear")
	:SetNativeString ("%self%:Clear ()")
	:SetNativeFunction (
		function (self)
			self:Clear ()
		end
	)

Array:AddMethod ("count")
	:SetReturnType ("number")
	:SetNativeFunction (
		function (self)
			return #self.Values
		end
	)

local methodTypes =
{
	"string",
	"number",
	"vector"
}

for _, typeName in ipairs (methodTypes) do
	Array:AddMethod ("push" .. string.sub (typeName, 1, 1):upper () .. string.sub (typeName, 2), typeName .. " val")
		:SetNativeFunction (
			function (self, val)
				self.Values [#self.Values + 1] = val
				self.Types  [#self.Types  + 1] = executionContext:GetEnvironment ().Expression2 [typeName] [".Type"]
			end
		)
end

GCompute.Expression2.AddContainerIndexer (Array, "number")

Array:AddMethod ("ToString")
	:SetReturnType ("String")
	:SetNativeFunction (
		function (self)
			local tls = executionContext:GetThreadLocalStorage ()
			local inToString = tls.Expression2.InToString
			
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