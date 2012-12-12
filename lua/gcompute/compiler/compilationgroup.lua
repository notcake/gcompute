local self = {}
GCompute.CompilationGroup = GCompute.MakeConstructor (self)

function self:ctor ()
	self.SourceFiles = {}
	self.SourceFileCount = 0
	
	self.NamespaceDefinition = GCompute.MergedNamespaceDefinition ()
	self.NamespaceDefinition:SetNamespaceType (GCompute.NamespaceType.Global)
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
--- Starts compilation of this CompilationGroup.
-- @param callback A callback function (success)
function self:Compile (callback)
	local rootCallback = callback or GCompute.NullCallback

	local callbackChain = GCompute.CallbackChain ()
	for sourceFile in self:GetEnumerator () do
		local compilationUnit = sourceFile:GetCompilationUnit ()
		callbackChain:Then (
			function (callback, errorCallback)
				local callbackChain = GCompute.CallbackChain ()
					:Then (function (callback, errorCallback) compilationUnit:Lex (callback) end)
					:Then (function (callback, errorCallback) compilationUnit:Preprocess (callback) end)
					:Then (function (callback, errorCallback) compilationUnit:GenerateParserJobs (callback) end)
					:Then (function (callback, errorCallback) compilationUnit:Parse (callback) end)
					:Then (self:ASTErrorChecker (compilationUnit), self:ASTErrorHandler (compilationUnit, rootCallback))
					:Then (function (callback, errorCallback) compilationUnit:PostParse (callback) end)
					:Then (function (callback, errorCallback) compilationUnit:RunPass ("BlockStatementInserter", GCompute.BlockStatementInserter, callback) end)
					:Then (function (callback, errorCallback) compilationUnit:BuildNamespace (callback) end)
					:Then (function (callback, errorCallback) compilationUnit:PostBuildNamespace (callback) end)
					:ThenUnwrap (callback)
					:Execute ()
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
					:Then (function (callback, errorCallback) compilationUnit:RunPass ("SimpleNameResolver", GCompute.SimpleNameResolver, callback) end)
					:Then (self:ASTErrorChecker (compilationUnit), self:ASTErrorHandler (compilationUnit, rootCallback))
					:Then (function (callback, errorCallback) compilationUnit:RunPass ("LocalScopeMerger",   GCompute.LocalScopeMerger, callback) end)
					:Then (function (callback, errorCallback) compilationUnit:RunPass ("TypeInferer",        GCompute.TypeInfererTypeAssigner, callback) end)
					
					-- Runtime preparation
					:Then (function (callback, errorCallback) compilationUnit:RunPass ("StaticMemberToucher", GCompute.StaticMemberToucher, callback) end)
					:ThenUnwrap (callback)
					:Execute ()
			end
		)
	end
	
	callbackChain:ThenUnwrap (
		function ()
			rootCallback (true)
		end
	)
	callbackChain:Execute ()
end

function self:GetNamespaceDefinition ()
	return self.NamespaceDefinition
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

-- Internal, do not call
function self:ASTErrorChecker (compilationUnit)
	return function (callback, errorCallback)
		local compilerMessageCollection = compilationUnit:GetAbstractSyntaxTree ():GetMessages ()
		if compilerMessageCollection and compilerMessageCollection:GetErrorCount () > 0 then
			errorCallback (compilerMessageCollection)
			return
		end
		callback ()
	end
end

function self:ASTErrorHandler (compilationUnit, rootCallback)
	return function (_, compilerMessageCollection)
		for message in compilerMessageCollection:GetEnumerator () do
			if message:GetMessageType () == GCompute.CompilerMessageType.Warning then
				compilationUnit:Warning (message:GetText (), message:GetStartLine (), message:GetStartCharacter ())
			elseif message:GetMessageType () == GCompute.CompilerMessageType.Error then
				compilationUnit:Error (message:GetText (), message:GetStartLine (), message:GetStartCharacter ())
			else
				compilationUnit:Information (message:GetText (), message:GetStartLine (), message:GetStartCharacter ())
			end
		end
		rootCallback (false)
	end
end