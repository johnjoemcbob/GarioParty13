--
-- Gario Party 13
-- 28/06/20
--
-- State: Lobby
--

STATE_LOBBY = "Lobby"

BETWEEN_SPONSOR_CHANGES = 2

local me = {
	"http://johnjoemcbob.com/banner/garioparty_me.png",
	"https://i.imgur.com/ZTdMWwb.png", -- Backup
}
local sponsors = {
	"https://media.gmodstore.com/_/competition_banners/2020/gmodstore.png",
	"https://media.gmodstore.com/_/competition_banners/2020/zerochain.png",
	"https://media.gmodstore.com/_/competition_banners/2020/titsrp.png",
	"https://media.gmodstore.com/_/competition_banners/2020/willox.png",
	"https://media.gmodstore.com/_/competition_banners/2020/cfc.png",
	"https://media.gmodstore.com/_/competition_banners/2020/wisp.png",
	"https://media.gmodstore.com/_/competition_banners/2020/elitelupus.jpg",
	"https://media.gmodstore.com/_/competition_banners/2020/diablosbanner.png",
	"https://media.gmodstore.com/_/competition_banners/2020/crident.png",
	"https://media.gmodstore.com/_/competition_banners/2020/hexane.png",
	"https://media.gmodstore.com/_/competition_banners/2020/vcmod.jpg",
	"https://media.gmodstore.com/_/competition_banners/2020/fudgy.png",
	"https://media.gmodstore.com/_/competition_banners/2020/tombat-banner.png",
	"https://media.gmodstore.com/_/competition_banners/2020/babl.jpg",
	"https://media.gmodstore.com/_/competition_banners/2020/gmodel.png",
	"https://media.gmodstore.com/_/competition_banners/2020/tehbasshunter.png",
	"https://media.gmodstore.com/_/competition_banners/2020/molly-network.png",
}

if ( CLIENT ) then
	MAT_LOGO = Material( "gui/gmod_logo" )
end

GM.AddGameState( STATE_LOBBY, {
	OnStart = function( self )
		-- TODO TEMP
		--timer.Simple( 10, function() GAMEMODE:SwitchState( STATE_BOARD ) end )

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:HideFPSController()
		end

		if ( CLIENT ) then
			-- Create UI
			self:CreateUI()

			Music:Play( MUSIC_TRACK_LOBBY )
		end
	end,
	OnThink = function( self )
		if ( #player.GetAll() > 1 ) then
			GAMEMODE:SwitchState( STATE_BOARD )
		end
		
		if ( CLIENT ) then
			if ( Transition.Active ) then
				self:CreateUIOverlay()
			end
		end
	end,
	OnFinish = function( self )
		-- Hide UI
		if ( CLIENT ) then
			if ( self.Panel and self.Panel:IsValid() ) then
				self.Panel:Remove()
				self.Panel = nil
			end

			Music:Pause( MUSIC_TRACK_LOBBY )
		end

		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			ply:ShowFPSController()
		end

		for k, v in pairs( player.GetAll() ) do
			v:SwitchState( PLAYER_STATE_PLAY )
		end
	end,

	-- Custom functions
	CreateUI = function( self )
		local off = ( 200 - 20 ) / 766 * ScrH()

		-- Fullscreen panel
		self.Panel = vgui.Create( "DPanel" )
		self.Panel:SetSize( ScrW(), ScrH() )
		self.Panel:Center()
			self.Panel.Colour = GAMEMODE.ColourPalette[math.random( 1, #GAMEMODE.ColourPalette )]
			self.Panel.Highlight = GetColourHighlight( self.Panel.Colour )
			self.Panel.Background = math.random( 1, #GAMEMODE.Backgrounds )
			GAMEMODE.Backgrounds[self.Panel.Background].Init( self.Panel )
		function self.Panel:Paint( w, h )
			local function drawtitle( text, font, x, y, col, outwidth, outcol )
				-- Split to characters
				local chars = string.Split( text, "" )
				-- Get overall width first time through
				local w, h = 0, 0
				for k, char in pairs( chars ) do
					surface.SetFont( font )
					local tw, th = surface.GetTextSize( char )
					w = w + tw
					h = th
				end
		
				-- Then render based on this center pos calc
				local gpos = 0
				for k, char in pairs( chars ) do
					local col = GetLoopedColour( k )
					local charx = x - w / 2 + math.cos( CurTime() * 2 + k ) * 2
					local chary = y + math.sin( CurTime() * 2 + k ) * 16
					local tw, th = draw.SimpleTextOutlined( char, font, charx, chary, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outwidth, outcol )
					if ( k == 1 ) then
						gpos = Vector( charx, chary )
					end
					x = x + tw
				end
		
				return gpos
			end
		
			-- Draw background
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )

			-- Title
			local margin = ScrW() / 32
			local x = ScrW() / 2
			local y = ScrH() / 4
			local w = ScrW() / 8
			local h = ScrH() / 16
			local between = 96
			local outlinewidth = 2
			local colour		= COLOUR_WHITE
			local outlinecolour	= COLOUR_BLACK
			local gpos = drawtitle( "Gario Party 13!", "GarioParty", x, y, colour, outlinewidth, outlinecolour )

			-- G icon
			local w = 128 + 16
			local h = w
			local x = gpos.x - w / 2
			local y = gpos.y - h / 2.5
			surface.SetDrawColor( COLOUR_WHITE )
			surface.SetMaterial( MAT_LOGO )
			surface.DrawTexturedRect( x, y, w, h )

			-- Waiting for players
			local x = ScrW() / 2
			local y = y + ScrH() / 4
			draw.SimpleTextOutlined( "Waiting for players...", "SubTitle", x, y, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlinewidth, outlinecolour )

			-- Made By
			local x = ScrW() / 2
			local y = ScrH() - off - 24
			draw.SimpleTextOutlined( "For GGC2020", "DermaLarge", x, y, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, outlinewidth, outlinecolour )
			y = y + 24 
			draw.SimpleTextOutlined( "Theme: Space - Spaces on a board game!", "DermaLarge", x, y, colour, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, outlinewidth, outlinecolour )

			-- Made By
			local x = ScrW() / 64
			local y = ScrH() - off
			draw.SimpleTextOutlined( "Made By", "SubTitle", x, y, colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, outlinewidth, outlinecolour )

			-- Sponsored By
			local x = ScrW() - ScrW() / 64
			local y = ScrH() - off
			draw.SimpleTextOutlined( "Sponsored By", "SubTitle", x, y, colour, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, outlinewidth, outlinecolour )
		end
		-- self.Panel:MakePopup()
		-- self.Panel:MoveToBack()

		-- Credits
		local width = ScrW() / 2
		local height = ScrH()

		-- Me credits (backup)
		local html = vgui.Create( "DHTML", self.Panel )
		html:SetSize( width, height )
		--html:Dock( LEFT )
		html:SetPos( 0, ScrH() - off )
		html:SetHTML( [[
			<img style="text-align: center" src="]] .. me[2] .. [[" width="100%" style="position: absolute;bottom: 0px;">
		]] )

		-- Me credits
		local html = vgui.Create( "DHTML", self.Panel )
		html:SetSize( width, height )
		--html:Dock( LEFT )
		html:SetPos( 0, ScrH() - off )
		html:SetHTML( [[
			<img style="text-align: center" src="]] .. me[1] .. [[" width="100%" style="position: absolute;bottom: 0px;">
		]] )
		html.NextChange = 0
		html.Sponsor = 0
		-- function html:Think()
		-- 	if ( self.NextChange <= CurTime() ) then
		-- 		self.Sponsor = self.Sponsor + 1
		-- 			if ( self.Sponsor > #me ) then self.Sponsor = 1 end
		-- 		self:SetHTML( [[
		-- 			<img style="text-align: center" src="]] .. me[self.Sponsor] .. [[" width="100%">
		-- 		]] )
		-- 		self.NextChange = CurTime() + BETWEEN_SPONSOR_CHANGES
		-- 	end
		-- end

		-- Background loader (?)
		local html = vgui.Create( "DHTML", self.Panel )
		html:SetSize( width, height )
		--html:Dock( RIGHT )
		html:SetPos( ScrW(), ScrH() )
		html.NextChange = 0
		html.Sponsor = 0
		function html:Think()
			if ( self.NextChange <= CurTime() ) then
				self.Sponsor = self.Sponsor + 1
					if ( self.Sponsor > #sponsors ) then self:Remove() return end
				self:SetHTML( [[
					<img style="text-align: center" src="]] .. sponsors[self.Sponsor] .. [[" width="100%">
				]] )
				self.NextChange = CurTime() + 0.1
			end
		end

		-- They credits
		local function randomise()
			local shuffled = {}
			for k, v in pairs( sponsors ) do
				local pos = math.random( 1, #shuffled + 1 )
				table.insert( shuffled, pos, v )
			end
			sponsors = shuffled
		end
		randomise()
		local html = vgui.Create( "DHTML", self.Panel )
		html:SetSize( width, height )
		--html:Dock( RIGHT )
		html:SetPos( ScrW() / 2, ScrH() - off )
		html.NextChange = 0
		html.Sponsor = 0
		function html:Think()
			if ( self.NextChange <= CurTime() ) then
				self.Sponsor = self.Sponsor + 1
					if ( self.Sponsor > #sponsors ) then self.Sponsor = 1 randomise() end
				self:SetHTML( [[
					<img style="text-align: center" src="]] .. sponsors[self.Sponsor] .. [[" width="100%">
				]] )
				self.NextChange = CurTime() + BETWEEN_SPONSOR_CHANGES
			end
		end

		self:CreateUIOverlay()
	end,
	CreateUIOverlay = function( self )
		-- Transition overlay
		local overlay = vgui.Create( "DPanel", self.Panel )
		overlay:SetSize( ScrW(), ScrH() )
		overlay:Center()
		function overlay:Paint( w, h )
			if ( Transition.Active ) then
				if ( self.Panel and self.Panel:IsValid() ) then
					self.Panel:SetMouseInputEnabled( false )
				end
				Transition:Render()
			else
				if ( self.Panel and self.Panel:IsValid() ) then
					-- Wait for transition before showing cursor
					self.Panel:MakePopup()
					self.Panel:MoveToBack()
					self.Panel:SetKeyboardInputEnabled( false )
				end

				overlay:Remove()
				overlay = nil
			end
		end
	end,
})

if ( SERVER ) then
	-- Return to lobby if there are no players connected
	hook.Add( "Think", HOOK_PREFIX .. STATE_LOBBY .. "Think", function()
		if ( GAMEMODE:GetStateName() != STATE_LOBBY ) then
			if ( #player.GetAll() == 0 ) then
				--GAMEMODE:SwitchState( STATE_LOBBY )
				RunConsoleCommand( "changelevel", "gm_construct" )
			end
		end
	end )
end

if ( CLIENT ) then
	-- TODO TEMP HOTRELOAD TESTING
	if ( GAMEMODE ) then
		local self = GAMEMODE.GameStates[STATE_LOBBY]
		if ( self.Panel and self.Panel:IsValid() ) then
			self.Panel:Remove()
			self.Panel = nil
			self:CreateUI()
		end
	end
end
