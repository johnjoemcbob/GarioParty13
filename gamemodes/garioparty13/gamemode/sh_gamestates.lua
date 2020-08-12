--
-- Gario Party 13
-- 28/06/20
--
-- Shared Game States
--

STATE_ERROR = "ERROR"

local HOOK_PREFIX = HOOK_PREFIX .. "GameStates_"

GM.GameStates = GM.GameStates or {}

-- Load all states, add to download (called at bottom)
function includeanddownload()
	local dir = "game_states/"
	local files = {
		"sh_gs_lobby",
		"sh_gs_modeselect",
		"sh_gs_minigame_select",
		"sh_gs_board",
		"sh_gs_minigame",
		"sh_gs_minigame_intro",
		"sh_gs_minigame_outro",
		"sh_gs_win",
	}
	for k, file in pairs( files ) do
		local path = dir .. file .. ".lua"
		if ( SERVER ) then
			AddCSLuaFile( path )
		end
		include( path )
	end
end

-- Define add state function
function GM.AddGameState( name, data )
	GM.GameStates[name] = data
end

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_GameState"
local NETSTRING_REQUEST = HOOK_PREFIX .. "Net_GameState_Request"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_REQUEST )

	function GM.BroadcastGameState( oldstate, newstate )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteString( oldstate )
			net.WriteString( newstate )
		net.Broadcast()
	end

	function GM.SendGameState( ply, newstate )
		-- Communicate to specific client (late joiner normally)
		net.Start( NETSTRING )
			net.WriteString( STATE_ERROR )
			net.WriteString( newstate )
		net.Send( ply )
	end

	net.Receive( NETSTRING_REQUEST, function( lngth, ply )
		local state = net.ReadString()

		-- Ask current state if this player can change
		local cur = GAMEMODE:GetState()
		if ( cur.OnRequestStateChange ) then
			cur:OnRequestStateChange( ply, state )
		end
	end )
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local oldstate = net.ReadString()
		local newstate = net.ReadString()

		-- Start/Finish clientside
		Transition:Start()
			if ( oldstate == STATE_ERROR ) then
				Transition:Start( 1 )
			end
		if ( ( oldstate != STATE_ERROR ) and GAMEMODE.GameStates[oldstate].OnTransitionAway ) then
			GAMEMODE.GameStates[oldstate]:OnTransitionAway()
		end
		timer.Simple( TRANSITION_DURATION, function()
			if ( oldstate != STATE_ERROR ) then
				GAMEMODE.GameStates[oldstate]:OnFinish()
			end
			GAMEMODE:SetState( newstate )
			GAMEMODE.GameStates[newstate]:OnStart()
		end )

		Scoreboard:Hide()
	end )

	function GM.RequestGameState( state )
		-- Communicate to all clients
		net.Start( NETSTRING_REQUEST )
			net.WriteString( state )
		net.SendToServer()
	end
end

-- Set/Get/Switch
function GM:SetState( state )
	GAMEMODE.CurrentState = state
end

function GM:SwitchState( state )
	if ( SERVER ) then
		local self = GAMEMODE
		if ( self:GetStateName() == state ) then return end
		if ( self.Transitioning ) then return end

		local oldstate = self:GetStateName()
		-- Delay to try and line up with client transition effect
		self.Transitioning = true
		timer.Simple( TRANSITION_DURATION, function()
			if ( oldstate and oldstate != STATE_ERROR ) then
				self:GetState():OnFinish( self )
			end
			self:SetState( state )
			self:GetState():OnStart( self )
			self.Transitioning = false
		end )

		self.BroadcastGameState( oldstate, state )
	end
end

function GM:GetState()
	return GAMEMODE.GameStates[GAMEMODE:GetStateName()]
end

function GM:GetStateName()
	return GAMEMODE.CurrentState
end

-- Gamemode hooks
hook.Add( "Initialize", HOOK_PREFIX .. "Initialize", function()
	GAMEMODE:SetState( STATE_ERROR )
	GAMEMODE:SwitchState( STATE_LOBBY )

	if ( CLIENT ) then
		Transition:Start( 3 )
		Transition:Update()
	end
end )
hook.Add( "Think", HOOK_PREFIX .. "Think", function()
	--print( GAMEMODE.GetStateName() )
	if ( GAMEMODE:GetStateName() != STATE_ERROR ) then
		GAMEMODE:GetState():OnThink()
	end
end )
if ( SERVER ) then
	hook.Add( "PlayerInitialSpawn", HOOK_PREFIX .. "PlayerInitialSpawn", function( ply )
		GAMEMODE.SendGameState( ply, GAMEMODE.CurrentState )
	end )
end

-- Show current state on HUD
-- if ( CLIENT ) then
-- 	hook.Add( "HUDPaint", HOOK_PREFIX .. "HUDPaint", function()
-- 		draw.SimpleText( GAMEMODE:GetStateName(), "DermaDefault", 50, 120, COLOUR_WHITE )
-- 	end )
-- end

-- Last, after necessary functions are defined
includeanddownload()
