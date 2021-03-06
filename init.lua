
local config = {}
local cjson_safe = require "cjson.safe"

--- config.json 文件绝对路径 [需要自行根据自己服务器情况设置]
local config_json = "/opt/openresty/openstar/config.json"

--- 将全局配置参数存放到共享内存（config_dict）中
local config_dict = ngx.shared.config_dict

--- 读取文件（全部读取）
--- loadjson()调用
local function readfile(filepath)
	local fd = io.open(filepath,"r")
	if fd == nil then return end -- 文件读取错误返回
    local str = fd:read("*a") --- 全部内容读取
    fd:close()
    return str
end

--- 写文件(filepath,msg,ty)  默认追加方式写入
--- init_debug()
local function writefile(filepath,msg,ty)
	if ty == nil then ty = "a+" end
	-- w+ 覆盖
    local fd = io.open(filepath,ty) --- 默认追加方式写入
    if fd == nil then return end -- 文件读取错误返回
    fd:write("\n"..tostring(msg))
    fd:flush()
    fd:close()
end

--- init_debug()调用
local function tableToString(obj)
        local lua = ""  
        local t = type(obj)  
        if t == "number" then  
            lua = lua .. obj  
        elseif t == "boolean" then  
            lua = lua .. tostring(obj)  
        elseif t == "string" then  
            lua = lua .. string.format("%q", obj)  
        elseif t == "table" then  
            lua = lua .. "{\n"  
	        for k, v in pairs(obj) do  
	            lua = lua .. "[" .. _tableToString(k) .. "]=" .. _tableToString(v) .. ",\n"  
	        end  
        	local metatable = getmetatable(obj)  
	        if metatable ~= nil and type(metatable.__index) == "table" then  
	            for k, v in pairs(metatable.__index) do  
	                lua = lua .. "[" .. _tableToString(k) .. "]=" .. _tableToString(v) .. ",\n"  
	            end  
        	end  
            lua = lua .. "}"  
        elseif t == "nil" then  
            return nil  
        else  
            error("can not tableToString a " .. t .. " type.")  
        end  
        return lua  
end

-- init_debug(msg) 阶段调试记录LOG
-- 暂无调用
local function init_debug(msg)
	if Config.base.debug_Mod == false then return end  --- 判断debug开启状态
	local filepath = Config.base.logPath.."debug.log"
	local time = ngx.localtime()
	if type(msg) == "table" then
		local str_msg = tableToString(msg)
		writefile(filepath,time.."- init_debug: "..tostring(str_msg))
	else
		writefile(filepath,time.."- init_debug: "..tostring(msg))
	end
end

--- 载入JSON文件
--- loadConfig()调用
local function loadjson(_path_name)
	local x = readfile(_path_name)
	local json = cjson_safe.decode(x) or {}
	return json
end



--- 载入config.json全局基础配置
function loadConfig()

	config.base = loadjson(config_json)
	local _basedir = config.base.jsonPath or "./"
	
	config.realIpFrom_Mod = loadjson(_basedir.."realIpFrom_Mod.json")
	--config.ip_Mod = loadjson(_basedir.."ip_Mod.json")
	config.host_method_Mod = loadjson(_basedir.."host_method_Mod.json")
	config.rewrite_Mod = loadjson(_basedir.."rewrite_Mod.json")
	config.app_Mod = loadjson(_basedir.."app_Mod.json")
	config.referer_Mod = loadjson(_basedir.."referer_Mod.json")
	config.url_Mod = loadjson(_basedir.."url_Mod.json")
	config.header_Mod = loadjson(_basedir.."header_Mod.json")
	config.useragent_Mod = loadjson(_basedir.."useragent_Mod.json")	
	config.cookie_Mod = loadjson(_basedir.."cookie_Mod.json")
	config.args_Mod = loadjson(_basedir.."args_Mod.json")
	config.post_Mod = loadjson(_basedir.."post_Mod.json")
	config.network_Mod = loadjson(_basedir.."network_Mod.json")
	config.replace_Mod = loadjson(_basedir.."replace_Mod.json")
	
	for k,v in pairs(config) do
		v = cjson_safe.encode(v)
		config_dict:safe_set(k,v,0)
	end

	--- 将ip_mod放入 ip_dict 中
	if config.base["ip_Mod"] == "on" then
		local tb_ip_mod = loadjson(_basedir.."ip_Mod.json")
		local _dict = ngx.shared["ip_dict"]
		for i,v in ipairs(tb_ip_mod) do
			if v.action == "allow" then
				_dict:safe_set(v.ip,"allow",0)
				--- key 存在会覆盖 lru算法关闭
			elseif v.action == "deny" then
				_dict:safe_set(v.ip,"deny",0)
			else
				_dict:safe_set(v.ip,"log",0)
			end
		end
	end

end

loadConfig()