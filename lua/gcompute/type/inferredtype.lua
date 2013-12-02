local self = {}
GCompute.InferredType = GCompute.MakeConstructor (self, GCompute.Type)

--[[
	Type inference constraint types:
		<type> must be implicitly castable to <x>:
			Either:
				<type> inherits from <x>
				<type> has an implicit cast to <x>
				<x> has a constructor which takes <type>
		<type> must be implicitly castable from <x>:
			Either:
				<x> inherits from <type>
				<x> has an implicit cast to <type>
				<type> has a constructor which takes <x>
	
	Type inference data sources:
			- Assignment
				<left> & = <right>
				<left> & = <right> &
					<left> has an assignment operator which takes <right>
					or:
						<right inferred> must be implicitly castable to <left>
						<left inferred> must be implicitly castable from <right>
			- Parameter passing
				<expression>   -> <argument>
				<expression> & -> <argument>
				<expression> & -> <argument> &
					<expression inferred> type must be implicitly castable to <argument> type
					<argument inferred> type must be implicitly castable from <expression> type
	
	The type of a variable is always a reference type.
	<T> && is not a valid type.
	
	Eg:
		int i = 0;
		typeof (Identifier ("i")) is int &
		typeof (NumericLiteral (0)) is int
		typeof (AssignmentOperator ("i = 0")) is int &
		The stored type of i would be int, not int &
	
		void f (T &i) {} means i is passed by reference
		typeof (Identifier ("i")) is T &, not T &&
		The stored type of f would be void (T &)
		
	<T> is a reference type where <T> is backed by a lua table or userdata object
	<T> & is a reference type
	Assignment operators take a reference type for their first argument.
	Eg: operator= (<T>) if <T> is backed by a lua table or userdata object,
	    operator= (<T> &) otherwise.
		
	Native parametric types can be marked to allow covariance.
	<T> & has all the methods of <T> except assignment
	<T> & is implicitly castable to <T>
	IEnumerable<T1> where T1 : T0 is implicitly castable to IEnumerable<T0>
]]

function self:ctor ()
	self.ImplicitlyCastableTo = {}    -- This type must be implicitly castable to any of the types in this array
	self.ImplicitlyCastableFrom = {}  -- This type must be implicitly castable from any of the types in this array
	
	self.Type = nil
end

function self:AddCastableTo (type)
	for _, v in ipairs (self.ImplicitlyCastableTo) do
		if v:Equals (type) then return end
	end
	self.ImplicitlyCastableTo [#self.ImplicitlyCastableTo + 1] = type
end

function self:AddCastableFrom (type)
	for _, v in ipairs (self.ImplicitlyCastableFrom) do
		if v:Equals (type) then return end
	end
	self.ImplicitlyCastableFrom [#self.ImplicitlyCastableFrom + 1] = type
end

function self:CanConstructFrom (sourceType)
	return false
end

function self:CanExplicitCastTo (destinationType)
	return false
end

function self:CanImplicitCastTo (destinationType)
	return false
end

function self:Equals (other)
	if self.Type then
		return self.Type:Equals (other)
	end
	return self == other
end

function self:GetBaseType (index)
	return nil
end

function self:GetBaseTypeCount ()
	return 0
end

function self:GetCorrespondingDefinition (globalNamespace)
	return self
end

function self:GetFullName ()
	return "<inferred-type " .. self:GetHashCode ():sub (8) .. ">"
end

function self:ImportMethodTypes (overloadedMethodDefinition)
	for methodDefinition in overloadedMethodDefinition:GetEnumerator () do
	end
end

function self:IsInferredType ()
	return true
end

function self:ToString ()
	local inferredType = self:GetFullName ()
	if next (self.ImplicitlyCastableTo) then
		inferredType = inferredType .. "\n    [Implicitly castable to]"
		inferredType = inferredType .. "\n    {"
		for type, _ in pairs (self.ImplicitlyCastableTo) do
			inferredType = inferredType .. "\n        " .. type:ToString ():gsub ("\n", "\n        ")
		end
		inferredType = inferredType .. "\n    }"
	end
	if next (self.ImplicitlyCastableFrom) then
		inferredType = inferredType .. "\n    [Implicitly castable from]"
		inferredType = inferredType .. "\n    {"
		for type, _ in pairs (self.ImplicitlyCastableFrom) do
			inferredType = inferredType .. "\n        " .. type:ToString ():gsub ("\n", "\n        ")
		end
		inferredType = inferredType .. "\n    }"
	end
	return inferredType
end