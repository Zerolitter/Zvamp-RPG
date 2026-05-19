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

Class UIP_PerkSelection extends KFGUI_MultiComponent;

var KFGUI_List PerkList;
var KFGUI_Button B_Prestige, B_Reset, B_Unload;
var KFGUI_ComponentList StatsList;
var UIR_PerkTraitList TraitsList;
var KFGUI_VampModuleFrame SkillPanel, SummaryPanel, ModuleDividerPanel;
var KFGUI_TextLable PerkLabel, SkillsLabel, BonusesLabel, LoadoutLabel, BonusSummaryLabel, LoadoutSummaryLabel, PointsLeftLabel;
var KFGUI_Button ConfigureButton, TraitTabAll, TraitTabCombat, TraitTabSurvival, TraitTabUtility, TraitTabZed, GrenadePrevButton, GrenadeNextButton;
var ExtPerkManager CurrentManager;
var Ext_PerkBase PendingPerk,OldUsedPerk;
var class<Ext_PerkBase> PrevPendingPerk;
var array<UIR_PerkStat> StatBuyers;
var int OldPerkPoints;
var float LastPerkReplicationRequestTime;
var class<Ext_PerkBase> OldSummaryPerk;
var bool bShowingTraits;
var() bool bUseSpawnedHeader;
var name ActiveTraitCategory;

var localized string PrestigeButtonText;
var localized string PrestigeButtonToolTip;
var localized string ResetButtonText;
var localized string ResetButtonToolTip;
var localized string UnloadButtonText;
var localized string UnloadButtonToolTip;
var localized string PrestigeButtonDisabledToolTip;
var localized string Level;
var localized string Points;
var localized string NoPerkSelected;
var localized string NotAviable;
var localized string MaxStr;

function InitMenu()
{
	PerkList = KFGUI_List(FindComponentID('Perks'));
	StatsList = KFGUI_ComponentList(FindComponentID('Stats'));
	TraitsList = UIR_PerkTraitList(FindComponentID('Traits'));
	PerkLabel = KFGUI_TextLable(FindComponentID('Info'));
	SkillPanel = KFGUI_VampModuleFrame(FindComponentID('SkillPanel'));
	SummaryPanel = KFGUI_VampModuleFrame(FindComponentID('SummaryPanel'));
	ModuleDividerPanel = KFGUI_VampModuleFrame(FindComponentID('ModuleDivider'));
	SkillsLabel = KFGUI_TextLable(FindComponentID('SkillsLabel'));
	BonusesLabel = KFGUI_TextLable(FindComponentID('BonusesLabel'));
	LoadoutLabel = KFGUI_TextLable(FindComponentID('LoadoutLabel'));
	BonusSummaryLabel = KFGUI_TextLable(FindComponentID('BonusSummary'));
	LoadoutSummaryLabel = KFGUI_TextLable(FindComponentID('LoadoutSummary'));
	PointsLeftLabel = KFGUI_TextLable(FindComponentID('PointsLeft'));
	ConfigureButton = KFGUI_Button(FindComponentID('Configure'));
	GrenadePrevButton = KFGUI_Button(FindComponentID('GrenadePrev'));
	GrenadeNextButton = KFGUI_Button(FindComponentID('GrenadeNext'));
	TraitTabAll = KFGUI_Button(FindComponentID('TraitTabAll'));
	TraitTabCombat = KFGUI_Button(FindComponentID('TraitTabCombat'));
	TraitTabSurvival = KFGUI_Button(FindComponentID('TraitTabSurvival'));
	TraitTabUtility = KFGUI_Button(FindComponentID('TraitTabUtility'));
	TraitTabZed = KFGUI_Button(FindComponentID('TraitTabZed'));
	PerkLabel.SetText("");
	B_Prestige = KFGUI_Button(FindComponentID('Prestige'));
	B_Reset = KFGUI_Button(FindComponentID('Reset'));
	B_Unload = KFGUI_Button(FindComponentID('Unload'));

	B_Prestige.ButtonText=PrestigeButtonText;
	B_Prestige.ToolTip="-";

	B_Unload.ButtonText=UnloadButtonText;
	B_Unload.ToolTip=UnloadButtonToolTip;

	B_Reset.ButtonText=ResetButtonText;
	B_Reset.ToolTip=ResetButtonToolTip;

	SkillsLabel.SetText("SKILLS");
	BonusesLabel.SetText("PERK BONUSES");
	LoadoutLabel.SetText("STARTING LOADOUT");
	ConfigureButton.ToolTip = "Configure perk-unique traits";
	GrenadePrevButton.ButtonText = "<";
	GrenadeNextButton.ButtonText = ">";
	GrenadePrevButton.ToolTip = "Previous grenade";
	GrenadeNextButton.ToolTip = "Next grenade";
	TraitTabAll.ButtonText = "All";
	TraitTabCombat.ButtonText = "Combat";
	TraitTabSurvival.ButtonText = "Support";
	TraitTabUtility.ButtonText = "Utility";
	TraitTabZed.ButtonText = "Zed";
	ActiveTraitCategory = 'All';
	BonusSummaryLabel.SetText("");
	LoadoutSummaryLabel.SetText("");
	PointsLeftLabel.SetText("");
	if (bUseSpawnedHeader)
		PerkLabel.SetPosition(2.0,2.0,0.01,0.01);
	ApplyPerkActionButtonLayout();
	SetConfigureMode(false);

	Super.InitMenu();
}

function ShowMenu()
{
	Super.ShowMenu();
	SetTimer(0.1,true);
	Timer();
}

function CloseMenu()
{
	if (PendingPerk!=None && ExtPlayerController(GetPlayer())!=None)
		ExtPlayerController(GetPlayer()).CancelPendingStatBuys(PendingPerk.Class);
	Super.CloseMenu();
	CurrentManager = None;
	PrevPendingPerk = (PendingPerk!=None ? PendingPerk.Class : None);
	PendingPerk = None;
	OldUsedPerk = None;
	SetTimer(0,false);
}

function Timer()
{
	local int i;
	local ExtPlayerController PC;

	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return;
	CurrentManager = PC.ActivePerkManager;
	if (CurrentManager==None)
	{
		if (PC.WorldInfo.TimeSeconds-LastPerkReplicationRequestTime>=2.f)
		{
			LastPerkReplicationRequestTime = PC.WorldInfo.TimeSeconds;
			PC.ZvampextRequestPerkReplication();
		}
		return;
	}
	if (CurrentManager!=None)
	{
		if (CurrentManager.UserPerks.Length==0 || CurrentManager.CurrentPerk==None)
			CurrentManager.InitPerks();
		if ((CurrentManager.UserPerks.Length==0 || CurrentManager.CurrentPerk==None || (PendingPerk!=None && !PendingPerk.bPerkNetReady))
			&& PC.WorldInfo.TimeSeconds-LastPerkReplicationRequestTime>=2.f)
		{
			LastPerkReplicationRequestTime = PC.WorldInfo.TimeSeconds;
			PC.ZvampextRequestPerkReplication();
		}
		if (PrevPendingPerk!=None)
		{
			PendingPerk = CurrentManager.FindPerk(PrevPendingPerk);
			PrevPendingPerk = None;
		}
		PerkList.ChangeListSize(CurrentManager.UserPerks.Length);
		if (PendingPerk!=None && !PendingPerk.bPerkNetReady)
			return;

		// Huge code block to handle stat updating, but actually pretty well optimized.
		if (PendingPerk!=OldUsedPerk)
		{
			OldUsedPerk = PendingPerk;
			if (PendingPerk!=None)
			{
				OldPerkPoints = -1;
				if (StatsList.ItemComponents.Length!=PendingPerk.PerkStats.Length)
				{
					if (StatsList.ItemComponents.Length<PendingPerk.PerkStats.Length)
					{
						for (i=StatsList.ItemComponents.Length; i<PendingPerk.PerkStats.Length; ++i)
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
					else if (StatsList.ItemComponents.Length>PendingPerk.PerkStats.Length)
					{
						for (i=PendingPerk.PerkStats.Length; i<StatsList.ItemComponents.Length; ++i)
							StatBuyers[i].CloseMenu();
						StatsList.ItemComponents.Length = PendingPerk.PerkStats.Length;
					}
				}
				OldPerkPoints = PendingPerk.CurrentSP;
				PerkLabel.SetText(Level$PendingPerk.GetLevelString()@PendingPerk.PerkName@"("$Points@PendingPerk.CurrentSP$")");
				UpdateSummary();
				for (i=0; i<StatsList.ItemComponents.Length; ++i) // Just make sure perk stays the same.
				{
					StatBuyers[i].SetActivePerk(PendingPerk);
					StatBuyers[i].CheckBuyLimit();
				}
				B_Prestige.SetDisabled(!PendingPerk.CanPrestige());
				if (PendingPerk.MinLevelForPrestige<0)
					B_Prestige.ChangeToolTip(PrestigeButtonDisabledToolTip);
				else B_Prestige.ChangeToolTip(PrestigeButtonToolTip$" "$PendingPerk.MinLevelForPrestige);
				UpdateTraits();
			}
			else // Empty out if needed.
			{
				for (i=0; i<StatsList.ItemComponents.Length; ++i)
					StatBuyers[i].CloseMenu();
				StatsList.ItemComponents.Length = 0;
		PerkLabel.SetText(NoPerkSelected);
		UpdateSummary();
		SetConfigureMode(false);
			}
		}
		else if (PendingPerk!=None && OldPerkPoints!=PendingPerk.CurrentSP)
		{
			B_Prestige.SetDisabled(!PendingPerk.CanPrestige());

			OldPerkPoints = PendingPerk.CurrentSP;
			PerkLabel.SetText(Level$PendingPerk.GetLevelString()@PendingPerk.PerkName@"("$Points@PendingPerk.CurrentSP$")");
			UpdateSummary();
			for (i=0; i<StatsList.ItemComponents.Length; ++i) // Just make sure perk stays the same.
				StatBuyers[i].CheckBuyLimit();

			// Update traits list.
			UpdateTraits();
		}
		else if (PendingPerk!=None && !bShowingTraits)
		{
			UpdateSummary();
		}
	}
}

final function SetConfigureMode(bool bShowTraits)
{
	local int i;

	bShowingTraits = bShowTraits;

	if (bShowingTraits)
	{
		ConfigureButton.ButtonText = "BACK";
		SkillsLabel.SetText("");
		PointsLeftLabel.SetText("");
		BonusesLabel.SetText("TRAITS");
		LoadoutLabel.SetText("");
		BonusSummaryLabel.SetText("");
		LoadoutSummaryLabel.SetText("");
		SkillPanel.SetPosition(2.0,2.0,0.01,0.01);
		ModuleDividerPanel.SetPosition(2.0,2.0,0.01,0.01);
		SummaryPanel.SetPosition(0.10,0.16,0.89,0.73);
		for (i=0; i<StatsList.ItemComponents.Length; ++i)
			StatBuyers[i].CloseMenu();
		StatsList.ItemComponents.Length = 0;
		StatsList.SetPosition(2.0,2.0,0.01,0.01);
		StatsList.OldXSize = -1.f;
		TraitsList.SetPosition(0.115,0.285,0.84,0.54);
		TraitsList.OldXSize = -1.f;
		BonusesLabel.SetPosition(0.115,0.19,0.16,0.04);
		ConfigureButton.SetPosition(0.115,0.835,0.84,0.055);
		PointsLeftLabel.SetPosition(2.0,2.0,0.01,0.01);
		SetTraitTabsVisible(true);
		if (PendingPerk!=None)
			UpdateTraits();
	}
	else
	{
		ConfigureButton.ButtonText = "CONFIGURE";
		SkillsLabel.SetText("SKILLS");
		BonusesLabel.SetText("PERK BONUSES");
		LoadoutLabel.SetText("GRENADE");
		if (bUseSpawnedHeader)
		{
			ApplyPerkActionButtonLayout();
			PerkList.SetPosition(LayoutFloat("RailX",0.f),LayoutFloat("RailY",0.f),LayoutFloat("RailW",0.09),LayoutFloat("RailH",1.f));
			SkillPanel.SetPosition(LayoutFloat("SkillX",0.10),LayoutFloat("SkillY",0.16),LayoutFloat("SkillW",0.47),LayoutFloat("SkillH",0.74));
			SkillPanel.LeftBorderAlpha = LayoutAlpha("SkillLeftBorderAlpha",255);
			ModuleDividerPanel.SetPosition(LayoutFloat("DividerX",0.57),LayoutFloat("DividerY",0.16),LayoutFloat("DividerW",0.015),LayoutFloat("DividerH",0.74));
			SummaryPanel.SetPosition(LayoutFloat("SummaryX",0.585),LayoutFloat("SummaryY",0.16),LayoutFloat("SummaryW",0.405),LayoutFloat("SummaryH",0.74));
			StatsList.SetPosition(LayoutFloat("StatsX",0.115),LayoutFloat("StatsY",0.29),LayoutFloat("StatsW",0.43),LayoutFloat("StatsH",0.47));
			SkillsLabel.SetPosition(LayoutFloat("SkillsLabelX",0.115),LayoutFloat("SkillsLabelY",0.18),LayoutFloat("SkillsLabelW",0.16),LayoutFloat("SkillsLabelH",0.045));
			BonusesLabel.SetPosition(LayoutFloat("BonusesLabelX",0.61),LayoutFloat("BonusesLabelY",0.18),LayoutFloat("BonusesLabelW",0.22),LayoutFloat("BonusesLabelH",0.045));
			BonusSummaryLabel.SetPosition(LayoutFloat("BonusSummaryX",0.62),LayoutFloat("BonusSummaryY",0.25),LayoutFloat("BonusSummaryW",0.34),LayoutFloat("BonusSummaryH",0.36));
			LoadoutLabel.SetPosition(LayoutFloat("LoadoutLabelX",0.61),LayoutFloat("LoadoutLabelY",0.66),LayoutFloat("LoadoutLabelW",0.28),LayoutFloat("LoadoutLabelH",0.04));
			LoadoutSummaryLabel.SetPosition(LayoutFloat("LoadoutSummaryX",0.675),LayoutFloat("LoadoutSummaryY",0.77),LayoutFloat("LoadoutSummaryW",0.15),LayoutFloat("LoadoutSummaryH",0.055));
			ConfigureButton.SetPosition(LayoutFloat("ConfigureX",0.125),LayoutFloat("ConfigureY",0.82),LayoutFloat("ConfigureW",0.40),LayoutFloat("ConfigureH",0.06));
			GrenadePrevButton.SetPosition(LayoutFloat("GrenadePrevX",0.61),LayoutFloat("GrenadePrevY",0.77),LayoutFloat("GrenadePrevW",0.055),LayoutFloat("GrenadePrevH",0.055));
			GrenadeNextButton.SetPosition(LayoutFloat("GrenadeNextX",0.80),LayoutFloat("GrenadeNextY",0.77),LayoutFloat("GrenadeNextW",0.055),LayoutFloat("GrenadeNextH",0.055));
		}
		else
		{
			SkillPanel.SetPosition(0.10,0.16,0.47,0.74);
			ModuleDividerPanel.SetPosition(0.57,0.16,0.015,0.74);
			SummaryPanel.SetPosition(0.585,0.16,0.405,0.74);
			StatsList.SetPosition(0.115,0.29,0.43,0.47);
			BonusesLabel.SetPosition(0.61,0.18,0.22,0.045);
			ConfigureButton.SetPosition(0.125,0.82,0.40,0.06);
			GrenadePrevButton.SetPosition(0.61,0.77,0.055,0.055);
			GrenadeNextButton.SetPosition(0.80,0.77,0.055,0.055);
		}
		StatsList.OldXSize = -1.f;
		TraitsList.SetPosition(2.0,2.0,0.01,0.01);
		TraitsList.OldXSize = -1.f;
		if (bUseSpawnedHeader)
			PointsLeftLabel.SetPosition(2.0,2.0,0.01,0.01);
		else PointsLeftLabel.SetPosition(0.19,0.76,0.24,0.04);
		SetTraitTabsVisible(false);
		OldUsedPerk = None;
		UpdateSummary();
	}
}

final function ApplyPerkActionButtonLayout()
{
	if (!bUseSpawnedHeader)
		return;

	B_Reset.SetPosition(LayoutFloat("ResetX",0.60),LayoutFloat("ResetY",0.025),LayoutFloat("ResetW",0.10),LayoutFloat("ResetH",0.045));
	B_Unload.SetPosition(LayoutFloat("UnloadX",0.705),LayoutFloat("UnloadY",0.025),LayoutFloat("UnloadW",0.10),LayoutFloat("UnloadH",0.045));
	B_Prestige.SetPosition(LayoutFloat("PrestigeX",0.81),LayoutFloat("PrestigeY",0.025),LayoutFloat("PrestigeW",0.10),LayoutFloat("PrestigeH",0.045));
}

final function string GetLayoutValue(string Key, string DefaultValue)
{
	local ExtPlayerController PC;
	local string Layout,Needle,Tail;
	local int i,j;

	if (!bUseSpawnedHeader)
		return DefaultValue;
	PC = ExtPlayerController(GetPlayer());
	if (PC==None || PC.SpawnedPerkUILayout=="")
		return DefaultValue;

	Layout = ";"$PC.SpawnedPerkUILayout$";";
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

final function float LayoutFloat(string Key, float DefaultValue)
{
	local string S;

	S = GetLayoutValue(Key,"");
	if (S=="")
		return DefaultValue;
	return float(S);
}

final function byte LayoutAlpha(string Key, byte DefaultValue)
{
	return byte(Clamp(int(LayoutFloat(Key,float(DefaultValue))),0,255));
}

final function SetTraitTabsVisible(bool bVisible)
{
	if (bVisible)
	{
		TraitTabAll.SetPosition(0.115,0.235,0.09,0.04);
		TraitTabCombat.SetPosition(0.205,0.235,0.12,0.04);
		TraitTabSurvival.SetPosition(0.325,0.235,0.12,0.04);
		TraitTabUtility.SetPosition(0.445,0.235,0.11,0.04);
		TraitTabZed.SetPosition(0.555,0.235,0.09,0.04);
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
	TraitTabAll.bIsHighlighted = (ActiveTraitCategory=='All');
	TraitTabCombat.bIsHighlighted = (ActiveTraitCategory=='Combat');
	TraitTabSurvival.bIsHighlighted = (ActiveTraitCategory=='Support');
	TraitTabUtility.bIsHighlighted = (ActiveTraitCategory=='Utility');
	TraitTabZed.bIsHighlighted = (ActiveTraitCategory=='Zed');
}

function DrawMenu()
{
	if (bUseSpawnedHeader)
		DrawSpawnedClassHeader();
}

final function DrawSpawnedClassHeader()
{
	local float X,Y,W,H,IconSize,Sc,XL,YL,XPFrac,BarX,BarY,BarW,BarH;
	local string S;
	local int PendingCost;
	local ExtPlayerController PC;

	X = CompPos[2] * LayoutFloat("HeaderX",0.075);
	Y = CompPos[3] * LayoutFloat("HeaderY",0.015);
	W = CompPos[2] * LayoutFloat("HeaderW",0.49);
	H = CompPos[3] * LayoutFloat("HeaderH",0.13);

	Canvas.SetDrawColor(12,10,16,LayoutAlpha("HeaderAlpha",70));
	Canvas.SetPos(X,Y);
	Owner.CurrentStyle.DrawWhiteBox(W,H);

	if (PendingPerk==None || !PendingPerk.bPerkNetReady)
		return;
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
		PendingCost = PC.GetPendingStatBuyCost(PendingPerk.Class);

	IconSize = H * 0.90;
	Canvas.SetDrawColor(255,255,255,255);
	Canvas.SetPos(X + H * 0.06,Y + H * 0.05);
	Canvas.DrawRect(IconSize,IconSize,PendingPerk.PerkIcon);

	Canvas.Font = Owner.CurrentStyle.PickFont(2,Sc);
	Canvas.SetDrawColor(245,245,245,255);
	Canvas.SetPos(X + IconSize + H * 0.16,Y + H * 0.10);
	Canvas.DrawText(PendingPerk.PerkName,,Sc,Sc);

	Canvas.Font = Owner.CurrentStyle.PickFont(0,Sc);
	S = "Current Prestige Rank: "$PendingPerk.CurrentPrestige;
	Canvas.SetDrawColor(218,207,238,255);
	Canvas.SetPos(X + IconSize + H * 0.17,Y + H * 0.52);
	Canvas.DrawText(S,,Sc,Sc);

	S = "Arrange XP: "$Max(PendingPerk.CurrentSP-PendingCost,0);
	if (PendingCost>0)
		S $= " (-"$PendingCost$")";
	Canvas.TextSize(S,XL,YL,Sc,Sc);
	Canvas.SetDrawColor(245,245,245,255);
	Canvas.SetPos(X + W - XL - H * 0.18,Y + H * 0.52);
	Canvas.DrawText(S,,Sc,Sc);

	Canvas.Font = Owner.CurrentStyle.PickFont(3,Sc);
	S = PendingPerk.GetLevelString();
	Canvas.TextSize(S,XL,YL,Sc,Sc);
	Canvas.SetDrawColor(245,245,245,255);
	Canvas.SetPos(X + W - XL - H * 0.18,Y + H * 0.05);
	Canvas.DrawText(S,,Sc,Sc);

	BarX = X + IconSize + H * 0.16;
	BarY = Y + H - H * 0.18;
	BarW = W - IconSize - H * 0.34;
	BarH = H * 0.08;
	Canvas.SetDrawColor(45,10,10,160);
	Canvas.SetPos(BarX,BarY);
	Owner.CurrentStyle.DrawWhiteBox(BarW,BarH);
	XPFrac = PendingPerk.GetProgressPercent();
	Canvas.SetDrawColor(140,10,10,230);
	Canvas.SetPos(BarX,BarY);
	Owner.CurrentStyle.DrawWhiteBox(BarW * XPFrac,BarH);
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
		return "Fire Rate";
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
	case 'Armor':
		return "Armor";
	case 'AllDmg':
		return "ZedsD Reduc";
	case 'Heal':
		return "Healing";
	case 'HealRecharge':
		return "Syringe";
	case 'Switch':
		return "WeaponSwap";
	case 'BossDamageReduction':
		return "BossD Reduc";
	case 'EliteDamageReduction':
		return "EliteD Reduc";
	}
	return string(StatType);
}

final function string GetStatSummaryLine(int StatIndex)
{
	return GetShortStatUIStr(PendingPerk.PerkStats[StatIndex].StatType)$": "$ChopExtraDigits(GetStatSummaryEffect(StatIndex))$"%";
}

final function float GetStatSummaryEffect(int StatIndex)
{
	local ExtPlayerController PC;
	local int PendingAmount;

	if (PendingPerk==None || StatIndex<0 || StatIndex>=PendingPerk.PerkStats.Length)
		return 0.f;
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
		PendingAmount = PC.GetPendingStatBuyAmount(PendingPerk.Class,StatIndex);
	return (PendingPerk.PerkStats[StatIndex].CurrentValue + PendingAmount) * PendingPerk.PerkStats[StatIndex].Progress;
}

final function UpdateSummary()
{
	local int i, ACount, BCount;
	local string S;
	local array<string> A1Lines, B1Lines;
	local ExtPlayerController PC;
	local int PendingCost;

	if (bShowingTraits)
		return;

	if (PendingPerk==None || !PendingPerk.bPerkNetReady)
	{
		OldSummaryPerk = None;
		BonusSummaryLabel.SetText("");
		LoadoutSummaryLabel.SetText("");
		PointsLeftLabel.SetText("");
		return;
	}

	OldSummaryPerk = PendingPerk.Class;
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
		PendingCost = PC.GetPendingStatBuyCost(PendingPerk.Class);
	PointsLeftLabel.SetText((bUseSpawnedHeader ? "Arrange XP: " : "Points left: ")$Max(PendingPerk.CurrentSP-PendingCost,0));
	for (i=0; i<PendingPerk.PerkStats.Length; ++i)
	{
		if ((PendingPerk.PerkStats[i].StatGroup=='B1' || (PendingPerk.PerkStats[i].StatGroup=='' && i>=6)) && BCount<6)
		{
			B1Lines.AddItem(GetStatSummaryLine(i));
			++BCount;
		}
		else if (ACount<6)
		{
			A1Lines.AddItem(GetStatSummaryLine(i));
			++ACount;
		}
	}
	for (i=0; i<Max(A1Lines.Length,B1Lines.Length); ++i)
	{
		if (S!="")
			S $= "\n";
		if (i<A1Lines.Length)
			S $= A1Lines[i];
		if (i<B1Lines.Length)
			S $= "     "$B1Lines[i];
	}
	BonusSummaryLabel.SetText(S);

	S = "";
	if (PendingPerk.GrenadeWeaponDef!=None)
		S $= PendingPerk.GrenadeWeaponDef.Static.GetItemName();
	LoadoutSummaryLabel.SetText(S);
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

final function UpdateTraits()
{
	local int i;
	local class<Ext_TraitBase> TC;
	local string S;

	// A bit hacky to delete and refill list again, but at least it works...
	TraitsList.DisplayPerk = PendingPerk;
	TraitsList.EmptyList();
	TraitsList.ToolTip.Length = 0;

	if (PendingPerk==None)
		return;
	for (i=0; i<PendingPerk.PerkTraits.Length; ++i)
	{
		TC = PendingPerk.PerkTraits[i].TraitType;
		if (!ShouldShowTrait(TC))
			continue;
		if (PendingPerk.PerkTraits[i].CurrentLevel>=TC.Default.NumLevels)
			S = MaxStr$"\n"$NotAviable;
		else
		{
			S = PendingPerk.PerkTraits[i].CurrentLevel$"/"$TC.Default.NumLevels$"\n";
			if (TC.Static.MeetsRequirements(PendingPerk.PerkTraits[i].CurrentLevel,PendingPerk))
				S $= string(TC.Static.GetTraitCost(PendingPerk.PerkTraits[i].CurrentLevel));
			else S $= NotAviable;
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
		return !ShouldShowTraitAsUtilitySurvivalOrZed(TC);

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

final function bool ShouldShowTraitAsUtilitySurvivalOrZed(class<Ext_TraitBase> TC)
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

function DrawPerkInfo(Canvas C, int Index, float YOffset, float Height, float Width, bool bFocus)
{
	local Ext_PerkBase P;
	local float Sc;
	local float IconSize, TileX, TileW;
	local bool bSelected, bPopped;

	if (CurrentManager==None || Index>=CurrentManager.UserPerks.Length)
		return;
	P = CurrentManager.UserPerks[Index];
	bSelected = (P.Class==ExtPlayerReplicationInfo(GetPlayer().PlayerReplicationInfo).ECurrentPerk);
	if (bSelected)
	{
		if (PendingPerk==None)
			PendingPerk = P;
		C.SetDrawColor(LayoutAlpha("RailSelectedR",164),LayoutAlpha("RailSelectedG",164),LayoutAlpha("RailSelectedB",32),(bUseSpawnedHeader ? LayoutAlpha("RailSelectedAlpha",190) : 255));
	}
	else if (P==PendingPerk)
		C.SetDrawColor(LayoutAlpha("RailPendingR",164),LayoutAlpha("RailPendingG",86),LayoutAlpha("RailPendingB",32),(bUseSpawnedHeader ? LayoutAlpha("RailPendingAlpha",150) : 255));
	else C.SetDrawColor(LayoutAlpha("RailInactiveR",32),LayoutAlpha("RailInactiveG",32),LayoutAlpha("RailInactiveB",128),(bUseSpawnedHeader ? LayoutAlpha("RailInactiveAlpha",35) : 255));

	if (bFocus)
	{
		C.DrawColor.R+=15;
		C.DrawColor.G+=15;
		C.DrawColor.B+=15;
	}
	bPopped = (!bUseSpawnedHeader || bFocus || bSelected || P==PendingPerk);
	if (bPopped)
	{
		if (bUseSpawnedHeader)
		{
			TileW = FMin(Width,Height) * LayoutFloat("RailPoppedTileScale",1.f);
			TileX = (Width - TileW) * 0.5f;
		}
		else
		{
			TileX = 0.f;
			TileW = Width;
		}
	}
	else
	{
		TileX = Width * LayoutFloat("RailTuck",-0.78);
		TileW = Width;
	}
	C.SetPos(TileX,YOffset);
	Owner.CurrentStyle.DrawWhiteBox(TileW,Height);

	C.SetDrawColor(240,240,240);
	IconSize = FMin(Height-4,TileW-4);
	C.SetPos(TileX + (TileW-IconSize)*0.5,YOffset+(Height-IconSize)*0.5);
	C.DrawRect(IconSize,IconSize,P.PerkIcon);

	if (Width<Height*2.f)
		return;

	C.SetPos(6+Height,YOffset);
	C.Font = Owner.CurrentStyle.PickFont(Max(Owner.CurrentStyle.DefaultFontSize-1,0),Sc);
	C.DrawText(P.PerkName,,Sc,Sc);

	C.SetPos(6+Height,YOffset+Height*0.5);
	C.DrawText("Lv "$P.GetLevelString()$" ("$P.CurrentEXP$"/"$P.NextLevelEXP$" XP)",,Sc,Sc); // TODO: Localization
}

function SwitchedPerk(int Index, bool bRight, int MouseX, int MouseY)
{
	if (CurrentManager==None || Index>=CurrentManager.UserPerks.Length)
		return;

	PendingPerk = CurrentManager.UserPerks[Index];
	ExtPlayerController(GetPlayer()).SwitchToPerk(PendingPerk.Class);
}

function ShowTraitInfo(KFGUI_ListItem Item, int Row, bool bRight, bool bDblClick)
{
	local UIR_TraitInfoPopup T;
	if (Item!=None && (bRight || bDblClick) && Item.Value>=0)
	{
		T = UIR_TraitInfoPopup(Owner.OpenMenu(class'UIR_TraitInfoPopup'));
		T.ShowTraitInfo(Item.Value,PendingPerk);
	}
}

function ButtonClicked(KFGUI_Button Sender)
{
	local KFGUI_Page T;

	switch (Sender.ID)
	{
	case 'Configure':
		SetConfigureMode(!bShowingTraits);
		PlayMenuSound(MN_ClickButton);
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
	case 'GrenadePrev':
	case 'GrenadeNext':
		PlayMenuSound(MN_ClickButton);
		if (PendingPerk!=None)
			ExtPlayerController(GetPlayer()).ClientMessage("Grenade cycling is not wired yet.");
		break;
	case 'Reset':
		if (PendingPerk!=None)
		{
			T = Owner.OpenMenu(class'UI_ResetWarning');
			UI_ResetWarning(T).SetupTo(PendingPerk);
		}
		break;
	case 'Unload':
		if (PendingPerk!=None)
		{
			T = Owner.OpenMenu(class'UI_UnloadInfo');
			UI_UnloadInfo(T).SetupTo(PendingPerk.Class);
		}
		break;
	case 'Prestige':
		if (PendingPerk!=None)
		{
			T = Owner.OpenMenu(class'UI_PrestigeNote');
			UI_PrestigeNote(T).SetupTo(PendingPerk);
		}
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_List Name=PerksList
		ID="Perks"
		XPosition=0
		YPosition=0
		XSize=0.09
		YSize=1
		ListItemsPerPage=10
		BackgroundColor=(R=8,G=5,B=18,A=30)
		bDrawBackground=false
		bClickable=true
		OnDrawItem=DrawPerkInfo
		OnClickedItem=SwitchedPerk
	End Object

	Begin Object Class=KFGUI_ComponentList Name=PerkStats
		ID="Stats"
		XPosition=0.115
		YPosition=0.29
		XSize=0.43
		YSize=0.47
		ListItemsPerPage=8
	End Object

	Begin Object Class=UIR_PerkTraitList Name=PerkTraits
		ID="Traits"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		OnSelectedRow=ShowTraitInfo
	End Object

	Begin Object Class=KFGUI_TextLable Name=CurPerkLabel
		ID="Info"
		XPosition=0.10
		YPosition=0.025
		XSize=0.48
		YSize=0.08
		AlignX=1
		AlignY=1
		TextFontInfo=(bClipText=true)
	End Object

	Begin Object Class=KFGUI_VampModuleFrame Name=SkillPanel
		ID="SkillPanel"
		XPosition=0.10
		YPosition=0.16
		XSize=0.47
		YSize=0.74
		FillAlpha=80
	End Object
	Components.Add(PerksList)
	Components.Add(SkillPanel)

	Begin Object Class=KFGUI_VampModuleFrame Name=SummaryPanel
		ID="SummaryPanel"
		XPosition=0.585
		YPosition=0.16
		XSize=0.405
		YSize=0.74
		FillAlpha=80
	End Object
	Components.Add(SummaryPanel)

	Begin Object Class=KFGUI_VampModuleFrame Name=ModuleDividerPanel
		ID="ModuleDivider"
		XPosition=0.57
		YPosition=0.16
		XSize=0.015
		YSize=0.74
		BorderAlpha=0
		FillAlpha=95
	End Object
	Components.Add(ModuleDividerPanel)

	Begin Object Class=KFGUI_TextLable Name=SkillsHeader
		ID="SkillsLabel"
		XPosition=0.115
		YPosition=0.18
		XSize=0.16
		YSize=0.045
		AlignX=0
		AlignY=1
	End Object
	Components.Add(SkillsHeader)

	Begin Object Class=KFGUI_TextLable Name=BonusesHeader
		ID="BonusesLabel"
		XPosition=0.61
		YPosition=0.18
		XSize=0.22
		YSize=0.045
		AlignX=0
		AlignY=1
	End Object
	Components.Add(BonusesHeader)

	Begin Object Class=KFGUI_TextLable Name=BonusSummary
		ID="BonusSummary"
		XPosition=0.62
		YPosition=0.25
		XSize=0.34
		YSize=0.36
		AlignX=0
		AlignY=0
		FontScale=1
		TextFontInfo=(bClipText=false,bEnableShadow=true)
	End Object
	Components.Add(BonusSummary)

	Begin Object Class=KFGUI_TextLable Name=LoadoutHeader
		ID="LoadoutLabel"
		XPosition=0.61
		YPosition=0.66
		XSize=0.28
		YSize=0.04
		AlignX=0
		AlignY=1
	End Object
	Components.Add(LoadoutHeader)

	Begin Object Class=KFGUI_TextLable Name=LoadoutSummary
		ID="LoadoutSummary"
		XPosition=0.675
		YPosition=0.77
		XSize=0.15
		YSize=0.055
		AlignX=1
		AlignY=1
		FontScale=1
		TextFontInfo=(bClipText=false,bEnableShadow=true)
	End Object
	Components.Add(LoadoutSummary)

	Begin Object Class=KFGUI_TextLable Name=PointsLeftSummary
		ID="PointsLeft"
		XPosition=0.19
		YPosition=0.76
		XSize=0.24
		YSize=0.04
		AlignX=1
		AlignY=1
		FontScale=0
		TextFontInfo=(bClipText=true,bEnableShadow=true)
	End Object
	Components.Add(PointsLeftSummary)

	Begin Object Class=KFGUI_Button Name=GrenadePrevButten
		ID="GrenadePrev"
		XPosition=0.61
		YPosition=0.77
		XSize=0.055
		YSize=0.055
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(GrenadePrevButten)

	Begin Object Class=KFGUI_Button Name=GrenadeNextButten
		ID="GrenadeNext"
		XPosition=0.80
		YPosition=0.77
		XSize=0.055
		YSize=0.055
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(GrenadeNextButten)

	Begin Object Class=KFGUI_Button Name=ConfigureButton
		ID="Configure"
		XPosition=0.125
		YPosition=0.82
		XSize=0.40
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(ConfigureButton)

	Begin Object Class=KFGUI_Button Name=TraitTabAllButton
		ID="TraitTabAll"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		FontScale=0
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabAllButton)

	Begin Object Class=KFGUI_Button Name=TraitTabCombatButton
		ID="TraitTabCombat"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		FontScale=0
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabCombatButton)

	Begin Object Class=KFGUI_Button Name=TraitTabSurvivalButton
		ID="TraitTabSurvival"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		FontScale=0
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabSurvivalButton)

	Begin Object Class=KFGUI_Button Name=TraitTabUtilityButton
		ID="TraitTabUtility"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		FontScale=0
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabUtilityButton)

	Begin Object Class=KFGUI_Button Name=TraitTabZedButton
		ID="TraitTabZed"
		XPosition=2.0
		YPosition=2.0
		XSize=0.01
		YSize=0.01
		FontScale=0
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraitTabZedButton)

	Begin Object Class=KFGUI_Button Name=ResetPerkButton
		ID="Reset"
		XPosition=0.60
		YPosition=0.025
		XSize=0.10
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		ExtravDir=1
	End Object
	Begin Object Class=KFGUI_Button Name=UnloadPerkButton
		ID="Unload"
		XPosition=0.705
		YPosition=0.025
		XSize=0.10
		YSize=0.045
		ExtravDir=1
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=PrestigePerkButton
		ID="Prestige"
		XPosition=0.81
		YPosition=0.025
		XSize=0.10
		YSize=0.045
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		bDisabled=true
	End Object

	Components.Add(PerkStats)
	Components.Add(PerkTraits)
	Components.Add(CurPerkLabel)
	Components.Add(ResetPerkButton)
	Components.Add(UnloadPerkButton)
	Components.Add(PrestigePerkButton)
	bUseSpawnedHeader=true
}
