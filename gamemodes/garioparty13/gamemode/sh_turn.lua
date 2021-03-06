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
TURN_SPECIAL	= 4

TURN_INTRO_TIME	= 2
TURN_ASK_TIME	= 2

-- Net
local NETSTRING = HOOK_PREFIX .. "Net_Turn"
local NETSTRING_REQUESTEND = HOOK_PREFIX .. "Net_Turn_RequestEnd"
local NETSTRING_ASKDIR = HOOK_PREFIX .. "Net_Turn_AskDirection"
local NETSTRING_ANSWERDIR = HOOK_PREFIX .. "Net_Turn_AnswerDirection"
local NET_INT = 4
local NET_INT_ROUND = 7
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )
	util.AddNetworkString( NETSTRING_REQUESTEND )
	util.AddNetworkString( NETSTRING_ASKDIR )
	util.AddNetworkString( NETSTRING_ANSWERDIR )

	function Turn:Broadcast( ply )
		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
			net.WriteInt( GAMEMODE.GameStates[STATE_BOARD].Round, NET_INT_ROUND )
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
		local round = net.ReadInt( NET_INT_ROUND )

		-- Sync current round for display on board HUD, and to help late joiners
		GAMEMODE.GameStates[STATE_BOARD].Round = round

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
	self.Players = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )

	if ( #self.Players == 0 ) then
		-- TODO Bad but running out of time
		timer.Simple( 0.5, function()
			self.Players = PlayerStates:GetPlayers( PLAYER_STATE_PLAY )
			-- Start the first player's turn
			self:Switch( self.Players[1] )
		end )
	else
		-- Start the first player's turn
		self:Switch( self.Players[1] )
	end
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
		if ( !self.Current or !self.Current:IsValid() ) then
			-- Handle players leaving on their turn
			self.Finished = true
		end

		if ( !self.Finished and self.State == TURN_MOVE ) then
			-- Move forwards one space at a time for each dice value
			if ( !Board.MoveStart or Board.MoveStart + BOARD_MOVETIME <= CurTime() ) then
				if ( Dice.Result and Dice.Result > 0 ) then
					local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
					local shouldmove = true
						if ( self.CurrentMoves != 0 ) then
							shouldmove = Board:OnPassSpace( Board.Data[space.x][space.y] )
						end
					if ( shouldmove ) then
						if ( #Board.Data[space.x][space.y].Connections == 1 ) then
							self:PickDir( 1 )
						else
							self.State = TURN_CHOOSEDIR
							self:AskDirection( self.Current )
						end
					end
				else
					self.DiceRemaining = self.DiceRemaining - 1
					if ( self.DiceRemaining <= 0 ) then
						self.State = TURN_LAND

						-- React to space landed on
						Turn:LandOnSpace()
						local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
						local shouldend = Board:OnLandSpace( Board.Data[space.x][space.y] )

						-- End turn timer
						if ( shouldend ) then
							timer.Simple( 1, function()
								self.Finished = true
							end )
						end
					else
						self.State = TURN_ROLL
						Dice:Roll( self.Current )
					end
				end
			end
		else
			self.CurrentMoves = 0
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

	self.State = TURN_MOVE
	self.CurrentMoves = self.CurrentMoves + 1
end

function Turn:LandOnSpace()
	local ply = self.Current
	local space = ply:GetNWVector( "BoardPos", Vector( 1, 1 ) )
	local type = Board:GetSpace( space ).Type

	if ( ply and ply:IsValid() ) then
		if ( type == SPACE_TYPE_DEFAULT ) then
			-- Add props
			ply:AddScore( SCORE_SPACE_ADD )
		elseif ( type == SPACE_TYPE_NEGATIVE ) then
			-- Remove props
			ply:AddScore( SCORE_SPACE_REMOVE )
		elseif ( type == SPACE_TYPE_INVEST ) then
			-- Logic is in sh_board, this should be refactored to all be there!
		else
			print( "Warning: Unregistered space type in sh_turn: ", type )
		end
	end
end

function Turn:Finish()
	Board.Moves = 0
end

function Turn:Next()
	local index = table.indexOf( self.Players, self.Current ) + 1
	if ( index > 0 and index <= #self.Players ) then
		local success = self:Switch( self.Players[index] )
		if ( success ) then
			return true
		end
	end
	return false
end

function Turn:Switch( ply, juststarted )
	if ( !ply or !ply:IsValid() ) then
		-- Handle player leaving early
		table.RemoveByValue( self.Players, ply )
		Turn:Next()
		return false
	end
	if ( !juststarted ) then
		self:Finish()
	end
	self:Set( ply )
	self:Start()

	if ( SERVER ) then
		self:Broadcast( ply )
	end

	return true
end

function Turn:Set( ply )
	self.Current = ply
end

function Turn:Get()
	if ( !self.Current or !self.Current:IsValid() ) then
		local next = Turn:Next()
		if ( next ) then
			return self:Get()
		else
			return nil
		end
	end
	return self.Current
end

function Turn:IsSystemActive()
	return GAMEMODE:GetStateName() == STATE_BOARD
end

hook.Add( "PlayerDisconnected", HOOK_PREFIX .. "PlayerDisconnected", function( ply )
	if ( Turn.Current == ply ) then
		Turn:Next()
	end
end )

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
		draw.NoTexture()

		-- Turn intro
		if ( Turn:IsSystemActive() and Turn:Get() ) then
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
				local text = Turn:Get():Nick() .. "'s turn!"
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
