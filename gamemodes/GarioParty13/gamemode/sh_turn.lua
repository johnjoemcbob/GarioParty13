--
-- Gario Party 13
-- 02/07/20
--
-- Shared Turn System
--

local HOOK_PREFIX = HOOK_PREFIX .. "Turn_"

Turn = Turn or {}

TURN_ROLL		= 0
TURN_MOVE		= 1
TURN_CHOOSEDIR	= 2

TURN_INTRO_TIME	= 2
TURN_ASK_TIME	= 2

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_Turn"
local NETSTRING_REQUESTEND = HOOK_PREFIX .. "Net_Turn_RequestEnd"
local NETSTRING_ASKDIR = HOOK_PREFIX .. "Net_Turn_AskDirection"
local NETSTRING_ANSWERDIR = HOOK_PREFIX .. "Net_Turn_AnswerDirection"
local NET_INT = 4
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_REQUESTEND )
	util.AddNetworkString( NETSTRING_ASKDIR )
	util.AddNetworkString( NETSTRING_ANSWERDIR )

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

	function Turn:AskDirection( ply )
		-- Communicate to current player turn
		net.Start( NETSTRING_ASKDIR )
		net.Send( ply )

		if ( ply:IsBot() ) then
			local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
			local dir = math.random( 1, #Board.Data[space.x][space.y].Connections )
			Turn:PickDir( dir )
		end
	end

	net.Receive( NETSTRING_ANSWERDIR, function( lngth, ply )
		local dir = net.ReadInt( NET_INT )

		if ( Turn.State == TURN_CHOOSEDIR and ( ply == Turn.Current or Turn.Current:IsBot() ) ) then
			Turn:PickDir( dir )
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

	net.Receive( NETSTRING_ASKDIR, function( lngth )
		LocalPlayer().AskDir = true
		Turn.AskTime = CurTime()
	end )

	function Turn:AnswerDirection( dir )
		if ( LocalPlayer().AskDir ) then
			-- Communicate to server
			net.Start( NETSTRING_ANSWERDIR )
				net.WriteInt( dir, NET_INT )
			net.SendToServer()

			LocalPlayer().AskDir = nil
		end
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

	-- TODO start [PLAYER TURN] intro animation
	self.StartTime = CurTime()

	self.State = TURN_ROLL
	Dice:Roll( self.Current )
end

-- Called from board game state
function Turn:Think()
	local ply = self.Current

	local next = true
	if ( SERVER ) then
		if ( self.State == TURN_MOVE ) then
			-- Move forwards one space at a time for each dice value
			if ( !Board.MoveStart or Board.MoveStart + BOARD_MOVETIME <= CurTime() ) then
				if ( Dice.Result > 0 ) then
				--if ( true ) then
					local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
					if ( #Board.Data[space.x][space.y].Connections == 1 ) then
						self:PickDir( 1 )
					else
						self.State = TURN_CHOOSEDIR
						self:AskDirection( self.Current )
					end
				else
					self.Finished = true
				end
			end
		end

		if ( self.Finished ) then
			-- Try to get next or finish current round if end
			next = self:Next()
		end
	end

	return next
end

function Turn:PickDir( dir )
	local ply = self.Current
	local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
	local target = Board.Data[space.x][space.y].Connections[dir]
	Board:BroadcastMove( ply, target )
	Dice.Result = Dice.Result - 1

	Turn.State = TURN_MOVE
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
	hook.Add( "KeyPress", HOOK_PREFIX .. "KeyPress", function( ply, key )
		if ( LocalPlayer().AskDir ) then
			if ( key == IN_MOVELEFT ) then
				Turn:AnswerDirection( 1 )
			elseif ( key == IN_MOVERIGHT ) then
				Turn:AnswerDirection( 2 )
			end
		end
	end )

	hook.Add( "HUDPaint", HOOK_PREFIX .. "HUDPaint", function()
		-- Turn intro
		if ( Turn:IsSystemActive() ) then
			local progress = ( CurTime() - Turn.StartTime ) / TURN_INTRO_TIME
			if ( progress >= 0 and progress <= 1 ) then
				local center = Vector( ScrW() / 2, ScrH() / 8, ScrW() )
				local xoff = ScrW() / 2
				local heightoff = 0-- ScrH() / 4
				local poses = {
					[0] = center + Vector( -xoff, heightoff, -ScrW() ),
					[0.1] = center,
					--[0.5] = center + Vector( 0, math.sin( CurTime() * 5 ) * 8 ),
					[0.9] = center,
					[1] = center + Vector( xoff, -heightoff, -ScrW() ),
				}
				local pos = AnimateVectorBetween( progress, poses )

				surface.SetDrawColor( COLOUR_WHITE )
				surface.DrawTexturedRectRotated( pos.x, pos.y, pos.z, 64, 1 )
				local text = tostring( Turn:Get() ) .. "'s turn!"
				local font = "DermaLarge"
				draw.SimpleText( text, font, pos.x, pos.y, COLOUR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			--else
			---- TODO temp testing
			--	Turn.StartTime = CurTime()
			end
		end

		-- Ask direction
		if ( Turn.AskTime ) then
			local progress = ( CurTime() - Turn.AskTime ) / TURN_ASK_TIME
				if ( LocalPlayer().AskDir ) then
					progress = 0.5
					Turn.AskTime = CurTime() - 0.9
				end
			if ( progress >= 0 and progress <= 1 ) then
				local center = Vector( ScrW() / 2, ScrH() / 8, ScrW() )
				local xoff = ScrW() / 2
				local heightoff = 0-- ScrH() / 4
				local poses = {
					[0] = center + Vector( -xoff, heightoff, -ScrW() ),
					[0.1] = center,
					--[0.5] = center + Vector( 0, math.sin( CurTime() * 5 ) * 8 ),
					[0.9] = center,
					[1] = center + Vector( xoff, -heightoff, -ScrW() ),
				}
				local pos = AnimateVectorBetween( progress, poses )

				surface.SetDrawColor( COLOUR_WHITE )
				surface.DrawTexturedRectRotated( pos.x, pos.y, pos.z, 64, 1 )
				local text = "Which direction?"
				local font = "DermaLarge"
				draw.SimpleText( text, font, pos.x, pos.y, COLOUR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end
	end )
end

function AnimateVectorBetween( progress, anim )
	-- Find last value higher than this
	local current = GetClosestKeyframe( anim, progress )
	local target = GetClosestKeyframe( anim, progress, true )
	local range = target - current

	return LerpVector( ( progress - current ) / range, anim[current], anim[target] )
end
