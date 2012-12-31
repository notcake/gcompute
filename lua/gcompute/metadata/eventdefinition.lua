local self = {}
GCompute.EventDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

--- @param The name of this event
-- @param parameterList A ParameterList describing the parameters the event takes or nil if the event takes no parameters
function self:ctor (name, parameterList)
	-- Event
	self.ReturnType    = GCompute.DeferredObjectResolution ("void", GCompute.ResolutionObjectType.Type)
	self.ParameterList = GCompute.ToParameterList (parameterList)
	
	-- AST
	self.EventDeclaration = nil
end

-- Event
function self:GetParameterCount ()
	return self.ParameterList:GetParameterCount ()
end

--- Gets the parameter list of this event
-- @return The parameter list of this event
function self:GetParameterList ()
	return self.ParameterList
end

function self:GetParameterName (index)
	return self.ParameterList:GetParameterName (index)
end

--- Gets the return type of this event as a DeferredObjectResolution or Type
-- @return A DeferredObjectResolution or Type representing the return type of this event
function self:GetReturnType ()
	return self.ReturnType
end

--- Sets the return type of this event
-- @param returnType The return type as a string or DeferredObjectResolution or Type
function self:SetReturnType (returnType)
	self.ReturnType = GCompute.ToDeferredTypeResolution (returnType, self)
	return self
end

-- AST
--- Gets the EventDeclaration syntax tree node corresponding to this function
-- @return The EventDeclaration corresponding to this function
function self:GetEventDeclaration ()
	return self.EventDeclaration
end

--- Sets the EventDeclaration syntax tree node corresponding to this event
-- @param eventDeclaration The EventDeclaration corresponding to this event
function self:SetEventDeclaration (eventDeclaration)
	self.EventDeclaration = eventDeclaration
end

-- Definition
function self:ComputeMemoryUsage (memoryUsageReport)
	memoryUsageReport = memoryUsageReport or GCompute.MemoryUsageReport ()
	if memoryUsageReport:IsCounted (self) then return end
	
	memoryUsageReport:CreditTableStructure ("Object Definitions", self)
	
	return memoryUsageReport
end

function self:CreateRuntimeObject ()
	return self
end

function self:GetDisplayText ()
	return self:GetReturnType ():GetRelativeName (self) .. " " .. self:GetShortName () .. " " .. self:GetParameterList ():GetRelativeName (self)
end

--- Gets the type of this event
-- @return A FunctionType representing the type of this event
function self:GetType ()
	return GCompute.FunctionType (self:GetReturnType (), self:GetParameterList ())
end

function self:IsEvent ()
	return true
end

--- Resolves the return type and paremeter types of this event
function self:ResolveTypes (objectResolver, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	self:BuildNamespace ()
	
	local returnType = self:GetReturnType ()
	if returnType and returnType:IsDeferredObjectResolution () then
		returnType:Resolve (objectResolver)
		if returnType:IsFailedResolution () then
			returnType:GetAST ():GetMessages ():PipeToErrorReporter (errorReporter)
			self:SetReturnType (GCompute.ErrorType ())
		else
			self:SetReturnType (returnType:GetObject ())
		end
	end
	self:GetParameterList ():ResolveTypes (objectResolver, self, errorReporter)
end

--- Returns a string representation of this event
-- @return A string representation of this event
function self:ToString ()
	local eventDefinition = "[Event] " .. self.ReturnType and self.ReturnType:GetRelativeName (self) or "[Unknown Type]"
	eventDefinition = eventDefinition .. " " .. self:GetName ()
	eventDefinition = eventDefinition .. " " .. self:GetParameterList ():GetRelativeName (self)
	return eventDefinition
end

function self:Visit (namespaceVisitor, ...)
	namespaceVisitor:VisitEvent (self, ...)
end