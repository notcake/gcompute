local commandQueue = {}
local nextRunItem = 1

local function QueueConsoleCommand (...)
	commandQueue [#commandQueue + 1] = {...}
	
	if #commandQueue == 1 then
		timer.Create ("VFS.Adaptors.E2FileList", 0.1, 0, function ()
			for i = 1, 10 do
				RunConsoleCommand (unpack (commandQueue [nextRunItem]))
				print (unpack (commandQueue [nextRunItem]))
			
				nextRunItem = nextRunItem + 1
				if nextRunItem > #commandQueue then
					commandQueue = {}
					nextRunItem = 1
					timer.Destroy ("VFS.Adaptors.E2FileList")
					break
				end
			end
		end)
	end
end

local upload_buffer = {}
local upload_chunk_size = 200

local function upload_callback ()
	if not upload_buffer or not upload_buffer.data then return end
	
	local chunk_size = math.Clamp (string.len (upload_buffer.data), 0, upload_chunk_size)
	
	local transmittedString = string.Left (upload_buffer.data, chunk_size)
	if transmittedString:sub (-1, -1) == "%" then
		transmittedString = string.Left (upload_buffer.data, chunk_size + 1)
	end
	QueueConsoleCommand ("wire_expression2_file_chunk", transmittedString)
	upload_buffer.data = string.sub (upload_buffer.data, transmittedString:len () + 1, string.len (upload_buffer.data))
	
	if upload_buffer.chunk >= upload_buffer.chunks then
		QueueConsoleCommand ("wire_expression2_file_finish")
		timer.Remove ("wire_expression2_file_upload")
		return
	end
	
	upload_buffer.chunk = upload_buffer.chunk + 1
end

usermessage.GetTable () ["wire_expression2_request_file"] =
{
	Function = function (umsg)
		local filePath = umsg:ReadString ()
		if filePath:sub (-5, -1) == "\\.txt" then filePath = filePath:sub (1, -6) end
		ErrorNoHalt ("read: " .. filePath)
		VFS.Root:GetChild (GAuth.GetLocalId (), filePath,
			function (returnCode, node)
				if returnCode == VFS.ReturnCode.None then
					if node:IsFile () then
						node:Open (GAuth.GetLocalId (), VFS.OpenFlags.ReadOnly,
							function (returnCode, filestream)
								if returnCode == VFS.ReturnCode.None then
									filestream:Read (filestream:GetLength (),
										function (returnCode, data)
											if returnCode == VFS.ReturnCode.None then
												
												local encoded = E2Lib.encode (data)
												
												upload_buffer = {
													chunk = 1,
													chunks = math.ceil (string.len (encoded) / upload_chunk_size),
													data = encoded
												}
												
												QueueConsoleCommand ("wire_expression2_file_begin", "1", string.len (data))
												
												timer.Create ("wire_expression2_file_upload", 1 / 60, upload_buffer.chunks, upload_callback)
											else
												filestream:Close ()
												ErrorNoHalt ("E2 files: Cannot read " .. filePath .. " (" .. VFS.ReturnCode [returnCode] .. ")\n")
												QueueConsoleCommand ("wire_expression2_file_begin", "0")
											end
										end
									)
								else
									ErrorNoHalt ("E2 files: Cannot open " .. filePath .. " (" .. VFS.ReturnCode [returnCode] .. ")\n")
									QueueConsoleCommand ("wire_expression2_file_begin", "0")
								end
							end
						)
					else
						ErrorNoHalt ("E2 files: " .. filePath .. " is not a file!\n")
						QueueConsoleCommand ("wire_expression2_file_begin", "0")
					end
				else
					ErrorNoHalt ("E2 files: Error when resolving " .. filePath .. " (" .. VFS.ReturnCode [returnCode] .. ")\n")
					QueueConsoleCommand ("wire_expression2_file_begin", "0")
				end
			end
		)
	end,
	PreArgs = {}
}
usermessage.GetTable () ["wire_expression2_request_file_sp"] = usermessage.GetTable () ["wire_expression2_request_file"]

usermessage.GetTable () ["wire_expression2_request_list"] = 
{
	Function = function (umsg)
		local folderPath = umsg:ReadString () or ""
		ErrorNoHalt ("list: " .. folderPath)
		VFS.Root:GetChild (GAuth.GetLocalId (), folderPath,
			function (returnCode, node)
				if returnCode == VFS.ReturnCode.None then
					node:EnumerateChildren (GAuth.GetLocalId (),
						function (returnCode, node)
							if returnCode == VFS.ReturnCode.None then
								if node:IsFolder () then
									QueueConsoleCommand ("wire_expression2_file_list", "1", E2Lib.encode (node:GetDisplayName () .. "/"))
								else
									QueueConsoleCommand ("wire_expression2_file_list", "1", E2Lib.encode (node:GetDisplayName ()))
								end
							elseif returnCode == VFS.ReturnCode.Finished then
								QueueConsoleCommand ("wire_expression2_file_list", "0")
							else
								ErrorNoHalt ("E2 files: Error when enumerating contents of " .. folderPath .. " (" .. VFS.ReturnCode [returnCode] .. ")\n")
								QueueConsoleCommand ("wire_expression2_file_list", "0")
							end
						end
					)
				else
					ErrorNoHalt ("E2 files: Error when resolving folder " .. folderPath .. " (" .. VFS.ReturnCode [returnCode] .. ")\n")
					QueueConsoleCommand ("wire_expression2_file_list", "0")
				end
			end
		)
	end,
	PreArgs = {}
}
