Class UI_PlayerProgressWaveVote extends KFGUI_Page;

var KFGUI_TextLable InfoLabel;
var KFGUI_Button YesButton;
var KFGUI_Button NoButton;

function InitMenu()
{
	Super.InitMenu();

	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	YesButton = KFGUI_Button(FindComponentID('Yes'));
	NoButton = KFGUI_Button(FindComponentID('No'));

	YesButton.ButtonText = "ACCEPT";
	NoButton.ButtonText = "DECLINE";
}

function InitVote(string CallerName, int WaveCount, int Seconds)
{
	if (InfoLabel!=None)
		InfoLabel.SetText(CallerName$" called a vote to progress "$WaveCount$" wave(s).||"$Seconds$" seconds remaining.");
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Yes':
		ExtPlayerController(GetPlayer()).PlayerProgressWaveVoteAnswer(true);
		DoClose();
		break;
	case 'No':
		ExtPlayerController(GetPlayer()).PlayerProgressWaveVoteAnswer(false);
		DoClose();
		break;
	}
}

defaultproperties
{
	bPersistant=false
	bAlwaysTop=true
	bOnlyThisFocus=false
	XPosition=0.35
	YPosition=0.36
	XSize=0.3
	YSize=0.24

	Begin Object Class=KFGUI_TextLable Name=InfoLabel
		ID="Info"
		XPosition=0.08
		YPosition=0.12
		XSize=0.84
		YSize=0.42
		AlignX=1
		AlignY=1
	End Object
	Begin Object Class=KFGUI_Button Name=YesButton
		XPosition=0.18
		YPosition=0.6
		XSize=0.28
		YSize=0.24
		ID="Yes"
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		TextColor=(R=128,G=255,B=128,A=255)
	End Object
	Begin Object Class=KFGUI_Button Name=NoButton
		XPosition=0.54
		YPosition=0.6
		XSize=0.28
		YSize=0.24
		ID="No"
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		TextColor=(R=255,G=128,B=128,A=255)
	End Object

	Components.Add(InfoLabel)
	Components.Add(YesButton)
	Components.Add(NoButton)
}
