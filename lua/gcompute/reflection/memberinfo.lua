local self = {}
GCompute.MemberInfo = GCompute.MakeConstructor (self)

function self:ctor (name, memberType)
	self.Name = name
	self.MemberType = memberType
end

function self:GetMemberType ()
	return self.MemberType
end

function self:GetName ()
	return self.Name
end