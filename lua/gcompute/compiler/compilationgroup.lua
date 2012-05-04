local self = {}
GCompute.CompilationGroup = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SourceFiles = {}
	self.SourceFileCount = 0
end

-- Source Files
function self:AddSourceFile (sourceFile)
	self.SourceFileCount = self.SourceFileCount + 1
	self.SourceFiles [self.SourceFileCount] = sourceFile
	
	local compilationUnit = sourceFile:GetCompilationUnit ()
	if not compilationUnit then
		compilationUnit = GCompute.CompilationUnit (sourceFile)
		sourceFile:SetCompilationUnit (compilationUnit)
	end
	
	return compilationUnit
end

function self:GetEnumerator ()
	local i = 0
	return function ()
		i = i + 1
		return self.SourceFiles [i]
	end
end

function self:GetSourceFile (index)
	return self.SourceFiles [index]
end

function self:GetSourceFileCount ()
	return self.SourceFileCount
end

-- Compilation
function self:Compile ()
	for sourceFile in self:GetEnumerator () do
		local compilationUnit = sourceFile:GetCompilationUnit ()
		compilationUnit:Tokenize ()
		compilationUnit:Preprocess ()
		compilationUnit:Parse ()
		compilationUnit:BuildAST ()
	end
end

function self:ToString ()
	local compilationGroup = "[CompilationGroup [" .. self:GetSourceFileCount () .. "]]"
	compilationGroup = compilationGroup .. "\n{"
	
	for sourceFile in self:GetEnumerator () do
		compilationGroup = compilationGroup .. "\n    " .. sourceFile:ToString ()
	end
	
	compilationGroup = compilationGroup .. "\n}"
	return compilationGroup
end