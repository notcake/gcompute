local self = {}
GCompute.Module = GCompute.MakeConstructor (self)

function self:ctor (sourceFile)
	self.SourceFile = sourceFile
	self.CompilationUnit = self.SourceFile:GetCompilationUnit ()

	self.GlobalScope = GCompute.Scope ()
	self.GlobalScope:SetGlobalScope (self.GlobalScope)
end

function self:GetModuleScope ()
	return self.GlobalScope
end