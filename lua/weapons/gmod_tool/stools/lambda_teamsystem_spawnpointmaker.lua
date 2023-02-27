AddCSLuaFile()

if ( CLIENT ) then

	TOOL.Information = {
		{ name = "left" },
		{ name = "right" }
	}

	language.Add("tool.lambda_teamsystem_spawnpointmaker", "Lambda Spawn Point Maker")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.name", "Lambda Spawn Point Maker")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.desc", "Creates a spawn point that both normal and Lambda teamed players will use to spawn and respawn")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.left", "Fire onto an empty surface to create spawn point or fire near an existing spawn point to change its team to the currenly selected one")
	language.Add("tool.lambda_teamsystem_spawnpointmaker.right", "Fire near an existing spawn point to remove it")

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambda_teamsystem_spawnpointmaker"
TOOL.ClientConVar = {
	[ "spawnteam" ] = ""
}

function TOOL:LeftClick( tr )
	local spawnTeam = self:GetClientInfo( "spawnteam" )

	if ( SERVER ) then
		local changedTeam = false
		for _, ent in ipairs( ents.FindInSphere( tr.HitPos, 5 ) ) do
			if IsValid( ent ) and ent.IsLambdaSpawnpoint then 
				ent:SetSpawnTeam( spawnTeam )
				ent:SetTeamColor( LambdaTeams:GetTeamColor( spawnTeam ) )
				changedTeam = true; break
			end
		end

		if !changedTeam then
			local spawnPoint = ents.Create( "lambda_teamspawnpoint" )
			spawnPoint:SetPos( tr.HitPos )

			local spawnAng = ( tr.StartPos - tr.HitPos ):Angle().y
			spawnPoint:SetAngles( Angle( 0, spawnAng, 0 ) )

			spawnPoint.SpawnTeam = spawnTeam

			spawnPoint:Spawn()

			local addname = ( teamName != "" and teamName or spawnPoint:GetCreationID() )
			undo.Create("Lambda Spawn Point " .. addname )
				undo.SetPlayer( self:GetOwner() )
				undo.AddEntity( spawnPoint )
			undo.Finish("Lambda Spawn Point " .. addname )

			self:GetOwner():AddCleanup( "sents", spawnPoint )
    	end
    end

    return true
end

function TOOL:RightClick(tr)
	if ( SERVER ) then
		for _, ent in ipairs( ents.FindInSphere( tr.HitPos, 5 ) ) do
			if IsValid( ent ) and ent.IsLambdaSpawnpoint then 
				ent:Remove() 
			end
		end
	end

	return true
end

function TOOL.BuildCPanel( panel )
    local combo = panel:ComboBox( "Spawn Team", "lambda_teamsystem_spawnpointmaker_spawnteam" )
    for k, v in pairs( LambdaTeams.TeamOptions ) do combo:AddChoice( k, v ) end
	panel:ControlHelp( "The team that this spawn point will belong to." )

	local refresh = vgui.Create( "DButton" )
	panel:AddItem( refresh )
	refresh:SetText( "Refresh Team List" )

	function refresh:DoClick()
		combo:Clear()
		for k, v in pairs( LambdaTeams.TeamOptions ) do combo:AddChoice( k, v ) end
	end
end