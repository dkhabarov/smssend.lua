#!/usr/bin/env lua5.1
-- ***************************************************************************
-- smssend - is a program to send SMS messages from the commandline. (Lua Version)

-- Copyright © 2013 Denis Khabarov aka 'Saymon21'
-- E-Mail: saymon at hub21 dot ru (saymon@hub21.ru)

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License version 3
-- as published by the Free Software Foundation.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- ***************************************************************************
local smsrulib = require('smsrulib')
local tArgs = {}
local _EXIT_SUCCESS = 0
local _EXIT_SMSRU_ERR = 1
local _EXIT_ERRUSE =  2
local _MYVERSION = '0.2-beta'

function show_help()
	print('\n\tsmssend is a program to send SMS messages from the commandline.\n\tUsing API service http://sms.ru\
\tCopyright © 2009-2012 by Denis Khabarov aka \'Saymon21\'\n\tE-Mail: saymon at hub21 dot ru (saymon@hub21.ru)\
\tHomepage: http://opensource.hub21.ru/smssend.lua\n\n\tOptions:')
	print('\t--help', '- show this help')
	print('\t--version', '- show version')
	print('\t--login', '- login at service sms.ru')
	print('\t--password', '- password at service sms.ru')
	print('\t--action', '- run action (available actions: send, status, cost, balance, limit, stoplistadd, stoplistdel)')
	print('\t--to', '- send message to this phone number')
	print('\t--message', '- don\'t read stdin. Send text from this argument')
	print('\t--from', '- sender name')
	print('\t--time', '- set send time (in unixtime format)')
	print('\t--translit', '- convert message to translit')
	os.exit(_EXIT_SUCCESS)
end

function cliarg_parser()
	if arg then
		local available_args = {
			['login'] = true, ['password'] = true, 
			['action'] = true, ['to'] = true, 
			['message'] = true, ['from'] = true, 
			['time'] = true, ['help']= true,
			['translit'] = true, ['version'] = true,
			--['debug'] = true,
 		}
 		for _, val in ipairs(arg) do
			if val:find('=', 1, true) then
				local name, value = val:match('%-%-(.-)=(.+)')
				if name and value and available_args[name:lower()] then
					tArgs[name:lower()] = value
				else
					print(('Unknown commandline argument used: %s\nusage: %s --help'):format(val,arg[0]))
					os.exit(_EXIT_ERRUSE)
				end
			else
				name = val:match('%-%-(.+)')
				if name and  available_args[name:lower()] then
					tArgs[name:lower()] = true
				else
					print(('Unknown commandline argument used: %s\nusage: %s --help'):format(val,arg[0]))
					os.exit(_EXIT_ERRUSE)
				end
			end
		end
		if not tArgs.action then
			tArgs.action = 'send' -- Set default action. (Send SMS message)
		else 
			tArgs.action = tArgs.action:lower()
		end
		if tArgs.help then
			show_help()
		end
		if tArgs.version then
			print(('smssend.lua version: %s'):format(_MYVERSION))
			os.exit(_EXIT_SUCCESS)
		end
	end
end

function get_os()
	local path_separator = package.config:sub(1,1)
	if path_separator == '/' then
		return 1 -- Unix
	elseif path_separator == '\\' then
		return 2 -- Win
	end
end

function get_home_path()
	local _os = get_os()
	if _os == 1 then
		home = os.getenv('HOME')
	elseif _os == 2 then
		home = os.getenv("USERPROFILE")
	else 
		os.exit(_EXIT_ERRUSE)
	end
	return home
end

function read_smssendrc()
	local home = get_home_path()
	if home then
		h=io.open(home..'/.smssendrc','r')
		if h then
			data=h:read()
		end
	end
	if data then
		local login, password = data:match('(%d+):(.+)')
		if login and password then
			return login, password	 
		end
	end		
end

function getpass()
    local stty_ret = os.execute('stty -echo 2>/dev/null')
    if stty_ret ~= 0 then
        io.write('\027[08m') -- ANSI 'hidden' text attribute
    end
    local ok, pass = pcall(io.read, "*l")
    if stty_ret == 0 then
        os.execute("stty sane")
    else
        io.write("\027[00m")
    end
    io.write("\n")
    if ok then
        return pass
    end
end

function getchar(n)
    local stty_ret = os.execute("stty raw -echo 2>/dev/null")
    local ok, char
    if stty_ret == 0 then
        ok, char = pcall(io.read, n or 1)
        os.execute("stty sane")
    else
        ok, char = pcall(io.read, "*l")
        if ok then
            char = char:sub(1, n or 1)
        end
    end
    if ok then
        return char
    end
end

function show_yesno(prompt)
    io.write(prompt, " ")
    local choice = getchar():lower()
    io.write("\n");
    if not choice:match("%a") then
        choice = prompt:match("%[.-(%U).-%]$")
        if not choice then 
        	return nil 
        end
    end
    return (choice == "y")
end

function read_password()
    local password
    while true do
        io.write("Enter password: ")
        password = getpass();
        if not password then
            print("No password - cancelled")
            return
        end
        io.write("Retype password: ")
        if getpass() ~= password then
            if not show_yesno('Passwords did not match, try again? [Y/n]') then
                return
            end
        else
            break
        end
    end
    return password
end

function term_get_login()
	local login 
	io.write('Enter login: ')
	local ok, login = pcall(io.read, "*l")
	if ok then
		return login		
	elseif not ok then
		print('No login cancelled')
		return nil
	end
end

function get_msg()
	if tArgs.message then
		return tArgs.message
	else
		return io.stdin:read()
	end
end

function main()
	cliarg_parser()
	if not tArgs.login or not tArgs.password then
		login, password = read_smssendrc()
		if login and password then
			tArgs.login = login
			tArgs.password = password
		else 
			login = term_get_login()
			if not login then
				os.exit(_EXIT_ERRUSE)
			else 
				tArgs.login = login
			end
			password = read_password()
			if not password then
				print('No password - cancelled')
				os.exit(_EXIT_ERRUSE)
			else
				tArgs.password = password
			end
		end
	end
	sms_client = smsrulib.init(tArgs.login, tArgs.password)
	if not sms_client or type(sms_client) ~= 'table' then
		print('Error. Unable to initialize client.')
		os.exit(3)
	end
	if tArgs.action == 'send' then
		sms_send()
	elseif tArgs.action == 'status' then
		sms_status()
	elseif tArgs.action == 'cost' then
		sms_cost()
	elseif tArgs.action == 'balance' then
		get_balance()
	elseif tArgs.action == 'limit' then
		get_limit()
	elseif tArgs.action == 'stoplistadd' then
		stoplist_add()
	elseif tArgs.action == 'stoplistdel' then
		stoplist_del()
	else 
		print('Unknown action.')
		os.exit(_EXIT_ERRUSE)
	end
end

function sms_status()
	if not tArgs.message or type(tArgs.message) ~= 'string' then
		print('Invalid value for argument \'message\'.')
		os.exit(_EXIT_ERRUSE)
	end
	local _STATUSES={
	[-1] = 'Сообщение не найдено.',
	[100] = 'Сообщение находится в нашей очереди',
	[101] = 'Сообщение передается оператору',
	[102] = 'Сообщение отправлено (в пути)',
	[103] = 'Сообщение доставлено',
	[104] = 'Не может быть доставлено: время жизни истекло',
	[105] = 'Не может быть доставлено: удалено оператором',
	[106] = 'Не может быть доставлено: сбой в телефоне',
	[107] = 'Не может быть доставлено: неизвестная причина',
	[108] = 'Не может быть доставлено: отклонено',
	[200] = 'Неправильный api_id',
	[210] = 'Используется GET, где необходимо использовать POST',
	[211] = 'Метод не найден',
	[220] = 'Сервис временно недоступен, попробуйте чуть позже.',
	[300] = 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)',
	[301] = 'Неправильный пароль, либо пользователь не найден',
	[302] = 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)',
	}
	local res = sms_client:status(tArgs.message)
	if res then
		print(('%s: %s'):format(tArgs.message,(_STATUSES[res] and _STATUSES[res] or res)))
		os.exit(_EXIT_SUCCESS)	
	end
end

function sms_cost()
	local msg = get_msg()
	if not tArgs.to or not tArgs.to:match("^%d+$") then
		print('Invalid value for argument \'to\'.')
		os.exit(_EXIT_ERRUSE)
	end
	
	local _STATUSES = {
		[100] = 'Запрос выполнен. На второй строчке будет указана стоимость сообщения. На третьей строчке будет указана его длина.',
		[200] = 'Неправильный api_id',
		[202] = 'Неправильно указан получатель',
		[207] = 'На этот номер нельзя отправлять сообщения',
		[210] = 'Используется GET, где необходимо использовать POST',
		[211] = 'Метод не найден',
		[220] = 'Сервис временно недоступен, попробуйте чуть позже.',
		[300] = 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)',
		[301] = 'Неправильный пароль, либо пользователь не найден',
		[302] = 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)',
	
	}
	
	local res,data = sms_client:cost(tArgs.to,get_msg())
	if res then
		print(('\nCost: %s\nSMS Count: %s\n'):format((data[2] and data[2] or '?'),(data[3] and data[3] or '?')))
		os.exit(_EXIT_SUCCESS)
	else
		print('Error:',(_STATUSES[data] and _STATUSES[data] or 'Unable to get cost sms message. SMS.ru return code: '..data))
		os.exit(_EXIT_SMSRU_ERR)
	end
end

function sms_send()
	if not tArgs.to or not tArgs.to:match("^%d+$") then
		print('Invalid value for argument \'to\'.')
		os.exit(_EXIT_ERRUSE)
	end
	local _STATUSES={
		[100] = 'Сообщение принято к отправке. На следующих строчках вы найдете идентификаторы отправленных сообщений в том же порядке, в котором вы указали номера, на которых совершалась отправка.',
		[200] = 'Неправильный api_id',
		[201] = 'Не хватает средств на лицевом счету',
		[202] = 'Неправильно указан получатель',
		[203] = 'Нет текста сообщения',
		[204] = 'Имя отправителя не согласовано с администрацией',
		[205] = 'Сообщение слишком длинное (превышает 8 СМС)',
		[206] = 'Будет превышен или уже превышен дневной лимит на отправку сообщений',
		[207] = 'На этот номер (или один из номеров) нельзя отправлять сообщения, либо указано более 100 номеров в списке получателей',
		[208] = 'Параметр time указан неправильно',
		[209] = 'Вы добавили этот номер (или один из номеров) в стоп-лист',
		[210] = 'Используется GET, где необходимо использовать POST',
		[211] = 'Метод не найден',
		[212] = 'Текст сообщения необходимо передать в кодировке UTF-8 (вы передали в другой кодировке)',
		[220] = 'Сервис временно недоступен, попробуйте чуть позже.',
		[230] = 'Сообщение не принято к отправке, так как на один номер в день нельзя отправлять более 100 сообщений.',
		[300] = 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)',
		[301] = 'Неправильный пароль, либо пользователь не найден',
		[302] = 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)',
	}
	local res,errcode = sms_client:send(tArgs.to, get_msg(), tArgs.from, tArgs.time, tArgs.translit)
	if res and errcode then
		os.exit(_EXIT_SUCCESS)
	elseif not res then
		print('Error:',(_STATUSES[errcode] and _STATUSES[errcode] or 'Unable to send sms message. SMS.ru return code: '..errcode))
		os.exit(_EXIT_SMSRU_ERR)
	end
end

function get_balance()
	local _STATUSES = {
		[100] = 'Запрос выполнен. На второй строчке вы найдете ваше текущее состояние баланса.',
		[200] = 'Неправильный api_id',
		[210] = 'Используется GET, где необходимо использовать POST',
		[211] = 'Метод не найден',
		[220] = 'Сервис временно недоступен, попробуйте чуть позже.',
		[300] = 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)',
		[301] = 'Неправильный пароль, либо пользователь не найден',
		[302] = 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)',
	}
	local res,data = sms_client:balance()
	if res and data then
		print(('Balance: %s'):format((data and data or '?')))
		os.exit(_EXIT_SUCCESS)
	else 
		print('Error:',(_STATUSES[data] and _STATUSES[data] or 'Unable to get balance. SMS.ru return code: '..data))
		os.exit(_EXIT_SMSRU_ERR)
	end
end

function get_limit()
	local _STATUSES = {
		[100] = 'Запрос выполнен. На второй строчке вы найдете ваше текущее дневное ограничение. На третьей строчке количество сообщений, отправленных вами в текущий день.',
		[200] = 'Неправильный api_id',
		[210] = 'Используется GET, где необходимо использовать POST',
		[211] = 'Метод не найден',
		[220] = 'Сервис временно недоступен, попробуйте чуть позже.',
		[300] = 'Неправильный token (возможно истек срок действия, либо ваш IP изменился)',
		[301] = 'Неправильный пароль, либо пользователь не найден',
		[302] = 'Пользователь авторизован, но аккаунт не подтвержден (пользователь не ввел код, присланный в регистрационной смс)',
	}
	local res,code = sms_client:limit()
	if res then
		print(('\nDay limit: %s\nMessages (Count) sent today: %s'):format((code[2] and code[2] or '?'), (code[3] and code[3] or '?')))
		os.exit(_EXIT_SUCCESS)
	else 
		print('Error:',(_STATUSES[code[1]] and _STATUSES[code[1]] or 'Unable to get limit. SMS.ru return code: '..code[1]))
		os.exit(_EXIT_SMSRU_ERR)
	end
end

function stoplist_add()
	if not tArgs.to or not tArgs.to:match("^%d+$") then
		print('Invalid value for argument \'to\'.')
		os.exit(_EXIT_ERRUSE)
	elseif not tArgs.message or type(tArgs.message) ~= 'string' then
		print('Invalid value for argument \'message\'.')
		os.exit(_EXIT_ERRUSE)
	end
	local res = sms_client:stoplist_add(tArgs.to, tArgs.message)
	if res then
		os.exit(_EXIT_SUCCESS)
	else
		print('Invalid phone number format')
		os.exit(_EXIT_SMSRU_ERR)
	end
end

function stoplist_del()
	if not tArgs.to or not tArgs.to:match('^%d+$') then
		print('Invalid value for argument \'to\'.')
		os.exit(_EXIT_ERRUSE)
	end
	local res = sms_client:stoplist_del(tArgs.to)
	if res then
		os.exit(_EXIT_SUCCESS)
	else 
		print('Invalid phone number format')
		os.exit(_EXIT_SMSRU_ERR)
	end
end

if arg and type(arg) == 'table' then
	main()
end
