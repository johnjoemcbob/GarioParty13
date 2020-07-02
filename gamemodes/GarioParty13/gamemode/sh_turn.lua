--
-- Gario Party 13
-- 02/07/20
--
-- Shared Turn System
--

local HOOK_PREFIX = HOOK_PREFIX .. "Turn_"

Turn = Turn or {}

TURN_ROLL = 0
TURN_MOVE = 1

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_Turn"
local NETSTRING_REQUESTEND = HOOK_PREFIX .. "Net_Turn_RequestEnd"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_REQUESTEND )

	function Turn:Broadcast( ply )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
		net.Broadcast()
	end

	net.Receive( NETSTRING_REQUESTEND, function( lngth, ply )
		if ( ply == Turn.Current or Turn.Current:IsBot() ) then
			Turn.Finished = true
		end
	end )
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()

		-- Start/Finish clientside
		Turn:Finish()
		Turn:Set( ply )
		Turn:Start()
	end )

	function Turn:RequestEnd()
		-- Communicate to server
		net.Start( NETSTRING_REQUESTEND )
		net.SendToServer()
	end
end

function Turn:Initialize()
	-- Cache the current players
	self.Players = player.GetAll()

	-- Start the first player's turn
	self:Switch( self.Players[1] )
end

function Turn:Start()
	self.Finished = false

	-- TODO start intro animation

	self.State = TURN_ROLL
	Dice:Roll( self.Current )
end

-- Called from board game state
function Turn:Think()
	local next = true
	if ( SERVER ) then
		if ( self.Finished ) then
			next = self:Next()
		end
	end

	return next
end

function Turn:Finish()

end

function Turn:Next()
	local index = table.indexOf( self.Players, self.Current ) + 1
	if ( index <= #self.Players ) then
		self:Switch( self.Players[index] )
		return true
	else
		return false
	end
end

function Turn:Switch( ply, juststarted )
	if ( !juststarted ) then
		self:Finish()
	end
	self:Set( ply )
	self:Start()

	if ( SERVER ) then
		self:Broadcast( ply )
	end
end

function Turn:Set( ply )
	self.Current = ply
end

function Turn:Get()
	return self.Current
end

function Turn:IsSystemActive()
	return GAMEMODE:GetStateName() == STATE_BOARD
end

if ( CLIENT ) then
	hook.Add( "HUDPaint", HOOK_PREFIX .. "HUDPaint", function()
		if ( Turn:IsSystemActive() ) then
			draw.SimpleText( tostring( Turn:Get() ) .. "'s turn!", "DermaDefault", 50, 200, COLOUR_WHITE )
		end
	end )
end
