local self = {}
GCompute.Expression2.Container = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Values = {}
	self.Types  = {}
end

function self:Clear ()
	self.Values = {}
	self.Types  = {}
end

function self:Clone ()
	local container = GCompute.Expression2.Container ()
	for k, v in pairs (self.Types) do
		container.Values [k] = self.Values [k]
		container.Types  [k] = v
	end
	return container
end

function self:Get (index, destinationType)
	local sourceType      = self.Types [index]
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

function self:Remove (index)
	if index < 1 or math.floor (index) ~= index then
		self.Values [index] = nil
		self.Types  [index] = nil
		return
	end
	for i = index, #self.Types - 1 do
		self.Values [i] = self.Values [i + 1]
	end
	table.remove (self.Types, index)
end