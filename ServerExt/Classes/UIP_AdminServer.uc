// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.
//
// Copyright (C) 2016-2024 The Server Extension authors and contributors
//
// Server Extension is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Server Extension is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with Server Extension. If not, see <https://www.gnu.org/licenses/>.

Class UIP_AdminServer extends KFGUI_MultiComponent;

var KFGUI_Button MotdButton, BroadcastButton, AutoMessageButton, SaveStatsButton, RestartButton;
var KFGUI_TextLable InfoLabel, ServerCardLabel, MotdCardLabel;

var localized string EditMotdButtonText;
var localized string EditMotdButtonToolTip;
var localized string SaveStatsButtonText;
var localized string SaveStatsButtonToolTip;
var localized string ServerInfoText;
var localized string BroadcastMotdButtonText;
var localized string BroadcastMotdButtonToolTip;
var localized string RestartMapButtonText;
var localized string RestartMapButtonToolTip;

function string TextOrDefault(string Value, string Fallback)
{
	return (Value!="" ? Value : Fallback);
}

function InitMenu()
{
	MotdButton = KFGUI_Button(FindComponentID('MOTD'));
	BroadcastButton = KFGUI_Button(FindComponentID('BroadcastMOTD'));
	AutoMessageButton = KFGUI_Button(FindComponentID('AutoMessage'));
	SaveStatsButton = KFGUI_Button(FindComponentID('SaveStats'));
	RestartButton = KFGUI_Button(FindComponentID('RestartMap'));
	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	ServerCardLabel = KFGUI_TextLable(FindComponentID('ServerCard'));
	MotdCardLabel = KFGUI_TextLable(FindComponentID('MotdCard'));

	MotdButton.ButtonText = TextOrDefault(EditMotdButtonText,"Edit MOTD");
	MotdButton.Tooltip = TextOrDefault(EditMotdButtonToolTip,"Edit the server Message of the Day");
	BroadcastButton.ButtonText = TextOrDefault(BroadcastMotdButtonText,"Broadcast MOTD");
	BroadcastButton.Tooltip = TextOrDefault(BroadcastMotdButtonToolTip,"Send the current Message of the Day to connected players");
	AutoMessageButton.ButtonText = "Auto Messages";
	AutoMessageButton.Tooltip = "Configure recurring colored server chat messages";
	SaveStatsButton.ButtonText = TextOrDefault(SaveStatsButtonText,"Save Stats");
	SaveStatsButton.Tooltip = TextOrDefault(SaveStatsButtonToolTip,"Save dirty RPG stats for all players");
	RestartButton.ButtonText = TextOrDefault(RestartMapButtonText,"Restart Map");
	RestartButton.Tooltip = TextOrDefault(RestartMapButtonToolTip,"Disabled until the safe KF2 restart path is verified");
	RestartButton.SetDisabled(true);
	InfoLabel.SetText(TextOrDefault(ServerInfoText,"Zvampext server dashboard for Endless RPG sessions."));
	ServerCardLabel.SetText("Server Functions");
	MotdCardLabel.SetText("Message of the Day");

	Super.InitMenu();
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'MOTD':
		Owner.OpenMenu(class'UI_AdminMOTD');
		break;
	case 'BroadcastMOTD':
		ExtPlayerController(GetPlayer()).AdminRevampAction(12);
		break;
	case 'AutoMessage':
		Owner.OpenMenu(class'UI_AdminAutoMessage');
		break;
	case 'SaveStats':
		ExtPlayerController(GetPlayer()).AdminRevampAction(10);
		break;
	case 'RestartMap':
		ExtPlayerController(GetPlayer()).AdminRevampAction(14);
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_TextLable Name=AdminServerInfo
		ID="Info"
		XPosition=0.05
		YPosition=0.08
		XSize=0.9
		YSize=0.08
		AlignX=0
		AlignY=0
	End Object
	Components.Add(AdminServerInfo)

	Begin Object Class=KFGUI_TextLable Name=AdminServerCard
		ID="ServerCard"
		XPosition=0.05
		YPosition=0.20
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(AdminServerCard)

	Begin Object Class=KFGUI_Button Name=EditMOTDButton
		ID="MOTD"
		XPosition=0.48
		YPosition=0.30
		XSize=0.24
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(EditMOTDButton)

	Begin Object Class=KFGUI_Button Name=BroadcastMOTDButton
		ID="BroadcastMOTD"
		XPosition=0.74
		YPosition=0.30
		XSize=0.24
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BroadcastMOTDButton)

	Begin Object Class=KFGUI_Button Name=AutoMessageButton
		ID="AutoMessage"
		XPosition=0.48
		YPosition=0.39
		XSize=0.24
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(AutoMessageButton)

	Begin Object Class=KFGUI_Button Name=SaveStatsButton
		ID="SaveStats"
		XPosition=0.05
		YPosition=0.30
		XSize=0.24
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(SaveStatsButton)

	Begin Object Class=KFGUI_Button Name=RestartMapButton
		ID="RestartMap"
		XPosition=0.31
		YPosition=0.30
		XSize=0.24
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(RestartMapButton)

	Begin Object Class=KFGUI_TextLable Name=AdminMotdCard
		ID="MotdCard"
		XPosition=0.48
		YPosition=0.20
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(AdminMotdCard)
}
