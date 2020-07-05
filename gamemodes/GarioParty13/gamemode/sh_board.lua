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

SPACE_TYPE_DEFAULT	= 0
SPACE_TYPE_NEGATIVE	= 1

Board = Board or {}
local function setupboard()
	Board.Data = {}
	AddBoardSpace( 1, 1, SPACE_TYPE_DEFAULT, { Vector( 2, 2 ) } )
	AddBoardSpace( 2, 2, SPACE_TYPE_DEFAULT, { Vector( 2, 3 ) } )
	AddBoardSpace( 2, 3, SPACE_TYPE_DEFAULT, { Vector( 2, 4 ) } )
	AddBoardSpace( 2, 4, SPACE_TYPE_DEFAULT, { Vector( 1, 1 ) } )
end

-- Connections are one way by default
function AddBoardSpace( x, y, type, connections )
	Board.Data = Board.Data or {}
	Board.Data[x] = Board.Data[x] or {}
	Board.Data[x][y] = {}
	Board.Data[x][y].Type = type
	Board.Data[x][y].Connections = connections

	-- Another method?
	-- GAMEMODE.Board[x][y].Connections = {}
	-- for k, conn in pairs( connections ) do
	-- 	GAMEMODE.Board[x][y].Connections[conn.x] = GAMEMODE.Board[x][y].Connections[conn.x] or {}
	-- 	GAMEMODE.Board[x][y].Connections[conn.x][conn.y] = true
	-- end
end

if ( CLIENT ) then
	hook.Add( "Tick", HOOK_PREFIX .. "Tick", function()
		for k, ply in pairs( player.GetAll() ) do
			if ( ply == Turn.Current and LocalPlayer():KeyDown( IN_USE ) ) then
				if ( Dice.Current ) then
					Dice:RequestHit()
				end
			end
			if ( !Dice.Current and !ply.TempTargetSpace and ply.BoardModel and ply.BoardModel.Moves > 0 ) then
				local space = ply.TempCurrentSpace
				ply.TempTravel = 0
				ply.TempTargetSpace = Board.Data[space.x][space.y].Connections[1]
				ply.BoardModel.NextPlay = 0
				ply.BoardModel.Moves = ply.BoardModel.Moves - 1
			end

			-- Temp target controls
			ply.TempCurrentSpace = ply.TempCurrentSpace or Vector( 1, 1 )
			ply.TempTravel = ply.TempTravel or 0

			-- Create
			if ( !ply.BoardModel or !ply.BoardModel:IsValid() ) then
				local pos = GP13_BOARD_POS
				local ang = Angle( 0, 0, 0 )
				ply.BoardModel = GAMEMODE.AddAnim( "models/eli.mdl", "run_all", pos, ang, 1 )
				ply.BoardModel.Moves = 0
			end

			if ( ply.TempTargetSpace ) then
				-- Temp time progress
				ply.TempTravel = ply.TempTravel + FrameTime() * 10
				if ( ply.TempTravel > 1 ) then
					ply.TempTravel = 0

					local space = ply.TempCurrentSpace
					local target = Board.Data[space.x][space.y].Connections[1]
					ply.TempCurrentSpace = target

					ply.TempTargetSpace = nil
					ply.BoardModel.NextPlay = 0

					if ( ply.BoardModel.Moves == 0 ) then
						Turn:RequestEnd()
					end
					break
				end

				-- Move
				local space = ply.TempCurrentSpace
				local target = ply.TempTargetSpace
				local pos = GP13_BOARD_POS + space * GP13_BOARD_SCALE
					local targetpos = GP13_BOARD_POS + target * GP13_BOARD_SCALE
					pos = LerpVector( ply.TempTravel, pos, targetpos )
				local ang = ( targetpos - pos ):Angle()

				-- Update
				ply.BoardModel:SetPos( pos )
				ply.BoardModel:SetAngles( ang )

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

				-- Face camera
				local ang = Angle( 0, 180, 0 )
				ply.BoardModel:SetAngles( ang )
			end

			-- Animate
			ply.BoardModel:FrameAdvance()
		end
	end )

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
