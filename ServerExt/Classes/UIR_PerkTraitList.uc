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
	local int i,n;
	local float Y,RowH,IconSize,MouseY,NameX,StatusX,BuyX,BuyW,BuyH,XL,YL;
	local KFGUI_ListItem C;
	local class<Ext_TraitBase> TC;
	local Texture2D Icon;
	local string Title,StatusText,BuyText;
	local bool bSelected,bFocusedRow;
	local byte bCanBuy;
	local byte StatusR,StatusG,StatusB;

	Canvas.DrawColor = BackgroundColor;
	Canvas.SetPos(0.f,0.f);
	Owner.CurrentStyle.DrawWhiteBox(CompPos[2],CompPos[3]);

	RowH = FMax(TextHeight*2.25f,42.f);
	ListItemsPerPage = Max(int(CompPos[3] / RowH),1);
	RowH = CompPos[3] / ListItemsPerPage;
	UpdateListVis();

	FocusMouseItem = -1;
	if (bClickable && bFocused)
		MouseY = Owner.MousePosition.Y - CompPos[1];

	n = ScrollBar.CurrentScroll;
	i = 0;
	for (C=FirstItem; C!=None; C=C.Next)
		if ((i++)==n)
			break;

	NameX = RowH*0.95f;
	BuyW = FMin(92.f,CompPos[2]*0.21f);
	BuyH = FMin(RowH*0.62f,30.f);
	BuyX = CompPos[2]-BuyW-10.f;
	StatusX = BuyX-106.f;
	for (i=0; i<ListItemsPerPage && C!=None; ++i)
	{
		StatusR = 210;
		StatusG = 195;
		StatusB = 230;
		bCanBuy = 0;
		Y = float(i) * RowH;
		if (bClickable && bFocused && MouseY>=Y && MouseY<=(Y+RowH))
		{
			FocusMouseItem = n;
		}

		bSelected = (SelectedRowIndex==n);
		bFocusedRow = (FocusMouseItem==n);
		if (bSelected)
			Canvas.SetDrawColor(60,34,104,235);
		else if (bFocusedRow)
			Canvas.SetDrawColor(34,28,58,230);
		else Canvas.SetDrawColor(10,12,19,205);
		Canvas.SetPos(0.f,Y);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],RowH-2.f);
		Canvas.SetDrawColor(56,48,76,175);
		Canvas.SetPos(0.f,Y+RowH-2.f);
		Owner.CurrentStyle.DrawWhiteBox(CompPos[2],1.f);

		if (DisplayPerk!=None && C.Value>=0 && C.Value<DisplayPerk.PerkTraits.Length)
		{
			TC = DisplayPerk.PerkTraits[C.Value].TraitType;
			if (TC!=None)
			{
				Title = TrimTraitTitle(TC.Default.TraitName);
				Icon = ResolveTraitIcon(TC);
				if (Icon==None)
					Icon = DisplayPerk.PerkIcon;
				StatusText = GetLiveStatusText(C.Value,StatusR,StatusG,StatusB,bCanBuy);
			}
		}
		if (Title=="")
			Title = C.GetDisplayStr(0);

		if (Icon!=None)
		{
			IconSize = FMin(RowH*0.70f,34.f);
			Canvas.SetPos(10.f,Y+(RowH-IconSize)*0.5f);
			Canvas.SetDrawColor(255,255,255,220);
			Canvas.DrawRect(IconSize,IconSize,Icon);
		}

		Canvas.SetClip(CompPos[0]+StatusX-8.f,CompPos[1]+Y+RowH);
		Canvas.SetPos(NameX,Y+(RowH-TextHeight)*0.5f);
		Canvas.SetDrawColor(245,235,245,255);
		DrawStrClipped(Title);

		Canvas.SetClip(CompPos[0]+BuyX-10.f,CompPos[1]+Y+RowH);
		Canvas.SetDrawColor(StatusR,StatusG,StatusB,255);
		Canvas.SetPos(StatusX,Y+(RowH-TextHeight)*0.5f);
		Canvas.DrawText(StatusText,,TextScaler,TextScaler,LineFontInfo);

		Canvas.SetPos(BuyX,Y+(RowH-BuyH)*0.5f);
		if (bCanBuy!=0)
			Canvas.SetDrawColor(74,44,142,245);
		else Canvas.SetDrawColor(32,30,44,220);
		Owner.CurrentStyle.DrawWhiteBox(BuyW,BuyH);
		Canvas.SetDrawColor((bCanBuy!=0 ? 150 : 72),(bCanBuy!=0 ? 88 : 62),(bCanBuy!=0 ? 220 : 92),210);
		Canvas.SetPos(BuyX,Y+(RowH-BuyH)*0.5f);
		Owner.CurrentStyle.DrawWhiteBox(BuyW,2.f);
		BuyText = "BUY";
		if (bCanBuy==0)
			BuyText = "-";
		Canvas.TextSize(BuyText,XL,YL,TextScaler,TextScaler);
		Canvas.SetPos(BuyX+(BuyW-XL)*0.5f,Y+(RowH-YL)*0.5f);
		Canvas.SetDrawColor((bCanBuy!=0 ? 245 : 130),(bCanBuy!=0 ? 235 : 126),(bCanBuy!=0 ? 255 : 145),255);
		Canvas.DrawText(BuyText,,TextScaler,TextScaler,LineFontInfo);

		++n;
		C = C.Next;
		Title = "";
		StatusText = "";
		bCanBuy = 0;
		Icon = None;
	}
	Canvas.SetClip(CompPos[0]+CompPos[2],CompPos[1]+CompPos[3]);
}

function InternalClickedItem(int Index, bool bRight, int MouseX, int MouseY)
{
	local KFGUI_ListItem Item;

	SelectedRowIndex = Index;
	Item = GetFromIndex(Index);
	if (Item==None)
		return;

	if (bRight)
	{
		OnSelectedRow(Item,Index,true,false);
		return;
	}

	if (MouseX>=GetBuyHitX())
		TryBuyTrait(Item.Value);
}

function InternalDblClickedItem(int Index, bool bRight, int MouseX, int MouseY)
{
	local KFGUI_ListItem Item;

	SelectedRowIndex = Index;
	Item = GetFromIndex(Index);
	if (Item!=None)
		OnSelectedRow(Item,Index,bRight,true);
}

final function float GetBuyHitX()
{
	return CompPos[2]-FMin(92.f,CompPos[2]*0.21f)-12.f;
}

final function TryBuyTrait(int TraitIndex)
{
	local class<Ext_TraitBase> TC;
	local byte R,G,B;
	local byte bCanBuy;
	local ExtPlayerController PC;

	if (DisplayPerk==None || TraitIndex<0 || TraitIndex>=DisplayPerk.PerkTraits.Length)
		return;
	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return;
	TC = DisplayPerk.PerkTraits[TraitIndex].TraitType;
	if (TC==None)
		return;
	GetLiveStatusText(TraitIndex,R,G,B,bCanBuy);
	if (bCanBuy!=0)
		PC.BoughtTrait(DisplayPerk.Class,TC);
}

final function string GetLiveStatusText(int TraitIndex, out byte OutR, out byte OutG, out byte OutB, out byte bCanBuy)
{
	local class<Ext_TraitBase> TC;
	local int Level;

	OutR = 210;
	OutG = 195;
	OutB = 230;
	bCanBuy = 0;
	if (DisplayPerk==None || TraitIndex<0 || TraitIndex>=DisplayPerk.PerkTraits.Length)
		return "-";

	TC = DisplayPerk.PerkTraits[TraitIndex].TraitType;
	if (TC==None)
		return "-";
	Level = DisplayPerk.PerkTraits[TraitIndex].CurrentLevel;
	if (Level>=TC.Default.NumLevels)
	{
		OutR = 155;
		OutG = 235;
		OutB = 140;
		return "Done";
	}
	if (TC.Default.MinLevel>0 && DisplayPerk.CurrentLevel<TC.Default.MinLevel)
	{
		OutR = 255;
		OutG = 210;
		OutB = 95;
		return "Lv "$TC.Default.MinLevel;
	}
	if (Level==0 && TC.Default.TraitGroup==class'Ext_TGroupRegen')
		return GetRegenStatusText(TC,OutR,OutG,OutB,bCanBuy);
	if (TC.Static.MeetsRequirements(Level,DisplayPerk) && TC.Static.GetTraitCost(Level)<=DisplayPerk.CurrentSP)
	{
		OutR = 245;
		OutG = 235;
		OutB = 245;
		bCanBuy = 1;
		return "Upg "$Level$"/"$TC.Default.NumLevels;
	}
	if (TC.Static.MeetsRequirements(Level,DisplayPerk))
	{
		OutR = 255;
		OutG = 210;
		OutB = 95;
		return "Upg "$Level$"/"$TC.Default.NumLevels;
	}
	OutR = 235;
	OutG = 65;
	OutB = 72;
	return "Locked";
}

final function string GetRegenStatusText(class<Ext_TraitBase> TC, out byte OutR, out byte OutG, out byte OutB, out byte bCanBuy)
{
	local int Used,Limit;
	local bool bSlotAvailable;

	Used = GetRegenTraitCount();
	Limit = class'Ext_TGroupRegen'.Static.GetMaxLimit(DisplayPerk);
	bSlotAvailable = !class'Ext_TGroupRegen'.Static.GroupLimited(DisplayPerk,TC);
	if (bSlotAvailable)
	{
		OutR = 155;
		OutG = 235;
		OutB = 140;
		if (TC.Static.GetTraitCost(0)<=DisplayPerk.CurrentSP && TC.Static.MeetsRequirements(0,DisplayPerk))
			bCanBuy = 1;
		else bCanBuy = 0;
	}
	else if ((Used>=1 && DisplayPerk.CurrentPrestige<1) || (Used>=2 && DisplayPerk.CurrentPrestige<5))
	{
		OutR = 235;
		OutG = 65;
		OutB = 72;
	}
	else
	{
		OutR = 255;
		OutG = 210;
		OutB = 95;
	}
	return "R "$Used$"/"$Limit;
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
		Icon = Texture2D(DynamicLoadObject("SkillTraitIcons."$string(TC.Name),class'Texture2D',true));
	if (Icon==None)
		Icon = Texture2D(DynamicLoadObject("SkillTraitIcons.TraitIcons."$string(TC.Name),class'Texture2D',true));
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
