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

class ExtMenu_Trader extends KFGFxMenu_Trader;

var ExtPlayerController ExtKFPC;
var Ext_PerkBase ExLastPerkClass;
var bool bZvampextApplyingPerkChange;
var array<int> ZvampextShopIndexMap;
var int ZvampextSelectedShopDisplayIndex;

function InitializeMenu(KFGFxMoviePlayer_Manager InManager)
{
	Super.InitializeMenu(InManager);
	ExtKFPC = ExtPlayerController (GetPC());
}

function int GetPerkIndex()
{
	return (ExtKFPC!=None ? ExtKFPC.GetZvampextTraderFilterIndex() : 0);
}

function bool ShouldHideOwnedTraderItem(SItemInformation ItemInfo)
{
	local class<KFWeapon> WeaponClass;

	WeaponClass = class<KFWeapon>(DynamicLoadObject(string(ItemInfo.DefaultItem.ClassName), class'Class', true));
	if (WeaponClass == None && ItemInfo.DefaultItem.WeaponDef != None)
	{
		WeaponClass = class<KFWeapon>(DynamicLoadObject(ItemInfo.DefaultItem.WeaponDef.default.WeaponClassPath, class'Class', true));
	}
	if (WeaponClass != None)
	{
		if (ClassIsChildOf(WeaponClass, class'KFWeap_Edged_Knife')
			|| ClassIsChildOf(WeaponClass, class'KFWeap_Healer_Syringe'))
		{
			return ClassIsChildOf(WeaponClass, class'KFWeap_Edged_Knife');
		}
	}

	return ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Berserker'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Commando'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Demo'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Firebug'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Gunslinger'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Medic'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Sharpshooter'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Support'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_Survivalist'
		|| ItemInfo.DefaultItem.WeaponDef == class'KFWeapDef_Knife_SWAT';
}

function bool IsOwnedSyringeItem(SItemInformation ItemInfo)
{
	local class<KFWeapon> WeaponClass;

	WeaponClass = class<KFWeapon>(DynamicLoadObject(string(ItemInfo.DefaultItem.ClassName), class'Class', true));

	return ItemInfo.DefaultItem.ClassName == 'KFWeap_Healer_Syringe'
		|| (WeaponClass != None && ClassIsChildOf(WeaponClass, class'KFWeap_Healer_Syringe'));
}

function bool IsSyringeTraderItem(STraderItem Item)
{
	local class<KFWeapon> WeaponClass;

	WeaponClass = class<KFWeapon>(DynamicLoadObject(string(Item.ClassName), class'Class', true));
	if (WeaponClass == None && Item.WeaponDef != None)
	{
		WeaponClass = class<KFWeapon>(DynamicLoadObject(Item.WeaponDef.default.WeaponClassPath, class'Class', true));
	}

	return Item.WeaponDef == class'KFWeapDef_Healer'
		|| Item.ClassName == 'KFWeap_Healer_Syringe'
		|| (WeaponClass != None && ClassIsChildOf(WeaponClass, class'KFWeap_Healer_Syringe'));
}

function bool FindSyringeTraderItem(out STraderItem SyringeItem)
{
	local int i;

	if (MyKFPC != None && MyKFPC.GetPurchaseHelper() != None)
	{
		for (i = 0; i < MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.Length; ++i)
		{
			if (IsSyringeTraderItem(MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[i]))
			{
				SyringeItem = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[i];
				return true;
			}
		}
	}

	SyringeItem.WeaponDef = class'KFWeapDef_Healer';
	SyringeItem.ClassName = 'KFWeap_Healer_Syringe';
	SyringeItem.MaxSpareAmmo = 100;
	SyringeItem.MagazineCapacity = 100;
	SyringeItem.BlocksRequired = 0;
	SyringeItem.InventoryGroup = 3;
	SyringeItem.GroupPriority = 255;
	SyringeItem.bCanBuyAmmo = false;
	return true;
}

function EnsureOwnedSyringeItem()
{
	local Inventory Inv;
	local KFWeapon KFW;
	local STraderItem SyringeItem;
	local SItemInformation SyringeInfo;
	local int i;

	for (i = 0; i < OwnedItemList.Length; ++i)
	{
		if (IsOwnedSyringeItem(OwnedItemList[i]))
		{
			OwnedItemList[i].SellPrice = 0;
			return;
		}
	}

	if (MyKFIM == None)
	{
		return;
	}

	for (Inv = MyKFIM.InventoryChain; Inv != None; Inv = Inv.Inventory)
	{
		KFW = KFWeapon(Inv);
		if (KFW != None && ClassIsChildOf(KFW.Class, class'KFWeap_Healer_Syringe'))
		{
			break;
		}
		KFW = None;
	}
	if (KFW == None || !FindSyringeTraderItem(SyringeItem))
	{
		return;
	}

	SyringeInfo.SpareAmmoCount = KFW.GetTotalAmmoAmount(0);
	SyringeInfo.MaxSpareAmmo = KFW.GetMaxAmmoAmount(0);
	SyringeInfo.MagazineCapacity = KFW.MagazineCapacity[0];
	SyringeInfo.SecondaryAmmoCount = KFW.GetTotalAmmoAmount(1);
	SyringeInfo.MaxSecondaryAmmo = KFW.GetMaxAmmoAmount(1);
	SyringeInfo.DefaultItem = SyringeItem;
	SyringeInfo.DefaultItem.bCanBuyAmmo = false;
	SyringeInfo.SellPrice = 0;
	SyringeInfo.AmmoPricePerMagazine = 0;
	SyringeInfo.ItemUpgradeLevel = KFW.CurrentWeaponUpgradeIndex;
	OwnedItemList.AddItem(SyringeInfo);
}

function bool ShouldDisplayShopItem(STraderItem Item, TabIndices TabIndex, byte FilterIndex, optional class<KFPerk> TargetPerkClass)
{
	if (IsSyringeTraderItem(Item))
	{
		return false;
	}
	if (ShopContainer != None && ShopContainer.IsItemFiltered(Item))
	{
		return false;
	}

	switch (TabIndex)
	{
	case TI_Perks:
		if (Item.AssociatedPerkClasses.Length > 0 && Item.AssociatedPerkClasses[0] != None
			&& TargetPerkClass != class'KFPerk_Survivalist'
			&& (TargetPerkClass == None || Item.AssociatedPerkClasses.Find(TargetPerkClass) == INDEX_NONE))
		{
			return false;
		}
		return Item.AssociatedPerkClasses.Length > 0;
	case TI_Type:
		return Item.TraderFilter == FilterIndex || Item.AltTraderFilter == FilterIndex;
	case TI_Favorites:
		return false;
	case TI_All:
		return true;
	}

	return true;
}

function AppendDisplayedShopItem(out array<STraderItem> DisplayedItems, out array<int> DisplayedIndexes, STraderItem Item, int OriginalIndex)
{
	DisplayedItems.AddItem(Item);
	DisplayedIndexes.AddItem(OriginalIndex);
}

function AppendDisplayedShopGroup(out array<STraderItem> DisplayedItems, out array<int> DisplayedIndexes, array<STraderItem> GroupItems, array<int> GroupIndexes)
{
	local int i;

	for (i = 0; i < GroupItems.Length; ++i)
	{
		AppendDisplayedShopItem(DisplayedItems, DisplayedIndexes, GroupItems[i], GroupIndexes[i]);
	}
}

function BuildDisplayedShopItems(TabIndices TabIndex, byte FilterIndex, out array<STraderItem> DisplayedItems)
{
	local int i;
	local array<STraderItem> SourceItems;
	local array<STraderItem> OnPerkWeapons, SecondaryWeapons, OffPerkWeapons;
	local array<int> OnPerkIndexes, SecondaryIndexes, OffPerkIndexes, DisplayedIndexes;
	local class<KFPerk> TargetPerkClass;
	local ExtPlayerController EKFPC;
	local int PerkMatchIndex;

	DisplayedItems.Length = 0;
	ZvampextShopIndexMap.Length = 0;
	if (MyKFPC == None || MyKFPC.GetPurchaseHelper() == None)
	{
		return;
	}

	EKFPC = ExtPlayerController(MyKFPC);
	if (EKFPC != None && EKFPC.ActivePerkManager != None && FilterIndex < EKFPC.ActivePerkManager.UserPerks.Length)
	{
		TargetPerkClass = EKFPC.ActivePerkManager.UserPerks[FilterIndex].BasePerk;
	}

	SourceItems = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems;
	for (i = 0; i < SourceItems.Length; ++i)
	{
		if (!ShouldDisplayShopItem(SourceItems[i], TabIndex, FilterIndex, TargetPerkClass))
		{
			continue;
		}

		if (TabIndex == TI_Perks)
		{
			PerkMatchIndex = SourceItems[i].AssociatedPerkClasses.Find(TargetPerkClass);
			if (PerkMatchIndex == 0)
			{
				AppendDisplayedShopItem(OnPerkWeapons, OnPerkIndexes, SourceItems[i], i);
			}
			else if (PerkMatchIndex == 1)
			{
				AppendDisplayedShopItem(SecondaryWeapons, SecondaryIndexes, SourceItems[i], i);
			}
			else
			{
				AppendDisplayedShopItem(OffPerkWeapons, OffPerkIndexes, SourceItems[i], i);
			}
		}
		else
		{
			AppendDisplayedShopItem(DisplayedItems, DisplayedIndexes, SourceItems[i], i);
		}
	}

	if (TabIndex == TI_Perks)
	{
		AppendDisplayedShopGroup(DisplayedItems, DisplayedIndexes, OnPerkWeapons, OnPerkIndexes);
		AppendDisplayedShopGroup(DisplayedItems, DisplayedIndexes, SecondaryWeapons, SecondaryIndexes);
		AppendDisplayedShopGroup(DisplayedItems, DisplayedIndexes, OffPerkWeapons, OffPerkIndexes);
	}

	ZvampextShopIndexMap = DisplayedIndexes;
}

function int GetOriginalShopIndex(int DisplayIndex)
{
	if (DisplayIndex >= 0 && DisplayIndex < ZvampextShopIndexMap.Length)
	{
		return ZvampextShopIndexMap[DisplayIndex];
	}
	return DisplayIndex;
}

function int GetDisplayShopIndex(int OriginalIndex)
{
	local int i;

	for (i = 0; i < ZvampextShopIndexMap.Length; ++i)
	{
		if (ZvampextShopIndexMap[i] == OriginalIndex)
		{
			return i;
		}
	}
	return INDEX_NONE;
}

function NormalizeOwnedTraderItems()
{
	local int i;

	EnsureOwnedSyringeItem();
	for (i = OwnedItemList.Length - 1; i >= 0; --i)
	{
		if (ShouldHideOwnedTraderItem(OwnedItemList[i]))
		{
			OwnedItemList.Remove(i, 1);
		}
		else if (IsOwnedSyringeItem(OwnedItemList[i]))
		{
			OwnedItemList[i].SellPrice = 0;
		}
	}
}

function SetPlayerItemDetails(int ItemIndex)
{
	local STraderItem SyringeItem;

	NormalizeOwnedTraderItems();
	if (MyKFPC != None && MyKFPC.GetPurchaseHelper() != None)
	{
		MyKFPC.GetPurchaseHelper().OwnedItemList = OwnedItemList;
	}

	if (ItemIndex < 0 || ItemIndex >= OwnedItemList.Length)
	{
		Super.SetPlayerItemDetails(ItemIndex);
		return;
	}

	Super.SetPlayerItemDetails(ItemIndex);
	if (IsOwnedSyringeItem(OwnedItemList[ItemIndex]))
	{
		if (ItemDetails != None)
		{
			SyringeItem = OwnedItemList[ItemIndex].DefaultItem;
			ItemDetails.SetPlayerItemDetails(SyringeItem, 0, OwnedItemList[ItemIndex].ItemUpgradeLevel);
		}
		bCanBuyOrSellItem = false;
		PurchaseError(false, false);
	}
}

function Callback_PlayerItemSelected(int ItemIndex)
{
	SetPlayerItemDetails(ItemIndex);
}

function RefreshShopItemList(TabIndices TabIndex, byte FilterIndex)
{
	local array<STraderItem> DisplayedItems;
	local int DisplayIndex;

	if (ShopContainer == None || FilterContainer == None)
	{
		return;
	}

	BuildDisplayedShopItems(TabIndex, FilterIndex, DisplayedItems);
	switch (TabIndex)
	{
	case TI_Perks:
		ShopContainer.RefreshAllItems(DisplayedItems);
		FilterContainer.SetPerkFilterData(FilterIndex);
		break;
	case TI_Type:
		ShopContainer.RefreshAllItems(DisplayedItems);
		FilterContainer.SetTypeFilterData(FilterIndex);
		break;
	case TI_Favorites:
		ShopContainer.RefreshAllItems(DisplayedItems);
		FilterContainer.ClearFilters();
		break;
	case TI_All:
		ShopContainer.RefreshAllItems(DisplayedItems);
		FilterContainer.ClearFilters();
		break;
	}
	FilterContainer.SetInt("selectedTab", TabIndex);
	FilterContainer.SetInt("selectedFilter", FilterIndex);

	if (SelectedList == TL_Shop)
	{
		DisplayIndex = GetDisplayShopIndex(SelectedItemIndex);
		if (DisplayIndex == INDEX_NONE)
		{
			DisplayIndex = Max(0, Min(ZvampextSelectedShopDisplayIndex, DisplayedItems.Length - 1));
			SelectedItemIndex = GetOriginalShopIndex(DisplayIndex);
		}
		SetTraderItemDetails(SelectedItemIndex);
		ShopContainer.SetSelectedIndex(DisplayIndex);
	}
}

function Callback_ShopItemSelected(int ItemIndex)
{
	ZvampextSelectedShopDisplayIndex = ItemIndex;
	SetTraderItemDetails(GetOriginalShopIndex(ItemIndex));
}

function AddExactShopItemToOwnedList(STraderItem DefaultItem)
{
	local SItemInformation WeaponInfo;
	local float AmmoCostScale;
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(GetPC().WorldInfo.GRI);
	AmmoCostScale = (KFGRI != None) ? KFGRI.GameAmmoCostScale : 1.f;

	WeaponInfo.MagazineCapacity = DefaultItem.MagazineCapacity;
	if (MyKFPC.CurrentPerk != None)
	{
		MyKFPC.CurrentPerk.ModifyMagSizeAndNumber(None, WeaponInfo.MagazineCapacity, DefaultItem.AssociatedPerkClasses,, DefaultItem.ClassName);
	}
	WeaponInfo.MaxSpareAmmo = DefaultItem.MaxSpareAmmo;
	if (MyKFPC.CurrentPerk != None)
	{
		MyKFPC.CurrentPerk.ModifyMaxSpareAmmoAmount(None, WeaponInfo.MaxSpareAmmo, DefaultItem);
	}
	WeaponInfo.MaxSpareAmmo += WeaponInfo.MagazineCapacity;
	WeaponInfo.SpareAmmoCount = DefaultItem.InitialSpareMags * WeaponInfo.MagazineCapacity;
	if (MyKFPC.CurrentPerk != None)
	{
		MyKFPC.CurrentPerk.ModifySpareAmmoAmount(None, WeaponInfo.SpareAmmoCount, DefaultItem);
		MyKFPC.CurrentPerk.MaximizeSpareAmmoAmount(DefaultItem.AssociatedPerkClasses, WeaponInfo.SpareAmmoCount, DefaultItem.MaxSpareAmmo + WeaponInfo.MagazineCapacity);
	}
	WeaponInfo.SpareAmmoCount += WeaponInfo.MagazineCapacity;
	WeaponInfo.SecondaryAmmoCount = DefaultItem.InitialSecondaryAmmo;
	if (MyKFPC.CurrentPerk != None)
	{
		MyKFPC.CurrentPerk.ModifySpareAmmoAmount(None, WeaponInfo.SecondaryAmmoCount, DefaultItem, true);
	}
	WeaponInfo.MaxSecondaryAmmo = DefaultItem.MaxSecondaryAmmo;
	if (MyKFPC.CurrentPerk != None)
	{
		MyKFPC.CurrentPerk.ModifyMaxSpareAmmoAmount(None, WeaponInfo.MaxSecondaryAmmo, DefaultItem, true);
	}
	WeaponInfo.AmmoPricePerMagazine = AmmoCostScale * DefaultItem.WeaponDef.default.AmmoPricePerMag;
	WeaponInfo.DefaultItem = DefaultItem;
	WeaponInfo.SellPrice = MyKFPC.GetPurchaseHelper().GetAdjustedSellPriceFor(DefaultItem);
	OwnedItemList.AddItem(WeaponInfo);
	MyKFPC.GetPurchaseHelper().OwnedItemList = OwnedItemList;
}

function bool TryZvampextBuyShopItem()
{
	local int OriginalIndex;
	local int Price;
	local int ItemUpgradeLevel;
	local STraderItem ShopItem;

	if (MyKFPC == None || MyKFIM == None || MyKFPC.GetPurchaseHelper() == None || SelectedList != TL_Shop)
	{
		return false;
	}

	OriginalIndex = SelectedItemIndex;
	if (ZvampextSelectedShopDisplayIndex >= 0 && ZvampextSelectedShopDisplayIndex < ZvampextShopIndexMap.Length)
	{
		OriginalIndex = ZvampextShopIndexMap[ZvampextSelectedShopDisplayIndex];
	}
	if (OriginalIndex < 0 || OriginalIndex >= MyKFPC.GetPurchaseHelper().TraderItems.SaleItems.Length)
	{
		return false;
	}

	ShopItem = MyKFPC.GetPurchaseHelper().TraderItems.SaleItems[OriginalIndex];
	if (!MyKFPC.GetPurchaseHelper().GetCanAfford(MyKFPC.GetPurchaseHelper().GetAdjustedBuyPriceFor(ShopItem))
		|| !MyKFPC.GetPurchaseHelper().CanCarry(ShopItem))
	{
		MyKFPC.PlayTraderSelectItemDialog(!MyKFPC.GetPurchaseHelper().GetCanAfford(MyKFPC.GetPurchaseHelper().GetAdjustedBuyPriceFor(ShopItem)), !MyKFPC.GetPurchaseHelper().CanCarry(ShopItem));
		return true;
	}

	Price = MyKFPC.GetPurchaseHelper().GetAdjustedBuyPriceFor(ShopItem);
	MyKFPC.AddWeaponPurchased(ShopItem.WeaponDef, Price);
	ItemUpgradeLevel = ShopItem.SingleClassName != '' ? MyKFPC.GetPurchaseHelper().GetItemUpgradeLevelByClassName(ShopItem.SingleClassName) : INDEX_None;
	if (ItemUpgradeLevel == INDEX_None)
		ItemUpgradeLevel = 0;
	MyKFPC.GetPurchaseHelper().AddDosh(-Price);
	MyKFPC.GetPurchaseHelper().AddBlocks(MyKFIM.GetWeaponBlocks(ShopItem, ItemUpgradeLevel));
	AddExactShopItemToOwnedList(ShopItem);
	MyKFIM.ServerBuyWeapon(OriginalIndex, ItemUpgradeLevel);
	SetNewSelectedIndex(ZvampextShopIndexMap.Length);
	SetTraderItemDetails(OriginalIndex);
	ShopContainer.ActionScriptVoid("itemBought");
	RefreshItemComponents();
	return true;
}

function RefreshItemComponents(optional bool bInitOwnedItems=false)
{
	Super.RefreshItemComponents(bInitOwnedItems);

	if (PlayerInventoryContainer != None && MyKFPC != None && MyKFPC.GetPurchaseHelper() != None)
	{
		OwnedItemList = MyKFPC.GetPurchaseHelper().OwnedItemList;
		NormalizeOwnedTraderItems();
		MyKFPC.GetPurchaseHelper().OwnedItemList = OwnedItemList;
		PlayerInventoryContainer.RefreshPlayerInventory();
	}
}

function bool TryZvampextSellOwnedItem(int OwnedIndex)
{
	local SItemInformation ItemInfo;

	if (ExtKFPC == None || MyKFPC == None || MyKFPC.GetPurchaseHelper() == None
		|| OwnedIndex < 0 || OwnedIndex >= OwnedItemList.Length)
	{
		return false;
	}

	ItemInfo = OwnedItemList[OwnedIndex];
	if (ItemInfo.bIsSecondaryAmmo || ItemInfo.DefaultItem.ClassName == '' || IsOwnedSyringeItem(ItemInfo))
	{
		return false;
	}

	MyKFPC.GetPurchaseHelper().AddDosh(ItemInfo.SellPrice);
	MyKFPC.GetPurchaseHelper().AddBlocks(-MyKFIM.GetDisplayedBlocksRequiredFor(ItemInfo.DefaultItem));
	ExtKFPC.ZvampextServerSellTraderWeaponByClass(ItemInfo.DefaultItem.ClassName);
	OwnedItemList.Remove(OwnedIndex, 1);
	MyKFPC.GetPurchaseHelper().OwnedItemList = OwnedItemList;
	return true;
}

function Callback_BuyOrSellItem()
{
	if (SelectedList == TL_Shop && TryZvampextBuyShopItem())
	{
		return;
	}

	if (bCanBuyOrSellItem && SelectedList != TL_Shop && TryZvampextSellOwnedItem(SelectedItemIndex))
	{
		SetNewSelectedIndex(OwnedItemList.Length);
		SetPlayerItemDetails(SelectedItemIndex);
		PlayerInventoryContainer.ActionScriptVoid("itemSold");
		GameInfoContainer.UpdateGameInfo();
		GameInfoContainer.SetDosh(MyKFPC.GetPurchaseHelper().TotalDosh);
		GameInfoContainer.SetCurrentWeight(MyKFPC.GetPurchaseHelper().TotalBlocks, MyKFPC.GetPurchaseHelper().MaxBlocks);
		return;
	}

	Super.Callback_BuyOrSellItem();
}

function UpdatePlayerInfo()
{
	if (ExtKFPC != none && PlayerInfoContainer != none)
	{
		PlayerInfoContainer.SetPerkInfo();
		PlayerInfoContainer.SetPerkList();
		if (!bZvampextApplyingPerkChange && ExtKFPC.ActivePerkManager!=None && ExtKFPC.ActivePerkManager.CurrentPerk!=ExLastPerkClass)
		{
			ExLastPerkClass = ExtKFPC.ActivePerkManager.CurrentPerk;
			ExtKFPC.SetZvampextClientTraderFilterIndex(ExtKFPC.GetZvampextActiveTraderPerkIndex());
			OnPerkChanged(GetPerkIndex());
		}

		RefreshItemComponents();
	}
}

function Callback_PerkChanged(int PerkIndex)
{
	if (ExtKFPC==None || ExtKFPC.ActivePerkManager==None || PerkIndex<0 || PerkIndex>ExtKFPC.ActivePerkManager.UserPerks.Length)
		return;

	if (bZvampextApplyingPerkChange)
		return;

	bZvampextApplyingPerkChange = true;
	if (PerkIndex==ExtKFPC.ActivePerkManager.UserPerks.Length)
	{
		ExtKFPC.SetZvampextClientTraderFilterIndex(PerkIndex);
		OnPerkChanged(PerkIndex);
		bZvampextApplyingPerkChange = false;
		RefreshItemComponents();
		return;
	}

	ExtKFPC.SetZvampextClientTraderPerkIndex(PerkIndex);
	ExtKFPC.PendingPerkClass = ExtKFPC.ActivePerkManager.UserPerks[PerkIndex].Class;
	ExtKFPC.SwitchToPerk(ExtKFPC.PendingPerkClass);
	ExLastPerkClass = ExtKFPC.ActivePerkManager.CurrentPerk;
	OnPerkChanged(PerkIndex);
	bZvampextApplyingPerkChange = false;

	if (PlayerInventoryContainer != none)
	{
		PlayerInventoryContainer.UpdateLock();
	}
	UpdatePlayerInfo();

	// Refresht he UI
	RefreshItemComponents();
}

function OnPerkChanged(int PerkIndex)
{
	if (ExtKFPC!=None && ExtKFPC.ActivePerkManager!=None
		&& PerkIndex>=0 && PerkIndex<=ExtKFPC.ActivePerkManager.UserPerks.Length)
	{
		ExtKFPC.SetZvampextClientTraderFilterIndex(PerkIndex);
	}

	Super.OnPerkChanged(PerkIndex);
	if (PlayerInfoContainer != none)
	{
		PlayerInfoContainer.SetPerkInfo();
		PlayerInfoContainer.SetPerkList();
	}
}

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="filterContainer",WidgetClass=class'KFGFxTraderContainer_Filter'))
	SubWidgetBindings.Add((WidgetName="filterContainer",WidgetClass=class'ExtTraderContainer_Filter'))
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'ExtTraderContainer_Store'))
	SubWidgetBindings.Remove((WidgetName="playerInfoContainer",WidgetClass=class'KFGFxTraderContainer_PlayerInfo'))
	SubWidgetBindings.Add((WidgetName="playerInfoContainer",WidgetClass=class'ExtTraderContainer_PlayerInfo'))
}
