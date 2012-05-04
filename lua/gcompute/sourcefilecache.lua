local self = {}
GCompute.SourceFileCache = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SourceFiles = {}
end

GCompute.SourceFileCache = GCompute.SourceFileCache ()