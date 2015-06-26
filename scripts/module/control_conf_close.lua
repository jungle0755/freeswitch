--require('conf_room')
--require('info_process')
--require('conf_control')


function Conference:close(confID)

	api:executeString("conference "..confID.." kick all")
end

CloseConf = Base:new()
function CloseConf:execute(info)
	print("Start close conference control")

	local serviceType = tonumber(info.body["service-type"])
	local confID = tonumber(info.body["call-id"])
	local room = Room:get(confID)

	if room then
		local body = {}
		body["service-type"] = serviceType
		body["cmd-type"] = 242
		body["call-id"] = confID
		info:send(Info:toString(body))

		Conference:close(confID)

	else
		print("no such room, confid="..confID.."\n")
	end
end

-- feature register
function CloseConf:registerToControl(cmdType)
	local obj = CloseConf:new()
    Control:register(cmdType, obj)
end

CloseConf:registerToControl(240)
