--[[
-- Copyright (c) 2015 Hanspeter Portner (dev@open-music-kontrollers.ch)
-- 
-- This software is provided 'as-is', without any express or implied
-- warranty. In no event will the authors be held liable for any damages
-- arising from the use of this software.
-- 
-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:
-- 
--     1. The origin of this software must not be misrepresented; you must not
--     claim that you wrote the original software. If you use this software
--     in a product, an acknowledgment in the product documentation would be
--     appreciated but is not required.
-- 
--     2. Altered source versions must be plainly marked as such, and must not be
--     misrepresented as being the original software.
-- 
--     3. This notice may not be removed or altered from any source
--     distribution.
--]]

-- create some handy shortcuts
OscMessage = renoise.Osc.Message

-- open a socket connection to the server
conf_client, err = renoise.Socket.create_client('chimaera.local', 4444, renoise.Socket.PROTOCOL_UDP)
if err then
  renoise.app():show_warning(('Failed to start the OSC client. Error: %s'):format(err))
  return
end

print(conf_client.local_address)
print(conf_client.local_port)
print(conf_client.peer_address)
print(conf_client.peer_port)

-- open a socket connection to the server
conf_server, err = renoise.Socket.create_server(conf_client.local_port, renoise.Socket.PROTOCOL_UDP)
if err then 
	renoise.app():show_warning(('Failed to start the OSC server. Error: %s'):format(err))
  return
end

conf_methods = {
	['/success'] = function(args)
		local uuid = args[1].value
		local path = args[2].value
		print('success', uuid, path)
	end,

	['/fail'] = function(args)
		local uuid = args[1].value
		local path = args[2].value
		local err = args[3].value
		print('fail', uuid, path, err)
	end
}

conf_server:run({
  socket_message = function(socket, data)
    -- decode the data to Osc
    local osc, err = renoise.Osc.from_binary_data(data)
    
    -- show what we've got
    if osc then
			local meth = conf_methods[osc.pattern]
			if meth then
				meth(osc.arguments)
			end
    else
      print(('Got invalid OSC data, or data which is not OSC data at all. Error: %s'):format(err))
    end
	end
})

oscarg = {}
setmetatable(oscarg, {
	__index = function(self, k)
		return function(v)
			return { tag=k, value=v }
		end
	end
})

uuid = function()
	local rand = math.random
	return oscarg.i(rand(1024))
end

osc_false = oscarg.i(0)
osc_true = oscarg.i(1)

N = 160
offset = (3.0*12.0 - 0.5 - (N % 18 / 6.0))
range = N / 3.0

-- construct and send messages
conf_client:send( OscMessage('/engines/reset', { uuid() }) )
conf_client:send( OscMessage('/engines/offset', { uuid(), oscarg.f(0.0025) }) )
conf_client:send( OscMessage('/engines/parallel', { uuid(), osc_false }) )
conf_client:send( OscMessage('/engines/enabled', { uuid(), osc_false }) )
conf_client:send( OscMessage('/engines/address', { uuid(), oscarg.s(conf_client.local_address .. ':8000') }) )
conf_client:send( OscMessage('/engines/server', { uuid(), osc_false }) )
conf_client:send( OscMessage('/engines/mode', { uuid(), oscarg.s('osc.udp') }) )
conf_client:send( OscMessage('/engines/enabled', { uuid(), osc_true }) )

conf_client:send( OscMessage('/sensors/rate', { uuid(), oscarg.i(2000) }) )
conf_client:send( OscMessage('/sensors/group/reset', { uuid() }) )
conf_client:send( OscMessage("/sensors/group/attributes/0/min", { uuid(), oscarg.f(0.0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/0/max", { uuid(), oscarg.f(1.0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/0/north", { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/0/south", { uuid(), oscarg.i(1) }) )
conf_client:send( OscMessage("/sensors/group/attributes/0/scale", { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/1/min", { uuid(), oscarg.f(0.0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/1/max", { uuid(), oscarg.f(1.0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/1/north", { uuid(), oscarg.i(1) }) )
conf_client:send( OscMessage("/sensors/group/attributes/1/south", { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage("/sensors/group/attributes/1/scale", { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage('/sensors/number', { uuid() }) )
		
conf_client:send( OscMessage('/engines/oscmidi/enabled', { uuid(), osc_true }) )
conf_client:send( OscMessage('/engines/oscmidi/multi', { uuid(), osc_false }) )
conf_client:send( OscMessage('/engines/oscmidi/path', { uuid(), oscarg.s('/renoise/trigger/midi') }) )
conf_client:send( OscMessage('/engines/oscmidi/format', { uuid(), oscarg.s('int32') }) )
conf_client:send( OscMessage('/engines/oscmidi/reset', { uuid() }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/0/mapping', { uuid(), oscarg.s('control_change') }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/0/offset', { uuid(), oscarg.f(offset) }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/0/range', { uuid(), oscarg.f(range) }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/0/controller', { uuid(), oscarg.i(0x07) }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/1/mapping', { uuid(), oscarg.s('control_change') }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/1/offset', { uuid(), oscarg.f(offset) }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/1/range', { uuid(), oscarg.f(range) }) )
conf_client:send( OscMessage('/engines/oscmidi/attributes/1/controller', { uuid(), oscarg.i(0x07) }) )
