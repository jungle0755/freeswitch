require('conf_room')
require('common_def')

-- �ն�һ����ᣬ��INVITE·�ɵ����ű�

-- ��ȡ��ػ���������ͨ������
local access_code = session:getVariable("access_code")	-- �û���������
freeswitch.consoleLog("info", "access_code: " .. access_code .. "\n")

local caller_no = session:getVariable("caller_id_number")
local caller_addr = session:getVariable("network_addr")
freeswitch.consoleLog("info", "caller: " .. caller_no .. "@" .. caller_addr .. "\n")

local dest_no = session:getVariable("destination_number")
local dest_addr = session:getVariable("destination_addr") -- �û���������
freeswitch.consoleLog("info", "dest: " .. dest_no .. "@" .. dest_addr .. "\n")

-- ��dest_no�л�ȡ����ID������
local dial_confid = nil
local dial_pwd = nil

_, _, dial_confid, dial_pwd = string.find(dest_no, access_code .. "(%d+)*(%d+)#")
freeswitch.consoleLog("info", string.format("dial_confid: %s, dial_pwd: %s\n", dial_confid, dial_pwd))

local result = AUTH_RESULT.SUCCESS		-- ��Ȩ�Ľ��
local identity  	-- ���

-- �������ݿ�
local dbh = freeswitch.Dbh("odbc://freeswitch")	-- �˴����û�����������Զ���odbc.ini�л�ȡ
if dbh:connected() then
	freeswitch.consoleLog("info", "connect odbc://freeswitch success !\n")
else
	freeswitch.consoleLog("err", "connect odbc://freeswitch failed !\n")
	result = AUTH_RESULT.DB_BAD	-- FS�������ݿ�ʧ�ܣ�������������
end

-- ��Ȩ����
local authkey = nul
local chairman
local function authenticate(row)
	if row then
		freeswitch.consoleLog("info", string.format("find the conference whose confid : %d, chairmanpwd : %s, attendpwd : %s\n", dial_confid, row.chairmanpwd, row.attendpwd))
	else
		freeswitch.consoleLog("err", string.format("there is no conference whose confid : %d\n", dial_confid))
		result = AUTH_RESULT.CONF_NONE -- ���ݿ���û�иû���
		return
	end

	if (dial_pwd == row.chairmanpwd) then
		identity = MEMB_ATTR.ROLE.CHAIRMAN
		freeswitch.consoleLog("info", string.format("authentication pass, identity is chairman !\n"))
	elseif (dial_pwd == row.attendpwd) then
		identity = MEMB_ATTR.ROLE.COMMON
		freeswitch.consoleLog("info", string.format("authentication pass, identity is attendee !\n"))
	else
		result = AUTH_RESULT.CODE_ERR -- ������󣬼�Ȩ��ͨ��
		freeswitch.consoleLog("err", string.format("authentication is not through !\n"))
		return
	end

	chairman = row.chairman
	authkey = row.authkey
end

-- �����ݿ��л�ȡ��Ӧ�Ļ���ID�����벢���ü�Ȩ����
if result == AUTH_RESULT.SUCCESS then
	dbh:query("SELECT chairman, chairmanpwd, attendpwd, authkey FROM tbl_conf WHERE confid = " .. dial_confid, authenticate)
end
dbh:release()

-- �ɹ�����200OK��Ӧ��ʧ���򡣡���
if result == AUTH_RESULT.SUCCESS then
	-- ���û�������������200OK
	session:setVariable("g_invite_contact_params", "isfocus;conftype=00000111;confid=" .. dial_confid);
	session:answer()

	-- ��Ȩ�ɹ�����hash��ȡ��ǰ�᳡��Ϣ��
	local room = Room:get(dial_confid)

	--����������˵����һ����ᣬ�½��᳡����mysql��ȡ�᳡��Ϣ
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
		-- �������
		freeswitch.consoleLog("info", string.format("put into conference %s ...\n", dial_confid))
		session:execute("conference", string.format("%s@default", dial_confid))
	else

	end
else

end

session:hangup()
