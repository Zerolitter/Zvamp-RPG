// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UI_AdminResourceLimits extends KFGUI_FloatingWindow;

var KFGUI_TextLable GrenadeDamageLabel, GrenadeRadiusLabel, AmmoPickupLabel, ItemPickupLabel, ArmorPickupLabel;
var KFGUI_CheckBox GrenadeDamageBox, GrenadeRadiusBox, AmmoPickupBox, ItemPickupBox, ArmorPickupBox;
var KFGUI_EditBox GrenadeDamageValueBox, GrenadeRadiusValueBox, AmmoPickupValueBox, ItemPickupValueBox, ArmorPickupValueBox;
var KFGUI_Button ApplyButton, CloseButton;
var bool bInitialising;

function InitMenu()
{
	local ExtPlayerController PC;

	Super.InitMenu();

	GrenadeDamageLabel = KFGUI_TextLable(FindComponentID('GrenadeDamageLabel'));
	GrenadeRadiusLabel = KFGUI_TextLable(FindComponentID('GrenadeRadiusLabel'));
	AmmoPickupLabel = KFGUI_TextLable(FindComponentID('AmmoPickupLabel'));
	ItemPickupLabel = KFGUI_TextLable(FindComponentID('ItemPickupLabel'));
	ArmorPickupLabel = KFGUI_TextLable(FindComponentID('ArmorPickupLabel'));
	GrenadeDamageBox = KFGUI_CheckBox(FindComponentID('GrenadeDamage'));
	GrenadeRadiusBox = KFGUI_CheckBox(FindComponentID('GrenadeRadius'));
	AmmoPickupBox = KFGUI_CheckBox(FindComponentID('AmmoPickup'));
	ItemPickupBox = KFGUI_CheckBox(FindComponentID('ItemPickup'));
	ArmorPickupBox = KFGUI_CheckBox(FindComponentID('ArmorPickup'));
	GrenadeDamageValueBox = KFGUI_EditBox(FindComponentID('GrenadeDamageValue'));
	GrenadeRadiusValueBox = KFGUI_EditBox(FindComponentID('GrenadeRadiusValue'));
	AmmoPickupValueBox = KFGUI_EditBox(FindComponentID('AmmoPickupValue'));
	ItemPickupValueBox = KFGUI_EditBox(FindComponentID('ItemPickupValue'));
	ArmorPickupValueBox = KFGUI_EditBox(FindComponentID('ArmorPickupValue'));
	ApplyButton = KFGUI_Button(FindComponentID('Apply'));
	CloseButton = KFGUI_Button(FindComponentID('Close'));

	WindowTitle = "Resource Limits";
	GrenadeDamageLabel.SetText("Grenade Damage");
	GrenadeRadiusLabel.SetText("Grenade Radius");
	AmmoPickupLabel.SetText("Ammo Pickup");
	ItemPickupLabel.SetText("Item Pickup");
	ArmorPickupLabel.SetText("Armor Pickup");
	ApplyButton.ButtonText = "APPLY";
	CloseButton.ButtonText = "CLOSE";

	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
	{
		bInitialising = true;
		GrenadeDamageBox.bChecked = PC.bAdminGrenadeDamage;
		GrenadeRadiusBox.bChecked = PC.bAdminGrenadeRadius;
		AmmoPickupBox.bChecked = PC.bAdminAmmoPickup;
		ItemPickupBox.bChecked = PC.bAdminItemPickup;
		ArmorPickupBox.bChecked = PC.bAdminArmorPickup;
		GrenadeDamageValueBox.ChangeValue(FloatTwo(PC.AdminGrenadeDamageValue));
		GrenadeRadiusValueBox.ChangeValue(FloatTwo(PC.AdminGrenadeRadiusValue));
		AmmoPickupValueBox.ChangeValue(FloatTwo(PC.AdminAmmoPickupValue));
		ItemPickupValueBox.ChangeValue(FloatTwo(PC.AdminItemPickupValue));
		ArmorPickupValueBox.ChangeValue(FloatTwo(PC.AdminArmorPickupValue));
		bInitialising = false;
	}
}

final function string FloatTwo(float Value)
{
	local int Scaled, Whole, Fraction;

	Scaled = Max(Round(Value * 100.f), 0);
	Whole = Scaled / 100;
	Fraction = Scaled - (Whole * 100);
	return string(Whole)$"."$(Fraction<10 ? "0" : "")$string(Fraction);
}

function SubmitSettings()
{
	if (bInitialising)
		return;

	ExtPlayerController(GetPlayer()).AdminSetPickupOverrides(
		GrenadeDamageBox.bChecked,float(GrenadeDamageValueBox.Value),
		GrenadeRadiusBox.bChecked,float(GrenadeRadiusValueBox.Value),
		AmmoPickupBox.bChecked,float(AmmoPickupValueBox.Value),
		ItemPickupBox.bChecked,float(ItemPickupValueBox.Value),
		ArmorPickupBox.bChecked,float(ArmorPickupValueBox.Value));
}

function ToggleCheckBox(KFGUI_CheckBox Sender)
{
	SubmitSettings();
}

function ValueChanged(KFGUI_EditBox Sender)
{
	SubmitSettings();
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Apply':
		SubmitSettings();
		break;
	case 'Close':
		DoClose();
		break;
	}
}

defaultproperties
{
	XPosition=0.33
	YPosition=0.27
	XSize=0.34
	YSize=0.46
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextLable Name=GrenadeDamageText
		ID="GrenadeDamageLabel"
		XPosition=0.07
		YPosition=0.18
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(GrenadeDamageText)

	Begin Object Class=KFGUI_TextLable Name=GrenadeRadiusText
		ID="GrenadeRadiusLabel"
		XPosition=0.07
		YPosition=0.29
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(GrenadeRadiusText)

	Begin Object Class=KFGUI_TextLable Name=AmmoPickupText
		ID="AmmoPickupLabel"
		XPosition=0.07
		YPosition=0.40
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(AmmoPickupText)

	Begin Object Class=KFGUI_TextLable Name=ItemPickupText
		ID="ItemPickupLabel"
		XPosition=0.07
		YPosition=0.51
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(ItemPickupText)

	Begin Object Class=KFGUI_TextLable Name=ArmorPickupText
		ID="ArmorPickupLabel"
		XPosition=0.07
		YPosition=0.62
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(ArmorPickupText)

	Begin Object Class=KFGUI_CheckBox Name=GrenadeDamageCheckBox
		ID="GrenadeDamage"
		XPosition=0.56
		YPosition=0.18
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadeDamageCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=GrenadeRadiusCheckBox
		ID="GrenadeRadius"
		XPosition=0.56
		YPosition=0.29
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadeRadiusCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=AmmoPickupCheckBox
		ID="AmmoPickup"
		XPosition=0.56
		YPosition=0.40
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(AmmoPickupCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=ItemPickupCheckBox
		ID="ItemPickup"
		XPosition=0.56
		YPosition=0.51
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ItemPickupCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=ArmorPickupCheckBox
		ID="ArmorPickup"
		XPosition=0.56
		YPosition=0.62
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ArmorPickupCheckBox)

	Begin Object Class=KFGUI_EditBox Name=GrenadeDamageValueEdit
		ID="GrenadeDamageValue"
		XPosition=0.72
		YPosition=0.18
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadeDamageValueEdit)

	Begin Object Class=KFGUI_EditBox Name=GrenadeRadiusValueEdit
		ID="GrenadeRadiusValue"
		XPosition=0.72
		YPosition=0.29
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadeRadiusValueEdit)

	Begin Object Class=KFGUI_EditBox Name=AmmoPickupValueEdit
		ID="AmmoPickupValue"
		XPosition=0.72
		YPosition=0.40
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(AmmoPickupValueEdit)

	Begin Object Class=KFGUI_EditBox Name=ItemPickupValueEdit
		ID="ItemPickupValue"
		XPosition=0.72
		YPosition=0.51
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(ItemPickupValueEdit)

	Begin Object Class=KFGUI_EditBox Name=ArmorPickupValueEdit
		ID="ArmorPickupValue"
		XPosition=0.72
		YPosition=0.62
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(ArmorPickupValueEdit)

	Begin Object Class=KFGUI_Button_Tint Name=ApplyButton
		ID="Apply"
		XPosition=0.29
		YPosition=0.80
		XSize=0.18
		YSize=0.08
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(ApplyButton)

	Begin Object Class=KFGUI_Button_Tint Name=CloseButton
		ID="Close"
		XPosition=0.53
		YPosition=0.80
		XSize=0.18
		YSize=0.08
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(CloseButton)
}
