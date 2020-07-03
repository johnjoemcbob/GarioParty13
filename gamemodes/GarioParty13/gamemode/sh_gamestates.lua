--
-- Gario Party 13
-- 28/06/20
--
-- Shared Game States
--

STATE_ERROR = "ERROR"

GM.GameStates = GM.GameStates or {}

-- Load all states, add to download (called at bottom)
function includeanddownload()
	local dir = "game_states/"
	local files = {
		"sh_gs_lobby",
		"sh_gs_board",
		"sh_gs_minigame",
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
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )

	function GM.BroadcastGameState( oldstate, newstate )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteString( oldstate )
			net.WriteString( newstate )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local oldstate = net.ReadString()
		local newstate = net.ReadString()

		-- Start/Finish clientside
		Transition:Start()
		if ( oldstate != STATE_ERROR ) then
			GAMEMODE.GameStates[oldstate]:OnFinish()
		end
		GAMEMODE:SetState( newstate )
		GAMEMODE.GameStates[newstate]:OnStart()
	end )
end

-- Set/Get/Switch
function GM:SetState( state )
	GAMEMODE.CurrentState = state
end

function GM:SwitchState( state )
	if ( SERVER ) then
		local self = GAMEMODE
		if ( self:GetStateName() == state ) then return end

		local oldstate = self:GetStateName()
		-- Delay to try and line up with client transition effect
		--timer.Simple( 0.5, function()
			if ( oldstate and oldstate != STATE_ERROR ) then
				self:GetState():OnFinish( self )
			end
			self:SetState( state )
			self:GetState():OnStart( self )
		--end )

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
hook.Add( "Initialize", HOOK_PREFIX .. "GameStates_Initialize", function()
	GAMEMODE:SetState( STATE_ERROR )
	GAMEMODE:SwitchState( STATE_LOBBY )
end )
hook.Add( "Think", HOOK_PREFIX .. "GameStates_Think", function()
	--print( GAMEMODE.GetStateName() )
	if ( GAMEMODE:GetStateName() != STATE_ERROR ) then
		GAMEMODE:GetState():OnThink()
	end
end )

-- Show current state on HUD
if ( CLIENT ) then
	hook.Add( "HUDPaint", HOOK_PREFIX .. "GameStates_HUDPaint", function()
		draw.SimpleText( GAMEMODE:GetStateName(), "DermaDefault", 50, 120, COLOUR_WHITE )
	end )
end

-- Last, after necessary functions are defined
includeanddownload()
