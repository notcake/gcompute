local self = {}
GCompute.Pipe = GCompute.MakeConstructor (self)

function self:ctor ()
	GCompute.EventProvider (self)
end

function self:Chain (pipe)
	pipe:AddEventListener ("Data", self:GetHashCode (),
		function (_, data, color)
			self:DispatchEvent ("Data", data, color)
		end
	)
end

function self:Unchain (pipe)
	pipe:RemoveEventListener ("Data", self:GetHashCode ())
end

function self:Write (data)
	data = data or ""
	self:DispatchEvent ("Data", data, nil)
end

function self:WriteColor (data, color)
	data = data or ""
	self:DispatchEvent ("Data", data, color)
end

function self:WriteLine (data)
	data = data or ""
	self:DispatchEvent ("Data", data .. "\n", nil)
end