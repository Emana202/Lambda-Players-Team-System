AddCSLuaFile()

ENT.Base = "base_anim"
ENT.IsLambdaSpawnpoint = true

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "SpawnIndex" )

    self:NetworkVar( "String", 0, "SpawnTeam" )

    self:NetworkVar( "Vector", 0, "TeamColor" )
end

if ( SERVER ) then

    local vec_white = Vector( 1, 1, 1 )
    local TraceHull = util.TraceHull
    local occupiedTrTbl = {
        collisiongroup = COLLISION_GROUP_PLAYER,
        mins = Vector( -16, -16, 0 ), 
        maxs = Vector( 16, 16, 72 )
    }

    function ENT:Initialize()
        local spawnTeam = self.SpawnTeam
        self:SetSpawnTeam( spawnTeam )

        local teamColor = ( LambdaTeams:GetTeamColor( self.SpawnTeam ) or vec_white )
        self:SetTeamColor( teamColor )
        
        self:SetSpawnIndex( self:GetCreationID() )

        self.IsOccupied = false
        
        self:SetModel( "models/props_combine/combine_mine01.mdl" )
        self:EmitSound( "lambdaplayers/spawnpoint/teamspawn_init.mp3" )
        self:DrawShadow(false)
        self:SetColor( teamColor:ToColor() )
    end

    function ENT:Think()
        local selfPos = self:GetPos()

        occupiedTrTbl.start = selfPos
        occupiedTrTbl.endpos = selfPos + vector_up * 4
        self.IsOccupied = ( LambdaIsValid( TraceHull( occupiedTrTbl ).Entity ) )

        self:NextThink( CurTime() + 0.1 )
        return true
    end

end

if ( CLIENT ) then

    local IsValid = IsValid
    local LocalPlayer = LocalPlayer
    local CurTime = CurTime
    local cam = cam

    local rotateAng = Angle( 0, ( CurTime() * 100 % 360 ), 90 )
    local angAddVec = Vector( 0, 0, 1 )
    local textOffset = Vector( 0, 0, 90 )

    function ENT:Draw()
        local ply = LocalPlayer()
        local actWep = ply:GetActiveWeapon()
        if !ply:Alive() or !IsValid( actWep ) or actWep:GetClass() != "gmod_tool" or ply:GetTool().Mode != "lambda_teamsystem_spawnpointmaker" then return end

        local textPos = ( self:GetPos() + textOffset )
        local spawnID = self:GetSpawnIndex()
        local teamColor = self:GetTeamColor():ToColor()
        local spawnTeam = self:GetSpawnTeam()
        local text = ( spawnTeam != "" and  spawnTeam .. " " .. spawnID or spawnID )

        rotateAng[ 2 ] = ( CurTime() * 100 % 360 )
        cam.Start3D2D( textPos, rotateAng, 0.5 )
            draw.DrawText( text, "ChatFont", 0, 0, teamColor, TEXT_ALIGN_CENTER )
        cam.End3D2D()

        rotateAng:RotateAroundAxis( angAddVec, 180 )
        cam.Start3D2D( textPos, rotateAng, 0.5 )
            draw.DrawText( text, "ChatFont", 0, 0, teamColor, TEXT_ALIGN_CENTER )
        cam.End3D2D()

        self:DrawModel()
    end

end