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

Class UIP_AdminMenu extends KFGUI_MultiComponent;

var KFGUI_SwitchMenuBar PageSwitcher;
var array< class<KFGUI_Base> > Pages;

function InitMenu()
{
	local int i;
	local KFGUI_Button B;
	local string PageTitle;
	local string PageToolTip;

	PageSwitcher = KFGUI_SwitchMenuBar(FindComponentID('AdminPager'));
	Super.InitMenu();

	for (i=0; i<Pages.Length; ++i)
	{
		PageSwitcher.AddPage(Pages[i],B).InitMenu();
		switch (i)
		{
		case 0:
			PageTitle = "Player";
			PageToolTip = "Admin player and RPG stat controls";
			break;
		case 1:
			PageTitle = "Settings";
			PageToolTip = "Server, trader, wave, restriction, and tool modules";
			break;
		}
		B.ButtonText = PageTitle;
		B.ToolTip = PageToolTip;
	}
	PageSwitcher.SelectPage(1);
}

defaultproperties
{
	Pages.Add(Class'UIP_AdminPlayers')
	Pages.Add(Class'UIP_AdminSettingsDashboard')

	Begin Object Class=KFGUI_SwitchMenuBar Name=AdminMultiPager
		ID="AdminPager"
		XPosition=0.01
		YPosition=0.02
		XSize=0.98
		YSize=0.94
		BorderWidth=0.08
		ButtonAxisSize=0.16
	End Object
	Components.Add(AdminMultiPager)
}
