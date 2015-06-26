require('conf_room')
require('conf_control')
require('info_process')

require('control_conf_create')
require('control_conf_close')
require('control_report_client')
require('control_conf_auth')
require('control_member_add')
require('control_member_del')
require('control_mute_conf')

--main()
function main()
    print("main start")
    con = freeswitch.EventConsumer("RECV_INFO");
    api = freeswitch.API();
	api:execute("hash", "insert_ifempty/conference_room/conf_queue/1000000")

    for e in (function() return con:pop(1) end) do
      freeswitch.consoleLog("info", "sxf>>>>>>>>>> info event\n" .. e:serialize("xml"));
      local info = Info:new();
      info:receive(e);
      Control:execute(info);

      -- exit main
      if(nil == info.body["cmd-type"]) then
		print("exit info recv event listener")
		break
	  end
    end
end

main()






