local self = {}
self.__Type = "RangeForLoop"
GCompute.AST.RangeForLoop = GCompute.AST.MakeConstructor (self)

function self:ctor ()
	self.Variable = nil -- VariableDeclaration or QualifiedIdentifier
	self.Range = {}
	
	self.Namespace = GCompute.NamespaceDefinition ()
	self.LoopStatement = nil
end

function self:AddValue (n)
	self.Range [#self.Range + 1] = { n }
end

function self:AddRange (startValue, endValue, increment)
	self.Range [#self.Range + 1] = { startValue, endValue, increment }
end

function self:Evaluate (executionContext)
end

function self:GetLoopStatement ()
	return self.LoopStatement
end

function self:GetVariable ()
	return self.Variable
end

function self:SetLoopStatement (statement)
	self.LoopStatement = statement
end

function self:SetVariable (variable)
	self.Variable = variable
end

function self:ToString ()
	local variable = self.Variable and self.Variable:ToString () or "[Unknown]"
	local range = ""
	
	for _, rangeEntry in ipairs (self.Range) do
		if range ~= "" then range = range .. ", " end
		if #rangeEntry == 1 then
			range = range .. rangeEntry [1]:ToString ()
		else
			range = range .. rangeEntry [1]:ToString () .. ":" .. rangeEntry [2]:ToString ()
			if rangeEntry [3] then
				range = range .. ":" .. rangeEntry [3]:ToString ()
			end
		end
	end
	
	local loopStatement = "    [Unknown]"
	
	if self.LoopStatement then
		if self.LoopStatement:Is ("Block") then
			loopStatement = self.LoopStatement:ToString ()
		else
			loopStatement = "    " .. self.LoopStatement:ToString ():gsub ("\n", "\n    ")
		end
	end
	return "for (" .. variable .. " = " .. range .. ")\n" .. loopStatement
end