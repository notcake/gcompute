local self = {}
GCompute.MirrorOverloadedMethodDefinition = GCompute.MakeConstructor (self, GCompute.OverloadedMethodDefinition)

--- @param name The name of this function
function self:ctor (name)
	self.SourceOverloadedMethods = {}
end

--- Adds a source overloaded method from which methods will be obtained
-- @param overloadedMethodDefinition Source overloaded method definition from which methods will be obtained
function self:AddSourceOverloadedMethod (overloadedMethodDefinition)
	self.SourceOverloadedMethods [#self.SourceOverloadedMethods + 1] = overloadedMethodDefinition
	
	for method in overloadedMethodDefinition:GetEnumerator () do
		self.Methods [#self.Methods + 1] = method
	end
end