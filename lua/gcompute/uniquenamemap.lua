local self = {}
GCompute.UniqueNameMap = GCompute.MakeConstructor (self)

function self:ctor ()
	self.NameMap = GCompute.WeakKeyTable ()
	self.UsedNames = {}
end

function self:AddObject (object)
	if self.NameMap [object] then return end
	
	local baseName = object:GetName ()
	
	if not self.UsedNames [baseName] then
		self.NameMap [object] = baseName
		self.UsedNames [baseName] = true
	else
		local i = 0
		while true do
			if not self.UsedNames [baseName .. "_" .. tostring (i)] then
				self.NameMap [object] = baseName .. "_" .. tostring (i)
				self.UsedNames [baseName .. "_" .. tostring (i)] = true
			end
		end
	end
end

function self:GetObjectName (object)
	if not self.NameMap [object] then
		self:AddObject (object)
	end
	
	return self.NameMap [object]
end

function self:ReserveName (name)
	self.UsedNames [name] = true
end