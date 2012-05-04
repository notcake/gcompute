local self = {}
GCompute.SourceFile = GCompute.MakeConstructor (self)

function self:ctor ()
	self.Path = nil
	
	self.Code = ""
	self.CodeHash = 0
	
	self.CompilationUnit = nil
	
	self.Cacheable = true
end

function self:CanCache ()
	return self.Cacheable
end

function self:ComputeCodeHash ()
	self.CodeHash = tonumber (util.CRC (self.Code))
end

function self:GetCode ()
	return self.Code
end

function self:GetCodeHash ()
	return self.CodeHash
end

function self:GetCompilationUnit ()
	return self.CompilationUnit
end

function self:SetCompilationUnit (compilationUnit)
	self.CompilationUnit = compilationUnit
end