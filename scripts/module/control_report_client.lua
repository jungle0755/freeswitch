--require('conf_room')
--require('info_process')
--require('conf_control')
--require('control_conf_create')

local util = require('common_util')

--send info 290 全量会议状态及与会者列表
local function sendConfStateMsg(info, room)
	local respBody = {}
	respBody["service-type"] = 3
	respBody["cmd-type"] = 290
	respBody["conf-state"] = 2
	respBody["confirm"] = 0
	respBody["call-id"] = room:getConfID()
	respBody["group-uri"] = room:getGroupURI()
	respBody["chairman"] = room:getManagerID()
	respBody["createtime"] = room:getCreateTime()

	local attendeelist = ""
	for key, value in pairs(room:getMemberList()) do
		attendeelist = attendeelist .. Attendee:toString(value)
	end

	respBody["attendeelist"] = attendeelist

	info:send(Info:toString(respBody))
end

ReportClientType = Base:new()
function ReportClientType:execute(info)
	local confID = util.fetchConfIDFromCallID(info.body["call-id"])
	local ip = info.body["ip"]
	local room = Room:get(confID)

	if room then
		--上报的终端保存为订阅者
        local clientInfo = {}
        clientInfo["service-type"] = info.body["service-type"]
        clientInfo["softphone_pickup"] = info.body["softphone_pickup"]
        clientInfo["ip"] = ip
        clientInfo["attendee-eid"] = util.fetchAttendeeFromRequest(info.body["attendee-eid"])
        
		room:addSubcriber(ip, clientInfo)
		sendConfStateMsg(info, room)
	else
		print("no such room, confid="..confID.."\n")
	end
end

-- feature register
function ReportClientType:registerToControl(cmdType)
	local obj = ReportClientType:new()
    Control:register(cmdType, obj)
end

ReportClientType:registerToControl(285)
