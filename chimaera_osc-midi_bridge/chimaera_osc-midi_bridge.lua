--[[
-- Copyright (c) 2014 Hanspeter Portner (dev@open-music-kontrollers.ch)
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
conf_server, err = renoise.Socket.create_server(4444, renoise.Socket.PROTOCOL_UDP)
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

-- open a socket connection to the server
conf_client, err = renoise.Socket.create_client( 'chimaera.local', 4444, renoise.Socket.PROTOCOL_UDP)
if err then 
  renoise.app():show_warning(('Failed to start the OSC client. Error: %s'):format(err))
  return
end

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

f = io.input('/etc/hostname')
hostname = f:read('*l')
f:close()

-- construct and send messages
conf_client:send( OscMessage('/engines/reset', { uuid() }) )
conf_client:send( OscMessage('/engines/offset', { uuid(), oscarg.f(0.002) }) )
conf_client:send( OscMessage('/engines/parallel', { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage('/engines/enabled', { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage('/engines/address', { uuid(), oscarg.s(hostname .. '.local:8000') }) )
conf_client:send( OscMessage('/engines/server', { uuid(), oscarg.i(0) }) )
conf_client:send( OscMessage('/engines/mode', { uuid(), oscarg.s('osc.udp') }) )
conf_client:send( OscMessage('/engines/enabled', { uuid(), oscarg.i(1) }) )
		
dest  = oscarg.s('/renoise/trigger/midi')
conf_client:send( OscMessage('/engines/custom/enabled', { uuid(), oscarg.i(1) }) )
conf_client:send( OscMessage('/engines/custom/reset', { uuid() }) )
conf_client:send( OscMessage('/engines/custom/append', { uuid(), oscarg.s('on'), dest,
	oscarg.s('i(0x7f0090 $g| 13.5 $n 18% 6/- $n 3/ $x @@ $g[*+ 8<<|)') }) );
conf_client:send( OscMessage('/engines/custom/append', { uuid(), oscarg.s('off'), dest,
	oscarg.s('i(0x7f0080 $g| 13.5 $n 18% 6/- $n 3/ $g]*+ 8<<|)') }) );
conf_client:send( OscMessage('/engines/custom/append', { uuid(), oscarg.s('set'), dest,
	oscarg.s('i(0xe0 $g| $x $g]- 0x2000* 0x1fff+ @@ 7>> 16<< # 0x7f& 8<<| |)') }) );
conf_client:send( OscMessage('/engines/custom/append', { uuid(), oscarg.s('set'), dest,
	oscarg.s('i(0x27b0 $g| $z 0x3fff* 0x7f& 16<<|)') }) );
conf_client:send( OscMessage('/engines/custom/append', { uuid(), oscarg.s('set'), dest,
	oscarg.s('i(0x07b0 $g| $z 0x3fff* 7>> 16<<|)') }) );

conf_client:send( OscMessage('/sensors/rate', { uuid(), oscarg.i(2000) }) )
conf_client:send( OscMessage('/sensors/group/reset', { uuid() }) )
conf_client:send( OscMessage('/sensors/group/attributes/0', { uuid(), oscarg.f(0.0), oscarg.f(1.0), oscarg.i(0), oscarg.i(1), oscarg.i(0) }) )
conf_client:send( OscMessage('/sensors/group/attributes/1', { uuid(), oscarg.f(0.0), oscarg.f(1.0), oscarg.i(1), oscarg.i(0), oscarg.i(0) }) )
conf_client:send( OscMessage('/sensors/number', { uuid() }) )
