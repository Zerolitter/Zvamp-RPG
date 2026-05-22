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

class ExtInventoryManager extends KFInventoryManager;

// Dosh spamming barrier.
var transient float MoneyTossTime;
var transient byte MoneyTossCount;
var bool bOverrideAmmoPickup,bOverrideItemPickup,bOverrideArmorPickup,bOverrideGrenadePickup,bAmmoPickupGivesArmor;
var int DoshThrowAmount;
var float AmmoPickupValue,ItemPickupValue,ArmorPickupValue,GrenadePickupValue,AmmoPickupArmorValue;

reliable server function ServerThrowMoney()
{
	if (MoneyTossTime>WorldInfo.TimeSeconds)
	{
		if (MoneyTossCount>=10)
			return;
		++MoneyTossCount;
		MoneyTossTime = FMax(MoneyTossTime,WorldInfo.TimeSeconds+0.5);
	}
	else
	{
		MoneyTossCount = 0;
		MoneyTossTime = WorldInfo.TimeSeconds+1;
	}
	Super.ServerThrowMoney();
}

simulated function Inventory CreateInventory(class<Inventory> NewInventoryItemClass, optional bool bDoNotActivate)
{
	local KFWeapon Wep;
	local Inventory SupClass;

	SupClass = Super.CreateInventory(NewInventoryItemClass, bDoNotActivate);
	if (NewInventoryItemClass == class'KFInventory_Money' && ExtInventory_Money(SupClass) == None)
	{
		if (SupClass != None)
			SupClass.Destroy();
		return Super.CreateInventory(class'ExtInventory_Money', bDoNotActivate);
	}
	Wep = KFWeapon(SupClass);

	if (Wep != none)
	{
		if (KFWeap_Pistol_Dual9mm(Wep) != None && ExtWeap_Pistol_Dual9mm(Wep) == None)
		{
			Wep.Destroy();
			return Super.CreateInventory(class'ExtWeap_Pistol_Dual9mm', bDoNotActivate);
		}

		return Wep;
	}

	return SupClass;
}

function SetAdminPickupOverrides(bool bAmmoPickup, float NewAmmoPickupValue, bool bItemPickup, float NewItemPickupValue, bool bArmorPickup, float NewArmorPickupValue)
{
	bOverrideAmmoPickup = bAmmoPickup;
	AmmoPickupValue = FMax(NewAmmoPickupValue,0.f);
	bOverrideItemPickup = bItemPickup;
	ItemPickupValue = FMax(NewItemPickupValue,0.f);
	bOverrideArmorPickup = bArmorPickup;
	ArmorPickupValue = FMax(NewArmorPickupValue,0.f);
}

function SetAdminResourcePickupOverrides(bool bGrenadePickup, float NewGrenadePickupValue, bool bArmorFromAmmo, float NewAmmoPickupArmorValue)
{
	bOverrideGrenadePickup = bGrenadePickup;
	GrenadePickupValue = FMax(NewGrenadePickupValue,0.f);
	bAmmoPickupGivesArmor = bArmorFromAmmo;
	AmmoPickupArmorValue = FMax(NewAmmoPickupArmorValue,0.f);
}

function SetDoshThrowAmount(int NewDoshThrowAmount)
{
	DoshThrowAmount = Clamp(NewDoshThrowAmount, 1, 1000000);
}

function bool GiveWeaponAmmo(KFWeapon KFW)
{
	local bool bAddedAmmo;

	if (!bOverrideAmmoPickup)
		return Super.GiveWeaponAmmo(KFW);

	if (KFW.AddAmmo(Max(Round(KFW.AmmoPickupScale[0] * KFW.MagazineCapacity[0] * AmmoPickupValue),1)) > 0)
		bAddedAmmo = true;

	if (KFW.CanRefillSecondaryAmmo())
	{
		if (KFW.AddSecondaryAmmo(Max(Round(KFW.AmmoPickupScale[1] * KFW.MagazineCapacity[1] * AmmoPickupValue),1)) > 0)
			bAddedAmmo = true;
	}

	return bAddedAmmo;
}

function bool GiveWeaponsAmmo(bool bIncludeGrenades)
{
	local KFWeapon W;
	local bool bAddedAmmo;
	local int GrenadeAmount;
	local KFPawn_Human KFPH;

	if (!bOverrideAmmoPickup && !bOverrideGrenadePickup && !bAmmoPickupGivesArmor)
		return Super.GiveWeaponsAmmo(bIncludeGrenades);

	foreach InventoryActors(class'KFWeapon', W)
	{
		if (!W.bInfiniteSpareAmmo && GiveWeaponAmmo(W))
			bAddedAmmo = true;
	}

	if (bIncludeGrenades)
	{
		GrenadeAmount = bOverrideGrenadePickup ? Max(Round(GrenadePickupValue),1) : 1;
		if (AddGrenades(GrenadeAmount))
			bAddedAmmo = true;
	}

	if (bAmmoPickupGivesArmor)
	{
		KFPH = KFPawn_Human(Instigator);
		if (KFPH != None && KFPH.Armor != KFPH.GetMaxArmor())
		{
			KFPH.AddArmor(Max(Round(float(KFPH.GetMaxArmor()) * AmmoPickupArmorValue),1));
			bAddedAmmo = true;
		}
	}

	if (bAddedAmmo)
	{
		PlayerController(Instigator.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_Ammo);
		PlayGiveInventorySound(AmmoPickupSound);
	}
	else
	{
		PlayerController(Instigator.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_AmmoIsFull);
	}

	return bAddedAmmo;
}

function bool AddArmorFromPickup()
{
	local KFPawn_Human KFPH;

	if (!bOverrideArmorPickup)
		return Super.AddArmorFromPickup();

	KFPH = KFPawn_Human(Instigator);
	if (KFPH != None && KFPH.Armor != KFPH.GetMaxArmor())
	{
		PlayerController(Instigator.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_PickedupArmor);
		PlayGiveInventorySound(ArmorPickupSound);
		KFPH.AddArmor(Max(Round(float(KFPH.GetMaxArmor()) * ArmorPickupValue),1));
		return true;
	}

	PlayerController(Instigator.Owner).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_FullArmor);
	return false;
}

simulated function CheckForExcessRemoval(KFWeapon NewWeap)
{
	local Inventory RemoveInv, Inv;

	if (KFWeap_Pistol_Dual9mm(NewWeap) != None)
	{
		for (Inv = InventoryChain; Inv != None; Inv = Inv.Inventory)
		{
			if (Inv.Class == class'ExtWeap_Pistol_9mm')
			{
				RemoveInv = Inv;
				Inv = Inv.Inventory;
				RemoveFromInventory(RemoveInv);
			}
		}
	}

	Super.CheckForExcessRemoval(NewWeap);
}

defaultproperties
{
	DoshThrowAmount=50
}
