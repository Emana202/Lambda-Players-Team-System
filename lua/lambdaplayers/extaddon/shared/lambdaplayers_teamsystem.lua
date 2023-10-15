local ipairs = ipairs
local IsValid = IsValid
local CurTime = CurTime
local tostring = tostring
local pairs = pairs
local GetGlobalInt = GetGlobalInt
local SetGlobalInt = SetGlobalInt
local Rand = math.Rand
local random = math.random
local table_Count = table.Count
local table_Empty = table.Empty
local team_SetUp = team.SetUp
local team_SetColor = team.SetColor
local team_GetColor = team.GetColor
local net = net
local ents_GetAll = ents.GetAll
local ents_FindByClass = ents.FindByClass
local player_GetAll = player.GetAll
local table_Add = table.Add
local table_Copy = table.Copy
local table_remove = table.remove
local timer_Simple = timer.Simple
local timer_Create = timer.Create
local timer_Remove = timer.Remove
local file_Exists = file.Exists

local modulePrefix = "Lambda_TeamSystem_"
local defaultPlyClr = Color( 255, 255, 100 )
local color_glacier = Color( 130, 164, 192 )

local ignorePlys = GetConVar( "ai_ignoreplayers" )
local rasp = GetConVar( "lambdaplayers_lambda_respawnatplayerspawns" )

if SERVER and !file_Exists( "lambdaplayers/teamlist.json", "DATA" ) then
    LAMBDAFS:WriteFile( "lambdaplayers/teamlist.json", {
        [ "Based Bros" ] = {
            name = "Based Bros",
            color = Vector( 1, 0, 0 )
        },
        [ "Counter-Minges" ] = {
            name = "Counter-Minges",
            color = Vector( 0, 0.2471, 1 )
        },
        [ "Eeveelutioners" ] = {
            name = "Eeveelutioners",
            color = Vector( 0, 1, 1 )
        },
        [ "ARCLIGHT" ] = {
            name = "ARCLIGHT",
            color = Vector( 0.6039, 0.2392, 1 )
        }
    }, "json", false )
end

LambdaTeams = LambdaTeams or {}

function LambdaTeams:UpdateData()
    local teamList = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
    if table_Count( teamList ) == 0 then print( "LAMBDA TEAM SYSTEM WARNING: THERE ARE NO TEAMS REGISTERED!" ) return end
    
    LambdaTeams.TeamData = teamList
    LambdaTeams.RealTeams = LambdaTeams.RealTeams or {}
    LambdaTeams.RealTeamCount = LambdaTeams.RealTeamCount or 0

    if ( CLIENT ) then
        LambdaTeams.TeamOptions = { [ "None" ] = "" }
        LambdaTeams.TeamOptionsRandom = { [ "None" ] = "", [ "Random" ] = "random" }
    end

    local teamID = ( LambdaTeams.RealTeamCount + 1 )
    for name, data in pairs( LambdaTeams.TeamData ) do 
        if ( CLIENT ) then
            LambdaTeams.TeamOptions[ name ] = name 
            LambdaTeams.TeamOptionsRandom[ name ] = name
        end

        local teamClr = data.color
        teamClr = ( teamClr and teamClr:ToColor() or defaultPlyClr )

        if !LambdaTeams.RealTeams[ name ] then
            team_SetUp( teamID, name, teamClr, false )
            LambdaTeams.RealTeams[ name ] = teamID

            teamID = teamID + 1
            LambdaTeams.RealTeamCount = teamID
        else
            team_SetColor( LambdaTeams.RealTeams[ name ], teamClr )
        end
    end
end

LambdaTeams:UpdateData()

---

local teamsEnabled  = CreateLambdaConvar( "lambdaplayers_teamsystem_enable", 0, true, false, false, "Enables the work of the module.", 0, 1, { name = "Enable Team System", type = "Bool", category = "Team System" } )
local mwsTeam       = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_spawnteam", "", true, false, false, "The team the newly spawned Lambda Players from MWS should be assigned into.", 0, 1, { name = "Spawn Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "MWS" } )
local incNoTeams    = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_includenoteams", 0, true, false, false, "When spawning a Lambda Player from MWS with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "MWS" }  )
local mwsTeamLimit  = CreateLambdaConvar( "lambdaplayers_teamsystem_mws_teamlimit", 0, true, false, false, "The limit of how many members can be allowed to be assigned to each team. Set to zero for no limit.", 0, 50, { name = "Team Member Limit", type = "Slider", decimals = 0, category = "MWS" }  )
CreateLambdaConvar( "lambdaplayers_teamsystem_lambdateam", "", true, true, true, "The team the newly spawned Lambda Players should be assigned into.", 0, 1, { name = "Lambda Team", type = "Combo", options = LambdaTeams.TeamOptionsRandom, category = "Team System" } )
local playerTeam    = CreateLambdaConvar( "lambdaplayers_teamsystem_playerteam", "", true, true, true, "The lambda team you are currently assigned to.", 0, 1, { name = "Player Team", type = "Combo", options = LambdaTeams.TeamOptions, category = "Team System" }  )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_updateteamlist", function( ply ) 
    LambdaTeams:UpdateData()

   for _, option in ipairs( _LAMBDAConVarSettings ) do
        local name = option.name
        if option.name == "Player Team" then option.options = LambdaTeams.TeamOptions end
        if option.name == "Lambda Team" then option.options = LambdaTeams.TeamOptionsRandom end
   end

    ply:ConCommand( "spawnmenu_reload" )
end, true, "Refreshes the team list. Use this after editting teams in the team panel.", { name = "Refresh Team List", category = "Team System" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_includenoteams", 0, true, true, true, "When spawning a Lambda Player with random team, should they also have a chance to spawn without being assigned to any team?", 0, 1, { name = "Include Neutral To Random Teams", type = "Bool", category = "Team System" }  )
local teamLimit         = CreateLambdaConvar( "lambdaplayers_teamsystem_teamlimit", 0, true, false, false, "The limit of how many members can be allowed to be assigned to each team. Set to zero for no limit.", 0, 50, { name = "Team Member Limit", type = "Slider", decimals = 0, category = "Team System" }  )
local attackOthers      = CreateLambdaConvar( "lambdaplayers_teamsystem_attackotherteams", 0, true, false, false, "If Lambda Players should immediately start attacking the members of other teams at their sight.", 0, 1, { name = "Attack On Sight", type = "Bool", category = "Team System" } )
local noFriendFire      = CreateLambdaConvar( "lambdaplayers_teamsystem_nofriendlyfire", 1, true, false, false, "If Lambda Players shouldn't be able to damage their teammates.", 0, 1, { name = "No Friendly Fire", type = "Bool", category = "Team System" } )
local stickTogether     = CreateLambdaConvar( "lambdaplayers_teamsystem_sticktogether", 1, true, false, false, "If Lambda Players should stick together with their teammates.", 0, 1, { name = "Stick Together", type = "Bool", category = "Team System" } )
local huntDown          = CreateLambdaConvar( "lambdaplayers_teamsystem_huntdownotherteams", 0, true, false, false, "If Lambda Players should hunt down the members of other teams. 'Attack On Sight' option should be enabled for it to work.", 0, 1, { name = "Hunt Down Enemy Teams", type = "Bool", category = "Team System" } )
local useSpawnpoints    = CreateLambdaConvar( "lambdaplayers_teamsystem_usespawnpoints", 0, true, false, false, "If Lambda Players should spawn and respawn in one of their team's spawn points.", 0, 1, { name = "Respawn In Team Spawn Points", type = "Bool", category = "Team System" } )
local plyUseSpawnpoints = CreateLambdaConvar( "lambdaplayers_teamsystem_plyusespawnpoints", 0, true, true, true, "If when respawning, should you spawn in one of your Lambda Team's spawn points.", 0, 1, { name = "Respawn In Team Spawn Points", type = "Bool", category = "Team System" } )
local drawTeamName      = CreateLambdaConvar( "lambdaplayers_teamsystem_drawteamname", 1, true, true, false, "Enables drawing team names above your Lambda teammates.", 0, 1, { name = "Draw Team Names", type = "Bool", category = "Team System" } )
local drawHalo          = CreateLambdaConvar( "lambdaplayers_teamsystem_drawhalo", 1, true, true, false, "Enables drawing halos around you Lambda Teammates", 0, 1, { name = "Draw Halos", type = "Bool", category = "Team System" } )

---

local gmMatchTime = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_gametime", 5, true, false, false, "The time the gamemode match will take to end in minutes. Set to zero for an endless match.", 0, 30, { name = "Match Time", type = "Slider", decimals = 0, category = "Team System - Gamemodes" } )
local gmPointsLimit = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_pointslimit", 30, true, false, false, "How many points should the team score in gamemode match in order to win. Set to zero to disable points", 0, 1000, { name = "Points Limit", type = "Slider", decimals = 0, category = "Team System - Gamemodes" } )
local gmTPToSpawns = CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_tptospawns", 1, true, false, false, "If team players should be teleported to their spawn positions on gamemode start", 0, 1, { name = "Teleport To Spawn On Start", type = "Bool", category = "Team System - Gamemodes" } )

--

CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_onwin", "lambdaplayers/gamewon/*", true, true, false, "The sound that plays when your team wins a gamemode match", 0, 1, { name = "Sound - On Game Won", type = "Text", category = "Team System - Gamemodes" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_onlose", "lambdaplayers/gamelost/*", true, true, false, "The sound that plays when your team loses a gamemode match", 0, 1, { name = "Sound - On Game Lost", type = "Text", category = "Team System - Gamemodes" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_gamestart", "lambdaplayers/gamestart/*", true, true, false, "The sound that plays when a gamemode starts.", 0, 1, { name = "Sound - On Match Begin", type = "Text", category = "Team System - Gamemodes" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_match30left", "lambdaplayers/matchtimeleft/30seconds.mp3", true, true, false, "The sound that plays when there's 30 seconds left before match's end.", 0, 1, { name = "Sound - 30 Second Left", type = "Text", category = "Team System - Gamemodes" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_gamemodes_snd_match10left", "lambdaplayers/matchtimeleft/10seconds.mp3", true, true, false, "The sound that plays when there's 10 seconds left before match's end.", 0, 1, { name = "Sound - 10 Second Left", type = "Text", category = "Team System - Gamemodes" } )

LambdaTeams.TeamPoints = LambdaTeams.TeamPoints or {}
LambdaTeams.SoundsToStop = LambdaTeams.SoundsToStop or {}

local gamemodeName, pointsName
local nextTimerProgressT = ( CurTime() + 1 )

local function GetTheMatchStats( endedPrematurely )
    local winnerTeam, winnerClr
    local curPoints, samePoints = 0, 0

    local contesters = {}
    for teamName, globalName in pairs( LambdaTeams.TeamPoints ) do
        local teamPoints = GetGlobalInt( globalName, 0 )
        local teamColor = LambdaTeams:GetTeamColor( teamName, true )

        if teamPoints > curPoints then 
            winnerTeam = teamName
            winnerClr = teamColor
            curPoints = teamPoints
        elseif teamPoints == curPoints then
            samePoints = ( samePoints + 1 )
        end

        contesters[ #contesters + 1 ] = { teamName, teamPoints, teamColor }
    end

    if samePoints != #contesters then
        LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", winnerClr, winnerTeam, color_glacier, " won the match of ", color_white, gamemodeName, color_glacier, " with total of ", color_white, tostring( curPoints ), color_glacier, " ", pointsName, ( curPoints > 1 and "s" or "" ), "!" )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_onwin", winnerTeam )

        for _, contestData in ipairs( contesters ) do
            local contestTeam = contestData[ 1 ]
            if contestTeam == winnerTeam then continue end

            local contestPoints = contestData[ 2 ]
            if contestPoints == 0 then
                LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", contestData[ 3 ], contestTeam, color_glacier, " ended up with no ", pointsName, "s at all :(" )
            else
                LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", contestData[ 3 ], contestTeam, color_glacier, " ended with total of ", color_white, tostring( contestPoints ), color_glacier, " ", pointsName, ( contestPoints > 1 and "s" or "" ) )
            end

            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_onlose", contestTeam )
        end
    elseif !endedPrematurely then
        LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", color_glacier, "Stalemate! Each team got the same amount of ", pointsName, ( curPoints > 1 and "s" or "" ), "!" )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_onlose" )
    end
end

local function StopGameMatch()
    SetGlobalInt( "LambdaTeamMatch_GameID", 0 )
    timer_Remove( "LambdaTeamMatch_ThinkTimer" )

    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_gamestart" )
    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match30left" )
    LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match10left" )

    local stopSnds = LambdaTeams.SoundsToStop
    if stopSnds then
        for _, sndCvar in ipairs( stopSnds ) do
            net.Start( "lambda_teamsystem_stopclientsound" )
                net.WriteString( sndCvar )
            net.Broadcast()
        end
    end

    for _, kp in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
        if !kp:GetIsCaptured() then continue end
        kp:BecomeNeutral()
    end
end

local function GameMatchThinkTimer()
    if !teamsEnabled:GetBool() then StopGameMatch() return end

    local pointLimit = GetGlobalInt( "LambdaTeamMatch_PointLimit" )
    if pointLimit != 0 then
        for teamName, globalName in pairs( LambdaTeams.TeamPoints ) do
            local teamPoints = GetGlobalInt( globalName, 0 )
            if teamPoints < pointLimit then continue end

            GetTheMatchStats()
            StopGameMatch()
            return
        end
    end

    local timeRemain = GetGlobalInt( "LambdaTeamMatch_TimeRemaining", 0 )
    if timeRemain != -1 and CurTime() >= nextTimerProgressT then
        if timeRemain == 0 then
            LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", color_glacier, "Reached the time limit of the match!" )
            GetTheMatchStats()
            StopGameMatch()
            return
        end
        nextTimerProgressT = ( CurTime() + 1 )

        timeRemain = ( timeRemain - 1 )
        SetGlobalInt( "LambdaTeamMatch_TimeRemaining", timeRemain )

        if timeRemain == 30 then
            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match30left", "all" )
        elseif timeRemain == 10 then
            LambdaTeams:StopConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match30left" )
            LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_match10left", "all" )
        end
    end
end

local function StartGamemode( ply, gameIndex, stopSnds )
    if !ply:IsSuperAdmin() then
        LambdaPlayers_Notify( ply, "You must be a Super Admin in order to start a match!", 1, "buttons/button10.wav" )
        return
    end

    local curIndex = GetGlobalInt( "LambdaTeamMatch_GameID", 0 )
    if curIndex != 0 then
        LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", color_glacier, "Player ", team_GetColor( ply:Team() ), ply:Nick(), color_glacier, " ended the match prematurely!" )
        GetTheMatchStats( true )
        StopGameMatch()
        return
    end

    if !teamsEnabled:GetBool() then 
        LambdaPlayers_Notify( ply, "You must have Team System enabled!", 1, "buttons/button10.wav" )
        return 
    end

    if gameIndex == 1 and #ents_FindByClass( "lambda_koth_point" ) == 0 then
        LambdaPlayers_Notify( ply, "You must have atleast one KOTH Point exist in order to start!", 1, "buttons/button10.wav" )
        return
    elseif gameIndex == 2 and #ents_FindByClass( "lambda_ctf_flag" ) <= 1 then
        LambdaPlayers_Notify( ply, "You must have atleast two CTF Flags exist for each team in order to start!", 1, "buttons/button10.wav" )
        return
    end

    LambdaTeams.SoundsToStop = stopSnds
    SetGlobalInt( "LambdaTeamMatch_GameID", gameIndex )
    SetGlobalInt( "LambdaTeamMatch_PointLimit", gmPointsLimit:GetInt() )

    for teamName, globalName in pairs( LambdaTeams.TeamPoints ) do
        SetGlobalInt( globalName, 0 )
        LambdaTeams.TeamPoints[ teamName ] = nil
    end

    local curTeams = {}
    for _, ply in ipairs( table_Add( GetLambdaPlayers(), player_GetAll() ) ) do
        local plyTeam = LambdaTeams:GetPlayerTeam( ply )
        if !plyTeam then continue end

        if !LambdaTeams.TeamPoints[ plyTeam ] then
            LambdaTeams.TeamPoints[ plyTeam ] = "LambdaTeamMatch_TeamPoints_" .. plyTeam 
            curTeams[ plyTeam ] = {}
        end

        curTeams[ plyTeam ][ #curTeams[ plyTeam ] + 1 ] = ply
    end

    pointsName = "point"
    if gameIndex == 1 then
        gamemodeName = "King Of The Hill"
    elseif gameIndex == 2 then
        gamemodeName = "Capture The Flag"
        pointsName = "flag capture"
    elseif gameIndex == 3 then
        gamemodeName = "Team Deathmatch"
        pointsName = "kill"
    end

    local timeLimit = gmMatchTime:GetInt()
    if timeLimit != 0 then
        nextTimerProgressT = ( CurTime() + 1 )
        SetGlobalInt( "LambdaTeamMatch_TimeRemaining", ( timeLimit * 60 ) )
    else
        SetGlobalInt( "LambdaTeamMatch_TimeRemaining", -1 )
    end

    LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_gamemodes_snd_gamestart", "all" )
    if gmTPToSpawns:GetBool() then
        for team, plys in pairs( curTeams ) do
            local spawnPoints = ( useSpawnpoints:GetBool() and LambdaTeams:GetSpawnPoints( team ) )

            for _, ply in ipairs( plys ) do
                if !ply:Alive() then continue end

                local spawnPos, spawnAng = ply.l_SpawnPos, ply.l_SpawnAngles
                if spawnPoints and #spawnPoints > 0 then
                    local rndSpawn = spawnPoints[ random( #spawnPoints ) ]
                    for index, point in RandomPairs( spawnPoints ) do 
                        table_remove( spawnPoints, index )

                        if !point.IsOccupied then 
                            rndSpawn = point
                            break
                        end
                    end

                    spawnPos = rndSpawn:GetPos()
                    spawnAng = rndSpawn:GetAngles()
                elseif rasp:GetBool() then
                    LambdaSpawnPoints = ( LambdaSpawnPoints or LambdaGetPossibleSpawns() )
                    if LambdaSpawnPoints and #LambdaSpawnPoints > 0 then 
                        local rndPoint = LambdaSpawnPoints[ random( #LambdaSpawnPoints ) ]
                        spawnPos = rndPoint:GetPos()
                        spawnAng = rndPoint:GetAngles()
                    end
                end

                if ply.IsLambdaPlayer then
                    ply:SetState( "Idle" )
                    ply:SetEnemy( nil )
                    ply:ResetAI()
                    ply:CancelMovement() 
                    ply.loco:SetVelocity( vector_origin )
                else
                    ply:SetVelocity( vector_origin )
                end

                ply:SetPos( spawnPos )
                ply:SetAngles( spawnAng )
            end
        end
    end

    for _, kp in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
        if !kp:GetIsCaptured() then continue end
        kp:BecomeNeutral()
    end

    timer_Create( "LambdaTeamMatch_ThinkTimer", 0.1, 0, GameMatchThinkTimer )
end

--

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_koth_startmatch", function( ply )
    StartGamemode( ply, 1 )
end, false, "Start the match of the King Of The Hill gamemode", { name = "Start KOTH Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_ctf_startmatch", function( ply )
    StartGamemode( ply, 2 )
end, false, "Start the match of the Capture The Flag gamemode", { name = "Start CTF Match", category = "Team System - Gamemodes" } )

CreateLambdaConsoleCommand( "lambdaplayers_teamsystem_tdm_startmatch", function( ply )
    StartGamemode( ply, 3, { "lambdaplayers_teamsystem_tdm_snd_10killsleft" } )
end, false, "Start the match of the Team Deathmatch gamemode", { name = "Start TDM Match", category = "Team System - Gamemodes" } )

--

CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerate", 0.2, true, false, false, "The speed rate of capturing the KOTH Points.", 0.01, 5.0, { name = "Capture Rate", type = "Slider", decimals = 2, category = "Team System - KOTH" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_scoregaintime", 5, true, false, false, "How much time should pass before the KOTH Point gives point to its team.", 0.1, 60, { name = "Score Gain Time", type = "Slider", decimals = 1, category = "Team System - KOTH" } )
local kothCapRange = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_capturerange", 500, true, false, false, "How close player should be to start capturing the point.", 100, 1000, { name = "Capture Range", type = "Slider", decimals = 0, category = "Team System - KOTH" } )

local kothIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_enabled", 1, true, true, false, "If your team's captured KOTH point should have a icon drawn on them.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - KOTH" } )
local kothIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_alwaysdraw", 0, true, true, false, "If the icon should always be drawn no matter if it's visible.", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - KOTH" } )
local kothIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - KOTH" } )
local kothIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_koth_icon_fadeinenddist", 500, true, true, false, "How close you should be from the icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - KOTH" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointcaptured", "lambdaplayers/koth/captured.mp3", true, true, false, "The sound that plays when your team has successfully captured a KOTH point.", 0, 1, { name = "Sound - On Point Capture", type = "Text", category = "Team System - KOTH" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointneutered", "lambdaplayers/koth/holdlost.mp3", true, true, false, "The sound that plays when a KOTH point has become neutral.", 0, 1, { name = "Sound - On Point Neutral", type = "Text", category = "Team System - KOTH" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointrestored", "lambdaplayers/koth/holdrestored.mp3", true, true, false, "The sound that plays when your team's KOTH point is reclaimed back from neutral.", 0, 1, { name = "Sound - On Point Reclaim", type = "Text", category = "Team System - KOTH" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_koth_snd_onpointlost", "lambdaplayers/koth/loss.mp3", true, true, false, "The sound that plays when your team's KOTH point is lost.", 0, 1, { name = "Sound - On Point Lost", type = "Text", category = "Team System - KOTH" } )

--

CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_returntime", 15, true, false, false, "The time Lambda Flag can be in dropped state before returning to its capture zone.", 0, 120, { name = "Time Before Returning", type = "Slider", decimals = 0, category = "Team System - CTF" } )

local ctfIconEnabled = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_enabled", 1, true, true, false, "If your team's dropped flag or enemy flag carried by your teammate should have a icon drawn on them.", 0, 1, { name = "Enable Icons", type = "Bool", category = "Team System - CTF" } )
local ctfIconDrawVisible = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_alwaysdraw", 0, true, true, false, "If the icon should always be drawn no matter if it's visible.", 0, 1, { name = "Always Draw Icon", type = "Bool", category = "Team System - CTF" } )
local ctfIconFadeStartDist = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_fadeinstartdist", 2000, true, true, false, "How far you should be from the icon for it to completely fade out of view.", 0, 4096, { name = "Icon Fade In Start", type = "Slider", decimals = 0, category = "Team System - CTF" } )
local ctfIconFadeEndDist = CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_icon_fadeinenddist", 500, true, true, false, "How close you should be from the icon for it to become fully visible.", 0, 4096, { name = "Icon Fade In End", type = "Slider", decimals = 0, category = "Team System - CTF" } )

CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_enemy", "lambdaplayers/ctf/flagsteal.mp3", true, true, false, "The sound that plays when your team picks up enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onpickup_ally", "lambdaplayers/ctf/ourflagstole.mp3", true, true, false, "The sound that plays when enemy team picks up your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Pickup", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_ally", "lambdaplayers/ctf/flagcapture.mp3", true, true, false, "The sound that plays when your team has captured enemy team's CTF Flag.", 0, 1, { name = "Sound - On Enemy Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_oncapture_enemy", "lambdaplayers/ctf/ourflagcaptured.mp3", true, true, false, "The sound that plays when enemy team has captured your team's CTF Flag.", 0, 1, { name = "Sound - On Ally Flag Capture", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_ondrop", "lambdaplayers/ctf/flagdropped.mp3", true, true, false, "The sound that plays when the CTF Flag is dropped.", 0, 1, { name = "Sound - On Flag Drop", type = "Text", category = "Team System - CTF" } )
CreateLambdaConvar( "lambdaplayers_teamsystem_ctf_snd_onreturn", "lambdaplayers/ctf/flagreturn.mp3", true, true, false, "The sound that plays when the CTF Flag has returned to its base.", 0, 1, { name = "Sound - On Flag Return", type = "Text", category = "Team System - CTF" } )

---

CreateLambdaConvar( "lambdaplayers_teamsystem_tdm_snd_10killsleft", "lambdaplayers/tdm/10killsleft.mp3", true, true, false, "The sound that plays when there are only 10 kills left to win.", 0, 1, { name = "Sound - 10 Kills Left", type = "Text", category = "Team System - TDM" } )

---

function LambdaTeams:GetCurrentGamemodeID()
    return GetGlobalInt( "LambdaTeamMatch_GameID", 0 )
end

function LambdaTeams:GamemodeMatchActive()
    return ( LambdaTeams:GetCurrentGamemodeID() != 0 )
end

function LambdaTeams:AreTeamsHostile()
    return ( LambdaTeams:GamemodeMatchActive() or attackOthers:GetBool() )
end

function LambdaTeams:GetTeamPoints( teamName )
    return ( GetGlobalInt( "LambdaTeamMatch_TeamPoints_" .. teamName, 0 ) )
end

function LambdaTeams:AddTeamPoints( teamName, count )
    local teamPoints = LambdaTeams.TeamPoints[ teamName ]
    if !teamPoints then
        teamPoints = "LambdaTeamMatch_TeamPoints_" .. teamName
        LambdaTeams.TeamPoints[ teamName ] = teamPoints
    end

    local newCount = ( GetGlobalInt( teamPoints, 0 ) + count )
    if LambdaTeams:GetCurrentGamemodeID() == 3 and ( GetGlobalInt( "LambdaTeamMatch_PointLimit" ) - newCount ) == 10 then
        LambdaPlayers_ChatAdd( nil, color_white, "[LTS] ", LambdaTeams:GetTeamColor( teamName, true ), teamName, color_glacier, " needs 10 more kills to win!" )
        LambdaTeams:PlayConVarSound( "lambdaplayers_teamsystem_tdm_snd_10killsleft", "all" )
    end

    SetGlobalInt( teamPoints, newCount )
end

function LambdaTeams:GetTeamColor( teamName, realColor )
    local data = LambdaTeams.TeamData[ teamName ]
    return ( data and data.color and ( !realColor and data.color or data.color:ToColor() ) )
end

function LambdaTeams:GetPlayerTeam( ply )
    if !IsValid( ply ) then return end
    local plyTeam = nil

    if ply.IsLambdaPlayer then
        if ( CLIENT ) then
            plyTeam = ply:GetNW2String( "lambda_teamname" )
            if !plyTeam or plyTeam == "" then plyTeam = ply:GetNWString( "lambda_teamname" ) end
        else
            plyTeam = ply.l_TeamName
        end
    elseif ply:IsPlayer() then
        if ( CLIENT ) then
            plyTeam = playerTeam:GetString()
        else
            plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
        end
    end

    return ( plyTeam != "" and plyTeam or nil )
end

function LambdaTeams:AreTeammates( ent, target )
    if !IsValid( ent ) or !IsValid( target ) then return end

    local entTeam = LambdaTeams:GetPlayerTeam( ent )
    if !entTeam then return end

    local targetTeam = LambdaTeams:GetPlayerTeam( target )
    if !targetTeam then return end

    return ( entTeam == targetTeam )
end

function LambdaTeams:GetTeamCount( teamName )
    local count = 0
    
    for _, ply in ipairs( ents_GetAll() ) do
        if LambdaTeams:GetPlayerTeam( ply ) == teamName and ( !ply:IsPlayer() or !ignorePlys:GetBool() ) then 
            count = count + 1 
        end
    end
    
    return count
end

function LambdaTeams:GetSpawnPoints( teamName )
    local points = {}

    for _, point in ipairs( ents_FindByClass( "lambda_teamspawnpoint" ) ) do
        if !IsValid( point ) then continue end
        
        local pointTeam = point:GetSpawnTeam()
        if pointTeam != "" and ( !teamName or pointTeam != teamName ) then continue end

        points[ #points + 1 ] = point
    end

    return points
end

---

if ( SERVER ) then

    util.AddNetworkString( "lambda_teamsystem_playclientsound" )
    util.AddNetworkString( "lambda_teamsystem_stopclientsound" )
    util.AddNetworkString( "lambda_teamsystem_setplayerteam" )
    util.AddNetworkString( "lambda_teamsystem_updatedata" )
    util.AddNetworkString( "lambda_teamsystem_sendupdateddata" )

    local GetNearestNavArea = navmesh.GetNearestNavArea
    local VectorRand = VectorRand
    local FrameTime = FrameTime
    local RandomPairs = RandomPairs
    local table_Random = table.Random
    local tobool = tobool
    local min = math.min
    local abs = math.abs
    local lower = string.lower

    local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )

    net.Receive( "lambda_teamsystem_setplayerteam", function()
        local ply = net.ReadEntity()
        if !IsValid( ply ) then return end

        local teamID = LambdaTeams.RealTeams[ net.ReadString() ]
        if teamID and teamsEnabled:GetBool() then 
            ply:SetTeam( teamID )
            ply.l_IsInLambdaTeam = true
        elseif ply.l_IsInLambdaTeam then
            ply:SetTeam( 1001 )
            ply.l_IsInLambdaTeam = false
        end
    end )

    net.Receive( "lambda_teamsystem_updatedata", function()
        LambdaTeams:UpdateData()
        net.Start( "lambda_teamsystem_sendupdateddata" ); net.Broadcast()
    end )

    function LambdaTeams:PlayConVarSound( sndCvar, targetTeam )
        net.Start( "lambda_teamsystem_playclientsound" )
            net.WriteString( targetTeam or "" )
            net.WriteString( sndCvar )
        net.Broadcast()
    end

    function LambdaTeams:StopConVarSound( sndCvar )
        net.Start( "lambda_teamsystem_stopclientsound" )
            net.WriteString( sndCvar )
        net.Broadcast()
    end

    local function OnTeamSystemDisable( name, oldVal, newVal )
        for _, ply in ipairs( ents_GetAll() ) do
            if IsValid( ply ) then
                if ply.IsLambdaPlayer then
                    local teamID = LambdaTeams.RealTeams[ ply.l_TeamName ]
                    if teamID and teamsEnabled:GetBool() and ply:GetTeam() == 0 then
                        ply:SetTeam( teamID )
                        if ply.l_TeamColor then ply:SetPlyColor( ply.l_TeamColor:ToVector() ) end
                    elseif ply:GetTeam() != 0 then
                        ply:SetTeam( 0 )
                        if ply.l_PlyNoTeamColor then ply:SetPlyColor( ply.l_PlyNoTeamColor ) end
                    end
                elseif ply:IsPlayer() then
                    local teamID = LambdaTeams.RealTeams[ ply:GetInfo( "lambdaplayers_teamsystem_playerteam" ) ]
                    if teamID and teamsEnabled:GetBool() and !ply.l_IsInLambdaTeam then
                        ply:SetTeam( teamID )
                        ply.l_IsInLambdaTeam = true
                    elseif ply.l_IsInLambdaTeam then
                        ply:SetTeam( 1001 )
                        ply.l_IsInLambdaTeam = false
                    end
                end
            end 
        end
    end
    cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_enable", modulePrefix .. "OnSystemChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_enable", OnTeamSystemDisable, modulePrefix .. "OnSystemChanged" )

    local function SetTeamToLambda( lambda, team, rndNoTeams, limit, useMdls )
        if !teamsEnabled:GetBool() then return end

        local teamTbl = LambdaTeams.TeamData
        if limit and limit > 0 then
            teamTbl = table_Copy( teamTbl )
            for name, _ in pairs( teamTbl ) do
                if LambdaTeams:GetTeamCount( name ) < limit then continue end
                teamTbl[ name ] = nil
            end
        end

        local teamData
        if team == "random" then
            if rndNoTeams then
                local teamCount = table_Count( teamTbl )
                if random( teamCount + 1 ) > teamCount then return end
            end

            teamData = table_Random( teamTbl )
        else
            teamData = teamTbl[ team ]
        end
        if !teamData then return end

        local name = teamData.name
        lambda:SetExternalVar( "l_TeamName", name )
        lambda:SetNW2String( "lambda_teamname", name )
        lambda:SetNWString( "lambda_teamname", name )

        if useMdls == nil then useMdls = true end
        if useMdls then
            local plyMdls = teamData.playermdls
            if plyMdls and #plyMdls > 0 then 
                lambda:SetModel( plyMdls[ random( #plyMdls ) ] ) 

                lambda.l_BodyGroupData = {}
                if rndBodyGroups:GetBool() then
                    for _, bg in ipairs( lambda:GetBodyGroups() ) do
                        local subMdls = #bg.submodels
                        if subMdls == 0 then continue end 

                        local rndID = random( 0, subMdls )
                        lambda:SetBodygroup( bg.id, rndID )
                        lambda.l_BodyGroupData[ bg.id ] = rndID
                    end

                    local skinCount = lambda:SkinCount()
                    if skinCount > 0 then lambda:SetSkin( random( 0, skinCount - 1 ) ) end
                end
            end
        end

        local color = teamData.color
        lambda:SetExternalVar( "l_TeamColor", color:ToColor() )
        lambda:SetPlyColor( color )
        lambda:SetNW2Vector( "lambda_teamcolor", color )
        lambda:SetNWVector( "lambda_teamcolor", color )

        local teamID = LambdaTeams.RealTeams[ name ]
        if teamID then lambda:SetTeam( teamID ) end

        lambda:SetExternalVar( "l_TeamSpawnHealth", teamData.spawnhealth )
        lambda:SetExternalVar( "l_TeamSpawnArmor", teamData.spawnarmor )
        lambda:SetExternalVar( "l_TeamVoiceProfile", teamData.voiceprofile )
        lambda:SetExternalVar( "l_TeamWepRestrictions", teamData.weaponrestrictions )
    end

    local function OnPlayerSpawnedNPC( ply, npc )
        if !npc.IsLambdaPlayer then return end
        SetTeamToLambda( npc, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), tobool( ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ), teamLimit:GetInt() )
    end

    local function LambdaOnInitialize( self )
        self.l_NextEnemyTeamSearchT = CurTime() + Rand( 0.33, 1.0 )
        self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )

        self:SimpleTimer( 0.1, function()
            if !self.l_TeamName then
                if self.l_MWSspawned then
                    self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
                    SetTeamToLambda( self, mwsTeam:GetString(), incNoTeams:GetBool(), mwsTeamLimit:GetInt() )
                else
                    local ply = self:GetCreator()
                    if IsValid( ply ) then
                        self:SetExternalVar( "l_PlyNoTeamColor", self:GetPlyColor() )
                        SetTeamToLambda( self, ply:GetInfo( "lambdaplayers_teamsystem_lambdateam" ), tobool( ply:GetInfo( "lambdaplayers_teamsystem_includenoteams" ) ), teamLimit:GetInt(), false ) 
                    end
                end

                if self.l_TeamColor then self:SetPlyColor( self.l_TeamColor:ToVector() ) end
            end

            if useSpawnpoints:GetBool() then
                local spawnPoints = LambdaTeams:GetSpawnPoints( self.l_TeamName )
                if #spawnPoints > 0 then 
                    local spawnPoint = spawnPoints[ random( #spawnPoints ) ]
                    for _, point in RandomPairs( spawnPoints ) do if !point.IsOccupied then spawnPoint = point end end
                    
                    self:SetPos( spawnPoint:GetPos() )
                    self:SetAngles( spawnPoint:GetAngles() ) 
                end
            end

            if self.l_TeamName then 
                local spawnHealth = self.l_TeamSpawnHealth
                if spawnHealth then 
                    self:SetHealth( spawnHealth )
                    if spawnHealth > self:GetMaxHealth() then self:SetMaxHealth( spawnHealth ) end
                end

                local spawnArmor = self.l_TeamSpawnArmor
                if spawnArmor then 
                    self:SetArmor( spawnArmor )
                    if spawnArmor > self:GetMaxArmor() then self:SetMaxArmor( spawnArmor ) end
                end

                local voiceProfile = self.l_TeamVoiceProfile
                if voiceProfile then 
                    self.l_VoiceProfile = voiceProfile
                    self:SetNW2String( "lambda_vp", voiceProfile )
                elseif !self.l_VoiceProfile then
                    local modelVP = LambdaModelVoiceProfiles[ lower( self:GetModel() ) ]
                    if modelVP then 
                        self.l_VoiceProfile = modelVP 
                        self:SetNW2String( "lambda_vp", modelVP )
                    end
                end

                local wepRestrictions = self.l_TeamWepRestrictions
                if wepRestrictions and !wepRestrictions[ self.l_Weapon ] then 
                    local _, rndWep = table_Random( wepRestrictions )
                    self:SwitchWeapon( rndWep )
                end
            end
        end, true )
    end

    local function LambdaPostRecreated( self )
        if !self.l_TeamName then return end
        self:SetNW2String( "lambda_teamname", self.l_TeamName )
        self:SetNWString( "lambda_teamname", self.l_TeamName )

        local teamID = LambdaTeams.RealTeams[ self.l_TeamName ]
        if teamID then self:SetTeam( teamID ) end

        if !self.l_TeamColor then return end
        self.l_TeamColor = Color( self.l_TeamColor.r, self.l_TeamColor.g, self.l_TeamColor.b )

        self:SetNW2Vector( "lambda_teamcolor", self.l_TeamColor:ToVector() )
        self:SetNWVector( "lambda_teamcolor", self.l_TeamColor:ToVector() )

        if self.l_PlyNoTeamColor and !teamsEnabled:GetBool() then
            self:SetPlyColor( self.l_PlyNoTeamColor )
        else
            self:SetPlyColor( self.l_TeamColor:ToVector() )
        end
    end

    local function LambdaOnRespawn( self )
        if !useSpawnpoints:GetBool() then return end

        local spawnPoints = LambdaTeams:GetSpawnPoints( teamName )
        if #spawnPoints == 0 then return end 
        
        local spawnPoint = spawnPoints[ random( #spawnPoints ) ]
        for _, point in RandomPairs( spawnPoints ) do if !point.IsOccupied then spawnPoint = point end end

        self:SetPos( spawnPoint:GetPos() )
        self:SetAngles( spawnPoint:GetAngles() )
    end

    local function LambdaOnThink( self, wepent, isdead )
        if isdead or !teamsEnabled:GetBool() then return end

        if CurTime() >= self.l_NextEnemyTeamSearchT then
            self.l_NextEnemyTeamSearchT = CurTime() + Rand( 0.1, 0.5 )

            local kothEnt = self.l_KOTH_Entity
            if self.l_TeamName and LambdaTeams:AreTeamsHostile() or IsValid( kothEnt ) then
                local myPos = self:WorldSpaceCenter()
                local eneDist = ( self:InCombat() and myPos:DistToSqr( self:GetEnemy():WorldSpaceCenter() ) )
                local myForward = self:GetForward()
                local dotView = ( validEnemy and 0.33 or 0.5 )

                local surroundings = self:FindInSphere( nil, 2000, function( ent )
                    if !LambdaIsValid( ent ) then return false end

                    local entPos = ent:WorldSpaceCenter()
                    local los = ( entPos - myPos ); los.z = 0
                    los:Normalize()
                    if los:Dot( myForward ) < dotView or eneDist and myPos:DistToSqr( entPos ) >= eneDist or !self:CanTarget( ent ) or !self:CanSee( ent ) then return false end

                    local areTeammates = LambdaTeams:AreTeammates( self, ent )
                    return ( areTeammates == false or areTeammates == nil and IsValid( kothEnt ) and kothEnt == ent.l_KOTH_Entity and ent:IsInRange( kothEnt, 1000 ) )
                end )

                if #surroundings > 0 then 
                    self:AttackTarget( surroundings[ random( #surroundings ) ] ) 
                end
            end
        end
    end
    
    local function LambdaCanTarget( self, ent )
        if teamsEnabled:GetBool() and LambdaTeams:AreTeammates( self, ent ) then return true end
    end

    local function LambdaOnAttackTarget( self, ent )
        if self.l_HasFlag and ent.IsLambdaPlayer and !ent.l_HasFlag and ( !ent:InCombat() or ent:GetEnemy() != self or !ent:IsInRange( self, 768 ) ) then return true end
    end

    local function LambdaOnInjured( self, dmginfo )
        local attacker = dmginfo:GetAttacker()
        if attacker == self or !LambdaTeams:AreTeammates( self, attacker ) or !teamsEnabled:GetBool() then return end
        if noFriendFire:GetBool() then return true end
    end

    local function LambdaOnOtherInjured( self, victim, dmginfo, tookDamage )
        if !tookDamage or self:InCombat() or !teamsEnabled:GetBool() then return end

        local attacker = dmginfo:GetAttacker()
        if attacker == self or !LambdaIsValid( attacker ) then return end

        if LambdaTeams:AreTeammates( self, victim ) and self:CanTarget( attacker ) and ( self:IsInRange( victim, random( 400, 700 ) ) or self:CanSee( victim ) ) then
            self:AttackTarget( attacker )
            return
        end

        if LambdaTeams:AreTeammates( self, attacker ) and self:CanTarget( victim ) and ( self:IsInRange( attacker, random( 400, 700 ) ) or self:CanSee( attacker ) ) then
            self:AttackTarget( victim )
            return 
        end
    end

    local rndMovePos = Vector()
    
    local function LambdaOnBeginMove( self, pos, onNavmesh )
        if !teamsEnabled:GetBool() then return end

        local state = self:GetState()
        if state != "Idle" and state != "FindTarget" then return end

        local kothEnt = self.l_KOTH_Entity
        if !IsValid( kothEnt ) or kothEnt:GetIsCaptured() and random( kothEnt:GetCapturerName() == kothEnt:GetCapturerTeamName( self ) and 2 or 8 ) == 1 then
            local kothEnts = ents_FindByClass( "lambda_koth_point" )
            if #kothEnts > 0 then kothEnt = kothEnts[ random( #kothEnts ) ] end
        end
        if IsValid( kothEnt ) then
            local capRange = kothCapRange:GetInt()

            local movePos
            local kothPos = kothEnt:GetPos()
            if !kothEnt:GetIsCaptured() or kothEnt:GetContesterTeam() != "" or kothEnt:GetCapturerName() != kothEnt:GetCapturerTeamName( self ) then
                rndMovePos.x = random( -150, 150 )
                rndMovePos.y = random( -150, 150 )
                movePos = ( kothPos + rndMovePos )
            else
                movePos = self:GetRandomPosition( kothPos, capRange )
            end

            self:RecomputePath( movePos )
            self:SetRun( random( 3 ) != 1 and ( !self:IsInRange( movePos, capRange ) or !self:CanSee( kothEnt ) ) )

            self.l_KOTH_Entity = kothEnt
            return
        end

        local teamName = self.l_TeamName
        if teamName then
            local ctfFlag, hasFlag = self.l_CTF_Flag, self.l_HasFlag
            if !IsValid( ctfFlag ) or hasFlag and ctfFlag:GetTeamName() != teamName or random( 3 ) == 1 then
                for _, flag in RandomPairs( ents_FindByClass( "lambda_ctf_flag" ) ) do
                    if flag == ctfFlag or !IsValid( flag ) then continue end

                    local flagTeam = flag:GetTeamName()
                    if hasFlag and flagTeam != teamName or !hasFlag and flag:GetIsCaptureZone() then continue end

                    ctfFlag = flag
                    break
                end
            end
            if IsValid( ctfFlag ) then
                local movePos
                if hasFlag or ctfFlag:GetTeamName() != teamName then
                    rndMovePos.x = random( -40, 40 )
                    rndMovePos.y = random( -40, 40 )
                    movePos = ( ( hasFlag and ctfFlag.CaptureZone or ctfFlag ):GetPos() + rndMovePos )
                    self:SetRun( true )
                else
                    if ctfFlag:GetTeamName() == teamName and ctfFlag:GetIsPickedUp() then
                        local flagHolder = ctfFlag:GetFlagHolderEnt()
                        if IsValid( flagHolder ) and self:CanTarget( flagHolder ) then
                            self:AttackTarget( flagHolder )
                            self.l_CTF_Flag = ctfFlag
                            return
                        end
                    end

                    movePos = self:GetRandomPosition( ctfFlag:GetPos(), 300 )
                    self:SetRun( !self:IsInRange( movePos, 500 ) )
                end

                self:RecomputePath( movePos )
                self.l_CTF_Flag = ctfFlag
                return
            end

            if random( 3 ) == 1 then
                local combatChance = ( self:GetCombatChance() * min( self:Health() / self:GetMaxHealth(), 1.0 ) )
                if random( 100 ) <= combatChance then
                    if huntDown:GetBool() and LambdaTeams:AreTeamsHostile() then
                        for _, ent in RandomPairs( ents_GetAll() ) do
                            if ent == self or LambdaTeams:AreTeammates( self, ent ) or !self:CanTarget( ent ) then continue end
                            local rndPos = ( self:GetRandomPosition( ent:GetPos(), random( 300, 550 ) ) )
                            self:SetRun( random( 3 ) == 1 )
                            self:RecomputePath( rndPos ); return
                        end
                    end
                elseif stickTogether:GetBool() then
                    for _, ent in RandomPairs( ents_GetAll() ) do
                        if ent == self or !LambdaTeams:AreTeammates( self, ent ) or !ent:Alive() or ent:IsPlayer() and ignorePlys:GetBool() then continue end

                        local movePos 
                        local path = self.l_CurrentPath
                        if !self:IsInRange( ent, 750 ) and IsValid( path ) then
                            movePos = ent
                            self.l_moveoptions.update = 0.2
                            path:SetGoalTolerance( 50 )
                        else
                            movePos = self:GetRandomPosition( ent:GetPos(), random( 150, 350 ) )
                        end

                        self:SetRun( random( 4 ) == 1 or !self:IsInRange( movePos, 1500 ) )                            
                        self:RecomputePath( movePos ); return
                    end
                end
            end
        end
    end

    local function LambdaCanSwitchWeapon( self, name, data )
        if !self.l_TeamName or name == "none" or name == "physgun" or !teamsEnabled:GetBool() then return end

        local teamPerms = self.l_TeamWepRestrictions
        if teamPerms and !teamPerms[ name ] then return true end
    end

    local function OnPlayerShouldTakeDamage( ply, attacker )
        if !attacker.IsLambdaPlayer or !teamsEnabled:GetBool() then return end

        local plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
        if plyTeam == "" then return end

        local attTeam = attacker.l_TeamName
        if attTeam and attTeam != "" and plyTeam == attTeam and noFriendFire:GetBool() then return false end
    end
    
    local function OnPlayerInitialSpawn( ply )
        timer_Simple( 0, function()
            local teamID = LambdaTeams.RealTeams[ ply:GetInfo( "lambdaplayers_teamsystem_playerteam" ) ]
            if teamID and teamsEnabled:GetBool() then 
                ply:SetTeam( teamID )
                ply.l_IsInLambdaTeam = true
            end
        end )
    end

    local function OnPlayerSpawn( ply, transition )
        if transition or !tobool( ply:GetInfo( "lambdaplayers_teamsystem_plyusespawnpoints" ) ) then return end

        local plyTeam = ply:GetInfo( "lambdaplayers_teamsystem_playerteam" )
        local spawnPoints = LambdaTeams:GetSpawnPoints( plyTeam == "" and nil or plyTeam )
        if #spawnPoints > 0 then 
            local spawnPoint = spawnPoints[ random( #spawnPoints ) ]
            for _, point in RandomPairs( spawnPoints ) do if !point.IsOccupied then spawnPoint = point end end

            ply:SetPos( spawnPoint:GetPos() )
            ply:SetEyeAngles( spawnPoint:GetAngles() ) 
        end
    end

    local function LambdaOnKilled( lambda, dmginfo )
        local gamemodeID = LambdaTeams:GetCurrentGamemodeID()
        if gamemodeID == 3 then
            local attackerTeam = LambdaTeams:GetPlayerTeam( dmginfo:GetAttacker() )
            if attackerTeam then LambdaTeams:AddTeamPoints( attackerTeam, 1 ) end
        end
    end

    local function OnPlayerDeath( ply, inflictor, attacker )
        local gamemodeID = LambdaTeams:GetCurrentGamemodeID()
        if gamemodeID == 3 then
            local attackerTeam = LambdaTeams:GetPlayerTeam( attacker )
            if attackerTeam then LambdaTeams:AddTeamPoints( attackerTeam, 1 ) end
        end
    end

    hook.Add( "PlayerSpawnedNPC", modulePrefix .. "OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
    hook.Add( "LambdaOnInitialize", modulePrefix .. "LambdaOnInitialize", LambdaOnInitialize )
    hook.Add( "LambdaPostRecreated", modulePrefix .. "LambdaPostRecreated", LambdaPostRecreated )
    hook.Add( "LambdaOnRespawn", modulePrefix .. "LambdaOnRespawn", LambdaOnRespawn )
    hook.Add( "LambdaOnThink", modulePrefix .. "OnThink", LambdaOnThink )
    hook.Add( "LambdaCanTarget", modulePrefix .. "OnCanTarget", LambdaCanTarget )
    hook.Add( "LambdaOnAttackTarget", modulePrefix .. "OnAttackTarget", LambdaOnAttackTarget )
    hook.Add( "LambdaOnInjured", modulePrefix .. "OnInjured", LambdaOnInjured )
    hook.Add( "LambdaOnKilled", modulePrefix .. "OnKilled", LambdaOnKilled )
    hook.Add( "LambdaOnOtherInjured", modulePrefix .. "OnOtherInjured", LambdaOnOtherInjured )
    hook.Add( "LambdaOnBeginMove", modulePrefix .. "OnBeginMove", LambdaOnBeginMove )
    hook.Add( "LambdaCanSwitchWeapon", modulePrefix .. "LambdaCanSwitchWeapon", LambdaCanSwitchWeapon )
    hook.Add( "PlayerShouldTakeDamage", modulePrefix .. "OnPlayerShouldTakeDamage", OnPlayerShouldTakeDamage )
    hook.Add( "PlayerInitialSpawn", modulePrefix .. "OnPlayerInitialSpawn", OnPlayerInitialSpawn )
    hook.Add( "PlayerSpawn", modulePrefix .. "OnPlayerSpawn", OnPlayerSpawn )
    hook.Add( "PlayerDeath", modulePrefix .. "OnPlayerDeath", OnPlayerDeath )

end

if ( CLIENT ) then

    local LocalPlayer = LocalPlayer
    local GetConVar = GetConVar
    local surface = surface
    local PlayClientSound = surface.PlaySound
    local file_Find = file.Find
    local string_Replace = string.Replace
    local string_EndsWith = string.EndsWith
    local FormattedTime = string.FormattedTime
    local SimpleTextOutlined = draw.SimpleTextOutlined
    local DrawText = draw.DrawText
    local ScrW = ScrW
    local ScrH = ScrH
    local TraceLine = util.TraceLine
    local table_IsEmpty = table.IsEmpty
    local AddHalo = halo.Add
    local LerpVector = LerpVector
    local vec_white = Vector( 1, 1, 1 )
    local CreateFont = surface.CreateFont
    local table_Add = table.Add

    local uiScale = GetConVar( "lambdaplayers_uiscale" )
    local function UpdateFont()
        CreateFont( "lambda_teamsystem_matchtimer", {
            font = "ChatFont",
            extended = false,
            size = LambdaScreenScale( 15 + uiScale:GetFloat() ),
            weight = 500,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            underline = false,
            italic = false,
            strikeout = false,
            symbol = false,
            rotary = false,
            shadow = false,
            additive = false,
            outline = false,
        } )
    end
    UpdateFont()
    cvars.AddChangeCallback( "lambdaplayers_uiscale", UpdateFont, "lambda_teamsystem_updatefonts" )

    local nameTrTbl = {}
    local hudTrTbl = { filter = function( ent ) if ent:IsWorld() then return true end end }

    local gamemodeCompetitors = {}
    local nextScoreUpdateT = 0

    local ctfFlagCircle = Material( "lambdaplayers/icon/team_flag_circle.png" )
    local kothFlagCircle = Material( "lambdaplayers/icon/team_flag_square.png" )

    local clientSnds = {}

    net.Receive( "lambda_teamsystem_playclientsound", function()
        local plyTeam = playerTeam:GetString()
        local targetTeam = net.ReadString()
        if targetTeam != "" and targetTeam != "all" and plyTeam != targetTeam then return end

        local cvarName = net.ReadString()
        if !cvarName or cvarName == "" then return end

        local cvar = GetConVar( cvarName )
        if !cvar then return end

        local sndPath = cvar:GetString()
        if sndPath == "" then return end

        if string_EndsWith( sndPath, "*" ) then
            local dirFiles = file_Find( "sound/" .. sndPath, "GAME" )
            sndPath = string_Replace( sndPath .. dirFiles[ random( #dirFiles ) ], "*", "" )
        end

        local snd = CreateSound( Entity( 0 ), sndPath )
        snd:SetSoundLevel( 0 )
        snd:Play()

        local sndList = clientSnds[ cvarName ]
        if !sndList then
            sndList = {}
            clientSnds[ cvarName ] = sndList
        end
        sndList[ #sndList + 1 ] = snd
    end )

    net.Receive( "lambda_teamsystem_stopclientsound", function()
        local cvarName = net.ReadString()
        if !cvarName or cvarName == "" then return end

        local sndList = clientSnds[ cvarName ]
        if !sndList or #sndList == 0 then return end

        for _, snd in ipairs( sndList ) do
            snd:Stop()
        end
    end )

    local function OnPlayerLambdaTeamChanged( name, oldVal, newVal )
        net.Start( "lambda_teamsystem_setplayerteam" )
            net.WriteEntity( LocalPlayer() )
            net.WriteString( newVal )
        net.SendToServer()
    end
    cvars.RemoveChangeCallback( "lambdaplayers_teamsystem_playerteam", modulePrefix .. "OnPlayerLambdaTeamChanged" )
    cvars.AddChangeCallback( "lambdaplayers_teamsystem_playerteam", OnPlayerLambdaTeamChanged, modulePrefix .. "OnPlayerLambdaTeamChanged" )

    local function GetLambdaTeamColor( self )
        local colorvec = self:GetNW2Vector( "lambda_teamcolor", false )
        if !colorvec then colorvec = self:GetNWVector( "lambda_teamcolor" ) end
        return colorvec:ToColor()
    end

    local function LambdaGetDisplayColor( self )
        local teamName = LambdaTeams:GetPlayerTeam( self )
        if teamName and teamsEnabled:GetBool() then return LambdaTeams:GetTeamColor( teamName, true ) end
    end

    local function OnPreDrawHalos()
        if !drawHalo:GetBool() or !teamsEnabled:GetBool() then return end

        local plyTeam = playerTeam:GetString()
        if plyTeam == "" then return end

        for _, ent in ipairs( GetLambdaPlayers() ) do
            local entTeam = LambdaTeams:GetPlayerTeam( ent )
            if entTeam and entTeam == plyTeam and !ent:GetIsDead() and ent:IsBeingDrawn() then
                AddHalo( { ent }, LambdaTeams:GetTeamColor( entTeam, true ), 3, 3, 1, true, false )
            end
        end
    end

    local function OnHUDPaint()
        if !teamsEnabled:GetBool() then return end
        
        local ply = LocalPlayer()
        local scrW, scrH = ScrW(), ScrH()

        local traceEnt = ply:GetEyeTrace().Entity
        if LambdaIsValid( traceEnt ) and traceEnt.IsLambdaPlayer then
            local entTeam = LambdaTeams:GetPlayerTeam( traceEnt )
            if entTeam then 
                local friendTbl = traceEnt.l_friends
                local height = ( ( friendTbl and !table_IsEmpty( friendTbl ) ) and 1.68 or 1.78 )
                
                DrawText( "Team: " .. entTeam, "lambdaplayers_displayname", ( scrW / 2 ), ( scrH / height ) + LambdaScreenScale( 1 + uiScale:GetFloat() ), LambdaTeams:GetTeamColor( entTeam, true ), TEXT_ALIGN_CENTER ) 
            end
        end

        local gamemodeID = LambdaTeams:GetCurrentGamemodeID()
        if gamemodeID != 0 then
            local timeRemain = GetGlobalInt( "LambdaTeamMatch_TimeRemaining", 0 )
            if timeRemain != -1 then
                local timeFormatted = FormattedTime( timeRemain, "%02i:%02i" )
                SimpleTextOutlined( "Time Left: " .. timeFormatted, "lambda_teamsystem_matchtimer", ( scrW / 2 ), ( scrH / 50 ) + LambdaScreenScale( 1 + uiScale:GetFloat() ), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black )
            end

            local pointsName = "Total Points"
            if gamemodeID == 2 then
                pointsName = "Flags Captured"
            elseif gamemodeID == 3 then
                pointsName = "Total Kills"
            end

            local drawWidth = ( scrW / 45 )
            local drawHeight = ( ( scrH / 2 ) + LambdaScreenScale( 1 + uiScale:GetFloat() ) )
            SimpleTextOutlined( pointsName .. ":", "ChatFont", drawWidth, ( drawHeight - 20 ), color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black )

            if CurTime() >= nextScoreUpdateT then
                table_Empty( gamemodeCompetitors )
                for _, ply in ipairs( table_Add( GetLambdaPlayers(), player_GetAll() ) ) do
                    local plyTeam = LambdaTeams:GetPlayerTeam( ply )
                    if !plyTeam or gamemodeCompetitors[ plyTeam ] then continue end

                    gamemodeCompetitors[ plyTeam ] = {
                        LambdaTeams:GetTeamPoints( plyTeam ),
                        LambdaTeams:GetTeamColor( plyTeam, true ) 
                    }
                end
                nextScoreUpdateT = ( CurTime() + 0.1 )
            end

            local scoreIndex = 0
            for teamName, teamData in pairs( gamemodeCompetitors ) do
                SimpleTextOutlined( teamName .. ": " .. teamData[ 1 ], "ChatFont", drawWidth, ( drawHeight + ( 20 * scoreIndex ) ), teamData[ 2 ], TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, color_black )
                scoreIndex = ( scoreIndex + 1 )
            end
        end

        local plyTeam = playerTeam:GetString()
        if plyTeam == "" then return end

        local eyePos = ply:EyePos()

        if drawTeamName:GetBool() then
            nameTrTbl.start = eyePos
            nameTrTbl.filter = ply

            for _, ent in ipairs( GetLambdaPlayers() ) do
                local entTeam = LambdaTeams:GetPlayerTeam( ent )
                if entTeam and entTeam == plyTeam and !ent:GetIsDead() and ent:IsBeingDrawn() then
                    local textPos = ( ent:GetPos() + ent:GetUp() * 96 )
                    nameTrTbl.endpos = textPos
                    
                    local nameTr = TraceLine( nameTrTbl )
                    if !nameTr.Hit or nameTr.Entity == ent then
                        local drawPos = textPos:ToScreen()
                        DrawText( entTeam .. "'s Member", "lambdaplayers_displayname", drawPos.x, drawPos.y, LambdaTeams:GetTeamColor( entTeam, true ), TEXT_ALIGN_CENTER )
                    end
                end
            end
        end

        if kothIconEnabled:GetBool() then
            local fadeInStart = kothIconFadeStartDist:GetInt()
            local fadeOutEnd = kothIconFadeEndDist:GetInt()
            
            for _, koth in ipairs( ents_FindByClass( "lambda_koth_point" ) ) do
                if IsValid( koth ) then
                    local iconPos = koth:WorldSpaceCenter()

                    hudTrTbl.start = eyePos
                    hudTrTbl.endpos = iconPos

                    if kothIconDrawVisible:GetBool() or TraceLine( hudTrTbl ).Hit then
                        surface.SetMaterial( kothFlagCircle )

                        local iconClr = koth:GetCapturerColor()
                        local capPerc = koth:GetCapturePercent()
                        if !koth:GetIsCaptured() then
                            iconClr = LerpVector( ( capPerc / 100 ), iconClr, koth:GetContesterColor() )
                        else
                            iconClr = LerpVector( ( ( 100 - capPerc ) / 100 ), iconClr, vec_white )
                        end

                        local drawAlpha = 0
                        local dist = eyePos:Distance( iconPos )
                        if dist < fadeInStart and dist > fadeOutEnd then
                            local norm = ( 1 / ( fadeInStart - fadeOutEnd ) * ( dist - fadeInStart ) + 1 )
                            drawAlpha = ( ( 1 - norm ) * 255 )
                        elseif dist < fadeOutEnd then
                            drawAlpha = 255
                        end
                        
                        iconClr = iconClr:ToColor()
                        surface.SetDrawColor( iconClr.r, iconClr.g, iconClr.b, drawAlpha )
                        
                        local angDiff = math.AngleDifference( ply:GetAimVector():GetNormalized():Angle().y, ( iconPos - eyePos ):GetNormalized():Angle().y )
                        if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
                        angDiff = angDiff - 90
                        
                        local offsetSize = 45
                        local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
                        local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

                        local screenPos = iconPos:ToScreen()
                        if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then 
                            screenPos.x = x
                        end
                        if screenPos.y < y or screenPos.y > scrH then 
                            screenPos.y = y 
                        elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then 
                            screenPos.y = ( scrH - y ) 
                        end

                        surface.DrawTexturedRect( screenPos.x, screenPos.y, 32, 32 )
                    end
                end
            end
        end

        if ctfIconEnabled:GetBool() then
            local fadeInStart = ctfIconFadeStartDist:GetInt()
            local fadeOutEnd = ctfIconFadeEndDist:GetInt()

            for _, flag in ipairs( ents_FindByClass( "lambda_ctf_flag" ) ) do
                if IsValid( flag ) then
					local isHome = flag:GetIsAtHome()
					if isHome or !flag:IsDormant() then
						local holder = flag:GetFlagHolderEnt()
						if holder != ply and ( !isHome and !flag:GetIsPickedUp() and flag:GetTeamName() == plyTeam or IsValid( holder ) and LambdaTeams:GetPlayerTeam( holder ) == plyTeam ) then
							local iconPos = flag:WorldSpaceCenter()

							hudTrTbl.start = eyePos
							hudTrTbl.endpos = iconPos

							if ctfIconDrawVisible:GetBool() or TraceLine( hudTrTbl ).Hit then
								surface.SetMaterial( ctfFlagCircle )

								local drawAlpha = 0
								local dist = eyePos:Distance( iconPos )
								if dist < fadeInStart and dist > fadeOutEnd then
									local norm = ( 1 / ( fadeInStart - fadeOutEnd ) * ( dist - fadeInStart ) + 1 )
									drawAlpha = ( ( 1 - norm ) * 255 )
								elseif dist < fadeOutEnd then
									drawAlpha = 255
								end

								local iconClr = flag:GetTeamColor():ToColor()
								surface.SetDrawColor( iconClr.r, iconClr.g, iconClr.b, drawAlpha )
								
								local angDiff = math.AngleDifference( ply:GetAimVector():GetNormalized():Angle().y, ( iconPos - eyePos ):GetNormalized():Angle().y )
								if angDiff < 0 then angDiff = 180 + ( angDiff + 180 ) end
								angDiff = angDiff - 90
								
								local offsetSize = 45
								local x = ( scrW / 2 ) + ( ( ( scrW - offsetSize ) / 2 ) * math.cos( math.rad( angDiff ) ) )
								local y = ( scrH / 2 ) + ( ( ( scrH - ( offsetSize * 1.4 ) ) / 2 ) * math.sin( math.rad( angDiff ) ) )

								local screenPos = iconPos:ToScreen()
								if screenPos.x < x and screenPos.x < ( scrW - x ) or screenPos.x > x and screenPos.x > ( scrW - x ) then 
									screenPos.x = x
								end
								if screenPos.y < y or screenPos.y > scrH then 
									screenPos.y = y 
								elseif screenPos.y > ( scrH - y ) and screenPos.y < scrH then 
									screenPos.y = ( scrH - y ) 
								end

								surface.DrawTexturedRect( screenPos.x, screenPos.y, 32, 32 )
							end
						end
					end
                end
            end
        end
    end

    hook.Add( "HUDPaint", modulePrefix .. "OnHUDPaint", OnHUDPaint )
    hook.Add( "PreDrawHalos", modulePrefix .. "OnPreDrawHalos", OnPreDrawHalos )
    hook.Add( "LambdaGetDisplayColor", modulePrefix .. "LambdaGetDisplayColor", LambdaGetDisplayColor )

    ---
    
    local CreateVGUI = vgui.Create
    local spairs = SortedPairs
    local DermaMenu = DermaMenu
    local table_insert = table.insert
    local AddNotification = notification.AddLegacy
    local GetAllValidPlayerModels = player_manager.AllValidModels
    local TranslateToPlayerModelName = player_manager.TranslateToPlayerModelName
    local string_len = string.len
    local Round = math.Round
    local table_Merge = table.Merge

    local function OpenLambdaTeamPanel( ply )
        if !ply:IsSuperAdmin() then 
            AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
            PlayClientSound( "buttons/button10.wav" ) 
            return 
        end

        local frame = LAMBDAPANELS:CreateFrame( "Lambda Team Editor", 550, 550 )

        local leftpanel = LAMBDAPANELS:CreateBasicPanel( frame )
        leftpanel:SetSize( 225, 200 )
        leftpanel:Dock( LEFT )

        local teamlist = CreateVGUI( "DListView", leftpanel )
        teamlist:Dock( FILL )
        teamlist:AddColumn( "Teams", 1 )

        local CompileSettings
        local ImportTeam
        local teams = {}

        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/teamlist.json", "json", function( data ) 
            if !data then return end

            table_Merge( teams, data )

            for name, data in spairs( data ) do
                local line = teamlist:AddLine( name )
                line:SetSortValue( 1, data )
            end
        end )

        local function UpdateTeamLine( teamname, newinfo )
            for _, line in ipairs( teamlist:GetLines() ) do
                local info = line:GetSortValue( 1 )
                if info.name == teamname then line:SetSortValue( 1, newinfo ) return end
            end

            local line = teamlist:AddLine( teamname )
            line:SetSortValue( 1, newinfo )
        end

        function teamlist:DoDoubleClick( id, line )
            ImportTeam( line:GetSortValue( 1 ) )
            PlayClientSound( "buttons/button15.wav" )
        end

        function teamlist:OnRowRightClick( id, line )
            local conmenu = DermaMenu( false, leftpanel )
            local info = line:GetSortValue( 1 )

            conmenu:AddOption( "Delete " .. info.name .. "?", function()
                chat.AddText( "Deleted " .. info.name .. " from the team list.")
                PlayClientSound( "buttons/button15.wav" )
                teamlist:RemoveLine( id )
                
                LAMBDAPANELS:RemoveVarFromKVFile( "lambdaplayers/teamlist.json", info.name, "json" ) 
                net.Start( "lambda_teamsystem_updatedata" ); net.SendToServer()
                net.Receive( "lambda_teamsystem_sendupdateddata", LambdaTeams.UpdateData )
            end )
            conmenu:AddOption( "Cancel", function() end )
        end

        local rightpanel = LAMBDAPANELS:CreateBasicPanel( frame, RIGHT )
        rightpanel:SetSize( 310, 200 )

        local mainscroll = LAMBDAPANELS:CreateScrollPanel( rightpanel, false, FILL )
        
        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Validate Teams", function()
            local hasissue = false
            
            for name, data in pairs( teams ) do
                local mdls = data.playermdls
                if mdls and #mdls > 0 then
                    for _, mdl in ipairs( mdls ) do
                        if file_Exists( mdl, "GAME" ) then continue end
                        hasissue = true; print( "Lambda Team Validation: Team " .. name .. " has an invalid playermodel! (" .. mdl .. ")" )
                    end
                end
            end

            chat.AddText( "Team Validation complete." .. ( hasissue and " Some issues were found. Check console for more details." or " No issues were found." ) )
        end )

        LAMBDAPANELS:CreateButton( rightpanel, BOTTOM, "Save Team", function()
            local compiledinfo = CompileSettings()
            if !compiledinfo then return end

            local alreadyexists = false
            for _, line in ipairs( teamlist:GetLines() ) do
                local info = line:GetSortValue( 1 )
                if info.name == compiledinfo.name then 
                    line:SetSortValue( 1, compiledinfo ) 
                    chat.AddText( "Edited team " .. compiledinfo.name .. "'s data." )
                    alreadyexists = true; break 
                end
            end
            if !alreadyexists then
                local line = teamlist:AddLine( compiledinfo.name )
                line:SetSortValue( 1, compiledinfo )
                chat.AddText( "Saved " .. compiledinfo.name .. " to the team list." )
            end

            PlayClientSound( "buttons/button15.wav" )
            LAMBDAPANELS:UpdateKeyValueFile( "lambdaplayers/teamlist.json", { [ compiledinfo.name ] = compiledinfo }, "json" )

            net.Start( "lambda_teamsystem_updatedata" ); net.SendToServer()
            net.Receive( "lambda_teamsystem_sendupdateddata", LambdaTeams.UpdateData )
        end )

        --

        LAMBDAPANELS:CreateLabel( "Team Name", mainscroll, TOP )
        local teamname = LAMBDAPANELS:CreateTextEntry( mainscroll, TOP, "Enter the team's name here" )

        LAMBDAPANELS:CreateLabel( "Team Color", mainscroll, TOP )
        local teamcolor = LAMBDAPANELS:CreateColorMixer( mainscroll, TOP )

        LAMBDAPANELS:CreateLabel( "Team Playermodels", mainscroll, TOP )
        local teampmlist = CreateVGUI( "DListView", mainscroll )
        teampmlist:SetSize( 250, 150 )
        teampmlist:Dock( TOP )
        teampmlist:AddColumn( "", 1 )

        function teampmlist:DoDoubleClick( id )
            teampmlist:RemoveLine( id )
            PlayClientSound( "buttons/button15.wav" )
        end

        local mdlPreviewAng = Angle()

        LAMBDAPANELS:CreateButton( mainscroll, TOP, "Add Playermodel", function()
            local modelframe = LAMBDAPANELS:CreateFrame( "Team Playermodels", 800, 500 )
            
            local modelpanel = LAMBDAPANELS:CreateBasicPanel( modelframe, RIGHT )
            modelpanel:SetSize( 350, 200 )

            local modelpreview = CreateVGUI( "DModelPanel", modelframe )
            modelpreview:SetSize( 400, 100 )
            modelpreview:Dock( LEFT )

            modelpreview:SetModel( "" )

            function modelpreview:LayoutEntity( Entity )
                mdlPreviewAng[ 2 ] = ( RealTime() * 20 % 360 )
                Entity:SetAngles( mdlPreviewAng )
            end

            local modelscroll = LAMBDAPANELS:CreateScrollPanel( modelpanel, false, FILL )
            local pmlist = CreateVGUI( "DIconLayout", modelscroll )
            pmlist:Dock( FILL )
            pmlist:SetSpaceY( 12 )
            pmlist:SetSpaceX( 12 )

            LAMBDAPANELS:CreateButton( modelpanel, BOTTOM, "Select Model", function()
                local selectedmodel = modelpreview:GetModel()

                if !selectedmodel or selectedmodel == "" then
                    AddNotification( "You didn't select any playermodel!", 1, 4 )
                    PlayClientSound( "buttons/button10.wav" )
                    return
                end
                for _, line in ipairs( teampmlist:GetLines() ) do
                    if line:GetValue( 1 ) == selectedmodel then
                        AddNotification( "Selected playermodel is already on the list!", 1, 4 )
                        PlayClientSound( "buttons/button10.wav" )
                        return
                    end
                end

                AddNotification( "Added " .. TranslateToPlayerModelName( selectedmodel ) ..  " to the playermodel list!", 0, 4 )
                PlayClientSound( "buttons/button15.wav" )

                teampmlist:AddLine( selectedmodel )
            end )

            local manualMdl = LAMBDAPANELS:CreateTextEntry( modelpanel, BOTTOM, "Enter here if you want to use a non-playermodel model" )

            function manualMdl:OnChange()
                local mdlPath = manualMdl:GetText()
                
                if file_Exists( mdlPath, "GAME" ) then
                    modelpreview:SetModel( mdlPath )
                    local mdlEnt = modelpreview:GetEntity()
                    if IsValid( mdlEnt ) then modelpreview:GetEntity().GetPlayerColor = function() return teamcolor:GetVector() end end
                end
            end

            for _, mdl in spairs( GetAllValidPlayerModels() ) do
                local modelbutton = pmlist:Add( "SpawnIcon" )
                modelbutton:SetModel( mdl )

                function modelbutton:DoClick()
                    manualMdl:SetValue( modelbutton:GetModelName() )
                    manualMdl:OnChange()
                end
            end
        end )

        local spawnhealth = LAMBDAPANELS:CreateNumSlider( mainscroll, TOP, 100, "Team Health", 1, 10000, 0 )
        local spawnarmor = LAMBDAPANELS:CreateNumSlider( mainscroll, TOP, 0, "Team Armor", 0, 10000, 0 )

        LAMBDAPANELS:CreateLabel( "Team Voice Profile", mainscroll, TOP )
        local voiceprofiletbl = { [ "No Voice Profile" ] = "/NIL" }
        for vp, _ in pairs( LambdaVoiceProfiles ) do voiceprofiletbl[ vp ] = vp end
        local voiceprofile = LAMBDAPANELS:CreateComboBox( mainscroll, TOP, voiceprofiletbl )

        local teamweaponrestrictions = {}
        LAMBDAPANELS:CreateLabel( "Team Weapon Restrictions", mainscroll, TOP )
        LAMBDAPANELS:CreateButton( mainscroll, TOP, "Edit Weapon Restrictions", function()
            local weppermframe = LAMBDAPANELS:CreateFrame( "Weapon Restrictions", 800, 400 )
            local weppermscroll = LAMBDAPANELS:CreateScrollPanel( weppermframe, true, FILL )

            LAMBDAPANELS:CreateLabel( "Here you can mark weapons that the team will only be allowed to use.", weppermframe, TOP )
            LAMBDAPANELS:CreateLabel( "Leaving all weapons un-checked will disable team weapon restrictions.", weppermframe, TOP )

            local weaponcheckboxes = {}
            for weporigin, _ in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do
                local weppermscroll2 = LAMBDAPANELS:CreateScrollPanel( weppermscroll, false, LEFT )
                weppermscroll2:SetSize( 250, 350 )
                weppermscroll:AddPanel( weppermscroll2 )

                LAMBDAPANELS:CreateLabel( "------ " .. weporigin .. " ------ ", weppermscroll2, TOP )

                local togglestate = false
                weaponcheckboxes[ weporigin ] = {}

                LAMBDAPANELS:CreateButton( weppermscroll2, TOP, "Toggle " .. weporigin .. " Weapons", function()
                    togglestate = !togglestate
                    for _, check in ipairs( weaponcheckboxes[ weporigin ] ) do
                        check[1]:SetChecked( togglestate )
                    end
                end )

                for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
                    if data.origin == weporigin and name != "none" and name != "physgun" then
                        local weprettyname = string_Replace( data.prettyname, "[" .. weporigin .. "] ", "" )
                        local weppermcheckbox = LAMBDAPANELS:CreateCheckBox( weppermscroll2, TOP, ( teamweaponrestrictions[ name ] or false ), weprettyname )
                        table_insert( weaponcheckboxes[ weporigin ], { weppermcheckbox, name } )
                    end
                end
            end

            LAMBDAPANELS:CreateButton( weppermscroll, BOTTOM, "Done", function()
                table_Empty( teamweaponrestrictions )

                for _, v in pairs( weaponcheckboxes ) do
                    for _, j in ipairs( v ) do
                        if !j[ 1 ]:GetChecked() then continue end
                        teamweaponrestrictions[ j[ 2 ] ] = true
                    end
                end

                AddNotification( "Updated team's weapon restrictions!", 0, 4 )
                PlayClientSound( "buttons/button15.wav" )

                weppermframe:Close()
            end )
        end )

        CompileSettings = function()
            local name = teamname:GetText()
            if name == "" then 
                AddNotification( "No team name is set for this team!", 1, 4 )
                PlayClientSound( "buttons/button10.wav" )
                return 
            end

            local playermdls
            local pmlist = teampmlist:GetLines()
            if #pmlist > 0 then
                playermdls = {}
                for _, list in ipairs( pmlist ) do playermdls[ #playermdls + 1 ] = list:GetValue( 1 ) end
            end

            local health = Round( spawnhealth:GetValue(), 0 )
            if health == 100 then health = nil end

            local armor = Round( spawnarmor:GetValue(), 0 )
            if armor == 0 then armor = nil end

            local _, vp = voiceprofile:GetSelected()

            local infotable = {
                name = name,
                color = teamcolor:GetVector(),
                spawnhealth = health,
                spawnarmor = armor,
                playermdls = playermdls,
                weaponrestrictions = ( !table_IsEmpty( teamweaponrestrictions ) and teamweaponrestrictions or nil ),
                voiceprofile = ( vp != "/NIL" and vp )
            }

            return infotable
        end

        ImportTeam = function( infotable )
            teamname:SetText( infotable.name or "" )
            teamcolor:SetVector( infotable.color or vec_white )
            
            spawnhealth:SetValue( infotable.spawnhealth or 100 )
            spawnarmor:SetValue( infotable.spawnarmor or 0 )

            teampmlist:Clear()
            local mdls = infotable.playermdls
            if mdls then for _, mdl in ipairs( mdls ) do teampmlist:AddLine( mdl ) end end

            local vp = infotable.voiceprofile
            voiceprofile:SelectOptionByKey( vp and vp or "/NIL" ) 

            teamweaponrestrictions = infotable.weaponrestrictions or {}
        end
    end

    RegisterLambdaPanel( "LambdaTeam", "Opens a panel that allows you to create and edit lambda teams. You must be a Super Admin to use this panel. Make sure to refresh the team list after adding or deleting a team.", OpenLambdaTeamPanel )

end
