local Type = {}
Type.__index = Type
setmetatable (Type, GCompute._Scope)

function GCompute.Type (...)
	local Object = {}
	setmetatable (Object, Type)
	Object:ctor (...)
	return Object
end

function Type:ctor (Name)
	GCompute._Scope.ctor (self)
	self.Name = Name
	
	self.NativeGenerator = nil
	self.NativeString = nil
	self.NativeStringGenerator = nil
	
	self.ArgumentCount = 0
	self.Arguments = {}
end

function Type:AddArgument (Name)
	self.ArgumentCount = self.ArgumentCount + 1
	self.Arguments [#self.Arguments + 1] = Name
end

function Type:CanCompileNative ()
	if self.NativeString or
		self.NativeStringGenerator then
		return true
	end
	return false
end

function Type:GetNativeFunction (Node)
	if self.NativeGenerator then
		return self.NativeGenerator (Node)
	end
	return nil
end

function Type:GetNativeString (Node)
	if self.NativeStringGenerator then
		return self.NativeStringGenerator (Node)
	end
	if self.NativeString then
		return self.NativeString:gsub ("%1%", Node.Value)
	end
	return nil
end