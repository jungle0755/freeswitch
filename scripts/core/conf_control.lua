
--Conference object
Conference={}


--Control object
Control = {map={}}
function Control:register(key, value)

	if key and value then
		self.map[key] = value;
		freeswitch.consoleLog("info", "Init: register info event "..key.." to control.\n");
	else
		freeswitch.consoleLog("error", "Init: register info event failed.\n");
	end
end

function Control:execute(info)
	local key = tonumber(info.body["cmd-type"])
    print(self.map[key])
	if nil ~= key and nil ~= self.map[key] then
		self.map[key]:execute(info)
	else
		freeswitch.consoleLog("info", "none conference info event\n")
		print("none conference info event\n")
	end
end

--feature object  refer  the command design  mode
--http://blog.csdn.net/yitouhan/article/details/16833177
--实现主要的会议处理逻辑
--base class include attribute body  and function execute
Base = {}
function Base:new()
	newObj = {}
	self.__index = self
	return setmetatable(newObj, self)
end

function Base:new(r,o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    o.conference = r;
    return o
end

function Base:registerToControl(cmdType )
	print(cmdType)
    Control:register(cmdType, self);
end

function Base:unRegisterToControl(cmdType)

end






