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

Class UI_MidGameMenu extends KFGUI_FloatingWindow;

var KFGUI_SwitchMenuBar PageSwitcher;
var array< class<KFGUI_Base> > Pages;

var KFGUI_Button AdminButton,SpectateButton,SkipTraderButton,DebugGridButton;
var KFGUI_AdminGridOverlay DebugGrid;

var transient KFGUI_Button PrevButton;
var transient int NumButtons,NumButtonRows;
var transient int DebugGridMode;
var transient bool bInitSpectate,bOldSpectate;

var localized string MapVoteButtonText;
var localized string MapVoteButtonToolTip;
var localized string SettingsButtonText;
var localized string SettingsButtonToolTip;
var localized string SkipTraderButtonText;
var localized string SkipTraderButtonToolTip;
var localized string SpectateButtonText;
var localized string SpectateButtonToolTip;
var localized string CloseButtonText;
var localized string CloseButtonToolTip;
var localized string DisconnectButtonText;
var localized string DisconnectButtonToolTip;
var localized string ExitButtonText;
var localized string ExitButtonToolTip;
var localized string JoinButtonText;
var localized string JoinButtonToolTip;

function InitMenu()
{
	local int i;
	local KFGUI_Button B;

	PageSwitcher = KFGUI_SwitchMenuBar(FindComponentID('Pager'));
	DebugGridButton = KFGUI_Button(FindComponentID('DebugGrid'));
	DebugGrid = KFGUI_AdminGridOverlay(FindComponentID('DebugGridOverlay'));
	ApplyConfiguredLayout();
	Super(KFGUI_Page).InitMenu();

	if (DebugGridButton!=None)
	{
		DebugGridButton.ButtonText = "DB";
		DebugGridButton.Tooltip = "Left-click toggles the UI layout grid. Right-click cycles grid size.";
	}

	AddMenuButton('Mapvote',MapVoteButtonText,MapVoteButtonToolTip);
	AddMenuButton('Settings',SettingsButtonText,SettingsButtonToolTip);
	SkipTraderButton = AddMenuButton('SkipTrader',SkipTraderButtonText,SkipTraderButtonToolTip);
	SpectateButton = AddMenuButton('Spectate',SpectateButtonText,SpectateButtonToolTip);
	AddMenuButton('Close',CloseButtonText,CloseButtonToolTip);
	AddMenuButton('Disconnect',DisconnectButtonText,DisconnectButtonToolTip);
	AddMenuButton('Exit',ExitButtonText,ExitButtonToolTip);

	for (i=0; i<Pages.Length; ++i)
	{
		PageSwitcher.AddPage(Pages[i],B).InitMenu();
		if (Pages[i]==Class'UIP_AdminMenu')
			AdminButton = B;
	}
}

function bool CaptureMouse()
{
	if (DebugGridButton!=None && DebugGridButton.CaptureMouse())
	{
		MouseArea = DebugGridButton;
		return true;
	}
	return Super.CaptureMouse();
}

function DrawMenu()
{
	local int XS,YS;
	local float X,Y,W,H;
	local float BackX,BackY,BackW,BackH;

	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;
	BackX = FMin(MenuLayoutFloat("BackX",0.08),0.08);
	BackY = MenuLayoutFloat("BackY",0.08);
	BackW = FMin(MenuLayoutFloat("BackW",0.80),0.80);
	BackH = FMin(MenuLayoutFloat("BackH",0.74),0.74);
	Canvas.SetDrawColor(
		MenuLayoutByte("OuterR",24),
		MenuLayoutByte("OuterG",24),
		MenuLayoutByte("OuterB",28),
		0);
	Canvas.SetPos(XS*BackX,YS*BackY);
	Owner.CurrentStyle.DrawWhiteBox(XS*BackW,YS*BackH);

	X = XS * MenuLayoutFloat("ButtonPanelX",0.12);
	Y = YS * MenuLayoutFloat("ButtonPanelY",0.89);
	W = XS * MenuLayoutFloat("ButtonPanelW",0.76);
	H = YS * FMax(MenuLayoutFloat("ButtonPanelH",0.055),0.055);
	Canvas.SetDrawColor(
		MenuLayoutByte("ButtonPanelR",84),
		MenuLayoutByte("ButtonPanelG",32),
		MenuLayoutByte("ButtonPanelB",28),
		MenuLayoutByte("ButtonPanelA",170));
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(W,H);
	Canvas.SetDrawColor(
		MenuLayoutByte("ButtonPanelRailR",12),
		MenuLayoutByte("ButtonPanelRailG",10),
		MenuLayoutByte("ButtonPanelRailB",18),
		MenuLayoutByte("ButtonPanelRailA",210));
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(W,H*0.18);
	Canvas.SetPos(X,Y+H*0.82);
	Owner.CurrentStyle.DrawWhiteBox(W,H*0.18);
	Canvas.SetDrawColor(
		MenuLayoutByte("ButtonPanelAccentR",76),
		MenuLayoutByte("ButtonPanelAccentG",50),
		MenuLayoutByte("ButtonPanelAccentB",150),
		MenuLayoutByte("ButtonPanelAccentA",220));
	Canvas.SetPos(X+W-(XS*MenuLayoutFloat("ButtonPanelAccentW",0.006)),Y);
	Owner.CurrentStyle.DrawWhiteBox(XS*MenuLayoutFloat("ButtonPanelAccentW",0.006),H);
}

function Timer()
{
	local PlayerReplicationInfo PRI;

	if (ExtPlayerController(GetPlayer()) != None && ExtPlayerController(GetPlayer()).ShouldBlockVampUIForEndMatch())
	{
		ExtPlayerController(GetPlayer()).CheckVampUIEndMatchHandoff();
		return;
	}

	PRI = GetPlayer().PlayerReplicationInfo;
	if (PRI==None)
		return;
	AdminButton.SetDisabled(!PRI.bAdmin && PRI.WorldInfo.NetMode==NM_Client);
	if (DebugGridButton!=None)
		DebugGridButton.SetDisabled(!PRI.bAdmin && PRI.WorldInfo.NetMode==NM_Client);
	SkipTraderButton.SetDisabled(!SkipTraderIsAviable(PRI));
	if (!bInitSpectate || bOldSpectate!=PRI.bOnlySpectator)
	{
		bInitSpectate = true;
		bOldSpectate = PRI.bOnlySpectator;
		SpectateButton.ButtonText = (bOldSpectate ? JoinButtonText : SpectateButtonText);
		SpectateButton.ChangeToolTip(bOldSpectate ? JoinButtonToolTip : SpectateButtonToolTip);
	}
}

function bool SkipTraderIsAviable(PlayerReplicationInfo PRI)
{
	local KFGameReplicationInfo KFGRI;
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(PRI);
	KFGRI = KFGameReplicationInfo(KFPRI.WorldInfo.GRI);

	if (KFGRI == none || KFPRI == none)
		return false;

	if (ExtPlayerController(GetPlayer())!=None
		&& ExtPlayerController(GetPlayer()).bRevampTraderGuardEnabled
		&& ExtPlayerController(GetPlayer()).bRevampTraderGuardBlockSkip
		&& !KFPRI.bAdmin)
		return false;

	return KFGRI.bMatchHasBegun && KFGRI.bTraderIsOpen && KFPRI.bHasSpawnedIn && !KFPRI.bVotedToSkipTraderTime;
}

function SelectAdminPage()
{
	local int i;

	for (i=0; i<Pages.Length; ++i)
	{
		if (Pages[i]==Class'UIP_AdminMenu')
		{
			PageSwitcher.SelectPage(i);
			return;
		}
	}
}

final function ApplyDebugGridMode()
{
	if (DebugGrid==None)
		return;

	switch (DebugGridMode)
	{
	case 1:
		DebugGrid.XPosition = 0.01;
		DebugGrid.YPosition = 0.08;
		DebugGrid.XSize = 0.98;
		DebugGrid.YSize = 0.775;
		DebugGrid.GridX = 32;
		DebugGrid.GridY = 17;
		break;
	case 2:
		DebugGrid.XPosition = 0.0;
		DebugGrid.YPosition = 0.0;
		DebugGrid.XSize = 1.0;
		DebugGrid.YSize = 0.86;
		DebugGrid.GridX = 32;
		DebugGrid.GridY = 18;
		break;
	case 3:
		DebugGrid.XPosition = -0.02;
		DebugGrid.YPosition = -0.08;
		DebugGrid.XSize = 1.04;
		DebugGrid.YSize = 1.12;
		DebugGrid.GridX = 32;
		DebugGrid.GridY = 18;
		break;
	default:
		DebugGridMode = 0;
		DebugGrid.bVisible = false;
		DebugGridButton.bIsHighlighted = false;
		return;
	}

	DebugGrid.bVisible = true;
	DebugGridButton.bIsHighlighted = true;
}

function DebugGridClicked(KFGUI_Button Sender)
{
	if (DebugGridMode==0)
		DebugGridMode = 1;
	else DebugGridMode = 0;
	ApplyDebugGridMode();
}

function DebugGridRightClicked(KFGUI_Button Sender)
{
	++DebugGridMode;
	if (DebugGridMode>3)
		DebugGridMode = 1;
	ApplyDebugGridMode();
}

function ShowMenu()
{
	if (ExtPlayerController(GetPlayer()) != None && ExtPlayerController(GetPlayer()).ShouldBlockVampUIForEndMatch())
	{
		ExtPlayerController(GetPlayer()).CheckVampUIEndMatchHandoff();
		return;
	}

	Super.ShowMenu();
	ApplyConfiguredLayout();
	AdminButton.SetDisabled(true);
	SkipTraderButton.SetDisabled(false);
	if (GetPlayer().WorldInfo.GRI!=None)
		WindowTitle = GetPlayer().WorldInfo.GRI.ServerName;

	// Update spectate button info text.
	Timer();
	SetTimer(0.5,true);
}

function CloseMenu()
{
	Super.CloseMenu();
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Mapvote':
		OpenUpMapvote();
		break;
	case 'Settings':
		DoClose();
		KFPlayerController(GetPlayer()).MyGFxManager.OpenMenu(UI_OptionsSelection);
		break;
	case 'Disconnect':
		GetPlayer().ConsoleCommand("DISCONNECT");
		break;
	case 'Close':
		DoClose();
		break;
	case 'Exit':
		GetPlayer().ConsoleCommand("EXIT");
		break;
	case 'Spectate':
		ExtPlayerController(GetPlayer()).ChangeSpectateMode(!bOldSpectate);
		DoClose();
		break;
	case 'SkipTrader':
		KFPlayerController(GetPlayer()).RequestSkipTrader();
		SkipTraderButton.SetDisabled(true);
		break;
	}
}

final function OpenUpMapvote()
{
	local xVotingReplication R;

	foreach GetPlayer().DynamicActors(class'xVotingReplication',R)
		R.ClientOpenMapvote();
}

final function KFGUI_Button AddMenuButton(name ButtonID, string Text, optional string ToolTipStr)
{
	local KFGUI_Button B;
	local float PanelY,PanelH;

	B = new (Self) class'KFGUI_ZvampFooterButton';
	B.ButtonText = Text;
	B.ToolTip = ToolTipStr;
	B.OnClickLeft = ButtonClicked;
	B.OnClickRight = ButtonClicked;
	B.ID = ButtonID;
	PanelY = MenuLayoutFloat("ButtonPanelY",0.89);
	PanelH = FMax(MenuLayoutFloat("ButtonPanelH",0.055),0.055);
	B.YSize = FMin(MenuLayoutFloat("FooterH",0.040),FMax(PanelH-0.016,0.030));
	B.YPosition = PanelY + (PanelH-B.YSize)*0.5;

	switch (ButtonID)
	{
	case 'Spectate':
		B.XPosition = MenuLayoutFloat("SpectateX",0.14);
		B.XSize = MenuLayoutFloat("SpectateW",0.12);
		break;
	case 'SkipTrader':
		B.XPosition = MenuLayoutFloat("SkipTraderX",0.27);
		B.XSize = MenuLayoutFloat("SkipTraderW",0.13);
		break;
	case 'Settings':
		B.XPosition = MenuLayoutFloat("SettingsX",0.41);
		B.XSize = MenuLayoutFloat("SettingsW",0.12);
		break;
	case 'Mapvote':
		B.XPosition = MenuLayoutFloat("MapVoteX",0.54);
		B.XSize = MenuLayoutFloat("MapVoteW",0.13);
		break;
	case 'Close':
		B.XPosition = MenuLayoutFloat("CloseX",0.68);
		B.XSize = MenuLayoutFloat("CloseW",0.09);
		break;
	case 'Disconnect':
		B.XPosition = MenuLayoutFloat("DisconnectX",0.78);
		B.XSize = MenuLayoutFloat("DisconnectW",0.12);
		break;
	case 'Exit':
		B.XPosition = MenuLayoutFloat("ExitX",0.91);
		B.XSize = MenuLayoutFloat("ExitW",0.08);
		break;
	default:
		B.XPosition = 0.05+NumButtons*0.1;
		B.XSize = 0.099;
	}

	if (NumButtons>0 && PrevButton!=None)
		PrevButton.ExtravDir = 1;
	PrevButton = B;
	if (++NumButtons>8)
	{
		++NumButtonRows;
		NumButtons = 0;
	}
	AddComponent(B);
	return B;
}

final function string GetMenuLayoutValue(string Key, string DefaultValue)
{
	local ExtPlayerController PC;
	local string Layout,Needle,Tail;
	local int i,j;

	PC = ExtPlayerController(GetPlayer());
	if (PC==None || PC.MidGameMenuLayout=="")
		return DefaultValue;

	Layout = ";"$PC.MidGameMenuLayout$";";
	Needle = ";"$Key$"=";
	i = InStr(Caps(Layout),Caps(Needle));
	if (i<0)
		return DefaultValue;

	Tail = Mid(Layout,i+Len(Needle));
	j = InStr(Tail,";");
	if (j>=0)
		Tail = Left(Tail,j);
	if (Tail=="")
		return DefaultValue;
	return Tail;
}

final function float MenuLayoutFloat(string Key, float DefaultValue)
{
	local string S;

	S = GetMenuLayoutValue(Key,"");
	if (S=="")
		return DefaultValue;
	return float(S);
}

final function byte MenuLayoutByte(string Key, byte DefaultValue)
{
	return byte(Clamp(int(MenuLayoutFloat(Key,float(DefaultValue))),0,255));
}

final function ApplyConfiguredLayout()
{
	SetPosition(
		MenuLayoutFloat("MenuX",XPosition),
		MenuLayoutFloat("MenuY",YPosition),
		MenuLayoutFloat("MenuW",XSize),
		MenuLayoutFloat("MenuH",YSize));

	if (PageSwitcher!=None)
	{
		PageSwitcher.SetPosition(
			MenuLayoutFloat("PagerX",PageSwitcher.XPosition),
			MenuLayoutFloat("PagerY",PageSwitcher.YPosition),
			MenuLayoutFloat("PagerW",PageSwitcher.XSize),
			MenuLayoutFloat("PagerH",PageSwitcher.YSize));
		PageSwitcher.BorderWidth = MenuLayoutFloat("PagerBorder",PageSwitcher.BorderWidth);
		PageSwitcher.ButtonAxisSize = MenuLayoutFloat("PagerButtonSize",PageSwitcher.ButtonAxisSize);
		PageSwitcher.BackPanelR = MenuLayoutByte("BackR",PageSwitcher.BackPanelR);
		PageSwitcher.BackPanelG = MenuLayoutByte("BackG",PageSwitcher.BackPanelG);
		PageSwitcher.BackPanelB = MenuLayoutByte("BackB",PageSwitcher.BackPanelB);
		PageSwitcher.BackPanelA = 0;
		PageSwitcher.BackPanelX = FMin(MenuLayoutFloat("BackX",PageSwitcher.BackPanelX),0.08);
		PageSwitcher.BackPanelY = MenuLayoutFloat("BackY",PageSwitcher.BackPanelY);
		PageSwitcher.BackPanelW = FMin(MenuLayoutFloat("BackW",PageSwitcher.BackPanelW),0.80);
		PageSwitcher.BackPanelH = FMin(MenuLayoutFloat("BackH",PageSwitcher.BackPanelH),0.74);
	}
}

defaultproperties
{
	WindowTitle="Zvampext"
	XPosition=0.1
	YPosition=0.1
	XSize=0.8
	YSize=0.8

	Pages.Add(Class'UIP_SpawnedPerkRebuild')
	Pages.Add(Class'UIP_Settings')
	Pages.Add(Class'UIP_News')
	Pages.Add(Class'UIP_AdminMenu')
	Pages.Add(Class'UIP_About')
	Pages.Add(Class'UIP_PlayerSpecs')

	Begin Object Class=KFGUI_SwitchMenuBar Name=MultiPager
		ID="Pager"
		XPosition=0.01
		YPosition=0.08
		XSize=0.98
		YSize=0.775
		BorderWidth=0.04
		ButtonAxisSize=0.08
	End Object

	Components.Add(MultiPager)

	Begin Object Class=KFGUI_AdminGridOverlay Name=MidGameDebugGridOverlay
		ID="DebugGridOverlay"
		XPosition=0.01
		YPosition=0.08
		XSize=0.98
		YSize=0.775
		GridY=17
	End Object
	Components.Add(MidGameDebugGridOverlay)

	Begin Object Class=KFGUI_Button_Tint Name=DebugGridButton
		ID="DebugGrid"
		XPosition=0.958
		YPosition=0.125
		XSize=0.026
		YSize=0.032
		ButtonColor=(R=24,G=24,B=30,A=1)
		HoverColor=(R=58,G=58,B=70,A=245)
		PressedColor=(R=74,G=52,B=150,A=245)
		AccentColor=(R=180,G=255,B=255,A=1)
		TextColor=(R=245,G=238,B=255,A=8)
		FontScale=0
		OnClickLeft=DebugGridClicked
		OnClickRight=DebugGridRightClicked
	End Object
	Components.Add(DebugGridButton)
}
