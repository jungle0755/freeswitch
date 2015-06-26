require('conf_room')
--require('conf_control')
require('info_process')

local dao = require('conf_dao')
local util = require('common_util')

function onInputCBF(s, type, obj, org)
    if(type == "dtmf") then
        freeswitch.consoleLog("INFO", "Got FTMF:"..obj.digit.." Duration: ".. obj.duration.."\n")
        if(obj.digit == "0") then
            return 'break'
        elseif(obj.digit == "9") then
            -- 设置re-invite头域contact的内容，并发送re-invite请求

            freeswitch.API():executeString("uuid_media_reneg "..session:get_uuid())
        end
    end
    return ''
end

local function sendConfMsg(room)
    local info = Info:new()
    info.user = "1006"
    info.client = "10.170.49.157"
    info.host = "10.170.103.127"

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
    body["attendee-eid"] = "1006"
    body["authkey"] = room:getAuthCode()
    body["cm-address"] = room:getServerIP()..":5060"
    body["chairman"] = room:getManagerID()

    info:send(Info:toString(body))
end

-- get conference number from input
local function get_conference_num(min, max, attempts, timeout)
  local conference_num
  freeswitch.consoleLog("NOTICE", "Awaiting caller to enter a conference number phrase:conference_num\n")
  conference_num = session:playAndGetDigits(min, max, attempts, timeout, '#', '/usr/local/freeswitch/sounds/ipt/conference/conf-enter_conf_number.wav', '', '\\d+')
  return tonumber(conference_num)
end

-- get conference passcode from input
local function get_conference_passcode(min, max, attempts, timeout, pin_number)
  local pin_attempt = 1
  local pin_max_attempt = 3

  while pin_attempt <= pin_max_attempt do
    conference_passcode = session:playAndGetDigits(min, max, attempts, timeout, '#', '/usr/local/freeswitch/sounds/ipt/conference/conf-enter_conf_pin.wav', '', '\\d+')

    if tonumber(conference_passcode) == tonumber(pin_number) then
      return true
    else
      session:streamFile("/usr/local/freeswitch/sounds/ipt/conference/conf-bad-pin.wav")
      --ession:execute("phrase", "conference_bad_passcode")
    end

    pin_attempt = pin_attempt + 1
  end

  return false
end




function main()

        print("IVR main start.")
        print("session uuid:"..session:get_uuid())
        print("session context:"..session:getVariable("context"))
        print("session destination_number:"..session:getVariable("destination_number"))
        print("session caller_id_name:"..session:getVariable("caller_id_name"))
        print("session caller_id_number:"..session:getVariable("caller_id_number"))

        api = freeswitch.API()
        attempt = 1
        max_attempts = 3

        local accessNumber = tonumber(session:getVariable("destination_number"))
        local attendeeID = tonumber(session:getVariable("caller_id_number"))
        local dest_addr = session:getVariable("destination_addr")

        -- IVR应答

        session:answer()

        if session:ready() then
            freeswitch.consoleLog("info", "Caller has called, playing welcome message\n")
            session:streamFile("/usr/local/freeswitch/sounds/ipt/conference/conf-welcome.wav")
            --session:execute("phrase", "/usr/local/freeswitch/sounds/music/love.wav")
        end

        --
        while attempt <= max_attempts do
            local confID = get_conference_num(1, 10, 3, 4000)
            if nil ~= confID then
                row = dao.getConfMsgByID(confID)

                if nil == row then
                    freeswitch.consoleLog("error", string.format("Conference %d is not availalbe\n", tonumber(confID)))
                    --session:execute("phrase", "conference_bad_num")
                else
                    freeswitch.consoleLog("info", string.format("Conference %d has a PIN %d, Authenticating user\n", tonumber(confID), tonumber(row["attendpwd"])))
                    local pwd = ""
                    if attendeeID == row["chairman"] then
                        pwd = row["attendpwd"]
                    else
                        pwd = row["chairmanpwd"]
                    end
                    -- 收号鉴权
                    if ((get_conference_passcode(1, 6, 3, 4000, pwd)) == true) then
                        freeswitch.consoleLog("info", string.format("Conference %d correct PIN entered, Sending caller into conference\n", tonumber(accessNumber)))

                        -- 鉴权成功，从hash获取当前会场信息；
                        local room = Room:get(confID)

                        --若不存在则说明第一个入会，新建会场，从mysql获取会场信息
                        if nil == room then
                            room = Room:new(confID)
                            room:setManagerID(row["chairman"])
                            room:setGroupURI("")
                            room:setConfType(3)
                            room:setServerIP(dest_addr)
                            room:setAuthCode(row["authkey"])
                            Room:add(confID, room)
                        end

                        -- send re-invite to client
                        session:setVariable("sip_reinvite_contact_params", "~isfocus;conftype=00000100;confid="..confID)
                        freeswitch.API():executeString("uuid_media_reneg "..session:get_uuid())

                        -- 将创建者加入与会者列表
                        --room:addMember(attendeeID, 1)          --- 1表示主持人


                        --[[ join the conference, if the correct pin was entered ]]--
                        print("start conference"..confID)
                        session:execute("conference", confID)
                        break;
                    else
                        freeswitch.consoleLog("NOTICE", string.format("Conference %d invalid PIN entered, Looping again\n", tonumber(accessNumber)))
                    end
                end
            end
            
            attempt = attempt + 1
        end


        --session:execute("phrase", "conference_too_many_failures")
        freeswitch.consoleLog("error", string.format("Conference too many failures\n"))
        session:hangup()
         -- 设置DTMF，放音
        --session:setInputCallback('onInputCBF', '')
        --session:streamFile("/usr/local/freeswitch/sounds/music/love.wav")


end

main()
