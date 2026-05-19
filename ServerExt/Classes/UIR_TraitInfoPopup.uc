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

Class UIR_TraitInfoPopup extends KFGUI_FloatingWindow;

var KFGUI_TextField TraitInfo;
var KFGUI_Button YesButton;
var KFGUI_Button NoButton;

var class<Ext_TraitBase> MyTraitClass;
var Ext_TraitBase MyTrait;
var int TraitIndex;
var Ext_PerkBase MyPerk;
var int OldPoints,OldLevel;

var localized string ButtonBuyText;
var localized string ButtonBuyDisabledText;
var localized string ButtonBuyTooltip;
var localized string ButtonCancelText;
var localized string ButtonCancelTooltip;

function InitMenu()
{
	TraitInfo = KFGUI_TextField(FindComponentID('Info'));
	YesButton = KFGUI_Button(FindComponentID('Yes'));
	NoButton = KFGUI_Button(FindComponentID('No'));

	NoButton.ButtonText=ButtonCancelText;
	NoButton.Tooltip=ButtonCancelTooltip;
	YesButton.Tooltip=ButtonBuyTooltip;

	Super.InitMenu();
}

function CloseMenu()
{
	Super.CloseMenu();
	MyPerk = None;
	MyTrait = None;
	MyTraitClass = None;
	SetTimer(0,false);
}

function ShowTraitInfo(int Index, Ext_PerkBase Perk)
{
	MyTraitClass = Perk.PerkTraits[Index].TraitType;
	MyTrait = new MyTraitClass;
	WindowTitle = MyTraitClass.Default.TraitName;

	OldPoints = -1;
	OldLevel = -1;
	TraitIndex = Index;
	MyPerk = Perk;
	Timer();
	SetTimer(0.2,true);
}

function Timer()
{
	local int Cost;

	if (OldPoints!=MyPerk.CurrentSP || OldLevel!=MyPerk.PerkTraits[TraitIndex].CurrentLevel)
	{
		OldPoints = MyPerk.CurrentSP;
		OldLevel = MyPerk.PerkTraits[TraitIndex].CurrentLevel;
		UpdateTraitDescription();
		if (OldLevel>=MyTraitClass.Default.NumLevels)
		{
			YesButton.ButtonText = ButtonBuyDisabledText;
			YesButton.SetDisabled(true);
			return;
		}
		Cost = MyTraitClass.Static.GetTraitCost(OldLevel);
		YesButton.ButtonText = ButtonBuyText$" ("$Cost$")";
		if (Cost>OldPoints || !MyTraitClass.Static.MeetsRequirements(OldLevel,MyPerk))
			YesButton.SetDisabled(true);
		else YesButton.SetDisabled(false);
	}
}

final function UpdateTraitDescription()
{
	local string S;
	local int Cost;

	if (MyTrait==None || MyTraitClass==None || MyPerk==None)
		return;

	S = "Current level: #{9FF781}"$MyPerk.PerkTraits[TraitIndex].CurrentLevel$"/"$MyTraitClass.Default.NumLevels$"#{DEF}";
	S $= "|Available XP: #{F3F781}"$MyPerk.CurrentSP$"#{DEF}";
	if (MyPerk.PerkTraits[TraitIndex].CurrentLevel<MyTraitClass.Default.NumLevels)
	{
		Cost = MyTraitClass.Static.GetTraitCost(MyPerk.PerkTraits[TraitIndex].CurrentLevel);
		S $= "|Next cost: #{F3F781}"$Cost$"#{DEF}";
	}
	else S $= "|Next cost: #{9FF781}MAX#{DEF}";

	TraitInfo.SetText(S$"||"$MyTrait.GetPerkDescription());
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Yes':
		ExtPlayerController(GetPlayer()).BoughtTrait(MyPerk.Class,MyTraitClass);
		break;
	case 'No':
		DoClose();
		break;
	}
}

defaultproperties
{
	XPosition=0.31
	YPosition=0.24
	XSize=0.38
	YSize=0.46
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextField Name=TraitInfoLbl
		ID="Info"
		XPosition=0.05
		YPosition=0.12
		XSize=0.9
		YSize=0.70
	End Object
	Begin Object Class=KFGUI_Button Name=BuyButten
		ID="Yes"
		XPosition=0.18
		YPosition=0.86
		XSize=0.30
		YSize=0.09
		ExtravDir=1
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=CancelButten
		ID="No"
		XPosition=0.52
		YPosition=0.86
		XSize=0.30
		YSize=0.09
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object

	Components.Add(TraitInfoLbl)
	Components.Add(BuyButten)
	Components.Add(CancelButten)
}
