addon.name = 'TrackMeBooty'
addon.author = 'Arielfy'
addon.version = '0.2'
addon.desc = 'Item Tracker'
addon.link = 'https://github.com/ariel-logos/TrackMeBooty'

require 'common'
imgui = require('imgui')
imguiWrap = require('imguiWrap')
local ffi = require('ffi');
local d3d       = require('d3d8');
local C         = ffi.C;
local d3d8dev   = d3d.get_device();
local settings = require('settings');

local cd = 0
local incrcd = 0
local zonecd = 0
local incridx = {}
local maxlength = 0
local invs = T{}
local items = T{}
local tracked = T{}
local loaded = false
local amounts = T{}
local colors = 
T{
	white = { 1.0, 1.0, 1.0, 1.0},
	green = { 0.0, 1.0, 0.0, 1.0},
}
local charsize
local pirateTex
local pirateId
local bubbleTex
local bubbleId

local defaultsettings = 
T{
	pirate = true,
	lastlist = '',
	reloadlist = true,
}
local currentsettings = T{}

local function save_settings()
    settings.save('settings');
end

local function FindInTableT(sometable, f)
	local idx = 0;
	local result = {}
	if sometable then
		for _, t in pairs(sometable) do
			
			idx=idx+1;
			if (t == f) then table.insert(result, idx) end
		end
	end
	if #result > 0 then return result end
	return nil
end

ffi.cdef[[
    // Exported from Addons.dll
    HRESULT __stdcall D3DXCreateTextureFromFileA(IDirect3DDevice8* pDevice, const char* pSrcFile, IDirect3DTexture8** ppTexture);
]];

local function loadTexture(name)
	local textureID;
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local res = C.D3DXCreateTextureFromFileA(d3d8dev, string.format('%s/img/%s.png', addon.path, name), texture_ptr);
    if (res ~= C.S_OK) then
        error(('Failed to load image texture: %08X (%s)'):fmt(res, d3d.get_error(res)));
    end;
    textureID = ffi.new('IDirect3DTexture8*', texture_ptr[0]);
    d3d.gc_safe_release(textureID);
	return textureID;
end

ashita.events.register('load', 'load_callback1', function ()
	currentsettings = settings.load(defaultsettings, 'settings');
	pirateTex = loadTexture('pirate');
	pirateId = tonumber(ffi.cast("uint32_t", pirateTex));
	bubbleTex = loadTexture('bubble');
	bubbleId = tonumber(ffi.cast("uint32_t", bubbleTex));
	charsize = imgui.CalcTextSize('A')
end);


ashita.events.register('command', 'command_callback1', function (e)

	local args = e.command:args()
	if #args == 0 or not args[1]:any('/tmb') then
		return
	end
	
	e.blocked = true
	
	if #args == 2 then
		if args[2] == 'list' then
			local folder =  addon.path.."lists"
			local cmd = string.format('dir "%s" /b /a-d', folder)
			local path = io.popen(cmd)
			if not path then print('[TMB] Blimey! Somethin\' went afoul accessing path: ['..folder..']') return end
			print('[TMB] Behold, ye scallywag! The ship\'s log o\' plunder:')
			for filename in path:lines() do
				local name = filename:gsub('.txt$','')
				print('> '..name)
			end
			path:close()
		end
		if args[2] == 'pirate' then
			
			currentsettings.pirate = not currentsettings.pirate
			if currentsettings.pirate then
				print('[TMB] Har har! Glad t’ lay me eye on ye again, matey!')
			else
				print('[TMB] Aye, I get it... ye ain’t too fond o’ me, eh?')
			end
			save_settings()
		end
		if args[2] == 'loadlast' then
			currentsettings.reloadlist = not currentsettings.reloadlist
			if currentsettings.reloadlist then
				print('[TMB] Yer list’ll be hoisted again next time, aye!')
			else
				print('[TMB] Yer list won’t be hoisted again next time, arrr!')
			end
			save_settings()
		end
		
	end
	
	if #args == 3 then
		if args[2] == 'save' then
			if #tracked == 0 then print('[TMB] Shiver me timbers! Ye can\'t save a loot log with no booty!!') return end
			local folder =  addon.path.."lists"
			local success = os.execute("mkdir "..folder) 

			local filename = folder..'\\'..args[3]..".txt"
			local file = io.open(filename, "w")
			if not file then
				print('[TMB] Blimey! Somethin\' went afoul opening file: ['..filename..']')
				return
			end
			for t = 1, #tracked do
				file:write('------- Item '..tostring(t)..' -------\n')
				file:write('Name: '..tostring(tracked[t][1])..'\n')
				file:write('Id: '..tostring(tracked[t][2])..'\n')
				file:write('Target Quantity: '..tostring(tracked[t][3])..'\n')
			end
			io.close(file);
			print('[TMB] Yer loot log be stowed safe \'n sound: ['..args[3]..']')
			
		elseif args[2] == 'load' then
			local folder =  addon.path.."lists"
			local filename = folder..'\\'..args[3]..".txt"
			local file = io.open(filename, "r")
			if not file then
				print('[TMB] Blimey! Somethin\' went afoul opening file: ['..filename..']')
				return
			end
			
			tracked = {}
			local name
			local id
			local quantity
			for line in file:lines() do
				if line:match('^Name: .*$') then
					name = line:gsub('^Name: ',''):gsub('\n','')
				elseif line:match('^Id: .*$') then
					id = line:gsub('^Id: ',''):gsub('\n','')
				elseif line:match('^Target Quantity: .*$') then
					quantity = line:gsub('^Target Quantity: ',''):gsub('\n','')
				end
				if name and id and quantity then
					table.insert(tracked, {name, tonumber(id), tonumber(quantity)})
					name = nil
					id = nil
					quantity = nil
				end
			end
			file:close()
			print('[TMB] Arrr, yer list be loaded and ready, matey!: ['..args[3]..']')
			currentsettings.lastlist = args[3]
			save_settings()
			amounts = T{}
			cd = 0
		end
	end
	
	if #args > 2 then
		if args[2] == 'track' and args[3] then
			local name = args[3]
			local idx = 4
			local quantity = 0
			while args[idx] do
				if args[idx]:match('^%d*$') then
					quantity = tonumber(args[idx])
					break
				end
				name = name..' '..args[idx]
				idx = idx + 1
			end
			name = name:gsub("(%S+)", function(w) return w:sub(1,1):upper()..w:sub(2):lower() end)
			local item = AshitaCore:GetResourceManager():GetItemByName(name, 0)
			if item then
				local exists = false
				for e = 1, #tracked do
					if tracked[e][1] == name then exists = e break end
				end
				if exists then
					tracked[exists][3] = quantity
					print('[TMB] The marked loot\'s been freshened up, cap\'n: ['..name..']')
					cd = os.time()
				else
					table.insert(tracked, {name, item.Id, quantity})
					print('[TMB] Keepin\' an eye on this booty: ['..name..']')
					cd = 0
				end		
			else
				print('[TMB] Arrr! That be no proper name fer treasure: ['..name..']')
			end
		end
		if args[2] == 'untrack' and args[3] then
			local name = args[3]
			if name == 'all' then
				tracked = {}
				cd = 0
				amounts = T{}
				print('[TMB] Avast! The whole list be lost to the depths!')
				return
			end
			local idx = 4
			while args[idx] do
				name = name..' '..args[idx]
				idx = idx + 1
			end
			for t = 1, #tracked do
				if string.lower(tracked[t][1]) == string.lower(name)
					then table.remove(tracked, t)
					print('[TMB] No longer spyin\' on this treasure: ['..name..']')
					cd = 0
					amounts = T{}
					return
				end	
			end
			print('[TMB] Blast it! I couldn\'t find any booty by the name: ['..name..']')
		end
	end
	
end);

ashita.events.register('d3d_present', 'd3d_present_callback1', function ()
	-- The "main loop", runs once per frame
	
	if AshitaCore:GetMemoryManager():GetPlayer():GetLoginStatus() == 2 and os.clock() - zonecd > 3 then
	
		if not loaded then
			loaded = true
			print('[TMB] Ahoy, matey! Let’s be markin\' some booty fer keepin\'~')
			if currentsettings.reloadlist and #currentsettings.lastlist > 0 then
				AshitaCore:GetChatManager():QueueCommand(-1, '/tmb load '..currentsettings.lastlist)
			end
		end
		
		if (os.time() - cd > 1 and os.clock() - zonecd > 15) then
			local RM = AshitaCore:GetResourceManager()
			local inv = AshitaCore:GetMemoryManager():GetInventory()
			cd = os.time()
			items = T{}
			maxlength = 0
			local idx = 1
			
			for i = 0, 16 do
				invs[i] = {}
				invs[i].size = inv:GetContainerCount(i)
				for j = 1, invs[i].size do
					local invitem = inv:GetContainerItem(i, j)
					item = RM:GetItemById(invitem.Id)
					
					if item then
						
						if not items[item.Id] then
							items[item.Id] = {}
							items[item.Id].name = item.Name[1]
							if invitem.Count then
								items[item.Id].size = invitem.Count
							else
								items[item.Id].size = 0
							end
						else
							if invitem.Count then
								items[item.Id].size = items[item.Id].size + invitem.Count
							else
								items[item.Id].size = 0
							end
						end
						
					end
				end
			end
			
			for i = 1, #tracked do
				if tracked[i][2] < 0 then
					
					local t = RM:GetItemByName(tracked[i][1], 0)
					tracked[i][2] = t.Id
				end
				if items[tracked[i][2]] then
					if amounts[i] and items[tracked[i][2]].size > amounts[i] then
						incrcd = os.clock()
						for c = 1, items[tracked[i][2]].size - amounts[i] do
							table.insert(incridx, i)
						end
					end
					amounts[i] = items[tracked[i][2]].size
				else
					amounts[i] = 0
				end
				if #tracked[i][1] > maxlength then maxlength = #tracked[i][1] end
			end
		end
		
		local dsize = imgui.GetIO().DisplaySize
		imgui.SetNextWindowPos({dsize.x/2, dsize.y/2}, ImGuiCond_FirstUseEver);
			local windowFlags = bit.bor(
			ImGuiWindowFlags_NoDecoration, 
			ImGuiWindowFlags_AlwaysAutoResize, 
			ImGuiWindowFlags_NoFocusOnAppearing, 
			ImGuiWindowFlags_NoNav,
			ImGuiWindowFlags_NoBringToFrontOnFocus);
		
		local winposx, winposy
		local winsizex, winsizey
		
		imgui.PushStyleColor(ImGuiCol_WindowBg, {0.1,0.1,0.1,1.0});
		if imgui.Begin('Tracked booty', true, windowFlags) then
			


			imgui.Text('Tracked Booty')
			imgui.Separator()
			
			for i = 1, #tracked do
				if amounts[i] then
					
					imguiWrap.TextLinkOpenURL(tracked[i][1]..string.rep(' ',maxlength - #tracked[i][1]), 'https://www.bg-wiki.com/ffxi/'..tracked[i][1]:gsub(' ','_'))
					
					local f
					if #incridx > 0 then f = FindInTableT(incridx, i) end 
					if os.clock() - incrcd < 2.5 and f then
						imgui.SameLine()
						if #f > 9 then
							imgui.SetCursorPosX(imgui.GetCursorPosX() - (charsize/2))
						end			
						imgui.TextColored(colors.green, (#f<10 and ' ' or '')..'[+'..#f..']')
					elseif os.clock() - incrcd > 2.5 then
						incridx = {}
						imgui.SameLine()
						imgui.Text('    ')
					else
						imgui.SameLine()
						imgui.Text('    ')
					end
					imgui.SameLine()
					if f and #f > 9 then
						imgui.SetCursorPosX(imgui.GetCursorPosX() - (charsize/2))
					end	
					local col = colors.white
					if amounts[i] and tracked[i][3] > 0 and amounts[i] >= tracked[i][3] then col = colors.green end
					imgui.TextColored(col, '['..tostring(amounts[i])..(tracked[i][3] > 0 and '/'..tostring(tracked[i][3])..']' or ']'))
				end
			end
			
			winposx, windowposy = imgui.GetWindowPos()
			pwinsizex, pwinsizey = imgui.GetWindowSize()
			winsizex, winsizey = imgui.CalcTextSize('Tracked Booty');
			
			
		end
		
		imgui.End()
		imgui.PopStyleColor(1);
		
		if currentsettings.pirate then
			imgui.SetNextWindowSize({ winsizex, winsizex });
			imgui.SetNextWindowPos({winposx+pwinsizex-winsizex, windowposy-winsizex+16});
			local windowFlags = bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_NoResize ,ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoBringToFrontOnFocus, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoMove,ImGuiWindowFlags_NoSavedSettings);
			
			local positionStartX, positionStartY = imgui.GetCursorScreenPos();

			if imgui.Begin('Pirate', true, windowFlags) then
				if (pirateId ~= nil) then
					imgui.GetWindowDrawList():AddImage(pirateId, {winposx+pwinsizex-winsizex, windowposy-winsizex+16}, {winposx+pwinsizex, windowposy+16}, {0,0}, {1,1}, imgui.GetColorU32({ 1.0, 1.0, 1.0, 1.0 }));
				end
			end
			winposx, windowposy = imgui.GetWindowPos()
			pwinsizex, pwinsizey = imgui.GetWindowSize()
			winsizex, winsizey = imgui.CalcTextSize('Tracked Booty');
			imgui.End()
			
			if os.clock() - incrcd < 2.5 then

				imgui.SetNextWindowSize({ winsizex, winsizex });
				imgui.SetNextWindowPos({winposx-(winsizex/1.5), windowposy-(winsizex/2.5)});
			
				if imgui.Begin('Bubble', true, windowFlags) then
					if (bubbleId ~= nil) then
						imgui.GetWindowDrawList():AddImage(bubbleId, {winposx-(winsizex/1.5), windowposy-(winsizex/2.5) }, {winposx+(winsizex/2.5) ,windowposy+(winsizex/1.5)}, {0,0}, {1,1}, imgui.GetColorU32({ 1.0, 1.0, 1.0, 1.0 }));
					end
				end
				imgui.End()
			end
		end
	elseif AshitaCore:GetMemoryManager():GetPlayer():GetLoginStatus() ~= 2 then
		zonecd = os.clock()
	end
end);

