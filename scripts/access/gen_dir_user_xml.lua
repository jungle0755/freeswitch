-- gen_dir_user_xml.lua
-- example script for generating user directory XML

freeswitch.consoleLog("DEBUG", "lua take the users authentication...\n");
freeswitch.consoleLog("DEBUG", "Debug from gen_dir_user_xml.lua, provided params:\n" .. params:serialize() .. "\n")

local req_domain = params:getHeader("domain")
local req_key    = params:getHeader("key")
local req_user   = params:getHeader("user")
local req_password  = nil

if not req_user then
	freeswitch.consoleLog("err", " lack of the number to register\n")
	return
end

local dbh = freeswitch.Dbh("odbc://freeswitch");
assert(dbh:connected());

dbh:query("select password from userinfo where username=" .. req_user, 
    function(row)
		if not row then
			freeswitch.consoleLog("NOTICE", string.format("user phone= %d, not exist\n", req_user))
		else
			req_password = row.password
			freeswitch.consoleLog("DEBUG", string.format("user phone= %d, password= %s\n", req_user, req_password))
		end
    end);
dbh:release();

if req_password then
	freeswitch.consoleLog("debug", string.format("user: %s:%s@%s through the verification\n", req_user, req_password, req_domain))
else
	freeswitch.consoleLog("ERR", string.format("user: %s@%s has null password, it is invalid\n", req_user, req_domain))
	return
end


--This example script only supports generating directory xml for a single user !

local outbound_caller_name = freeswitch.getGlobalVariable("outbound_caller_name")
local outbound_caller_id = freeswitch.getGlobalVariable("outbound_caller_id")

if req_domain ~= nil and req_key~=nil and req_user~=nil then
    XML_STRING =
    [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <document type="freeswitch/xml">
      <section name="directory">
        <domain name="]]..req_domain..[[">
          <params>
            <param name="dial-string"  value="{^^:sip_invite_domain=${dialed_domain}:presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(*/${dialed_user}@${dialed_domain})}"/>
          </params>
		  
          <groups>
            <group name="default">
              <users>
                <user id="]] ..req_user..[[">
				  <params>
                    <param name="password" value="]]..req_password..[["/>
                    <param name="vm-password" value="]]..req_password..[["/>
                  </params>
                
				  <variables>
                    <variable name="toll_allow" value="domestic,international,local"/>
                    <variable name="accountcode" value="]] ..req_user..[["/>
				    <variable name="user_context" value="default"/>
				    <variable name="directory-visible" value="true"/>
				    <variable name="directory-exten-visible" value="true"/>
				    <variable name="limit_max" value="15"/>
				    <variable name="effective_caller_id_name" value="Extension ]] ..req_user..[["/>
				    <variable name="effective_caller_id_number" value="]] ..req_user..[["/>
				    <variable name="outbound_caller_id_name" value="]] ..outbound_caller_name.. [["/>
				    <variable name="outbound_caller_id_number" value="]] ..outbound_caller_id.. [["/>
				    <variable name="callgroup" value="techsupport"/>
                  </variables>
                </user>
              </users>
            </group>
          </groups>
        </domain>
      </section>
    </document>]]
else
    XML_STRING =
    [[<?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <document type="freeswitch/xml">
      <section name="directory">
      </section>
    </document>]]
end

freeswitch.consoleLog("DEBUG", "Debug from gen_dir_user_xml.lua, generated User directory XML:\n" .. XML_STRING .. "\n");
