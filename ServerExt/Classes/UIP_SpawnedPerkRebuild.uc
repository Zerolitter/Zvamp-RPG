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

Class UIP_SpawnedPerkRebuild extends KFGUI_MultiComponent;

var KFGUI_List PerkRail;
var KFGUI_ComponentList StatsList;
var UIR_PerkTraitList TraitsList;
var KFGUI_Button B_Reset, B_Unload, B_Prestige, B_Configure;
var KFGUI_Button TraitTabAll, TraitTabCombat, TraitTabSurvival, TraitTabUtility, TraitTabZed;
var KFGUI_Button B_GrenadePrev, B_GrenadeNext;
var KFGUI_Button StatBuyButtons[24];
var KFGUI_ZvampInvisibleHotspot XPBarHotspot;
var ExtPerkManager CurrentManager;
var Ext_PerkBase DisplayPerk;
var array<UIR_PerkStat> StatBuyers;
var bool bShowingTraits;
var int LastTraitPerkPoints, LastTraitCount;
var class<Ext_PerkBase> LastTraitPerkClass;
var class<Ext_PerkBase> LastRequestedPerkClass;
var array<string> ThanksAuthors;
var int ThanksAuthorIndex;
var float LastThanksCycleTime;
var float LastPerkReplicationRequestTime;
var name ActiveTraitCategory;

function InitMenu()
{
	local int i;

	PerkRail = KFGUI_List(FindComponentID('PerkRail'));
	StatsList = KFGUI_ComponentList(FindComponentID('Stats'));
	TraitsList = UIR_PerkTraitList(FindComponentID('Traits'));
	B_Reset = KFGUI_Button(FindComponentID('Reset'));
	B_Unload = KFGUI_Button(FindComponentID('Unload'));
	B_Prestige = KFGUI_Button(FindComponentID('Prestige'));
	B_Configure = KFGUI_Button(FindComponentID('Configure'));
	TraitTabAll = KFGUI_Button(FindComponentID('TraitTabAll'));
	TraitTabCombat = KFGUI_Button(FindComponentID('TraitTabCombat'));
	TraitTabSurvival = KFGUI_Button(FindComponentID('TraitTabSurvival'));
	TraitTabUtility = KFGUI_Button(FindComponentID('TraitTabUtility'));
	TraitTabZed = KFGUI_Button(FindComponentID('TraitTabZed'));
	B_GrenadePrev = KFGUI_Button(FindComponentID('GrenadePrev'));
	B_GrenadeNext = KFGUI_Button(FindComponentID('GrenadeNext'));
	StatBuyButtons[0] = KFGUI_Button(FindComponentID('BuyStat0'));
	StatBuyButtons[1] = KFGUI_Button(FindComponentID('BuyStat1'));
	StatBuyButtons[2] = KFGUI_Button(FindComponentID('BuyStat2'));
	StatBuyButtons[3] = KFGUI_Button(FindComponentID('BuyStat3'));
	StatBuyButtons[4] = KFGUI_Button(FindComponentID('BuyStat4'));
	StatBuyButtons[5] = KFGUI_Button(FindComponentID('BuyStat5'));
	StatBuyButtons[6] = KFGUI_Button(FindComponentID('BuyStat6'));
	StatBuyButtons[7] = KFGUI_Button(FindComponentID('BuyStat7'));
	for (i=0; i<ArrayCount(StatBuyButtons); ++i)
	{
		if (StatBuyButtons[i]==None)
		{
			StatBuyButtons[i] = New(None) class'KFGUI_ZvampPressButton';
			StatBuyButtons[i].ID = 'BuyStat';
			StatBuyButtons[i].IntIndex = i;
			StatBuyButtons[i].OnClickLeft = ButtonClicked;
			StatBuyButtons[i].OnClickRight = ButtonClicked;
			StatBuyButtons[i].SetPosition(2.0,2.0,0.01,0.01);
			Components.AddItem(StatBuyButtons[i]);
		}
	}
	XPBarHotspot = KFGUI_ZvampInvisibleHotspot(FindComponentID('XPBar'));

	B_Reset.ButtonText = "COMMIT SP";
	B_Unload.ButtonText = "UNLOAD";
	B_Prestige.ButtonText = "PRESTIGE";
	B_Configure.ButtonText = "CONFIGURE";
	TraitTabAll.ButtonText = "All";
	TraitTabCombat.ButtonText = "Combat";
	TraitTabSurvival.ButtonText = "Support";
	TraitTabUtility.ButtonText = "Utility";
	TraitTabZed.ButtonText = "Zed";
	B_Configure.ToolTip = "Configure perk-unique traits";
	B_GrenadePrev.ButtonText = "<";
	B_GrenadeNext.ButtonText = ">";
	B_GrenadePrev.ToolTip = "Grenade cycling is not wired yet";
	B_GrenadeNext.ToolTip = "Grenade cycling is not wired yet";
	ActiveTraitCategory = 'All';
	InitThanksAuthors();

	B_Reset.SetDisabled(true);
	B_Unload.SetDisabled(true);
	B_Prestige.SetDisabled(true);
	SetGrenadeButtonsVisible(false);
	SetConfigureMode(false);

	Super.InitMenu();
}

final function InitThanksAuthors()
{
	if (ThanksAuthors.Length>0)
		return;

	ThanksAuthors.AddItem("GenZmeY for ServerExt, CTI, and ZedSpawner");
	ThanksAuthors.AddItem("HickDead_ for TIM");
	ThanksAuthors.AddItem("humam2104 for CustomSyringe");
	ThanksAuthors.AddItem("[Insert Name Here] for KFStaticCameraMod");
	ThanksAuthors.AddItem("Ameisenber for WeaponizedMayhem");
	ThanksAuthors.AddItem("open-source repositories and comment sections");
	ThanksAuthors.AddItem("Zerolitter for the effort behind this rebuild");
}

function ShowMenu()
{
	Super.ShowMenu();
	SetConfigureMode(false);
	SetTimer(0.1,true);
	Timer();
}

function CloseMenu()
{
	if (DisplayPerk!=None && ExtPlayerController(GetPlayer())!=None)
		ExtPlayerController(GetPlayer()).CancelPendingStatBuys(DisplayPerk.Class);
	SetConfigureMode(false);
	Super.CloseMenu();
	SetTimer(0,false);
	CurrentManager = None;
	DisplayPerk = None;
	bShowingTraits = false;
}

function bool CaptureMouse()
{
	if (B_Configure!=None)
	{
		B_Configure.ComputeCoords();
		if (B_Configure.CaptureMouse())
		{
			MouseArea = B_Configure;
			return true;
		}
	}
	return Super.CaptureMouse();
}

function Timer()
{
	local ExtPlayerController PC;
	local ExtPlayerReplicationInfo EPRI;

	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return;
	EPRI = ExtPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if (EPRI!=None && LastRequestedPerkClass!=None && EPRI.ECurrentPerk==LastRequestedPerkClass)
		LastRequestedPerkClass = None;
	if (ThanksAuthors.Length>1 && PC.WorldInfo.TimeSeconds-LastThanksCycleTime>=3.5f)
	{
		LastThanksCycleTime = PC.WorldInfo.TimeSeconds;
		ThanksAuthorIndex = (ThanksAuthorIndex+1) % ThanksAuthors.Length;
	}

	CurrentManager = PC.ActivePerkManager;
	if (CurrentManager!=None)
	{
		if (CurrentManager.UserPerks.Length==0 || CurrentManager.CurrentPerk==None)
			CurrentManager.InitPerks();
		PerkRail.ChangeListSize(CurrentManager.UserPerks.Length);
	}

	DisplayPerk = ResolveDisplayPerk();
	if ((CurrentManager==None || CurrentManager.UserPerks.Length==0 || CurrentManager.CurrentPerk==None || DisplayPerk==None || !DisplayPerk.bPerkNetReady)
		&& PC.WorldInfo.TimeSeconds-LastPerkReplicationRequestTime>=2.f)
	{
		LastPerkReplicationRequestTime = PC.WorldInfo.TimeSeconds;
		PC.ZvampextRequestPerkReplication();
	}
	UpdateActionButtons();
	if (!bShowingTraits)
		UpdateStatsList();
	if (bShowingTraits)
		UpdateTraitsIfNeeded();
}

function DrawMenu()
{
	local float W,H,Sc,XL,YL,HeaderX,HeaderY,HeaderW,HeaderH,IconSize,BarX,BarY,BarW,BarH,XPFrac;
	local string S;
	local int PendingCost;
	local ExtPlayerController PC;

	DisplayPerk = ResolveDisplayPerk();
	W = CompPos[2];
	H = CompPos[3];

	Canvas.SetDrawColor(3,3,6,48);
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(W,H);

	Canvas.SetDrawColor(5,5,8,0);
	Canvas.SetPos(W*0.005,H*0.015);
	Owner.CurrentStyle.DrawWhiteBox(W*0.075,H*0.960);
	Canvas.SetDrawColor(11,7,22,0);
	Canvas.SetPos(W*0.005,H*0.150);
	Owner.CurrentStyle.DrawWhiteBox(W*0.900,H*0.022);

	HeaderX = W * 0.080;
	HeaderY = H * 0.015;
	HeaderW = W * 0.395;
	HeaderH = H * 0.13;

	Canvas.SetDrawColor(9,8,12,210);
	Canvas.SetPos(HeaderX,HeaderY);
	Owner.CurrentStyle.DrawWhiteBox(HeaderW,HeaderH);
	IconSize = HeaderH * 0.85;
	BarX = HeaderX+HeaderH*0.06+IconSize+HeaderH*0.10;
	BarY = HeaderY+HeaderH-7.f;
	BarW = HeaderW-(BarX-HeaderX);
	BarH = 7.f;
	Canvas.SetDrawColor(45,10,10,160);
	Canvas.SetPos(BarX,BarY);
	Owner.CurrentStyle.DrawWhiteBox(BarW,BarH);
	if (XPBarHotspot!=None)
		XPBarHotspot.SetPosition(BarX/W,BarY/H,BarW/W,BarH/H);

	if (DisplayPerk!=None && DisplayPerk.bPerkNetReady)
	{
		PC = ExtPlayerController(GetPlayer());
		if (PC!=None)
			PendingCost = PC.GetPendingStatBuyCost(DisplayPerk.Class);

		Canvas.SetDrawColor(255,255,255,255);
		Canvas.SetPos(HeaderX+HeaderH*0.06,HeaderY+HeaderH*0.075);
		Canvas.DrawRect(IconSize,IconSize,DisplayPerk.PerkIcon);

		Canvas.Font = Owner.CurrentStyle.PickFont(2,Sc);
		Canvas.SetDrawColor(245,235,255,255);
		S = DisplayPerk.PerkName;
		Canvas.SetPos(HeaderX+IconSize+HeaderH*0.16,HeaderY+HeaderH*0.12);
		Canvas.DrawText(S,,Sc,Sc);

		Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
		Canvas.SetDrawColor(218,207,238,255);
		S = "Prestige Rank: "$DisplayPerk.CurrentPrestige;
		Canvas.SetPos(HeaderX+IconSize+HeaderH*0.17,HeaderY+HeaderH*0.58);
		Canvas.DrawText(S,,Sc,Sc);

		S = "Arrange XP: "$Max(DisplayPerk.CurrentSP-PendingCost,0);
		if (PendingCost>0)
			S $= " (-"$PendingCost$")";
		Canvas.TextSize(S,XL,YL,Sc,Sc);
		Canvas.SetPos(HeaderX+HeaderW-XL-HeaderH*0.07,HeaderY+HeaderH*0.58);
		Canvas.DrawText(S,,Sc,Sc);

		Canvas.Font = Owner.CurrentStyle.PickFont(3,Sc);
		S = DisplayPerk.GetLevelString();
		Canvas.TextSize(S,XL,YL,Sc,Sc);
		Canvas.SetPos(HeaderX+HeaderW-XL-HeaderH*0.07,HeaderY+HeaderH*0.08);
		Canvas.DrawText(S,,Sc,Sc);

		XPFrac = DisplayPerk.GetProgressPercent();
		Canvas.SetDrawColor(150,16,22,235);
		Canvas.SetPos(BarX,BarY);
		Owner.CurrentStyle.DrawWhiteBox(BarW * XPFrac,BarH);
		if (XPBarHotspot!=None)
			XPBarHotspot.ChangeToolTip("XP to next level: "$Max(DisplayPerk.NextLevelEXP-DisplayPerk.CurrentEXP,0)$" ("$DisplayPerk.CurrentEXP$"/"$DisplayPerk.NextLevelEXP$")");
	}
	else
	{
		Canvas.Font = Owner.CurrentStyle.PickFont(2,Sc);
		Canvas.SetDrawColor(245,235,255,255);
		if (DisplayPerk!=None && DisplayPerk.PerkName!="")
			S = DisplayPerk.PerkName;
		else S = "PERK";
		Canvas.SetPos(HeaderX+HeaderH*0.18,HeaderY+HeaderH*0.18);
		Canvas.DrawText(S,,Sc,Sc);

		Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
		Canvas.SetDrawColor(180,166,205,255);
		S = "LOADING";
		Canvas.SetPos(HeaderX+HeaderH*0.18,HeaderY+HeaderH*0.58);
		Canvas.DrawText(S,,Sc,Sc);
	}

	if (bShowingTraits)
		DrawTraitPanel(W,H);
	else
	{
		DrawSkillsPanel(W,H);
		DrawBonusPanel(W,H);
	}
	DrawThanksBanner(W,H);
}

function ButtonClicked(KFGUI_Button Sender)
{
	local KFGUI_Page T;
	local ExtPlayerController PC;

	switch (Sender.ID)
	{
	case 'Configure':
		SetConfigureMode(!bShowingTraits);
		PlayMenuSound(MN_ClickButton);
		break;
	case 'Reset':
		if (DisplayPerk!=None)
			ExtPlayerController(GetPlayer()).CommitPendingStatBuys(DisplayPerk.Class);
		break;
	case 'Unload':
		if (DisplayPerk!=None)
		{
			PC = ExtPlayerController(GetPlayer());
			if (PC!=None && PC.GetPendingStatBuyCost(DisplayPerk.Class)>0)
			{
				PC.CancelPendingStatBuys(DisplayPerk.Class,true);
				UpdateActionButtons();
				break;
			}
			T = Owner.OpenMenu(class'UI_UnloadInfo');
			UI_UnloadInfo(T).SetupTo(DisplayPerk.Class);
		}
		break;
	case 'Prestige':
		if (DisplayPerk!=None)
		{
			T = Owner.OpenMenu(class'UI_PrestigeNote');
			UI_PrestigeNote(T).SetupTo(DisplayPerk);
		}
		break;
	case 'TraitTabAll':
		ActiveTraitCategory = 'All';
		UpdateTraitTabHighlights();
		UpdateTraits();
		break;
	case 'TraitTabCombat':
		ActiveTraitCategory = 'Combat';
		UpdateTraitTabHighlights();
		UpdateTraits();
		break;
	case 'TraitTabSurvival':
		ActiveTraitCategory = 'Support';
		UpdateTraitTabHighlights();
		UpdateTraits();
		break;
	case 'TraitTabUtility':
		ActiveTraitCategory = 'Utility';
		UpdateTraitTabHighlights();
		UpdateTraits();
		break;
	case 'TraitTabZed':
		ActiveTraitCategory = 'Zed';
		UpdateTraitTabHighlights();
		UpdateTraits();
		break;
	case 'BuyStat0':
	case 'BuyStat1':
	case 'BuyStat2':
	case 'BuyStat3':
	case 'BuyStat4':
	case 'BuyStat5':
	case 'BuyStat6':
	case 'BuyStat7':
	case 'BuyStat':
		BuyStatPoint(Sender.IntIndex);
		break;
	case 'GrenadePrev':
	case 'GrenadeNext':
		PlayMenuSound(MN_ClickButton);
		ExtPlayerController(GetPlayer()).ClientMessage("Grenade cycling is not wired yet.");
		break;
	}
}

final function DrawThanksBanner(float W, float H)
{
	local float Sc,XL,YL,X,Y,BW,BH;
	local string S;
	local KFGameReplicationInfo KFGRI;

	if (ThanksAuthors.Length==0)
		InitThanksAuthors();
	KFGRI = KFGameReplicationInfo(GetPlayer().WorldInfo.GRI);
	if (KFGRI!=None && KFGRI.bMatchHasBegun)
		return;

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	S = "Special thanks: <"$ThanksAuthors[ThanksAuthorIndex]$">";
	Canvas.TextSize(S,XL,YL,Sc,Sc);
	X = W*0.085;
	Y = H*0.985;
	BW = FMin(XL+W*0.035,W*0.84);
	BH = FMax(YL+H*0.012,H*0.035);
	Canvas.SetDrawColor(8,6,16,56);
	Canvas.SetPos(X-W*0.012,Y-H*0.006);
	Owner.CurrentStyle.DrawWhiteBox(BW,BH);
	Canvas.SetDrawColor(255,248,230,255);
	Canvas.SetPos(X,Y);
	Canvas.DrawText(S,,Sc,Sc);
}

final function SetConfigureMode(bool bShowTraits)
{
	bShowingTraits = bShowTraits;

	if (B_Configure!=None)
	{
		if (bShowingTraits)
			B_Configure.ButtonText = "BACK";
		else B_Configure.ButtonText = "CONFIGURE";
	}

	if (TraitsList==None)
		return;

	if (bShowingTraits)
	{
		TraitsList.SetPosition(0.095,0.285,0.785,0.55);
		TraitsList.OldXSize = -1.f;
		if (StatsList!=None)
		{
			StatsList.SetPosition(2.0,2.0,0.01,0.01);
			StatsList.OldXSize = -1.f;
		}
		LastTraitPerkClass = None;
		SetActionButtonsVisible(false);
		SetGrenadeButtonsVisible(false);
		SetTraitTabsVisible(true);
		UpdateTraits();
	}
	else
	{
		TraitsList.SetPosition(2.0,2.0,0.01,0.01);
		TraitsList.OldXSize = -1.f;
		if (StatsList!=None)
		{
			StatsList.SetPosition(0.085,0.235,0.370,0.555);
			StatsList.OldXSize = -1.f;
		}
		SetActionButtonsVisible(true);
		SetGrenadeButtonsVisible(false);
		SetTraitTabsVisible(false);
	}
	SetStatButtonsVisible(false);
	UpdateActionButtons();
}

final function UpdateStatsList()
{
	local int i;

	if (StatsList==None)
		return;

	if (DisplayPerk==None || !DisplayPerk.bPerkNetReady)
	{
		for (i=0; i<StatsList.ItemComponents.Length; ++i)
			if (i<StatBuyers.Length && StatBuyers[i]!=None)
				StatBuyers[i].CloseMenu();
		StatsList.ItemComponents.Length = 0;
		return;
	}

	if (StatsList.ItemComponents.Length!=DisplayPerk.PerkStats.Length)
	{
		if (StatsList.ItemComponents.Length<DisplayPerk.PerkStats.Length)
		{
			for (i=StatsList.ItemComponents.Length; i<DisplayPerk.PerkStats.Length; ++i)
			{
				if (i>=StatBuyers.Length)
				{
					StatBuyers[StatBuyers.Length] = UIR_PerkStat(StatsList.AddListComponent(class'UIR_PerkStat'));
					StatBuyers[i].StatIndex = i;
					StatBuyers[i].InitMenu();
				}
				else
				{
					StatsList.ItemComponents.Length = i+1;
					StatsList.ItemComponents[i] = StatBuyers[i];
				}
			}
		}
		else
		{
			for (i=DisplayPerk.PerkStats.Length; i<StatsList.ItemComponents.Length; ++i)
				if (i<StatBuyers.Length && StatBuyers[i]!=None)
					StatBuyers[i].CloseMenu();
			StatsList.ItemComponents.Length = DisplayPerk.PerkStats.Length;
		}
	}

	for (i=0; i<StatsList.ItemComponents.Length; ++i)
	{
		StatBuyers[i].SetActivePerk(DisplayPerk);
		StatBuyers[i].CheckBuyLimit();
	}
}

final function SetTraitTabsVisible(bool bVisible)
{
	if (TraitTabAll==None || TraitTabCombat==None || TraitTabSurvival==None || TraitTabUtility==None || TraitTabZed==None)
		return;

	if (bVisible)
	{
		TraitTabAll.SetPosition(0.350,0.235,0.090,0.040);
		TraitTabCombat.SetPosition(0.440,0.235,0.120,0.040);
		TraitTabSurvival.SetPosition(0.560,0.235,0.120,0.040);
		TraitTabUtility.SetPosition(0.680,0.235,0.110,0.040);
		TraitTabZed.SetPosition(0.790,0.235,0.090,0.040);
	}
	else
	{
		TraitTabAll.SetPosition(2.0,2.0,0.01,0.01);
		TraitTabCombat.SetPosition(2.0,2.0,0.01,0.01);
		TraitTabSurvival.SetPosition(2.0,2.0,0.01,0.01);
		TraitTabUtility.SetPosition(2.0,2.0,0.01,0.01);
		TraitTabZed.SetPosition(2.0,2.0,0.01,0.01);
	}
	UpdateTraitTabHighlights();
}

final function UpdateTraitTabHighlights()
{
	if (TraitTabAll==None)
		return;
	TraitTabAll.bIsHighlighted = (ActiveTraitCategory=='All');
	TraitTabCombat.bIsHighlighted = (ActiveTraitCategory=='Combat');
	TraitTabSurvival.bIsHighlighted = (ActiveTraitCategory=='Support');
	TraitTabUtility.bIsHighlighted = (ActiveTraitCategory=='Utility');
	TraitTabZed.bIsHighlighted = (ActiveTraitCategory=='Zed');
}

final function UpdateActionButtons()
{
	local ExtPlayerController PC;
	local bool bReady;
	local int PendingCost;

	bReady = (DisplayPerk!=None && DisplayPerk.bPerkNetReady);
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None && DisplayPerk!=None)
		PendingCost = PC.GetPendingStatBuyCost(DisplayPerk.Class);
	if (B_Reset!=None)
	{
		B_Reset.ButtonText = "COMMIT SP";
		B_Reset.ToolTip = "Commit queued skill point purchases.";
		B_Reset.SetDisabled(bShowingTraits || !bReady || PendingCost<=0);
	}
	if (B_Unload!=None)
	{
		if (PendingCost>0)
		{
			B_Unload.ButtonText = "CANCEL SP";
			B_Unload.ToolTip = "Cancel queued skill point purchases and return the SP.";
		}
		else
		{
			B_Unload.ButtonText = "UNLOAD";
			B_Unload.ToolTip = "Unload this perk's spent skill points.";
		}
		B_Unload.SetDisabled(bShowingTraits || !bReady);
	}
	if (B_Prestige!=None)
	{
		if (bShowingTraits || !bReady)
			B_Prestige.SetDisabled(true);
		else B_Prestige.SetDisabled(!DisplayPerk.CanPrestige());
	}
	if (B_Configure!=None)
		B_Configure.SetDisabled(false);
}

final function SetActionButtonsVisible(bool bVisible)
{
	if (B_Reset==None || B_Unload==None || B_Prestige==None)
		return;

	if (bVisible)
	{
		B_Reset.SetPosition(0.155,0.20,0.090,0.045);
		B_Unload.SetPosition(0.245,0.20,0.090,0.045);
		B_Prestige.SetPosition(0.335,0.20,0.090,0.045);
	}
	else
	{
		B_Reset.SetPosition(2.0,2.0,0.01,0.01);
		B_Unload.SetPosition(2.0,2.0,0.01,0.01);
		B_Prestige.SetPosition(2.0,2.0,0.01,0.01);
	}
}

final function SetGrenadeButtonsVisible(bool bVisible)
{
	if (B_GrenadePrev==None || B_GrenadeNext==None)
		return;

	B_GrenadePrev.SetDisabled(true);
	B_GrenadeNext.SetDisabled(true);
	if (bVisible)
		return;

	B_GrenadePrev.SetPosition(2.0,2.0,0.01,0.01);
	B_GrenadeNext.SetPosition(2.0,2.0,0.01,0.01);
}

final function SetStatButtonsVisible(bool bVisible)
{
	local int i;

	for (i=0; i<ArrayCount(StatBuyButtons); ++i)
	{
		if (StatBuyButtons[i]==None)
			continue;
		if (bVisible)
			continue;
		StatBuyButtons[i].SetPosition(2.0,2.0,0.01,0.01);
		StatBuyButtons[i].SetDisabled(true);
	}
}

final function BuyStatPoint(int StatIndex)
{
	local int BuyAmount;

	if (DisplayPerk==None || StatIndex<0 || StatIndex>=DisplayPerk.PerkStats.Length)
		return;

	BuyAmount = GetStatBuyAmount(StatIndex);
	if (BuyAmount>0)
		ExtPlayerController(GetPlayer()).QueuePerkStatBuy(DisplayPerk.Class,StatIndex,BuyAmount);
}

final function int GetStatBuyAmount(int StatIndex)
{
	local ExtPlayerController PC;
	local int StepAmount, RemainingValue, AffordableValue, BuyStep, PendingAmount, PendingCost, AvailableSP, CostPerValue;

	if (DisplayPerk==None || StatIndex<0 || StatIndex>=DisplayPerk.PerkStats.Length)
		return 0;

	StepAmount = Max(DisplayPerk.StatBuyStep,1);
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
	{
		PendingAmount = PC.GetPendingStatBuyAmount(DisplayPerk.Class,StatIndex);
		PendingCost = PC.GetPendingStatBuyCost(DisplayPerk.Class);
	}
	CostPerValue = Max(DisplayPerk.PerkStats[StatIndex].CostPerValue,1);
	AvailableSP = Max(DisplayPerk.CurrentSP-PendingCost,0);
	RemainingValue = Max(DisplayPerk.PerkStats[StatIndex].MaxValue-DisplayPerk.PerkStats[StatIndex].CurrentValue-PendingAmount,0);
	if (DisplayPerk.PerkStats[StatIndex].CostPerValue<=0)
		AffordableValue = RemainingValue;
	else AffordableValue = AvailableSP/CostPerValue;

	BuyStep = Min(StepAmount,RemainingValue);
	return Min(BuyStep,AffordableValue);
}

final function int GetStatBuyCost(int StatIndex)
{
	local int BuyStep, RemainingValue;

	if (DisplayPerk==None || StatIndex<0 || StatIndex>=DisplayPerk.PerkStats.Length)
		return 0;

	RemainingValue = Max(DisplayPerk.PerkStats[StatIndex].MaxValue-DisplayPerk.PerkStats[StatIndex].CurrentValue,0);
	BuyStep = Min(Max(DisplayPerk.StatBuyStep,1),RemainingValue);
	return BuyStep * Max(DisplayPerk.PerkStats[StatIndex].CostPerValue,1);
}

final function UpdateTraitsIfNeeded()
{
	if (DisplayPerk==None)
		return;
	if (LastTraitPerkClass!=DisplayPerk.Class || LastTraitPerkPoints!=DisplayPerk.CurrentSP || LastTraitCount!=DisplayPerk.PerkTraits.Length)
		UpdateTraits();
}

final function Ext_PerkBase ResolveDisplayPerk()
{
	local ExtPlayerController PC;
	local ExtPlayerReplicationInfo EPRI;
	local ExtPerkManager M;
	local int i;

	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return None;
	M = PC.ActivePerkManager;
	if (M==None)
		return None;

	if (DisplayPerk!=None)
	{
		for (i=0; i<M.UserPerks.Length; ++i)
			if (M.UserPerks[i]==DisplayPerk)
				return DisplayPerk;
	}

	EPRI = ExtPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if (EPRI!=None && EPRI.ECurrentPerk!=None)
	{
		for (i=0; i<M.UserPerks.Length; ++i)
			if (M.UserPerks[i].Class==EPRI.ECurrentPerk)
				return M.UserPerks[i];
	}
	if (M.UserPerks.Length>0)
		return M.UserPerks[0];
	return None;
}

final function DrawSkillsPanel(float W, float H)
{
	local float X,Y,PW,PH,Sc;

	X = W * 0.080;
	Y = H * 0.16;
	PW = W * 0.395;
	PH = H * 0.70;

	Canvas.SetDrawColor(34,34,38,105);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(PW,PH);
	Canvas.SetDrawColor(82,55,142,205);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(PW,4.f);
	Canvas.SetPos(X,Y+PH-4.f);
	Owner.CurrentStyle.DrawWhiteBox(PW,4.f);
	Canvas.SetPos(X+PW-4.f,Y);
	Owner.CurrentStyle.DrawWhiteBox(4.f,PH);

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	Canvas.SetDrawColor(230,220,248,255);
	Canvas.SetPos(X+8.f,Y+8.f);
	Canvas.DrawText("SKILLS",,Sc,Sc);
	Canvas.SetDrawColor(155,140,190,165);
	Canvas.SetPos(X+8.f,Y+44.f);
	Owner.CurrentStyle.DrawWhiteBox(PW*0.92,1.f);

	if (DisplayPerk==None || !DisplayPerk.bPerkNetReady)
	{
		SetStatButtonsVisible(false);
		DrawPerkLoadingLine(X+14.f,Y+62.f);
		return;
	}
}

final function DrawBonusPanel(float W, float H)
{
	local float X,Y,PW,PH,Sc,RowY,ColX[2],LineH,TextX,SurvY;
	local int i,Col,Row,MaxRows,BonusCount;
	local string S;

	X = W * 0.50;
	Y = H * 0.16;
	PW = W * 0.405;
	PH = H * 0.70;

	Canvas.SetDrawColor(34,34,38,90);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(PW,PH);
	Canvas.SetDrawColor(82,55,142,205);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(PW,4.f);
	Canvas.SetPos(X,Y+PH-4.f);
	Owner.CurrentStyle.DrawWhiteBox(PW,4.f);
	Canvas.SetPos(X, Y);
	Owner.CurrentStyle.DrawWhiteBox(4.f,PH);
	Canvas.SetPos(X+PW-4.f,Y);
	Owner.CurrentStyle.DrawWhiteBox(4.f,PH);

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	Canvas.SetDrawColor(230,220,248,255);
	Canvas.SetPos(X+18.f,Y+10.f);
	Canvas.DrawText("PERK BONUSES",,Sc,Sc);

	Canvas.SetDrawColor(155,140,190,165);
	Canvas.SetPos(X+18.f,Y+34.f);
	Owner.CurrentStyle.DrawWhiteBox(PW*0.30,1.f);

	if (DisplayPerk==None || !DisplayPerk.bPerkNetReady)
	{
		SetGrenadeButtonsVisible(false);
		DrawPerkLoadingLine(X+18.f,Y+54.f);
		return;
	}

	SetGrenadeButtonsVisible(false);
	ColX[0] = X + 34.f;
	ColX[1] = X + PW * 0.50;
	LineH = FMax((PH * 0.28) / 5.f,18.f);
	MaxRows = 10;
	BonusCount = 0;

	for (i=0; i<DisplayPerk.PerkStats.Length && BonusCount<MaxRows; ++i)
	{
		if (IsSurvivabilityBonusStat(DisplayPerk.PerkStats[i].StatType))
			continue;

		Col = BonusCount / 5;
		Row = BonusCount % 5;
		RowY = Y + 46.f + Row * LineH;
		TextX = ColX[Col];
		S = GetBonusStatLine(i);
		Canvas.SetDrawColor(232,224,242,245);
		Canvas.SetPos(TextX,RowY);
		Canvas.DrawText(S,,Sc,Sc);
		++BonusCount;
	}

	SurvY = Y + PH*0.49;
	Canvas.SetDrawColor(82,55,142,205);
	Canvas.SetPos(X,SurvY);
	Owner.CurrentStyle.DrawWhiteBox(PW,3.f);

	Canvas.SetDrawColor(230,220,248,255);
	Canvas.SetPos(X+18.f,SurvY+12.f);
	Canvas.DrawText("SURVIVABILITY",,Sc,Sc);
	Canvas.SetDrawColor(155,140,190,165);
	Canvas.SetPos(X+18.f,SurvY+36.f);
	Owner.CurrentStyle.DrawWhiteBox(PW*0.34,1.f);

	DrawSurvivabilityLine(X+34.f,SurvY+42.f,"Health",FindStatEffect('Health',true));
	DrawSurvivabilityLine(X+PW*0.50,SurvY+42.f,"Armor",FindStatEffect('Armor',true));
	DrawElementalReductionLine(X+34.f,SurvY+66.f);
	DrawDamageReductionLine(X+PW*0.50,SurvY+66.f);
}

final function DrawSurvivabilityLine(float X, float Y, string Label, float Value)
{
	local float Sc;
	local string S;

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	S = Label$": "$ChopExtraDigits(Value)$"%";
	Canvas.SetDrawColor(232,224,242,245);
	Canvas.SetPos(X,Y);
	Canvas.DrawText(S,,Sc,Sc);
}

final function bool IsSurvivabilityBonusStat(name StatType)
{
	switch (StatType)
	{
	case 'Health':
	case 'Armor':
	case 'KnockDown':
	case 'AllDmg':
	case 'BossDamageReduction':
	case 'EliteDamageReduction':
		return true;
	}
	return false;
}

final function DrawElementalReductionLine(float X, float Y)
{
	local float Sc;
	local string S;

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	S = "Fire "$ChopExtraDigits(FindStatEffect('FireDmg',true))$"%";
	S = S$", Sonic "$ChopExtraDigits(FindStatEffect('SonicDmg',true))$"%";
	Canvas.SetDrawColor(232,224,242,245);
	Canvas.SetPos(X,Y);
	Canvas.DrawText(S,,Sc,Sc);
	S = "Poison "$ChopExtraDigits(FindStatEffect('PoisonDmg',true))$"%";
	Canvas.SetPos(X,Y+20.f);
	Canvas.DrawText(S,,Sc,Sc);
}

final function DrawDamageReductionLine(float X, float Y)
{
	local float Sc;
	local string S;

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	S = "Zed "$ChopExtraDigits(FindStatEffect('AllDmg',true))$"%";
	S = S$", Boss "$ChopExtraDigits(FindStatEffect('BossDamageReduction',true))$"%";
	Canvas.SetDrawColor(232,224,242,245);
	Canvas.SetPos(X,Y);
	Canvas.DrawText(S,,Sc,Sc);
	S = "Elite "$ChopExtraDigits(FindStatEffect('EliteDamageReduction',true))$"%";
	Canvas.SetPos(X,Y+20.f);
	Canvas.DrawText(S,,Sc,Sc);
}

final function DrawPerkLoadingLine(float X, float Y)
{
	local float Sc;

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	Canvas.SetDrawColor(180,166,205,230);
	Canvas.SetPos(X,Y);
	Canvas.DrawText("Loading perk data...",,Sc,Sc);
}

final function DrawTraitPanel(float W, float H)
{
	local float X,Y,PW,PH,Sc;

	X = W * 0.080;
	Y = H * 0.18;
	PW = W * 0.825;
	PH = H * 0.67;

	Canvas.SetDrawColor(34,34,38,105);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(PW,PH);
	Canvas.SetDrawColor(82,55,142,205);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(PW,4.f);
	Canvas.SetPos(X,Y+PH-4.f);
	Owner.CurrentStyle.DrawWhiteBox(PW,4.f);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(4.f,PH);
	Canvas.SetPos(X+PW-4.f,Y);
	Owner.CurrentStyle.DrawWhiteBox(4.f,PH);

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	Canvas.SetDrawColor(230,220,248,255);
	Canvas.SetPos(X+12.f,Y+10.f);
	Canvas.DrawText("TRAITS",,Sc,Sc);

	Canvas.SetDrawColor(155,140,190,165);
	Canvas.SetPos(X+12.f,Y+34.f);
	Owner.CurrentStyle.DrawWhiteBox(PW*0.18,1.f);
}

function DrawRailPerkInfo(Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus)
{
	local Ext_PerkBase P;
	local ExtPlayerReplicationInfo EPRI;
	local float IconSize,TileX,TileW,TileY,TileH,NotchW;
	local bool bSelected,bPending;

	if (CurrentManager==None || Index>=CurrentManager.UserPerks.Length)
		return;

	P = CurrentManager.UserPerks[Index];
	EPRI = ExtPlayerReplicationInfo(GetPlayer().PlayerReplicationInfo);
	bSelected = (EPRI!=None && P.Class==EPRI.ECurrentPerk);
	bPending = (P==DisplayPerk);

	TileW = Width;
	TileX = 0.f;
	TileY = YOffset;
	TileH = Height;
	if (bFocus || bSelected || bPending)
	{
		TileW = Width * 1.26;
		TileX = 0.f;
	}

	if (bSelected)
		C.SetDrawColor(118,7,7,235);
	else if (bPending)
		C.SetDrawColor(82,18,12,220);
	else C.SetDrawColor(64,5,5,205);
	if (bFocus)
		C.SetDrawColor(Min(C.DrawColor.R+28,155),Min(C.DrawColor.G+14,60),Min(C.DrawColor.B+14,60),C.DrawColor.A);

	C.SetPos(TileX,TileY);
	Owner.CurrentStyle.DrawWhiteBox(TileW,TileH);

	if (bSelected)
	{
		NotchW = FMax(TileW-Width,6.f);
		C.SetDrawColor(7,7,8,245);
		C.SetPos(TileX+Width,TileY+TileH*0.18);
		Owner.CurrentStyle.DrawWhiteBox(NotchW,TileH*0.64);
		C.SetDrawColor(13,10,10,230);
		C.SetPos(TileX+TileW-4.f,TileY);
		Owner.CurrentStyle.DrawWhiteBox(4.f,TileH);
	}

	C.SetDrawColor(235,232,220,255);
	IconSize = FMin(TileH,Width);
	C.SetPos(TileX+(Width-IconSize)*0.5,TileY+(TileH-IconSize)*0.5);
	C.DrawRect(IconSize,IconSize,P.PerkIcon);
}

function SwitchedRailPerk(int Index, bool bRight, int MouseX, int MouseY)
{
	local ExtPlayerController PC;
	local ExtPlayerReplicationInfo EPRI;

	if (CurrentManager==None || Index>=CurrentManager.UserPerks.Length)
		return;

	DisplayPerk = CurrentManager.UserPerks[Index];
	UpdateActionButtons();
	if (bShowingTraits)
		UpdateTraits();
	if (!bRight)
	{
		PC = ExtPlayerController(GetPlayer());
		if (PC==None)
			return;
		EPRI = ExtPlayerReplicationInfo(PC.PlayerReplicationInfo);
		if (DisplayPerk!=None && DisplayPerk.Class!=LastRequestedPerkClass
			&& (EPRI==None || EPRI.ECurrentPerk!=DisplayPerk.Class))
		{
			LastRequestedPerkClass = DisplayPerk.Class;
			PC.SwitchToPerk(DisplayPerk.Class);
		}
	}
}

final function UpdateTraits()
{
	local int i;
	local class<Ext_TraitBase> TC;
	local string S;

	if (TraitsList==None)
		return;

	TraitsList.DisplayPerk = DisplayPerk;
	TraitsList.EmptyList();
	TraitsList.ToolTip.Length = 0;

	LastTraitPerkClass = None;
	LastTraitPerkPoints = 0;
	LastTraitCount = 0;

	if (DisplayPerk==None || !DisplayPerk.bPerkNetReady)
		return;

	LastTraitPerkClass = DisplayPerk.Class;
	LastTraitPerkPoints = DisplayPerk.CurrentSP;
	LastTraitCount = DisplayPerk.PerkTraits.Length;

	for (i=0; i<DisplayPerk.PerkTraits.Length; ++i)
	{
		TC = DisplayPerk.PerkTraits[i].TraitType;
		if (TC==None)
			continue;
		if (!ShouldShowTrait(TC))
			continue;

		if (DisplayPerk.PerkTraits[i].CurrentLevel>=TC.Default.NumLevels)
			S = "MAX\nN/A";
		else
		{
			S = DisplayPerk.PerkTraits[i].CurrentLevel$"/"$TC.Default.NumLevels$"\n";
			if (TC.Static.MeetsRequirements(DisplayPerk.PerkTraits[i].CurrentLevel,DisplayPerk))
				S $= string(TC.Static.GetTraitCost(DisplayPerk.PerkTraits[i].CurrentLevel));
			else S $= "N/A";
		}
		TraitsList.AddLine(TC.Default.TraitName$"\n"$S,i);
		TraitsList.ToolTip.AddItem(TC.Static.GetTooltipInfo());
	}
}

final function bool ShouldShowTrait(class<Ext_TraitBase> TC)
{
	local string N,T;

	if (ActiveTraitCategory=='All' || TC==None)
		return true;

	N = Caps(string(TC.Name));
	T = Caps(TC.Default.TraitName);

	if (ActiveTraitCategory=='Zed')
		return IsMonsterTrait(TC);

	if (ActiveTraitCategory=='Utility')
		return (!IsMonsterTrait(TC) && (InStr(N,"BUNNY")>=0 || InStr(N,"GHOST")>=0 || InStr(N,"NIGHT")>=0 || InStr(N,"TACTIC")>=0 || InStr(N,"UNCLOAK")>=0 || InStr(N,"UNGRAB")>=0 || InStr(N,"DOOR")>=0 || InStr(N,"DURACELL")>=0 || InStr(N,"WELD")>=0 || InStr(N,"EXPLOSIVE")>=0 || InStr(N,"DEMOAOE")>=0 || InStr(N,"DEMONUKE")>=0 || InStr(N,"DEMOREACTIVE")>=0 || InStr(T,"DETECTION")>=0 || InStr(T,"EXPLOSIVE")>=0));

	if (ActiveTraitCategory=='Support')
		return (!IsMonsterTrait(TC) && (InStr(N,"CARRY")>=0 || InStr(N,"AMMOREG")>=0 || InStr(N,"ARMOR")>=0 || InStr(N,"HEALTH")>=0 || InStr(N,"KNOCKBACK")>=0 || InStr(N,"MEDBOOST")>=0 || InStr(N,"MEDSHIELD")>=0 || InStr(N,"RETALI")>=0 || InStr(N,"REDEMPTION")>=0 || InStr(N,"VAMPIRE")>=0 || InStr(N,"SPARTAN")>=0 || InStr(N,"RAGDOLL")>=0 || InStr(N,"SUPPLY")>=0));

	if (ActiveTraitCategory=='Combat')
		return !ShouldShowTraitAsUtilitySupportOrZed(TC);

	return true;
}

final function bool IsMonsterTrait(class<Ext_TraitBase> TC)
{
	local string N,T;

	if (TC==None)
		return false;
	N = Caps(string(TC.Name));
	T = Caps(TC.Default.TraitName);
	return (InStr(N,"ZED_SUMMON")>=0 || InStr(N,"ZED_DAMAGE")>=0 || InStr(N,"ZED_HEALTH")>=0 || InStr(N,"ZEDTEXT")>=0 || InStr(N,"ENEMYHP")>=0 || InStr(T,"MONSTER")>=0);
}

final function bool ShouldShowTraitAsUtilitySupportOrZed(class<Ext_TraitBase> TC)
{
	local name OldCategory;
	local bool bResult;

	OldCategory = ActiveTraitCategory;
	ActiveTraitCategory = 'Zed';
	bResult = ShouldShowTrait(TC);
	ActiveTraitCategory = 'Utility';
	bResult = bResult || ShouldShowTrait(TC);
	ActiveTraitCategory = 'Support';
	bResult = bResult || ShouldShowTrait(TC);
	ActiveTraitCategory = OldCategory;
	return bResult;
}

function ShowTraitInfo(KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick)
{
	local UIR_TraitInfoPopup T;

	if (Item!=None && (bRight || bDblClick) && Item.Value>=0 && DisplayPerk!=None)
	{
		T = UIR_TraitInfoPopup(Owner.OpenMenu(class'UIR_TraitInfoPopup'));
		T.ShowTraitInfo(Item.Value,DisplayPerk);
	}
}

final function DrawSmallBonusButton(float X, float Y, float BW, float BH, string S, optional bool bIsDisabled)
{
	local float Sc,XL,YL;

	if (bIsDisabled)
		Canvas.SetDrawColor(36,32,50,210);
	else Canvas.SetDrawColor(76,50,150,235);
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(BW,BH);
	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	if (bIsDisabled)
		Canvas.SetDrawColor(130,122,150,225);
	else Canvas.SetDrawColor(230,220,248,255);
	Canvas.TextSize(S,XL,YL,Sc,Sc);
	Canvas.SetPos(X+(BW-XL)*0.5,Y+(BH-YL)*0.5);
	Canvas.DrawText(S,,Sc,Sc);
}

final function string GetBonusStatLine(int StatIndex)
{
	return GetShortStatUIStr(DisplayPerk.PerkStats[StatIndex].StatType)$": "$ChopExtraDigits(GetStatEffectByIndex(StatIndex,true))$"%";
}

final function float GetStatEffectByIndex(int StatIndex, optional bool bIncludePending)
{
	local ExtPlayerController PC;
	local int PendingAmount;

	if (DisplayPerk==None || StatIndex<0 || StatIndex>=DisplayPerk.PerkStats.Length)
		return 0.f;
	if (bIncludePending)
	{
		PC = ExtPlayerController(GetPlayer());
		if (PC!=None)
			PendingAmount = PC.GetPendingStatBuyAmount(DisplayPerk.Class,StatIndex);
	}
	return (DisplayPerk.PerkStats[StatIndex].CurrentValue + PendingAmount) * DisplayPerk.PerkStats[StatIndex].Progress;
}

final function float FindStatEffect(name StatType, optional bool bIncludePending)
{
	local int i;

	if (DisplayPerk==None)
		return 0.f;

	for (i=0; i<DisplayPerk.PerkStats.Length; ++i)
		if (DisplayPerk.PerkStats[i].StatType==StatType)
			return GetStatEffectByIndex(i,bIncludePending);
	return 0.f;
}

final function string GetShortStatUIStr(name StatType)
{
	switch (StatType)
	{
	case 'Speed':
		return "Movement";
	case 'Damage':
		return "Damage";
	case 'Recoil':
		return "Recoil";
	case 'Spread':
		return "Spread";
	case 'Rate':
		return "Rate of Fire";
	case 'Reload':
		return "Reload";
	case 'Health':
		return "Health";
	case 'KnockDown':
		return "Knockback";
	case 'HeadDamage':
		return "Head Damage";
	case 'Mag':
		return "Magazine";
	case 'Spare':
		return "Spare Ammo";
	case 'OffDamage':
		return "Off-Perk";
	case 'AllDmg':
		return "ZedsD Reduc";
	case 'HealRecharge':
		return "Syringe";
	case 'Switch':
		return "WeaponSwap";
	}
	return string(StatType);
}

final function string ChopExtraDigits(float Value)
{
	local int Rounded, Whole, Dec;
	local string S;

	Rounded = int(Abs(Value) * 100.f + 0.5f);
	Whole = Rounded / 100;
	Dec = Rounded - (Whole * 100);
	S = string(Whole);
	if (Dec > 0)
	{
		if ((Dec % 10) == 0)
			S $= "."$string(Dec / 10);
		else if (Dec < 10)
			S $= ".0"$string(Dec);
		else S $= "."$string(Dec);
	}

	return S;
}

defaultproperties
{
	Begin Object Class=KFGUI_ZvampPressButton Name=ResetPerkButton
		ID="Reset"
		XPosition=0.155
		YPosition=0.20
		XSize=0.090
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		ExtravDir=1
	End Object
	Components.Add(ResetPerkButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=UnloadPerkButton
		ID="Unload"
		XPosition=0.245
		YPosition=0.20
		XSize=0.090
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		ExtravDir=1
	End Object
	Components.Add(UnloadPerkButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=PrestigePerkButton
		ID="Prestige"
		XPosition=0.335
		YPosition=0.20
		XSize=0.090
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		bDisabled=true
	End Object
	Components.Add(PrestigePerkButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=ConfigureButton
		ID="Configure"
		XPosition=0.080
		YPosition=0.865
		XSize=0.395
		YSize=0.055
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(ConfigureButton)

	Begin Object Class=KFGUI_ComponentList Name=PerkStats
		ID="Stats"
		XPosition=0.085
		YPosition=0.265
		XSize=0.370
		YSize=0.495
		ListItemsPerPage=10
		BackgroundColor=(R=8,G=5,B=18,A=0)
		bDrawBackground=false
	End Object
	Components.Add(PerkStats)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton0
		ID="BuyStat0"
		IntIndex=0
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton0)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton1
		ID="BuyStat1"
		IntIndex=1
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton1)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton2
		ID="BuyStat2"
		IntIndex=2
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton2)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton3
		ID="BuyStat3"
		IntIndex=3
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton3)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton4
		ID="BuyStat4"
		IntIndex=4
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton4)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton5
		ID="BuyStat5"
		IntIndex=5
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton5)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton6
		ID="BuyStat6"
		IntIndex=6
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton6)

	Begin Object Class=KFGUI_ZvampPressButton Name=BuyStatButton7
		ID="BuyStat7"
		IntIndex=7
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyStatButton7)

	Begin Object Class=KFGUI_ZvampPressButton Name=TraitTabAllButton
		ID="TraitTabAll"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabAllButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=TraitTabCombatButton
		ID="TraitTabCombat"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabCombatButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=TraitTabSurvivalButton
		ID="TraitTabSurvival"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabSurvivalButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=TraitTabUtilityButton
		ID="TraitTabUtility"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabUtilityButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=TraitTabZedButton
		ID="TraitTabZed"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabZedButton)

	Begin Object Class=UIR_PerkTraitList Name=PerkTraits
		ID="Traits"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnSelectedRow=ShowTraitInfo
	End Object
	Components.Add(PerkTraits)

	Begin Object Class=KFGUI_ZvampInvisibleHotspot Name=XPBarHover
		ID="XPBar"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
	End Object
	Components.Add(XPBarHover)

	Begin Object Class=KFGUI_ZvampPressButton Name=GrenadePrevButton
		ID="GrenadePrev"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		bDisabled=true
	End Object
	Components.Add(GrenadePrevButton)

	Begin Object Class=KFGUI_ZvampPressButton Name=GrenadeNextButton
		ID="GrenadeNext"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		bDisabled=true
	End Object
	Components.Add(GrenadeNextButton)

	Begin Object Class=KFGUI_List Name=PerkIconRail
		ID="PerkRail"
		XPosition=0.005
		YPosition=0.015
		XSize=0.075
		YSize=0.960
		ListItemsPerPage=10
		BackgroundColor=(R=8,G=5,B=18,A=0)
		bDrawBackground=false
		bClickable=true
		OnDrawItem=DrawRailPerkInfo
		OnClickedItem=SwitchedRailPerk
	End Object
	Components.Add(PerkIconRail)
}
