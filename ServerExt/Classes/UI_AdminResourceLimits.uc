// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UI_AdminResourceLimits extends KFGUI_FloatingWindow;

var KFGUI_TextLable AmmoBoxCountLabel, ItemBoxCountLabel, PickupRespawnLabel, GrenadesFromAmmoLabel, ArmorFromAmmoLabel;
var KFGUI_CheckBox AmmoBoxCountBox, ItemBoxCountBox, PickupRespawnBox, GrenadesFromAmmoBox, ArmorFromAmmoBox;
var KFGUI_EditBox AmmoBoxCountValueBox, ItemBoxCountValueBox, PickupRespawnValueBox, GrenadesFromAmmoValueBox, ArmorFromAmmoValueBox;
var KFGUI_Button ApplyButton, CloseButton;
var bool bInitialising;

function InitMenu()
{
	local ExtPlayerController PC;

	Super.InitMenu();

	AmmoBoxCountLabel = KFGUI_TextLable(FindComponentID('AmmoBoxCountLabel'));
	ItemBoxCountLabel = KFGUI_TextLable(FindComponentID('ItemBoxCountLabel'));
	PickupRespawnLabel = KFGUI_TextLable(FindComponentID('PickupRespawnLabel'));
	GrenadesFromAmmoLabel = KFGUI_TextLable(FindComponentID('GrenadesFromAmmoLabel'));
	ArmorFromAmmoLabel = KFGUI_TextLable(FindComponentID('ArmorFromAmmoLabel'));
	AmmoBoxCountBox = KFGUI_CheckBox(FindComponentID('AmmoBoxCount'));
	ItemBoxCountBox = KFGUI_CheckBox(FindComponentID('ItemBoxCount'));
	PickupRespawnBox = KFGUI_CheckBox(FindComponentID('PickupRespawn'));
	GrenadesFromAmmoBox = KFGUI_CheckBox(FindComponentID('GrenadesFromAmmo'));
	ArmorFromAmmoBox = KFGUI_CheckBox(FindComponentID('ArmorFromAmmo'));
	AmmoBoxCountValueBox = KFGUI_EditBox(FindComponentID('AmmoBoxCountValue'));
	ItemBoxCountValueBox = KFGUI_EditBox(FindComponentID('ItemBoxCountValue'));
	PickupRespawnValueBox = KFGUI_EditBox(FindComponentID('PickupRespawnValue'));
	GrenadesFromAmmoValueBox = KFGUI_EditBox(FindComponentID('GrenadesFromAmmoValue'));
	ArmorFromAmmoValueBox = KFGUI_EditBox(FindComponentID('ArmorFromAmmoValue'));
	ApplyButton = KFGUI_Button(FindComponentID('Apply'));
	CloseButton = KFGUI_Button(FindComponentID('Close'));

	WindowTitle = "Resource Limits";
	AmmoBoxCountLabel.SetText("Ammo Boxes");
	ItemBoxCountLabel.SetText("Weapons / Items");
	PickupRespawnLabel.SetText("Respawn Seconds");
	GrenadesFromAmmoLabel.SetText("Grenades / Ammo Box");
	ArmorFromAmmoLabel.SetText("Armor / Ammo Box");
	ApplyButton.ButtonText = "APPLY";
	ApplyButton.ToolTip = "Settings are only sent to the server when APPLY is pressed.";
	CloseButton.ButtonText = "CLOSE";

	PC = ExtPlayerController(GetPlayer());
	if (PC!=None)
	{
		bInitialising = true;
		AmmoBoxCountBox.bChecked = PC.bAdminAmmoBoxCount;
		ItemBoxCountBox.bChecked = PC.bAdminItemBoxCount;
		PickupRespawnBox.bChecked = PC.bAdminPickupRespawnTime;
		GrenadesFromAmmoBox.bChecked = PC.bAdminGrenadesFromAmmo;
		ArmorFromAmmoBox.bChecked = PC.bAdminAmmoBoxArmor;
		AmmoBoxCountValueBox.ChangeValue(FloatTwo(PC.AdminAmmoBoxCountValue));
		ItemBoxCountValueBox.ChangeValue(FloatTwo(PC.AdminItemBoxCountValue));
		PickupRespawnValueBox.ChangeValue(FloatTwo(PC.AdminPickupRespawnTimeValue));
		GrenadesFromAmmoValueBox.ChangeValue(FloatTwo(PC.AdminGrenadesFromAmmoValue));
		ArmorFromAmmoValueBox.ChangeValue(FloatTwo(PC.AdminAmmoBoxArmorValue));
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

	ExtPlayerController(GetPlayer()).AdminSetResourceLimits(
		AmmoBoxCountBox.bChecked,float(AmmoBoxCountValueBox.Value),
		ItemBoxCountBox.bChecked,float(ItemBoxCountValueBox.Value),
		PickupRespawnBox.bChecked,float(PickupRespawnValueBox.Value),
		GrenadesFromAmmoBox.bChecked,float(GrenadesFromAmmoValueBox.Value),
		ArmorFromAmmoBox.bChecked,float(ArmorFromAmmoValueBox.Value));
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
	XPosition=0.33
	YPosition=0.27
	XSize=0.34
	YSize=0.46
	bAlwaysTop=true
	bOnlyThisFocus=true

	Begin Object Class=KFGUI_TextLable Name=AmmoBoxCountText
		ID="AmmoBoxCountLabel"
		XPosition=0.07
		YPosition=0.18
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(AmmoBoxCountText)

	Begin Object Class=KFGUI_TextLable Name=ItemBoxCountText
		ID="ItemBoxCountLabel"
		XPosition=0.07
		YPosition=0.29
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(ItemBoxCountText)

	Begin Object Class=KFGUI_TextLable Name=PickupRespawnText
		ID="PickupRespawnLabel"
		XPosition=0.07
		YPosition=0.40
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(PickupRespawnText)

	Begin Object Class=KFGUI_TextLable Name=GrenadesFromAmmoText
		ID="GrenadesFromAmmoLabel"
		XPosition=0.07
		YPosition=0.51
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(GrenadesFromAmmoText)

	Begin Object Class=KFGUI_TextLable Name=ArmorFromAmmoText
		ID="ArmorFromAmmoLabel"
		XPosition=0.07
		YPosition=0.62
		XSize=0.46
		YSize=0.08
		AlignX=0
		AlignY=1
		FontScale=1
	End Object
	Components.Add(ArmorFromAmmoText)

	Begin Object Class=KFGUI_CheckBox Name=AmmoBoxCountCheckBox
		ID="AmmoBoxCount"
		XPosition=0.56
		YPosition=0.18
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(AmmoBoxCountCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=ItemBoxCountCheckBox
		ID="ItemBoxCount"
		XPosition=0.56
		YPosition=0.29
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ItemBoxCountCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=PickupRespawnCheckBox
		ID="PickupRespawn"
		XPosition=0.56
		YPosition=0.40
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(PickupRespawnCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=GrenadesFromAmmoCheckBox
		ID="GrenadesFromAmmo"
		XPosition=0.56
		YPosition=0.51
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadesFromAmmoCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=ArmorFromAmmoCheckBox
		ID="ArmorFromAmmo"
		XPosition=0.56
		YPosition=0.62
		XSize=0.07
		YSize=0.08
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ArmorFromAmmoCheckBox)

	Begin Object Class=KFGUI_EditBox Name=AmmoBoxCountValueEdit
		ID="AmmoBoxCountValue"
		XPosition=0.72
		YPosition=0.18
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(AmmoBoxCountValueEdit)

	Begin Object Class=KFGUI_EditBox Name=ItemBoxCountValueEdit
		ID="ItemBoxCountValue"
		XPosition=0.72
		YPosition=0.29
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(ItemBoxCountValueEdit)

	Begin Object Class=KFGUI_EditBox Name=PickupRespawnValueEdit
		ID="PickupRespawnValue"
		XPosition=0.72
		YPosition=0.40
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(PickupRespawnValueEdit)

	Begin Object Class=KFGUI_EditBox Name=GrenadesFromAmmoValueEdit
		ID="GrenadesFromAmmoValue"
		XPosition=0.72
		YPosition=0.51
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadesFromAmmoValueEdit)

	Begin Object Class=KFGUI_EditBox Name=ArmorFromAmmoValueEdit
		ID="ArmorFromAmmoValue"
		XPosition=0.72
		YPosition=0.62
		XSize=0.18
		YSize=0.08
		MaxTextLength=4
		OnTextChange=ValueChanged
	End Object
	Components.Add(ArmorFromAmmoValueEdit)

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
