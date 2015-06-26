-- �ֶ����иýű�������ԤԼһ�λ���

require("conf_dao")
local util = require('common_util')

local host = freeswitch.getGlobalVariable("local_ip_v4")

-- �������ݿ�
local dbh = mysql_connect()
if dbh then
	print("connect odbc://freeswitch success !\n")
else
	print("connect odbc://freeswitch failed !\n")
	return
end

-- ���Ա��Ƿ���ڣ������½�
local ret = mysql_test_conf_tbl(dbh)
if not ret then
	print("tbl_conf is not exist !\n")
	
	-- ���������
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

-- ��ȡԤԼ�ߡ���ϯ������ߡ���������
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

-- ��ȡ����ʱ��
print("Please enter the conference start time, like 20150255103000:")
local startm = io.read()

print("Please enter the conference end time, like 20150255113000:")
local endtm = io.read()

-- ���ɻ���ID����Ȩ��
local confID = util.generateConfID(host)
local authCode = util.generateAuthCode()
print("please remember the confid: " .. confID .. "\n")

-- ����һ����¼����ԤԼ����
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
