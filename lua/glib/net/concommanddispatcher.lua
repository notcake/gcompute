local self = {}
GLib.Net.ConCommandDispatcher = GLib.MakeConstructor (self)

function self:ctor ()
	self.Queue = {}
	self.Buffer = ""
	
	hook.Add ("Tick", "GLib.ConCommandDispatcher",
		function ()
			if #self.Queue == 0 then return end
			
			for i = 1, 10 do
				RunConsoleCommand ("glib_data", self.Queue [1])
				table.remove (self.Queue, 1)
				
				if #self.Queue == 0 then break end
			end
			if #self.Queue == 0 then
				RunConsoleCommand ("glib_data", "\3")
			end
		end
	)
end

function self:dtor ()
	hook.Remove ("Tick", "GLib.ConCommandDispatcher")
end

function self:Dispatch (ply, channelName, packet)
	self.Buffer = ""
	self:String (channelName)
	for i = 1, #packet.Data do
		local data = packet.Data [i]
		local typeId = packet.Types [i]
		
		self [GLib.Net.DataType [typeId]] (self, data)
	end
	self.Buffer = self.Buffer:gsub ("\\", "\\\\")
	self.Buffer = self.Buffer:gsub ("%z", "\\0")
	self.Buffer = self.Buffer:gsub ("\t", "\\t")
	self.Buffer = self.Buffer:gsub ("\r", "\\r")
	self.Buffer = self.Buffer:gsub ("\n", "\\n")
	self.Buffer = self.Buffer:gsub ("\"", "\\q")

	local chunkSize = 497
	for i = 1, self.Buffer:len (), chunkSize do
		self.Queue [#self.Queue + 1] = (i == 1 and "\2" or "\1") .. self.Buffer:sub (i, i + chunkSize - 1)
	end
	if #self.Queue > 100 then
		ErrorNoHalt ("GLib.Net : Warning: Concommand queue is now " .. #self.Queue .. " items long.\n")
	end
end

function self:UInt8 (n)
	self.Buffer = self.Buffer .. string.char (n)
end

function self:UInt16 (n)
	self.Buffer = self.Buffer .. string.char (n % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 256))
end

function self:UInt32 (n)
	self.Buffer = self.Buffer .. string.char (n % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 256) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 65536) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 16777216) % 256)
end

function self:UInt64 (n)
	self.Buffer = self.Buffer .. string.char (n % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 256) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 65536) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 16777216) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 4294967296) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 1099511627776) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 281474976710656) % 256)
	self.Buffer = self.Buffer .. string.char (math.floor (n / 72057594037927936) % 256)
end

function self:Int8 (n)
	self:UInt8 (n + 128)
end

function self:Int16 (n)
	self:UInt16 (n + 32768)
end

function self:Int32 (n)
	self:UInt32 (n + 2147483648)
end

function self:Int64 (n)
	self:UInt64 (n + 2305843009213693952)
end

function self:String (data)
	self:UInt16 (data:len ())
	self.Buffer = self.Buffer .. data
end

function self:Boolean (b)
	self:UInt8 (b and 2 or 1)
end

GLib.Net.ConCommandDispatcher = GLib.Net.ConCommandDispatcher ()