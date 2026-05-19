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

Class UIP_AdminTraderGuard extends KFGUI_MultiComponent;

var KFGUI_CheckBox EnableGuardBox, BlockSkipBox, PublicOpenTraderBox;
var KFGUI_Button PauseTraderButton;
var KFGUI_TextLable InfoLabel, GuardCardLabel, PublicCardLabel, TraderCardLabel;

var localized string EnableGuardText;
var localized string BlockSkipText;
var localized string PublicOpenTraderText;
var localized string ForceSkipText;
var localized string ForceSkipToolTip;
var localized string InfoText;

function string TextOrDefault(string Value, string Fallback)
{
	return (Value!="" ? Value : Fallback);
}

function InitMenu()
{
	EnableGuardBox = KFGUI_CheckBox(FindComponentID('EnableGuard'));
	BlockSkipBox = KFGUI_CheckBox(FindComponentID('BlockSkip'));
	PublicOpenTraderBox = KFGUI_CheckBox(FindComponentID('PublicOpenTrader'));
	PauseTraderButton = KFGUI_Button(FindComponentID('PauseTrader'));
	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	GuardCardLabel = KFGUI_TextLable(FindComponentID('GuardCard'));
	PublicCardLabel = KFGUI_TextLable(FindComponentID('PublicCard'));
	TraderCardLabel = KFGUI_TextLable(FindComponentID('TraderCard'));

	EnableGuardBox.LableString = TextOrDefault(EnableGuardText,"Enable TraderGuard");
	EnableGuardBox.Tooltip = TextOrDefault(EnableGuardText,"Enable TraderGuard");
	BlockSkipBox.LableString = TextOrDefault(BlockSkipText,"Block non-admin skip trader");
	BlockSkipBox.Tooltip = TextOrDefault(BlockSkipText,"Block non-admin skip trader");
	PublicOpenTraderBox.LableString = TextOrDefault(PublicOpenTraderText,"Public command: RvOpenTrader");
	PublicOpenTraderBox.Tooltip = TextOrDefault(PublicOpenTraderText,"Let non-admins use RvOpenTrader when TraderGuard allows it");
	PauseTraderButton.ButtonText = "Pause Trader Time";
	PauseTraderButton.Tooltip = "Pause trader countdown without blocking normal skip-trader voting";
	InfoLabel.SetText(TextOrDefault(InfoText,"Trader tools for keeping Endless flow under admin control."));
	GuardCardLabel.SetText("TraderGuard");
	PublicCardLabel.SetText("Public Settings");
	TraderCardLabel.SetText("Trader Controls");

	Super.InitMenu();
}

function DrawMenu()
{
	Super.DrawMenu();
	EnableGuardBox.bChecked = ExtPlayerController(GetPlayer()).bRevampTraderGuardEnabled;
	BlockSkipBox.bChecked = ExtPlayerController(GetPlayer()).bRevampTraderGuardBlockSkip;
	PublicOpenTraderBox.bChecked = ExtPlayerController(GetPlayer()).bRevampTraderGuardPublicOpenTrader;
	PauseTraderButton.SetDisabled(false);
}

function ToggleCheckBox(KFGUI_CheckBox Sender)
{
	switch (Sender.ID)
	{
	case 'EnableGuard':
		ExtPlayerController(GetPlayer()).AdminSetTraderGuard(Sender.bChecked,ExtPlayerController(GetPlayer()).bRevampTraderGuardBlockSkip,ExtPlayerController(GetPlayer()).bRevampTraderGuardPublicOpenTrader);
		break;
	case 'BlockSkip':
		ExtPlayerController(GetPlayer()).AdminSetTraderGuard(ExtPlayerController(GetPlayer()).bRevampTraderGuardEnabled,Sender.bChecked,ExtPlayerController(GetPlayer()).bRevampTraderGuardPublicOpenTrader);
		break;
	case 'PublicOpenTrader':
		ExtPlayerController(GetPlayer()).AdminSetTraderGuard(ExtPlayerController(GetPlayer()).bRevampTraderGuardEnabled,ExtPlayerController(GetPlayer()).bRevampTraderGuardBlockSkip,Sender.bChecked);
		break;
	}
}

function ButtonClicked(KFGUI_Button Sender)
{
	if (Sender.ID=='PauseTrader')
		ExtPlayerController(GetPlayer()).AdminRevampAction(24);
}

defaultproperties
{
	Begin Object Class=KFGUI_VampModuleFrame Name=TraderGuardFrame
		XPosition=0.035
		YPosition=0.18
		XSize=0.43
		YSize=0.42
	End Object
	Components.Add(TraderGuardFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=TraderControlFrame
		XPosition=0.505
		YPosition=0.18
		XSize=0.46
		YSize=0.42
	End Object
	Components.Add(TraderControlFrame)

	Begin Object Class=KFGUI_TextLable Name=TraderGuardInfo
		ID="Info"
		XPosition=0.05
		YPosition=0.08
		XSize=0.9
		YSize=0.08
		AlignX=0
		AlignY=0
	End Object
	Components.Add(TraderGuardInfo)

	Begin Object Class=KFGUI_TextLable Name=TraderGuardCard
		ID="GuardCard"
		XPosition=0.055
		YPosition=0.205
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(TraderGuardCard)

	Begin Object Class=KFGUI_CheckBox Name=EnableGuardCheckBox
		ID="EnableGuard"
		XPosition=0.055
		YPosition=0.30
		XSize=0.40
		YSize=0.05
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(EnableGuardCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=BlockSkipCheckBox
		ID="BlockSkip"
		XPosition=0.055
		YPosition=0.50
		XSize=0.40
		YSize=0.05
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(BlockSkipCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=PublicOpenTraderCheckBox
		ID="PublicOpenTrader"
		XPosition=0.525
		YPosition=0.30
		XSize=0.40
		YSize=0.05
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(PublicOpenTraderCheckBox)

	Begin Object Class=KFGUI_TextLable Name=PublicCard
		ID="PublicCard"
		XPosition=0.525
		YPosition=0.205
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(PublicCard)

	Begin Object Class=KFGUI_TextLable Name=TraderCard
		ID="TraderCard"
		XPosition=0.525
		YPosition=0.405
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(TraderCard)

	Begin Object Class=KFGUI_Button Name=PauseTraderButton
		ID="PauseTrader"
		XPosition=0.525
		YPosition=0.50
		XSize=0.30
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(PauseTraderButton)
}
