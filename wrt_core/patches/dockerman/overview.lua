--[[
LuCI - Lua Configuration Interface
Copyright 2019 lisaac <https://github.com/lisaac/luci-app-dockerman>
]]--

local docker = require "luci.model.docker"
local uci = (require "luci.model.uci").cursor()

local m, s, o, lost_state
local socket_path = uci:get("dockerd", "dockerman", "socket_path") or "/var/run/docker.sock"
local remote_endpoint = uci:get_bool("dockerd", "dockerman", "remote_endpoint")
local local_daemon_missing = nixio.fs.access("/usr/bin/dockerd") and not remote_endpoint and not nixio.fs.access(socket_path)
local dk = docker.new()

if local_daemon_missing or dk:_ping().code ~= 200 then
	lost_state = true
end

m = SimpleForm("dockerd",
	translate("Docker - Overview"),
	translate("An overview with the relevant data is displayed here with which the LuCI docker client is connected.")
..
	" " ..
	[[<a href="https://github.com/lisaac/luci-app-dockerman" target="_blank">]] ..
	translate("Github") ..
	[[</a>]])
m.submit=false
m.reset=false

if local_daemon_missing then
	m.message = translate("Docker 服务未启动，请点击下方“启动”按钮启动 Docker。")
end

local docker_info_table = {}
docker_info_table['3ServerVersion'] = {_key=translate("Docker Version"),_value='-'}
docker_info_table['4ApiVersion'] = {_key=translate("Api Version"),_value='-'}
docker_info_table['5NCPU'] = {_key=translate("CPUs"),_value='-'}
docker_info_table['6MemTotal'] = {_key=translate("Total Memory"),_value='-'}
docker_info_table['7DockerRootDir'] = {_key=translate("Docker Root Dir"),_value='-'}
docker_info_table['8IndexServerAddress'] = {_key=translate("Index Server Address"),_value='-'}
docker_info_table['9RegistryMirrors'] = {_key=translate("Registry Mirrors"),_value='-'}

if nixio.fs.access("/usr/bin/dockerd") and not remote_endpoint then
	s = m:section(SimpleSection)
	s.template = "dockerman/apply_widget"
	s.err=docker:read_status()
	s.err=s.err and s.err:gsub("\n","<br>"):gsub(" ","&nbsp;")
	if s.err then
		docker:clear_status()
	end
	s = m:section(Table,{{}})
	s.notitle=true
	s.rowcolors=false
	s.template = "cbi/nullsection"

	o = s:option(Button, "_start")
	o.template = "dockerman/cbi/inlinebutton"
	o.inputtitle = lost_state and translate("Start") or translate("Stop")
	o.inputstyle = lost_state and "add" or "remove"
	o.forcewrite = true
	o.write = function(self, section)
		docker:clear_status()

		if lost_state then
			docker:append_status("Docker daemon: starting...")
			-- 异步启动 Docker，避免阻塞 LuCI 导致页面卡死
			os.execute("/etc/init.d/dockerd start >/dev/null 2>&1 &")
			os.execute("(sleep 8 && /etc/init.d/dockerman start) >/dev/null 2>&1 &")
		else
			docker:append_status("Docker daemon: stopping...")
			os.execute("/etc/init.d/dockerd stop >/dev/null 2>&1 &")
		end
		docker:clear_status()
		luci.http.redirect(luci.dispatcher.build_url("admin/docker/overview"))
	end

	o = s:option(Button, "_restart")
	o.template = "dockerman/cbi/inlinebutton"
	o.inputtitle = translate("Restart")
	o.inputstyle = "reload"
	o.forcewrite = true
	o.write = function(self, section)
		docker:clear_status()
		docker:append_status("Docker daemon: restarting...")
		-- 异步重启，避免阻塞 LuCI
		os.execute("/etc/init.d/dockerd restart >/dev/null 2>&1 &")
		os.execute("(sleep 8 && /etc/init.d/dockerman start) >/dev/null 2>&1 &")
		docker:clear_status()
		luci.http.redirect(luci.dispatcher.build_url("admin/docker/overview"))
	end
end

s = m:section(Table, docker_info_table)
s:option(DummyValue, "_key", translate("Info"))
s:option(DummyValue, "_value")

s = m:section(SimpleSection)
s.template = "dockerman/overview"

s.containers_running = '-'
s.images_used = '-'
s.containers_total = '-'
s.images_total = '-'
s.networks_total = '-'
s.volumes_total = '-'

if not lost_state then
	local containers_list = dk.containers:list({query = {all=true}}).body
	local images_list = dk.images:list().body
	local vol = dk.volumes:list()
	local volumes_list = vol and vol.body and vol.body.Volumes or {}
	local networks_list = dk.networks:list().body or {}
	local docker_info = dk:info()

	docker_info_table['3ServerVersion']._value = docker_info.body.ServerVersion
	docker_info_table['4ApiVersion']._value = docker_info.headers["Api-Version"]
	docker_info_table['5NCPU']._value = tostring(docker_info.body.NCPU)
	docker_info_table['6MemTotal']._value = docker.byte_format(docker_info.body.MemTotal)
	if docker_info.body.DockerRootDir then
		local statvfs = nixio.fs.statvfs(docker_info.body.DockerRootDir)
		local size = statvfs and (statvfs.bavail * statvfs.bsize) or 0
		docker_info_table['7DockerRootDir']._value = docker_info.body.DockerRootDir .. " (" .. tostring(docker.byte_format(size)) .. " " .. translate("Available") .. ")"
	end

	docker_info_table['8IndexServerAddress']._value = docker_info.body.IndexServerAddress
	if docker_info.body.RegistryConfig and docker_info.body.RegistryConfig.Mirrors then
		for i, v in ipairs(docker_info.body.RegistryConfig.Mirrors) do
			docker_info_table['9RegistryMirrors']._value = docker_info_table['9RegistryMirrors']._value == "-" and v or (docker_info_table['9RegistryMirrors']._value .. ", " .. v)
		end
	end

	s.images_used = 0
	for i, v in ipairs(images_list) do
		for ci,cv in ipairs(containers_list) do
			if v.Id == cv.ImageID then
				s.images_used = s.images_used + 1
				break
			end
		end
	end

	s.containers_running = tostring(docker_info.body.ContainersRunning)
	s.images_used = tostring(s.images_used)
	s.containers_total = tostring(docker_info.body.Containers)
	s.images_total = tostring(#images_list)
	s.networks_total = tostring(#networks_list)
	s.volumes_total = tostring(#volumes_list)
else
	if local_daemon_missing then
		docker_info_table['3ServerVersion']._value = translate("Docker 服务未启动，请先启用并启动 dockerd。")
	else
		docker_info_table['3ServerVersion']._value = translate("Can NOT connect to docker daemon, please check!!")
	end
end

return m
