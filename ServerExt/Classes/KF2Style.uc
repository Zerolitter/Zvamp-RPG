// This file is part of Server Extension.
// Server Extension - a mutator for Killing Floor 2.
//
// Copyright (C) 2016-2024 The Server Extension authors and contributors
//
// Server Extension is free software: you can redistribute it
// and/or modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// Server Extension is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with Server Extension. If not, see <https://www.gnu.org/licenses/>.

Class KF2Style extends GUIStyleBase;

var Texture2D LoadedTex[2];
var Font DrawFonts[3];

const TOOLTIP_BORDER=4;

function InitStyle()
{
	local byte i;

	Super.InitStyle();

	LoadedTex[0] = Texture2D(DynamicLoadObject("EditorMaterials.CASC_ModuleEnable",class'Texture2D'));
	LoadedTex[1] = Texture2D(DynamicLoadObject("EditorMaterials.Tick",class'Texture2D'));
	for (i=0; i<ArrayCount(LoadedTex); ++i)
		if (LoadedTex[i]==None)
			LoadedTex[i] = Texture2D'EngineMaterials.DefaultWhiteGrid';
	// TODO: SmallFont/TinyFont not support unicode
	DrawFonts[0] = Font(DynamicLoadObject("UI_Canvas_Fonts.Font_Main",class'Font'));
	DrawFonts[1] = Font(DynamicLoadObject("EngineFonts.SmallFont",class'Font'));
	DrawFonts[2] = Font(DynamicLoadObject("EngineFonts.TinyFont",class'Font'));
	for (i=0; i<ArrayCount(DrawFonts); ++i)
	{
		if (DrawFonts[i]==None)
			DrawFonts[i] = class'Engine'.Static.GetMediumFont();
	}
}

function RenderFramedWindow(KFGUI_FloatingWindow P)
{
	local int XS,YS,TitleHeight;

	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;
	TitleHeight = DefaultHeight;

	// Frame header.
	if (P.bWindowFocused)
		Canvas.SetDrawColor(54,36,112,255);
	else Canvas.SetDrawColor(26,16,62,P.FrameOpacity);
	Canvas.SetPos(0,0);
	DrawWhiteBox(XS,TitleHeight);

	// Frame itself.
	if (P.bWindowFocused)
		Canvas.SetDrawColor(8,5,18,255);
	else Canvas.SetDrawColor(5,3,12,P.FrameOpacity);
	Canvas.SetPos(0,TitleHeight);
	DrawWhiteBox(XS,YS-TitleHeight);

	// Title.
	if (P.WindowTitle!="")
	{
		Canvas.SetDrawColor(250,250,250,P.FrameOpacity);
		Canvas.SetPos(6,0);
		DrawText(DefaultFontSize,P.WindowTitle);
	}
}

function RenderWindow(KFGUI_Page P)
{
	local int XS,YS;

	XS = Canvas.ClipX-Canvas.OrgX;
	YS = Canvas.ClipY-Canvas.OrgY;

	if (P.bWindowFocused)
		Canvas.SetDrawColor(10,6,24,255);
	else Canvas.SetDrawColor(6,4,14,P.FrameOpacity);
	Canvas.SetPos(0,0);
	DrawWhiteBox(XS,YS);
}

function RenderToolTip(KFGUI_Tooltip TT)
{
	local int i;
	local float X,Y,XS,YS,TX,TY,TS;

	Canvas.Font = PickFont(DefaultFontSize,TS);

	// First compute textbox size.
	TY = DefaultHeight*TT.Lines.Length;
	for (i=0; i<TT.Lines.Length; ++i)
	{
		if (TT.Lines[i]!="")
			Canvas.TextSize(TT.Lines[i],XS,YS);
		TX = FMax(XS,TX);
	}
	TX*=TS;

	// Give some borders.
	TX += TOOLTIP_BORDER*2;
	TY += TOOLTIP_BORDER*2;

	X = TT.CompPos[0];
	Y = TT.CompPos[1]+24.f;

	// Then check if too close to window edge, then move it to another pivot.
	if ((X+TX)>TT.Owner.ScreenSize.X)
		X = TT.Owner.ScreenSize.X-TX;
	if ((Y+TY)>TT.Owner.ScreenSize.Y)
		Y = TT.CompPos[1]-TY;

	if (TT.CurrentAlpha<255)
		TT.CurrentAlpha = Min(TT.CurrentAlpha+25,255);

	// Reset clipping.
	Canvas.SetOrigin(0,0);
	Canvas.SetClip(TT.Owner.ScreenSize.X,TT.Owner.ScreenSize.Y);

	// Draw frame.
	Canvas.SetDrawColor(76,50,150,TT.CurrentAlpha);
	Canvas.SetPos(X-2,Y-2);
	DrawWhiteBox(TX+4,TY+4);
	Canvas.SetDrawColor(8,5,18,TT.CurrentAlpha);
	Canvas.SetPos(X,Y);
	DrawWhiteBox(TX,TY);

	// Draw text.
	Canvas.SetDrawColor(255,255,255,TT.CurrentAlpha);
	X+=TOOLTIP_BORDER;
	Y+=TOOLTIP_BORDER;
	for (i=0; i<TT.Lines.Length; ++i)
	{
		Canvas.SetPos(X,Y);
		Canvas.DrawText(TT.Lines[i],,TS,TS,TT.TextFontInfo);
		Y+=DefaultHeight;
	}
}

function RenderButton(KFGUI_Button B)
{
	local float XL,YL,TS;
	local byte i;

	if (B.bDisabled)
		Canvas.SetDrawColor(10,8,18,255);
	else if (B.bPressedDown)
		Canvas.SetDrawColor(76,50,150,255);
	else if (B.bFocused)
		Canvas.SetDrawColor(64,44,132,255);
	else Canvas.SetDrawColor(48,32,108,255);

	if (B.bIsHighlighted)
	{
		Canvas.DrawColor.R = Min(Canvas.DrawColor.R+12,76);
		Canvas.DrawColor.G = Min(Canvas.DrawColor.G+12,50);
		Canvas.DrawColor.B = Min(Canvas.DrawColor.B+18,150);
	}

	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(B.CompPos[2],B.CompPos[3]);
	if (B.bIsHighlighted)
	{
		Canvas.SetDrawColor(122,82,196,255);
		Canvas.SetPos(0.f,0.f);
		DrawWhiteBox(B.CompPos[2],3.f);
		Canvas.SetPos(0.f,B.CompPos[3]-3.f);
		DrawWhiteBox(B.CompPos[2],3.f);
	}
	else if (!B.bDisabled && B.bFocused)
	{
		Canvas.SetDrawColor(96,68,164,220);
		Canvas.SetPos(0.f,B.CompPos[3]-2.f);
		DrawWhiteBox(B.CompPos[2],2.f);
	}
	if (!B.bDisabled)
	{
		Canvas.SetDrawColor(76,50,150,155);
		Canvas.SetPos(0.f,0.f);
		DrawWhiteBox(B.CompPos[2],2.f);
	}

	if (B.OverlayTexture.Texture!=None)
	{
		Canvas.SetPos(0.f,0.f);
		Canvas.DrawTile(B.OverlayTexture.Texture,B.CompPos[2],B.CompPos[3],B.OverlayTexture.U,B.OverlayTexture.V,B.OverlayTexture.UL,B.OverlayTexture.VL);
	}
	if (B.ButtonText!="")
	{
		// Chose the best font to fit this button.
		i = Min(B.FontScale+DefaultFontSize,MaxFontScale);
		while (true)
		{
			Canvas.Font = PickFont(i,TS);
			Canvas.TextSize(B.ButtonText,XL,YL,TS,TS);
			if (i==0 || (XL<(B.CompPos[2]*0.95) && YL<(B.CompPos[3]*0.95)))
				break;
			--i;
		}
		Canvas.SetPos((B.CompPos[2]-XL)*0.5,(B.CompPos[3]-YL)*0.5);
		if (B.bDisabled)
			Canvas.DrawColor = B.TextColor*0.5f;
		else Canvas.DrawColor = B.TextColor;
		Canvas.DrawText(B.ButtonText,,TS,TS,B.TextFontInfo);
	}
}

function RenderEditBox(KFGUI_EditBox E)
{
	local color C;

	if (E.bDisabled)
	{
		Canvas.SetDrawColor(8,6,18,255);
		C = MakeColor(12,9,24,255);
	}
	else if (E.bPressedDown)
	{
		Canvas.SetDrawColor(76,50,150,255);
		C = MakeColor(14,9,32,255);
	}
	else if (E.bFocused || E.bIsTyping)
	{
		Canvas.SetDrawColor(64,44,132,255);
		C = MakeColor(12,8,28,255);
	}
	else
	{
		Canvas.SetDrawColor(34,22,78,255);
		C = MakeColor(8,5,18,255);
	}

	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(E.CompPos[2],E.CompPos[3]);

	Canvas.SetPos(3.f,3.f);
	Canvas.DrawColor = C;
	DrawWhiteBox(E.CompPos[2]-6,E.CompPos[3]-6);
}

function RenderScrollBar(KFGUI_ScrollBarBase S)
{
	local float A;
	local byte i;

	Canvas.SetDrawColor(10,8,18,255);

	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(S.CompPos[2],S.CompPos[3]);

	if (S.bDisabled)
		return;

	if (S.bVertical)
		i = 3;
	else i = 2;

	S.SliderScale = FMax(S.PageStep * (S.CompPos[i] - 32.f) / (S.MaxRange + S.PageStep),S.CalcButtonScale);

	if (S.bGrabbedScroller)
	{
		// Track mouse.
		if (S.bVertical)
			A = S.Owner.MousePosition.Y - S.CompPos[1] - S.GrabbedOffset;
		else A = S.Owner.MousePosition.X - S.CompPos[0] - S.GrabbedOffset;

		A /= ((S.CompPos[i]-S.SliderScale) / float(S.MaxRange));
		S.SetValue(A);
	}

	A = float(S.CurrentScroll) / float(S.MaxRange);
	S.ButtonOffset = A*(S.CompPos[i]-S.SliderScale);

	if (S.bGrabbedScroller)
		Canvas.SetDrawColor(122,82,196,255);
	else if (S.bFocused)
		Canvas.SetDrawColor(96,68,164,255);
	else Canvas.SetDrawColor(76,50,150,255);

	if (S.bVertical)
	{
		Canvas.SetPos(0.f,S.ButtonOffset);
		DrawWhiteBox(S.CompPos[2],S.SliderScale);
	}
	else
	{
		Canvas.SetPos(S.ButtonOffset,0.f);
		DrawWhiteBox(S.SliderScale,S.CompPos[3]);
	}
}

function RenderColumnHeader(KFGUI_ColumnTop C, float XPos, float Width, int Index, bool bFocus, bool bSort)
{
	local int XS;

	if (bSort)
	{
		if (bFocus)
			Canvas.SetDrawColor(76,50,150,255);
		else Canvas.SetDrawColor(54,36,112,255);
	}
	else if (bFocus)
		Canvas.SetDrawColor(76,50,150,255);
	else Canvas.SetDrawColor(44,30,102,255);

	XS = DefaultHeight*0.125;
	Canvas.SetPos(XPos,0.f);
	DrawWhiteBox(Width,C.CompPos[3]);

	Canvas.SetDrawColor(250,250,250,255);
	Canvas.SetPos(XPos+XS,(C.CompPos[3]-C.ListOwner.TextHeight)*0.5f);
	C.ListOwner.DrawStrClipped(C.ListOwner.Columns[Index].Text);
}

function RenderCheckbox(KFGUI_CheckBox C)
{
	local float Edge;

	Edge = FMax(2.f,C.CompPos[2]*0.08f);

	if (C.bDisabled)
		Canvas.SetDrawColor(30,26,42,255);
	else if (C.bPressedDown)
		Canvas.SetDrawColor(116,88,194,255);
	else if (C.bFocused)
		Canvas.SetDrawColor(98,72,176,255);
	else Canvas.SetDrawColor(48,34,104,255);

	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);

	if (C.bChecked)
	{
		if (C.bDisabled)
			Canvas.SetDrawColor(72,72,86,255);
		else Canvas.SetDrawColor(18,198,158,255);
		Canvas.SetPos(Edge,Edge);
		DrawWhiteBox(C.CompPos[2]-(Edge*2.f),C.CompPos[3]-(Edge*2.f));

		if (!C.bDisabled)
		{
			Canvas.SetDrawColor(110,245,196,130);
			Canvas.SetPos(Edge,Edge);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),Edge);
		}
	}
	else
	{
		if (C.bDisabled)
			Canvas.SetDrawColor(16,14,24,255);
		else Canvas.SetDrawColor(10,7,22,255);
		Canvas.SetPos(Edge,Edge);
		DrawWhiteBox(C.CompPos[2]-(Edge*2.f),C.CompPos[3]-(Edge*2.f));
	}
}

function RenderComboBox(KFGUI_ComboBox C)
{
	if (C.bDisabled)
		Canvas.SetDrawColor(10,8,18,255);
	else if (C.bPressedDown)
		Canvas.SetDrawColor(76,50,150,255);
	else if (C.bFocused)
		Canvas.SetDrawColor(64,44,132,255);
	else Canvas.SetDrawColor(48,32,108,255);

	Canvas.SetPos(0.f,0.f);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);

	if (C.SelectedIndex<C.Values.Length && C.Values[C.SelectedIndex]!="")
	{
		Canvas.SetPos(C.BorderSize,(C.CompPos[3]-C.TextHeight)*0.5);
		if (C.bDisabled)
			Canvas.DrawColor = C.TextColor*0.5f;
		else Canvas.DrawColor = C.TextColor;
		Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX-C.BorderSize,Canvas.ClipY);
		Canvas.DrawText(C.Values[C.SelectedIndex],,C.TextScale,C.TextScale,C.TextFontInfo);
		Canvas.PopMaskRegion();
	}
}

function RenderComboList(KFGUI_ComboSelector C)
{
	local float X,Y,YL,YP,Edge;
	local int i;
	local bool bCheckMouse;

	// Draw background.
	Edge = C.Combo.BorderSize;
	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(50,32,112,255);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);
	Canvas.SetPos(Edge,Edge);
	Canvas.SetDrawColor(8,5,18,255);
	DrawWhiteBox(C.CompPos[2]-(Edge*2.f),C.CompPos[3]-(Edge*2.f));

	// While rendering, figure out mouse focus row.
	X = C.Owner.MousePosition.X - Canvas.OrgX;
	Y = C.Owner.MousePosition.Y - Canvas.OrgY;

	bCheckMouse = (X>0.f && X<C.CompPos[2] && Y>0.f && Y<C.CompPos[3]);

	Canvas.Font = C.Combo.TextFont;
	YL = C.Combo.TextHeight;

	YP = Edge;
	C.CurrentRow = -1;

	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for (i=0; i<C.Combo.Values.Length; ++i)
	{
		if (bCheckMouse && Y>=YP && Y<=(YP+YL))
		{
			bCheckMouse = false;
			C.CurrentRow = i;
			Canvas.SetPos(4.f,YP);
			Canvas.SetDrawColor(58,38,118,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),YL);
		}
		Canvas.SetPos(Edge,YP);

		if (i==C.Combo.SelectedIndex)
			Canvas.DrawColor = C.Combo.SelectedTextColor;
		else Canvas.DrawColor = C.Combo.TextColor;

		Canvas.DrawText(C.Combo.Values[i],,C.Combo.TextScale,C.Combo.TextScale,C.Combo.TextFontInfo);

		YP+=YL;
	}
	Canvas.PopMaskRegion();
	if (C.OldRow!=C.CurrentRow)
	{
		C.OldRow = C.CurrentRow;
		C.PlayMenuSound(MN_DropdownChange);
	}
}

function RenderRightClickMenu(KFGUI_RightClickMenu C)
{
	local float X,Y,YP,Edge,TextScale;
	local int i;
	local bool bCheckMouse;

	// Draw background.
	Edge = C.EdgeSize;
	Canvas.SetPos(0.f,0.f);
	Canvas.SetDrawColor(50,32,112,255);
	DrawWhiteBox(C.CompPos[2],C.CompPos[3]);
	Canvas.SetPos(Edge,Edge);
	Canvas.SetDrawColor(8,5,18,255);
	DrawWhiteBox(C.CompPos[2]-(Edge*2.f),C.CompPos[3]-(Edge*2.f));

	// While rendering, figure out mouse focus row.
	X = C.Owner.MousePosition.X - Canvas.OrgX;
	Y = C.Owner.MousePosition.Y - Canvas.OrgY;

	bCheckMouse = (X>0.f && X<C.CompPos[2] && Y>0.f && Y<C.CompPos[3]);

	Canvas.Font = PickFont(DefaultFontSize,TextScale);

	YP = Edge;
	C.CurrentRow = -1;

	Canvas.PushMaskRegion(Canvas.OrgX,Canvas.OrgY,Canvas.ClipX,Canvas.ClipY);
	for (i=0; i<C.ItemRows.Length; ++i)
	{
		if (bCheckMouse && Y>=YP && Y<=(YP+DefaultHeight))
		{
			bCheckMouse = false;
			C.CurrentRow = i;
			Canvas.SetPos(4.f,YP);
			Canvas.SetDrawColor(58,38,118,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f),DefaultHeight);
		}

		Canvas.SetPos(Edge,YP);
		if (C.ItemRows[i].bSplitter)
		{
			Canvas.SetPos(Edge+6.f,YP+(DefaultHeight*0.5f));
			Canvas.SetDrawColor(76,50,150,255);
			DrawWhiteBox(C.CompPos[2]-(Edge*2.f)-12.f,1.f);
		}
		else
		{
			if (C.ItemRows[i].bDisabled)
				Canvas.SetDrawColor(148,148,148,255);
			else Canvas.SetDrawColor(248,248,248,255);
			Canvas.DrawText(C.ItemRows[i].Text,,TextScale,TextScale);
		}

		YP+=DefaultHeight;
	}
	Canvas.PopMaskRegion();
	if (C.OldRow!=C.CurrentRow)
	{
		C.OldRow = C.CurrentRow;
		C.PlayMenuSound(MN_DropdownChange);
	}
}

function Font PickFont(byte i, out float Scaler)
{
	switch (i)
	{
	case 0:
		Scaler = 0.55;
		return DrawFonts[0];
	case 1:
		Scaler = 0.65;
		return DrawFonts[0];
	case 2:
		Scaler = 0.70;
		return DrawFonts[0];
	case 3:
		Scaler = 0.75;
		return DrawFonts[0];
	case 4:
		Scaler = 0.85;
		return DrawFonts[0];
	case 5:
		Scaler = 0.90;
		return DrawFonts[0];
	default:
		Scaler = 1.0;
		return DrawFonts[0];
	}
}

defaultproperties
{
	MaxFontScale=6
}
