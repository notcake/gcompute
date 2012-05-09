local self = {}
VFS.Path = VFS.MakeConstructor (self)

function self:ctor (path)
	if type (path) == "table" then
		self.Path = path.Path
		self.Segments = table.Copy (path.Segments)
	elseif type (path) == "string" then
		path = path:gsub ("\\", "/")
		path = path:gsub ("//+", "/")
		
		self.Path = path
		if self.Path == "" then
			self.Segments = {}
		else
			self.Segments = self.Path:Split ("/")
		end
	else
		VFS.Error ("Path:ctor : Invalid argument passed to constructor")
	end
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.Segments [i]
	end
end

function self:GetPathString ()
	return self.Path
end

function self:GetSegment (index)
	return self.Segments [index + 1]
end

function self:GetSegmentCount ()
	return #self.Segments
end

function self:IsEmpty ()
	return self:GetSegmentCount () == 0
end

function self:RemoveFirstSegment ()
	local i = 1
	local segment = self.Segments [1]
	self.Path = self.Path:sub (segment:len () + 2)
	while self.Segments [i] do
		self.Segments [i] = self.Segments [i + 1]
		i = i + 1
	end
end

function self:ToString ()
	return self.Path
end