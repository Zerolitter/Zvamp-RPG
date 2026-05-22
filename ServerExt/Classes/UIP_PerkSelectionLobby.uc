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

Class UIP_PerkSelectionLobby extends UIP_PerkSelection;

var localized string LevelText;
var localized string PointsText;
var localized string NoPerkSelectedText;

function Timer()
{
	local int i;
	local ExtPlayerController PC;

	PC = ExtPlayerController(GetPlayer());
	if (PC==None)
		return;
	CurrentManager = PC.ActivePerkManager;
	if (CurrentManager==None)
	{
		RequestLobbyPerkReplication(PC);
		HandleLobbyPerkDataNotReady();
		return;
	}
	if (CurrentManager!=None)
	{
		if (CurrentManager.UserPerks.Length==0 || CurrentManager.CurrentPerk==None)
			CurrentManager.InitPerks();
		if (CurrentManager.UserPerks.Length==0 || CurrentManager.CurrentPerk==None)
		{
			RequestLobbyPerkReplication(PC);
			HandleLobbyPerkDataNotReady();
			return;
		}
		if (PrevPendingPerk!=None)
		{
			PendingPerk = CurrentManager.FindPerk(PrevPendingPerk);
			PrevPendingPerk = None;
		}
		PerkList.ChangeListSize(CurrentManager.UserPerks.Length);
		if (PendingPerk!=None && !IsLobbyPerkUsable(PendingPerk))
		{
			RequestLobbyPerkReplication(PC);
			HandleLobbyPerkDataNotReady();
			return;
		}

		// Huge code block to handle stat updating, but actually pretty well optimized.
		if (PendingPerk!=OldUsedPerk)
		{
			OldUsedPerk = PendingPerk;
			if (PendingPerk!=None)
			{
				OldPerkPoints = -1;
				if (StatsList.ItemComponents.Length!=PendingPerk.PerkStats.Length)
				{
					if (StatsList.ItemComponents.Length<PendingPerk.PerkStats.Length)
					{
						for (i=StatsList.ItemComponents.Length; i<PendingPerk.PerkStats.Length; ++i)
						{
							if (i>=StatBuyers.Length)
							{
								StatBuyers[StatBuyers.Length] = UIR_PerkStat(StatsList.AddListComponent(class'UIR_PerkStat'));
								StatBuyers[i].StatIndex = i;
								StatBuyers[i].InitMenu();
							}
							else
							{
								StatsList.ItemComponents.Length = i+1;
								StatsList.ItemComponents[i] = StatBuyers[i];
							}
						}
					}
					else if (StatsList.ItemComponents.Length>PendingPerk.PerkStats.Length)
					{
						for (i=PendingPerk.PerkStats.Length; i<StatsList.ItemComponents.Length; ++i)
							StatBuyers[i].CloseMenu();
						StatsList.ItemComponents.Length = PendingPerk.PerkStats.Length;
					}
				}
				OldPerkPoints = PendingPerk.CurrentSP;
				PerkLabel.SetText(LevelText$PendingPerk.GetLevelString()@PendingPerk.PerkName@"("$PointsText@PendingPerk.CurrentSP$")");
				for (i=0; i<StatsList.ItemComponents.Length; ++i) // Just make sure perk stays the same.
				{
					StatBuyers[i].SetActivePerk(PendingPerk);
					StatBuyers[i].CheckBuyLimit();
				}
				UpdateTraits();
			}
			else // Empty out if needed.
			{
				for (i=0; i<StatsList.ItemComponents.Length; ++i)
					StatBuyers[i].CloseMenu();
				StatsList.ItemComponents.Length = 0;
				PerkLabel.SetText(NoPerkSelectedText);
			}
		}
		else if (PendingPerk!=None && OldPerkPoints!=PendingPerk.CurrentSP)
		{
			OldPerkPoints = PendingPerk.CurrentSP;
			PerkLabel.SetText(LevelText$PendingPerk.GetLevelString()@PendingPerk.PerkName@"("$PointsText@PendingPerk.CurrentSP$")");
			for (i=0; i<StatsList.ItemComponents.Length; ++i) // Just make sure perk stays the same.
				StatBuyers[i].CheckBuyLimit();

			// Update traits list.
			UpdateTraits();
		}
	}
}

final function bool IsLobbyPerkUsable(Ext_PerkBase P)
{
	return (P!=None && P.bPerkNetReady && P.PerkStats.Length>0 && P.PerkTraits.Length>0);
}

final function RequestLobbyPerkReplication(ExtPlayerController PC)
{
	if (PC==None)
		return;
	if (PC.WorldInfo.TimeSeconds-LastPerkReplicationRequestTime<2.f)
		return;
	LastPerkReplicationRequestTime = PC.WorldInfo.TimeSeconds;
	PC.ZvampextRequestPerkReplication();
}

final function HandleLobbyPerkDataNotReady()
{
	local int i;

	if (StatsList!=None)
	{
		for (i=0; i<StatsList.ItemComponents.Length; ++i)
			if (i<StatBuyers.Length && StatBuyers[i]!=None)
				StatBuyers[i].CloseMenu();
		StatsList.ItemComponents.Length = 0;
	}
	if (TraitsList!=None)
	{
		TraitsList.DisplayPerk = None;
		TraitsList.ChangeListSize(0);
	}
	if (PerkLabel!=None)
		PerkLabel.SetText("Loading perk data...");
	OldUsedPerk = None;
	OldPerkPoints = -1;
}

defaultproperties
{
	bUseSpawnedHeader=false
	Components.Remove(UnloadPerkButton)
	Components.Remove(PrestigePerkButton)
	Components.Remove(ResetPerkButton)
}
