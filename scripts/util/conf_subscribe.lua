-- 手动运行该脚本，算是预约一次会议

require("conf_dao")
local util = require('common_util')

local host = freeswitch.getGlobalVariable("local_ip_v4")

-- 连接数据库
local dbh = mysql_connect()
if dbh then
	print("connect odbc://freeswitch success !\n")
else
	print("connect odbc://freeswitch failed !\n")
	return
end

-- 测试表是否存在，否则新建
local ret = mysql_test_conf_tbl(dbh)
if not ret then
	print("tbl_conf is not exist !\n")
	
	-- 创建会议表
	ret = mysql_create_conf_tbl(dbh)
	if not ret then
		print("create conf_tbl failed !\n")
		mysql_release(dbh)
		return
	else	
		print("create conf_tbl success !\n")
	end
else
	print("tbl_conf is exist !\n")
end

-- 获取预约者、主席、与会者、入会的密码
print("please enter the subscriber number: ")
local subscriber = tonumber(io.read())

print("please enter the chairman number: ")
local chairman = tonumber(io.read())

print("Please enter all attendee Numbers, separated by #:")
local attendees = io.read()

print("please enter the chairman password: ")
local chairmanpwd = tonumber(io.read())

print("please enter the attendee password: ")
local attendpwd = tonumber(io.read())

-- 获取会议时间
print("Please enter the conference start time, like 20150255103000:")
local startm = io.read()

print("Please enter the conference end time, like 20150255113000:")
local endtm = io.read()

-- 生成会议ID、鉴权码
local confID = util.generateConfID(host)
local authCode = util.generateAuthCode()
print("please remember the confid: " .. confID .. "\n")

-- 插入一条记录，即预约会议
local value = string.format("%d, %d, %d, \"%s\", \"%s\", \"%s\", %d, %d , \"%s\"", confID, subscriber, chairman, attendees, startm, endtm, chairmanpwd, attendpwd, authCode)

ret = mysql_insert_conf(dbh, value)
if ret then
	print("subscrib a conference success !\n")
else
	print("subscrib a conference failed !\n")
	mysql_release(dbh)
	return
end

mysql_release(dbh)
