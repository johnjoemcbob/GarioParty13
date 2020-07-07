--
-- Gario Party 13
-- 30/06/20
--
-- Shared Board
--

local HOOK_PREFIX = HOOK_PREFIX .. "Board_"

GP13_BOARD_SCALE		= 100
GP13_BOARD_POS			= Vector( 0, 0, 0 )
GP13_BOARD_SPACE_MODEL	= "models/hunter/blocks/cube1x1x025.mdl"

BOARD_MOVETIME 	= 1

SPACE_TYPE_DEFAULT	= 0
SPACE_TYPE_NEGATIVE	= 1

Board = Board or {}
local function setupboard()
	Board.Data = {}
	Board:AddSpace( 1, 1, SPACE_TYPE_DEFAULT, { Vector( 2, 2 ) } )
	Board:AddSpace( 2, 2, SPACE_TYPE_DEFAULT, { Vector( 2, 3 ) } )
	Board:AddSpace( 2, 3, SPACE_TYPE_DEFAULT, { Vector( 2, 4 ), Vector( 0, 3 ) } )
	Board:AddSpace( 2, 4, SPACE_TYPE_DEFAULT, { Vector( 1, 1 ) } )
	Board:AddSpace( 0, 3, SPACE_TYPE_DEFAULT, { Vector( 1, 1 ) } )
end

-- Connections are one way by default
function Board:AddSpace( x, y, type, connections )
	Board.Data = Board.Data or {}
	Board.Data[x] = Board.Data[x] or {}
	Board.Data[x][y] = {}
	Board.Data[x][y].Type = type
	Board.Data[x][y].Connections = connections
	Board.Data[x][y].CurrentPlayers = {}
		for k, ply in pairs( player.GetAll() ) do
			if ( ply:GetNWVector( "BoardPos", Vector( 1 , 1 ) ) == Vector( x, y ) ) then
				table.insert( Board.Data[x][y].CurrentPlayers, ply )
			end
		end
end

local layouts = {
	[1] = {
		{ Vector( 0, 0 ) },
	},
	[4] = {
		{ Vector( -1, -1 ) },
		{ Vector( 1, -1 ) },
		{ Vector( -1, 1 ) },
		{ Vector( 1, 1 ) },
	},
	[9] = {
		{ Vector( 0, 0 ) },
		{ Vector( 1, 0 ) },
		{ Vector( 0, -1 ) },
		{ Vector( 0, 1 ) },
		{ Vector( -1, -1 ) },
		{ Vector( 1, -1 ) },
		{ Vector( -1, 1 ) },
		{ Vector( 1, 1 ) },
		{ Vector( -1, 0 ) },
	},
}

-- Net
local NETSTRING = HOOK_PREFIX .. "Net"
if ( SERVER ) then
	util.AddNetworkString( NETSTRING )

	function Board:BroadcastMove( ply, pos )
		ply:SetNWVector( "BoardPos", pos )
		self.MoveStart = CurTime()

		-- Communicate to all clients
		net.Start( NETSTRING )
			net.WriteEntity( ply )
			net.WriteVector( pos )
		net.Broadcast()
	end
end
if ( CLIENT ) then
	net.Receive( NETSTRING, function( lngth )
		local ply = net.ReadEntity()
		local pos = net.ReadVector()

		Dice.Current = nil
		Turn.State = TURN_MOVE
		Board:Move( ply, pos )
	end )
end

if ( CLIENT ) then
	hook.Add( "Tick", HOOK_PREFIX .. "Tick", function()
		for k, ply in pairs( player.GetAll() ) do
			-- Hit dice input
			if ( ply == Turn.Current and LocalPlayer():KeyDown( IN_USE ) ) then
				if ( Dice.Current ) then
					Dice:RequestHit()
				end
			end

			-- Create player avatar
			if ( !ply.BoardModel or !ply.BoardModel:IsValid() ) then
				local pos = GP13_BOARD_POS
				local ang = Angle( 0, 0, 0 )
				ply.BoardModel = GAMEMODE.AddAnim( "models/eli.mdl", "run_all", pos, ang, 1 )
			end

			-- Target position and angle
			local pos, ang

			-- Move
			if ( ply.BoardFromPos != ply.BoardTargetPos ) then
				-- Time progress
				local progress = math.Clamp( ( CurTime() - Board.MoveStart ) / BOARD_MOVETIME, 0, 1 )
				if ( progress == 1 ) then
					ply.BoardFromPos = ply.BoardTargetPos
				end

				pos = ply.BoardFromExact
				local targetpos = Board:GetTargetPos( ply )
				pos = LerpVector( progress, pos, targetpos )
				ang = ( targetpos - pos ):Angle()

				-- Loop run animation
				if ( ply.BoardModel.NextPlay <= CurTime() ) then
					ply.BoardModel:ResetSequence( ply.BoardModel.MyAnim )
					ply.BoardModel.Delay = ply.BoardModel:SequenceDuration()
					ply.BoardModel.NextPlay = CurTime() + ply.BoardModel.Delay
				end
			else
				if ( ply.BoardModel.NextPlay <= CurTime() ) then
					-- Loop idle animation
					ply.BoardModel:ResetSequence( "idle01" )
					--ply.BoardModel:ResetSequence( "man_gun" )
					ply.BoardModel.Delay = ply.BoardModel:SequenceDuration()
					ply.BoardModel.NextPlay = CurTime() + ply.BoardModel.Delay
				end

				-- Still lerp in case needs to get out of way of moving player
				pos = ply.BoardModel:GetPos()
				local targetpos = Board:GetTargetPos( ply )
				pos = LerpVector( FrameTime() * 5, pos, targetpos )

				-- Face camera
				ang = Angle( 0, 180, 0 )
			end

			-- Update transform
			ply.BoardModel:SetPos( pos )
			ply.BoardModel:SetAngles( ang )

			-- Animate
			ply.BoardModel:FrameAdvance()
		end
	end )

	function Board:GetTargetPos( ply )
		if ( !ply.BoardTargetPos ) then
			--ply.BoardTargetPos = Vector( 1, 1 )
			Board:Move( ply, Vector( 1, 1 ) )
		end

		local target = ply.BoardTargetPos
			local count = #self.Data[target.x][target.y].CurrentPlayers
			local index = table.indexOf( self.Data[target.x][target.y].CurrentPlayers, ply )
		local offset = Vector( 0, 0 )
			if ( index != -1 ) then
				local layout
					-- Find closest layout
					local min = -1
					for int, lay in pairs( layouts ) do
						if ( count <= int and ( min == -1 or int < min ) ) then
							min = int
						end
					end
					if ( min == -1 ) then
						min = 1
					end
					layout = layouts[min]
				offset = layout[index][1]
			end
		return ( GP13_BOARD_POS + target * GP13_BOARD_SCALE + offset * 32 )
	end

	function Board:Move( ply, pos )
		-- Unregister from old space
		if ( ply.BoardTargetPos ) then
			table.RemoveByValue( self.Data[ply.BoardTargetPos.x][ply.BoardTargetPos.y].CurrentPlayers, ply )
		end

		-- Start move
		self.MoveStart = CurTime()
		ply.BoardFromPos = ply.BoardTargetPos or Vector( 1, 1 )
		ply.BoardFromExact = ply.BoardModel:GetPos()
		ply.BoardTargetPos = pos

		-- Register to new space
		table.insert( self.Data[ply.BoardTargetPos.x][ply.BoardTargetPos.y].CurrentPlayers, ply )
	end

	function Board:Render()
		for x, ys in pairs( Board.Data ) do
			for y, space in pairs( ys ) do
				local pos = GP13_BOARD_POS + Vector( x, y ) * GP13_BOARD_SCALE
				local ang = Angle( 0, 0, 0 )
				local sca = Vector( 1, 1, 1 )
				local mat = nil
				local col = COLOUR_WHITE

				for k, conn in pairs( space.Connections ) do
					local endpos = GP13_BOARD_POS + Vector( conn.x, conn.y ) * GP13_BOARD_SCALE
					render.DrawLine( pos, endpos, Color( 255, 255, 0, 255 ) )
				end

				GAMEMODE.RenderCachedModel(
					GP13_BOARD_SPACE_MODEL,
					pos, ang, sca,
					mat, col
				)
			end
		end

		for k, ply in pairs( player.GetAll() ) do
			if ( ply.BoardModel ) then
				ply.BoardModel:DrawModel()
			end
		end
	end
end

setupboard()
