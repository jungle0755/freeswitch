
function Conference:muteConf(confID,audioRight)
	if( MEMB_ATTR.RIGHT.AUDIO_YES == audioRight)then
	    print("begin to cancle mute conf, use conference module")
	    api:executeString("conference "..confID.." unmute all")
	else
	    print("start mute conf, use conference module")
		api:executeString("conference "..confID.." mute all")
	end
end

function Conference:muteMember(confID,memberID,audioRight)
	if( MEMB_ATTR.RIGHT.AUDIO_YES == audioRight)then
	    print("begin to cancle mute conf, use conference module")
	    api:executeString("conference "..confID.." unmute "..memberID)
	else
	    print("start mute conf, use conference module")
		api:executeString("conference "..confID.." mute "..memberID)
	end
end

MuteConf = Base:new()
function MuteConf:execute(info)
    print("Begin to mute the conf")
	
	local serviceType = tonumber(info.body["service-type"])
	local confID = tonumber(info.body["call-id"])
	local cmdType = tonumber(info.body["cmd-type"])
	local attendeeID = info.body["attendee-eid"]
	local confRoom = Room:get(confID)
    local audioRight = MEMB_ATTR.RIGHT.AUDIO_YES
	if( nil == confRoom) then
	    print("Get confRoom by confid="..confID.."failed\n")
		return
	end
	
	if((cmdType == INFO_CMD.MUTE.ALL_CANCLE) or (cmdType == INFO_CMD.MUTE.CANCEL )) then
	    audioRight = MEMB_ATTR.RIGHT.AUDIO_YES
	else
	    audioRight = MEMB_ATTR.RIGHT.AUDIO_NO
	end

	if( CONF_ATTR.TYPE.AUDIO == serviceType) then
	    if(nil == attendeeID) then
		    result = Conference:muteConf(confID,audioRight)
		    --confRoom:muteConf(audioRight)
		else
            local memberID = confRoom:getMemberIDByNumber(attendeeID)
		    result = Conference:muteMember(confID,memberID,audioRight)
			--confRoom:muteMember(attendeeID,audioRight)
		end
	else
	    print("not supported the servicetype "..serviceType.."\n")
	end

end

function MuteConf:registerToControl(cmdType)
    local obj = MuteConf:new()
	Control:register(cmdType, obj)
end

MuteConf:registerToControl(INFO_CMD.MUTE.SURE)
MuteConf:registerToControl(INFO_CMD.MUTE.CANCEL)
MuteConf:registerToControl(INFO_CMD.MUTE.ALL_SURE)
MuteConf:registerToControl(INFO_CMD.MUTE.ALL_CANCLE)
