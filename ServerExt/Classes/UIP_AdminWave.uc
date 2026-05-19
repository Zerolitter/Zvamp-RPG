// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class UIP_AdminWave extends KFGUI_MultiComponent;

var KFGUI_TextLable InfoLabel, WaveCardLabel, ProgressCardLabel, SpawnCardLabel;
var KFGUI_Button EndWaveButton, ProgressWaveButton, PauseSpawnsButton, MaxMonstersUpButton, MaxMonstersDownButton, SpawnRateUpButton, SpawnRateDownButton;
var KFGUI_NumericBox ProgressWaveBox;

function InitMenu()
{
	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	WaveCardLabel = KFGUI_TextLable(FindComponentID('WaveCard'));
	ProgressCardLabel = KFGUI_TextLable(FindComponentID('ProgressCard'));
	SpawnCardLabel = KFGUI_TextLable(FindComponentID('SpawnCard'));
	EndWaveButton = KFGUI_Button(FindComponentID('EndWave'));
	ProgressWaveButton = KFGUI_Button(FindComponentID('ProgressWave'));
	ProgressWaveBox = KFGUI_NumericBox(FindComponentID('ProgressWaveValue'));
	PauseSpawnsButton = KFGUI_Button(FindComponentID('PauseSpawns'));
	MaxMonstersUpButton = KFGUI_Button(FindComponentID('MaxMonstersUp'));
	MaxMonstersDownButton = KFGUI_Button(FindComponentID('MaxMonstersDown'));
	SpawnRateUpButton = KFGUI_Button(FindComponentID('SpawnRateUp'));
	SpawnRateDownButton = KFGUI_Button(FindComponentID('SpawnRateDown'));

	InfoLabel.SetText("Live Endless wave controls for testing and server management.");
	WaveCardLabel.SetText("Wave Control");
	ProgressCardLabel.SetText("Progress Wave");
	SpawnCardLabel.SetText("Spawn Control");

	EndWaveButton.ButtonText = "End Wave";
	EndWaveButton.Tooltip = "Warning: clears active zeds and queued spawns to force the wave forward";
	ProgressWaveButton.ButtonText = "Jump";
	ProgressWaveButton.Tooltip = "Jump forward by the selected wave count and enter trader time";
	ProgressWaveBox.ChangeValue("1");
	PauseSpawnsButton.ButtonText = "Pause Spawns";
	PauseSpawnsButton.Tooltip = "Toggle the server spawn manager off or on";
	MaxMonstersUpButton.ButtonText = "Max +4";
	MaxMonstersUpButton.Tooltip = "Increase active max monsters for the current difficulty";
	MaxMonstersDownButton.ButtonText = "Max -4";
	MaxMonstersDownButton.Tooltip = "Decrease active max monsters for the current difficulty";
	SpawnRateUpButton.ButtonText = "Faster";
	SpawnRateUpButton.Tooltip = "Make new spawn groups arrive faster";
	SpawnRateDownButton.ButtonText = "Slower";
	SpawnRateDownButton.Tooltip = "Make new spawn groups arrive slower";

	Super.InitMenu();
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
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
	}
}

defaultproperties
{
	Begin Object Class=KFGUI_VampModuleFrame Name=WaveControlFrame
		XPosition=0.035
		YPosition=0.18
		XSize=0.76
		YSize=0.24
	End Object
	Components.Add(WaveControlFrame)

	Begin Object Class=KFGUI_VampModuleFrame Name=SpawnControlFrame
		XPosition=0.035
		YPosition=0.44
		XSize=0.76
		YSize=0.34
	End Object
	Components.Add(SpawnControlFrame)

	Begin Object Class=KFGUI_TextLable Name=AdminWaveInfo
		ID="Info"
		XPosition=0.05
		YPosition=0.08
		XSize=0.9
		YSize=0.08
		AlignX=0
		AlignY=0
	End Object
	Components.Add(AdminWaveInfo)

	Begin Object Class=KFGUI_TextLable Name=WaveCard
		ID="WaveCard"
		XPosition=0.055
		YPosition=0.205
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(WaveCard)

	Begin Object Class=KFGUI_Button_Warning Name=EndWaveButton
		ID="EndWave"
		XPosition=0.055
		YPosition=0.30
		XSize=0.14
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(EndWaveButton)

	Begin Object Class=KFGUI_TextLable Name=ProgressCard
		ID="ProgressCard"
		XPosition=0.255
		YPosition=0.205
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(ProgressCard)

	Begin Object Class=KFGUI_Button Name=ProgressWaveButton
		ID="ProgressWave"
		XPosition=0.255
		YPosition=0.30
		XSize=0.10
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(ProgressWaveButton)

	Begin Object Class=KFGUI_NumericBox Name=ProgressWaveValueBox
		ID="ProgressWaveValue"
		XPosition=0.370
		YPosition=0.30
		XSize=0.07
		YSize=0.06
		MinValue=1
		MaxValue=99
		MaxTextLength=2
	End Object
	Components.Add(ProgressWaveValueBox)

	Begin Object Class=KFGUI_Button Name=PauseSpawnsButton
		ID="PauseSpawns"
		XPosition=0.055
		YPosition=0.64
		XSize=0.18
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(PauseSpawnsButton)

	Begin Object Class=KFGUI_TextLable Name=SpawnCard
		ID="SpawnCard"
		XPosition=0.055
		YPosition=0.465
		XSize=0.35
		YSize=0.05
		AlignX=0
		AlignY=1
	End Object
	Components.Add(SpawnCard)

	Begin Object Class=KFGUI_Button Name=MaxMonstersUpButton
		ID="MaxMonstersUp"
		XPosition=0.055
		YPosition=0.56
		XSize=0.14
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(MaxMonstersUpButton)

	Begin Object Class=KFGUI_Button Name=MaxMonstersDownButton
		ID="MaxMonstersDown"
		XPosition=0.215
		YPosition=0.56
		XSize=0.14
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(MaxMonstersDownButton)

	Begin Object Class=KFGUI_Button Name=SpawnRateUpButton
		ID="SpawnRateUp"
		XPosition=0.395
		YPosition=0.56
		XSize=0.14
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(SpawnRateUpButton)

	Begin Object Class=KFGUI_Button Name=SpawnRateDownButton
		ID="SpawnRateDown"
		XPosition=0.555
		YPosition=0.56
		XSize=0.14
		YSize=0.06
		OnClickLeft=ButtonClicked
	End Object
	Components.Add(SpawnRateDownButton)
}
