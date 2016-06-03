local Menu = {}
local menu

function getStockIcon(iconName)
	local img = Gtk.Image{icon_name=iconName}
	return img
end

function Menu.init()
	menu = Gtk.Menu {visible=true,
		Gtk.ImageMenuItem {
			label = i18n('play'), id='playBtn',
			on_activate = function()
				play()
			end
		},
		Gtk.ImageMenuItem {
			label = i18n('prev'), id='nextBtn',
			on_activate = function()
				prevTrack()
			end
		},
		Gtk.ImageMenuItem {
			label = i18n('next'), id='prevBtn',
			on_activate = function()
				nextTrack()
			end
		},
		Gtk.ImageMenuItem {
			label = i18n('jumpto'),
			visible = true,
			--submenu = tracksMenu,
			id = 'submenu',
		},
		Gtk.ImageMenuItem {
			label = i18n('stop'), id='stopBtn',
			on_activate = function()
				pipeline.state = 'NULL'
				status = 0
			end
		},
		Gtk.ImageMenuItem {
			label = i18n('eject'), id='ejectBtn',
			on_activate = function()
				pipeline.state = 'NULL'
				os.execute('eject '..device)
				actualTrack = 1
				status = -1
			end
		},
		Gtk.SeparatorMenuItem {},
		Gtk.ImageMenuItem {
			label = i18n('preferences'), id='configBtn',
			on_activate = function()
				Config.configure()
			end
		},
		Gtk.ImageMenuItem {
			label = i18n('about'), id='aboutBtn',
			on_activate = function()
				showAbout()
			end
		},
		Gtk.ImageMenuItem {
			label = i18n('quit'), id='quitBtn',
			on_activate = function()
				pipeline.state = 'NULL'
				main_loop:quit()
			end
		}
	}
	-- Set icons
	menu.child.playBtn:set_image( getStockIcon(Gtk.STOCK_MEDIA_PLAY))
	menu.child.nextBtn:set_image( getStockIcon(Gtk.STOCK_MEDIA_NEXT))
	menu.child.prevBtn:set_image( getStockIcon(Gtk.STOCK_MEDIA_PREVIOUS))
	menu.child.submenu:set_image( getStockIcon(Gtk.STOCK_JUMP_TO))
	menu.child.stopBtn:set_image( getStockIcon(Gtk.STOCK_MEDIA_STOP))
	menu.child.ejectBtn:set_image( getStockIcon('media-eject'))
	menu.child.configBtn:set_image( getStockIcon(Gtk.STOCK_PREFERENCES))
	menu.child.aboutBtn:set_image( getStockIcon(Gtk.STOCK_ABOUT))
	menu.child.quitBtn:set_image( getStockIcon(Gtk.STOCK_QUIT))
	return menu
end

function Menu.update()
	-- Regen the tracks submenu
	tracksMenu = Gtk.Menu()
	local submenu = menu.child.submenu
	submenu = Gtk.Menu()
	for i = 1, tags['track-count'] do
		local n
		if i < 10 then
			n = '0'..tostring(math.floor(i))
		else
			n = i
		end
		local m = Gtk.MenuItem{
			visible = true,
			label = 'Track '..n,
			on_activate = function()
				jumpTo(i)
			end
		}
		if i == actualTrack then
			m:set_sensitive(false)
		end
		tracksMenu:append(m)
	end
	menu.child.submenu:set_submenu(tracksMenu)
end

return Menu
