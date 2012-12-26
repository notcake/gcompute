local Global = GCompute.GlobalNamespace
local Interop = Global:AddNamespace ("Interop")
local LuaEnumerator = Global:AddClass ("LuaEnumerator", "T")
	:AddBaseType ("IEnumerator<T>")

LuaEnumerator:AddConstructor ("object iterator")
	:SetNativeFunction (
		function (self, iterator)
			self._.Current  = self:GetType ():GetTypeArgument (1):CreateDefaultValue ()
			self._.Iterator = iterator
		end
	)

LuaEnumerator:AddProperty ("Current", "T")
	:AddGetter ()
		:SetNativeFunction (
			function (self)
				return self._.Current
			end
		)

LuaEnumerator:AddMethod ("MoveNext")
	:SetReturnType ("bool")
	:SetNativeFunction (
		function (self)
			self._.Current = self._.Iterator ()
			return self._.Current ~= nil
		end
	)

LuaEnumerator:AddMethod ("Reset")
	:SetNativeFunction (
		function (self)
			-- Nope.mkv
			executionContext:Throw (__.NotImplementedException ())
		end
	)