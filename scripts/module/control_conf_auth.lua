--require('conf_room')
--require('info_process')
--require('conf_control')


--send info 601
local function sendConfAuthResponse(info, room)
	print("Send conference auth message")
	local respBody = {}
	respBody["service-type"] = 3
	respBody["cmd-type"] = 601
	respBody["conf-state"] = 2
	respBody["call-id"] = room:getConfID()
	respBody["authkey"] = room:getAuthCode()
	respBody["host-key"] = "111111"

	info:send(Info:toString(respBody))
end


ConfAuth = Base:new()
function ConfAuth:execute(info)
	print("Start conference auth message")

	local serviceType = tonumber(info.body["service-type"])
	local confID = tonumber(info.body["call-id"])

	local room = Room:get(confID)
	if room then
		sendConfAuthResponse(info, room)
	else
		print("no such room, confid="..confID.."\n")
	end
end

-- feature register
function ConfAuth:registerToControl(cmdType)
	local obj = ConfAuth:new()
    Control:register(cmdType, obj)
end

ConfAuth:registerToControl(600)








