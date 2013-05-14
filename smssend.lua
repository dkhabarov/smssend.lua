#!/usr/bin/env lua5.1
-- ***************************************************************************
-- smssend - smssend is a program to send SMS messages from the commandline.

-- Copyright © 2013 Denis Khabarov aka 'Saymon21'
-- E-Mail: saymon at hub21 dot ru (saymon@hub21.ru)

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License version 3
-- as published by the Free Software Foundation.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- ***************************************************************************

-- ATTENTION!!! This is beta version!!!
-- Recommended to use smssend.py from the repository - http://opensource.hub21.ru/smssend/
-- Tested only on Debian GNU/Linux & Lua 5.1.4

tArgs = {}
function show_help()
print("smssend is a program to send SMS messages from the commandline.\
Using API service http://sms.ru\
Copyright © 2009-2012 by Denis Khabarov aka 'Saymon21'\
E-Mail: saymon at hub21 dot ru (saymon@hub21.ru)\
\nOptional arguments:\
\t--help\t\tshow this help message and exit\
\t--apiid\tVALUE\t\tAPI ID (optional)\
\t--to PHONENUMBER\t\tTelephone number where send sms message (required)\
\t--message MESSAGE\t\tRead the message from this argument value instead of stdin (optional)\
\t--from VALUE\t\tSender name (optional)\
\t--time VALUE\t\tSend time (optional)\
\nReturned codes:\n\
\t0\t- Message send successful\
\t1\t- Service has retured error message\
\t2\t- HTTP Error\
\t3\t- Error for usage this tool\n\
Default API ID are read from the files:\
\tLinux: $HOME/.smssendrc\
\tWindows: %USERPROFILE%/.smssendrc\n\
Example usage:\
\techo \"Hello world\" | smssend.lua --apiid=yourapiid --to=target_phone_number")
end

function get_os()
	local path_separator = package.config:sub(1,1)
	if path_separator == "/" then
		return 1 -- Unix
	elseif path_separator == "\\" then
		return 2 -- Win
	end
end

function get_home_path()
	local _os = get_os()
	if _os == 1 then
		home = os.getenv("HOME")
	elseif _os == 2 then
		home = os.getenv("USERPROFILE")
	else os.exit(3)
	end
	return home
end

function get_api_id()
	local home = get_home_path()
	if home then
		h=io.open(home.."/.smssendrc","r")
		if h then
			data=h:read()
		end
	end
	if data then
		return data
	else 
		if tArgs["apiid"] then
			return tArgs["apiid"]
		else
			print("Error. See --help")
			os.exit(3)
		end
	end		
end

function get_msg()
	if tArgs['message'] then
		return tArgs['message']
	else
		return io.stdin:read()
	end
end


function cliarg_parser()
	if arg then
		local available_args = {
			["apiid"] = true, ["to"] = true, ["message"] = true, ["from"] = true, ["time"] = true, ["help"]= true,
 		}
 		for _, val in ipairs(arg) do
			if val:find("=", 1, true) then
				local name, value = val:match("%-%-(.-)=(.+)")
				--print("Commandline argument: "..tostring(name).." = "..tostring(value).."\n")
				if name and value and available_args[name:lower()] then
					tArgs[name:lower()] = value
					--print("[parser debug]: Commandline argument: "..tostring(name).." = "..tostring(value))
				else
					print("Unknown commandline argument used: "..val.."\nusage: "..arg[0].."--help")
					os.exit(3)
				end
			else
				name = val:match("%-%-(.+)")
				if name and  available_args[name:lower()] then
					tArgs[name:lower()] = true
					--print("[parser debug]: Commandline argument: "..tostring(name).." is set as TRUE ") -- debug
				else
					print("Unknown commandline argument used: "..val.."\nusage: "..arg[0].." --help")
					os.exit(3)
				end
			end
		end
	end
	
	if tArgs["help"] then
		show_help() -- Show help
		os.exit(0)
	end
	if not tArgs["to"] then
		print("Error. See --help")
		os.exit(3)
	elseif not tArgs["to"]:find("^%d+$") then
		print("Invalid argument for --to.")
		os.exit(3)
	end
end


function main()
	print("ATTENTION!!! This is beta version!!!\nRecommended to use smssend.py from the repository - http://opensource.hub21.ru/smssend/\n\n")
	urllib = require"socket.url"
	httplib = require"socket.http"
	cliarg_parser()
	api_id = get_api_id()
	if not api_id then
		print(("Error for get api-id. Check %s/.smssendrc or see --help"):format(get_home_path()))
		os.exit(1)
	end
	api_id = api_id:gsub("\r\n", "")
	api_id = api_id:gsub("\n", "")
	msg = get_msg()
	if msg:len() == 0 then
		print("Error. Please enter msg")
		os.exit(1)
	end
	
	local url=(("http://sms.ru/sms/send?api_id=%s&to=%s&text=%s&partner_id=3805"):format(api_id, tArgs["to"],  urllib.escape(msg)))
	
	if tArgs["from"] then
		local url=(("%s&from=%s"):format(url, urllib.escape(tArgs["from"])))
	elseif tArgs["time"] then
		local url=(("%s&time=%d"):format(url, tonumber(tArgs["time"])))
	end
	
	local res, err = httplib.request(url)
	if not res and err then
		os.exit(2)
	end
	local res=res:gsub("\n", " ")
	local res=res:match("^(%d+)%s+")
	if res then
		code=tonumber(res)
		if code == 100 then
			os.exit(0)
		elseif not code == 100 then
			os.exit(1)
		end
	else
		os.exit(1)
	end
end

if type(arg) == "table" then
	main()
end
