// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class KFGUI_AdminGridOverlay extends KFGUI_Base;

var() bool bVisible;
var() int GridX, GridY;
var() color LineColor, MajorLineColor, TextColor, DotColor;
var() byte LabelFontScale;

function bool CaptureMouse()
{
	return false;
}

function DrawMenu()
{
	local int X, Y;
	local float PX, PY, TS, XL, YL;
	local string S;

	if (!bVisible)
		return;

	GridX = Max(GridX, 4);
	GridY = Max(GridY, 4);

	for (X=0; X<=GridX; ++X)
	{
		Canvas.DrawColor = ((X % 4)==0) ? MajorLineColor : LineColor;
		PX = CompPos[2] * float(X) / float(GridX);
		Canvas.SetPos(PX, 0.f);
		Owner.CurrentStyle.DrawWhiteBox(((X % 4)==0) ? 2.f : 1.f, CompPos[3]);

		if ((X % 4)==0)
		{
			S = string(X);
			Canvas.Font = Owner.CurrentStyle.PickFont(LabelFontScale, TS);
			Canvas.TextSize(S, XL, YL, TS, TS);
			Canvas.DrawColor = TextColor;
			Canvas.SetPos(FClamp(PX-(XL*0.5), 1.f, CompPos[2]-XL-1.f), 2.f);
			Canvas.DrawText(S,,TS,TS);
			Canvas.SetPos(FClamp(PX-(XL*0.5), 1.f, CompPos[2]-XL-1.f), CompPos[3]-YL-2.f);
			Canvas.DrawText(S,,TS,TS);
		}
	}

	for (Y=0; Y<=GridY; ++Y)
	{
		Canvas.DrawColor = ((Y % 4)==0) ? MajorLineColor : LineColor;
		PY = CompPos[3] * float(Y) / float(GridY);
		Canvas.SetPos(0.f, PY);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2], ((Y % 4)==0) ? 2.f : 1.f);

		if ((Y % 4)==0)
		{
			S = string(Y);
			Canvas.Font = Owner.CurrentStyle.PickFont(LabelFontScale, TS);
			Canvas.TextSize(S, XL, YL, TS, TS);
			Canvas.DrawColor = TextColor;
			Canvas.SetPos(2.f, FClamp(PY-(YL*0.5), 1.f, CompPos[3]-YL-1.f));
			Canvas.DrawText(S,,TS,TS);
			Canvas.SetPos(CompPos[2]-XL-2.f, FClamp(PY-(YL*0.5), 1.f, CompPos[3]-YL-1.f));
			Canvas.DrawText(S,,TS,TS);
		}
	}

	for (X=0; X<=GridX; X+=4)
	{
		for (Y=0; Y<=GridY; Y+=4)
		{
			Canvas.DrawColor = DotColor;
			Canvas.SetPos((CompPos[2] * float(X) / float(GridX))-2.f, (CompPos[3] * float(Y) / float(GridY))-2.f);
			Owner.CurrentStyle.DrawWhiteBox(4.f, 4.f);
		}
	}
}

defaultproperties
{
	bVisible=false
	GridX=32
	GridY=17
	LineColor=(R=75,G=230,B=255,A=45)
	MajorLineColor=(R=145,G=255,B=255,A=95)
	TextColor=(R=210,G=255,B=255,A=210)
	DotColor=(R=255,G=255,B=255,A=170)
	LabelFontScale=0
	bClickable=false
	bCanFocus=false
}
