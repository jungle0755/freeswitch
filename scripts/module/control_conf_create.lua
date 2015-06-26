--require('conf_room')
--require('info_process')
--require('conf_control')

local util = require('common_util')

function Conference:create(room)
	local confID = room:getConfID()
	local managerID = room:getManagerID()
	local groupuri = room:getGroupURI()
	local host = room:getServerIP()

	local dialStr = "{alert_info='<http://www.huawei.com/alert.wav>;info=alert-autoanswer',sip_invite_contact_params='isfocus;confid="..confID..";conftype=00000100;groupuri="..groupuri.."'}"

	cmdStr = "conference "..confID.." dial "..dialStr.."sofia/internal/"..managerID.."%"..host.." "..managerID.." "..managerID
	freeswitch.consoleLog("info", "conference create:" .. cmdStr .. "\n")
	
	return api:executeString(cmdStr)
end

CreateConf = Base:new()
function CreateConf:execute(info)
	local managerID = info.body["attendee-eid"]
	local serviceType = tonumber(info.body["service-type"])

	local respBody = {}
	respBody["service-type"] = serviceType
	respBody["attendee-eid"] = managerID

	if 1 == serviceType then
		-- 语音会议

		-- 生成会议ID
		local confID = util.generateConfID(info.local_host)

		local requestID = tonumber(info.body["call-id"])
		-- 生成会场room
		local newRoom = Room:new(confID)
		newRoom:setManagerID(managerID)
		newRoom:setGroupURI(info.body["group-uri"])
		newRoom:setConfType(info.body["service-type"])
		newRoom:setServerIP(info.local_host)
		newRoom.requestID = requestID

		-- 保存会场信息Room
		Room:add(confID, newRoom)

		--  Send INFO 216 success
		respBody["cmd-type"] = 216
		respBody["call-id"] = requestID.."-"..confID
		respBody["conf-code"] = "9977"
		info:send(Info:toString(respBody))
	elseif 3 == serviceType then
		-- 数据会议

		local authCode = util.generateAuthCode()

		local confID = util.fetchConfIDFromCallID(info.body["call-id"])

		local room = Room:get(confID)

		if room then
			room:setAuthCode(authCode)
			room:setConfType(info.body["service-type"])

			--  Send INFO 216 success
			respBody["cmd-type"] = 216
			respBody["call-id"] = room.requestID.."-"..confID
			respBody["conf-code"] = "9977"
			respBody["authkey"] = authCode
			respBody["host-key"] = "111111"
			respBody["cm-address"] = info.host..":5060"
			info:send(Info:toString(respBody))

			-- 将创建者加入与会者列表
			room:addMember(managerID, MEMB_ATTR.ROLE.CHAIRMAN)

			-- 执行conf模块
			result = Conference:create(room)
		else
			freeswitch.consoleLog("notice", "no such room, confid="..confID.."\n")
		end
	else
		--其他
		freeswitch.consoleLog("err", "create other conference\n")
	end

end

-- feature register
function CreateConf:registerToControl(cmdType)
	createObj = CreateConf:new()
    Control:register(cmdType, createObj)
end

CreateConf:registerToControl(241)
