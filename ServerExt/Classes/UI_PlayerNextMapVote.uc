Class UI_PlayerNextMapVote extends KFGUI_Page;

var KFGUI_TextLable InfoLabel;
var KFGUI_Button KeepButton;
var KFGUI_Button NextButton;

function InitMenu()
{
	Super.InitMenu();

	InfoLabel = KFGUI_TextLable(FindComponentID('Info'));
	KeepButton = KFGUI_Button(FindComponentID('Keep'));
	NextButton = KFGUI_Button(FindComponentID('Next'));

	KeepButton.ButtonText = "KEEP PLAYING";
	NextButton.ButtonText = "NEXT MAP";
}

function InitVote(int WaveNum, int Seconds)
{
	if (InfoLabel!=None)
		InfoLabel.SetText("Wave "$WaveNum$" reached.||Keep playing or open the map vote?||"$Seconds$" seconds remaining.");
}

function ButtonClicked(KFGUI_Button Sender)
{
	switch (Sender.ID)
	{
	case 'Keep':
		ExtPlayerController(GetPlayer()).PlayerNextMapVoteAnswer(false);
		DoClose();
		break;
	case 'Next':
		ExtPlayerController(GetPlayer()).PlayerNextMapVoteAnswer(true);
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
	YSize=0.26

	Begin Object Class=KFGUI_TextLable Name=InfoLabel
		ID="Info"
		XPosition=0.08
		YPosition=0.1
		XSize=0.84
		YSize=0.44
		AlignX=1
		AlignY=1
	End Object
	Begin Object Class=KFGUI_Button Name=KeepButton
		XPosition=0.1
		YPosition=0.61
		XSize=0.38
		YSize=0.24
		ID="Keep"
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
	End Object
	Begin Object Class=KFGUI_Button Name=NextButton
		XPosition=0.52
		YPosition=0.61
		XSize=0.38
		YSize=0.24
		ID="Next"
		OnClickLeft=ButtonClicked
		OnClickRight=ButtonClicked
		TextColor=(R=128,G=255,B=128,A=255)
	End Object

	Components.Add(InfoLabel)
	Components.Add(KeepButton)
	Components.Add(NextButton)
}
