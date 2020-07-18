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
TURN_LAND		= 3

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
		local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )

		-- Communicate to current player turn
		net.Start( NETSTRING_ASKDIR )
			net.WriteTable( Board.Data[space.x][space.y].Connections )
		net.Send( ply )

		if ( ply:IsBot() ) then
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
		local cons = net.ReadTable()

		LocalPlayer().AskDir = cons
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

	self.StartTime = CurTime()

	self.State = TURN_ROLL
	self.DiceRemaining = 1
	Dice:Roll( self.Current )

	if ( SERVER ) then
		if ( self.Current:IsBot() ) then
			timer.Simple( 0.5, function()
				Dice:Hit()
			end )
		end
	end

	-- Override for round 1 to walk on board and then roll dice
	if ( GAMEMODE.GameStates[STATE_BOARD].Round == 1 ) then
	-- 	self.DiceRemaining = 2
	-- 	if ( SERVER ) then
	-- 		Dice:Hit( 1 )
	-- 		Turn.State = TURN_MOVE
	-- 		Board.MoveStart = CurTime()
	-- 	end
	end
end

-- Called from board game state
function Turn:Think()
	local ply = self.Current

	local next = true
	if ( SERVER ) then
		if ( !self.Finished and self.State == TURN_MOVE ) then
			-- Move forwards one space at a time for each dice value
			if ( !Board.MoveStart or Board.MoveStart + BOARD_MOVETIME <= CurTime() ) then
				if ( Dice.Result and Dice.Result > 0 ) then
					local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
					if ( #Board.Data[space.x][space.y].Connections == 1 ) then
						self:PickDir( 1 )
					else
						self.State = TURN_CHOOSEDIR
						self:AskDirection( self.Current )
					end
				else
					self.DiceRemaining = self.DiceRemaining - 1
					if ( self.DiceRemaining <= 0 ) then
						self.State = TURN_LAND

						-- React to space landed on
						Turn:LandOnSpace()

						-- End turn timer
						timer.Simple( 1, function()
							self.Finished = true
						end )
					else
						self.State = TURN_ROLL
						Dice:Roll( self.Current )
					end
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
	Dice.Result = Dice.Result - 1
	Board:BroadcastMove( ply, target, Dice.Result )

	Turn.State = TURN_MOVE
end

function Turn:LandOnSpace()
	local ply = self.Current
	local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
	local type = Board:GetSpace( space ).Type

	if ( type == SPACE_TYPE_DEFAULT ) then
		-- Add props
		ply:AddScore( SCORE_SPACE_ADD )
	elseif ( type == SPACE_TYPE_NEGATIVE ) then
		-- Remove props
		ply:AddScore( SCORE_SPACE_REMOVE )
	else
		print( "Warning: Unregistered space type: ", type )
	end
end

function Turn:Finish()
	Board.Moves = 0
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
				surface.DrawTexturedRectRotated( pos.x, pos.y, pos.z, 96, 1 )
				local text = tostring( Turn:Get() ) .. "'s turn!"
				local font = "DermaLarge"
				draw.SimpleText( text, font, pos.x, pos.y - 12, COLOUR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

				local text = "Jump to hit the dice!"
				draw.SimpleText( text, font, pos.x, pos.y + 24, COLOUR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
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

			-- Show connection keys on screen
			if ( LocalPlayer().AskDir ) then
				local strs = {
					"A",
					"D",
				}
				for k, con in pairs( LocalPlayer().AskDir ) do
					if ( k <= 2 ) then -- TODO TEMP REMOVE
						local pos = ( Vector( con.y, con.x ) * GP13_BOARD_SCALE ):ToScreen()
						local x, y = pos.x, pos.y
						local text = strs[k]
						local font = "DermaLarge"
						surface.SetDrawColor( COLOUR_WHITE )
						surface.DrawTexturedRectRotated( x, y, 32, 32, 1 )
						draw.SimpleText( text, font, x, y, COLOUR_BLACK, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
					end
				end
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
