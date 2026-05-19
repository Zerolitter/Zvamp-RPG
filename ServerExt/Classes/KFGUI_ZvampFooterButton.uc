// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class KFGUI_ZvampFooterButton extends KFGUI_Button;

function DrawMenu()
{
	local float XL,YL,TS;
	local byte i;

	if (bDisabled)
		Canvas.SetDrawColor(10,8,18,245);
	else if (bPressedDown)
		Canvas.SetDrawColor(78,40,132,255);
	else if (bFocused)
		Canvas.SetDrawColor(92,58,164,255);
	else Canvas.SetDrawColor(70,45,145,255);

	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);

	if (!bDisabled)
	{
		Canvas.SetDrawColor(118,78,194,220);
		Canvas.SetPos(0.f,0.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],2.f);
		Canvas.SetDrawColor(38,24,82,210);
		Canvas.SetPos(CompPos[2]-4.f,0.f);
		Owner.CurrentStyle.DrawWhiteBox(4.f,CompPos[3]);
	}
	else
	{
		Canvas.SetDrawColor(46,32,78,140);
		Canvas.SetPos(CompPos[2]-4.f,0.f);
		Owner.CurrentStyle.DrawWhiteBox(4.f,CompPos[3]);
	}

	if (bFocused && !bDisabled)
	{
		Canvas.SetDrawColor(155,112,220,220);
		Canvas.SetPos(0.f,CompPos[3]-2.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],2.f);
	}

	if (ButtonText!="")
	{
		i = Min(FontScale+Owner.CurrentStyle.DefaultFontSize,Owner.CurrentStyle.MaxFontScale);
		while (true)
		{
			Canvas.Font = Owner.CurrentStyle.PickFont(i,TS);
			Canvas.TextSize(ButtonText,XL,YL,TS,TS);
			if (i==0 || (XL<(CompPos[2]*0.93) && YL<(CompPos[3]*0.90)))
				break;
			--i;
		}
		Canvas.SetPos((CompPos[2]-XL)*0.5,(CompPos[3]-YL)*0.5);
		if (bDisabled)
			Canvas.SetDrawColor(128,118,150,210);
		else Canvas.DrawColor = TextColor;
		Canvas.DrawText(ButtonText,,TS,TS,TextFontInfo);
	}
}

defaultproperties
{
	TextColor=(R=230,G=220,B=248,A=255)
	FontScale=1
}
