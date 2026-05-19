// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UIP_AdminTools extends KFGUI_MultiComponent;

var KFGUI_TextLable InfoLabel, UtilityCardLabel, ModuleCardLabel;
var KFGUI_Button EnableCheatsButton, GodButton, TraderCommandButton;
var KFGUI_CheckBox DroppedWeaponsBox;

function InitMenu()
{
	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	UtilityCardLabel = KFGUI_TextLable(FindComponentID('UtilityCard'));
	ModuleCardLabel = KFGUI_TextLable(FindComponentID('ModuleCard'));
	EnableCheatsButton = KFGUI_Button(FindComponentID('EnableCheats'));
	GodButton = KFGUI_Button(FindComponentID('God'));
	TraderCommandButton = KFGUI_Button(FindComponentID('TraderCommand'));
	DroppedWeaponsBox = KFGUI_CheckBox(FindComponentID('DroppedWeapons'));

	InfoLabel.SetText("Testing tools for faster local admin checks.");
	UtilityCardLabel.SetText("Test Controls");
	ModuleCardLabel.SetText("Modules");
	EnableCheatsButton.ButtonText = "Toggle Cheats";
	EnableCheatsButton.Tooltip = "Toggle/request local cheat commands for this test session";
	GodButton.ButtonText = "God";
	GodButton.Tooltip = "Toggle Zvampext damage immunity for your player";
	TraderCommandButton.ButtonText = "ImRich";
	TraderCommandButton.Tooltip = "Run the vanilla admin ImRich command for your player";
	DroppedWeaponsBox.LableString = "Dropped weapons overlay";
	DroppedWeaponsBox.Tooltip = "WIP: client toggle placeholder for dropped weapons info";

	DroppedWeaponsBox.SetDisabled(true);

	Super.InitMenu();
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'EnableCheats':
		GetPlayer().ConsoleCommand("Admin EnableCheats");
		GetPlayer().ClientMessage("Requested admin EnableCheats.",'Priority');
		break;
	case 'God':
		ExtPlayerController(GetPlayer()).AdminRevampAction(16);
		break;
	case 'TraderCommand':
		GetPlayer().ConsoleCommand("Admin ImRich");
		GetPlayer().ClientMessage("Requested admin ImRich.",'Priority');
		break;
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_VampModuleFrame Name=TestControlsFrame
		XPosition=0.035
		YPosition=0.18
		XSize=0.76
		YSize=0.24
	End Object
	Components.Add(TestControlsFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=ModulesFrame
		XPosition=0.035
		YPosition=0.44
		XSize=0.76
		YSize=0.36
	End Object
	Components.Add(ModulesFrame)

	Begin Object Class=KFGUI_TextLable Name=AdminToolsInfo
		ID="Info"
		XPosition=0.05
		YPosition=0.08
		XSize=0.9
		YSize=0.08
		AlignX=0
		AlignY=0
	End Object
	Components.Add(AdminToolsInfo)

	Begin Object Class=KFGUI_TextLable Name=UtilityCard
		ID="UtilityCard"
		XPosition=0.055
		YPosition=0.205
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(UtilityCard)

	Begin Object Class=KFGUI_Button Name=EnableCheatsButton
		ID="EnableCheats"
		XPosition=0.055
		YPosition=0.30
		XSize=0.18
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(EnableCheatsButton)

	Begin Object Class=KFGUI_Button Name=GodButton
		ID="God"
		XPosition=0.255
		YPosition=0.30
		XSize=0.14
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(GodButton)

	Begin Object Class=KFGUI_Button Name=TraderCommandButton
		ID="TraderCommand"
		XPosition=0.415
		YPosition=0.30
		XSize=0.12
		YSize=0.06
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Components.Add(TraderCommandButton)

	Begin Object Class=KFGUI_TextLable Name=ModuleCard
		ID="ModuleCard"
		XPosition=0.055
		YPosition=0.465
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(ModuleCard)

	Begin Object Class=KFGUI_CheckBox Name=DroppedWeaponsCheckBox
		ID="DroppedWeapons"
		XPosition=0.055
		YPosition=0.56
		XSize=0.50
		YSize=0.05
	End Object
	Components.Add(DroppedWeaponsCheckBox)
}
