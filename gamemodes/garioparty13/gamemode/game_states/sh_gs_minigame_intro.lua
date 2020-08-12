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
local MARGIN = 0 -- Set in panel creation

-- Resources
if ( SERVER ) then
	resource.AddFile( "materials/hearts.png" )
end
if ( CLIENT ) then
	MAT_HEARTS = Material( "hearts.png", "noclamp smooth" )
end

local game_pool = {}
GM.AddGameState( STATE_MINIGAME_INTRO, {
	OnStart = function( self )
		-- Find a random minigame
		if ( SERVER ) then
			if ( GAMEMODE.Campaign ) then
				if ( #game_pool == 0 ) then
					game_pool = {}
					for name, game in pairs( GAMEMODE.Games ) do
						if ( game.Playable and !game.UnderConstruction ) then
							table.insert( game_pool, name )
						end
					end
				end
				local ind = math.random( 1, #game_pool )
				self.Minigame = game_pool[ind]
					local forced = false
					local next = CONVAR_MINIGAME_FORCE_NEXT:GetString()
					local all = CONVAR_MINIGAME_FORCE_ALL:GetString()
					if ( next != " " ) then
						self.Minigame = next
						CONVAR_MINIGAME_FORCE_NEXT:SetString( " " )
					elseif ( all != " " ) then
						self.Minigame = all
					end
				if ( !forced ) then
					table.remove( game_pool, ind )
				end
			end
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
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			MinigameIntro:SetReady( ply, READY_NONE )

			-- Bot testing
			if ( ply:IsBot() ) then
				timer.Simple( 0.5 + 0.5 * k, function()
					MinigameIntro:MoveReady( ply, 1 )
				end )
			end
		end

		-- Create UI
		-- Now moved to on receival of BroadcastMinigame ^
		-- if ( CLIENT ) then
		-- 	MinigameIntro:CreateMinigameIntroUI( self.Minigame )
		-- end
	end,
	OnThink = function( self )
		if ( CLIENT ) then
			if ( Transition.Active ) then
				MinigameIntro:CreateMinigameIntroUIOverlay()
			end
		end
	end,
	OnTransitionAway = function( self )
		-- Client only
		MinigameIntro:ZoomOnGIF()
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
local NETSTRING_MINIGAME_LATE = HOOK_PREFIX .. "Net_Minigame_Late"
local NETSTRING_WAITING_CUSTOM = HOOK_PREFIX .. "Net_Waiting"
local NETSTRING_WAITING_BROADCAST = HOOK_PREFIX .. "Net_Waiting_Broadcast"
local NET_INT = 3
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_MINIGAME )
	util.AddNetworkString( NETSTRING_MINIGAME_LATE )
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

	function MinigameIntro:SendLateMinigame( ply, minigame, ui )
		-- Communicate to late joiner
		net.Start( NETSTRING_MINIGAME_LATE )
			net.WriteString( minigame )
			net.WriteBool( ui )
		net.Send( ply )
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
		GAMEMODE.GameStates[STATE_MINIGAME].Minigame = minigame
		MinigameIntro:CreateMinigameIntroUI( minigame )
	end )

	net.Receive( NETSTRING_MINIGAME_LATE, function( lngth )
		local minigame = net.ReadString()
		local ui = net.ReadBool()

		GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame = minigame
		GAMEMODE.GameStates[STATE_MINIGAME].Minigame = minigame
		if ( ui ) then
			MinigameIntro:CreateMinigameIntroUI( minigame )
		end

		print( "Receive late minigame! " .. minigame )
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
		if ( !old ) then return end -- Spectator
		--self:SetReady( ply, math.Clamp( old + dir, READY_NONE, READY_PRACTICE ) )
		self:SetReady( ply, math.Clamp( old + dir, READY_NONE, READY_REAL ) )

		-- Voting
		local start = true
			for k, v in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
				if ( self.Ready[v] != READY_REAL ) then
					start = false
					break
				end
			end
		if ( start ) then
			-- CLIENT gets the STATE_MINIGAME.Minigame in NET broadcast above
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

-- Gamemode hooks
hook.Add( "PlayerInitialSpawn", HOOK_PREFIX .. "PlayerInitialSpawn", function( ply )
	-- Has played a minigame or is at intro, send server value to sync
	if ( GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame ) then
		MinigameIntro:SendLateMinigame( ply, GAMEMODE.GameStates[STATE_MINIGAME_INTRO].Minigame )
	end
end )

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
	function MinigameIntro:ZoomOnGIF()
		-- local time = 0.3
		-- local delay = 0
		-- local ease = -10
		-- self.GIF:MoveTo( -ScrW() / 8, -ScrH() / 8, time, delay, ease )
		-- self.GIF:SizeTo( ScrW(), ScrW(), time, delay, ease )
	end
	
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
		local bufferwidth = ScrW() / 16
		local leftwidth = ScrW() / 2.2
		local rightwidth = ScrW() - leftwidth - bufferwidth * 2
		local height = ScrH()
		local between = 0-- ScrH() / 48
		MARGIN = ScrW() / 64

		-- Fullscreen panel
		MinigameIntro.Panel = vgui.Create( "DPanel" )
		MinigameIntro.Panel:SetSize( ScrW(), ScrH() )
		MinigameIntro.Panel:Center()
			MinigameIntro.Panel.Colour = GetRandomColour()
			MinigameIntro.Panel.Highlight = GetColourHighlight( MinigameIntro.Panel.Colour )
			MinigameIntro.Panel.Background = math.random( 1, #GAMEMODE.Backgrounds )
			GAMEMODE.Backgrounds[MinigameIntro.Panel.Background].Init( MinigameIntro.Panel )
		function MinigameIntro.Panel:Paint( w, h )
			-- Draw background blue
			draw.NoTexture()
			surface.SetDrawColor( self.Colour )
			surface.DrawRect( 0, 0, w, h )

			-- Draw background
			GAMEMODE.Backgrounds[self.Background].Render( self, w, h )
		end

		local buffer = vgui.Create( "DPanel", MinigameIntro.Panel )
		buffer:SetSize( bufferwidth, height )
		buffer:Dock( LEFT )
		function buffer:Paint( w, h ) end

		-- Left
		local left = vgui.Create( "DPanel", MinigameIntro.Panel )
		left:SetSize( leftwidth, height )
		left:Dock( LEFT )
		function left:Paint( w, h )
			-- Draw foreground white
			surface.SetDrawColor( COLOUR_WHITE )
			surface.DrawRect( 0, 0, w, h )
		end

		-- Minigame title
		local text = minigame
		local font = "MinigameTitle"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local y = ScrH() / 18 - theight / 2
		local width = leftwidth * 1.3
		local label = vgui.Create( "DLabel", left )
		label:SetPos( leftwidth / 2 - twidth / 2, y )
		label:SetSize( width, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )
		y = y + theight + between
		--label:Dock( TOP )

		-- Video HTML panel
		local videowidth = leftwidth * 1.1
		local width = videowidth * 1.1
		local html = vgui.Create( "DHTML", MinigameIntro.Panel )
		html:SetSize( width, width )
		html:SetPos( leftwidth * 0.1 * 0.65, y )
		html:SetHTML( [[
			<img style="text-align: center" src="]] .. GAMEMODE.Games[minigame].GIF .. [[" width="95%">
		]] )
		MinigameIntro.GIF = HTML
		y = y + width * 0.72

		-- Tag line
		local text = GAMEMODE.Games[minigame].TagLine
		local font = "ScoreboardDefault"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", left )
		label:SetPos( leftwidth / 2 - twidth / 2, y )
		label:SetSize( twidth, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_DARK )
		y = y + theight

		-- Minigame intructions
		local text = GAMEMODE.Games[minigame].Instructions
		local font = "CloseCaption_Normal"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
		local label = vgui.Create( "DLabel", left )
		label:SetPos( MARGIN, y )
		label:SetSize( leftwidth - MARGIN * 2, theight )
		label:SetFont( font )
		label:SetText( text )
		label:SetTextColor( COLOUR_UI_TEXT_MED )

		local buffer = vgui.Create( "DPanel", MinigameIntro.Panel )
		buffer:SetSize( bufferwidth, height )
		buffer:Dock( LEFT )
		function buffer:Paint( w, h ) end

		-- Right
		local right = vgui.Create( "DPanel", MinigameIntro.Panel )
		right:SetSize( rightwidth, height )
		right:Dock( LEFT )
		function right:Paint( w, h ) end
		MinigameIntro.Panel.Right = right

		-- Minigame controls
		local text = GAMEMODE.Games[minigame].Controls
		local font = "CloseCaption_Normal"
			surface.SetFont( font )
			local twidth, theight = surface.GetTextSize( text )
			twidth = 128
		local label = vgui.Create( "DLabel", right )
		label:SetPos( 0, ScrH() / 7 )
		label:SetFont( font )
		label:SetText( text )
		label:SizeToContents()
		label:SetTextColor( COLOUR_UI_TEXT_LIGHT )
		function label:Paint( w, h )
			surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
			surface.DrawRect( 0, 0, w, h )
		end

		-- Minigame specific UI
		if ( GAMEMODE.Games[minigame].CreateWaitingUI ) then
			local w, h = rightwidth, ScrH() / 3
			local panel = vgui.Create( "DPanel", right )
			panel:SetSize( w, h )
			panel:SetPos( 0, ScrH() / 3 )
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
		local xs = {
			rightwidth / 4 * 1,
			rightwidth / 4 * 3,
		}
		MinigameIntro:CreateMinigameIntroUILabel( "Not Ready", font, xs[1] - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		MinigameIntro:CreateMinigameIntroUILabel( "Ready", font, xs[2] - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		--MinigameIntro:CreateMinigameIntroUILabel( "_VOTE_", font, rightx + rightwidth / 3 / 1.7 - twidth / 2, y - 32, COLOUR_UI_TEXT_LIGHT )
		--MinigameIntro:CreateMinigameIntroUILabel( "Play for Real", font, rightx - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )
		--MinigameIntro:CreateMinigameIntroUILabel( "Practice", font, rightx + rightwidth / 3 - twidth / 2, y, COLOUR_UI_TEXT_LIGHT )

		-- Test player icon
		for k, ply in pairs( PlayerStates:GetPlayers( PLAYER_STATE_PLAY ) ) do
			if ( ply and ply:IsValid() ) then
				local model = ply:GetModel()
					if ( model == "models/player.mdl" ) then
						model = "models/player/kleiner.mdl" -- Weird error woops
					end
				local icon = vgui.Create( "DModelPanel", right )
				--icon:SetSize( 200, 200 )
				--icon:SetPos( rightx - twidth / 2, y + 64 )
				icon:SetModel( model )
				icon:SetTooltip( ply:Nick() )
				icon.Size = 64
				function icon:LayoutEntity( Entity ) return end	-- Disable cam rotation
				local headpos = icon.Entity:GetBonePosition(icon.Entity:LookupBone("ValveBiped.Bip01_Head1"))
					icon:SetLookAt(headpos)
				local campos = headpos-Vector(-40, 0, -10)
					icon:SetCamPos( campos )
					icon.Entity:SetEyeTarget( campos )
					icon.Player = ply
				function icon:Think()
					if ( !MinigameIntro.Ready ) then return end
					if ( !self.Player or !self.Player:IsValid() ) then self:Remove() return end

					local ready = MinigameIntro.Ready[ply]
					if ( !ready or !MinigameIntro.Columns[ready] ) then return end -- Late joiner fix

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
						x[0] = xs[1]
						x[1] = xs[2]
						--x[2] = rightwidth / 3
					local target = Vector( x[ready] - twidth / 2 + offset.x, y + 32 + offset.y )
					icon.Pos = icon.Pos or target
					icon.Pos = ApproachVector( FrameTime() * LERPSPEED, icon.Pos, target )
					icon:SetPos( icon.Pos.x, icon.Pos.y )

					icon.Size = math.Approach( icon.Size, size, FrameTime() * LERPSIZESPEED )
					icon:SetSize( icon.Size, icon.Size )
				end
			end
		end

		MinigameIntro:CreateMinigameIntroUIOverlay()
	end

	function MinigameIntro:CreateMinigameIntroUILabel( text, font, x, y, colour )
		surface.SetFont( font )
		local twidth, theight = surface.GetTextSize( text )

		local label = vgui.Create( "DLabel", MinigameIntro.Panel.Right )
			label:SetPos( x, y )
			label:SetSize( twidth, theight )
			label:SetFont( font )
			label:SetText( text )
			label:SetTextColor( colour )
			function label:Paint( w, h )
				surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
				surface.DrawRect( 0, 0, w, h )
			end
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
