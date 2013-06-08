-- ***************************************************************************
-- smsrulib - Lua bindings for the sms.ru API. 
-- Lets you send messages, check their status, find their cost etc.

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
local base = _G
module('smsrulib')
_DEBUG = false
_HTTP_TIMEOUT = 10 -- timeout for all luasocket I/O operations
_VERSION = '0.1'
local httplib = base.require 'socket.http'
local urllib = base.require 'socket.url'
httplib.TIMEOUT = _HTTP_TIMEOUT
smsru = {}
--httplib.PROXY = ""
--httplib.USERAGENT = 'smsrulib_version_'.._VERSION..'_(http://opensource.hub21.ru/smssend.lua)'
-- *************************************************************
local function tracert(...)
	if _DEBUG then
		base.print(...)
	end
end

local function isset(d)
	if d and base.type(d) == 'string' then
		return true
	elseif d and base.type(d) == "number" and d == 1 then
		return true
	end
end

local function build_http_query(t)
	local s,c = '',0
	for i,v in base.pairs(t) do
		if isset(v) then
			c = c +1
			tracert(i,v)
			if c ~= 1 then
				s=(('%s&%s=%s'):format(s, i ,urllib.escape(v)))
			else 
				s =(('%s%s=%s'):format(s, i, urllib.escape(v)))
			end
		end
	end
	return s
end

function service_call(method, args)
	local methods={ ['sms/send'] = true, ['auth/get_token'] = true, ['auth/check'] = true, 
					['sms/status'] = true, ['sms/cost'] = true,
					['my/balance'] = true, ['my/limit'] = true,
					['stoplist/add'] = true, ['stoplist/del'] = true,}
	if not method or not methods[method] then
		base.error('Method not found or is not supported')
		return
	end
	local url=''
	if base.type(args) == 'table' then
		url = (('http://sms.ru/%s?%s'):format(method, build_http_query(args)))
	else
		url = (('http://sms.ru/%s'):format(method))
	end
	tracert('@service_call','request: ', url)
	local res, err = httplib.request(url)
	if not res then
		tracert('@service_call: ', err)
		return nil, (('socket.http error: %s'):format(err))
	end
	tracert('@service_call:', 'Recv: ', res)
	local result = res:split('\n')
	if result then
		return result
	end
end

function base.string:split(separator, max, bregexp)
    base.assert(separator ~= '')
    base.assert(max == nil or max >= 1)

    local record = {}

    if self:len() > 0 then
        local plain = not bregexp
        max = max or -1

        local field=1 start=1
        local first,last = self:find(separator, start, plain)
        while first and max ~= 0 do
            record[field] = self:sub(start, first-1)
            field = field+1
            start = last+1
            first,last = self:find(separator, start, plain)
            max = max-1
        end
        record[field] = self:sub(start)
    end
    return record
end


function init(myphone, password)
	mt = base.setmetatable({login = myphone, password = password}, {__index = smsru })
	if mt:init() then	
		return mt
	end
end

function smsru:init()
	if self:test_auth() == 100 then
		return true
	end
end

function smsru:get_crypt_key()
	self.token = self:get_token()
	local bcrypto,cryptlib = base.pcall(base.require, 'crypto') -- http://luacrypto.luaforge.net/
	if bcrypto then
		tracert('@get_crypt_key: using \'crypto\' library')
		return cryptlib.digest('SHA512',self.password..self.token)
	end
	local bsha2, shalib = base.pcall(base.require,'sha2') -- http://code.google.com/p/sha2/
	if bsha2 then
		tracert('@get_crypt_key: using \'sha2\' library')
		return shalib.sha512hex(self.password..self.token)
	end
end

function smsru:get_token()
	result = service_call('auth/get_token')
	if result then 
		return result[1]
	end
end

function smsru:send(to, text, from, time, translit, test)	
	if test then
		test="1"
	elseif translit then
		translit = "1"
	end
	
	local result = service_call('sms/send', {
					login = self.login,
					sha512 = self:get_crypt_key(), 
					token = self.token,
					to = to,
					text = text, 
					from = from, 
					time = time, 
					translit = translit, 
					test = test,
					partner_id = 3805})
	if result and base.type(result) == 'table' then
		if base.tonumber(result[1]) == 100 then
			return true, result[2]
		else
			return nil, result[1] and base.tonumber(result[1])
		end
	end
end

function smsru:status(id)
	result = service_call('sms/status', {
				login = self.login, 
				sha512 = self:get_crypt_key(), 
				token = self.token, 
				id = id})
	if result then
		return result[1] and base.tonumber(result[1])
	end
end

function smsru:cost(to, message)
	local result = service_call('sms/cost',{
					login = self.login,
					sha512 = self:get_crypt_key(),
					token = self.token,
					text = message,
					to = to})
	if result and base.type(result) == 'table' then
		if base.tonumber(result[1]) == 100 then
			return true, result
		else
			return nil, result[1] and base.tonumber(result[1])
		end 
	end	
end

function smsru:balance()
	local result = service_call('my/balance',{
					login = self.login,
					sha512 = self:get_crypt_key(),
					token = self.token})
	if result and base.type(result) == 'table' then
		if base.tonumber(result[1]) == 100 then
			return true, result[2]
		else 
			return nil, result[1] and base.tonumber(result[1])
		end
	end
end

function smsru:limit()
	local result = service_call('my/limit',{
					login = self.login,
					sha512 = self:get_crypt_key(),
					token = self.token})
	if result and base.type(result) == 'table' then
		
		if base.tonumber(result[1]) == 100 then
			return true, result
		else 
			return nil, result
		end
	end
end

function smsru:stoplist_add(phone, reason)
	local result = service_call('stoplist/add',{
		login = self.login,
		sha512 = self:get_crypt_key(),
		token = self.token,
		stoplist_phone = phone,
		stoplist_text = reason,
	})
	if result and base.type(result) == 'table' then
		if base.tonumber(result[1]) == 100 then
			return true
		elseif base.tonumber(result[1]) == 202 then
			return false
		end
	end
end

function smsru:stoplist_del(phone)
	local result = service_call('stoplist/del',{
		login = self.login,
		sha512 = self:get_crypt_key(),
		token = self.token,
		stoplist_phone = phone
	})
	if result and base.type(result) == 'table' then
		if base.tonumber(result[1]) == 100 then
			return true
		elseif base.tonumber(result[1]) == 202 then
			return false
		end
	end
end

function smsru:stoplist_get() -- TODO: FIXME
	local result = service_call('stoplist/get',{
		login = self.login,
		sha512 = self:get_crypt_key(),
		token = self.token,
	})
	
	if result and base.type(result) == 'table' then
		return result
	end
end

function smsru:test_auth()
	local result = service_call('auth/check', {
		login = self.login,
		sha512 = self:get_crypt_key(),
		token = self.token
	})
	if result and base.type(result) == 'table' then
		return result[1] and base.tonumber(result[1])
	end
end
