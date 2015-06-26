


local json = require('dkjson')
local api = freeswitch.API();
--Room:
--  call-id   -- 创建请求ID-创建的会场ID
--	authkey  -- 加入数据会议的鉴权码
	--attendee-eid    -- 会议主席号码
    --create-type   -- 0：基线1：数据 2：数据升级语音
    --serverIP
	--memberList
	--attendeeCode
	--group-uri
	--create-time
	--subscribeList


--与会成员类
Attendee = {}

function Attendee:new(userID)
	newObj = {number = userID, ["full-number"] = userID, role = 2, state = 5, audioright = 0, attendtime = os.date("%Y-%m-%d_%H:%M:%S")}  -- createTime = api:getTime()
	self.__index = self
	return setmetatable(newObj, self)
end

function Attendee:new(userID, ro)
	newObj = {number = userID, ["full-number"] = userID, role = ro, state = 5, audioright = 0, attendtime = os.date("%Y-%m-%d_%H:%M:%S")}  -- createTime = api:getTime()
	self.__index = self
	return setmetatable(newObj, self)
end

function Attendee:setRole(role) self.role = role end
function Attendee:getRole() return self.role  end

function Attendee:toString()
	return "number="..self.number.." full-number="..self["full-number"].." role="..self.role.." state="..self.state.." audioright="..self.audioright.." attendtime="..self.attendtime.."\r\n"
end
function Attendee:toString(attendee)
	if nil == attendee then
		return ""
	else
		return "number="..attendee.number.." full-number="..attendee["full-number"].." role="..attendee.role.." state="..attendee.state.." audioright="..attendee.audioright.." attendtime="..attendee.attendtime.."\r\n"
	end
end
--订阅者类
Subscriber = {}
function Subscriber:new(serviceType, softphone, ip)
	newObj = body
	self.__index = self
	return setmetatable(newObj, self)
end
function Subscriber:new(body)
	newObj = body
	self.__index = self
	return setmetatable(newObj, self)
end
function Attendee:new(userID)
	newObj = {number = userID, ["full-number"] = userID, role = 2, state = 5, audioright = 0, attendtime = os.date("%Y-%m-%d_%H:%M:%S")}  -- createTime = api:getTime()
	self.__index = self
	return setmetatable(newObj, self)
end
function Attendee:new(userID, ro)
	newObj = {number = userID, ["full-number"] = userID, role = ro, state = 5, audioright = 0, attendtime = os.date("%Y-%m-%d_%H:%M:%S")}  -- createTime = api:getTime()
	self.__index = self
	return setmetatable(newObj, self)
end
--会场信息类
Room = {}

-- 以 (confID, Room) 的形式保存所有会场信息
-- 以 json格式保存到Mod_hash中，roomMap不使用
roomMap = {}

--Room的构造函数
function Room:new(id)
	newObj = {confID = id, createTime = os.date("%Y-%m-%d_%H:%M:%S"), managerID = '', memberCount = 0,  serverIP="", memberList = {}, subcriberList = {}}  -- createTime = api:getTime()
	self.__index = self
	return setmetatable(newObj, self)
end

function Room:convert(obj)
	newObj = obj
	self.__index = self
	return setmetatable(newObj, self)
end

--会议号码
function Room:getConfID()
	return self.confID
end

--获取会议创建时间
function Room:getCreateTime()
	return self.createTime
end

--鉴权码
function Room:setAuthCode(code)
	self.authCode = code
end
function Room:getAuthCode()
	return self.authCode
end

--主席号码
function Room:setManagerID(id)
	self.managerID = id
end
function Room:getManagerID()
	return self.managerID
end

--主席密码
function Room:setManagerCode(code)
	self.managerCode = code
end
function Room:getManagerCode()
	return self.managerCode
end

--会议类型
function Room:setConfType(t)
	self.confType = t
end
function Room:getConfType()
	return self.confType
end

--主机地址
function Room:setServerIP(ip)
	self.serverIP = ip
end
function Room:getServerIP()
	return self.serverIP
end

--群组URI
function Room:setGroupURI(uri)
	self.groupURI = uri
end
function Room:getGroupURI()
	return self.groupURI
end

--成员数
function Room:getMemberCount()
	return self.memberCount
end

--成员列表
function Room:getMemberList()
	return self.memberList
end
function Room:getMember(userID)
	return self.memberList[userID]
end

function Room:getMemberIDByNumber(userID)
    if nil ~= self.memberList[userID] then
        return self.memberList[userID].memberID
    else
        return nil
    end
end

function Room:addMember(userID)
    self.memberList[userID] = Attendee:new(userID)
	self.memberCount = self.memberCount + 1

	self:update()
end

function Room:addMember(userID, role)
    self.memberList[userID] = Attendee:new(userID, role)
	self.memberCount = self.memberCount + 1
    
	self:update()
end

function Room:addMember(userID, role, memberID)
    local attendee = Attendee:new(userID, role)
    attendee.memberID = memberID
    
    self.memberList[userID] = attendee
	self.memberCount = self.memberCount + 1
	self:update()
end

function Room:delMember(userID)
	if(self.memberList[userID]) then
		self.memberList[userID].state = 6
		self.memberCount = self.memberCount - 1

		self:update()
	else
		print("del member is nil")
	end
end

--订阅列表
function Room:getSubcriberList()
	return self.subcriberList
end

function Room:getSubcriber(ip)
	return self.subcriberList[ip]
end
function Room:addSubcriber(ip, body)
    	self.subcriberList[ip] = Subscriber:new(body)
	self:update()
end
function Room:delSubcriber(ip)
    self.subcriberList[ip] = nil
	self:update()
end

-- 对会议成员静音
function Room:muteMember(userID, audioRight)
    if(self.memberList[userID]) then
         self.memberList[userID].audioright = audioRight
         self:update()
     else
        print("The member[userID="..userID.. "] doesnot exist.")
     end
end
 
-- 会议全场静音
function Room:muteConf(audiorRight)
    for id,memberInfo in pairs(self.memberList) do
      if(nil == memberInfo) then
          print("The member is nil when mute conf")
      else
          memberInfo.audioright = audiorRight 
      end                                                                                                                                                                           
    end
    self:update()
end

--显示会议信息
function Room:toString()
	local members = '['
	for confId, userId in pairs(self.memberList) do
		members = members .. confId .. '=' .. userId .. ', '
	end
	members = members .. ']'

	local subcribers = '['
	for k, v in pairs(self.subcriberList) do
		subcribers = subcribers .. k .. '=' .. v .. ', '
	end
	subcribers = subcribers .. ']'

	return 'confID=' .. self.confID .. ', createTime=' .. self.createTime .. ', managerID=' .. self.managerID .. ', memberList='.. members .. ', subcriberList=' .. subcribers
end

function Room:add(id, room)
	if id and room then
		local roomOfJSON = json.encode(room)
		--print("insert room to mod_hash:"..roomOfJSON)
		api:executeString("hash insert_ifempty/conference_room/"..id.."/"..roomOfJSON)
	end

    --roomMap[id] = room
end

function Room:del(id)
	if id then
		print("delete room from mod_hash:"..id)
		api:executeString("hash delete/conference_room/"..id)
	end
    --roomMap[id] = nil
end

function Room:get(id)

	if id then
		local roomOfJSON = api:executeString("hash select/conference_room/"..id)

		if "" ~= roomOfJSON then
			--print("get room from mod_hash:"..id.." = "..roomOfJSON)
			return Room:convert(json.decode(roomOfJSON))
		else
			print("get room from mod_hash failed:room is empty")
			return nil
		end
	else
		print("get room from mod_hash failed:id is nil")
		return nil
	end
end


--会议室有成员、状态变化时更新hash模块的缓存
function Room:update()
	local roomOfJSON = json.encode(self)
	--print("update room to mod_hash:"..roomOfJSON)
    api:executeString("hash insert/conference_room/"..self.confID.."/"..roomOfJSON)
end

return Room





