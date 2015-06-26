--require('conf_room')
--require('info_process')
--require('conf_control')

require('common_def')
local util = require('common_util')

function Conference:addMember(room, memberID)
	local confID = room:getConfID()
	local groupuri = room:getGroupURI()
	local host = room:getServerIP()

	local dialStr = "{alert_info='<http://www.huawei.com/alert.wav>',sip_contact_user="..memberID..",sip_invite_contact_params='isfocus;confid="..confID..";conftype=00000100;groupuri="..groupuri.."'}"

	cmdStr = "conference "..confID.." dial "..dialStr.."sofia/internal/"..memberID.."%"..host.." "..room:getManagerID().." "..room:getManagerID()
	
	return api:executeString(cmdStr)
end

AddMember = Base:new()
function AddMember:execute(info)
	local serviceType = tonumber(info.body["service-type"])
	local confID = util.fetchConfIDFromCallID(info.body["call-id"])
	local attendee_str = info.body["attendee-eid"]
	local room = Room:get(confID)
	
	if(nil == room) then
		freeswitch.consoleLog("err", "no such room, confid="..confID.."\n")
		return
	end

	local attendeeNum = 0;
	local attendee = {}

	for eid in string.gmatch(attendee_str, "%d+") do
		attendeeNum = attendeeNum + 1
		attendee[attendeeNum] = tonumber(eid)
	end

	local respBody = {}
	respBody["call-id"] = confID
	respBody["service-type"] = CONF_ATTR.TYPE.DATA

	if CONF_ATTR.TYPE.AUDIO == serviceType then
		for i = 1, attendeeNum do
			-- 通知振铃
			respBody["cmd-type"] = INFO_CMD.ADD.RINGING
			respBody["attendee-eid"] = attendee[i]
			info:send(Info:toString(respBody))

			-- 通过conf模块执行邀请
			result = Conference:addMember(room, attendee[i])

			if result then
				-- 通知入会
				respBody["cmd-type"] = INFO_CMD.ADD.SUCCESS
				info:send(Info:toString(respBody))
			else
				-- 失败
			end
		end
	else
		-- 其他
	end
end

-- feature register
function AddMember:registerToControl(cmdType)
	local obj = AddMember:new()
    Control:register(cmdType, obj)
end

AddMember:registerToControl(INFO_CMD.ADD.MEMB)
