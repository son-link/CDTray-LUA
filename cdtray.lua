#!/usr/bin/lua

lgi = require 'lgi'
Gtk = lgi.Gtk
Gio = lgi.Gio
GLib = lgi.GLib
Gst = lgi.Gst
GdkPixbuf = lgi.GdkPixbuf
Notify = lgi.require('Notify')
Notify.init('CD Tray')

-- Translation
i18n = require 'i18n'
local lang = string.match(os.getenv("LANG"), "(%w+)")
local f=io.open('lang/'..lang..'.lua',"r")
if f~=nil then
	io.close(f)
	i18n.loadFile('lang/'..lang..'.lua')
	i18n.setLocale(lang)
else
	i18n.loadFile('lang/en.lua')
	i18n.setLocale('en')
end


local main_loop = GLib.MainLoop()
statusIcon = Gtk.StatusIcon()
statusIcon:set_from_file('cdtray.svg')
statusIcon:set_tooltip_text(i18n('welcome'))
actualTrack = 1
config = {
	device = '/dev/sr0',
	shownotify = 'false',
	autostart = 'false',
	output = 'pulse',
}

status = -1 -- -1 -> nothing, 0 Stop, 1 play, 2 pause
tags = {}
tracksMenu = nil
pwd = os.getenv("PWD")
homedir = os.getenv("HOME")
pipeline = nil

local app = Gtk.Application { application_id = 'io.sonlink.cdtray' }

-- Configuration
Config = require 'config'
Config.readConf()

-- Menu
local Menu = require 'menu'
local menu = Menu.init()

function createPipeline()
	local cdsrc = string.format('cdparanoiasrc device=%s track=1 name=cdda ! audioconvert ! %ssink', config['device'], config['output'])
	pipeline = Gst.parse_launch(cdsrc)
	pipeline.bus:add_watch(GLib.PRIORITY_DEFAULT, bus_callback)
end

function play()
	if status == 1 then
		pipeline.state = 'PAUSED'
		status = 2
	elseif status == -1 then
		createPipeline()
		pipeline.state = 'PLAYING'
		status = 1
	else
		pipeline.state = 'PLAYING'
		status = 1
	end
end

function nextTrack()
	if actualTrack < tags['track-count'] then
		actualTrack = actualTrack + 1
		pipeline.state = 'READY'
		pipeline:get_by_name("cdda").track = actualTrack
		pipeline.state = 'PLAYING'
	else
		pipeline.state = 'NULL'
		actualTrack = 1
	end
end

function prevTrack()
	if actualTrack > 0 then
		actualTrack = actualTrack - 1
		pipeline.state = 'READY'
		pipeline:get_by_name("cdda").track = actualTrack
		pipeline.state = 'PLAYING'
	else
		pipeline.state = 'NULL'
		actualTrack = 1
	end
end

function jumpTo(n)
	actualTrack = n
	pipeline.state = 'READY'
	pipeline:get_by_name("cdda").track = actualTrack
	pipeline.state = 'PLAYING'
end

function statusIcon:on_activate()
	play()
end

function statusIcon:on_popup_menu(button, time)
	menu:show_all()
	menu:popup(nil, nil, Gtk.status_icon_position_menu, button, time)
end

function bus_callback(bus, message)
	if message.type.ERROR then
		print('Error:', message:parse_error().message)
		main_loop:quit()
	elseif message.type.EOS then
		nextTrack()
	--elseif message.type.STATE_CHANGED then
	--	local old, new, pending = message:parse_state_changed()
		--print(string.format('state changed: %s->%s:%s', old, new, pending))
	elseif message.type.TAG then
		message:parse_tag():foreach(
		function(list, tag)
			--print(('tag: %s = %s'):format(tag, tostring(list:get(tag))))
			if tag == 'track-number' or tag == 'track-count' then
				tags[tag] = math.floor(list:get(tag))
			else
				tags[tag] = tostring(list:get(tag))
			end
		end)
		updateInfo()
	end

	return true
end

function updateInfo()
	statusIcon:set_tooltip_text(i18n('icontooltip', {tracknumber = tags['track-number'], trackcount = tags['track-count']}))
	if config['shownotify'] == '1' then
		do_notify('Playing '..tags['track-number']..' of '..tags['track-count'])
	end
	actualTrack = tags['track-number']
	Menu.update()
end

function do_notify(txt)
    n=Notify.Notification.new('CD Tray', txt, pwd..'/cdtray.svg')
	n:show()
end

function showAbout()
	local icon = GdkPixbuf.Pixbuf.new_from_file(pwd..'/cdtray.svg')
	local dialog = Gtk.AboutDialog{
		title = 'CD Tray',
		program_name = 'CD Tray',
		logo = icon,
		version = '1.0',
		license_type=Gtk.License.GPL_3_0,
		comments = i18n('aboutcom'),
		copyright = '2012-2016 Alfonso Saavedra "Son Link"',
		on_response = Gtk.Widget.destroy,
	}
	dialog:set_name('CD Tray')
	dialog:show_all()
end

if config['autostart'] == '1' then
	play()
end

main_loop:run()
app:run { arg[0], ... }
