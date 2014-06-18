local self = {}
GCompute.UsingCollection = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Usings = {}
end

function self:AddUsing (qualifiedName)
	local usingDirective = GCompute.UsingDirective (qualifiedName)
	self.Usings [#self.Usings + 1] = usingDirective
	return usingDirective
end

function self:Clear ()
	self.Usings = {}
end

function self:GetEnumerator ()
	return GLib.ArrayEnumerator (self.Usings)
end

function self:GetUsing (index)
	return self.Usings [index]
end

function self:GetUsingCount ()
	return #self.Usings
end

function self:IsEmpty ()
	return #self.Usings == 0
end

function self:Resolve (objectResolver, compilerMessageSink)
	for usingDirective in self:GetEnumerator () do
		usingDirective:Resolve (objectResolver, compilerMessageSink)
	end
end

function self:ToString ()
	local usingCollection = "[Usings (" .. self:GetUsingCount () .. ")]"
	for usingDirective in self:GetEnumerator () do
		usingCollection = usingCollection .. "\n" .. usingDirective:ToString ()
	end
	return usingCollection
end