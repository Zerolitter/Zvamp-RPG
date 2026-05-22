// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UIP_AdminSettingsDashboard extends KFGUI_MultiComponent;

var KFGUI_TextLable ToolsLabel, TraderLabel, WaveLabel, RestrictionLabel, ServerLabel;
var KFGUI_TextLable TraderGuardLabel, PublicOpenTraderLabel;
var KFGUI_Button EnableCheatsButton, GodButton, ImRichButton, RestartButton;
var KFGUI_Button PauseTraderButton, EndWaveButton, ProgressWaveButton, PauseSpawnsButton, MaxMonstersUpButton, MaxMonstersDownButton, SpawnRateUpButton, SpawnRateDownButton;
var KFGUI_Button AutoMessageButton, MotdButton, BroadcastButton, SaveStatsButton;
var KFGUI_Button ResourceLimitsButton, RestrictionPlaceholder1Button, RestrictionPlaceholder2Button;
var KFGUI_NumericBox ProgressWaveBox;
var KFGUI_CheckBox EnableGuardBox, PublicOpenTraderBox;

function InitMenu()
{
	ToolsLabel = KFGUI_TextLable(FindComponentID('ToolsLabel'));
	TraderLabel = KFGUI_TextLable(FindComponentID('TraderLabel'));
	WaveLabel = KFGUI_TextLable(FindComponentID('WaveLabel'));
	RestrictionLabel = KFGUI_TextLable(FindComponentID('RestrictionLabel'));
	ServerLabel = KFGUI_TextLable(FindComponentID('ServerLabel'));
	TraderGuardLabel = KFGUI_TextLable(FindComponentID('TraderGuardLabel'));
	PublicOpenTraderLabel = KFGUI_TextLable(FindComponentID('PublicOpenTraderLabel'));
	EnableCheatsButton = KFGUI_Button(FindComponentID('EnableCheats'));
	GodButton = KFGUI_Button(FindComponentID('God'));
	ImRichButton = KFGUI_Button(FindComponentID('ImRich'));
	RestartButton = KFGUI_Button(FindComponentID('RestartMap'));
	PauseTraderButton = KFGUI_Button(FindComponentID('PauseTrader'));
	EndWaveButton = KFGUI_Button(FindComponentID('EndWave'));
	ProgressWaveButton = KFGUI_Button(FindComponentID('ProgressWave'));
	ProgressWaveBox = KFGUI_NumericBox(FindComponentID('ProgressWaveValue'));
	PauseSpawnsButton = KFGUI_Button(FindComponentID('PauseSpawns'));
	MaxMonstersUpButton = KFGUI_Button(FindComponentID('MaxMonstersUp'));
	MaxMonstersDownButton = KFGUI_Button(FindComponentID('MaxMonstersDown'));
	SpawnRateUpButton = KFGUI_Button(FindComponentID('SpawnRateUp'));
	SpawnRateDownButton = KFGUI_Button(FindComponentID('SpawnRateDown'));
	AutoMessageButton = KFGUI_Button(FindComponentID('AutoMessage'));
	MotdButton = KFGUI_Button(FindComponentID('MOTD'));
	BroadcastButton = KFGUI_Button(FindComponentID('BroadcastMOTD'));
	SaveStatsButton = KFGUI_Button(FindComponentID('SaveStats'));
	ResourceLimitsButton = KFGUI_Button(FindComponentID('ResourceLimits'));
	RestrictionPlaceholder1Button = KFGUI_Button(FindComponentID('RestrictionPlaceholder1'));
	RestrictionPlaceholder2Button = KFGUI_Button(FindComponentID('RestrictionPlaceholder2'));
	EnableGuardBox = KFGUI_CheckBox(FindComponentID('EnableGuard'));
	PublicOpenTraderBox = KFGUI_CheckBox(FindComponentID('PublicOpenTrader'));

	ToolsLabel.SetText("Tools");
	TraderLabel.SetText("Trader");
	WaveLabel.SetText("Wave");
	RestrictionLabel.SetText("Restrictions");
	ServerLabel.SetText("Server");
	TraderGuardLabel.SetText("TraderGuard");
	PublicOpenTraderLabel.SetText("RvOpenTrader");

	EnableCheatsButton.ButtonText = "Toggle Cheats";
	EnableCheatsButton.Tooltip = "Toggle/request local cheat commands for this test session";
	GodButton.ButtonText = "God";
	GodButton.Tooltip = "Toggle Zvampext damage immunity for your player";
	ImRichButton.ButtonText = "ImRich";
	ImRichButton.Tooltip = "Run the vanilla admin ImRich command for your player";
	RestartButton.ButtonText = "Restart Map";
	RestartButton.Tooltip = "Disabled until the safe KF2 restart path is verified";
	RestartButton.SetDisabled(true);

	PauseTraderButton.ButtonText = "Pause Trader Time";
	PauseTraderButton.Tooltip = "Pause trader countdown without blocking normal skip-trader voting";
	EnableGuardBox.Tooltip = "Enable TraderGuard";
	PublicOpenTraderBox.Tooltip = "Let non-admins use RvOpenTrader when TraderGuard allows it";

	EndWaveButton.ButtonText = "End Wave";
	EndWaveButton.Tooltip = "Warning: clears active zeds and queued spawns to force the wave forward";
	ProgressWaveButton.ButtonText = "Jump";
	ProgressWaveButton.Tooltip = "Jump forward by the selected wave count and enter trader time";
	ProgressWaveBox.ChangeValue("1");
	PauseSpawnsButton.ButtonText = "Pause Spawns";
	PauseSpawnsButton.Tooltip = "Toggle the server spawn manager off or on";
	MaxMonstersUpButton.ButtonText = "Max +4";
	MaxMonstersDownButton.ButtonText = "Max -4";
	SpawnRateUpButton.ButtonText = "Faster";
	SpawnRateDownButton.ButtonText = "Slower";

	AutoMessageButton.ButtonText = "Auto Messages";
	MotdButton.ButtonText = "Edit MOTD";
	BroadcastButton.ButtonText = "Broadcast MOTD";
	SaveStatsButton.ButtonText = "Save Stats";
	ResourceLimitsButton.ButtonText = "Resource Limits";
	ResourceLimitsButton.Tooltip = "Open ammo box, item pickup, respawn, grenade pickup, and armor pickup controls";
	RestrictionPlaceholder1Button.ButtonText = "Grenade Tuning";
	RestrictionPlaceholder1Button.Tooltip = "Open grenade damage and radius controls";
	RestrictionPlaceholder2Button.ButtonText = "Placeholder";
	RestrictionPlaceholder2Button.Tooltip = "Reserved for a future restriction module";

	Super.InitMenu();
}

function DrawMenu()
{
	local ExtPlayerController PC;

	Super.DrawMenu();

	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return;

	EnableGuardBox.bChecked = PC.bRevampTraderGuardEnabled;
	PublicOpenTraderBox.bChecked = PC.bRevampTraderGuardPublicOpenTrader;
}

final function string FloatTwo(float Value)
{
	local int Scaled, Whole, Fraction;

	Scaled = Max(Round(Value * 100.f), 0);
	Whole = Scaled / 100;
	Fraction = Scaled - (Whole * 100);
	return string(Whole)$"."$(Fraction<10 ? "0" : "")$string(Fraction);
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
	case 'ImRich':
		GetPlayer().ConsoleCommand("Admin ImRich");
		GetPlayer().ClientMessage("Requested admin ImRich.",'Priority');
		break;
	case 'RestartMap':
		ExtPlayerController(GetPlayer()).AdminRevampAction(14);
		break;
	case 'PauseTrader':
		ExtPlayerController(GetPlayer()).AdminRevampAction(24);
		break;
	case 'EndWave':
		ExtPlayerController(GetPlayer()).AdminRevampAction(18);
		break;
	case 'ProgressWave':
		ProgressWaveBox.ValidateValue();
		ExtPlayerController(GetPlayer()).AdminProgressWave(ProgressWaveBox.GetValueInt());
		break;
	case 'PauseSpawns':
		ExtPlayerController(GetPlayer()).AdminRevampAction(19);
		break;
	case 'MaxMonstersUp':
		ExtPlayerController(GetPlayer()).AdminRevampAction(20);
		break;
	case 'MaxMonstersDown':
		ExtPlayerController(GetPlayer()).AdminRevampAction(21);
		break;
	case 'SpawnRateUp':
		ExtPlayerController(GetPlayer()).AdminRevampAction(22);
		break;
	case 'SpawnRateDown':
		ExtPlayerController(GetPlayer()).AdminRevampAction(23);
		break;
	case 'AutoMessage':
		Owner.OpenMenu(class'UI_AdminAutoMessage');
		break;
	case 'MOTD':
		Owner.OpenMenu(class'UI_AdminMOTD');
		break;
	case 'BroadcastMOTD':
		ExtPlayerController(GetPlayer()).AdminRevampAction(12);
		break;
	case 'SaveStats':
		ExtPlayerController(GetPlayer()).AdminRevampAction(10);
		break;
	case 'ResourceLimits':
		Owner.OpenMenu(class'UI_AdminResourceLimits');
		break;
	case 'RestrictionPlaceholder1':
		Owner.OpenMenu(class'UI_AdminGrenadeTuning');
		break;
	}
}

function ToggleCheckBox(KFGUI_CheckBox Sender)
{
	switch (Sender.ID)
	{
	case 'EnableGuard':
		ExtPlayerController(GetPlayer()).AdminSetTraderGuard(Sender.bChecked,ExtPlayerController(GetPlayer()).bRevampTraderGuardBlockSkip,ExtPlayerController(GetPlayer()).bRevampTraderGuardPublicOpenTrader);
		break;
	case 'PublicOpenTrader':
		ExtPlayerController(GetPlayer()).AdminSetTraderGuard(ExtPlayerController(GetPlayer()).bRevampTraderGuardEnabled,ExtPlayerController(GetPlayer()).bRevampTraderGuardBlockSkip,Sender.bChecked);
		break;
	}
}

final function SubmitOverrideSettings()
{
}

function ValueChanged(KFGUI_EditBox Sender)
{
	SubmitOverrideSettings();
}

defaultproperties
{
	Begin Object Class=KFGUI_VampModuleFrame Name=ToolsFrame
		XPosition=0.325
		YPosition=0.390
		XSize=0.255
		YSize=0.345
	End Object
	Components.Add(ToolsFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=TraderFrame
		XPosition=0.495
		YPosition=0.130
		XSize=0.320
		YSize=0.260
	End Object
	Components.Add(TraderFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=WaveFrame
		XPosition=0.580
		YPosition=0.390
		XSize=0.235
		YSize=0.345
	End Object
	Components.Add(WaveFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=RestrictionFrame
		XPosition=0.115
		YPosition=0.130
		XSize=0.380
		YSize=0.260
	End Object
	Components.Add(RestrictionFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=ServerFrame
		XPosition=0.115
		YPosition=0.390
		XSize=0.210
		YSize=0.345
	End Object
	Components.Add(ServerFrame)

	Begin Object Class=KFGUI_TextLable Name=ToolsHeader
		ID="ToolsLabel"
		XPosition=0.325
		YPosition=0.390
		XSize=0.255
		YSize=0.06
		AlignX=1
		AlignY=1
		FontScale=2
	End Object
	Components.Add(ToolsHeader)

	Begin Object Class=KFGUI_TextLable Name=TraderHeader
		ID="TraderLabel"
		XPosition=0.495
		YPosition=0.130
		XSize=0.320
		YSize=0.06
		AlignX=1
		AlignY=1
		FontScale=1
	End Object
	Components.Add(TraderHeader)

	Begin Object Class=KFGUI_TextLable Name=WaveHeader
		ID="WaveLabel"
		XPosition=0.580
		YPosition=0.390
		XSize=0.235
		YSize=0.06
		AlignX=1
		AlignY=1
		FontScale=2
	End Object
	Components.Add(WaveHeader)

	Begin Object Class=KFGUI_TextLable Name=RestrictionHeader
		ID="RestrictionLabel"
		XPosition=0.115
		YPosition=0.130
		XSize=0.380
		YSize=0.06
		AlignX=1
		AlignY=1
		FontScale=1
	End Object
	Components.Add(RestrictionHeader)

	Begin Object Class=KFGUI_TextLable Name=ServerHeader
		ID="ServerLabel"
		XPosition=0.115
		YPosition=0.390
		XSize=0.210
		YSize=0.06
		AlignX=1
		AlignY=1
		FontScale=2
		TextColor=(R=255,G=226,B=255,A=255)
	End Object
	Components.Add(ServerHeader)

	Begin Object Class=KFGUI_Button_Tint Name=EnableCheatsButton
		ID="EnableCheats"
		XPosition=0.350
		YPosition=0.540
		XSize=0.200
		YSize=0.055
		ButtonColor=(R=103,G=28,B=146,A=235)
		HoverColor=(R=132,G=39,B=188,A=245)
		PressedColor=(R=75,G=18,B=112,A=245)
		AccentColor=(R=212,G=78,B=255,A=150)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(EnableCheatsButton)

	Begin Object Class=KFGUI_Button_Tint Name=GodButton
		ID="God"
		XPosition=0.350
		YPosition=0.635
		XSize=0.085
		YSize=0.055
		ButtonColor=(R=42,G=54,B=156,A=235)
		HoverColor=(R=62,G=80,B=205,A=245)
		PressedColor=(R=24,G=34,B=110,A=245)
		AccentColor=(R=120,G=140,B=255,A=150)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(GodButton)

	Begin Object Class=KFGUI_Button_Tint Name=ImRichButton
		ID="ImRich"
		XPosition=0.435
		YPosition=0.635
		XSize=0.085
		YSize=0.055
		ButtonColor=(R=174,G=18,B=216,A=235)
		HoverColor=(R=214,G=42,B=252,A=245)
		PressedColor=(R=126,G=8,B=168,A=245)
		AccentColor=(R=245,G=120,B=255,A=150)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(ImRichButton)

	Begin Object Class=KFGUI_Button_Tint Name=RestartMapButton
		ID="RestartMap"
		XPosition=0.360
		YPosition=0.455
		XSize=0.185
		YSize=0.055
		ButtonColor=(R=0,G=120,B=36,A=235)
		HoverColor=(R=0,G=158,B=52,A=245)
		PressedColor=(R=0,G=84,B=28,A=245)
		AccentColor=(R=80,G=255,B=128,A=150)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(RestartMapButton)

	Begin Object Class=KFGUI_Button_Tint Name=PauseTraderButton
		ID="PauseTrader"
		XPosition=0.525
		YPosition=0.240
		XSize=0.260
		YSize=0.060
		ButtonColor=(R=25,G=32,B=188,A=235)
		HoverColor=(R=42,G=52,B=230,A=245)
		PressedColor=(R=16,G=22,B=132,A=245)
		AccentColor=(R=102,G=128,B=255,A=150)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(PauseTraderButton)

	Begin Object Class=KFGUI_CheckBox Name=EnableGuardCheckBox
		ID="EnableGuard"
		XPosition=0.615
		YPosition=0.315
		XSize=0.035
		YSize=0.045
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(EnableGuardCheckBox)

	Begin Object Class=KFGUI_CheckBox Name=PublicOpenTraderCheckBox
		ID="PublicOpenTrader"
		XPosition=0.765
		YPosition=0.315
		XSize=0.035
		YSize=0.045
		OnCheckChange=ToggleCheckBox
	End Object
	Components.Add(PublicOpenTraderCheckBox)

	Begin Object Class=KFGUI_TextLable Name=EnableGuardLabel
		ID="TraderGuardLabel"
		XPosition=0.525
		YPosition=0.315
		XSize=0.085
		YSize=0.045
		AlignX=0
		AlignY=1
		FontScale=0
	End Object
	Components.Add(EnableGuardLabel)

	Begin Object Class=KFGUI_TextLable Name=PublicOpenTraderLabelText
		ID="PublicOpenTraderLabel"
		XPosition=0.655
		YPosition=0.315
		XSize=0.105
		YSize=0.045
		AlignX=0
		AlignY=1
		FontScale=0
	End Object
	Components.Add(PublicOpenTraderLabelText)

	Begin Object Class=KFGUI_Button_Warning Name=EndWaveButton
		ID="EndWave"
		XPosition=0.610
		YPosition=0.455
		XSize=0.160
		YSize=0.058
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(EndWaveButton)

	Begin Object Class=KFGUI_Button_Tint Name=ProgressWaveButton
		ID="ProgressWave"
		XPosition=0.610
		YPosition=0.520
		XSize=0.070
		YSize=0.052
		ButtonColor=(R=38,G=52,B=176,A=235)
		HoverColor=(R=54,G=72,B=220,A=245)
		PressedColor=(R=24,G=34,B=130,A=245)
		AccentColor=(R=108,G=130,B=255,A=150)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(ProgressWaveButton)

	Begin Object Class=KFGUI_NumericBox Name=ProgressWaveValueBox
		ID="ProgressWaveValue"
		XPosition=0.685
		YPosition=0.520
		XSize=0.085
		YSize=0.052
		MinValue=1
		MaxValue=99
		MaxTextLength=2
	End Object
	Components.Add(ProgressWaveValueBox)

	Begin Object Class=KFGUI_Button_Tint Name=PauseSpawnsButton
		ID="PauseSpawns"
		XPosition=0.610
		YPosition=0.580
		XSize=0.160
		YSize=0.052
		ButtonColor=(R=82,G=55,B=142,A=235)
		HoverColor=(R=112,G=76,B=184,A=245)
		PressedColor=(R=58,G=38,B=104,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(PauseSpawnsButton)

	Begin Object Class=KFGUI_Button_Tint Name=MaxMonstersUpButton
		ID="MaxMonstersUp"
		XPosition=0.610
		YPosition=0.635
		XSize=0.080
		YSize=0.040
		ButtonColor=(R=52,G=58,B=62,A=235)
		HoverColor=(R=78,G=84,B=90,A=245)
		PressedColor=(R=34,G=38,B=42,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(MaxMonstersUpButton)

	Begin Object Class=KFGUI_Button_Tint Name=MaxMonstersDownButton
		ID="MaxMonstersDown"
		XPosition=0.690
		YPosition=0.635
		XSize=0.080
		YSize=0.040
		ButtonColor=(R=52,G=58,B=62,A=235)
		HoverColor=(R=78,G=84,B=90,A=245)
		PressedColor=(R=34,G=38,B=42,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(MaxMonstersDownButton)

	Begin Object Class=KFGUI_Button_Tint Name=SpawnRateDownButton
		ID="SpawnRateDown"
		XPosition=0.610
		YPosition=0.680
		XSize=0.080
		YSize=0.040
		ButtonColor=(R=52,G=58,B=62,A=235)
		HoverColor=(R=78,G=84,B=90,A=245)
		PressedColor=(R=34,G=38,B=42,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(SpawnRateDownButton)

	Begin Object Class=KFGUI_Button_Tint Name=SpawnRateUpButton
		ID="SpawnRateUp"
		XPosition=0.690
		YPosition=0.680
		XSize=0.080
		YSize=0.040
		ButtonColor=(R=52,G=58,B=62,A=235)
		HoverColor=(R=78,G=84,B=90,A=245)
		PressedColor=(R=34,G=38,B=42,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(SpawnRateUpButton)

	Begin Object Class=KFGUI_Button_Tint Name=ResourceLimitsButton
		ID="ResourceLimits"
		XPosition=0.135
		YPosition=0.195
		XSize=0.135
		YSize=0.052
		ButtonColor=(R=34,G=46,B=176,A=235)
		HoverColor=(R=50,G=64,B=224,A=245)
		PressedColor=(R=24,G=34,B=130,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(ResourceLimitsButton)

	Begin Object Class=KFGUI_Button_Tint Name=RestrictionPlaceholderOne
		ID="RestrictionPlaceholder1"
		XPosition=0.135
		YPosition=0.247
		XSize=0.135
		YSize=0.052
		ButtonColor=(R=86,G=45,B=178,A=235)
		HoverColor=(R=116,G=68,B=220,A=245)
		PressedColor=(R=62,G=32,B=126,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(RestrictionPlaceholderOne)

	Begin Object Class=KFGUI_Button_Tint Name=RestrictionPlaceholderTwo
		ID="RestrictionPlaceholder2"
		XPosition=0.135
		YPosition=0.299
		XSize=0.135
		YSize=0.052
		ButtonColor=(R=40,G=40,B=45,A=235)
		HoverColor=(R=68,G=68,B=76,A=245)
		PressedColor=(R=24,G=24,B=30,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(RestrictionPlaceholderTwo)

	Begin Object Class=KFGUI_Button_Tint Name=AutoMessageButton
		ID="AutoMessage"
		XPosition=0.135
		YPosition=0.455
		XSize=0.170
		YSize=0.055
		ButtonColor=(R=34,G=46,B=176,A=235)
		HoverColor=(R=50,G=64,B=224,A=245)
		PressedColor=(R=24,G=34,B=130,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(AutoMessageButton)

	Begin Object Class=KFGUI_Button_Tint Name=EditMOTDButton
		ID="MOTD"
		XPosition=0.135
		YPosition=0.575
		XSize=0.170
		YSize=0.055
		ButtonColor=(R=40,G=40,B=45,A=235)
		HoverColor=(R=68,G=68,B=76,A=245)
		PressedColor=(R=24,G=24,B=30,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(EditMOTDButton)

	Begin Object Class=KFGUI_Button_Tint Name=SaveStatsButton
		ID="SaveStats"
		XPosition=0.135
		YPosition=0.515
		XSize=0.170
		YSize=0.055
		ButtonColor=(R=86,G=45,B=178,A=235)
		HoverColor=(R=116,G=68,B=220,A=245)
		PressedColor=(R=62,G=32,B=126,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(SaveStatsButton)

	Begin Object Class=KFGUI_Button_Tint Name=BroadcastMOTDButton
		ID="BroadcastMOTD"
		XPosition=0.135
		YPosition=0.635
		XSize=0.170
		YSize=0.055
		ButtonColor=(R=40,G=40,B=45,A=235)
		HoverColor=(R=68,G=68,B=76,A=245)
		PressedColor=(R=24,G=24,B=30,A=245)
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(BroadcastMOTDButton)

}
