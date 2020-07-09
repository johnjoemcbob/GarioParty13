--
-- Gario Party 13
-- 03/07/20
--
-- State: Minigame Intro
--

STATE_MINIGAME_INTRO = "Minigame_Intro"

local HOOK_PREFIX = HOOK_PREFIX .. STATE_MINIGAME_INTRO .. "_"

MinigameIntro = MinigameIntro or {}
--MinigameIntro.Panel = MinigameIntro.Panel or nil

READY_NONE		= 0
READY_REAL		= 1
READY_PRACTICE	= 2

local LERPSPEED = 600
local LERPSIZESPEED = 200

-- Resources
if ( SERVER ) then
	resource.AddFile( "materials/hearts.png" )
end
if ( CLIENT ) then
	MAT_HEARTS = Material( "hearts.png", "noclamp smooth" )

	surface.CreateFont( "MinigameTitle", {
		font = "Arial",
		extended = false,
		size = 64,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	})
end

GM.AddGameState( STATE_MINIGAME_INTRO, {
	OnStart = function( self )
		-- Find a random minigame
		if ( SERVER ) then
			local games = table.GetKeys( GAMEMODE.Games ) -- TODO TEMP USE THIS WHEN ALL IMPLEMENTED
			local games = {
				"Scary Game",
				--"Teeth",
				--"Screencheat",
			}
			self.Minigame = games[math.random( 1, #games )]
			MinigameIntro:BroadcastMinigame( self.Minigame )
		end

		-- Init columns of readiness
		if ( CLIENT ) then
			MinigameIntro.Columns = {}
			MinigameIntro.Columns[READY_NONE] = {}
			MinigameIntro.Columns[READY_REAL] = {}
			MinigameIntro.Columns[READY_PRACTICE] = {}
		end

		-- Initialise none ready
		MinigameIntro.Ready = {}
		for k, ply in pairs( player.GetAll() ) do
			MinigameIntro:SetReady( ply, READY_NONE )

			-- Bot testing
			if ( ply:IsBot() ) then
				timer.Simple( 0.5 + 0.5 * k, function()
					MinigameIntro:MoveReady( ply, 1 )
				end )
			end
		end

		-- Create UI
		if ( CLIENT ) then
			MinigameIntro:CreateMinigameIntroUI( self.Minigame )
		end
	end,
	OnThink = function( self )
		if ( CLIENT ) then
			if ( Transition.Active ) then
				MinigameIntro:CreateMinigameIntroUIOverlay()
			end
		end
	end,
	OnFinish = function( self )
		if ( CLIENT ) then
			if ( MinigameIntro.Panel and MinigameIntro.Panel:IsValid() ) then
				MinigameIntro.Panel:Remove()
				MinigameIntro.Panel = nil
			end
			
			-- Minigame specific UI
			if ( GAMEMODE.Games[self.Minigame].FinishWaitingUI ) then
				GAMEMODE.Games[self.Minigame]:FinishWaitingUI()
			end
			if ( GAMEMODE.Games[self.Minigame].SaveWaiting ) then
				GAMEMODE.Games[self.Minigame]:SaveWaiting()
			end
		end
	end,
})

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_"
local NETSTRING_MINIGAME = HOOK_PREFIX .. "Net_Minigame"
local NETSTRING_WAITING_CUSTOM = HOOK_PREFIX .. "Net_Waiting"
local NETSTRING_WAITING_BROADCAST = HOOK_PREFIX .. "Net_Waiting_Broadcast"
local NET_INT = 3
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_MINIGAME )
	util.AddNetworkString( NETSTRING_WAITING_CUSTOM )
	util.AddNetworkString( NETSTRING_WAITING_BROADCAST )

	function MinigameIntro:BroadcastReady( ply, ready )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
			net.WriteInt( ready, NET_INT )
		net.Broadcast()
	end

	function MinigameIntro:BroadcastMinigame( minigame )
		-- Communicate to all clients
		net.Start( NETSTRING_MINIGAME )
			net.WriteString( minigame )
		net.Broadcast()
	end

	net.Receive( NETSTRING_WAITING_CUSTOM, function( lngth, ply )
		local tab = net.ReadTable()
		MinigameIntro:BroadcastWaitingCustom( ply, tab )
	end )

	function MinigameIntro:BroadcastWaitingCustom( ply, tab )
		-- Communicate to all clients
		net.Start( NETSTRING_WAITING_BROADCAST )
			net.WriteEntity( ply )
			net.WriteString( GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame )
			net.WriteTable( tab )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()
		local ready = net.ReadInt( NET_INT )

		MinigameIntro:SetReady( ply, ready )
	end )

	net.Receive( NETSTRING_MINIGAME, function( lngth )
		local minigame = net.ReadString()

		GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame = minigame
	end )

	function MinigameIntro:SendWaitingToServer( tab )
		-- Send customised waiting stuff to server
		net.Start( NETSTRING_WAITING_CUSTOM )
			net.WriteTable( tab )
		net.SendToServer()
	end

	net.Receive( NETSTRING_WAITING_BROADCAST, function( lngth )
		local ply = net.ReadEntity()
		local game = net.ReadString()
		local tab = net.ReadTable()

		-- Look up minigame receive
		if ( GAMEMODE.Games[game].ReceiveWaiting ) then
			GAMEMODE.Games[game]:ReceiveWaiting( ply, tab )
		end
	end )
end

-- Functions
function MinigameIntro:MoveReady( ply, dir )
	if ( SERVER ) then
		-- Store on server (& self local)
		local old = self.Ready[ply]
		self:SetReady( ply, math.Clamp( old + dir, READY_NONE, READY_PRACTICE ) )

		-- Voting
		local start = true
			for k, v in pairs( player.GetAll() ) do
				if ( self.Ready[v] != READY_REAL ) then
					start = false
					break
				end
			end
		if ( start ) then
			GAMEMODE.GameStates[STATE_MINIGAME].Minigame = GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame
			GAMEMODE:SwitchState( STATE_MINIGAME )
		end

		-- Broadcast to clients
		if ( old != self.Ready[ply] ) then
			self:BroadcastReady( ply, self.Ready[ply] )
		end
	end
end

function MinigameIntro:SetReady( ply, ready )
	if ( CLIENT ) then
		local old = MinigameIntro.Ready[ply]
		if ( old ) then
			table.RemoveByValue( self.Columns[old], ply )
		end
	end

	self.Ready[ply] = ready

	if ( CLIENT ) then
		table.insert( self.Columns[ready], ply )
	end
end

hook.Add( "KeyPress", HOOK_PREFIX .. "KeyPress", function( ply, key )
	if ( GAMEMODE:GetStateName() == STATE_MINIGAME_INTRO ) then
		if ( key == IN_MOVELEFT ) then
			MinigameIntro:MoveReady( ply, -1 )
		end
		if ( key == IN_MOVERIGHT ) then
			MinigameIntro:MoveReady( ply, 1 )
		end
	end
end )

-- UI
if ( CLIENT ) then
	local layouts = {
		[1] = {
			{ Vector( 0, 0 ), 128 },
		},
		[4] = {
			{ Vector( -32, 0 ), 64 },
			{ Vector( 32, 0 ), 64 },
			{ Vector( -32, 64 ), 64 },
			{ Vector( 32, 64 ), 64 },
		},
		[9] = {
			{ Vector( -32	, 0 ), 32 },
			{ Vector( 0		, 0 ), 32 },
			{ Vector( 32	, 0 ), 32 },
			{ Vector( -32	, 32 ), 32 },
			{ Vector( 0		, 32 ), 32 },
			{ Vector( 32	, 32 ), 32 },
			{ Vector( -32	, 64 ), 32 },
			{ Vector( 0		, 64 ), 32 },
			{ Vector( 32	, 64 ), 32 },
		},
	}

	-- Create UI
	local time = 0
	function MinigameIntro:CreateMinigameIntroUI( minigame )
		local leftx = ScrW() / 3.5
		local leftwidth = ScrW() / 3
		local rightwidth = ( ScrW() - ( leftx + leftwidth / 2 ) ) * 0.8
		local rightx = ( leftx + leftwidth / 2 + rightwidth / 2 ) * 1.15

		-- Fullscreen panel
		MinigameIntro.Panel = vgui.Create( "DPanel" )
		MinigameIntro.Panel:SetSize( ScrW(), ScrH() )
		MinigameIntro.Panel:Center()
			MinigameIntro.Panel.Colour = GAMEMODE.ColourPalette[math.random( 1, #GAMEMODE.ColourPalette )]
			MinigameIntro.Panel.Highlight = GetColourHighlight( MinigameIntro.Panel.Colour )
			MinigameIntro.Panel.Background = math.random( 1, #GAMEMODE.Backgrounds )
			GAMEMODE.Backgrounds[MinigameIntro.Panel.Background].Init( MinigameIntro.Panel )
		function MinigameIntro.Panel:Paint( w, h )
			-- Draw background blue
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )

			-- Draw foreground white
			local width = leftwidth * 1.2
			surface.SetDrawColor( COLOUR_WHITE )
			surface.DrawRect( leftx - width / 2, 0, width, h )
		end

		-- Minigame title
		local text = minigame
		local font = "MinigameTitle"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntro.Panel )
		label:SetPos( leftx - twidth / 2, ScrH() / 18 - theight / 2 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Video HTML panel
		local videowidth = leftwidth * 1.5
		local width = videowidth * 1.1
		local html = vgui.Create( "DHTML" , MinigameIntro.Panel )
		html:SetSize( width, width )
		html:SetPos( leftx - videowidth / 2 - 6, ScrH() / 8 * 4.7 - width / 2 )
		html:SetHTML( [[
			<img style="text-align: center" src=" ]] .. GAMEMODE.Games[minigame].GIF .. [[ " width=" ]] .. videowidth .. [[ ">
		]] )

		-- Tag line
		local text = GAMEMODE.Games[minigame].TagLine
		local font = "ScoreboardDefault"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntro.Panel )
		label:SetPos( leftx - twidth / 2, ScrH() / 8 * 6.5 - theight / 2 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )

		-- Minigame intructions
		local text = GAMEMODE.Games[minigame].Instructions
		local font = "CloseCaption_Normal"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", MinigameIntro.Panel )
		label:SetPos( leftx - twidth / 2, ScrH() / 8 * 6.8 )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_MED )

		-- Minigame controls
		local text = GAMEMODE.Games[minigame].Controls
		local font = "CloseCaption_Normal"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
			twidth = 128
		local label = vgui.Create( "DLabel", MinigameIntro.Panel )
		label:SetPos( rightx - rightwidth / 2.6 - twidth / 2, ScrH() / 7 )
		label:SetFont( font )
		label:SetText( text )
		label:SizeToContents()
		label:SetTextColor( COLOUR_UI_TEXT_LIGHT )

		-- Minigame specific UI
		if ( GAMEMODE.Games[minigame].CreateWaitingUI ) then
			local w, h = rightwidth, ScrH() / 3
			local panel = vgui.Create( "DPanel", MinigameIntro.Panel )
			panel:SetSize( w, h )
			panel:SetPos( rightx - rightwidth / 2, ScrH() / 3 )
			function panel:Paint( w, h )
			end

			GAMEMODE.Games[minigame]:CreateWaitingUI( panel, w, h )
		end
		if ( GAMEMODE.Games[minigame].LoadWaiting ) then
			GAMEMODE.Games[minigame]:LoadWaiting()
		end

		-- Players/Votes
		local font = "CloseCaption_Normal"
		local y = ScrH() / 6 * 4.5
		MinigameIntro:CreateMinigameIntroUILabel( "Not Ready", font, rightx - rightwidth / 3 - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		MinigameIntro:CreateMinigameIntroUILabel( "_VOTE_", font, rightx + rightwidth / 3 / 1.7 - twidth / 2, y - 32, COLOUR_UI_TEXT_LIGHT )
		MinigameIntro:CreateMinigameIntroUILabel( "Play for Real", font, rightx - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		MinigameIntro:CreateMinigameIntroUILabel( "Practice", font, rightx + rightwidth / 3 - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )

		-- Test player icon
		for k, ply in pairs( player.GetAll() ) do
			local icon = vgui.Create( "DModelPanel", MinigameIntro.Panel )
			--icon:SetSize( 200, 200 )
			--icon:SetPos( rightx - twidth / 2, y + 64 )
			icon:SetModel( "models/player/alyx.mdl" )
			icon.Size = 64
			function icon:Think()
				if ( !MinigameIntro.Ready ) then return end

				local ready = MinigameIntro.Ready[ply]

				-- Position and scale by number of playres in column
				local count = #MinigameIntro.Columns[ready]
				local index = table.indexOf( MinigameIntro.Columns[ready], ply )
				local layout
					-- Find closest layout
					local min = -1
					for int, lay in pairs( layouts ) do
						if ( count <= int and ( min == -1 or int < min ) ) then
							min = int
						end
					end
					layout = layouts[min]
				local offset = layout[index][1]
				local size = layout[index][2]

				-- Lerp move
				local x = {}
					x[0] = -rightwidth / 3
					x[1] = 0
					x[2] = rightwidth / 3
				local target = Vector( rightx + x[ready] - twidth / 2 + offset.x, y + 32 + offset.y )
				icon.Pos = icon.Pos or target
				icon.Pos = ApproachVector( FrameTime() * LERPSPEED, icon.Pos, target )
				icon:SetPos( icon.Pos.x, icon.Pos.y )

				icon.Size = math.Approach( icon.Size, size, FrameTime() * LERPSIZESPEED )
				icon:SetSize( icon.Size, icon.Size )
			end
		end
 
		-- Test button
		-- local DermaButton = vgui.Create( "DButton", MinigameIntro.Panel )
		-- DermaButton:SetText( "Say hi" )
		-- DermaButton:SetPos( ScrW() - 250, ScrH() - 150 )
		-- DermaButton:SetSize( 250, 150 )
		-- DermaButton.DoClick = function()
		-- 	RunConsoleCommand( "say", "Hi" )
		-- 	print( "HI HI HI" )
		-- end

		MinigameIntro:CreateMinigameIntroUIOverlay()
	end

	function MinigameIntro:CreateMinigameIntroUILabel( text, font, x, y, colour )
		surface.SetFont( font )
		local twidth, theight = surface.GetTextSize( text )

		local label = vgui.Create( "DLabel", MinigameIntro.Panel )
			label:SetPos( x, y )
			label:SetSize( twidth, theight )
			label:SetFont( font )
			label:SetText( text )
			label:SetTextColor( colour )
		return label
	end

	function MinigameIntro:CreateMinigameIntroUIOverlay()
		-- Transition overlay
		local overlay = vgui.Create( "DPanel", MinigameIntro.Panel )
		overlay:SetSize( ScrW(), ScrH() )
		overlay:Center()
		function overlay:Paint( w, h )
			if ( Transition.Active ) then
				if ( MinigameIntro.Panel and MinigameIntro.Panel:IsValid() ) then
					MinigameIntro.Panel:SetMouseInputEnabled( false )
				end
				Transition:Render()
			else
				if ( MinigameIntro.Panel and MinigameIntro.Panel:IsValid() ) then
					-- Wait for transition before showing cursor
					MinigameIntro.Panel:MakePopup()
					MinigameIntro.Panel:MoveToBack()
					MinigameIntro.Panel:SetKeyboardInputEnabled( false )
				end

				overlay:Remove()
				overlay = nil
			end
		end
	end

	-- TODO TEMP HOTRELOAD TESTING
	if ( MinigameIntro.Panel and MinigameIntro.Panel:IsValid() ) then
		MinigameIntro.Panel:Remove()
		MinigameIntro.Panel = nil
		MinigameIntro:CreateMinigameIntroUI( "Scary Game" )
		MinigameIntro.Panel:MakePopup()
		MinigameIntro.Panel:MoveToBack()
		MinigameIntro.Panel:SetKeyboardInputEnabled( false )
	end
	--MinigameIntro:CreateMinigameIntroUI( "Scary Game" )
	-- timer.Simple( 10, function()
	-- 	if ( MinigameIntro.Panel and MinigameIntro.Panel:IsValid() ) then
	-- 		MinigameIntro.Panel:Remove()
	-- 	end
	-- end )
end
