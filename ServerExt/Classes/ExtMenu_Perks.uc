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

class ExtMenu_Perks extends KFGFxMenu_Perks;

var ExtPlayerController ExtKFPC;
var Ext_PerkBase ExtPrevPerk;
var transient int DeferredOpenAttempts;

function OnOpen()
{
	KFPC = KFPlayerController(GetPC());
	if (ExtKFPC == none)
		ExtKFPC = ExtPlayerController(KFPC);

	if (ExtKFPC==None || ExtKFPC.ActivePerkManager==None)
	{
		if (ExtKFPC!=None)
			ExtKFPC.SetTimer(0.25,true,'OnOpen',Self);
		return;
	}
	ExtKFPC.ActivePerkManager.InitPerks();
	if (ExtKFPC.ActivePerkManager.CurrentPerk==None)
		ExtKFPC.ResolveZvampextClientActivePerk();
	if (ExtKFPC.ActivePerkManager.UserPerks.Length==0 || ExtKFPC.ActivePerkManager.CurrentPerk==None)
	{
		if (++DeferredOpenAttempts<40)
			ExtKFPC.SetTimer(0.25,true,'OnOpen',Self);
		`log("[ZvampPerkGFx] Waiting for lobby perk data: userPerks="$ExtKFPC.ActivePerkManager.UserPerks.Length@"current="$ExtKFPC.ActivePerkManager.CurrentPerk);
		return;
	}
	ExtKFPC.ClearTimer('OnOpen',Self);
	DeferredOpenAttempts = 0;

	if (ExtPrevPerk==None)
		ExtPrevPerk = ExtKFPC.ActivePerkManager.CurrentPerk;

	ExUpdateContainers(ExtPrevPerk);
	SetBool("locked", true);
}

final function ExUpdateContainers(Ext_PerkBase PerkClass)
{
	if (PerkClass==None || ExtKFPC==None || ExtKFPC.ActivePerkManager==None)
		return;

	LastPerkLevel = PerkClass.CurrentLevel;
	if (ExtPerksContainer_Header(HeaderContainer)!=none)
		ExtPerksContainer_Header(HeaderContainer).ExUpdatePerkHeader(PerkClass);
	if (ExtPerksContainer_Details(DetailsContainer)!=none)
	{
		ExtPerksContainer_Details(DetailsContainer).ExUpdateDetails(PerkClass);
		ExtPerksContainer_Details(DetailsContainer).ExUpdatePassives(PerkClass);
	}
	if (SelectionContainer != none)
		SelectionContainer.UpdatePerkSelection(ExtKFPC.ActivePerkManager.UserPerks.Find(PerkClass));
}

function CheckTiersForPopup();

event OnClose()
{
	ExtPrevPerk = None;
	if (ExtKFPC != none)
		ExtKFPC.ClearTimer('OnOpen',Self);
	super.OnClose();
}

function PerkChanged(byte NewPerkIndex, bool bClickedIndex)
{
	ExUpdateContainers(ExtPrevPerk);
}

function OneSecondLoop()
{
	if (ExtPrevPerk!=None && LastPerkLevel!=ExtPrevPerk.CurrentLevel)
		ExUpdateContainers(ExtPrevPerk);
}

function UpdateLock();
function SavePerkData();

function Callback_PerkSelected(byte NewPerkIndex, bool bClickedIndex)
{
	if (ExtKFPC==None || ExtKFPC.ActivePerkManager==None || NewPerkIndex>=ExtKFPC.ActivePerkManager.UserPerks.Length)
		return;

	ExtPrevPerk = ExtKFPC.ActivePerkManager.UserPerks[NewPerkIndex];
	ExUpdateContainers(ExtPrevPerk);

	ExtKFPC.PendingPerkClass = ExtPrevPerk.Class;
	ExtKFPC.SwitchToPerk(ExtPrevPerk.Class);
}

function Callback_SkillSelectionOpened();

defaultproperties
{
	SubWidgetBindings(0)=(WidgetClass=Class'ExtPerksContainer_Selection')
	SubWidgetBindings(1)=(WidgetClass=Class'ExtPerksContainer_Header')
	SubWidgetBindings(3)=(WidgetClass=Class'ExtPerksContainer_Details')
}
