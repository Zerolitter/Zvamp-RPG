// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UI_AdminGrenadeTuning extends KFGUI_FloatingWindow;

var KFGUI_TextLable GrenadeDamageLabel, GrenadeRadiusLabel, ThrowRangeLabel;
var KFGUI_CheckBox GrenadeDamageBox, GrenadeRadiusBox, ThrowRangeBox;
var KFGUI_EditBox GrenadeDamageValueBox, GrenadeRadiusValueBox, ThrowRangeValueBox;
var KFGUI_Button ApplyButton, CloseButton;
var bool bInitialising;

function InitMenu()
{
	local ExtPlayerController PC;

	Super.InitMenu();

	GrenadeDamageLabel = KFGUI_TextLable(FindComponentID('GrenadeDamageLabel'));
	GrenadeRadiusLabel = KFGUI_TextLable(FindComponentID('GrenadeRadiusLabel'));
	ThrowRangeLabel = KFGUI_TextLable(FindComponentID('ThrowRangeLabel'));
	GrenadeDamageBox = KFGUI_CheckBox(FindComponentID('GrenadeDamage'));
	GrenadeRadiusBox = KFGUI_CheckBox(FindComponentID('GrenadeRadius'));
	ThrowRangeBox = KFGUI_CheckBox(FindComponentID('ThrowRange'));
	GrenadeDamageValueBox = KFGUI_EditBox(FindComponentID('GrenadeDamageValue'));
	GrenadeRadiusValueBox = KFGUI_EditBox(FindComponentID('GrenadeRadiusValue'));
	ThrowRangeValueBox = KFGUI_EditBox(FindComponentID('ThrowRangeValue'));
	ApplyButton = KFGUI_Button(FindComponentID('Apply'));
	CloseButton = KFGUI_Button(FindComponentID('Close'));

	WindowTitle = "Grenade Tuning";
	GrenadeDamageLabel.SetText("Grenade Damage");
	GrenadeRadiusLabel.SetText("Grenade Radius");
	ThrowRangeLabel.SetText("Throw Range");
	ApplyButton.ButtonText = "APPLY";
	ApplyButton.ToolTip = "Settings are only sent to the server when APPLY is pressed.";
	CloseButton.ButtonText = "CLOSE";

	PC = ExtPlayerController(GetPlayer());
	if (PC != None)
	{
		bInitialising = true;
		GrenadeDamageBox.bChecked = PC.bAdminGrenadeDamage;
		GrenadeRadiusBox.bChecked = PC.bAdminGrenadeRadius;
		ThrowRangeBox.bChecked = PC.bAdminGrenadeThrowRange;
		GrenadeDamageValueBox.ChangeValue(FloatTwo(PC.AdminGrenadeDamageValue));
		GrenadeRadiusValueBox.ChangeValue(FloatTwo(PC.AdminGrenadeRadiusValue));
		ThrowRangeValueBox.ChangeValue(FloatTwo(PC.AdminGrenadeThrowRangeValue));
		bInitialising = false;
	}
}

final function string FloatTwo(float Value)
{
	local int Scaled, Whole, Fraction;

	Scaled = Max(Round(Value * 100.f), 0);
	Whole = Scaled / 100;
	Fraction = Scaled - (Whole * 100);
	return string(Whole)$"."$(Fraction < 10 ? "0" : "")$string(Fraction);
}

function SubmitSettings()
{
	local ExtPlayerController PC;

	if (bInitialising)
	{
		return;
	}

	PC = ExtPlayerController(GetPlayer());
	if (PC == None)
	{
		return;
	}

	PC.AdminSetGrenadeTuning(
		GrenadeDamageBox.bChecked,float(GrenadeDamageValueBox.Value),
		GrenadeRadiusBox.bChecked,float(GrenadeRadiusValueBox.Value),
		ThrowRangeBox.bChecked,float(ThrowRangeValueBox.Value));
}

function ToggleCheckBox(KFGUI_CheckBox Sender)
{
}

function ValueChanged(KFGUI_EditBox Sender)
{
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
	XPosition=0.36
	YPosition=0.32
	XSize=0.30
	YSize=0.36
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextLable Name=GrenadeDamageText
		ID="GrenadeDamageLabel"
		XPosition=0.08
		YPosition=0.24
		XSize=0.46
		YSize=0.10
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(GrenadeDamageText)

	Begin Object Class=KFGUI_TextLable Name=GrenadeRadiusText
		ID="GrenadeRadiusLabel"
		XPosition=0.08
		YPosition=0.40
		XSize=0.46
		YSize=0.10
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(GrenadeRadiusText)

	Begin Object Class=KFGUI_TextLable Name=ThrowRangeText
		ID="ThrowRangeLabel"
		XPosition=0.08
		YPosition=0.56
		XSize=0.46
		YSize=0.10
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(ThrowRangeText)

	Begin Object Class=KFGUI_CheckBox Name=GrenadeDamageCheckBox
		ID="GrenadeDamage"
		XPosition=0.56
		YPosition=0.24
		XSize=0.08
		YSize=0.10
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadeDamageCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=GrenadeRadiusCheckBox
		ID="GrenadeRadius"
		XPosition=0.56
		YPosition=0.40
		XSize=0.08
		YSize=0.10
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadeRadiusCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=ThrowRangeCheckBox
		ID="ThrowRange"
		XPosition=0.56
		YPosition=0.56
		XSize=0.08
		YSize=0.10
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ThrowRangeCheckBox)

	Begin Object Class=KFGUI_EditBox Name=GrenadeDamageValueEdit
		ID="GrenadeDamageValue"
		XPosition=0.72
		YPosition=0.24
		XSize=0.18
		YSize=0.10
		MaxTextLength=5
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadeDamageValueEdit)

	Begin Object Class=KFGUI_EditBox Name=GrenadeRadiusValueEdit
		ID="GrenadeRadiusValue"
		XPosition=0.72
		YPosition=0.40
		XSize=0.18
		YSize=0.10
		MaxTextLength=5
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadeRadiusValueEdit)

	Begin Object Class=KFGUI_EditBox Name=ThrowRangeValueEdit
		ID="ThrowRangeValue"
		XPosition=0.72
		YPosition=0.56
		XSize=0.18
		YSize=0.10
		MaxTextLength=5
		OnTextChange=ValueChanged
	End Object
	Components.Add(ThrowRangeValueEdit)

	Begin Object Class=KFGUI_Button_Tint Name=ApplyButton
		ID="Apply"
		XPosition=0.28
		YPosition=0.78
		XSize=0.22
		YSize=0.11
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(ApplyButton)

	Begin Object Class=KFGUI_Button_Tint Name=CloseButton
		ID="Close"
		XPosition=0.55
		YPosition=0.78
		XSize=0.22
		YSize=0.11
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(CloseButton)
}
