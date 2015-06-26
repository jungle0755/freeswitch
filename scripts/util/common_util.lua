local Util = {}

--6位序列号，递增，第7位前缀
g_confQueue = 1000000

-- get 1006 from 1006#
function Util.fetchAttendeeFromRequest(input)
    if nil == input then 
        return ""
    end
	if string.find(input, "#", 1, true) then
		for i in string.gmatch(input, "(%d+)#") do
			return i
		end
	else
		return input
	end
end

function Util.fetchConfIDFromCallID(callid)
	if string.find(callid, "-", 1, true) then
		for i in string.gmatch(callid, "%d+%-(%d+)") do
			return tonumber(i)
		end
	else
		return tonumber(callid)
	end
end

function split(str, split_char)
	local sub_str_tab = {};

	while (true) do
		local pos = string.find(str, split_char);
		if (not pos) then
			local size_t = #sub_str_tab
			table.insert(sub_str_tab,size_t+1,str);
			break;
		end

		local sub_str = string.sub(str, 1, pos - 1);
		local size_t = #sub_str_tab
		table.insert(sub_str_tab,size_t+1,sub_str);
		local t = string.len(str);
		str = string.sub(str, pos + 1, t);
	end
	return sub_str_tab;
end

local function getConfQueueFromHash()
	local result = freeswitch.API():executeString("hash select/conference_room/conf_queue")
	return tonumber(result)
end

local function updateConfQueueToHash(confQueue)
	freeswitch.API():executeString("hash insert/conference_room/conf_queue/"..confQueue)
end

--根据Host（IP）生成

function  Util.generateConfID(host)

	-- 会议ID最后3位由IP后3位生成
	local suffix = 0

	if host then
		ipOptions = split(host, "%.")
		--print(ipOptions[4])
		if(4 == #ipOptions) then
			suffix = tonumber(ipOptions[4])
		end
	end


	--前7位由递增序列生成
    local confQueue = getConfQueueFromHash()
	local result = confQueue * 1000 + suffix

	confQueue = confQueue + 1
	if(confQueue%1000000 == 0) then
		confQueue = confQueue - 1000000
	end
	updateConfQueueToHash(confQueue)
	print(confQueue)
	return result
end


function Util.generateAuthCode()
	--return "530f279c951f589e23db96f53477c4c"    --freeswitch.API():create_uuid()
	return freeswitch.API():executeString("create_uuid")
end


return Util


