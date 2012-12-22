local self = {}
GCompute.PropertyDefinition = GCompute.MakeConstructor (self, GCompute.ObjectDefinition)

function self:ctor (name)
	self.Type   = nil
	self.Getter = nil
	self.Setter = nil
end

function self:AddGetter ()
	if not self.Getter then
		self.Getter = GCompute.PropertyAccessorDefinition (self:GetName ())
			:SetReturnType (self:GetType ())
			:SetMemberVisibility (self:GetMemberVisibility ())
		self:GetDeclaringObject ():GetNamespace ():SetupMemberHierarchy (self.Getter)
	end
	return self.Getter
end

function self:AddSetter ()
	if not self.Setter then
		self.Setter = GCompute.PropertyAccessorDefinition (self:GetName (), { { self:GetType (), "value" } })
			:SetMemberVisibility (self:GetMemberVisibility ())
		self:GetDeclaringObject ():GetNamespace ():SetupMemberHierarchy (self.Setter)
	end
	return self.Setter
end

function self:GetGetter ()
	return self.Getter
end

function self:GetSetter ()
	return self.Setter
end

function self:SetType (type)
	self.Type = GCompute.ToDeferredTypeResolution (type, self:GetGlobalNamespace (), self:GetDeclaringObject ())
	if self.Getter then self.Getter:SetReturnType (self.Type) end
	if self.Setter then self.Setter:GetParameterList ():SetParameterType (1, self.Type) end
	return self
end

-- Definition
function self:GetDisplayText ()
	local displayText = self:GetType ():GetRelativeName (self) .. " " .. self:GetShortName () .. " { "
	if self.Getter then
		displayText = displayText .. "get; "
	end
	if self.Setter then
		displayText = displayText .. "set; "
	end
	displayText = displayText .. "}"
	return displayText
end

function self:GetType ()
	return self.Type
end

function self:ResolveTypes (globalNamespace, errorReporter)
	errorReporter = errorReporter or GCompute.DefaultErrorReporter
	
	if self.Type and self.Type:IsDeferredObjectResolution () then
		self.Type:Resolve (globalNamespace, self:GetDeclaringObject ())
		if self.Type:IsFailedResolution () then
			self.Type:GetAST ():GetMessages ():PipeToErrorReporter (errorReporter)
		else
			self.Type = self.Type:GetObject ():ToType ()
		end
	end
	
	if self.Getter then
		self.Getter:ResolveTypes (globalNamespace, errorReporter)
	end
	if self.Setter then
		self.Setter:ResolveTypes (globalNamespace, errorReporter)
	end
end

function self:ToString ()
	return self:GetDisplayText ()
end