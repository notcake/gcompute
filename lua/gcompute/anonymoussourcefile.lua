local self = {}
GCompute.AnonymousSourceFile = GCompute.MakeConstructor (self, GCompute.SourceFile)

local nextAnonymousId = 0

function self:ctor (code)
	self.Path = "@dynamic_" .. tostring (nextAnonymousId)
	nextAnonymousId = nextAnonymousId + 1
	
	self.Code = code
	self:ComputeCodeHash ()
end