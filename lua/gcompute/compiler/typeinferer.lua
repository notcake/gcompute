local self = {}
GCompute.TypeInferer = GCompute.MakeConstructor (self)

function self:ctor (compilationUnit)
	self.CompilationUnit = compilationUnit
end

function self:Process (blockStatement)
	
end