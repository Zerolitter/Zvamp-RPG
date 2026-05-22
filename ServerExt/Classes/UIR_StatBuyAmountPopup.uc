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

Class UIR_StatBuyAmountPopup extends KFGUI_FloatingWindow;

var KFGUI_TextField InfoText;
var KFGUI_NumericBox AmountBox;
var KFGUI_Button BuyButton;
var KFGUI_Button Add5Button, Add25Button, Add100Button;
var KFGUI_Button CancelButton;

var Ext_PerkBase MyPerk;
var int StatIndex, MaxBuyAmount, OldPoints, OldValue, OldPendingAmount;

function InitMenu()
{
	InfoText = KFGUI_TextField(FindComponentID('Info'));
	AmountBox = KFGUI_NumericBox(FindComponentID('Amount'));
	BuyButton = KFGUI_Button(FindComponentID('Buy'));
	Add5Button = KFGUI_Button(FindComponentID('Add5'));
	Add25Button = KFGUI_Button(FindComponentID('Add25'));
	Add100Button = KFGUI_Button(FindComponentID('Add100'));
	CancelButton = KFGUI_Button(FindComponentID('Cancel'));

	BuyButton.ButtonText = "BUY";
	Add5Button.ButtonText = "ADD 5";
	Add25Button.ButtonText = "ADD 25";
	Add100Button.ButtonText = "ADD 100";
	CancelButton.ButtonText = "CANCEL";
	BuyButton.ToolTip = "Queue this stat purchase. Use COMMIT SP on the perk screen to save it.";
	Add5Button.ToolTip = "Queue 5 points or the maximum affordable amount.";
	Add25Button.ToolTip = "Queue 25 points or the maximum affordable amount.";
	Add100Button.ToolTip = "Queue 100 points or the maximum affordable amount.";
	CancelButton.ToolTip = "Close without adding more queued points.";
	AmountBox.OnTextChange = AmountChanged;
	AmountBox.OnHitEnter = AmountHitEnter;

	Super.InitMenu();
}

function CloseMenu()
{
	Super.CloseMenu();
	MyPerk = None;
	SetTimer(0,false);
}

function SetupTo(Ext_PerkBase Perk, int Index)
{
	MyPerk = Perk;
	StatIndex = Index;
	OldPoints = -1;
	OldValue = -1;
	OldPendingAmount = -1;
	WindowTitle = "Buy "$GetShortStatName();
	UpdateInfo();
	SetTimer(0.2,true);
}

function Timer()
{
	local ExtPlayerController PC;
	local int PendingAmount;

	if (MyPerk==None || StatIndex<0 || StatIndex>=MyPerk.PerkStats.Length)
	{
		DoClose();
		return;
	}

	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
		PendingAmount = PC.GetPendingStatBuyAmount(MyPerk.Class,StatIndex);

	if (OldPoints!=MyPerk.CurrentSP || OldValue!=MyPerk.PerkStats[StatIndex].CurrentValue || OldPendingAmount!=PendingAmount)
		UpdateInfo();
}

final function UpdateInfo()
{
	local ExtPlayerController PC;
	local int RemainingValue, AffordableValue, DefaultAmount, CostPerValue, PendingAmount, PendingCost, AvailableSP;
	local string S;

	if (MyPerk==None || StatIndex<0 || StatIndex>=MyPerk.PerkStats.Length)
		return;

	OldPoints = MyPerk.CurrentSP;
	OldValue = MyPerk.PerkStats[StatIndex].CurrentValue;
	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
	{
		PendingAmount = PC.GetPendingStatBuyAmount(MyPerk.Class,StatIndex);
		PendingCost = PC.GetPendingStatBuyCost(MyPerk.Class);
	}
	OldPendingAmount = PendingAmount;
	CostPerValue = Max(MyPerk.PerkStats[StatIndex].CostPerValue,1);
	AvailableSP = Max(MyPerk.CurrentSP-PendingCost,0);
	RemainingValue = Max(MyPerk.PerkStats[StatIndex].MaxValue-MyPerk.PerkStats[StatIndex].CurrentValue-PendingAmount,0);
	AffordableValue = AvailableSP/CostPerValue;
	MaxBuyAmount = Min(RemainingValue,AffordableValue);
	DefaultAmount = Min(Max(MyPerk.StatBuyStep,1),MaxBuyAmount);

	AmountBox.MinValue = 1;
	AmountBox.MaxValue = Max(MaxBuyAmount,1);
	if (int(AmountBox.Value)<=0 || int(AmountBox.Value)>MaxBuyAmount)
		AmountBox.ChangeValue(string(Max(DefaultAmount,1)));
	else AmountBox.ValidateValue();

	S = "Stat: #{9FF781}"$GetShortStatName()$"#{DEF}";
	S $= "|Current points: #{F3F781}"$MyPerk.PerkStats[StatIndex].CurrentValue$" / "$MyPerk.PerkStats[StatIndex].MaxValue$"#{DEF}";
	S $= "|Arrange XP after queue: #{F3F781}"$AvailableSP$"#{DEF}";
	S $= "|Queued on this stat: #{F3F781}"$PendingAmount$"#{DEF}";
	S $= "|Cost per point: #{F3F781}"$CostPerValue$"#{DEF}";
	S $= "|Can add now: #{F3F781}"$MaxBuyAmount$"#{DEF}";
	S $= "|Purchases remain queued until COMMIT SP.";
	InfoText.SetText(S);

	RefreshBuyButton();
}

function AmountChanged(KFGUI_EditBox Sender)
{
	RefreshBuyButton();
}

function bool AmountHitEnter(KFGUI_EditBox Sender)
{
	BuySelectedAmount();
	return false;
}

final function RefreshBuyButton()
{
	local int Amount, CostPerValue;

	if (MyPerk==None || StatIndex<0 || StatIndex>=MyPerk.PerkStats.Length || MaxBuyAmount<=0)
	{
		BuyButton.ButtonText = "BUY";
		BuyButton.SetDisabled(true);
		Add5Button.SetDisabled(true);
		Add25Button.SetDisabled(true);
		Add100Button.SetDisabled(true);
		return;
	}

	CostPerValue = Max(MyPerk.PerkStats[StatIndex].CostPerValue,1);
	Amount = Clamp(AmountBox.GetValueInt(),1,MaxBuyAmount);
	BuyButton.ButtonText = "BUY ("$(Amount*CostPerValue)$")";
	BuyButton.SetDisabled(Amount<=0);
	Add5Button.SetDisabled(MaxBuyAmount<1);
	Add25Button.SetDisabled(MaxBuyAmount<1);
	Add100Button.SetDisabled(MaxBuyAmount<1);
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Buy':
		BuySelectedAmount();
		break;
	case 'Add5':
		BuyQuickAmount(5);
		break;
	case 'Add25':
		BuyQuickAmount(25);
		break;
	case 'Add100':
		BuyQuickAmount(100);
		break;
	case 'Cancel':
		DoClose();
		break;
	}
}

final function BuyQuickAmount(int DesiredAmount)
{
	local int Amount;

	if (MyPerk==None || StatIndex<0 || StatIndex>=MyPerk.PerkStats.Length || MaxBuyAmount<=0)
		return;

	Amount = Clamp(DesiredAmount,1,MaxBuyAmount);
	if (Amount>0)
		ExtPlayerController(GetPlayer()).QueuePerkStatBuy(MyPerk.Class,StatIndex,Amount,true);
	UpdateInfo();
}

final function BuySelectedAmount()
{
	local int Amount;

	if (MyPerk==None || StatIndex<0 || StatIndex>=MyPerk.PerkStats.Length || MaxBuyAmount<=0)
		return;

	AmountBox.ValidateValue();
	Amount = Clamp(AmountBox.GetValueInt(),1,MaxBuyAmount);
	if (Amount>0)
		ExtPlayerController(GetPlayer()).QueuePerkStatBuy(MyPerk.Class,StatIndex,Amount,true);
	DoClose();
}

final function string GetShortStatName()
{
	if (MyPerk==None || StatIndex<0 || StatIndex>=MyPerk.PerkStats.Length)
		return "Stat";

	switch (MyPerk.PerkStats[StatIndex].StatType)
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
	return string(MyPerk.PerkStats[StatIndex].StatType);
}

defaultproperties
{
	XPosition=0.315
	YPosition=0.235
	XSize=0.37
	YSize=0.48
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextField Name=AmountInfo
		ID="Info"
		XPosition=0.06
		YPosition=0.12
		XSize=0.88
		YSize=0.43
	End Object
	Components.Add(AmountInfo)

	Begin Object Class=KFGUI_NumericBox Name=AmountInput
		ID="Amount"
		XPosition=0.32
		YPosition=0.58
		XSize=0.36
		YSize=0.08
		MinValue=1
		MaxValue=999999
		MaxTextLength=6
	End Object
	Components.Add(AmountInput)

	Begin Object Class=KFGUI_Button Name=Add5AmountButton
		ID="Add5"
		XPosition=0.08
		YPosition=0.70
		XSize=0.25
		YSize=0.10
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(Add5AmountButton)

	Begin Object Class=KFGUI_Button Name=Add25AmountButton
		ID="Add25"
		XPosition=0.375
		YPosition=0.70
		XSize=0.25
		YSize=0.10
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(Add25AmountButton)

	Begin Object Class=KFGUI_Button Name=Add100AmountButton
		ID="Add100"
		XPosition=0.67
		YPosition=0.70
		XSize=0.25
		YSize=0.10
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(Add100AmountButton)

	Begin Object Class=KFGUI_Button Name=BuyAmountButton
		ID="Buy"
		XPosition=0.16
		YPosition=0.855
		XSize=0.32
		YSize=0.10
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(BuyAmountButton)

	Begin Object Class=KFGUI_Button Name=CancelAmountButton
		ID="Cancel"
		XPosition=0.52
		YPosition=0.855
		XSize=0.32
		YSize=0.10
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(CancelAmountButton)
}
