local self = {}
GCompute.ScopeLookup = GCompute.MakeConstructor (self)

function self:ctor ()
	self.GlobalScope = GCompute.GlobalScope
	self.ScopeStack = GCompute.Containers.Stack ()
	self.TopScope = nil
end

-- returns value
function self:Get (names)
	local scope = self.ScopeStack.Top
	
	while scope do
		local value, type = self:Lookup (scope, names)
		if type then return value end
		
		scope = scope.ParentScope
	end
	
	local value = self:Lookup (self.GlobalScope, names)
	return value
end

-- returns value, Reference
function self:GetReference (names)
	local scope = self.ScopeStack.Top
	
	while scope do
		local value, reference = self:LookupReference (scope, names)
		if reference then return value, reference end
		scope = scope.ParentScope
	end
	
	return self:LookupReference (self.GlobalScope, names)
end

-- returns value, Type
function self:Lookup (scope, names)
	local valueOrScope = scope
	local type = nil
	for i = 1, #names do
		valueOrScope, type = valueOrScope:GetMember (names [i])
		if not type then return nil, nil end
	end
	
	return valueOrScope, type
end

-- returns value, Reference
function self:LookupReference (scope, names)
	if not names then GCompute.PrintStackTrace () end

	local valueOrScope = scope
	local parentScope = scope
	local reference = nil
	for i = 1, #names do
		parentScope = valueOrScope
		valueOrScope, reference = parentScope:GetMemberReference (names [i])
		if not reference then return nil, nil end
	end
	
	return valueOrScope, reference
end

function self:LookupSet (scope, names, value)
	local type = nil
	for i = 1, #names - 1 do
		scope, type = scope:GetItem (names [i])
		if not type then return nil end
	end
	
	local _, type = scope:GetItem (names [#names])
	if not type then
		return nil
	end
	scope:SetMember (names [#names], value)
	
	return scope
end

function self:Set (names, value)
	local scope = self.ScopeStack.Top
	while scope do
		local parentScope = self:LookupSet (Scope, names, value)
		if parentScope then return parentScope end
		
		scope = scope.ParentScope
	end
	
	return self:LookupSet (self.GlobalScope, names, value)
end

function self:PopScope ()
	self.ScopeStack:Pop ()
	self.TopScope = self.ScopeStack.Top
end

function self:PushScope (scope)
	self.ScopeStack:Push (scope)
	self.TopScope = self.ScopeStack.Top
end