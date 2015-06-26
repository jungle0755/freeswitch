require('conf_room')
require('common_def')

-- 终端一键入会，将INVITE路由到本脚本

-- 获取相关环境变量和通道变量
local access_code = session:getVariable("access_code")	-- 用户额外设置
freeswitch.consoleLog("info", "access_code: " .. access_code .. "\n")

local caller_no = session:getVariable("caller_id_number")
local caller_addr = session:getVariable("network_addr")
freeswitch.consoleLog("info", "caller: " .. caller_no .. "@" .. caller_addr .. "\n")

local dest_no = session:getVariable("destination_number")
local dest_addr = session:getVariable("destination_addr") -- 用户额外设置
freeswitch.consoleLog("info", "dest: " .. dest_no .. "@" .. dest_addr .. "\n")

-- 从dest_no中获取会议ID、密码
local dial_confid = nil
local dial_pwd = nil

_, _, dial_confid, dial_pwd = string.find(dest_no, access_code .. "(%d+)*(%d+)#")
freeswitch.consoleLog("info", string.format("dial_confid: %s, dial_pwd: %s\n", dial_confid, dial_pwd))

local result = AUTH_RESULT.SUCCESS		-- 鉴权的结果
local identity  	-- 身份

-- 连接数据库
local dbh = freeswitch.Dbh("odbc://freeswitch")	-- 此处的用户名和密码会自动从odbc.ini中获取
if dbh:connected() then
	freeswitch.consoleLog("info", "connect odbc://freeswitch success !\n")
else
	freeswitch.consoleLog("err", "connect odbc://freeswitch failed !\n")
	result = AUTH_RESULT.DB_BAD	-- FS连接数据库失败，即服务器错误
end

-- 鉴权函数
local authkey = nul
local chairman
local function authenticate(row)
	if row then
		freeswitch.consoleLog("info", string.format("find the conference whose confid : %d, chairmanpwd : %s, attendpwd : %s\n", dial_confid, row.chairmanpwd, row.attendpwd))
	else
		freeswitch.consoleLog("err", string.format("there is no conference whose confid : %d\n", dial_confid))
		result = AUTH_RESULT.CONF_NONE -- 数据库中没有该会议
		return
	end

	if (dial_pwd == row.chairmanpwd) then
		identity = MEMB_ATTR.ROLE.CHAIRMAN
		freeswitch.consoleLog("info", string.format("authentication pass, identity is chairman !\n"))
	elseif (dial_pwd == row.attendpwd) then
		identity = MEMB_ATTR.ROLE.COMMON
		freeswitch.consoleLog("info", string.format("authentication pass, identity is attendee !\n"))
	else
		result = AUTH_RESULT.CODE_ERR -- 密码错误，鉴权不通过
		freeswitch.consoleLog("err", string.format("authentication is not through !\n"))
		return
	end

	chairman = row.chairman
	authkey = row.authkey
end

-- 从数据库中获取对应的会议ID、密码并调用鉴权函数
if result == AUTH_RESULT.SUCCESS then
	dbh:query("SELECT chairman, chairmanpwd, attendpwd, authkey FROM tbl_conf WHERE confid = " .. dial_confid, authenticate)
end
dbh:release()

-- 成功则构造200OK并应答，失败则。。。
if result == AUTH_RESULT.SUCCESS then
	-- 设置环境变量并发送200OK
	session:setVariable("g_invite_contact_params", "isfocus;conftype=00000111;confid=" .. dial_confid);
	session:answer()

	-- 鉴权成功，从hash获取当前会场信息；
	local room = Room:get(dial_confid)

	--若不存在则说明第一个入会，新建会场，从mysql获取会场信息
	if nil == room then
		room = Room:new(dial_confid)
		room:setManagerID(chairman)
		room:setGroupURI("")
		room:setConfType(CONF_ATTR.TYPE.DATA)
		room:setServerIP(dest_addr)
		room:setAuthCode(authkey)
		Room:add(dial_confid, room)
	end

	room:addMember(caller_no, identity)

	if session:ready() then
		-- 拉入会议
		freeswitch.consoleLog("info", string.format("put into conference %s ...\n", dial_confid))
		session:execute("conference", string.format("%s@default", dial_confid))
	else

	end
else

end

session:hangup()
