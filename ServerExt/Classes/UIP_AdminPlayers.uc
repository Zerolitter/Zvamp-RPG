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

Class UIP_AdminPlayers extends KFGUI_MultiComponent;

var KFGUI_ColumnList PlayersList;
var KFGUI_Button MotdButton;
var editinline export KFGUI_RightClickMenu PlayerContext;
var int SelectedID;

var localized string EditPlayer;
var localized string ShowDebugInfo;
var localized string Add1kXP;
var localized string Add10kXP;
var localized string AdvancePerkLevel;
var localized string SetPerkLevel;
var localized string SetPrestigeLevel;
var localized string UnloadAllStats;
var localized string UnloadAllTraits;
var localized string Remove1kXP;
var localized string Remove10kXP;
var localized string ResetAllStats;
var localized string ResetCurrentPerkStats;
var localized string ColumnPlayer;
var localized string ColumnTotalKills;
var localized string ColumnTotalExp;
var localized string ColumnTotalPlayTime;
var localized string EditMotdButtonText;
var localized string EditMotdButtonToolTip;

function string TextOrDefault(string Value, string Fallback)
{
	return (Value!="" ? Value : Fallback);
}

function FRowItem newFRowItem(string Text, int Value, bool isSplitter)
{
	local FRowItem newItem;

	newItem.Text=Text;
	newItem.Value=Value;
	newItem.bSplitter=isSplitter;

	return newItem;
}

function FColumnItem newFColumnItem(string Text, float Width)
{
	local FColumnItem newItem;

	newItem.Text=Text;
	newItem.Width=Width;

	return newItem;
}

function InitMenu()
{
	PlayersList = KFGUI_ColumnList(FindComponentID('Players'));
	MotdButton = KFGUI_Button(FindComponentID('MOTD'));

	PlayerContext.ItemRows.AddItem(newFRowItem("",-1,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(ShowDebugInfo,"Debug Info"),9,false));
	PlayerContext.ItemRows.AddItem(newFRowItem("",0,true));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(Add1kXP,"+1,000 XP"),2,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(Add10kXP,"+10,000 XP"),3,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(AdvancePerkLevel,"Advance Level"),4,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(SetPerkLevel,"Set Level"),-1,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(SetPrestigeLevel,"Set Prestige"),-2,false));
	PlayerContext.ItemRows.AddItem(newFRowItem("",0,true));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(UnloadAllStats,"Unload Stats"),5,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(UnloadAllTraits,"Unload Traits"),6,false));
	PlayerContext.ItemRows.AddItem(newFRowItem("",0,true));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(Remove1kXP,"-1,000 XP"),7,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(Remove10kXP,"-10,000 XP"),8,false));
	PlayerContext.ItemRows.AddItem(newFRowItem("",0,true));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(ResetAllStats,"Reset Stats"),0,false));
	PlayerContext.ItemRows.AddItem(newFRowItem(TextOrDefault(ResetCurrentPerkStats,"Reset Perk Stats"),1,false));

	PlayersList.Columns.AddItem(newFColumnItem(TextOrDefault(ColumnPlayer,"Player"),0.55));
	PlayersList.Columns.AddItem(newFColumnItem(TextOrDefault(ColumnTotalKills,"Kills"),0.15));
	PlayersList.Columns.AddItem(newFColumnItem(TextOrDefault(ColumnTotalExp,"XP"),0.15));
	PlayersList.Columns.AddItem(newFColumnItem(TextOrDefault(ColumnTotalPlayTime,"Play Time"),0.15));

	MotdButton.ButtonText=TextOrDefault(EditMotdButtonText,"Edit MOTD");
	MotdButton.Tooltip=TextOrDefault(EditMotdButtonToolTip,"Edit the server Message of the Day");

	Super.InitMenu();
}

function ShowMenu()
{
	Super.ShowMenu();
	SetTimer(2,true);
	Timer();
}

function CloseMenu()
{
	Super.CloseMenu();
	SetTimer(0,false);
}

function Timer()
{
	class'UIP_PlayerSpecs'.Static.UpdatePlayerList(PlayersList,GetPlayer().WorldInfo.GRI);
}

function SelectedRow(KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick)
{
	if (bRight || bDblClick)
	{
		PlayerContext.ItemRows[0].Text = TextOrDefault(EditPlayer,"EDIT:")$" "$Item.Columns[0];
		SelectedID = Item.Value;
		PlayerContext.OpenMenu(Self);
	}
}

function SelectedRCItem(int Index)
{
	if (Index>0 && !PlayerContext.ItemRows[Index].bSplitter)
	{
		if (PlayerContext.ItemRows[Index].Value>=0)
			ExtPlayerController(GetPlayer()).AdminRPGHandle(SelectedID,PlayerContext.ItemRows[Index].Value);
		else UI_AdminPerkLevel(Owner.OpenMenu(class'UI_AdminPerkLevel')).InitPage(SelectedID,-PlayerContext.ItemRows[Index].Value);
	}
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'MOTD':
		Owner.OpenMenu(class'UI_AdminMOTD');
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_RightClickMenu Name=PlayerContextMenu
		OnSelectedItem=SelectedRCItem
	End Object
	PlayerContext=PlayerContextMenu

	Begin Object Class=KFGUI_Button Name=EditMOTDButton
		ID="MOTD"
		XPosition=0.2
		YPosition=0.997
		XSize=0.1
		YSize=0.03
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(EditMOTDButton)

	Begin Object Class=KFGUI_ColumnList Name=PlayerList
		ID="Players"
		XPosition=0.05
		YPosition=0.05
		XSize=0.9
		YSize=0.92
		OnSelectedRow=SelectedRow
	End Object
	Components.Add(PlayerList)
}
