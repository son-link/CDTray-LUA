local Config = {}

function Config.readConf()
	for line in io.lines(homedir..'/.cdtray') do
		local key, value = line:match("^([%w_]+)%s-=%s-(.+)$")
		if key ~= nil then
			config[key] = value:gsub("^%s*(.-)%s*$", "%1")
		end
	end
end

function Config.configure()
	configwin = Gtk.Dialog {
		title = i18n('conftitle'),
		resizable = false,
		buttons = {
			{ Gtk.STOCK_SAVE, Gtk.ResponseType.ACCEPT },
			{ Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL },
		},
	}
	content = Gtk.Box {
		orientation = 'VERTICAL',
		spacing = 5,
		border_width = 5,
		Gtk.HBox {
			spacing = 5,
			Gtk.Label {
				label = i18n('device'),
			},
			Gtk.Entry {
				id = 'device',
				completion = Gtk.EntryCompletion {
					model = store,
					text_column = 0,
				},
			},
		},
		Gtk.CheckButton {
			label = i18n('autostart'), id = 'autostart',
		},
		Gtk.CheckButton {
			label = i18n('shownotify'), id = 'shownotify'
		},
		Gtk.HBox {
			spacing = 5,
			Gtk.Label {
				label = i18n('output'),
			},
			Gtk.ComboBoxText {id = 'output'}
		},
	}
	configwin:get_content_area():add(content)
	configwin.child.output:append_text('alsa')
	configwin.child.output:append_text('pulse')
	configwin.child.output:append_text('oss')
	
	-- Set configuration
	configwin.child.device:set_text(config['device'])
	
	if config['autostart'] == '1' then
		configwin.child.autostart.active = true
	end
	
	if config['shownotify'] == '1' then
		configwin.child.shownotify.active = true
	end
	
	if config['output'] == 'alsa' then
		configwin.child.output:set_active(0)
	elseif config['output'] == 'pulse' then
		configwin.child.output:set_active(1)
	elseif config['output'] == 'oss' then
		configwin.child.output:set_active(2)
	end
	
	function configwin:on_response(response_id)
		if response_id == Gtk.ResponseType.ACCEPT then
			file = io.open("cdtray", "w")
			io.output(file)
			io.write('[cdtray]\n')
			io.write(string.format('device = %s\n', configwin.child.device:get_text()))
			io.write(string.format('autostart = %i\n', (configwin.child.autostart.active and 1 or 0)))
			io.write(string.format('shownotify = %i\n', (configwin.child.shownotify.active and 1 or 0)))
			io.write(string.format('output = %s\n', configwin.child.output:get_active_text()))
			io.close(file)
			Config.readConf()
		end
		configwin:hide()
	end
	configwin:show_all()
end

return Config
