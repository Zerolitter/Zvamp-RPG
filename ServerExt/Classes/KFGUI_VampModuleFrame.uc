// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.

Class KFGUI_VampModuleFrame extends KFGUI_Base;

var() byte BorderAlpha, FillAlpha;
var byte TopBorderAlpha, BottomBorderAlpha, LeftBorderAlpha, RightBorderAlpha;

function bool CaptureMouse()
{
	return false;
}

function DrawMenu()
{
	local float Edge;

	Edge = 5.f;

	Canvas.SetDrawColor(34,34,38,FillAlpha);
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);

	Canvas.SetDrawColor(100,62,210,(TopBorderAlpha==255 ? BorderAlpha : TopBorderAlpha));
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],Edge);
	Canvas.SetPos(0.f,CompPos[3]-Edge);
	Canvas.SetDrawColor(100,62,210,(BottomBorderAlpha==255 ? BorderAlpha : BottomBorderAlpha));
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],Edge);
	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(100,62,210,(LeftBorderAlpha==255 ? BorderAlpha : LeftBorderAlpha));
	Owner.CurrentStyle.DrawWhiteBox(Edge,CompPos[3]);
	Canvas.SetPos(CompPos[2]-Edge,0.f);
	Canvas.SetDrawColor(100,62,210,(RightBorderAlpha==255 ? BorderAlpha : RightBorderAlpha));
	Owner.CurrentStyle.DrawWhiteBox(Edge,CompPos[3]);
}

defaultproperties
{
	BorderAlpha=255
	FillAlpha=64
	TopBorderAlpha=255
	BottomBorderAlpha=255
	LeftBorderAlpha=255
	RightBorderAlpha=255
	bClickable=false
	bCanFocus=false
}
