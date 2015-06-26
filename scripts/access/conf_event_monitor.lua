require('common_def')
require('conf_room')
require('conf_control')
require('info_process')

-- get user from uri, like '1007' in "1007%10.170.103.127"
local function fetchAttendeeIDFromCallNumber(callerNumber)
	if string.find(callerNumber, "%", 1, true) then
		for i in string.gmatch(callerNumber, "(%d+)%%%d+") do
			return i
		end
	else
		return callerNumber
	end
end

-- send info 292
local function sendConfMsg(room, attendeeID, client)
    local info = Info:new()
    info.user = attendeeID
    info.client = client
    info.host = room:getServerIP()

	local ops_ext_ip = freeswitch.getGlobalVariable("opensips-external-ip")
	
	local body = {}
    body["call-state"] = 0
	body["service-type"] = 3
    body["reason-code"] = 200
	body["cmd-type"] = 292
    body["peer-to-conf"] = 0
	body["isP2Pconf"] = 0
	body["rec"] = 0
    body["confirm"] = 0
    body["conf-state"] = 0
    body["status-flag"] = 0
    body["islock"] = 0
    body["sbj"] = "TEST"
	body["call-id"] = room:getConfID()
	body["attendee-eid"] = attendeeID
	body["authkey"] = room:getAuthCode()
	body["cm-address"] = ops_ext_ip .. ":5060"
	body["chairman"] = room:getManagerID()

	local event = freeswitch.Event("SEND_INFO");

	event:addHeader("local-user", info.user .. "@" .. info.host);
	event:addHeader("to-uri", "sip:"..info.user .. "@" .. info.client);

	event:addHeader("from-uri", "sip:mod_sofia".."@"..info.host);
	event:addHeader("User-Agent", "Huawei eSpace USM V200R003");
	event:addHeader("Content-Type", "application/Huawei-TAS");
	event:addHeader("Profile", "internal");
	event:addBody(Info:toString(body));
	event:fire();
end

-- send info 290 增量数据
local function sendConfStateAndAttendeeList(room, attendeeID)
	local confID = room:getConfID()
	local subcribers = room:getSubcriberList()

	if nil~= subcribers then
		for ip, subcriber in pairs(subcribers) do
			local info = Info:new()
			info.local_host = room:getServerIP()

			if("1" == subcriber["softphone_pickup"]) then
				-- soft phone pick up
				info.user = subcriber["attendee-eid"]
			elseif("2" == subcriber["softphone_pickup"]) then
				-- ms server pick up
				info.user = "ms"
			else
				-- other phone pick up
				info.user = subcriber["attendee-eid"]
			end

			info.client = ip
			info.host = room:getServerIP()

			local body = {}
			body["service-type"] = 3
			body["cmd-type"] = 290
			body["conf-state"] = 2
			body["confirm"] = room:getMemberCount()
			body["islock"] = 0
			body["call-id"] = room:getConfID()
			body["group-uri"] = room:getGroupURI()
			body["createtime"] = room:getCreateTime()
			
			local attendee = room:getMember(attendeeID)
			body["attendeelist"] = Attendee:toString(attendee)

			info:send(Info:toString(body))
		end
	end
end

local function processAddMemberEvent(event)
    local confID = event:getHeader("Conference-Name")
	local attendeeID = fetchAttendeeIDFromCallNumber(event:getHeader("Caller-Caller-ID-Number"))
	local client = event:getHeader("Caller-Network-Addr")
    local memberID = event:getHeader("Member-ID")

	local room = Room:get(confID)

	-- add attendee to room
	if attendeeID == room:getManagerID() then
		-- attendee is chairman
		room:addMember(attendeeID, 1, memberID)
	else
		room:addMember(attendeeID, 2, memberID)
	end

	-- send info 292 to this new attendee
	sendConfMsg(room, attendeeID, client)

	-- send info 290 to all conference subcribers
	sendConfStateAndAttendeeList(room, attendeeID)
end

local function processDelMemberEvent(event)
    local confID = event:getHeader("Conference-Name")
	local attendeeID = fetchAttendeeIDFromCallNumber(event:getHeader("Caller-Caller-ID-Number"))
	local client = event:getHeader("Caller-Network-Addr")
    
	local room = Room:get(confID)
    
    -- remove attendee from memberlist, change state to 6
    room:delMember(attendeeID)
    
    -- remove attendee from subcriberlist
    room:delSubcriber(client)
    
    -- send info 290 to all conference subcribers
	sendConfStateAndAttendeeList(room, attendeeID)
       
end

local function processDestroyConfEvent(event)
    local confID = event:getHeader("Conference-Name")
    
	Room:del(confID)
end

local function processMuteConfEvent(event, audioright)
    local confID = event:getHeader("Conference-Name")
    local attendeeID = fetchAttendeeIDFromCallNumber(event:getHeader("Caller-Caller-ID-Number"))
    
    local room = Room:get(confID)
    
    -- set audioright
    room:muteMember(attendeeID, audioright)
    
    -- send info 290 to all conference subcribers
	sendConfStateAndAttendeeList(room, attendeeID)
end

local function processConferenceEvent(event)
    local confID = event:getHeader("Conference-Name")
    if(CONF_EVENT.CREATE == event:getHeader("Action")) then
		freeswitch.consoleLog("info", "sxf>>>>>>>>>> conference create\n" .. event:serialize("xml"))

	elseif(CONF_EVENT.ADD == event:getHeader("Action")) then
        freeswitch.consoleLog("info", "sxf>>>>>>>>>> add member\n" .. event:serialize("xml"))
        processAddMemberEvent(event)
    elseif(CONF_EVENT.DEL == event:getHeader("Action")) then
		freeswitch.consoleLog("info", "sxf>>>>>>>>>> del member\n" .. event:serialize("xml"))
		processDelMemberEvent(event)
	elseif(CONF_EVENT.DESTROY == event:getHeader("Action")) then
		freeswitch.consoleLog("info", "sxf>>>>>>>>>> conference destroy\n" .. event:serialize("xml"))
		processDestroyConfEvent(event)
    elseif(CONF_EVENT.MUTE == event:getHeader("Action")) then
		freeswitch.consoleLog("info", "sxf>>>>>>>>>> conference mute\n" .. event:serialize("xml"))
		processMuteConfEvent(event, 1)
    elseif(CONF_EVENT.UNMUTE == event:getHeader("Action")) then
		freeswitch.consoleLog("info", "sxf>>>>>>>>>> conference unmute\n" .. event:serialize("xml"))
		processMuteConfEvent(event, 0)
    end
end

--main()
function main()
	freeswitch.consoleLog("info", "conference event monitor process start\n")
	
    con = freeswitch.EventConsumer("CUSTOM","conference::maintenance");
    api = freeswitch.API();

    for e in (function() return con:pop(1) end) do

		freeswitch.consoleLog("info", "sxf>>>>>>>>>> conference event:" .. e:getHeader("Action") .. "\n")

		processConferenceEvent(e)
    end
end

main()
