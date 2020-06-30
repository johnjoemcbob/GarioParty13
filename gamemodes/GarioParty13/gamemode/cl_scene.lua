--
-- Gario Party 13
-- 11/06/20
--
-- Clientside Scenes & Animations
--

--
-- Scenes
--

local PATH = HOOK_PREFIX .. "/scenes/"

RESERVED_CAMERA = "reserved_camera"
RESERVED_PLAYER = "reserved_player"

-- Load json format from data files and parse to table
function LoadScene( name )
	return LoadTableFromJSON( PATH, name )
end

-- Temp for old existing hardcoded scenes
function SaveScene( name, tab )
	local path = PATH .. name .. ".json"

	local json = util.TableToJSON( tab, true )
	file.Write( path, json )
end

function RenderScene( scene, pos, storecollisions, Collisions, BoundsMultiplier )
	if ( !scene ) then return end
	for k, detail in pairs( scene ) do
		if ( detail[1] ) then
			local col = detail.Colour
				if ( col == nil ) then
					col = COLOUR_BASE
				end
			local scale = Vector( 1, 1, 1 )
				if ( detail.Scale != nil ) then
					scale = detail.Scale
				end
			local ent = GAMEMODE.RenderCachedModel(
				detail[1],
				pos + detail[2],
				detail[3],
				scale,
				detail.Material,
				col
			)

			-- If first render then also store collision data
			if ( storecollisions ) then
				if ( detail[2].z < 0 ) then
					local min, max = ent:GetRenderBounds()

					table.insert( Collisions, {
						min = pos + detail[2] + min * BoundsMultiplier,
						max = pos + detail[2] + max * BoundsMultiplier,
						angle = detail[3].y
					} )
				end
			end
		end
	end
	return Collisions
end

function GetSceneCalcView( scene, ply, pos, ang, fov )
	if ( !scene[RESERVED_CAMERA] ) then return end
	local pos = scene[RESERVED_CAMERA][2]
	local ang = scene[RESERVED_CAMERA][3]

	local view = {}
		view.origin = pos
		view.angles = ang
		view.fov = scene[RESERVED_CAMERA].FOV or fov
		view.zfar = 1000

		LocalPlayer().CalcViewAngles = Angle( view.angles.p, view.angles.y + 90, view.angles.r )
	return view
end

--
-- ANIMATIONS
--

-- Set animation with name and scene table to control
function PlaySceneAnimation( scenetab, anim, finishcallback )
	LocalPlayer().CurrentAnimation = {}
	LocalPlayer().CurrentAnimation.Scene = scenetab
	LocalPlayer().CurrentAnimation.Data = LoadAnimation( anim )
	LocalPlayer().CurrentAnimation.StartTime = CurTime()
	LocalPlayer().CurrentAnimation.FinishCallback = finishcallback
end

-- Load animation
local PATH = HOOK_PREFIX .. "/animations/"
function LoadAnimation( name )
	return LoadTableFromJSON( PATH, name )
end
-- Temp for old existing hardcoded scenes
function SaveAnimation( name, tab )
	local path = PATH .. name .. ".json"

	local json = util.TableToJSON( tab, true )
	file.Write( path, json )
end

-- Update animation
local function getclosestkeyframe( part, time, next )
	local closest = 0
	for frame, data in SortedPairs( part ) do
		if ( tonumber( frame ) < time ) then
			closest = frame
		elseif ( next ) then
			closest = frame
			return closest
		else
			return closest
		end
	end
end

hook.Add( "Think", HOOK_PREFIX .. "Animations_Think", function()
	local anim = LocalPlayer().CurrentAnimation
	if ( anim and anim.Data ) then
		local overallprogress = ( CurTime() - anim.StartTime ) / anim.Data.Duration
		anim.CurrentProgress = overallprogress

		-- Test skipping input
		if ( input.IsButtonDown( KEY_SPACE ) ) then
			LocalPlayer().CurrentAnimation.StartTime = anim.StartTime - FrameTime()
		end

		-- Update
		for name, part in pairs( anim.Data ) do
			if ( type(part) == "table" ) then
				if ( !anim.Scene[name] ) then
					anim.Scene[name] = {
						[1] = nil,
						[2] = part[0].Pos,
						[3] = part[0].Ang or Angle( 0, 0, 0 ),
					}
				end

				local currentkeyframe = getclosestkeyframe( part, overallprogress )
				local nextkeyframe = getclosestkeyframe( part, overallprogress, true )
				if ( currentkeyframe != nextkeyframe ) then
					local progress = ( overallprogress - currentkeyframe ) / ( nextkeyframe - currentkeyframe )

					-- Custom variables, for both key frames
					local fs = { currentkeyframe, nextkeyframe }
					for i = 1, 2 do
						for k, val in pairs( part[fs[i]] ) do
							if ( k != "Pos" and k != "Ang" ) then
								if ( k == "LookAt" and anim.Scene[val] ) then
									part[fs[i]].Ang = ( anim.Scene[val][2] - part[currentkeyframe].Pos ):GetNormalized():Angle()
								end
								if ( k == "FOV" and i == 1 ) then
									anim.Scene[name].FOV = Lerp( progress, part[currentkeyframe].FOV, part[nextkeyframe].FOV )
								end
							end
						end
					end

					-- Basic pos/ang
					anim.Scene[name][2] = LerpVector( progress, part[currentkeyframe].Pos, part[nextkeyframe].Pos )
					if ( part[currentkeyframe].Ang and part[nextkeyframe].Ang ) then
						anim.Scene[name][3] = LerpAngle( progress, part[currentkeyframe].Ang, part[nextkeyframe].Ang )
					end
				end
			end
		end

		-- Finish
		if ( overallprogress >= 1 ) then
			if ( anim.FinishCallback ) then
				anim.FinishCallback()
			end
			LocalPlayer().CurrentAnimation = nil
		end
	end
end )
