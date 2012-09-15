local self = {}
GCompute.Pipe = GCompute.MakeConstructor (self)

function self:ctor ()
	GCompute.EventProvider (self)
end

function self:Chain (pipe)
	pipe:AddEventListener ("Data", tostring (self),
		function (_, data)
			self:DispatchEvent ("Data", data)
		end
	)
end

function self:Unchain (pipe)
	pipe:RemoveEventListener ("Data", tostring (self))
end

function self:Write (data)
	self:DispatchEvent ("Data", data)
end

function self:WriteLine (data)
	self:DispatchEvent ("Data", data .. "\n")
end