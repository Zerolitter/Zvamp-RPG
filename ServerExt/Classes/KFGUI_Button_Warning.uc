// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class KFGUI_Button_Warning extends KFGUI_Button;

function DrawMenu()
{
	local float XL,YL,TS;
	local byte i;

	if (bDisabled)
		Canvas.SetDrawColor(12,8,18,255);
	else if (bPressedDown)
		Canvas.SetDrawColor(128,34,118,255);
	else if (bFocused)
		Canvas.SetDrawColor(104,28,108,255);
	else Canvas.SetDrawColor(72,18,78,255);

	if (bIsHighlighted)
	{
		Canvas.DrawColor.R = Min(Canvas.DrawColor.R+18,128);
		Canvas.DrawColor.G = Min(Canvas.DrawColor.G+10,34);
		Canvas.DrawColor.B = Min(Canvas.DrawColor.B+22,118);
	}

	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	if (!bDisabled)
	{
		Canvas.SetDrawColor(188,58,156,170);
		Canvas.SetPos(0.f,0.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],2.f);
		Canvas.SetDrawColor(188,58,156,70);
		Canvas.SetPos(0.f,CompPos[3]-2.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],2.f);
	}

	if (OverlayTexture.Texture!=None)
	{
		Canvas.SetPos(0.f,0.f);
		Canvas.DrawTile(OverlayTexture.Texture,CompPos[2],CompPos[3],OverlayTexture.U,OverlayTexture.V,OverlayTexture.UL,OverlayTexture.VL);
	}
	if (ButtonText!="")
	{
		i = Min(FontScale+Owner.CurrentStyle.DefaultFontSize,Owner.CurrentStyle.MaxFontScale);
		while (true)
		{
			Canvas.Font = Owner.CurrentStyle.PickFont(i,TS);
			Canvas.TextSize(ButtonText,XL,YL,TS,TS);
			if (i==0 || (XL<(CompPos[2]*0.95) && YL<(CompPos[3]*0.95)))
				break;
			--i;
		}
		Canvas.SetPos((CompPos[2]-XL)*0.5,(CompPos[3]-YL)*0.5);
		if (bDisabled)
			Canvas.DrawColor = TextColor*0.5f;
		else Canvas.DrawColor = TextColor;
		Canvas.DrawText(ButtonText,,TS,TS,TextFontInfo);
	}
}

defaultproperties
{
	TextColor=(R=255,G=224,B=246,A=255)
}
