// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UIP_AdminRestrictions extends KFGUI_MultiComponent;

var KFGUI_TextLable InfoLabel, RestrictionCardLabel, OverrideCardLabel;
var KFGUI_Button WeaponButton, PerkButton, ServerButton;
var KFGUI_CheckBox GrenadeDamageBox, GrenadeRadiusBox, AmmoPickupBox, ItemPickupBox, ArmorPickupBox;
var KFGUI_EditBox GrenadeDamageValueBox, GrenadeRadiusValueBox, AmmoPickupValueBox, ItemPickupValueBox, ArmorPickupValueBox;

function InitMenu()
{
	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	RestrictionCardLabel = KFGUI_TextLable(FindComponentID('RestrictionCard'));
	OverrideCardLabel = KFGUI_TextLable(FindComponentID('OverrideCard'));
	WeaponButton = KFGUI_Button(FindComponentID('WeaponRules'));
	PerkButton = KFGUI_Button(FindComponentID('PerkRules'));
	ServerButton = KFGUI_Button(FindComponentID('ServerRules'));
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

	InfoLabel.SetText("Server rule controls for live Endless sessions.");
	RestrictionCardLabel.SetText("Restrictions");
	OverrideCardLabel.SetText("Pickup and Grenade Overrides");
	WeaponButton.ButtonText = "Weapon Rules";
	PerkButton.ButtonText = "Perk Rules";
	ServerButton.ButtonText = "Server Rules";
	WeaponButton.Tooltip = "WIP: weapon allow, ban, and level rules";
	PerkButton.Tooltip = "WIP: perk authority and role rules";
	ServerButton.Tooltip = "WIP: server-side restriction presets";
	WeaponButton.SetDisabled(true);
	PerkButton.SetDisabled(true);
	ServerButton.SetDisabled(true);

	GrenadeDamageBox.LableString = "Grenade Damage";
	GrenadeRadiusBox.LableString = "Grenade Radius";
	AmmoPickupBox.LableString = "Ammo Pickup";
	ItemPickupBox.LableString = "Item Pickup";
	ArmorPickupBox.LableString = "Armor Pickup";
	GrenadeDamageBox.Tooltip = "Enable admin grenade damage scaling";
	GrenadeRadiusBox.Tooltip = "Enable admin grenade radius scaling";
	AmmoPickupBox.Tooltip = "Enable admin ammo pickup scaling";
	ItemPickupBox.Tooltip = "Enable admin item pickup scaling";
	ArmorPickupBox.Tooltip = "Enable admin armor pickup scaling";
	GrenadeDamageValueBox.Tooltip = "Grenade damage scale";
	GrenadeRadiusValueBox.Tooltip = "Grenade radius scale";
	AmmoPickupValueBox.Tooltip = "Ammo pickup scale";
	ItemPickupValueBox.Tooltip = "Item pickup scale";
	ArmorPickupValueBox.Tooltip = "Armor pickup scale";

	Super.InitMenu();
}

function DrawMenu()
{
	local ExtPlayerController PC;

	Super.DrawMenu();

	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return;

	GrenadeDamageBox.bChecked = PC.bAdminGrenadeDamage;
	GrenadeRadiusBox.bChecked = PC.bAdminGrenadeRadius;
	AmmoPickupBox.bChecked = PC.bAdminAmmoPickup;
	ItemPickupBox.bChecked = PC.bAdminItemPickup;
	ArmorPickupBox.bChecked = PC.bAdminArmorPickup;

	if (!GrenadeDamageValueBox.bIsTyping)
		GrenadeDamageValueBox.ChangeValue(string(PC.AdminGrenadeDamageValue));
	if (!GrenadeRadiusValueBox.bIsTyping)
		GrenadeRadiusValueBox.ChangeValue(string(PC.AdminGrenadeRadiusValue));
	if (!AmmoPickupValueBox.bIsTyping)
		AmmoPickupValueBox.ChangeValue(string(PC.AdminAmmoPickupValue));
	if (!ItemPickupValueBox.bIsTyping)
		ItemPickupValueBox.ChangeValue(string(PC.AdminItemPickupValue));
	if (!ArmorPickupValueBox.bIsTyping)
		ArmorPickupValueBox.ChangeValue(string(PC.AdminArmorPickupValue));
}

final function SubmitOverrideSettings()
{
	ExtPlayerController(GetPlayer()).AdminSetPickupOverrides(
		GrenadeDamageBox.bChecked,float(GrenadeDamageValueBox.Value),
		GrenadeRadiusBox.bChecked,float(GrenadeRadiusValueBox.Value),
		AmmoPickupBox.bChecked,float(AmmoPickupValueBox.Value),
		ItemPickupBox.bChecked,float(ItemPickupValueBox.Value),
		ArmorPickupBox.bChecked,float(ArmorPickupValueBox.Value));
}

function ToggleCheckBox(KFGUI_CheckBox Sender)
{
	SubmitOverrideSettings();
}

function ValueChanged(KFGUI_EditBox Sender)
{
	SubmitOverrideSettings();
}

defaultproperties
{
	Begin Object Class=KFGUI_VampModuleFrame Name=RestrictionFrame
		XPosition=0.035
		YPosition=0.18
		XSize=0.30
		YSize=0.26
	End Object
	Components.Add(RestrictionFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=OverrideFrame
		XPosition=0.365
		YPosition=0.18
		XSize=0.60
		YSize=0.62
	End Object
	Components.Add(OverrideFrame)

	Begin Object Class=KFGUI_TextLable Name=AdminRestrictionsInfo
		ID="Info"
		XPosition=0.05
		YPosition=0.08
		XSize=0.9
		YSize=0.08
		AlignX=0
		AlignY=0
	End Object
	Components.Add(AdminRestrictionsInfo)

	Begin Object Class=KFGUI_TextLable Name=RestrictionCard
		ID="RestrictionCard"
		XPosition=0.055
		YPosition=0.205
		XSize=0.25
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(RestrictionCard)

	Begin Object Class=KFGUI_Button Name=WeaponRulesButton
		ID="WeaponRules"
		XPosition=0.055
		YPosition=0.30
		XSize=0.24
		YSize=0.055
	End Object
	Components.Add(WeaponRulesButton)

	Begin Object Class=KFGUI_Button Name=PerkRulesButton
		ID="PerkRules"
		XPosition=0.055
		YPosition=0.37
		XSize=0.24
		YSize=0.055
	End Object
	Components.Add(PerkRulesButton)

	Begin Object Class=KFGUI_Button Name=ServerRulesButton
		ID="ServerRules"
		XPosition=0.055
		YPosition=0.44
		XSize=0.24
		YSize=0.055
	End Object
	Components.Add(ServerRulesButton)

	Begin Object Class=KFGUI_TextLable Name=OverrideCard
		ID="OverrideCard"
		XPosition=0.385
		YPosition=0.205
		XSize=0.50
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(OverrideCard)

	Begin Object Class=KFGUI_CheckBox Name=GrenadeDamageCheckBox
		ID="GrenadeDamage"
		XPosition=0.385
		YPosition=0.30
		XSize=0.33
		YSize=0.052
		LableWidth=0.80
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadeDamageCheckBox)

	Begin Object Class=KFGUI_EditBox Name=GrenadeDamageValueEdit
		ID="GrenadeDamageValue"
		XPosition=0.75
		YPosition=0.30
		XSize=0.17
		YSize=0.052
		MaxTextLength=12
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadeDamageValueEdit)

	Begin Object Class=KFGUI_CheckBox Name=GrenadeRadiusCheckBox
		ID="GrenadeRadius"
		XPosition=0.385
		YPosition=0.39
		XSize=0.33
		YSize=0.052
		LableWidth=0.80
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(GrenadeRadiusCheckBox)

	Begin Object Class=KFGUI_EditBox Name=GrenadeRadiusValueEdit
		ID="GrenadeRadiusValue"
		XPosition=0.75
		YPosition=0.39
		XSize=0.17
		YSize=0.052
		MaxTextLength=12
		OnTextChange=ValueChanged
	End Object
	Components.Add(GrenadeRadiusValueEdit)

	Begin Object Class=KFGUI_CheckBox Name=AmmoPickupCheckBox
		ID="AmmoPickup"
		XPosition=0.385
		YPosition=0.48
		XSize=0.33
		YSize=0.052
		LableWidth=0.80
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(AmmoPickupCheckBox)

	Begin Object Class=KFGUI_EditBox Name=AmmoPickupValueEdit
		ID="AmmoPickupValue"
		XPosition=0.75
		YPosition=0.48
		XSize=0.17
		YSize=0.052
		MaxTextLength=12
		OnTextChange=ValueChanged
	End Object
	Components.Add(AmmoPickupValueEdit)

	Begin Object Class=KFGUI_CheckBox Name=ItemPickupCheckBox
		ID="ItemPickup"
		XPosition=0.385
		YPosition=0.57
		XSize=0.33
		YSize=0.052
		LableWidth=0.80
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ItemPickupCheckBox)

	Begin Object Class=KFGUI_EditBox Name=ItemPickupValueEdit
		ID="ItemPickupValue"
		XPosition=0.75
		YPosition=0.57
		XSize=0.17
		YSize=0.052
		MaxTextLength=12
		OnTextChange=ValueChanged
	End Object
	Components.Add(ItemPickupValueEdit)

	Begin Object Class=KFGUI_CheckBox Name=ArmorPickupCheckBox
		ID="ArmorPickup"
		XPosition=0.385
		YPosition=0.66
		XSize=0.33
		YSize=0.052
		LableWidth=0.80
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(ArmorPickupCheckBox)

	Begin Object Class=KFGUI_EditBox Name=ArmorPickupValueEdit
		ID="ArmorPickupValue"
		XPosition=0.75
		YPosition=0.66
		XSize=0.17
		YSize=0.052
		MaxTextLength=12
		OnTextChange=ValueChanged
	End Object
	Components.Add(ArmorPickupValueEdit)
}
