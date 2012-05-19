GLib.UTF8 = {}

function GLib.UTF8.Byte (char, offset)
	if char == "" then return -1 end
	offset = offset or 1
	
	local byte = string.byte (char, offset)
	local length = 1
	if byte >= 128 then
		if byte >= 240 then
			-- 4 byte sequence
			length = 4
			if string.len (char) < 4 then return -1, length end
			byte = (byte & 7) * 262144
			byte = byte + (string.byte (char, offset + 2) & 63) * 4096
			byte = byte + (string.byte (char, offset + 3) & 63) * 64
			byte = byte + (string.byte (char, offset + 4) & 63)
		elseif byte >= 224 then
			-- 3 byte sequence
			length = 3
			if string.len (char) < 3 then return -1, length end
			byte = (byte & 15) * 4096
			byte = byte + (string.byte (char, offset + 2) & 63) * 64
			byte = byte + (string.byte (char, offset + 3) & 63)
		elseif byte >= 192 then
			-- 2 byte sequence
			length = 2
			if string.len (char) < 2 then return -1, length end
			byte = (byte & 31) * 64
			byte = byte + (string.byte (char, offset + 2) & 63)
		else
			-- invalid sequence
			byte = -1
		end
	end
	return byte, length
end

function GLib.UTF8.Char (byte)
	local utf8 = ""
	if byte < 0 then
		utf8 = ""
	elseif byte <= 127 then
		utf8 = string.char (byte)
	elseif byte < 2048 then
		utf8 = string.format ("%c%c", 192 + math.floor (byte / 64), 128 + (byte & 63))
	elseif byte < 65536 then
		utf8 = string.format ("%c%c%c", 224 + math.floor (byte / 4096), 128 + (math.floor (byte / 64) & 63), 128 + (byte & 63))
	elseif byte < 2097152 then
		utf8 = string.format ("%c%c%c%c", 240 + math.floor (byte / 262144), 128 + (math.floor(byte / 4096) & 63), 128 + (math.floor (byte / 64) & 63), 128 + (byte & 63))
	end
	return utf8
end

function GLib.UTF8.Length (str)
	local _, length = string.gsub (str, "[^\128-\191]", "")
	return length
end