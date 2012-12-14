local self = {}
GCompute.SubstitutionMap = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Map = {}
end

function self:Add (object, replacement)
	self.Map [object] = replacement
end

function self:Contains (object)
	return self.Map [object] or nil
end

function self:GetReplacement (object)
	return self.Map [object]
end