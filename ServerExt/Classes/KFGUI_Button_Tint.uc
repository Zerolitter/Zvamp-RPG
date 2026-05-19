// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class KFGUI_Button_Tint extends KFGUI_Button;

var() color ButtonColor, HoverColor, PressedColor, DisabledColor, AccentColor;

function DrawMenu()
{
	local float XL,YL,TS;
	local byte i;

	if (bDisabled)
		Canvas.DrawColor = DisabledColor;
	else if (bPressedDown)
		Canvas.DrawColor = PressedColor;
	else if (bFocused || bIsHighlighted)
		Canvas.DrawColor = HoverColor;
	else Canvas.DrawColor = ButtonColor;

	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);
	if (!bDisabled)
	{
		Canvas.DrawColor = AccentColor;
		Canvas.SetPos(0.f,0.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],2.f);
		Canvas.DrawColor.A = 70;
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
	ButtonColor=(R=70,G=48,B=150,A=235)
	HoverColor=(R=92,G=66,B=190,A=245)
	PressedColor=(R=48,G=32,B=112,A=245)
	DisabledColor=(R=28,G=27,B=34,A=190)
	AccentColor=(R=155,G=124,B=255,A=150)
	TextColor=(R=245,G=238,B=255,A=255)
}
