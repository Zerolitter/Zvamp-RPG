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

// Columned list box (only for text lines).
Class UIR_PerkTraitList extends KFGUI_ColumnList;

var array<string> ToolTip;
var KFGUI_Tooltip ToolTipItem;
var() bool bShowToolTips;
var() bool bCardMode;
var Ext_PerkBase DisplayPerk;
var array<name> DynamicIconNames;
var array<Texture2D> DynamicIcons;

var localized string TraitNameText;
var localized string TraitLevelText;
var localized string TraitCostText;

function InitMenu()
{
	local FColumnItem NameItem;
	local FColumnItem LevelItem;
	local FColumnItem CostItem;

	Super.InitMenu();

	NameItem.Text=TraitNameText;
	NameItem.Width=0.6;
	LevelItem.Text=TraitLevelText;
	LevelItem.Width=0.2;
	CostItem.Text=TraitCostText;
	CostItem.Width=0.2;

	Columns.AddItem(NameItem);
	Columns.AddItem(LevelItem);
	Columns.AddItem(CostItem);
}

function DrawMenu()
{
	local int i,n,j;
	local float Y,TextY,YClip,XOffset;
	local KFGUI_ListItem C;
	local bool bCheckMouse,bHideRow;

	if (bCardMode)
	{
		DrawCardGrid();
		return;
	}

	Canvas.DrawColor = BackgroundColor;
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);

	// Mouse focused item check.
	bCheckMouse = bClickable && bFocused;
	FocusMouseItem = -1;
	if (bCheckMouse)
		MouseYHit = Owner.MousePosition.Y - CompPos[1];

	n = ScrollBar.CurrentScroll;
	i = 0;
	for (C=FirstItem; C!=None; C=C.Next)
		if ((i++)==n)
			break;
	Y = 0.f;
	TextY = (ItemHeight-TextHeight)*0.5f;
	XOffset = TextY*0.75;
	YClip = CompPos[1]+CompPos[3];
	Canvas.SetDrawColor(250,250,250,255);

	for (i=0; (i<ListItemsPerPage && C!=None); ++i)
	{
		// Check for mouse hit.
		if (bCheckMouse && FocusMouseItem==-1)
		{
			if (MouseYHit<ItemHeight)
				FocusMouseItem = n;
			else MouseYHit-=ItemHeight;
		}

		// Draw selection background.
		bHideRow = false;
		if (Left(C.GetDisplayStr(0),2)=="--") // Group name.
		{
			Canvas.SetPos(0,Y);
			Canvas.SetDrawColor(32,128,32);
			bHideRow = true;

			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);

			Canvas.SetClip(CompPos[0]+CompPos[2],YClip);
			Canvas.SetPos(2,TextY);
			DrawStrClipped(Mid(C.GetDisplayStr(0),2));
		}
		else if (SelectedRowIndex==n) // Selected
		{
			Canvas.SetPos(0,Y);
			Canvas.DrawColor = SelectedLineColor;
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
		}
		else if (FocusMouseItem==n) // Focused
		{
			Canvas.SetPos(0,Y);
			Canvas.DrawColor = FocusedLineColor;
			Owner.CurrentStyle.DrawWhiteBox(CompPos[2],ItemHeight);
			Canvas.SetDrawColor(250,250,250,255);
		}

		if (!bHideRow)
		{
			// Draw columns of text
			for (j=0; j<Columns.Length; ++j)
				if (!Columns[j].bHidden)
				{
					Canvas.SetClip(Columns[j].X+Columns[j].XSize,YClip);
					Canvas.SetPos(Columns[j].X+XOffset,TextY);
					DrawStrClipped(C.GetDisplayStr(j));
				}
		}
		Y+=ItemHeight;
		TextY+=ItemHeight;
		++n;
		C = C.Next;
	}
}

function PreDraw()
{
	if (!bCardMode)
	{
		Super.PreDraw();
		return;
	}

	ComputeCoords();

	Canvas.Font = Owner.CurrentStyle.PickFont(Min(FontSize+Owner.CurrentStyle.DefaultFontSize,Owner.CurrentStyle.MaxFontScale),TextScaler);
	Canvas.TextSize("ABC",ScalerSize,TextHeight,TextScaler,TextScaler);

	ScrollBar.InputPos[0] = CompPos[0];
	ScrollBar.InputPos[1] = CompPos[1];
	ScrollBar.InputPos[2] = CompPos[2];
	ScrollBar.InputPos[3] = CompPos[3];
	if (OldXSize!=InputPos[2])
	{
		OldXSize = InputPos[2];
		ScrollBar.XPosition = 1.f - ScrollBar.GetWidth();
	}
	ScrollBar.Canvas = Canvas;
	ScrollBar.PreDraw();

	CompPos[2] -= ScrollBar.CompPos[2];
	Canvas.SetOrigin(CompPos[0],CompPos[1]);
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
	DrawCardGrid();
	CompPos[2] += ScrollBar.CompPos[2];
}

final function DrawCardGrid()
{
	local int i,n,CardsPerRow,FocusCard,Level;
	local float Gap,CardW,CardH,X,Y,TextY,IconSize,MouseX,MouseY,LabelH;
	local KFGUI_ListItem C;
	local class<Ext_TraitBase> TC;
	local Texture2D Icon;
	local string Title,CostText,ReqText;
	local bool bReqBlocked;

	Canvas.DrawColor = BackgroundColor;
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);

	CardsPerRow = 4;
	if (CompPos[2]>760.f)
		CardsPerRow = 5;
	else if (CompPos[2]<520.f)
		CardsPerRow = 3;

	Gap = 8.f;
	CardW = (CompPos[2] - Gap*float(CardsPerRow+1)) / float(CardsPerRow);
	if (bCardMode)
		CardH = FMax((CompPos[3] - Gap*4.f) / 3.f,58.f);
	else CardH = FMax(CardW*0.54f,74.f);
	ListItemsPerPage = Max(CardsPerRow * Max(int(CompPos[3] / (CardH+Gap)),1),CardsPerRow);
	UpdateListVis();

	FocusMouseItem = -1;
	FocusCard = -1;
	if (bClickable && bFocused)
	{
		MouseX = Owner.MousePosition.X - CompPos[0];
		MouseY = Owner.MousePosition.Y - CompPos[1];
	}

	n = ScrollBar.CurrentScroll;
	i = 0;
	for (C=FirstItem; C!=None; C=C.Next)
		if ((i++)==n)
			break;

	for (i=0; i<ListItemsPerPage && C!=None; ++i)
	{
		X = Gap + float(i % CardsPerRow) * (CardW + Gap);
		Y = Gap + float(i / CardsPerRow) * (CardH + Gap);
		if ((Y+CardH)>CompPos[3])
			break;

		if (bClickable && bFocused && MouseX>=X && MouseX<=(X+CardW) && MouseY>=Y && MouseY<=(Y+CardH))
		{
			FocusMouseItem = n;
			FocusCard = i;
		}

		Canvas.SetPos(X,Y);
		if (SelectedRowIndex==n)
			Canvas.SetDrawColor(80,48,132,255);
		else if (FocusCard==i)
			Canvas.SetDrawColor(58,38,118,255);
		else Canvas.SetDrawColor(14,11,22,255);
		Owner.CurrentStyle.DrawWhiteBox(CardW,CardH);

		Canvas.SetPos(X+2,Y+2);
		Canvas.SetDrawColor(48,48,52,220);
		Owner.CurrentStyle.DrawWhiteBox(CardW-4,CardH*0.56f);

		if (DisplayPerk!=None && C.Value>=0 && C.Value<DisplayPerk.PerkTraits.Length)
		{
			TC = DisplayPerk.PerkTraits[C.Value].TraitType;
			Level = DisplayPerk.PerkTraits[C.Value].CurrentLevel;
			if (TC!=None)
			{
				Title = TrimTraitTitle(TC.Default.TraitName);
				Icon = ResolveTraitIcon(TC);
				if (Icon==None)
					Icon = DisplayPerk.PerkIcon;

				if (Level>=TC.Default.NumLevels)
				{
					CostText = "N/A";
				}
				else
				{
					if (TC.Static.MeetsRequirements(Level,DisplayPerk))
						CostText = string(TC.Static.GetTraitCost(Level));
					else CostText = "N/A";
				}
				if (TC.Default.TraitGroup==class'Ext_TGroupRegen')
				{
					ReqText = "R "$GetRegenTraitCount()$"/"$class'Ext_TGroupRegen'.Static.GetMaxLimit(DisplayPerk);
					bReqBlocked = class'Ext_TGroupRegen'.Static.GroupLimited(DisplayPerk,TC);
				}
				else if (TC.Default.MinLevel>0 && DisplayPerk.CurrentLevel<TC.Default.MinLevel)
				{
					ReqText = "Lv "$TC.Default.MinLevel;
					bReqBlocked = true;
				}
				else if (Level<TC.Default.NumLevels)
					ReqText = "Upg "$(Level+1);
				else ReqText = "Done";
			}
		}
		if (Title=="")
			Title = C.GetDisplayStr(0);

		if (Icon!=None)
		{
			IconSize = FMin(CardW*0.44f,CardH*0.38f);
			Canvas.SetPos(X+(CardW-IconSize)*0.5f,Y+5.f);
			Canvas.SetDrawColor(255,255,255,220);
			Canvas.DrawRect(IconSize,IconSize,Icon);
		}

		Canvas.SetPos(X+CardW-34.f,Y+4.f);
		Canvas.SetDrawColor(74,22,98,240);
		Owner.CurrentStyle.DrawWhiteBox(30.f,19.f);
		Canvas.SetPos(X+CardW-31.f,Y+5.f);
		Canvas.SetDrawColor(255,255,255,255);
		Canvas.DrawText(CostText,,TextScaler,TextScaler,LineFontInfo);

		Canvas.SetPos(X+CardW-43.f,Y+24.f);
		if (bReqBlocked)
			Canvas.SetDrawColor(210,32,42,255);
		else Canvas.SetDrawColor(210,195,230,255);
		Canvas.DrawText(ReqText,,TextScaler*0.78f,TextScaler*0.78f,LineFontInfo);

		LabelH = CardH*0.38f;
		Canvas.SetDrawColor(18,12,28,235);
		Canvas.SetPos(X+2,Y+CardH-LabelH-2.f);
		Owner.CurrentStyle.DrawWhiteBox(CardW-4,LabelH);

		TextY = Y+CardH-LabelH+2.f;
		Canvas.SetClip(CompPos[0]+X+CardW-6.f,CompPos[1]+Y+CardH-4.f);
		Canvas.SetPos(X+5.f,TextY);
		Canvas.SetDrawColor(245,235,245,255);
		DrawStrClipped(Title);

		++n;
		C = C.Next;
		Title = "";
		CostText = "";
		ReqText = "";
		bReqBlocked = false;
		Icon = None;
	}
}

final function int GetRegenTraitCount()
{
	local int i,Count;

	if (DisplayPerk==None)
		return 0;
	for (i=0; i<DisplayPerk.PerkTraits.Length; ++i)
	{
		if (DisplayPerk.PerkTraits[i].CurrentLevel>0 && DisplayPerk.PerkTraits[i].TraitType!=None && DisplayPerk.PerkTraits[i].TraitType.Default.TraitGroup==class'Ext_TGroupRegen')
			++Count;
	}
	return Count;
}

final function Texture2D ResolveTraitIcon(class<Ext_TraitBase> TC)
{
	local int i;
	local Texture2D Icon;

	if (TC==None)
		return None;

	if (TC.Default.TraitIcon!=None)
		return TC.Default.TraitIcon;

	i = DynamicIconNames.Find(TC.Name);
	if (i!=-1)
		return DynamicIcons[i];

	Icon = Texture2D(DynamicLoadObject("ServerExtTraitIcons."$string(TC.Name),class'Texture2D',true));
	if (Icon==None)
		Icon = Texture2D(DynamicLoadObject("ServerExtTraitIcons.TraitIcons."$string(TC.Name),class'Texture2D',true));
	if (Icon==None)
		Icon = Texture2D(DynamicLoadObject("ServerExt_TraitIcons."$string(TC.Name),class'Texture2D',true));
	if (Icon==None)
		Icon = Texture2D(DynamicLoadObject("ServerExt_TraitIcons.TraitIcons."$string(TC.Name),class'Texture2D',true));
	if (Icon==None)
		Icon = Texture2D(DynamicLoadObject("ServerExt.TraitIcons."$string(TC.Name),class'Texture2D',true));

	DynamicIconNames.AddItem(TC.Name);
	DynamicIcons.AddItem(Icon);
	return Icon;
}

final function string TrimTraitTitle(string S)
{
	S = Repl(S,"Survivalist ","");
	S = Repl(S,"Monster Tongue Extra","Zed Packmaster");
	S = Repl(S,"Monster Tongue","Zed Handler");
	S = Repl(S,"Monster Health","Zed Vitality");
	S = Repl(S,"Monster Damage","Zed Ferocity");
	S = Repl(S,"Enemy Health Bar","Zed Scan");
	S = Repl(S,"Ammo Regeneration","Ammo Resupply");
	S = Repl(S,"Health Regeneration","Health Regen");
	S = Repl(S,"Armor Regeneration","Armor Repair");
	S = Repl(S,"Resistance","Resist");
	S = Repl(S,"Ammunition","Ammo");
	S = Repl(S,"Magazine Size","Mag Size");
	S = Repl(S,"Rate Of Fire","Fire Rate");
	S = Repl(S,"Reload Speed","Reload");
	S = Repl(S,"Knockdown Effect","Knockdown");
	S = Repl(S,"Weapon Loadout","Loadout");
	S = Repl(S," weapons","");
	if (Len(S)>26)
		S = Left(S,24)$"..";
	return S;
}

function NotifyMousePaused()
{
	if (!bShowToolTips)
	{
		if (ToolTipItem!=None)
			ToolTipItem.DropInputFocus();
		return;
	}

	if (Owner.InputFocus==None && FocusMouseItem!=-1 && ToolTip[FocusMouseItem]!="")
	{
		if (ToolTipItem==None)
		{
			ToolTipItem = New(None)Class'KFGUI_Tooltip';
			ToolTipItem.Owner = Owner;
			ToolTipItem.ParentComponent = Self;
			ToolTipItem.InitMenu();
		}
		ToolTipItem.SetText(ToolTip[FocusMouseItem]);
		ToolTipItem.ShowMenu();
		ToolTipItem.CompPos[0] = Owner.MousePosition.X;
		ToolTipItem.CompPos[1] = Owner.MousePosition.Y;
		ToolTipItem.GetInputFocus();
	}
}

defaultproperties
{
	bCanSortColumn=false
	bShowToolTips=false
	bCardMode=true
	FontSize=0
}
