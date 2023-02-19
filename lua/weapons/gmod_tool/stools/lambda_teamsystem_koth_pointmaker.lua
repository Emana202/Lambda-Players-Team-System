AddCSLuaFile()

if ( CLIENT ) then

	TOOL.Information = {
		{ name = "left" },
		{ name = "right" }
	}

	language.Add( "tool.lambda_teamsystem_koth_pointmaker", "Lambda KOTH Point Maker" )
	language.Add( "tool.lambda_teamsystem_koth_pointmaker.name", "Lambda KOTH Point Maker" )
	language.Add( "tool.lambda_teamsystem_koth_pointmaker.desc", "Marks a spot for a King of the Hill point" )
	language.Add( "tool.lambda_teamsystem_koth_pointmaker.left", "Fire onto a surface to mark a KOTH spot" )
	language.Add( "tool.lambda_teamsystem_koth_pointmaker.right", "Fire near a Point to remove it" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambda_teamsystem_koth_pointmaker"
TOOL.ClientConVar = { 
	[ "pointname" ] = "",
	[ "startteam" ] = ""
}

function TOOL:LeftClick( tr )
	if ( SERVER ) then
		local kothPoint = ents.Create( "lambda_koth_point" )
		kothPoint:SetPos( tr.HitPos )
		
		local pointName = self:GetClientInfo( "pointname" )
		kothPoint.CustomName = ( pointName != "" and pointName )
		
		local startTeam = self:GetClientInfo( "startteam" )
		kothPoint.SpawnTeam = ( startTeam != "" and startTeam )
		
		kothPoint:Spawn()

		undo.Create("Lambda KOTH Point " .. pointName)
			undo.SetPlayer( self:GetOwner() )
			undo.AddEntity( kothPoint )
		undo.Finish("Lambda KOTH Point " .. pointName)

		self:GetOwner():AddCleanup( "sents", kothPoint )
    end

    return true
end

function TOOL:RightClick( tr )
	if ( SERVER ) then
		for _, ent in ipairs( ents.FindInSphere( tr.HitPos, 5 ) ) do
			if IsValid( ent ) and ent.IsLambdaKOTH then ent:Remove() end
		end
	end

	return true
end

function TOOL.BuildCPanel( panel )
	panel:TextEntry( "Point Name", "lambda_teamsystem_koth_pointmaker_pointname" )
	panel:ControlHelp( "The name of this KOTH Point. Leave empty to use default ones." )

    local combo = panel:ComboBox( "Start Team", "lambda_teamsystem_koth_pointmaker_startteam" )
    for k, v in pairs( LambdaTeams.TeamOptions ) do combo:AddChoice( k, v ) end
	panel:ControlHelp( "The team that this point should be assigned to after spawning." )

	local refresh = vgui.Create( "DButton" )
	panel:AddItem( refresh )
	refresh:SetText( "Refresh Team List" )

	function refresh:DoClick()
		combo:Clear()
		local teamData = LAMBDAFS:ReadFile( "lambdaplayers/teamlist.json", "json" )
    	teamData[ "None" ] = ""
	    for k, _ in pairs( teamData ) do combo:AddChoice( k, k ) end
	end
end