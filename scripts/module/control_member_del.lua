--require('conf_room')
--require('info_process')
--require('conf_control')

function Conference:delMember(confID, memberID)
	print("start del member, use conference module")
    local cmd = "conference " ..confID.. " kick " ..memberID
    if nil ~= memberID then
        api:executeString(cmd)
    else
        print("execute del member failed")
    end
end

DelMember = Base:new()
function DelMember:execute(info)
	print("Start del member control")

	local serviceType = tonumber(info.body["service-type"])
	local confID = tonumber(info.body["call-id"])
	local attendee = info.body["attendee-eid"]

	local room = Room:get(confID)
	if(nil == room) then
		print("no such room, confid="..confID.."\n")
		return
	end
    
    local memberID = room:getMemberIDByNumber(attendee)

	if CONF_ATTR.TYPE.AUDIO == serviceType then
		print("delMember service-type 1")
		result = Conference:delMember(confID, memberID)
		
	else
		-- 其他
		print("delMember other service-type")
	end
end

-- feature register
function DelMember:registerToControl(cmdType)
	local obj = DelMember:new()
    Control:register(cmdType, obj)
end

DelMember:registerToControl(INFO_CMD.DEL.MEMB)
