--Info object

Info={}
function Info:new()
	newObj = {user="",host="",body={}}
	self.__index = self
	return setmetatable(newObj, self)
end

function Info:receive(event)
	self.user = event:getHeader("SIP-From-User");
	self.client = event:getHeader("SIP-Contact-Host");
	self.host = event:getHeader("SIP-To-Host");
	self.local_host = event:getHeader("FreeSWITCH-IPv4")

	local s = event:getBody()
	for k, v in string.gmatch(s, "([^%s]+)=([^%s]+)") do
		self.body[k]=v
	end

	for k, v in pairs(self.body) do
		print(k.."="..v)
	end
end

function Info:send(body)
	freeswitch.consoleLog("DEBUG", "send info to " .. self.user.."@"..self.client)

	local event = freeswitch.Event("SEND_INFO");

	if "ms" ~= self.user then
		event:addHeader("local-user", self.user .. "@" .. self.local_host);
		event:addHeader("to-uri", "sip:"..self.user .. "@" .. self.client);
	else
		event:addHeader("to-uri", "sip:"..self.user .. "@" .. self.client..":5092");
	end
	
	event:addHeader("from-uri", "sip:imeeting" .. "@" .. self.host);
	event:addHeader("User-Agent", "Huawei eSpace USM V200R003");
	event:addHeader("Content-Type", "application/Huawei-TAS");
	event:addHeader("Profile", "internal");
	event:addBody(body);
	
	freeswitch.consoleLog("DEBUG", "zsl>>>>>>>>>> SEND_INFO event\n" .. event:serialize());
	
	event:fire();
end

function Info:toString (body)
	local result = ''
	if(nil == body) then
		return result
	end

	for key, value in pairs(body) do
		if("attendeelist" == key) then
			result = result..value
		else
			result = result..key.."="..value.."\r\n"
		end
	end

	return result
end

