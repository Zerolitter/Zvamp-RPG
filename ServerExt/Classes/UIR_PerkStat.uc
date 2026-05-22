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

Class UIR_PerkStat extends KFGUI_MultiComponent;

var KFGUI_Button CostButton;
var KFGUI_ZvampInvisibleHotspot StatTitleHotspot;

var Ext_PerkBase MyPerk;
var int StatIndex,OldValue,OldPoints,OldPendingAmount,CurrentCost,CurrentBuyAmount,MaxStatValue;
var string ProgressStr;
var bool bCostDirty;

var localized string AddButtonToolTip;
var localized string CostText;

function InitMenu()
{
	CostButton = KFGUI_Button(FindComponentID('CostBox'));
	StatTitleHotspot = new(Self) class'KFGUI_ZvampInvisibleHotspot';
	StatTitleHotspot.SetPosition(0.f,0.f,0.31,1.f);
	Components.AddItem(StatTitleHotspot);

	CostButton.ToolTip=AddButtonToolTip;

	Super.InitMenu();
}

function ShowMenu()
{
	Super.ShowMenu();
	OldValue = -1;
	OldPoints = -1;
	OldPendingAmount = -1;
	SetTimer(0.1,true);
	UpdateStepInfo();
}

function CloseMenu()
{
	Super.CloseMenu();
	MyPerk = None;
	SetTimer(0,false);
}

function SetActivePerk(Ext_PerkBase P)
{
	MyPerk = P;
	OldValue = -1;
	OldPoints = -1;
	OldPendingAmount = -1;
	UpdateStepInfo();
}

function Timer()
{
	local ExtPlayerController PC;
	local int PendingAmount;

	if (MyPerk==None || StatIndex>=MyPerk.PerkStats.Length)
		return;

	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
		PendingAmount = PC.GetPendingStatBuyAmount(MyPerk.Class,StatIndex);

	if (OldValue!=MyPerk.PerkStats[StatIndex].CurrentValue || OldPoints!=MyPerk.CurrentSP || OldPendingAmount!=PendingAmount || bCostDirty)
	{
		bCostDirty = false;
		OldValue = MyPerk.PerkStats[StatIndex].CurrentValue;
		OldPoints = MyPerk.CurrentSP;
		OldPendingAmount = PendingAmount;
		UpdateStepInfo();
		if (CurrentCost > 0)
			CostButton.ButtonText = string(CurrentCost);
		else
			CostButton.ButtonText = "-";
	}
}

function BuyStatPoint(KFGUI_Button Sender)
{
	if (MyPerk!=None && StatIndex<MyPerk.PerkStats.Length && CurrentBuyAmount>0)
	{
		ExtPlayerController(GetPlayer()).QueuePerkStatBuy(MyPerk.Class,StatIndex,CurrentBuyAmount);
		bCostDirty = true;
	}
}

function OpenBuyAmountPopup(KFGUI_Button Sender)
{
	local UIR_StatBuyAmountPopup T;

	if (MyPerk==None || StatIndex>=MyPerk.PerkStats.Length || CurrentBuyAmount<=0)
		return;

	T = UIR_StatBuyAmountPopup(Owner.OpenMenu(class'UIR_StatBuyAmountPopup'));
	if (T!=None)
		T.SetupTo(MyPerk,StatIndex);
}

function ScrollMouseWheel(bool bUp)
{
	if (ParentComponent!=None)
		ParentComponent.ScrollMouseWheel(bUp);
}

function DrawMenu()
{
	local ExtPlayerController PC;
	local int PendingAmount;
	local float BarX,BarY,BarW,BarH,FillW,PendingFillW,TS,XL,YL,ProgressValue,PendingProgressValue,MaxProgressValue,VisibleProgressPercent,NameX;
	local string NameText,ValueText;

	if (MyPerk==None || StatIndex>=MyPerk.PerkStats.Length)
		return;

	BarX = CompPos[2]*0.36f;
	BarY = CompPos[3]*0.30f;
	BarW = CompPos[2]*0.61f;
	BarH = CompPos[3]*0.42f;
	NameX = CompPos[2]*0.025f;
	NameText = GetShortStatName(MyPerk.PerkStats[StatIndex].StatType);

	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(12,14,19,245);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	Canvas.SetDrawColor(34,38,46,210);
	Canvas.SetPos(0.f,CompPos[3]-1.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],1.f);

	Canvas.Font = Owner.CurrentStyle.PickFont(Owner.CurrentStyle.DefaultFontSize,TS);
	Canvas.TextSize(NameText,XL,YL,TS,TS);
	Canvas.SetPos(NameX,(CompPos[3]-YL)*0.5f);
	Canvas.SetDrawColor(246,242,230,255);
	Canvas.DrawText(NameText,,TS,TS);

	Canvas.SetPos(BarX,BarY);
	Canvas.SetDrawColor(66,68,78,255);
	Owner.CurrentStyle.DrawWhiteBox(BarW,BarH);
	Canvas.SetPos(BarX+3.f,BarY+3.f);
	Canvas.SetDrawColor(18,19,25,255);
	Owner.CurrentStyle.DrawWhiteBox(BarW-6.f,BarH-6.f);

	ProgressValue = MyPerk.PerkStats[StatIndex].CurrentValue * MyPerk.PerkStats[StatIndex].Progress;
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
		PendingAmount = PC.GetPendingStatBuyAmount(MyPerk.Class,StatIndex);
	PendingProgressValue = (MyPerk.PerkStats[StatIndex].CurrentValue+PendingAmount) * MyPerk.PerkStats[StatIndex].Progress;
	MaxProgressValue = MyPerk.PerkStats[StatIndex].MaxValue * MyPerk.PerkStats[StatIndex].Progress;
	if (MaxProgressValue>0.f)
	{
		VisibleProgressPercent = FClamp(PendingProgressValue / MaxProgressValue,0.f,1.f) * 100.f;
		FillW = FClamp(ProgressValue / MaxProgressValue,0.f,1.f) * (BarW-6.f);
		PendingFillW = FClamp(PendingProgressValue / MaxProgressValue,0.f,1.f) * (BarW-6.f);
	}
	else FillW = 0.f;
	if (PendingFillW>FillW)
	{
		Canvas.SetPos(BarX+3.f+FillW,BarY+3.f);
		Canvas.SetDrawColor(225,145,42,220);
		Owner.CurrentStyle.DrawWhiteBox(PendingFillW-FillW,BarH-6.f);
	}
	if (FillW>0.f)
	{
		Canvas.SetPos(BarX+3.f,BarY+3.f);
		Canvas.SetDrawColor(76,196,112,255);
		Owner.CurrentStyle.DrawWhiteBox(FillW,BarH-6.f);
	}

	ValueText = ChopExtraDigits(VisibleProgressPercent)$"%";
	Canvas.Font = Owner.CurrentStyle.PickFont(Max(Owner.CurrentStyle.DefaultFontSize-2,0),TS);
	Canvas.TextSize(ValueText,XL,YL,TS,TS);
	Canvas.SetPos(BarX+FMax((BarW-XL)*0.5,2.f),(CompPos[3]-YL)*0.5f);
	Canvas.SetDrawColor(236,232,222,255);
	Canvas.DrawText(ValueText,,TS,TS);

	CostButton.SetPosition(0.250,0.16,0.085,0.68);
	CostButton.ChangeToolTip(GetStatToolTip(MyPerk.PerkStats[StatIndex].StatType, ProgressValue, PendingProgressValue, MaxProgressValue, PendingAmount));
	if (StatTitleHotspot != None)
		StatTitleHotspot.ChangeToolTip(GetStatToolTip(MyPerk.PerkStats[StatIndex].StatType, ProgressValue, PendingProgressValue, MaxProgressValue, PendingAmount));
}

function UpdateStepInfo()
{
	local ExtPlayerController PC;
	local int StepAmount, RemainingValue, AffordableValue, BuyStep, PendingAmount, PendingCost, AvailableSP, CostPerValue;

	if (MyPerk==None || StatIndex>=MyPerk.PerkStats.Length)
		return;

	StepAmount = Max(MyPerk.StatBuyStep,1);
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
	{
		PendingAmount = PC.GetPendingStatBuyAmount(MyPerk.Class,StatIndex);
		PendingCost = PC.GetPendingStatBuyCost(MyPerk.Class);
	}
	CostPerValue = Max(MyPerk.PerkStats[StatIndex].CostPerValue,1);
	AvailableSP = Max(MyPerk.CurrentSP-PendingCost,0);
	RemainingValue = Max(MyPerk.PerkStats[StatIndex].MaxValue-MyPerk.PerkStats[StatIndex].CurrentValue-PendingAmount,0);
	if (MyPerk.PerkStats[StatIndex].CostPerValue<=0)
		AffordableValue = RemainingValue;
	else
		AffordableValue = AvailableSP/CostPerValue;

	BuyStep = Min(StepAmount,RemainingValue);
	CurrentBuyAmount = Min(BuyStep,AffordableValue);
	CurrentCost = CurrentBuyAmount*CostPerValue;
	MaxStatValue = MyPerk.PerkStats[StatIndex].MaxValue;
	ProgressStr = ChopExtraDigits(MyPerk.PerkStats[StatIndex].Progress * CurrentBuyAmount);
	MaxStatValue = MyPerk.PerkStats[StatIndex].MaxValue;
	CostButton.SetDisabled(CurrentBuyAmount<=0);
	if (CurrentCost>0)
		CostButton.ButtonText = string(CurrentCost);
	else CostButton.ButtonText = "-";
}

final function CheckBuyLimit()
{
	if (MyPerk==None || StatIndex>=MyPerk.PerkStats.Length)
		return;

	UpdateStepInfo();
}

final function string GetShortStatName(name StatType)
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
	case 'Armor':
		return "Armor";
	case 'KnockDown':
		return "Knockback";
	case 'HeadDamage':
		return "Headshot";
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
	case 'BossDamageReduction':
		return "BossD Reduc";
	case 'EliteDamageReduction':
		return "EliteD Reduc";
	}
	return string(StatType);
}

final function string GetStatDescription(name StatType)
{
	switch (StatType)
	{
	case 'Speed':
		return "Increases player movement speed.";
	case 'Damage':
		return "Increases damage dealt with this perk's weapons.";
	case 'Recoil':
		return "Reduces weapon recoil for steadier fire.";
	case 'Spread':
		return "Tightens weapon spread and improves accuracy.";
	case 'Rate':
		return "Increases weapon fire rate.";
	case 'Reload':
		return "Increases reload speed.";
	case 'Health':
		return "Increases maximum player health.";
	case 'Armor':
		return "Increases maximum armor.";
	case 'KnockDown':
		return "Improves knockdown and stumble power.";
	case 'HeadDamage':
		return "Increases headshot damage.";
	case 'Mag':
		return "Increases magazine capacity.";
	case 'Spare':
		return "Increases spare ammo capacity.";
	case 'OffDamage':
		return "Increases damage with off-perk weapons.";
	case 'AllDmg':
		return "Gives the player damage reduction against zeds.";
	case 'HealRecharge':
		return "Improves syringe recharge and healing uptime.";
	case 'Switch':
		return "Increases weapon swap speed.";
	case 'BossDamageReduction':
		return "Gives the player damage reduction against bosses.";
	case 'EliteDamageReduction':
		return "Gives the player damage reduction against elite zeds.";
	case 'FireDmg':
		return "Reduces incoming fire damage.";
	case 'SonicDmg':
		return "Reduces incoming sonic damage.";
	case 'PoisonDmg':
		return "Reduces incoming poison damage.";
	}
	return "Improves this RPG stat.";
}

final function string GetStatToolTip(name StatType, float ProgressValue, float PendingProgressValue, float MaxProgressValue, int PendingAmount)
{
	local string S;

	S = GetShortStatName(StatType)$": "$GetStatDescription(StatType)
		$"|Current: "$MyPerk.PerkStats[StatIndex].CurrentValue$" / "$MyPerk.PerkStats[StatIndex].MaxValue$" points"
		$"|Effect: "$ChopExtraDigits(ProgressValue)$"% / "$ChopExtraDigits(MaxProgressValue)$"%";
	if (PendingAmount>0)
		S $= "|Queued: +"$PendingAmount$" point(s), preview "$ChopExtraDigits(PendingProgressValue)$"%";
	return S;
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
	Begin Object Class=KFGUI_ZvampPressButton Name=CostSButton
		ID="CostBox"
		XPosition=0.33
		YPosition=0.05
		XSize=0.11
		YSize=0.90
		ButtonText="-"
		OnClickLeft=BuyStatPoint
		OnClickRight=OpenBuyAmountPopup
	End Object

	Components.Add(CostSButton)
}
