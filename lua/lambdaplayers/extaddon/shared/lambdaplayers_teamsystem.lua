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
local huntDown = CreateLambdaConvar( "lambdaplayers_teams_huntdownotherteams", 0, true, false, false, "If members of Lambda Team should stick together if possible", 0, 1, { name = "Stick Together", type = "Bool", category = "Team System" } )
local drawTeamName = CreateLambdaConvar( "lambdaplayers_teams_drawteamname", 1, true, true, false, "If your teammates should have your team's name drawn above them", 0, 1, { name = "Draw Team Name Above Teammates", type = "Bool", category = "Team System" } )
local drawHalo = CreateLambdaConvar( "lambdaplayers_teams_drawhalo", 1, true, true, false, "If your teammates should have halos drawn around them", 0, 1, { name = "Draw Halos Around Teammates", type = "Bool", category = "Team System" } )

CreateLambdaColorConvar( "lambdaplayers_teams_teamcolor", Color( 255, 255, 255 ), false, false, "The color to use for team the next Lambda Player spawns in", { name = "Team Color", category = "Team System" } )
local teamColorR = GetConVar( "lambdaplayers_teams_teamcolor_r" )
local teamColorG = GetConVar( "lambdaplayers_teams_teamcolor_g" )
local teamColorB = GetConVar( "lambdaplayers_teams_teamcolor_b" )

CreateLambdaConsoleCommand( "lambdaplayers_teams_copyteamnametomyteam", function( ply ) plyTeam:SetString( lambdaTeam:GetString() ) end, true, "Copies the currently set team name to my team setting", { name = "Copy Team Name To My Team", category = "Team System" } )

hook.Add( "LambdaOnInitialize", hooksPrefix .. "OnInitialize", function( self, wepEnt )
    if teamsEnabled:GetBool() then 
        local spawnTeam = lambdaTeam:GetString()
        if spawnTeam != "" then
            self.l_Team = spawnTeam
            self.l_TeamColor = Color( teamColorR:GetInt(), teamColorG:GetInt(), teamColorB:GetInt() )
        end
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
            if !LambdaIsValid( ent ) or !self:CanTarget( ent ) then return end
            return ( ent.IsLambdaPlayer and ent.l_Team or ent:IsPlayer() and ent:GetInfo( "lambdaplayers_teams_myteam" ) != "" )
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

        if self:IsInMyTeam( victim ) and self:CanTarget( attacker ) and ( self:IsInRange( attacker, 500 ) or self:CanSee( attacker ) ) then
            self:AttackTarget( attacker )
        elseif self:IsInMyTeam( attacker ) and self:CanTarget( victim ) and ( self:IsInRange( victim, 500 ) or self:CanSee( victim ) ) then
            self:AttackTarget( victim )
        end
    end )

    hook.Add( "LambdaOnBeginMove", hooksPrefix .. "OnBeginMove", function( self, pos, isonnavmesh )
        local state = self:GetState()
        if state != "Idle" and state != "FindTarget" then return end

        local rndDecision = random( 1, 100 )
        if rndDecision < 30 and stickTogether:GetBool() then
            local rndMember = self:GetRandomTeamMember()
            if IsValid( rndMember ) then
                local movePos = ( rndMember:GetPos() + VectorRand( -400, 400 ) )
                if isonnavmesh then
                    local navarea = GetNavArea( movePos, 400 )
                    if IsValid( navarea ) then movePos = navarea:GetClosestPointOnArea( movePos ) end
                end
                self:RecomputePath( movePos ) 
            end
        elseif rndDecision > 60 and huntDown:GetBool() and attackOthers:GetBool() then
            for _, v in RandomPairs( GetLambdaPlayers() ) do
                if !v.l_Team or v:GetIsDead() or self:IsInMyTeam( v ) then continue end

                local movePos = ( v:GetPos() + VectorRand( -300, 300 ) )
                if isonnavmesh then
                    local navarea = GetNavArea( movePos, 300 )
                    if IsValid( navarea ) then movePos = navarea:GetClosestPointOnArea( movePos ) end
                end

                self:RecomputePath( movePos )
                break
            end
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
    local table_IsEmpty = table.IsEmpty
    local AddHalo = halo.Add

    hook.Add( "LambdaGetDisplayColor", hooksPrefix .. "OnGetDisplayColor", function( self, ply )
        if self.l_TeamColor then return self.l_TeamColor end
    end )

    hook.Add( "PreDrawHalos", hooksPrefix .. "OnPreDrawHalos", function()
        local plyTeam = LocalPlayer():GetInfo( "lambdaplayers_teams_myteam" )
        if plyTeam == "" or !drawHalo:GetBool() then return end

        for _, v in ipairs( GetLambdaPlayers() ) do
            local vTeam = v.l_Team
            if !vTeam or vTeam != plyTeam or v:GetIsDead() or !v:IsBeingDrawn() then continue end            
            AddHalo( { v }, v:GetDisplayColor(), 3, 3, 1, true, false )
        end
    end )

    hook.Add( "HUDPaint", hooksPrefix .. "OnHUDPaint", function()
        local ply = LocalPlayer()
        
        local traceEnt = ply:GetEyeTrace().Entity
        if LambdaIsValid( traceEnt ) and traceEnt.IsLambdaPlayer then
            local entTeam = traceEnt.l_Team
            if entTeam then 
                local color = traceEnt:GetDisplayColor()
                
                local friendTbl = traceEnt.l_friends
                local height = ( ( friendTbl and !table_IsEmpty( friendTbl ) ) and 1.68 or 1.78 )

                DrawText( "Team: " .. entTeam, "lambdaplayers_displayname", ( ScrW() / 2 ), ( ScrH() / height ) + LambdaScreenScale( 1 + UIScale:GetFloat() ), color, TEXT_ALIGN_CENTER ) 
            end
        end

        local plyTeam = ply:GetInfo( "lambdaplayers_teams_myteam" )
        if plyTeam == "" or !drawTeamName:GetBool() then return end

        teamNameTraceTbl.start = ply:EyePos()
        teamNameTraceTbl.filter = { ply }

        for _, v in ipairs( GetLambdaPlayers() ) do
            local vTeam = v.l_Team
            if !vTeam or vTeam != plyTeam or v:GetIsDead() or !v:IsBeingDrawn() then continue end

            local textPos = ( v:GetPos() + v:GetUp() * 96 )
            teamNameTraceTbl.endpos = textPos
            teamNameTraceTbl.filter[ 2 ] = v
            if TraceLine( teamNameTraceTbl ).Hit then continue end

            local drawPos = textPos:ToScreen()
            DrawText( plyTeam .. "'s Member", "lambdaplayers_displayname", drawPos.x, drawPos.y, v.l_TeamColor, TEXT_ALIGN_CENTER )
        end
    end )

end