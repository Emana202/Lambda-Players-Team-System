local IsValid = IsValid
local RandomPairs = RandomPairs
local GetConVar = GetConVar
local GetAll = ents.GetAll
local ignorePlys = GetConVar( "ai_ignoreplayers" )
local hooksPrefix = "LambdaTeamSystemHook_"

local teamsEnabled = CreateLambdaConvar( "lambdaplayers_teams_enabled", 0, true, false, false, "Enables the team system that will allow Lambda Players to be assigned to various different teams", 0, 1, { name = "Enable Team System", type = "Bool", category = "Team System" } )
local lambdaTeam = CreateLambdaConvar( "lambdaplayers_teams_teamname", "", true, false, false, "The team the next spawned Lambda Players will be assigned to. Leave empty to not assign to any", 0, 1, { name = "Team Name", type = "Text", category = "Team System" } )
local plyTeam = CreateLambdaConvar( "lambdaplayers_teams_myteam", "", true, true, true, "Determines what team you are currenly assigned to. Leave empty to be neutral to every team", 0, 1, { name = "My Team", type = "Text", category = "Team System" }  )
local attackOthers = CreateLambdaConvar( "lambdaplayers_teams_attackotherteams", 1, true, false, false, "If the Lambda Teams should attack other teams on sight", 0, 1, { name = "Attack Other Teams", type = "Bool", category = "Team System" } )
local noFFs = CreateLambdaConvar( "lambdaplayers_teams_nofriendlyfire", 1, true, false, false, "If the Lambda Teams shouldn't be able to damage their teammates", 0, 1, { name = "No Friendly Fire", type = "Bool", category = "Team System" } )
local stickTogether = CreateLambdaConvar( "lambdaplayers_teams_sticktogether", 1, true, false, false, "If members of Lambda Team should stick together if possible", 0, 1, { name = "Stick Together", type = "Bool", category = "Team System" } )

CreateLambdaColorConvar( "lambdaplayers_teams_teamcolor", Color( 255, 255, 255 ), false, false, "The color to use for team the next Lambda Player spawns in", { name = "Team Color", category = "Team System" } )
local teamColorR = GetConVar( "lambdaplayers_teams_teamcolor_r" )
local teamColorG = GetConVar( "lambdaplayers_teams_teamcolor_g" )
local teamColorB = GetConVar( "lambdaplayers_teams_teamcolor_b" )

CreateLambdaConvar( "lambdaplayers_teams_displaymyteamname", 1, true, true, true, "If your team's name should display above your teammates when you're near them", 0, 1, { name = "Display My Team Name", type = "Bool", category = "Team System" } )
CreateLambdaConsoleCommand( "lambdaplayers_teams_copyteamnametomyteam", function( ply ) plyTeam:SetString( lambdaTeam:GetString() ) end, true, "Copies the currently set team name to my team setting", { name = "Copy Team Name To My Team", category = "Team System" } )

hook.Add( "LambdaOnInitialize", hooksPrefix .. "OnInitialize", function( self, wepEnt )
    if teamsEnabled:GetBool() and lambdaTeam:GetString() != "" then
        self.l_Team = spawnTeam
        self.l_TeamColor = Color( teamColorR:GetInt(), teamColorG:GetInt(), teamColorB:GetInt() )
    end

    function self:IsInMyTeam( ent )
        local myTeam = self.l_Team
        if !myTeam then return false end

        local entTeam = ( ent:IsPlayer() and ent:GetInfo( "lambdaplayers_teams_myteam" ) or ent.l_Team )
        return ( entTeam and entTeam != "" and entTeam == myTeam )
    end

    if ( SERVER ) then 
        self.l_NextEnemyTeamSearchT = 0 
        if self.l_TeamColor then self:SetPlyColor( self.l_TeamColor:ToVector() ) end

        function self:GetRandomTeamMember()
            if !self.l_Team then return NULL end
            for _, v in RandomPairs( GetAll() ) do
                if !IsValid( v ) or v == self or v:IsPlayer() and ( !v:Alive() or ignorePlys:GetBool() ) or !self:IsInMyTeam( v ) then continue end
                return v
            end
        end
    end
end )

if ( SERVER ) then

    local GetNavArea = navmesh.GetNavArea
    local VectorRand = VectorRand
    local random = math.random
    local CurTime = CurTime

    hook.Add( "LambdaOnThink", hooksPrefix .. "OnThink", function( self, wepEnt )
        if CurTime() <= self.l_NextEnemyTeamSearchT then return end
        self.l_NextEnemyTeamSearchT = CurTime() + 1.0

        if !self.l_Team or self:GetState() == "Combat" or !attackOthers:GetBool() then return end

        local surroundings = self:FindInSphere( nil, 2000, function( ent )
            return ( LambdaIsValid( ent ) and ( ent.IsLambdaPlayer or ent:IsPlayer() ) and self:CanTarget( ent ) )
        end )
        if #surroundings == 0 then return end
        self:AttackTarget( surroundings[ random( #surroundings ) ] )
    end )
    
    hook.Add( "LambdaCanTarget", hooksPrefix .. "OnCanTarget", function( self, target )
        if self:IsInMyTeam( target ) then return true end
    end )
    
    hook.Add( "LambdaOnInjured", hooksPrefix .. "OnInjured", function( self, dmginfo )
        if !self.l_Team then return end

        local attacker = dmginfo:GetAttacker()
        if !IsValid( attacker ) or attacker == self or !self:IsInMyTeam( attacker ) then return end

        if noFFs:GetBool() then return true end
    end )
    
    hook.Add( "LambdaOnOtherInjured", hooksPrefix .. "OnOtherInjured", function( self, victim, dmginfo, tookDamage )
        if !tookDamage or !self.l_Team or self:GetState() == "Combat" then return end

        local attacker = dmginfo:GetAttacker()
        if !LambdaIsValid( attacker ) or attacker == self then return end

        if self:IsInMyTeam( victim ) and self:CanTarget( attacker ) then
            self:AttackTarget( attacker )
        elseif self:IsInMyTeam( attacker ) and self:CanTarget( victim ) then
            self:AttackTarget( victim )
        end
    end )
    
    hook.Add( "LambdaOnBeginMove", hooksPrefix .. "OnBeginMove", function( self, pos, isonnavmesh )
        local state = self:GetState()
        if ( state != "Idle" and state != "FindTarget" ) or random( 1, 100 ) < 30 or !stickTogether:GetBool() then return end

        local rndMember = self:GetRandomTeamMember()
        if IsValid( rndMember ) then
            local movePos = ( rndMember:GetPos() + VectorRand( -500, 500 ) )
            if isonnavmesh then
                local navarea = GetNavArea( movePos, 500 )
                if IsValid( navarea ) then movePos = navarea:GetClosestPointOnArea( movePos ) end
            end
            self:RecomputePath( movePos ) 
        end
    end )
    
    hook.Add( "PlayerShouldTakeDamage", hooksPrefix .. "OnPlayerShouldTakeDamage", function( ply, attacker )
        local plyTeam = ply:GetInfo( "lambdaplayers_teams_myteam" )
        if !plyTeam or plyTeam == "" then return end

        local attTeam = ( attacker:IsPlayer() and attacker:GetInfo( "lambdaplayers_teams_myteam" ) or attacker.l_Team )
        if !attTeam or attTeam == "" or plyTeam != attTeam then return end

        if noFFs:GetBool() then return false end
    end )

end

if ( CLIENT ) then

    local DrawText = draw.DrawText
    local UIScale = GetConVar( "lambdaplayers_uiscale" )
    local ScrW = ScrW
    local ScrH = ScrH
    local LocalPlayer = LocalPlayer
    local ipairs = ipairs
    local teamNameTraceTbl = {}
    local TraceLine = util.TraceLine
    local GetLambdaPlayers = GetLambdaPlayers
    local tobool = tobool
    local table_IsEmpty = table.IsEmpty

    local function OnGetDisplayColor( self, ply )
        if self.l_TeamColor then return self.l_TeamColor end
    end

    local function OnHUDPaint()
        local ply = LocalPlayer()
        local sw, sh = ScrW(), ScrH()
        local traceEnt = ply:GetEyeTrace().Entity

        if LambdaIsValid( traceEnt ) and traceEnt.IsLambdaPlayer then
            local entTeam = traceEnt.l_Team
            if entTeam then 
                local color = traceEnt:GetDisplayColor()
                
                local friendTbl = traceEnt.l_friends
                local height = ( ( friendTbl and !table_IsEmpty( friendTbl ) ) and 1.68 or 1.78 )

                DrawText( "Team: " .. entTeam, "lambdaplayers_displayname", ( sw / 2 ), ( sh / height ) + LambdaScreenScale( 1 + UIScale:GetFloat() ), color, TEXT_ALIGN_CENTER ) 
            end
        end

        local plyTeam = ply:GetInfo( "lambdaplayers_teams_myteam" )
        if plyTeam != "" and tobool( ply:GetInfo( "lambdaplayers_teams_displaymyteamname" ) ) then
            local eyePos = ply:EyePos()
            
            teamNameTraceTbl.start = eyePos
            teamNameTraceTbl.filter = { ply }

            for _, v in ipairs( GetLambdaPlayers() ) do
                local vTeam = v.l_Team
                if !vTeam or vTeam != plyTeam or v:GetIsDead() then continue end

                local textPos = ( v:GetPos() + v:GetUp() * 96 )
                if textPos:DistToSqr( eyePos ) > ( 1000 * 1000 ) then continue end

                teamNameTraceTbl.endpos = textPos
                teamNameTraceTbl.filter[ 2 ] = v
                if TraceLine( teamNameTraceTbl ).Hit then continue end

                local drawPos = textPos:ToScreen()
                DrawText( plyTeam .. "'s Member", "lambdaplayers_displayname", drawPos.x, drawPos.y, v.l_TeamColor, TEXT_ALIGN_CENTER )
            end
        end
    end

    hook.Add( "HUDPaint", hooksPrefix .. "OnHUDPaint", OnHUDPaint )
    hook.Add( "LambdaGetDisplayColor", hooksPrefix .. "OnGetDisplayColor", OnGetDisplayColor )

end