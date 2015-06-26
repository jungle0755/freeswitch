local ConferenceDao = {}

-- 从数据库中获取预约会议相关信息
function ConferenceDao.getConfMsgByID(confID)
	local msg = nil

	local dbh = mysql_connect()
	mysql_select_conf(dbh, confID, "confid,chairman,attendee,chairmanpwd,attendpwd,authkey", function(row) msg=row end	)

	mysql_release(dbh)
	return msg
end

-- 使用FS的mysql接口，封装“会议表”的操作接口

------------------------------连接与释放-------------------------------------
function mysql_connect()
	local dbh = freeswitch.Dbh("odbc://freeswitch")
	if dbh:connected() then
		freeswitch.consoleLog("info", "connect odbc://freeswitch success !\n")
		return dbh
	else
		freeswitch.consoleLog("err", "connect odbc://freeswitch failed !\n")
		return nil
	end
end

function mysql_release(dbh)
	dbh:release()
end

-----------------------------对“会议表”的操作，测试、创建、增、删、查-------------------------------
-- 测试会议表是否存在
function mysql_test_conf_tbl(dbh)
	return dbh:query("SELECT * FROM tbl_conf")
end

-- 创建会议表
function mysql_create_conf_tbl(dbh)
	local create_cmd = string.format("CREATE TABLE tbl_conf (confid INTEGER(8) NOT NULL UNIQUE, subscriber INTEGER(8), chairman INTEGER(8) NOT NULL, attendee VARCHAR(256) NOT NULL, starttime VARCHAR(14) NOT NULL, endtime VARCHAR(14) NOT NULL, chairmanpwd INTEGER(8), attendpwd INTEGER(8), authkey VARCHAR(64) NOT NULL)")

	return dbh:query(create_cmd)
end

-- 删除会议表
function mysql_drop_conf_tbl(dbh)
	return dbh:query("DROP TABLE tbl_conf")
end

-- 添加会议即预约
-- 注意参数“value”字符串中，若有VARCHAR字段，需要添加引号
function mysql_insert_conf(dbh, value)
	return dbh:query(string.format("INSERT INTO tbl_conf VALUES(%s)", value))
end

-- 删除某会议，即会议已结束退出
function mysql_delete_conf(dbh, confid)
	return dbh:query(string.format("DELETE FROM tbl_conf WHERE confid=%d", confid))
end

-- 根据confid，查询会议的信息（wanted描述需要的字段，用逗号隔开）
function mysql_select_conf(dbh, confid, wanted, handle)
	return dbh:query(string.format("SELECT %s FROM tbl_conf WHERE confid=%d", wanted, confid), handle)
end

return ConferenceDao
