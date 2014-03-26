local self = {}
GCompute.IDE.Console.Printer = GLib.MakeConstructor (self)

function self:ctor (pipe)
	self.Pipe = pipe
	
	self.OutputSuppressed = 0
	self.SuppressedCharacterCount = 0
	
	self.LineBreakIndentationCache = {}
	self.IndentationLevel = 0
	self.LineBreakIndentation = ""
end

-- Output suppression
function self:GetSuppressedCharacterCount ()
	return self.SuppressedCharacterCount
end

function self:IsOutputSuppressed ()
	return self.OutputSuppressed > 0
end

function self:SuppressOutput ()
	self.OutputSuppressed = self.OutputSuppressed + 1
	if self.OutputSuppressed == 1 then
		self.SuppressedCharacterCount = 0
	end
end

function self:UnsuppressOutput ()
	self.OutputSuppressed = self.OutputSuppressed - 1
end

-- Indentation
function self:DecreaseIndentation (n)
	n = n or 1
	self:SetIndentationLevel (self.IndentationLevel - n)
end

function self:IncreaseIndentation (n)
	n = n or 1
	self:SetIndentationLevel (self.IndentationLevel + n)
end

function self:GetIndentationLevel ()
	return self.IndentationLevel
end

function self:SetIndentationLevel (n)
	n = math.max (0, n)
	
	self.IndentationLevel = n
	
	if not self.LineBreakIndentationCache [n] then
		self.LineBreakIndentationCache [n] = "\n" .. string.rep ("\t", n)
	end
	
	self.LineBreakIndentation = self.LineBreakIndentationCache [n]
end

-- Printing
function self:Print (obj, multiline)
	if multiline == nil then multiline = true end
	
	local type = type (obj)
	
	if type == "nil" then
		self:PrintNil ()
	elseif type == "boolean" then
		self:PrintBoolean (obj)
	elseif type == "number" then
		self:PrintNumber (obj)
	elseif type == "string" then
		self:PrintString (obj, multiline)
	elseif type == "function" then
		self:PrintFunction (obj, multiline)
	elseif type == "table" then
		self:PrintTable (obj, multiline)
	else
		self:PrintGeneric (obj, multiline)
	end
end

function self:PrintNil ()
	self:PrintKeyword ("nil")
end

function self:PrintBoolean (b)
	self:PrintKeyword (b and "true" or "false")
end

function self:PrintNumber (value, desiredWidth)
	if value == math.huge then
		self:Append ("math", GLib.Colors.SkyBlue)
		self:Append (".", GLib.Colors.White)
		self:Append ("huge", GLib.Colors.SkyBlue)
	elseif value == -math.huge then
		self:Append ("-", GLib.Colors.White)
		self:Append ("math", GLib.Colors.SkyBlue)
		self:Append (".", GLib.Colors.White)
		self:Append ("huge", GLib.Colors.SkyBlue)
	elseif value >= 65536 and
	       value < 4294967296 and
	       math.floor (value) == value then
		self:Append (string.format ("0x%08x", value), GLib.Colors.SandyBrown)
	else
		local str = tostring (value)
		if desiredWidth and #str < desiredWidth then
			str = string.rep (" ", desiredWidth - #str) .. str
		end
		self:Append (str, GLib.Colors.SandyBrown)
	end
end

function self:PrintString (str, multiline)
	self:Append (GLib.Lua.ToLuaString (str), GLib.Colors.Gray)
end

function self:PrintFunction (f, multiline)
	if multiline == nil then multiline = true end
	
	local f = GLib.Lua.Function (f)
	
	if multiline then
		if f:IsNative () then
			self:PrintComment ("-- [Native]\n")
		else
			self:PrintComment ("-- " .. f:GetFilePath () .. ": " .. f:GetStartLine () .. "-" .. f:GetEndLine () .. "\n")
			
			local functionName = GLib.Lua.GetObjectName (f:GetRawFunction ())
			if functionName then
				self:PrintComment ("-- " .. functionName .. "\n")
			end
		end
		self:Append (GLib.Lua.ToLuaString (f:GetRawFunction ()), GLib.Colors.White)
	else
		self:PrintKeyword ("function ")
		self:Append (f:GetParameterList ():ToString (), GLib.Colors.White)
		
		if f:IsNative () then
			self:PrintComment (" --[[ Native ]]")
		else
			local functionName = GLib.Lua.GetObjectName (f:GetRawFunction ())
			
			if functionName then
				self:PrintComment (" --[[ " .. f:GetFilePath () .. ": " .. f:GetStartLine () .. "-" .. f:GetEndLine () .. ", " ..  functionName .. " ]]")
			else
				self:PrintComment (" --[[ " .. f:GetFilePath () .. ": " .. f:GetStartLine () .. "-" .. f:GetEndLine () .. " ]]")
			end
		end
	end
end

function self:PrintTable (t, multiline)
	if multiline == nil then multiline = true end
	
	if self:IsColor (t) then
		return self:PrintColor (t, multiline)
	end
	
	if not multiline then
		return self:PrintGeneric (t, multiline)
	end
	
	self:PrintComment ("-- " .. string.format ("0x%08x", GLib.Lua.AddressOf (t)) .. "\n")
	
	local tableName = GLib.Lua.GetObjectName (t)
	if tableName then
		self:PrintComment ("-- " .. tableName .. "\n")
	end
	
	if next (t) == nil then
		self:Append ("{}", GLib.Colors.White)
	else
		local sortedKeys = {}
		local keyLengths = {}
		
		for k, _ in pairs (t) do
			sortedKeys [#sortedKeys + 1] = k
		end
		table.sort (sortedKeys,
			function (a, b)
				if isnumber (a) and isnumber (b) then
					return a < b
				end
				if isnumber (a) then return true end
				if isnumber (b) then return true end
				
				return tostring (a) < tostring (b)
			end
		)
		
		local maxKeyIndex = math.min (160, #sortedKeys)
		
		local maxKeyLength = 0
		for i = 1, maxKeyIndex do
			local k = sortedKeys [i]
			
			local length = 0
			if GLib.Lua.IsValidVariableName (k) then
				length = GLib.UTF8.Length (k)
			else
				length = 2
				self:SuppressOutput ()
				self:Print (k, false)
				self:UnsuppressOutput ()
				length = length + self:GetSuppressedCharacterCount ()
			end
			
			keyLengths [i] = length
			
			if length <= 32 then
				maxKeyLength = math.max (maxKeyLength, length)
			end
		end
		
		self:Append ("{\n", GLib.Colors.White)
		for i = 1, maxKeyIndex do
			local k = sortedKeys [i]
			
			self:IncreaseIndentation (2)
			
			self:Append ("\t", GLib.Colors.White)
			if GLib.Lua.IsValidVariableName (k) then
				self:Append (k, GLib.Colors.White)
			else
				self:Append ("[", GLib.Colors.White)
				self:Print (k, false)
				self:Append ("]", GLib.Colors.White)
			end
			
			self:Append (string.rep (" ", maxKeyLength - keyLengths [i]), GLib.Colors.White)
			
			self:Append (" = ", GLib.Colors.White)
			
			self:Print (t [k], false)
			self:DecreaseIndentation (2)
			
			if i < maxKeyIndex or maxKeyIndex < #sortedKeys then
				self:Append (",", GLib.Colors.White)
			end
			
			self:Append ("\n", GLib.Colors.White)
		end
		
		if maxKeyIndex < #sortedKeys then
			self:PrintComment ("\t-- " .. tostring (#sortedKeys - maxKeyIndex) .. " more...\n")
		end
		
		self:Append ("}\n", GLib.Colors.White)
		self:PrintComment ("-- " .. tostring (#sortedKeys) .. " total entrie" .. (#sortedKeys == 1 and "" or "s") .. ".")
	end
end

function self:PrintColor (t, multiline)
	if multiline == nil then multiline = true end
	
	if multiline then
		self:PrintComment ("-- " .. string.format ("0x%08x", GLib.Lua.AddressOf (t)) .. "\n")
		
		self:PrintComment ("-- ")
		self:Append ("█", t)
		self:PrintComment ("\n")
	end
	
	self:Append ("Color", GLib.Colors.SkyBlue)
	self:Append (" (", GLib.Colors.White)
	self:PrintNumber (t.r, 3)
	self:Append (", ", GLib.Colors.White)
	self:PrintNumber (t.g, 3)
	self:Append (", ", GLib.Colors.White)
	self:PrintNumber (t.b, 3)
	self:Append (", ", GLib.Colors.White)
	self:PrintNumber (t.a, 3)
	self:Append (")", GLib.Colors.White)
	
	if not multiline then
		self:PrintComment (" --[[ ")
		self:Append ("█", t)
		self:PrintComment (" ]]")
	end
end

function self:PrintGeneric (obj, multiline)
	if multiline == nil then multiline = true end
	
	self:Append (GLib.Lua.ToLuaString (obj), GLib.Colors.White)
end

function self:PrintComment (str)
	self:Append (str, GLib.Colors.ForestGreen)
end

function self:PrintKeyword (str)
	self:Append (str, GLib.Colors.RoyalBlue)
end

function self:Append (text, color)
	if self.IndentationLevel > 0 then
		text = string.gsub (text, "\n", self.LineBreakIndentation)
	end
	if self:IsOutputSuppressed () then
		self.SuppressedCharacterCount = self.SuppressedCharacterCount + GLib.UTF8.Length (text)
	else
		self.Pipe:WriteColor (text, color)
	end
end

-- Internal, do not call
local colorKeys =
{
	r = true,
	g = true,
	b = true,
	a = true
}
function self:IsColor (t)
	if debug.getmetatable (t) ~= nil then return false end
	
	for k, v in pairs (t) do
		if not colorKeys [k] then return false end
	end
	
	for k, _ in pairs (colorKeys) do
		if not isnumber (t [k]) then return false end
	end
	
	return true
end