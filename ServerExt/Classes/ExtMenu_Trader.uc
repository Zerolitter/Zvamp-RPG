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

class ExtMenu_Trader extends KFGFxMenu_Trader;

var ExtPlayerController ExtKFPC;
var Ext_PerkBase ExLastPerkClass;
var bool bZvampextApplyingPerkChange;

function InitializeMenu(KFGFxMoviePlayer_Manager InManager)
{
	Super.InitializeMenu(InManager);
	ExtKFPC = ExtPlayerController (GetPC());
}

function int GetPerkIndex()
{
	return (ExtKFPC!=None ? ExtKFPC.GetZvampextTraderFilterIndex() : 0);
}

function UpdatePlayerInfo()
{
	if (ExtKFPC != none && PlayerInfoContainer != none)
	{
		PlayerInfoContainer.SetPerkInfo();
		PlayerInfoContainer.SetPerkList();
		if (!bZvampextApplyingPerkChange && ExtKFPC.ActivePerkManager!=None && ExtKFPC.ActivePerkManager.CurrentPerk!=ExLastPerkClass)
		{
			ExLastPerkClass = ExtKFPC.ActivePerkManager.CurrentPerk;
			ExtKFPC.SetZvampextClientTraderFilterIndex(ExtKFPC.GetZvampextActiveTraderPerkIndex());
			OnPerkChanged(GetPerkIndex());
		}

		RefreshItemComponents();
	}
}

function Callback_PerkChanged(int PerkIndex)
{
	if (ExtKFPC==None || ExtKFPC.ActivePerkManager==None || PerkIndex<0 || PerkIndex>ExtKFPC.ActivePerkManager.UserPerks.Length)
		return;

	if (bZvampextApplyingPerkChange)
		return;

	bZvampextApplyingPerkChange = true;
	if (PerkIndex==ExtKFPC.ActivePerkManager.UserPerks.Length)
	{
		ExtKFPC.SetZvampextClientTraderFilterIndex(PerkIndex);
		OnPerkChanged(PerkIndex);
		bZvampextApplyingPerkChange = false;
		RefreshItemComponents();
		return;
	}

	ExtKFPC.SetZvampextClientTraderPerkIndex(PerkIndex);
	ExtKFPC.PendingPerkClass = ExtKFPC.ActivePerkManager.UserPerks[PerkIndex].Class;
	ExtKFPC.SwitchToPerk(ExtKFPC.PendingPerkClass);
	ExLastPerkClass = ExtKFPC.ActivePerkManager.CurrentPerk;
	OnPerkChanged(PerkIndex);
	bZvampextApplyingPerkChange = false;

	if (PlayerInventoryContainer != none)
	{
		PlayerInventoryContainer.UpdateLock();
	}
	UpdatePlayerInfo();

	// Refresht he UI
	RefreshItemComponents();
}

function OnPerkChanged(int PerkIndex)
{
	if (ExtKFPC!=None && ExtKFPC.ActivePerkManager!=None
		&& PerkIndex>=0 && PerkIndex<=ExtKFPC.ActivePerkManager.UserPerks.Length)
	{
		ExtKFPC.SetZvampextClientTraderFilterIndex(PerkIndex);
	}

	Super.OnPerkChanged(PerkIndex);
	if (PlayerInfoContainer != none)
	{
		PlayerInfoContainer.SetPerkInfo();
		PlayerInfoContainer.SetPerkList();
	}
}

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="filterContainer",WidgetClass=class'KFGFxTraderContainer_Filter'))
	SubWidgetBindings.Add((WidgetName="filterContainer",WidgetClass=class'ExtTraderContainer_Filter'))
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'ExtTraderContainer_Store'))
	SubWidgetBindings.Remove((WidgetName="playerInfoContainer",WidgetClass=class'KFGFxTraderContainer_PlayerInfo'))
	SubWidgetBindings.Add((WidgetName="playerInfoContainer",WidgetClass=class'ExtTraderContainer_PlayerInfo'))
}
