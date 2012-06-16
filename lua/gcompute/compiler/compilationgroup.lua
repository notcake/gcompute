local self = {}
GCompute.CompilationGroup = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SourceFiles = {}
	self.SourceFileCount = 0
	
	self.NamespaceDefinition = GCompute.MergedNamespaceDefinition ()
end

-- Source Files
function self:AddSourceFile (sourceFile, languageName)
	languageName = languageName or "Derpscript"

	self.SourceFileCount = self.SourceFileCount + 1
	self.SourceFiles [self.SourceFileCount] = sourceFile
	
	local compilationUnit = sourceFile:GetCompilationUnit ()
	if not compilationUnit then
		compilationUnit = GCompute.CompilationUnit (sourceFile, languageName)
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
function self:Compile (callback)
	callback = callback or GCompute.NullCallback

	local actionChain = GCompute.CallbackChain ()
	for sourceFile in self:GetEnumerator () do
		local compilationUnit = sourceFile:GetCompilationUnit ()
		actionChain:Add (
			function (nextCallback)
				local actionChain = GCompute.CallbackChain ()
				actionChain:Add (function (callback) compilationUnit:Tokenize (callback) end)
				actionChain:Add (function (callback) compilationUnit:Preprocess (callback) end)
				actionChain:Add (function (callback) compilationUnit:GenerateParserJobs (callback) end)
				actionChain:Add (function (callback) compilationUnit:Parse (callback) end)
				actionChain:Add (function (callback) compilationUnit:PostParse (callback) end)
				actionChain:Add (function (callback) compilationUnit:BuildNamespace (callback) end)
				actionChain:AddUnwrap (nextCallback)
				actionChain:Execute ()
			end
		)
	end
	actionChain:Add (
		function (callback)
			self.NamespaceDefinition:AddSourceNamespace (GCompute.GlobalNamespace)
			for sourceFile in self:GetEnumerator () do
				self.NamespaceDefinition:AddSourceNamespace (sourceFile:GetCompilationUnit ():GetNamespaceDefinition ())
			end			
			callback ()
		end
	)
			
	for sourceFile in self:GetEnumerator () do
		local compilationUnit = sourceFile:GetCompilationUnit ()
		actionChain:Add (
			function (nextCallback)
				local actionChain = GCompute.CallbackChain ()
				--actionChain:Add (function (callback) compilationUnit:LookupNames (callback) end)
				actionChain:AddUnwrap (nextCallback)
				actionChain:Execute ()
			end
		)
	end
	
	actionChain:AddUnwrap (callback)
	actionChain:Execute ()
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