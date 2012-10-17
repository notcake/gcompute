local self = {}
GCompute.CompilationGroup = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SourceFiles = {}
	self.SourceFileCount = 0
	
	self.NamespaceDefinition = GCompute.MergedNamespaceDefinition ()
	self.NamespaceDefinition:SetNamespaceType (GCompute.NamespaceType.Global)
	
	self.NameResolver = GCompute.NameResolver ()
end

-- Source Files
function self:AddSourceFile (sourceFile, languageName)
	self.SourceFileCount = self.SourceFileCount + 1
	self.SourceFiles [self.SourceFileCount] = sourceFile
	
	local compilationUnit = sourceFile:GetCompilationUnit ()
	if languageName then
		compilationUnit:SetLanguage (languageName)
	end
	compilationUnit:SetCompilationGroup (self)
	-- TODO: Fix bug where two CompilationGroups run simultaneously and use the same CompilationUnit
	
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

	local callbackChain = GCompute.CallbackChain ()
	for sourceFile in self:GetEnumerator () do
		local compilationUnit = sourceFile:GetCompilationUnit ()
		callbackChain:Then (
			function (callback, errorCallback)
				local callbackChain = GCompute.CallbackChain ()
				callbackChain:Then (function (callback, errorCallback) compilationUnit:Lex (callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:Preprocess (callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:GenerateParserJobs (callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:Parse (callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:PostParse (callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:RunPass ("BlockStatementInserter", GCompute.BlockStatementInserter, callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:BuildNamespace (callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:PostBuildNamespace (callback) end)
				callbackChain:ThenUnwrap (callback)
				callbackChain:Execute ()
			end
		)
	end
	callbackChain:Then (
		function (callback, errorCallback)
			self.NamespaceDefinition:AddSourceNamespace (GCompute.GlobalNamespace)
			for sourceFile in self:GetEnumerator () do
				self.NamespaceDefinition:AddSourceNamespace (sourceFile:GetCompilationUnit ():GetNamespaceDefinition ())
			end
			GCompute.UniqueNameAssigner ():Process (self.NamespaceDefinition)
			callback ()
		end
	)
			
	for sourceFile in self:GetEnumerator () do
		local compilationUnit = sourceFile:GetCompilationUnit ()
		callbackChain:Then (
			function (callback, errorCallback)
				local callbackChain = GCompute.CallbackChain ()
				callbackChain:Then (function (callback, errorCallback) compilationUnit:RunPass ("SimpleNameResolver", GCompute.SimpleNameResolver, callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:RunPass ("LocalScopeMerger",   GCompute.LocalScopeMerger, callback) end)
				callbackChain:Then (function (callback, errorCallback) compilationUnit:RunPass ("TypeInferer",        GCompute.TypeInfererTypeAssigner, callback) end)
				callbackChain:ThenUnwrap (callback)
				callbackChain:Execute ()
			end
		)
	end
	
	callbackChain:ThenUnwrap (callback)
	callbackChain:Execute ()
end

function self:GetNamespaceDefinition ()
	return self.NamespaceDefinition
end

function self:GetNameResolver ()
	return self.NameResolver
end

function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Compilation Groups", self)
	memoryUsageReport:CreditTableStructure ("Compilation Groups", self.SourceFiles)
	for sourceFile in self:GetEnumerator () do
		sourceFile:ComputeMemoryUsage (memoryUsageReport)
	end
	self.NamespaceDefinition:ComputeMemoryUsage (memoryUsageReport)
	self.NameResolver:ComputeMemoryUsage (memoryUsageReport)
	return memoryUsageReport
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