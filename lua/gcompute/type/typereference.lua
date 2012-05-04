local self = {}
GCompute.TypeReference = GCompute.MakeConstructor (self, GCompute.Type)

function self:ctor (typeName)
	self.ResolutionScope = nil
	
	self.ShortName = nil
	self.ReferencedType = nil
	
	self.Parsed = false
	self.ParseLayers = {}
	
	if not typeName then
		GCompute.Error ("TypeReference constructed with a nil value!")
		typeName = "[nil]"
	end
	
	if type (typeName) == "table" and not typeName.IsTypeReference then
		GCompute.Error ("TypeReference constructed with an invalid parameter!")
	end

	if type (typeName) == "string" then
		self.ShortName = typeName
		self.ReferencedType = nil
	elseif typeName:IsTypeReference () then
		self.ShortName = typeName.ShortName
		self.ReferencedType = typeName.ReferencedType
	else
		self.ShortName = typeName:GetFullName ()
		self.ReferencedType = typeName
	end
end

function self:GetArgumentCount ()
	if not self.ReferencedType then return 0 end
	
	return self.ReferencedType:GetArgumentCount ()
end

function self:GetFullName ()
	if not self.ReferencedType then
		self:ResolveType ()
	end
	if self.ReferencedType then
		return self.ReferencedType:GetFullName ()
	end
	return "[Unknown TypeReference]"
end

function self:GetResolutionScope ()
	return self.ResolutionScope
end

function self:GetReferencedType ()
	if not self:IsResolved () then
		self:ResolveType ()
	end
	return self.ReferencedType
end

function self:GetShortName ()
	if self.ShortName then return self.ShortName end
	if self.ReferencedType then return self.ReferencedType:GetFullName () end
	return "[Unknown TypeReference]"
end

function self:IsResolved ()
	return self.ReferencedType ~= nil
end

function self:IsTypeReference ()
	return true
end

function self:ParseType ()
	if self.Parsed then return end
	self.Parsed = true
	
	local name = self.ShortName:gsub (" ", "")
end

function self:ResolveType ()
	if self:IsResolved () then return end
	if not self.ResolutionScope then
		GCompute.Error ("Failed to resolve type " .. self:GetShortName () .. ": TypeReference is missing a parent scope!")
		return
	end
	
	local typeName = self:GetShortName ():Trim ()
	if typeName:sub (-1, -1) == "]" then
		-- array type
		local i = typeName:len ()
		while typeName:sub (i, i) ~= "[" do
			i = i - 1
		end
		local arrayBrackets = typeName:sub (i, -1):gsub (" ", "")
		local rank = arrayBrackets:len () - 2
		
		self.ReferencedType = GCompute.TypeReference (typeName:sub (1, i - 1):Trim ())
		self.ReferencedType:SetResolutionScope (self:GetResolutionScope ())
		self.ReferencedType:ResolveType ()
	else
		local nextLessThan = typeName:find ("<")
		local nextDot = typeName:find ("%.")
		
		-- Warning: Extremely bad code ahead
		if not nextLessThan and not nextDot then
			-- No parametric types, no indexing
			local member, memberType = self.ResolutionScope:GetMember (typeName)
			if not member and self.ResolutionScope:GetGlobalScope () then
				member, memberType = self.ResolutionScope:GetGlobalScope ():GetMember (typeName)
			end
			if not member then
				GCompute.Error ("Failed to resolve type " .. self:GetShortName () .. ": Type not found!")
				return
			end
			
			self.ReferencedType = member
		elseif not nextLessThan then
			-- Only simple indexing, no parametric types
			local names = typeName:Split (".")
			local scope = self.ResolutionScope
			
			local member, memberType = self.ResolutionScope:GetMember (typeName)
			if not member and self.ResolutionScope:GetGlobalScope () then
				member, memberType = self.ResolutionScope:GetGlobalScope ():GetMember (typeName)
			end
			if not member then
				GCompute.Error ("Failed to resolve type " .. self:GetShortName () .. ": Type not found!")
				return
			end
			
			self.ReferencedType = member
		else
			-- Need a full blown parser
			local parseTree = GCompute.TypeParser (self:GetShortName ()).ParseTree
			local rootType = parseTree.Value
			
			if rootType == "parametric_type" or
				rootType == "." then
				GCompute.Error ("Failed to resolve type " .. self:GetShortName () .. ": Unhandled type type!")
				return
			else
				GCompute.Error ("Failed to resolve type " .. self:GetShortName () .. ": Unhandled type type!")
				return
			end
		end
	end
	self.FullName = self.ReferencedType:GetFullName ()
end

function self:SetResolutionScope (resolutionScope)
	if self.ResolutionScope and self.ResolutionScope ~= resolutionScope then GCompute.Error ("Resolution scope already set!") end

	self.ResolutionScope = resolutionScope
end

self.ToDefinitionString = self.GetFullName
self.ToString = self.GetFullName

local proxyFunctions =
	{
		"GetArrayRank",
		"GetElementType",
		"GetMembers",
		"HasElementType",
		"HasVTable",
		"IsArrayType",
		"IsInheritable",
		"IsPrimitiveType",
		"IsReferenceType",
		"IsScopeType",
		"UnreferenceType"
	}
	
for _, functionName in ipairs (proxyFunctions) do
	self [functionName] = function (self)
		if not self:IsResolved () then self:ResolveType () end
		return self.ReferencedType [functionName] (self.ReferencedType)
	end
end