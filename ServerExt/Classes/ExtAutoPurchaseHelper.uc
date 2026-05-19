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

class ExtAutoPurchaseHelper extends KFAutoPurchaseHelper within ExtPlayerController;

final function class<KFPerk> GetBasePerk()
{
	return (ActivePerkManager!=None && ActivePerkManager.CurrentPerk!=None) ? ActivePerkManager.CurrentPerk.BasePerk : None;
}

final function Ext_PerkBase GetExtPerk()
{
	return ActivePerkManager!=None ? ActivePerkManager.CurrentPerk : None;
}

final function class<KFWeaponDefinition> GetSafeGrenadeWeaponDef(Ext_PerkBase EP)
{
	if (EP != None && EP.GrenadeWeaponDef != None)
	{
		return EP.GrenadeWeaponDef;
	}

	if (CurrentPerk != None && CurrentPerk.GetGrenadeWeaponDef() != None)
	{
		return CurrentPerk.GetGrenadeWeaponDef();
	}

	return class'KFWeapDef_Grenade_Berserker';
}

final function float GetSafeArmorDiscountMod()
{
	if (ActivePerkManager != None)
	{
		return ActivePerkManager.GetArmorDiscountMod();
	}

	if (CurrentPerk != None)
	{
		return CurrentPerk.GetArmorDiscountMod();
	}

	return 1.f;
}

function DoAutoPurchase()
{
	local int PotentialDosh, i;
	local Array <STraderItem> OnPerkWeapons;
	local STraderItem TopTierWeapon;
	local int ItemIndex;
	local bool bSecondaryWeaponPurchased;
	local bool bUpgradeSuccess;
	local bool bAutoFillPurchasedItem;
	local string AutoFillMessageString;
	local Ext_PerkBase EP;

	GetTraderItems();
	EP = GetExtPerk();

	if (EP==None || EP.AutoBuyLoadOutPath.length == 0)
		return;

	for (i = 0; i<EP.AutoBuyLoadOutPath.length; i++)
	{
		ItemIndex = TraderItems.SaleItems.Find('WeaponDef', EP.AutoBuyLoadOutPath[i]);
		if (ItemIndex != INDEX_NONE)
			OnPerkWeapons.AddItem(TraderItems.SaleItems[ItemIndex]);
	}

	SellOffPerkWeapons();

	TopTierWeapon = GetTopTierWeapon(OnPerkWeapons);
	//can I afford my top teir without selling my current weapon?
	if (!DoIOwnThisWeapon(TopTierWeapon) && GetCanAfford(GetAdjustedBuyPricefor (TopTierWeapon) + DoshBuffer) && CanCarry(TopTierWeapon))
	{
		bUpgradeSuccess = AttemptUpgrade(TotalDosh, OnPerkWeapons, true);
	}
	else
	{
		PotentialDosh = GetPotentialDosh();
		bUpgradeSuccess = AttemptUpgrade(PotentialDosh+TotalDosh, OnPerkWeapons);
	}

	bAutoFillPurchasedItem = StartAutoFill();
	if (DoIOwnThisWeapon(TopTierWeapon))
	{
		while (AttemptToPurchaseNextLowerTier(TotalDosh, OnPerkWeapons))
		{
			bSecondaryWeaponPurchased = true;
			AttemptToPurchaseNextLowerTier(TotalDosh, OnPerkWeapons);
		}
	}

	MyKFIM.ServerCloseTraderMenu();

	if (bUpgradeSuccess)
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.WeaponUpgradeComepleteString;
	}
	else if (bSecondaryWeaponPurchased)
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.SecondaryWeaponPurchasedString;
	}
	else if (bAutoFillPurchasedItem)
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.AutoFillCompleteString;
	}
	else
	{
		AutoFillMessageString = class'KFCommon_LocalizedStrings'.default.NoItemsPurchasedString;
	}


	if (MyGFxHUD != none)
	{
		MyGFxHUD.ShowNonCriticalMessage(class'KFCommon_LocalizedStrings'.default.AutoTradeCompleteString$AutoFillMessageString);
	}
}

function SellOnPerkWeapons()
{
	local int i;
	local class<KFPerk> Perk;

	Perk = GetBasePerk();
	if (Perk!=None)
	{
		for (i = 0; i < OwnedItemList.length; i++)
		{
			if (OwnedItemList[i].DefaultItem.AssociatedPerkClasses.Find(Perk)!=INDEX_NONE && OwnedItemList[i].DefaultItem.BlocksRequired != -1)
			{
				SellWeapon(OwnedItemList[i], i);
				i=-1;
			}
		}
	}
}

function SellOffPerkWeapons()
{
	local int i;
	local Ext_PerkBase EP;

	EP = GetExtPerk();
	if (EP == None)
	{
		return;
	}

	for (i = 0; i < OwnedItemList.length; i++)
	{
		if (OwnedItemList[i].DefaultItem.AssociatedPerkClasses.Find(EP.BasePerk)==INDEX_NONE && !IsUtilityTraderItem(OwnedItemList[i].DefaultItem) && OwnedItemList[i].SellPrice != 0)
		{
			if (EP.AutoBuyLoadOutPath.Find(OwnedItemList[i].DefaultItem.WeaponDef) == INDEX_NONE)
			{
				SellWeapon(OwnedItemList[i], i);
				i=-1;
			}
		}
	}
}

final function bool TraderItemMatchesWeapon(KFWeapon KFW, STraderItem Item)
{
	if (KFW == None)
	{
		return false;
	}

	if (KFW.Class.Name == Item.ClassName
		|| KFW.Class.Name == Item.SingleClassName
		|| KFW.Class.Name == Item.DualClassName)
	{
		return true;
	}

	if (Item.WeaponDef != None
		&& Item.WeaponDef.default.WeaponClassPath != ""
		&& PathName(KFW.Class) ~= Item.WeaponDef.default.WeaponClassPath)
	{
		return true;
	}

	if (Item.WeaponDef != None
		&& Item.WeaponDef.default.WeaponClassPath != ""
		&& InStr(Caps(Item.WeaponDef.default.WeaponClassPath), Caps(string(KFW.Class.Name))) >= 0)
	{
		return true;
	}

	return false;
}

final function bool IsUtilityTraderItem(STraderItem Item)
{
	if (Item.BlocksRequired == -1 || Item.WeaponDef == class'KFWeapDef_Welder')
	{
		return true;
	}

	if (Item.WeaponDef != None && InStr(Caps(Item.WeaponDef.default.WeaponClassPath), "WELDER") >= 0)
	{
		return true;
	}

	if (Item.WeaponDef != None && IsUtilityWeaponName(Item.WeaponDef.default.WeaponClassPath))
	{
		return true;
	}

	if (IsUtilityWeaponName(string(Item.ClassName)))
	{
		return true;
	}

	return false;
}

final function bool IsUtilityWeaponName(string ItemName)
{
	local string UtilityName;

	UtilityName = Caps(ItemName);
	return InStr(UtilityName, "WRENCH") >= 0
		|| InStr(UtilityName, "TURRET") >= 0
		|| InStr(UtilityName, "AUTOTURRET") >= 0
		|| InStr(UtilityName, "SENTRY") >= 0;
}

final function class<KFWeaponDefinition> ResolveWeaponDefForWeapon(KFWeapon KFW)
{
	local string ClassPath;
	local string PackageName;
	local string ClassName;
	local string Suffix;
	local string DefPath;
	local int DotPos;
	local class<KFWeaponDefinition> WeaponDef;

	if (KFW == None)
	{
		return None;
	}

	ClassPath = PathName(KFW.Class);
	DotPos = InStr(ClassPath, ".");
	if (DotPos <= 0)
	{
		return None;
	}

	PackageName = Left(ClassPath, DotPos);
	ClassName = string(KFW.Class.Name);
	if (Left(ClassName, 7) ~= "KFWeap_")
	{
		Suffix = Mid(ClassName, 7);
		DefPath = PackageName $ ".KFWeapDef_" $ Suffix;
		WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(DefPath, class'Class', true));
		if (WeaponDef != None && PathName(KFW.Class) ~= WeaponDef.default.WeaponClassPath)
		{
			return WeaponDef;
		}
	}

	DefPath = PackageName $ "." $ Repl(ClassName, "KFWeap", "KFWeapDef");
	WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(DefPath, class'Class', true));
	if (WeaponDef != None && PathName(KFW.Class) ~= WeaponDef.default.WeaponClassPath)
	{
		return WeaponDef;
	}

	return None;
}

function InitializeOwnedItemList()
{
	local KFPawn_Human KFP;
	local Ext_PerkBase EP;
	local class<KFWeaponDefinition> SafeGrenadeDef;
	local class<KFPerk> SafePerkClass;
	local KFPerk PawnPerk;

	EP = GetExtPerk();
	OwnedItemList.length = 0;

	TraderItems = KFGameReplicationInfo(WorldInfo.GRI).TraderItems;

	if (TraderItems == None || MyKFIM == None)
	{
		`log("[Zvampext] ExtAutoPurchaseHelper skipped trader item init: TraderItems="$TraderItems$" MyKFIM="$MyKFIM);
		return;
	}

	KFP = KFPawn_Human(Pawn);
	if (KFP == None)
	{
		`log("[Zvampext] ExtAutoPurchaseHelper skipped trader item init: pawn is not KFPawn_Human");
		return;
	}

	ArmorItem.SpareAmmoCount = KFP.Armor;
	ArmorItem.MaxSpareAmmo = KFP.GetMaxArmor();
	ArmorItem.AmmoPricePerMagazine = TraderItems.ArmorPrice * GetSafeArmorDiscountMod();
	ArmorItem.DefaultItem.WeaponDef = TraderItems.ArmorDef != None ? TraderItems.ArmorDef : class'KFWeapDef_Armor';

	PawnPerk = KFP.GetPerk();
	GrenadeItem.SpareAmmoCount = MyKFIM.GrenadeCount;
	if (ActivePerkManager != None)
	{
		GrenadeItem.MaxSpareAmmo = ActivePerkManager.MaxGrenadeCount;
	}
	else if (PawnPerk != None)
	{
		GrenadeItem.MaxSpareAmmo = PawnPerk.MaxGrenadeCount;
	}
	else
	{
		GrenadeItem.MaxSpareAmmo = 0;
	}
	GrenadeItem.AmmoPricePerMagazine = TraderItems.GrenadePrice;
	SafeGrenadeDef = GetSafeGrenadeWeaponDef(EP);
	GrenadeItem.DefaultItem.WeaponDef = SafeGrenadeDef;
	SafePerkClass = GetBasePerk();
	if (SafePerkClass == None && CurrentPerk != None)
	{
		SafePerkClass = CurrentPerk.Class;
	}
	if (SafePerkClass == None)
	{
		SafePerkClass = class'KFPerk_Berserker';
	}
	GrenadeItem.DefaultItem.AssociatedPerkClasses[0] = SafePerkClass;

	`log("[Zvampext] ExtAutoPurchaseHelper initialized generic trader items: owned=0 armorDef="$ArmorItem.DefaultItem.WeaponDef$" grenadeDef="$GrenadeItem.DefaultItem.WeaponDef$" perk="$SafePerkClass);
}

simulated function int GetAdjustedSellPriceFor(const out STraderItem ShopItem)
{
	if (ShopItem.WeaponDef == class'KFWeapDef_Welder')
	{
		return Max(1, ShopItem.WeaponDef.default.BuyPrice / 2);
	}

	return Super.GetAdjustedSellPriceFor(ShopItem);
}

function SetWeaponInformation(KFWeapon KFW)
{
	local int i;

	if (KFW == None || TraderItems == None)
	{
		return;
	}

	for (i = 0; i < TraderItems.SaleItems.Length; ++i)
	{
		if (TraderItemMatchesWeapon(KFW, TraderItems.SaleItems[i]))
		{
			SetWeaponInfo(KFW, TraderItems.SaleItems[i]);
			return;
		}
	}
}

function int AddItemByPriority(out SItemInformation WeaponInfo)
{
	local byte i;
	local byte WeaponGroup, WeaponPriority;
	local byte BestIndex;
	local class<KFPerk> Perk;

	Perk = GetBasePerk();

	BestIndex = 0;
	WeaponGroup = WeaponInfo.DefaultItem.InventoryGroup;
	WeaponPriority = WeaponInfo.DefaultItem.GroupPriority;

	for (i = 0; i < OwnedItemList.length; i++)
	{
		// If the weapon belongs in the group prior to the current weapon, we've found the spot
		if (WeaponGroup < OwnedItemList[i].DefaultItem.InventoryGroup)
		{
			BestIndex = i;
			break;
		}
		else if (WeaponGroup == OwnedItemList[i].DefaultItem.InventoryGroup)
		{
			if (WeaponPriority > OwnedItemList[i].DefaultItem.GroupPriority)
			{
				// if the weapon is in the same group but has a higher priority, we've found the spot
				BestIndex = i;
				break;
			}
			else if (WeaponPriority == OwnedItemList[i].DefaultItem.GroupPriority && WeaponInfo.DefaultItem.AssociatedPerkClasses.Find(Perk)>=0)
			{
				// if the weapons have the same priority give the slot to the on perk weapon
				BestIndex = i;
				break;
			}
		}
		else
		{
			// Covers the case if this weapon is the only item in the last group
			BestIndex = i + 1;
		}
	}
	OwnedItemList.InsertItem(BestIndex, WeaponInfo);

	// Add secondary ammo immediately after the main weapon
	if (WeaponInfo.DefaultItem.WeaponDef != None && WeaponInfo.DefaultItem.WeaponDef.static.UsesSecondaryAmmo())
	{
		WeaponInfo.bIsSecondaryAmmo = true;
		WeaponInfo.SellPrice = 0;
		OwnedItemList.InsertItem(BestIndex + 1, WeaponInfo);
	}

	return BestIndex;
}

function bool CanCarry(const out STraderItem Item, optional int OverrideLevelValue = INDEX_NONE)
{
	local int Result;

	Result = TotalBlocks + MyKFIM.GetDisplayedBlocksRequiredfor (Item);
	if (Result > MaxBlocks)
	{
		return false;
	}
	return true;
}
