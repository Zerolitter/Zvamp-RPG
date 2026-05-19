// This file is part of Server Extension.

class ExtInventory_Money extends KFInventory_Money;

function DropFrom(vector StartLocation, vector StartVelocity)
{
	local KFDroppedPickup_Cash KFDP;
	local PlayerReplicationInfo PRI;
	local int Amount;
	local KFGameReplicationInfo KFGRI;
	local ExtInventoryManager ExtIM;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (DroppedPickupClass == None || DroppedPickupMesh == None || (KFGRI != None && KFGRI.bIsWeeklyMode && KFGRI.CurrentWeeklyIndex == 16))
		return;

	PRI = Instigator.PlayerReplicationInfo;
	if (PRI != None && PRI.Score > 0)
	{
		ExtIM = ExtInventoryManager(Instigator.InvManager);
		if (ExtIM != None)
			Amount = Min(Max(ExtIM.DoshThrowAmount, 1), int(PRI.Score));
		else Amount = Min(50, int(PRI.Score));
	}
	if (Amount <= 0)
		return;

	StartLocation.Z += Instigator.BaseEyeHeight / 2;
	KFDP = KFDroppedPickup_Cash(Spawn(DroppedPickupClass, PlayerController(Instigator.Controller),, StartLocation,,, true));
	if (KFDP == None)
	{
		PlayerController(Instigator.Controller).ReceiveLocalizedMessage(class'KFLocalMessage_Game', GMT_FailedDropInventory);
		return;
	}

	KFDP.SetPhysics(PHYS_Falling);
	KFDP.Inventory = self;
	KFDP.InventoryClass = class;
	KFDP.Velocity = StartVelocity * 1.6;
	KFDP.Instigator = Instigator;
	KFDP.SetPickupMesh(DroppedPickupMesh);
	KFDP.SetPickupParticles(DroppedPickupParticles);

	KFDP.CashAmount = Amount;
	KFDP.TosserPRI = PRI;
	if (KFPlayerReplicationInfo(PRI) != None)
		KFPlayerReplicationInfo(PRI).AddDosh(-Amount);

	`DialogManager.PlayDoshTossDialog(KFPawn(Instigator));
}
