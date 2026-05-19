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

Class ExtPlayerController extends KFPlayerController;

var localized string GotItemText;
var localized string KilledHimselfWith;
var localized string WasBurnedToDeath;
var localized string WasBlownIntoPeaces;
var localized string HadSuddenHeartAttack;
var localized string WasKilledBy;
var localized string WasIncineratedBy;
var localized string WasBlownUpBy;
var localized string ConnectionError;
var localized string Disconnecting;
var localized string NowViewingFrom;
var localized string ViewingFromOwnCamera;

struct FAdminCmdType
{
	var string Cmd,Info;
};
struct FPendingPerkStatBuy
{
	var class<Ext_PerkBase> PerkClass;
	var int StatIndex;
	var int Amount;
};
enum EDmgMsgType
{
	DMG_PawnDamage,
	DMG_EXP,
	DMG_Heal,
};
var string ServerMOTD,PendingMOTD;

var ExtPerkManager ActivePerkManager;
var class<KFGUI_Page> MidGameMenuClass;
var class<Ext_PerkBase> PendingPerkClass;
var private transient rotator OldViewRot;
var private transient float LastMisfireTime,LastFireTime,MisfireTimer;
var private transient byte MisfireCount,MisrateCounter;
var transient float NextSpectateChange,NextCommTime;
var array<FAdminCmdType> AdminCommands;
var transient byte DropCount;
var transient Object UserAPI;
var transient SoundCue BonusMusic;
var transient Object BonusFX;
var bool bRevampTraderGuardEnabled,bRevampTraderGuardBlockSkip,bRevampTraderGuardPublicOpenTrader;
var bool bVampUIEndMatchEnabled;
var bool bAdminGrenadeDamage,bAdminGrenadeRadius,bAdminAmmoPickup,bAdminItemPickup,bAdminArmorPickup;
var float AdminGrenadeDamageValue,AdminGrenadeRadiusValue,AdminAmmoPickupValue,AdminItemPickupValue,AdminArmorPickupValue;
var bool bZvampCameraEnabled,bZvampDisableCamShakes,bZvampDisableSprintFOVChange,bZvampDisableEarsRinging,bZvampDisableCameraAnims;
var float ZvampZedTimeEffectReduction;
var string SpawnedPerkUILayout,MidGameMenuLayout,ZvampextBuildID;
var int PlayerDoshThrowAmount;
var transient array<FPendingPerkStatBuy> PendingStatBuys;
var transient array<string> ZvampextClientTraderItems;
var transient byte ZvampextSettingsSyncRetries;

// Stats
var transient byte TransitListNum;
var transient int TransitIndex;

// Dramatic end-game camera.
var transient vector EndGameCamFocusPos[2],CalcViewLocation;
var transient rotator EndGameCamRot,CalcViewRotation;
var transient float EndGameCamTimer,LastPlayerCalcView;
var transient bool bEndGameCamFocus;

var globalconfig bool bShowFPLegs,bHideNameBeacons,bHideKillMsg,bHideDamageMsg,bHideNumberMsg,bNoMonsterPlayer,bNoScreenShake,bRenderModes,bUseKF2DeathMessages,bUseKF2KillMessages;
var globalconfig int SelectedEmoteIndex;
var bool bMOTDReceived,bNamePlateShown,bNamePlateHidden,bClientHideKillMsg,bClientHideDamageMsg,bClientHideNumbers,bNoDamageTracking,bClientNoZed,bSetPerk;
var bool bRevampTestCheatsEnabled;
var transient bool bRevampGodMode;
var transient bool bVampUIClosedForEndGame;
var transient int LastZvampextStockPerkIndex,LastZvampextStockPerkLevel,ZvampextClientTraderFilterIndex;
var transient class<KFPerk> LastZvampextStockPerkClass;

struct SavedSkins
{
	var int ID;
	var class<KFWeaponDefinition> WepDef;
};
var globalconfig array<SavedSkins> SavedWeaponSkins;

replication
{
	// Things the server should send to the client.
	if (bNetDirty)
		MidGameMenuClass,ActivePerkManager,bRevampTraderGuardEnabled,bRevampTraderGuardBlockSkip,bRevampTraderGuardPublicOpenTrader,
		bVampUIEndMatchEnabled,bAdminGrenadeDamage,bAdminGrenadeRadius,bAdminAmmoPickup,bAdminItemPickup,bAdminArmorPickup,
		AdminGrenadeDamageValue,AdminGrenadeRadiusValue,AdminAmmoPickupValue,AdminItemPickupValue,AdminArmorPickupValue;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if (WorldInfo.NetMode!=NM_Client && ActivePerkManager==None)
	{
		ActivePerkManager = Spawn(class'ExtPerkManager',Self);
		ActivePerkManager.PlayerOwner = Self;
		ActivePerkManager.PRIOwner = ExtPlayerReplicationInfo(PlayerReplicationInfo);
		if (ActivePerkManager.PRIOwner!=None)
			ActivePerkManager.PRIOwner.PerkManager = ActivePerkManager;
		SetTimer(0.1,true,'CheckPerk');
	}
	else if (WorldInfo.NetMode==NM_Client)
	{
		ZvampextSettingsSyncRetries = 8;
		SetTimer(0.25,true,'ZvampextClientUISyncTimer');
	}
}

simulated function Destroyed()
{
	if (ActivePerkManager!=None)
		ActivePerkManager.PreNotifyPlayerLeave();
	Super.Destroyed();
	if (ActivePerkManager!=None)
		ActivePerkManager.Destroy();
}

final function int GetZvampextBasePerkIndex(class<KFPerk> BasePerk)
{
	local int i;

	if (BasePerk == None)
		return 0;

	for (i=0; i<PerkList.Length; ++i)
		if (PerkList[i].PerkClass == BasePerk)
			return i;

	if (BasePerk == class'KFPerk_Berserker') return 0;
	if (BasePerk == class'KFPerk_Commando') return 1;
	if (BasePerk == class'KFPerk_Support') return 2;
	if (BasePerk == class'KFPerk_FieldMedic') return 3;
	if (BasePerk == class'KFPerk_Demolitionist') return 4;
	if (BasePerk == class'KFPerk_Firebug') return 5;
	if (BasePerk == class'KFPerk_Gunslinger') return 6;
	if (BasePerk == class'KFPerk_Sharpshooter') return 7;
	if (BasePerk == class'KFPerk_SWAT') return 8;
	if (BasePerk == class'KFPerk_Survivalist') return 9;

	return 0;
}

function SyncZvampextPerkToStock()
{
	local KFPlayerReplicationInfo KFPRI;
	local Ext_PerkBase ActivePerk;
	local int PerkIndex;

	KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	if (KFPRI == None || ActivePerkManager == None || ActivePerkManager.CurrentPerk == None)
		return;

	ActivePerk = ActivePerkManager.CurrentPerk;
	PerkIndex = GetZvampextBasePerkIndex(ActivePerk.BasePerk);
	KFPRI.NetPerkIndex = PerkIndex;
	KFPRI.CurrentPerkClass = ActivePerk.BasePerk;
	if (PerkIndex >= 0 && PerkIndex < PerkList.Length)
		PerkList[PerkIndex].PerkLevel = ActivePerk.CurrentLevel;
	KFPRI.bForceNetUpdate = true;

	if (LastZvampextStockPerkIndex != PerkIndex
		|| LastZvampextStockPerkLevel != ActivePerk.CurrentLevel
		|| LastZvampextStockPerkClass != ActivePerk.BasePerk)
	{
		LastZvampextStockPerkIndex = PerkIndex;
		LastZvampextStockPerkLevel = ActivePerk.CurrentLevel;
		LastZvampextStockPerkClass = ActivePerk.BasePerk;
		ClientSyncZvampextPerkToStock(ActivePerk.BasePerk, PerkIndex, ActivePerk.CurrentLevel);
	}
}

reliable client function ClientSyncZvampextPerkToStock(class<KFPerk> BasePerk, int PerkIndex, int PerkLevel)
{
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	if (KFPRI != None && BasePerk != None)
	{
		KFPRI.NetPerkIndex = PerkIndex;
		KFPRI.CurrentPerkClass = BasePerk;
		KFPRI.bForceNetUpdate = true;
	}
	if (PerkIndex >= 0 && PerkIndex < PerkList.Length)
	{
		PerkList[PerkIndex].PerkLevel = PerkLevel;
	}
	PatchZvampextStockTraderPerkInfo();
	`log("[Zvamp] client synced stock perk: class="$BasePerk@"index="$PerkIndex@"level="$PerkLevel);
}

simulated function ZvampextClientUISyncTimer()
{
	CheckVampUIEndMatchHandoff();
	if (ZvampextSettingsSyncRetries > 0)
	{
		SendServerSettings();
		--ZvampextSettingsSyncRetries;
	}
	if (ActivePerkManager != None && CurrentPerk != ActivePerkManager)
	{
		CurrentPerk = ActivePerkManager;
	}
	SyncZvampextClientPerkListLevels();
	SyncZvampextStockCurrentPerk();
	RefreshZvampextStockTraderPerkSelection();
	PatchZvampextStockTraderPerkInfo();
	ApplyZvampCameraSettings();
}

simulated final function bool IsVampUIEndMatchState()
{
	local KFGameReplicationInfo KFGRI;

	if (WorldInfo == None)
		return false;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	return (WorldInfo.Game != None && WorldInfo.Game.bGameEnded)
		|| (KFGRI != None && KFGRI.bMatchIsOver);
}

simulated final function bool ShouldBlockVampUIForEndMatch()
{
	return bVampUIEndMatchEnabled && IsVampUIEndMatchState();
}

simulated final function CheckVampUIEndMatchHandoff()
{
	local KF2GUIController GUIController;

	if (!ShouldBlockVampUIForEndMatch())
	{
		bVampUIClosedForEndGame = false;
		return;
	}
	if (bVampUIClosedForEndGame)
		return;

	SyncZvampextClientPerkListLevels();
	SyncZvampextStockCurrentPerk();
	PatchZvampextStockTraderPerkInfo();
	bVampUIClosedForEndGame = true;
	GUIController = class'KF2GUIController'.Static.GetGUIController(Self);
	if (GUIController != None)
		GUIController.CloseMenu(None, true);
}

reliable client function ClientSetVampUIEndMatchEnabled(bool bEnabled)
{
	bVampUIEndMatchEnabled = bEnabled;
	ZvampextSettingsSyncRetries = Max(ZvampextSettingsSyncRetries, 4);
	CheckVampUIEndMatchHandoff();
}

reliable client function ClientRefreshZvampextSettings()
{
	ZvampextSettingsSyncRetries = Max(ZvampextSettingsSyncRetries, 12);
	SendServerSettings();
}

reliable server function ZvampextRequestPerkReplication()
{
	if (ActivePerkManager!=None)
	{
		ActivePerkManager.bForceNetUpdate = true;
		bForceNetUpdate = true;
		ActivePerkManager.ZvampextKickClientReplication(true);
	}
}

simulated final function Ext_PerkBase ResolveZvampextClientActivePerk()
{
	local ExtPlayerReplicationInfo EPRI;
	local int i;

	if (ActivePerkManager == None)
	{
		return None;
	}

	if (ActivePerkManager.CurrentPerk != None)
	{
		return ActivePerkManager.CurrentPerk;
	}

	EPRI = ExtPlayerReplicationInfo(PlayerReplicationInfo);
	if (EPRI != None && EPRI.ECurrentPerk != None)
	{
		for (i=0; i<ActivePerkManager.UserPerks.Length; ++i)
		{
			if (ActivePerkManager.UserPerks[i] != None
				&& ActivePerkManager.UserPerks[i].Class == EPRI.ECurrentPerk)
			{
				ActivePerkManager.CurrentPerk = ActivePerkManager.UserPerks[i];
				return ActivePerkManager.CurrentPerk;
			}
		}
	}

	return None;
}

simulated final function SyncZvampextStockCurrentPerk()
{
	local Ext_PerkBase ActivePerk;
	local int PerkIndex;

	ActivePerk = ResolveZvampextClientActivePerk();
	if (ActivePerk == None || ActivePerk.BasePerk == None)
	{
		return;
	}

	PerkIndex = GetZvampextBasePerkIndex(ActivePerk.BasePerk);
	if (PerkIndex >= 0 && PerkIndex < PerkList.Length)
	{
		PerkList[PerkIndex].PerkClass = ActivePerk.BasePerk;
		PerkList[PerkIndex].PerkLevel = ActivePerk.CurrentLevel;
	}
	if (KFPlayerReplicationInfo(PlayerReplicationInfo) != None)
	{
		KFPlayerReplicationInfo(PlayerReplicationInfo).NetPerkIndex = PerkIndex;
		KFPlayerReplicationInfo(PlayerReplicationInfo).CurrentPerkClass = ActivePerk.BasePerk;
		KFPlayerReplicationInfo(PlayerReplicationInfo).bForceNetUpdate = true;
	}
}

simulated final function int GetZvampextActiveTraderPerkIndex()
{
	local Ext_PerkBase ActivePerk;

	ActivePerk = ResolveZvampextClientActivePerk();
	if (ActivePerkManager == None || ActivePerk == None)
	{
		return 0;
	}
	return Max(ActivePerkManager.UserPerks.Find(ActivePerk), 0);
}

simulated final function int GetZvampextTraderFilterIndex()
{
	if (ActivePerkManager == None)
	{
		return 0;
	}

	if (ZvampextClientTraderFilterIndex >= 0
		&& ZvampextClientTraderFilterIndex <= ActivePerkManager.UserPerks.Length)
	{
		return ZvampextClientTraderFilterIndex;
	}

	return GetZvampextActiveTraderPerkIndex();
}

simulated final function bool SetZvampextClientTraderFilterIndex(int FilterIndex)
{
	if (ActivePerkManager == None || FilterIndex < 0 || FilterIndex > ActivePerkManager.UserPerks.Length)
	{
		return false;
	}

	ZvampextClientTraderFilterIndex = FilterIndex;
	return true;
}

simulated final function bool SetZvampextClientTraderPerkIndex(int PerkIndex)
{
	if (ActivePerkManager == None || PerkIndex < 0 || PerkIndex >= ActivePerkManager.UserPerks.Length
		|| ActivePerkManager.UserPerks[PerkIndex] == None)
	{
		return false;
	}

	ZvampextClientTraderFilterIndex = PerkIndex;
	ActivePerkManager.CurrentPerk = ActivePerkManager.UserPerks[PerkIndex];
	SyncZvampextStockCurrentPerk();
	PatchZvampextStockTraderPerkInfo();
	return true;
}

simulated final function RefreshZvampextStockTraderPerkSelection()
{
	local int PerkIndex;

	if (MyGFxManager == None || MyGFxManager.TraderMenu == None)
	{
		return;
	}

	PerkIndex = GetZvampextTraderFilterIndex();
	MyGFxManager.TraderMenu.OnPerkChanged(PerkIndex);
	MyGFxManager.TraderMenu.RefreshItemComponents();
}

simulated final function SyncZvampextClientPerkListLevels()
{
	local int i;
	local int PerkIndex;
	local Ext_PerkBase P;

	if (ActivePerkManager == None)
	{
		return;
	}

	for (i=0; i<ActivePerkManager.UserPerks.Length; ++i)
	{
		P = ActivePerkManager.UserPerks[i];
		if (P == None || P.BasePerk == None)
		{
			continue;
		}

		PerkIndex = GetZvampextBasePerkIndex(P.BasePerk);
		if (PerkIndex >= 0 && PerkIndex < PerkList.Length)
		{
			PerkList[PerkIndex].PerkLevel = P.CurrentLevel;
		}
	}
}

simulated final function PatchZvampextStockTraderPerkInfo()
{
	local Ext_PerkBase ActivePerk;
	local KFGFxTraderContainer_PlayerInfo PlayerInfo;
	local GFxObject PerkIconObject;
	local float XPPercent;
	local string IconPath;

	if (ActivePerkManager == None
		|| MyGFxManager == None || MyGFxManager.TraderMenu == None
		|| MyGFxManager.TraderMenu.PlayerInfoContainer == None)
	{
		return;
	}

	ActivePerk = ResolveZvampextClientActivePerk();
	if (ActivePerk == None)
	{
		return;
	}

	PlayerInfo = MyGFxManager.TraderMenu.PlayerInfoContainer;
	IconPath = ActivePerk.GetPerkIconPath(ActivePerk.CurrentLevel);
	PlayerInfo.SetString("perkName", ActivePerk.PerkName);
	PlayerInfo.SetString("perkIconPath", IconPath);
	PlayerInfo.SetString("perkIconSource", IconPath);
	PlayerInfo.SetString("iconPath", IconPath);
	PlayerInfo.SetString("iconSource", IconPath);
	PlayerInfo.SetString("source", IconPath);
	PerkIconObject = MyGFxManager.CreateObject("Object");
	if (PerkIconObject != None)
	{
		PerkIconObject.SetString("perkIcon", IconPath);
		PerkIconObject.SetString("source", IconPath);
		PerkIconObject.SetString("iconSource", IconPath);
		PlayerInfo.SetObject("perkImageSource", PerkIconObject);
		PlayerInfo.SetObject("perkIconObject", PerkIconObject);
	}
	PlayerInfo.SetInt("perkLevel", ActivePerk.CurrentLevel);
	XPPercent = ActivePerk.GetProgressPercent() * 100.f;
	PlayerInfo.SetInt("xpBarValue", int(XPPercent));
}

function CheckPerk()
{
	if (CurrentPerk != ActivePerkManager)
		CurrentPerk = ActivePerkManager;
	SyncZvampextPerkToStock();
}

reliable client function AddAdminCmd(string S)
{
	local int i,j;

	j = InStr(S,":");
	i = AdminCommands.Length;
	AdminCommands.Length = i+1;
	if (j==-1)
	{
		AdminCommands[i].Cmd = S;
		AdminCommands[i].Info = S;
	}
	else
	{
		AdminCommands[i].Cmd = Left(S,j);
		AdminCommands[i].Info = Mid(S,j+1);
	}
}

reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	Super.ClientSetHUD(newHUDType);
	SendServerSettings();
}

reliable client function ClientSetBonus(SoundCue C, Object FX)
{
	BonusMusic = C;
	BonusFX = FX;
}

simulated final function SendServerSettings()
{
	if (LocalPlayer(Player)!=None)
		ServerSetSettings(bHideKillMsg,bHideDamageMsg,bHideNumberMsg,bNoMonsterPlayer);
}

reliable server function ServerSetSettings(bool bHideKill, bool bHideDmg, bool bHideNum, bool bNoZ)
{
	bClientHideKillMsg = bHideKill;
	bClientHideDamageMsg = bHideDmg;
	bClientHideNumbers = bHideNum;
	bNoDamageTracking = (bHideDmg && bHideNum);
	bClientNoZed = bNoZ;
}

unreliable server function NotifyFixed(byte Mode)
{
	if (Mode==1 && (Pawn==None || (WorldInfo.TimeSeconds-Pawn.SpawnTime)<5.f))
		return;
	OnClientFixed(Self,Mode);
	if (Default.bRenderModes && ExtPlayerReplicationInfo(PlayerReplicationInfo)!=None)
		ExtPlayerReplicationInfo(PlayerReplicationInfo).SetFixedData(Mode);
}

delegate OnClientFixed(ExtPlayerController PC, byte Mode);

reliable client event ReceiveLocalizedMessage(class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if (Message!=class'KFLocalMessage_PlayerKills' && (Message!=class'KFLocalMessage_Game' || (Switch!=KMT_Suicide && Switch!=KMT_Killed)))
		Super.ReceiveLocalizedMessage(Message,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
}

function AddZedKill(class<KFPawn_Monster> MonsterClass, byte Difficulty, class<DamageType> DT, bool bKiller)
{
	// Stats.
	if (ActivePerkManager!=None)
	{
		ActivePerkManager.TotalKills++;
		ActivePerkManager.PRIOwner.RepKills++;
	}
}

unreliable client function ClientPlayCameraShake(CameraShake Shake, optional float Scale=1.f, optional bool bTryForceFeedback, optional ECameraAnimPlaySpace PlaySpace=CAPS_CameraLocal, optional rotator UserPlaySpaceRot)
{
	if (!bNoScreenShake)
		Super.ClientPlayCameraShake(Shake,Scale,bTryForceFeedback,PlaySpace,UserPlaySpaceRot);
}

exec final function AwardXP(int XP, optional byte Mode)
{
	if (WorldInfo.NetMode!=NM_Client && ActivePerkManager!=None)
		ActivePerkManager.EarnedEXP(XP,Mode);
}

/** Perk xp stat */
function OnPlayerXPAdded(INT XP, class<KFPerk> PerkClass)
{
	AwardXP(XP);
}

function AddSmallRadiusKill(byte Difficulty, class<KFPerk> PerkClass)
{
	AwardXP(class'KFPerk_Berserker'.static.GetSmallRadiusKillXP(Difficulty));
}

function AddWeldPoints(int PointsWelded)
{
	AwardXP(PointsWelded,1);
}

function AddHealPoints(int PointsHealed)
{
	AwardXP(PointsHealed,2);
}

function AddShotsHit(int AddedHits)
{
	local KFWeapon W;
	local float T;

	Super.AddShotsHit(AddedHits);
	W = KFWeapon(Pawn.Weapon);
	if (W==None)
	{
		if (LastMisfireTime>WorldInfo.TimeSeconds)
		{
			if (++MisfireCount>15 && (WorldInfo.TimeSeconds-MisfireTimer)>10.f)
				NotifyFixed(8);
			LastMisfireTime = WorldInfo.TimeSeconds+2.f;
			return;
		}
		MisfireCount = 0;
		LastMisfireTime = WorldInfo.TimeSeconds+2.f;
		MisfireTimer = WorldInfo.TimeSeconds;
		return;
	}
	if (!W.HasAmmo(W.CurrentFireMode))
	{
		if (LastMisfireTime>WorldInfo.TimeSeconds)
		{
			if (++MisfireCount>15 && (WorldInfo.TimeSeconds-MisfireTimer)>10.f)
				NotifyFixed(16);
			LastMisfireTime = WorldInfo.TimeSeconds+2.f;
			return;
		}
		MisfireCount = 0;
		LastMisfireTime = WorldInfo.TimeSeconds+2.f;
		MisfireTimer = WorldInfo.TimeSeconds;
		return;
	}
	T = W.GetFireInterval(W.CurrentFireMode);
	ActivePerkManager.ModifyRateOfFire(T,W);
	if ((WorldInfo.TimeSeconds-LastFireTime)<(T*0.5) || !W.IsFiring())
	{
		if ((WorldInfo.TimeSeconds-LastFireTime)>4.f)
			MisrateCounter = 0;
		LastFireTime = WorldInfo.TimeSeconds;
		if (MisrateCounter<5)
		{
			++MisrateCounter;
			return;
		}
		if (LastMisfireTime>WorldInfo.TimeSeconds)
		{
			if (++MisfireCount>15 && (WorldInfo.TimeSeconds-MisfireTimer)>10.f)
				NotifyFixed(2);
			LastMisfireTime = WorldInfo.TimeSeconds+1.f;
			return;
		}
		MisfireCount = 0;
		LastMisfireTime = WorldInfo.TimeSeconds+1.f;
		MisfireTimer = WorldInfo.TimeSeconds;
	}
	else MisrateCounter = 0;
}

// Message of the day.
Delegate OnSetMOTD(ExtPlayerController PC, string S);
reliable client function ReceiveServerMOTD(string S, bool bFinal)
{
	ServerMOTD $= S;
	bMOTDReceived = bFinal;
}

reliable server function ServerSetMOTD(string S, bool bFinal)
{
	PendingMOTD $= S;
	if (bFinal && PendingMOTD!="")
	{
		OnSetMOTD(Self,PendingMOTD);
		PendingMOTD = "";
	}
}

// TESTING:
reliable server function ServerItemDropGet(string Item)
{
	if (DropCount>5 || Len(Item)>100)
		return;
	++DropCount;
	WorldInfo.Game.Broadcast(Self,PlayerReplicationInfo.GetHumanReadableName()@GotItemText@Item);
}

reliable client function ReceiveLevelUp(Ext_PerkBase Perk, int NewLevel)
{
	if (Perk!=None)
		MyGFxHUD.LevelUpNotificationWidget.ShowAchievementNotification(class'KFGFxWidget_LevelUpNotification'.Default.LevelUpString, Perk.PerkName, class'KFGFxWidget_LevelUpNotification'.Default.TierUnlockedString, Perk.GetPerkIconPath(NewLevel), false, NewLevel);
}

reliable client function ReceiveKillMessage(class<Pawn> Victim, optional bool bGlobal, optional PlayerReplicationInfo KillerPRI)
{
	if (bHideKillMsg || (bGlobal && KillerPRI==None))
		return;
	if (bUseKF2KillMessages)
	{
		if (MyGFxHUD != none)
		{
			ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX((bGlobal ? KillerPRI : None), None, ,false, Victim);
		}
	}
	else if (KFExtendedHUD(myHUD)!=None && Victim!=None)
		KFExtendedHUD(myHUD).AddKillMessage(Victim,1,KillerPRI,byte(bGlobal));
}

unreliable client function ReceiveDamageMessage(class<Pawn> Victim, int Damage)
{
	if (!bHideDamageMsg && KFExtendedHUD(myHUD)!=None && Victim!=None)
		KFExtendedHUD(myHUD).AddKillMessage(Victim,Damage,None,2);
}

unreliable client function ClientNumberMsg(int Count, vector Pos, EDmgMsgType Type)
{
	if (!bHideNumberMsg && KFExtendedHUD(myHUD)!=None)
		KFExtendedHUD(myHUD).AddNumberMsg(Count,Pos,Type);
}

reliable client event TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional float MsgLifeTime )
{
	local string OriginalMessage;

	OriginalMessage = S;
	//if (((Type == 'Say') || (Type == 'TeamSay')) && (PRI != None))
	//	SpeakTTS(S, PRI); <- KF built without TTS...

	// since this is on the client, we can assume that if Player exists, it is a LocalPlayer
	if (Player!=None)
	{
		if (((Type == 'Say') || (Type == 'TeamSay')) && (PRI != None))
			S = PRI.GetHumanReadableName()$": "$S;
		LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("("$Type$") "$S);
	}

	if (MyGFxManager != none && MyGFxManager.PartyWidget != none)
	{
		if (!MyGFxManager.PartyWidget.ReceiveMessage(S))  //Fails if message is for updating perks in a steam lobby
		{
			if (Type != 'Say' && Type != 'TeamSay')
				return;
		}
	}

	if (MyGFxHUD != none && MyGFxHUD.HudChatBox != none)
	{
		switch (Type)
		{
		case 'Log':
			break; // Console only message.
		case 'Music':
			MyGFxHUD.MusicNotification.ShowSongInfo(S);
			break;
		case 'Event':
			MyGFxHUD.HudChatBox.AddChatMessage(S, class 'KFLocalMessage'.default.DefaultColor);
			break;
		case 'DeathMessage':
			//MyGFxHUD.HudChatBox.AddChatMessage(S, "FF0000"); // Console message only.
			break;
		case 'Say':
		case 'TeamSay':
			if (ExtPlayerReplicationInfo(PRI)!=None && ExtPlayerReplicationInfo(PRI).ShowAdminName())
				MyGFxHUD.HudChatBox.AddChatMessage("("$ExtPlayerReplicationInfo(PRI).GetAdminNameAbr()$")"$S, ExtPlayerReplicationInfo(PRI).GetAdminColor());
			else MyGFxHUD.HudChatBox.AddChatMessage(S, "64FE2E");
			break;
		case 'Priority':
			MyGFxHUD.HudChatBox.AddChatMessage(S, class 'KFLocalMessage'.default.PriorityColor);
			break;
		case 'CriticalEvent':
			PopScreenMsg(S); // HIGH|Low|Time
			break;
		case 'LowCriticalEvent':
			MyGFxHUD.ShowNonCriticalMessage(S);
			break;
		default:
			MyGFxHUD.HudChatBox.AddChatMessage(class'KFLocalMessage'.default.SystemString@S, class 'KFLocalMessage'.default.EventColor);
		}
	}
	else Super.TeamMessage(PRI,OriginalMessage,Type,MsgLifeTime);
}

final function PopScreenMsg(string S)
{
	local int i;
	local string L;
	local float T;

	T = 4.f;

	// Get lower part.
	i = InStr(S,"|");
	if (i!=-1)
	{
		L = Mid(S,i+1);
		S = Left(S,i);

		// Get time.
		i = InStr(L,"|");
		if (i!=-1)
		{
			T = float(Mid(L,i+1));
			L = Left(L,i);
		}
	}
	MyGFxHUD.DisplayPriorityMessage(S,L,T);
}

reliable client function ClientKillMessage(class<DamageType> DamType, PlayerReplicationInfo Victim, PlayerReplicationInfo KillerPRI, optional class<Pawn> KillerPawn)
{
	local string Msg,S;
	local bool bFF;

	if (Player==None || Victim==None)
		return;

	if (bUseKF2DeathMessages && MyGFxHUD!=None)
	{
		if (Victim==KillerPRI || (KillerPRI==None && KillerPawn==None)) // Suicide
			ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX(None, Victim, ,true);
		else ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX(KillerPRI, Victim, ,true, KillerPawn);
	}
	if (Victim==KillerPRI || (KillerPRI==None && KillerPawn==None)) // Suicide
	{
		if (Victim.GetTeamNum()==0)
		{
			Msg = ParseSuicideMsg(Chr(6)$"O"$Victim.GetHumanReadableName(),DamType);
			class'KFMusicStingerHelper'.static.PlayPlayerDiedStinger(Self);
		}
		else Msg = ParseSuicideMsg(Chr(6)$"K"$Victim.GetHumanReadableName(),DamType);
	}
	else
	{
		if (KillerPRI!=None && Victim.Team!=None && Victim.Team==KillerPRI.Team) // Team-kill
		{
			bFF = true;
			S = KillerPRI.GetHumanReadableName();
			class'KFMusicStingerHelper'.static.PlayTeammateDeathStinger(Self);
		}
		else // Killed by monster.
		{
			bFF = false;
			if (KillerPRI!=None)
			{
				S = KillerPRI.GetHumanReadableName();
			}
			else
			{
				S = class'KFExtendedHUD'.Static.GetNameOf(KillerPawn);
				if (class<KFPawn_Monster>(KillerPawn)!=None && class<KFPawn_Monster>(KillerPawn).Default.MinSpawnSquadSizeType==EST_Boss) // Boss type.
					S = "the "$S;
				else S = class'KFExtendedHUD'.Static.GetNameArticle(S)@S;
			}
			class'KFMusicStingerHelper'.static.PlayZedKillHumanStinger(Self);
		}
		Msg = ParseKillMsg(Victim.GetHumanReadableName(),S,bFF,DamType);
	}
	S = Class'KFExtendedHUD'.Static.StripMsgColors(Msg);
	if (!bUseKF2DeathMessages)
		KFExtendedHUD(myHUD).AddDeathMessage(Msg,S);
	ClientMessage(S,'DeathMessage');
}

reliable client function ClientZedKillMessage(class<DamageType> DamType, string Victim, optional PlayerReplicationInfo KillerPRI, optional class<Pawn> KillerPawn, optional bool bFFKill)
{
	local string Msg,S;

	if (Player==None)
		return;
	if (bUseKF2DeathMessages && MyGFxHUD!=None)
	{
		if (KillerPRI==None && KillerPawn==None) // Suicide
			ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX(None, None, Victim, true);
		else ExtMoviePlayer_HUD(MyGFxHUD).ShowKillMessageX(KillerPRI, None, Victim, true, KillerPawn);
	}
	if (KillerPRI==None && KillerPawn==None) // Suicide
	{
		Msg = ParseSuicideMsg(Chr(6)$"O"$Victim,DamType);
	}
	else
	{
		if (KillerPRI!=None) // Team-kill
		{
			S = KillerPRI.GetHumanReadableName();
		}
		else // Killed by monster.
		{
			S = class'KFExtendedHUD'.Static.GetNameOf(KillerPawn);
			if (class<KFPawn_Monster>(KillerPawn)!=None && class<KFPawn_Monster>(KillerPawn).Default.MinSpawnSquadSizeType==EST_Boss) // Boss type.
				S = "the "$S;
			else S = class'KFExtendedHUD'.Static.GetNameArticle(S)@S;
		}
		Msg = ParseKillMsg(Victim,S,bFFKill,DamType);
	}
	S = Class'KFExtendedHUD'.Static.StripMsgColors(Msg);
	if (!bUseKF2DeathMessages)
		KFExtendedHUD(myHUD).AddDeathMessage(Msg,S);
	ClientMessage(S,'DeathMessage');
}

simulated final function string ParseSuicideMsg(string Victim, class<DamageType> DamType)
{
	local string S;

	S = string(DamType.Name);
	if (Left(S,15)~="KFDT_Ballistic_")
	{
		S = Mid(S,15); // Weapon name.
		return Victim$Chr(6)$"M"@KilledHimselfWith@S;
	}
	else if (class<KFDT_Fire>(DamType)!=None)
		return Victim$Chr(6)$"M"@WasBurnedToDeath;
	else if (class<KFDT_Explosive>(DamType)!=None)
		return Victim$Chr(6)$"M"@WasBlownIntoPeaces;
	return Victim$Chr(6)$"M"@HadSuddenHeartAttack;
}

simulated final function string ParseKillMsg(string Victim, string Killer, bool bFF, class<DamageType> DamType)
{
	local string T,S;

	T = (bFF ? "O" : "K");
	S = string(DamType.Name);
	if (Left(S,15)~="KFDT_Ballistic_")
	{
		S = Mid(S,15); // Weapon name.
		return Chr(6)$"O"$Victim$Chr(6)$"M"@WasKilledBy@Chr(6)$T$Killer$Chr(6)$"M's "$S;
	}
	else if (class<KFDT_Fire>(DamType)!=None)
		return Chr(6)$"O"$Victim$Chr(6)$"M"@WasIncineratedBy@Chr(6)$T$Killer;
	else if (class<KFDT_Explosive>(DamType)!=None)
		return Chr(6)$"O"$Victim$Chr(6)$"M"@WasBlownUpBy@Chr(6)$T$Killer;
	return Chr(6)$"O"$Victim$Chr(6)$"M"@WasKilledBy@Chr(6)$T$Killer;
}

reliable server function ServerCamera(name NewMode)
{
	// <- REMOVED CAMERA LOGGING (PlayerController)
	if (NewMode == '1st')
		NewMode = 'FirstPerson';
	else if (NewMode == '3rd')
		NewMode = 'ThirdPerson';
	SetCameraMode(NewMode);
}

exec function Camera(name NewMode)
{
	ServerCamera(PlayerCamera.CameraStyle=='FirstPerson' ? 'ThirdPerson' : 'FirstPerson');
}

simulated final function ToggleFPBody(bool bEnable)
{
	bShowFPLegs = bEnable;
	Class'ExtPlayerController'.Default.bShowFPLegs = bEnable;

	if (ExtHumanPawn(Pawn)!=None)
		ExtHumanPawn(Pawn).UpdateFPLegs();
}

/*exec function KickBan(string S)
{
	if (WorldInfo.Game!=None)
		WorldInfo.Game.KickBan(S);
}*/
exec function Kick(string S)
{
	if (WorldInfo.Game!=None)
		WorldInfo.Game.Kick(S);
}

reliable server function SkipLobby();

Delegate OnChangePerk(ExtPlayerController PC, class<Ext_PerkBase> NewPerk);

reliable server function SwitchToPerk(class<Ext_PerkBase> PerkClass)
{
	if (PerkClass!=None)
		OnChangePerk(Self,PerkClass);
}

Delegate OnBoughtStats(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, int iStat, int Amount);

reliable server function BuyPerkStat(class<Ext_PerkBase> PerkClass, int iStat, int Amount)
{
	if (PerkClass!=None && Amount>0 && iStat>=0)
		OnBoughtStats(Self,PerkClass,iStat,Amount);
}

simulated final function Ext_PerkBase FindClientPerk(class<Ext_PerkBase> PerkClass)
{
	local int i;

	if (ActivePerkManager==None || PerkClass==None)
		return None;

	for (i=0; i<ActivePerkManager.UserPerks.Length; ++i)
		if (ActivePerkManager.UserPerks[i]!=None && ActivePerkManager.UserPerks[i].Class==PerkClass)
			return ActivePerkManager.UserPerks[i];
	return None;
}

simulated final function int FindPendingStatBuy(class<Ext_PerkBase> PerkClass, int iStat)
{
	local int i;

	for (i=0; i<PendingStatBuys.Length; ++i)
		if (PendingStatBuys[i].PerkClass==PerkClass && PendingStatBuys[i].StatIndex==iStat)
			return i;
	return -1;
}

simulated final function int GetPendingStatBuyAmount(class<Ext_PerkBase> PerkClass, int iStat)
{
	local int i;

	i = FindPendingStatBuy(PerkClass,iStat);
	if (i>=0)
		return PendingStatBuys[i].Amount;
	return 0;
}

simulated final function int GetPendingStatBuyCost(class<Ext_PerkBase> PerkClass)
{
	local Ext_PerkBase P;
	local int i,Cost;

	P = FindClientPerk(PerkClass);
	if (P==None)
		return 0;

	for (i=0; i<PendingStatBuys.Length; ++i)
	{
		if (PendingStatBuys[i].PerkClass!=PerkClass)
			continue;
		if (PendingStatBuys[i].StatIndex<0 || PendingStatBuys[i].StatIndex>=P.PerkStats.Length)
			continue;
		Cost += PendingStatBuys[i].Amount * Max(P.PerkStats[PendingStatBuys[i].StatIndex].CostPerValue,1);
	}
	return Cost;
}

simulated final function int GetPendingStatBuyCount(class<Ext_PerkBase> PerkClass)
{
	local int i,Count;

	for (i=0; i<PendingStatBuys.Length; ++i)
		if (PendingStatBuys[i].PerkClass==PerkClass)
			Count += PendingStatBuys[i].Amount;
	return Count;
}

simulated final function QueuePerkStatBuy(class<Ext_PerkBase> PerkClass, int iStat, int Amount, optional bool bNotify)
{
	local Ext_PerkBase P;
	local int PendingIndex,PendingAmount,PendingCost,CostPerValue,AvailableSP,RemainingValue,SafeAmount;

	P = FindClientPerk(PerkClass);
	if (P==None || iStat<0 || iStat>=P.PerkStats.Length || Amount<=0)
		return;

	CostPerValue = Max(P.PerkStats[iStat].CostPerValue,1);
	PendingAmount = GetPendingStatBuyAmount(PerkClass,iStat);
	PendingCost = GetPendingStatBuyCost(PerkClass);
	AvailableSP = Max(P.CurrentSP-PendingCost,0);
	RemainingValue = Max(P.PerkStats[iStat].MaxValue-P.PerkStats[iStat].CurrentValue-PendingAmount,0);
	SafeAmount = Min(Amount,RemainingValue);
	SafeAmount = Min(SafeAmount,AvailableSP/CostPerValue);
	if (SafeAmount<=0)
	{
		ClientMessage("[Zvamp] No SP available to queue for "$string(P.PerkStats[iStat].StatType)$".",'Priority');
		return;
	}

	PendingIndex = FindPendingStatBuy(PerkClass,iStat);
	if (PendingIndex<0)
	{
		PendingIndex = PendingStatBuys.Length;
		PendingStatBuys.Length = PendingIndex+1;
		PendingStatBuys[PendingIndex].PerkClass = PerkClass;
		PendingStatBuys[PendingIndex].StatIndex = iStat;
		PendingStatBuys[PendingIndex].Amount = SafeAmount;
	}
	else PendingStatBuys[PendingIndex].Amount += SafeAmount;

	if (bNotify)
		ClientMessage("[Zvamp] Queued "$SafeAmount$" "$string(P.PerkStats[iStat].StatType)$" point(s). Press COMMIT SP to apply.",'Priority');
}

simulated final function CommitPendingStatBuys(class<Ext_PerkBase> PerkClass)
{
	local int i,Committed;

	for (i=0; i<PendingStatBuys.Length; ++i)
	{
		if (PendingStatBuys[i].PerkClass!=PerkClass)
			continue;
		if (PendingStatBuys[i].Amount<=0)
			continue;
		BuyPerkStat(PendingStatBuys[i].PerkClass,PendingStatBuys[i].StatIndex,PendingStatBuys[i].Amount);
		Committed += PendingStatBuys[i].Amount;
	}

	ClearPendingStatBuys(PerkClass);
	if (Committed>0)
		ClientMessage("[Zvamp] Committed "$Committed$" queued SP point(s).",'Priority');
	else ClientMessage("[Zvamp] No queued SP to commit.",'Priority');
}

simulated final function ClearPendingStatBuys(class<Ext_PerkBase> PerkClass)
{
	local int i;

	for (i=PendingStatBuys.Length-1; i>=0; --i)
		if (PendingStatBuys[i].PerkClass==PerkClass)
			PendingStatBuys.Remove(i,1);
}

simulated final function CancelPendingStatBuys(class<Ext_PerkBase> PerkClass, optional bool bNotify)
{
	local int PendingCost, PendingCount;

	PendingCost = GetPendingStatBuyCost(PerkClass);
	PendingCount = GetPendingStatBuyCount(PerkClass);
	ClearPendingStatBuys(PerkClass);
	if (bNotify && (PendingCost>0 || PendingCount>0))
		ClientMessage("[Zvamp] Cancelled "$PendingCount$" queued SP point(s), returned "$PendingCost$" SP.",'Priority');
}

Delegate OnBoughtTrait(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait);

reliable server function BoughtTrait(class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait)
{
	if (PerkClass!=None && Trait!=None)
		OnBoughtTrait(Self,PerkClass,Trait);
}

Delegate OnPerkReset(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, bool bPrestige);

reliable server function ServerResetPerk(class<Ext_PerkBase> PerkClass, bool bPrestige)
{
	if (PerkClass!=None)
		OnPerkReset(Self,PerkClass,bPrestige);
}

reliable server function ServerResetCurrentClassYesImCertain()
{
	if (ActivePerkManager==None || ActivePerkManager.CurrentPerk==None)
	{
		ClientMessage("[Zvamp] Class reset failed: current perk is not ready.",'Priority');
		return;
	}

	ClientClearPendingStatBuys(ActivePerkManager.CurrentPerk.Class);
	OnPerkReset(Self,ActivePerkManager.CurrentPerk.Class,false);
	ClientMessage("[Zvamp] Reset requested for "$ActivePerkManager.CurrentPerk.PerkName$".",'Priority');
}

reliable client function ClientClearPendingStatBuys(class<Ext_PerkBase> PerkClass)
{
	ClearPendingStatBuys(PerkClass);
}

Delegate OnAdminHandle(ExtPlayerController PC, int PlayerID, int Action);
Delegate OnAdminRevampAction(ExtPlayerController PC, int Action);
Delegate OnAdminSetTraderGuard(ExtPlayerController PC, bool bEnabled, bool bBlockSkip, bool bPublicOpenTrader);
Delegate OnAdminSetPickupOverrides(ExtPlayerController PC, bool bGrenadeDamage, float GrenadeDamageValue, bool bGrenadeRadius, float GrenadeRadiusValue, bool bAmmoPickup, float AmmoPickupValue, bool bItemPickup, float ItemPickupValue, bool bArmorPickup, float ArmorPickupValue);
Delegate OnAdminFastForwardTrader(ExtPlayerController PC);
Delegate OnAdminOpenTrader(ExtPlayerController PC);
Delegate OnPublicOpenTrader(ExtPlayerController PC);
Delegate OnRefreshNewItems(ExtPlayerController PC);
Delegate OnAdminGiveDosh(ExtPlayerController PC, int DoshAmount);
Delegate OnAdminSetDoshThrowAmount(ExtPlayerController PC, int NewAmount);
Delegate OnAdminProgressWave(ExtPlayerController PC, int WaveCount);
Delegate OnAdminBuildID(ExtPlayerController PC);
Delegate OnAdminSetAutoMessage(ExtPlayerController PC, bool bEnabled, int IntervalSeconds, string MessageText, string MessageColor);
Delegate OnPlayerProgressWaveVoteCall(ExtPlayerController PC, int WaveCount);
Delegate OnPlayerProgressWaveVoteAnswer(ExtPlayerController PC, bool bAccept);
Delegate OnPlayerNextMapVoteAnswer(ExtPlayerController PC, bool bNextMap);

reliable server function AdminRPGHandle(int PlayerID, int Action)
{
	OnAdminHandle(Self,PlayerID,Action);
}

reliable server function AdminRevampAction(int Action)
{
	OnAdminRevampAction(Self,Action);
}

reliable server function AdminSetTraderGuard(bool bEnabled, bool bBlockSkip, bool bPublicOpenTrader)
{
	OnAdminSetTraderGuard(Self,bEnabled,bBlockSkip,bPublicOpenTrader);
}

reliable server function AdminSetPickupOverrides(bool bGrenadeDamage, float GrenadeDamageValue, bool bGrenadeRadius, float GrenadeRadiusValue, bool bAmmoPickup, float AmmoPickupValue, bool bItemPickup, float ItemPickupValue, bool bArmorPickup, float ArmorPickupValue)
{
	OnAdminSetPickupOverrides(Self,bGrenadeDamage,GrenadeDamageValue,bGrenadeRadius,GrenadeRadiusValue,bAmmoPickup,AmmoPickupValue,bItemPickup,ItemPickupValue,bArmorPickup,ArmorPickupValue);
}

reliable server function RevampAdminFastForwardTrader()
{
	OnAdminFastForwardTrader(Self);
}

reliable server function RevampAdminOpenTrader()
{
	OnAdminOpenTrader(Self);
}

reliable server function RevampPublicOpenTrader()
{
	OnPublicOpenTrader(Self);
}

reliable server function AdminGiveDosh(int DoshAmount)
{
	OnAdminGiveDosh(Self,DoshAmount);
}

reliable server function AdminSetDoshThrowAmount(int NewAmount)
{
	OnAdminSetDoshThrowAmount(Self,NewAmount);
}

reliable server function PlayerSetDoshThrowAmount(int NewAmount)
{
	local ExtInventoryManager IM;
	local int SafeAmount;

	SafeAmount = Clamp(NewAmount, 1, 1000000);
	PlayerDoshThrowAmount = SafeAmount;
	if (Pawn != None)
		IM = ExtInventoryManager(Pawn.InvManager);
	if (IM == None)
	{
		ClientMessage("[Zvamp] DoshThrowAmount will apply after you spawn.", 'Priority');
		return;
	}

	IM.SetDoshThrowAmount(SafeAmount);
	ClientMessage("[Zvamp] DoshThrowAmount set to "$SafeAmount$".", 'Priority');
	`log("[Zvamp] player "$PlayerReplicationInfo.PlayerName$" set DoshThrowAmount to "$SafeAmount);
}

function ApplyPlayerDoshThrowAmount()
{
	local ExtInventoryManager IM;

	if (PlayerDoshThrowAmount <= 0 || Pawn == None)
		return;

	IM = ExtInventoryManager(Pawn.InvManager);
	if (IM != None)
		IM.SetDoshThrowAmount(PlayerDoshThrowAmount);
}

reliable server function AdminProgressWave(int WaveCount)
{
	OnAdminProgressWave(Self,WaveCount);
}

reliable server function PlayerProgressWaveVoteCall(int WaveCount)
{
	OnPlayerProgressWaveVoteCall(Self,WaveCount);
}

reliable server function PlayerProgressWaveVoteAnswer(bool bAccept)
{
	OnPlayerProgressWaveVoteAnswer(Self,bAccept);
}

reliable server function PlayerNextMapVoteAnswer(bool bNextMap)
{
	OnPlayerNextMapVoteAnswer(Self,bNextMap);
}

reliable server function AdminBuildID()
{
	OnAdminBuildID(Self);
}

reliable server function AdminSetAutoMessage(bool bEnabled, int IntervalSeconds, string MessageText, string MessageColor)
{
	OnAdminSetAutoMessage(Self,bEnabled,IntervalSeconds,MessageText,MessageColor);
}

reliable client function ClientZvampextAutoMessage(string MessageText, string MessageColor)
{
	if (MyGFxHUD!=None && MyGFxHUD.HudChatBox!=None)
		MyGFxHUD.HudChatBox.AddChatMessage(MessageText,MessageColor);
	else ClientMessage(MessageText,'Event');
}

reliable client function ClientOpenProgressWaveVote(string CallerName, int WaveCount, int Seconds)
{
	local UI_PlayerProgressWaveVote Menu;

	Menu = UI_PlayerProgressWaveVote(class'KF2GUIController'.Static.GetGUIController(Self).OpenMenu(class'UI_PlayerProgressWaveVote'));
	if (Menu!=None)
		Menu.InitVote(CallerName,WaveCount,Seconds);
}

reliable client function ClientOpenNextMapVote(int WaveNum, int Seconds)
{
	local UI_PlayerNextMapVote Menu;

	Menu = UI_PlayerNextMapVote(class'KF2GUIController'.Static.GetGUIController(Self).OpenMenu(class'UI_PlayerNextMapVote'));
	if (Menu!=None)
		Menu.InitVote(WaveNum,Seconds);
}

simulated final function bool ShouldKeepChatDuringBossCinematic()
{
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	return bCinematicMode
		&& ((PlayerCamera!=None && PlayerCamera.CameraStyle=='Boss')
			|| IsBossCameraMode()
			|| GetBoss()!=None
			|| (KFGRI!=None && KFGRI.IsBossWave()));
}

reliable client function ClientSetIgnoreButtons(bool bAffectsButtons)
{
	local KFGFxHudWrapper GFxHUDWrapper;
	local bool bKeepChat;

	bKeepChat = bAffectsButtons && ShouldKeepChatDuringBossCinematic();
	if (bAffectsButtons && MyGFxManager!=None && !bKeepChat)
		MyGFxManager.CloseMenus();

	GFxHUDWrapper = KFGFxHudWrapper(myHUD);
	if (GFxHUDWrapper!=None && GFxHUDWrapper.HudMovie!=None)
	{
		if (bAffectsButtons && !bKeepChat && GFxHUDWrapper.HudMovie.HudChatBox!=None)
			GFxHUDWrapper.HudMovie.HudChatBox.ClearAndCloseChat();

		GFxHUDWrapper.HudMovie.EatMyInput(bAffectsButtons && !bKeepChat);
	}
}

reliable client function ClientSetRevampTraderGuard(bool bEnabled, bool bBlockSkip, bool bPublicOpenTrader)
{
	bRevampTraderGuardEnabled = bEnabled;
	bRevampTraderGuardBlockSkip = bBlockSkip;
	bRevampTraderGuardPublicOpenTrader = bPublicOpenTrader;
}

reliable client function ClientSetAdminPickupOverrides(bool bGrenadeDamage, float GrenadeDamageValue, bool bGrenadeRadius, float GrenadeRadiusValue, bool bAmmoPickup, float AmmoPickupValue, bool bItemPickup, float ItemPickupValue, bool bArmorPickup, float ArmorPickupValue)
{
	bAdminGrenadeDamage = bGrenadeDamage;
	AdminGrenadeDamageValue = GrenadeDamageValue;
	bAdminGrenadeRadius = bGrenadeRadius;
	AdminGrenadeRadiusValue = GrenadeRadiusValue;
	bAdminAmmoPickup = bAmmoPickup;
	AdminAmmoPickupValue = AmmoPickupValue;
	bAdminItemPickup = bItemPickup;
	AdminItemPickupValue = ItemPickupValue;
	bAdminArmorPickup = bArmorPickup;
	AdminArmorPickupValue = ArmorPickupValue;
}

reliable client function ClientSetZvampCamera(bool bEnabled, bool bDisableShakes, bool bDisableSprintFOV, bool bDisableRinging, bool bDisableAnims, float ZedReduction)
{
	bZvampCameraEnabled = bEnabled;
	bZvampDisableCamShakes = bDisableShakes;
	bZvampDisableSprintFOVChange = bDisableSprintFOV;
	bZvampDisableEarsRinging = bDisableRinging;
	bZvampDisableCameraAnims = bDisableAnims;
	ZvampZedTimeEffectReduction = FClamp(ZedReduction,0.f,1.f);
}

simulated function ApplyZvampCameraSettings()
{
	local MaterialInstanceConstant WorldMIC;
	local float MaxEffect;

	if (!bZvampCameraEnabled)
		return;

	if (bZvampDisableCamShakes && PlayerCamera!=None && PlayerCamera.CameraShakeCamMod!=None)
		PlayerCamera.CameraShakeCamMod.DisableModifier(true);

	if (bZvampDisableEarsRinging)
		EarsRingingPlayEvent = EarsRingingStopEvent;

	MaxEffect = 1.f - FClamp(ZvampZedTimeEffectReduction,0.f,1.f);
	if (TargetZEDTimeEffectIntensity > MaxEffect)
		TargetZEDTimeEffectIntensity = MaxEffect;
	if (CurrentZEDTimeEffectIntensity > MaxEffect)
	{
		CurrentZEDTimeEffectIntensity = MaxEffect;
		ZEDTimeEffectInterpTimeRemaining = 0.f;
		if (GameplayPostProcessEffectMIC!=None)
			GameplayPostProcessEffectMIC.SetScalarParameterValue(EffectZedTimeParamName,CurrentZEDTimeEffectIntensity);
		foreach WorldInfo.ZedTimeMICs(WorldMIC)
			if (WorldMIC!=None)
				WorldMIC.SetScalarParameterValue(EffectZedTimeParamName,CurrentZEDTimeEffectIntensity);
	}

	if (Pawn!=None && KFWeapon(Pawn.Weapon)!=None)
		ApplyZvampCameraWeaponSettings(KFWeapon(Pawn.Weapon));
}

simulated function ApplyZvampCameraWeaponSettings(KFWeapon W)
{
	local AnimSet WeaponAnimSet;
	local AnimSequence WeaponAnimSequence;
	local KFAnimNotify_CameraAnim WeaponAnimNotify;
	local int i;

	if (W==None)
		return;

	if (bZvampDisableSprintFOVChange)
		W.PlayerSprintFOV = DefaultFOV;

	if (!bZvampDisableCameraAnims || W.MySkelMesh==None)
		return;

	foreach W.MySkelMesh.AnimSets(WeaponAnimSet)
	{
		foreach WeaponAnimSet.Sequences(WeaponAnimSequence)
		{
			for (i=0; i<WeaponAnimSequence.Notifies.Length; ++i)
			{
				WeaponAnimNotify = KFAnimNotify_CameraAnim(WeaponAnimSequence.Notifies[i].Notify);
				if (WeaponAnimNotify!=None)
					WeaponAnimNotify.CameraAnimScale = 0.f;
			}
		}
	}
}

reliable client function ClientSetSpawnedPerkUILayout(string Layout)
{
	SpawnedPerkUILayout = Layout;
}

reliable client function ClientClearSpawnedPerkUILayout()
{
	SpawnedPerkUILayout = "";
}

reliable client function ClientAddSpawnedPerkUILayoutChunk(string LayoutChunk)
{
	SpawnedPerkUILayout $= LayoutChunk;
}

reliable client function ClientClearMidGameMenuLayout()
{
	MidGameMenuLayout = "";
}

reliable client function ClientAddMidGameMenuLayoutChunk(string LayoutChunk)
{
	MidGameMenuLayout $= LayoutChunk;
}

reliable client function ClientClearZvampextTraderItems()
{
	ZvampextClientTraderItems.Length = 0;
}

reliable client function ClientAddZvampextTraderItemPath(string WeaponPath)
{
	ZvampextClientTraderItems.AddItem(WeaponPath);
}

reliable client function ClientApplyZvampextTraderItems()
{
	ApplyZvampextClientTraderItems();
}

simulated function ApplyZvampextClientTraderItems()
{
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TraderItems;
	local int i, Added;
	local STraderItem NewItem;
	local int StorePrice;
	local bool bChanged;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None || KFGRI.TraderItems == None)
	{
		SetTimer(1.f, false, 'ApplyZvampextClientTraderItems');
		return;
	}

	TraderItems = KFGRI.TraderItems;
	for (i = 0; i < ZvampextClientTraderItems.Length; ++i)
	{
		if (!BuildZvampextClientTraderItem(ZvampextClientTraderItems[i], NewItem))
		{
			`log("[Zvamp] client skipped custom trader item, could not load weapon def/class: "$ZvampextClientTraderItems[i]);
			continue;
		}
		if (TraderItems.SaleItems.Find('WeaponDef', NewItem.WeaponDef) != INDEX_NONE
			|| TraderItems.SaleItems.Find('ClassName', NewItem.ClassName) != INDEX_NONE)
		{
			StorePrice = GetClientStorePrice(ZvampextClientTraderItems[i]);
			if (StorePrice >= 0)
			{
				ApplyZvampextClientStorePriceToTraderItems(TraderItems, NewItem, StorePrice);
				bChanged = true;
			}
			continue;
		}

		NewItem.ItemID = GetNextZvampextClientTraderItemID(TraderItems);
		TraderItems.SaleItems.AddItem(NewItem);
		++Added;
		LogZvampextClientTraderItem("client added custom trader item: "$ZvampextClientTraderItems[i], NewItem);
	}

	if (Added > 0 || bChanged)
	{
		TraderItems.SetItemsInfo(TraderItems.SaleItems);
		KFGRI.TraderItems = TraderItems;
	}
}

simulated final function int GetClientStorePrice(string WeaponDefPath)
{
	local int PriceSplit;

	PriceSplit = InStr(WeaponDefPath, "|");
	if (PriceSplit == INDEX_NONE)
	{
		return -1;
	}

	return int(ZvampTrimCommand(Mid(WeaponDefPath, PriceSplit + 1)));
}

simulated final function int GetNextZvampextClientTraderItemID(KFGFxObject_TraderItems TraderItems)
{
	local int ItemID;

	ItemID = TraderItems.SaleItems.Length;
	while (TraderItems.SaleItems.Find('ItemID', ItemID) != INDEX_NONE)
	{
		++ItemID;
	}

	return ItemID;
}

simulated final function bool BuildZvampextClientTraderItem(string WeaponDefPath, out STraderItem NewItem)
{
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> WeaponClass;
	local class<KFWeap_DualBase> DualClass;
	local array<STraderItemWeaponStats> WeaponStats;
	local string CandidateDefPath;
	local int DotPos;
	local int PriceSplit;
	local int StorePrice;
	local string PackageName;
	local string ClassName;

	WeaponDefPath = ZvampTrimCommand(WeaponDefPath);
	StorePrice = -1;
	PriceSplit = InStr(WeaponDefPath, "|");
	if (PriceSplit != INDEX_NONE)
	{
		StorePrice = int(ZvampTrimCommand(Mid(WeaponDefPath, PriceSplit + 1)));
		WeaponDefPath = ZvampTrimCommand(Left(WeaponDefPath, PriceSplit));
	}
	if (WeaponDefPath == "")
	{
		return false;
	}

	WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(WeaponDefPath, class'Class', true));
	if (WeaponDef != None && WeaponDef.default.WeaponClassPath != "")
	{
		WeaponClass = class<KFWeapon>(DynamicLoadObject(WeaponDef.default.WeaponClassPath, class'Class', true));
	}
	else
	{
		WeaponClass = class<KFWeapon>(DynamicLoadObject(WeaponDefPath, class'Class', true));
		if (WeaponClass == None)
			return false;

		DotPos = InStr(WeaponDefPath, ".");
		if (DotPos != INDEX_NONE)
		{
			PackageName = Left(WeaponDefPath, DotPos);
			ClassName = Mid(WeaponDefPath, DotPos + 1);
			CandidateDefPath = PackageName $ "." $ ClassName $ "Def";
			WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(CandidateDefPath, class'Class', true));
		}
	}

	if (WeaponClass == None || WeaponDef == None)
		return false;

	if (StorePrice >= 0)
	{
		ApplyZvampextClientStorePrice(WeaponDef, StorePrice);
	}

	NewItem.WeaponDef = WeaponDef;
	NewItem.ClassName = WeaponClass.Name;

	DualClass = class<KFWeap_DualBase>(WeaponClass);
	if (DualClass != None && DualClass.default.SingleClass != None)
		NewItem.SingleClassName = DualClass.default.SingleClass.Name;
	else NewItem.SingleClassName = WeaponClass.Name;

	NewItem.DualClassName = WeaponClass.default.DualClass != None ? WeaponClass.default.DualClass.Name : '';
	NewItem.AssociatedPerkClasses = WeaponClass.static.GetAssociatedPerkClasses();
	NormalizeZvampextClientAssociatedPerks(NewItem.AssociatedPerkClasses);
	if (NewItem.AssociatedPerkClasses.Find(class'KFPerk_Survivalist') == INDEX_NONE)
		NewItem.AssociatedPerkClasses.AddItem(class'KFPerk_Survivalist');
	NewItem.MagazineCapacity = WeaponClass.default.MagazineCapacity[0];
	NewItem.InitialSpareMags = WeaponClass.default.InitialSpareMags[0];
	NewItem.MaxSpareAmmo = WeaponClass.default.SpareAmmoCapacity[0];
	NewItem.InitialSecondaryAmmo = WeaponClass.default.InitialSpareMags[1];
	NewItem.MaxSecondaryAmmo = WeaponClass.default.MagazineCapacity[1] * WeaponClass.default.SpareAmmoCapacity[1];
	NewItem.BlocksRequired = WeaponClass.default.InventorySize;
	NewItem.SecondaryAmmoImagePath = WeaponClass.default.SecondaryAmmoTexture != None ? "img://"$PathName(WeaponClass.default.SecondaryAmmoTexture) : "";
	NewItem.TraderFilter = WeaponClass.static.GetTraderFilter();
	NewItem.AltTraderFilter = FT_None;
	NewItem.InventoryGroup = WeaponClass.default.InventoryGroup;
	NewItem.GroupPriority = WeaponClass.default.GroupPriority;
	NewItem.bCanBuyAmmo = true;

	WeaponClass.static.SetTraderWeaponStats(WeaponStats);
	NewItem.WeaponStats = WeaponStats;
	return true;
}

simulated final function ApplyZvampextClientStorePrice(class<KFWeaponDefinition> WeaponDef, int StorePrice)
{
	local string DefPath;
	local int OldPrice;

	if (WeaponDef == None || StorePrice < 0)
	{
		return;
	}

	DefPath = NormalizeZvampextClientClassPath(PathName(WeaponDef));
	OldPrice = WeaponDef.default.BuyPrice;
	ConsoleCommand("set" @ DefPath @ "BuyPrice" @ StorePrice);
	`log("[Zvamp] client custom item price override: "$DefPath@"old="$OldPrice@"new="$StorePrice@"effective="$WeaponDef.default.BuyPrice);
}

simulated final function ApplyZvampextClientStorePriceToTraderItems(out KFGFxObject_TraderItems TraderItems, const out STraderItem MatchItem, int StorePrice)
{
	local int i;

	ApplyZvampextClientStorePrice(MatchItem.WeaponDef, StorePrice);
	for (i = 0; i < TraderItems.SaleItems.Length; ++i)
	{
		if ((MatchItem.WeaponDef != None && TraderItems.SaleItems[i].WeaponDef == MatchItem.WeaponDef)
			|| (MatchItem.ClassName != '' && TraderItems.SaleItems[i].ClassName == MatchItem.ClassName))
		{
			ApplyZvampextClientStorePrice(TraderItems.SaleItems[i].WeaponDef, StorePrice);
		}
	}
}

simulated final function string NormalizeZvampextClientClassPath(string ClassPath)
{
	if (Left(ClassPath, 6) ~= "Class ")
	{
		ClassPath = Mid(ClassPath, 6);
	}
	if (Left(ClassPath, 6) ~= "Class'")
	{
		ClassPath = Mid(ClassPath, 6);
		if (Right(ClassPath, 1) == "'")
		{
			ClassPath = Left(ClassPath, Len(ClassPath) - 1);
		}
	}
	return ClassPath;
}

simulated final function NormalizeZvampextClientAssociatedPerks(out array<class<KFPerk> > AssociatedPerks)
{
	local int i, j;

	for (i = AssociatedPerks.Length - 1; i >= 0; --i)
	{
		if (AssociatedPerks[i] == None)
		{
			AssociatedPerks.Remove(i, 1);
			continue;
		}
		for (j = i - 1; j >= 0; --j)
		{
			if (AssociatedPerks[j] == AssociatedPerks[i])
			{
				AssociatedPerks.Remove(i, 1);
				break;
			}
		}
	}
}

simulated final function LogZvampextClientTraderItem(string Prefix, const out STraderItem Item)
{
	local int i;
	local string PerkNames;

	for (i = 0; i < Item.AssociatedPerkClasses.Length; ++i)
	{
		if (PerkNames != "")
			PerkNames $= ",";
		PerkNames $= string(Item.AssociatedPerkClasses[i]);
	}

	`log("[Zvamp] "$Prefix
		@"class="$Item.ClassName
		@"def="$Item.WeaponDef
		@"itemId="$Item.ItemID
		@"price="$(Item.WeaponDef != None ? Item.WeaponDef.default.BuyPrice : -1)
		@"blocks="$Item.BlocksRequired
		@"group="$Item.InventoryGroup
		@"priority="$Item.GroupPriority
		@"filter="$Item.TraderFilter
		@"perks="$PerkNames);
}

reliable client function ClientRevampOpenTraderMenu()
{
	ClientOpenTraderMenu(true);
	ConsoleCommand("OpenTraderMenu");
}

reliable client function ClientRevampSetCheats(bool bEnabled)
{
	bRevampTestCheatsEnabled = bEnabled;
	if (bEnabled)
	{
		ConsoleCommand("Admin EnableCheats");
		ClientMessage("Requested admin EnableCheats.",'Priority');
	}
	else ClientMessage("Test cheats toggle disabled.",'Priority');
}

reliable client function ClientRevampGod()
{
	ClientMessage("God command is unavailable on this server.",'Priority');
}

exec function God()
{
	ZvampextServerGod();
}

exec function Diag()
{
	ZvampextServerDiag("manual");
}

exec function ZRefreshnewitems()
{
	ZvampextServerRefreshNewItems();
}

exec function SpawnProbe(optional string ZedName)
{
	ZvampextServerSpawnProbe(ZedName);
}

exec function ZCheckHands()
{
	ZvampextServerCheckHands();
}

reliable server function ZvampextServerGod()
{
	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Zvampext god denied: you are not marked as admin on the server.", 'Priority');
		return;
	}

	bRevampGodMode = !bRevampGodMode;
	if (Pawn != None && bRevampGodMode)
	{
		Pawn.Health = Max(Pawn.Health, 1);
	}
	`log("[Zvamp] god mode "$(bRevampGodMode ? "enabled" : "disabled")$" for "$PlayerReplicationInfo.PlayerName);
	ClientMessage("[Zvamp] god mode "$(bRevampGodMode ? "enabled." : "disabled."), 'Priority');
}

reliable server function ZvampextServerDiag(string Label)
{
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;
	local int RemainingAI, CurrentMaxMonsters, Wave, AIAlive;
	local bool bTraderOpen, bStopCountDown;
	local name GameStateName;
	local KFAISpawnManager SpawnManager;

	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Zvampext diag denied: you are not marked as admin on the server.", 'Priority');
		return;
	}

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	GameStateName = 'None';
	Wave = -1;
	AIAlive = -1;
	RemainingAI = -1;
	CurrentMaxMonsters = -1;
	if (KFGI != None)
	{
		GameStateName = KFGI.GetStateName();
		AIAlive = KFGI.AIAliveCount;
		SpawnManager = KFGI.SpawnManager;
	}
	if (KFGRI != None)
	{
		Wave = KFGRI.WaveNum;
		RemainingAI = KFGRI.AIRemaining;
		CurrentMaxMonsters = KFGRI.CurrentMaxMonsters;
		bTraderOpen = KFGRI.bTraderIsOpen;
		bStopCountDown = KFGRI.bStopCountDown;
	}

	`log("[ZvampDiag] admin diag "$Label
		@"from="$PlayerReplicationInfo.PlayerName
		@"Game="$KFGI
		@"State="$GameStateName
		@"Wave="$Wave
		@"TraderOpen="$bTraderOpen
		@"StopCountdown="$bStopCountDown
		@"AIAlive="$AIAlive
		@"AIRemaining="$RemainingAI
		@"CurrentMaxMonsters="$CurrentMaxMonsters
		@"SpawnManager="$SpawnManager);
	ClientMessage("[Zvamp] diag printed to server console.", 'Priority');
}

final function class<KFWeaponDefinition> ZvampResolveWeaponDefForWeapon(KFWeapon W)
{
	local string ClassPath;
	local string PackageName;
	local string ClassName;
	local string Suffix;
	local string DefPath;
	local int DotPos;
	local class<KFWeaponDefinition> WeaponDef;

	if (W == None)
		return None;

	ClassPath = PathName(W.Class);
	DotPos = InStr(ClassPath, ".");
	if (DotPos <= 0)
		return None;

	PackageName = Left(ClassPath, DotPos);
	ClassName = string(W.Class.Name);
	if (Left(ClassName, 7) ~= "KFWeap_")
	{
		Suffix = Mid(ClassName, 7);
		DefPath = PackageName $ ".KFWeapDef_" $ Suffix;
		WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(DefPath, class'Class', true));
		if (WeaponDef != None && PathName(W.Class) ~= WeaponDef.default.WeaponClassPath)
			return WeaponDef;
	}

	DefPath = PackageName $ "." $ Repl(ClassName, "KFWeap", "KFWeapDef");
	WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(DefPath, class'Class', true));
	if (WeaponDef != None && PathName(W.Class) ~= WeaponDef.default.WeaponClassPath)
		return WeaponDef;

	return None;
}

reliable server function ZvampextServerCheckHands()
{
	local KFWeapon W;
	local Inventory Inv;
	local class<KFWeaponDefinition> WeaponDef;
	local string WeaponClassPath, WeaponDefPath, WeaponDefClassPath, ArchetypePath;
	local string ItemName;
	local int InventoryGroup, GroupPriority;

	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Zvampext checkhands denied: you are not marked as admin on the server.", 'Priority');
		return;
	}

	if (Pawn == None)
	{
		ClientMessage("[Zvamp] checkhands failed: you have no pawn.", 'Priority');
		return;
	}

	Inv = Pawn.Weapon;
	W = KFWeapon(Inv);
	if (Inv == None)
	{
		ClientMessage("[Zvamp] checkhands: no weapon/inventory in hands.", 'Priority');
		return;
	}

	WeaponClassPath = PathName(Inv.Class);
	ArchetypePath = PathName(Inv.ObjectArchetype);
	if (W != None)
	{
		ItemName = W.ItemName;
		InventoryGroup = W.InventoryGroup;
		GroupPriority = W.GroupPriority;
		WeaponDef = ZvampResolveWeaponDefForWeapon(W);
		if (WeaponDef != None)
		{
			WeaponDefPath = PathName(WeaponDef);
			WeaponDefClassPath = WeaponDef.default.WeaponClassPath;
		}
	}

	ClientMessage("[Zvamp] hands item: "$WeaponClassPath, 'Priority');
	if (W != None)
		ClientMessage("[Zvamp] item name: "$W.ItemName$" group="$W.InventoryGroup$" priority="$W.GroupPriority, 'Priority');
	if (WeaponDef != None)
		ClientMessage("[Zvamp] weapon def: "$WeaponDefPath$" -> "$WeaponDefClassPath, 'Priority');
	ClientMessage("[Zvamp] archetype: "$ArchetypePath, 'Priority');

	`log("[ZvampCheckHands] player="$PlayerReplicationInfo.PlayerName
		@"item="$WeaponClassPath
		@"itemName="$ItemName
		@"group="$InventoryGroup
		@"priority="$GroupPriority
		@"weaponDef="$WeaponDefPath
		@"weaponDefClass="$WeaponDefClassPath
		@"archetype="$ArchetypePath);
}

reliable server function ZvampextServerRefreshNewItems()
{
	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Zvampext item refresh denied: you are not marked as admin on the server.", 'Priority');
		return;
	}

	if (OnRefreshNewItems == None)
	{
		ClientMessage("[Zvamp] custom trader item refresh failed: server handler not ready.", 'Priority');
		return;
	}

	`log("[Zvamp] custom trader item refresh requested by "$PlayerReplicationInfo.PlayerName);
	OnRefreshNewItems(Self);
}

final function class<KFPawn_Monster> ZvampResolveSpawnProbeClass(string ZedName)
{
	local string ClassName;

	ZedName = Locs(ZvampTrimCommand(ZedName));
	if (ZedName == "" || ZedName ~= "crawler")
	{
		return class'KFPawn_ZedCrawler';
	}
	if (ZedName ~= "cyst" || ZedName ~= "clot")
	{
		return class'KFPawn_ZedClot_Cyst';
	}
	if (ZedName ~= "alpha" || ZedName ~= "aclot")
	{
		return class'KFPawn_ZedClot_Alpha';
	}
	if (ZedName ~= "slasher" || ZedName ~= "sclot")
	{
		return class'KFPawn_ZedClot_Slasher';
	}
	if (ZedName ~= "bloat")
	{
		return class'KFPawn_ZedBloat';
	}
	if (ZedName ~= "stalker")
	{
		return class'KFPawn_ZedStalker';
	}
	if (ZedName ~= "gorefast")
	{
		return class'KFPawn_ZedGorefast';
	}
	if (ZedName ~= "husk")
	{
		return class'KFPawn_ZedHusk';
	}

	ClassName = ZedName;
	if (InStr(ClassName, ".") == INDEX_NONE)
	{
		ClassName = "KFGameContent." $ ClassName;
	}
	return class<KFPawn_Monster>(DynamicLoadObject(ClassName, class'Class'));
}

reliable server function ZvampextServerSpawnProbe(optional string ZedName)
{
	local class<KFPawn_Monster> ZedClass;
	local KFPawn_Monster Zed;
	local Controller ZedController;
	local vector SpawnLocation, Forward;
	local rotator SpawnRotation;
	local NavigationPoint ProbeStartSpot;
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;

	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Zvampext spawnprobe denied: you are not marked as admin on the server.", 'Priority');
		return;
	}

	ZedClass = ZvampResolveSpawnProbeClass(ZedName);
	`log("[ZvampProbe] direct spawn requested by "$PlayerReplicationInfo.PlayerName
		@"Input="$ZedName
		@"Class="$ZedClass);
	if (ZedClass == None)
	{
		ClientMessage("[Zvamp] spawnprobe failed: unknown zed class.", 'Priority');
		return;
	}

	SpawnRotation = Rotation;
	if (Pawn != None)
	{
		Forward = Vector(Rotation);
		SpawnLocation = Pawn.Location + Forward * 220;
		SpawnLocation.Z += 24;
	}
	else
	{
		KFGI = KFGameInfo(WorldInfo.Game);
		if (KFGI != None)
		{
			ProbeStartSpot = KFGI.FindPlayerStart(Self, 0);
		}
		if (ProbeStartSpot != None)
		{
			SpawnLocation = ProbeStartSpot.Location;
			SpawnLocation.X += 128;
			SpawnLocation.Z += 64;
			SpawnRotation = ProbeStartSpot.Rotation;
		}
		else
		{
			SpawnLocation = Location;
			SpawnLocation.Z += 64;
		}
	}

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	`log("[ZvampProbe] before pawn spawn"
		@"Location="$SpawnLocation
		@"Game="$KFGI
		@"Wave="$((KFGRI != None) ? string(KFGRI.WaveNum) : "None")
		@"AIAlive="$((KFGI != None) ? string(KFGI.AIAliveCount) : "None")
		@"AIRemaining="$((KFGRI != None) ? string(KFGRI.AIRemaining) : "None"));

	Zed = Spawn(ZedClass,,, SpawnLocation, SpawnRotation,, true);
	`log("[ZvampProbe] after pawn spawn Pawn="$Zed);
	if (Zed == None)
	{
		ClientMessage("[Zvamp] spawnprobe pawn spawn returned None.", 'Priority');
		return;
	}

	`log("[ZvampProbe] before controller spawn ControllerClass="$Zed.ControllerClass
		@"Health="$Zed.Health
		@"HealthMax="$Zed.HealthMax);
	ZedController = Spawn(Zed.ControllerClass);
	`log("[ZvampProbe] after controller spawn Controller="$ZedController);
	if (ZedController == None)
	{
		ClientMessage("[Zvamp] spawnprobe controller spawn returned None.", 'Priority');
		return;
	}

	`log("[ZvampProbe] before possess");
	ZedController.Possess(Zed, false);
	`log("[ZvampProbe] after possess Controller="$Zed.Controller@"PawnController="$ZedController);
	ClientMessage("[Zvamp] spawnprobe spawned "$ZedClass$"; check server log.", 'Priority');
}

exec function RequestSkipTrader()
{
	if (bRevampTraderGuardEnabled && bRevampTraderGuardBlockSkip && PlayerReplicationInfo!=None && !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("TraderGuard is blocking skip trader votes.",'Priority');
		return;
	}
	ZvampextReleaseTraderPauseForSkip();
	Super.RequestSkipTrader();
}

reliable server function ZvampextReleaseTraderPauseForSkip()
{
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None || !KFGRI.bTraderIsOpen)
	{
		return;
	}

	KFGRI.bStopCountDown = false;
	KFGRI.bForceNetUpdate = true;
	`log("[Zvamp] released trader pause for skip request from "$PlayerReplicationInfo.PlayerName);
}

exec function RevampOpenTrader()
{
	RevampPublicOpenTrader();
}

exec function Admin(string CommandLine)
{
	ZvampextServerAdmin(CommandLine);
}

final function string ZvampTrimCommand(string S)
{
	while (Len(S)>0 && (Left(S,1)==" " || Left(S,1)==Chr(9)))
		S = Mid(S,1);
	while (Len(S)>0 && (Right(S,1)==" " || Right(S,1)==Chr(9)))
		S = Left(S,Len(S)-1);
	return S;
}

reliable server function ZvampextServerAdmin(string CommandLine)
{
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;
	local string Result;

	CommandLine = ZvampTrimCommand(CommandLine);
	if (CommandLine ~= "zvampextendwave")
		CommandLine = "endwave";
	else if (CommandLine ~= "zvampextkillzeds")
		CommandLine = "killzeds";
	else if (CommandLine ~= "zvampextfastforward")
		CommandLine = "ff";
	else if (CommandLine ~= "zvampextopentrader")
		CommandLine = "opentrader";

	if (CommandLine == "")
	{
		return;
	}

	if (Left(Locs(CommandLine), 15) == "doshthrowamount")
	{
		PlayerSetDoshThrowAmount(int(ZvampTrimCommand(Mid(CommandLine, 15))));
		return;
	}

	if (Left(Locs(CommandLine), 9) == "doshthrow")
	{
		PlayerSetDoshThrowAmount(int(ZvampTrimCommand(Mid(CommandLine, 9))));
		return;
	}

	if (CommandLine ~= "zclassresetyesimcertain")
	{
		ZClassResetyesimcertain();
		return;
	}

	if (Left(Locs(CommandLine), 5) == "zvote")
	{
		ZVote(ZvampTrimCommand(Mid(CommandLine, 5)));
		return;
	}

	if (PlayerReplicationInfo == None || !PlayerReplicationInfo.bAdmin)
	{
		ClientMessage("Zvampext admin command denied: you are not marked as admin on the server.", 'Priority');
		return;
	}
	`log("[Zvamp] admin command from "$PlayerReplicationInfo.PlayerName$": "$CommandLine);

	if (CommandLine ~= "god")
	{
		ZvampextServerGod();
		return;
	}

	if (CommandLine ~= "diag")
	{
		ZvampextServerDiag("admin-command");
		return;
	}

	if (CommandLine ~= "zcheckhands" || CommandLine ~= "zcheckhand" || CommandLine ~= "checkhands" || CommandLine ~= "checkhand")
	{
		ZvampextServerCheckHands();
		return;
	}

	if (CommandLine ~= "buildid" || CommandLine ~= "build id")
	{
		AdminBuildID();
		return;
	}

	if (CommandLine ~= "zrefreshnewitems" || CommandLine ~= "refreshnewitems" || CommandLine ~= "refreshitems")
	{
		ZvampextServerRefreshNewItems();
		return;
	}

	if (Left(Locs(CommandLine), 10) == "spawnprobe")
	{
		ZvampextServerSpawnProbe(ZvampTrimCommand(Mid(CommandLine, 10)));
		return;
	}

	if (Left(Locs(CommandLine), 6) == "doshme")
	{
		AdminGiveDosh(int(ZvampTrimCommand(Mid(CommandLine, 6))));
		return;
	}

	if (Left(Locs(CommandLine), 12) == "progresswave")
	{
		AdminProgressWave(int(ZvampTrimCommand(Mid(CommandLine, 12))));
		return;
	}

	if (CommandLine ~= "endwave")
	{
		AdminRevampAction(18);
		return;
	}

	if (CommandLine ~= "opentrader" || CommandLine ~= "open trader" || CommandLine ~= "trader")
	{
		AdminRevampAction(13);
		return;
	}

	if (CommandLine ~= "killzeds")
	{
		AdminRevampAction(17);
		return;
	}

	if (CommandLine ~= "f" || CommandLine ~= "ff" || CommandLine ~= "fastforward" || CommandLine ~= "skip" || CommandLine ~= "skiptrader")
	{
		KFGI = KFGameInfo(WorldInfo.Game);
		KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
		if (KFGI == None || KFGRI == None || !KFGRI.bTraderIsOpen)
		{
			ClientMessage("Trader is not open.", 'Priority');
			return;
		}

		ZvampextReleaseTraderPauseForSkip();
		KFGRI.bStopCountDown = false;
		KFGRI.RemainingTime = 1;
		KFGRI.RemainingMinute = 1;
		KFGI.SkipTrader(1);
		ClientMessage("Skipped trader time.", 'Priority');
		return;
	}

	Result = ConsoleCommand(CommandLine);
	if (Result != "")
	{
		ClientMessage(Result);
	}
}

exec function RvOpenTrader()
{
	RevampPublicOpenTrader();
}

exec function ZvampextFastForward()
{
	RevampAdminFastForwardTrader();
}

exec function ZvampextOpenTrader()
{
	RevampAdminOpenTrader();
}

exec function ZvampextKillZeds()
{
	AdminRevampAction(17);
}

exec function ZvampextEndWave()
{
	AdminRevampAction(18);
}

exec function KillZeds()
{
	AdminRevampAction(17);
}

exec function EndWave()
{
	AdminRevampAction(18);
}

exec function DoshMe(int DoshAmount)
{
	AdminGiveDosh(DoshAmount);
}

exec function DoshThrowAmount(int NewAmount)
{
	PlayerSetDoshThrowAmount(NewAmount);
}

exec function ProgressWave(int WaveCount)
{
	AdminProgressWave(WaveCount);
}

exec function ZVote(string CommandLine)
{
	CommandLine = ZvampTrimCommand(CommandLine);
	if (Left(Locs(CommandLine), 12) == "progresswave")
	{
		PlayerProgressWaveVoteCall(int(ZvampTrimCommand(Mid(CommandLine, 12))));
		return;
	}
	if (CommandLine ~= "yes" || CommandLine ~= "accept")
	{
		PlayerProgressWaveVoteAnswer(true);
		return;
	}
	if (CommandLine ~= "no" || CommandLine ~= "decline")
	{
		PlayerProgressWaveVoteAnswer(false);
		return;
	}
	ClientMessage("[Zvamp] Usage: Zvote progresswave <waves>, Zvote yes, or Zvote no.", 'Priority');
}

exec function BuildID()
{
	AdminBuildID();
}

exec function CheckHands()
{
	ZvampextServerCheckHands();
}

exec function ZClassResetyesimcertain()
{
	ServerResetCurrentClassYesImCertain();
}

exec function AdminMenu()
{
	local KF2GUIController GUIController;
	local UI_MidGameMenu Menu;

	if (ShouldBlockVampUIForEndMatch())
	{
		ClientMessage("Zvampext UI is disabled after match end so vanilla endmatch/mapvote can take over.",'Priority');
		return;
	}

	if (PlayerReplicationInfo==None || (!PlayerReplicationInfo.bAdmin && WorldInfo.NetMode==NM_Client))
	{
		ClientMessage("You are not authorized to open the Zvampext admin menu.",'Priority');
		return;
	}

	GUIController = class'KF2GUIController'.Static.GetGUIController(Self);
	if (GUIController==None)
		return;

	Menu = UI_MidGameMenu(GUIController.OpenMenu(MidGameMenuClass));
	if (Menu!=None)
		Menu.SelectAdminPage();
}

simulated reliable client event bool ShowConnectionProgressPopup(EProgressMessageType ProgressType, string ProgressTitle, string ProgressDescription, bool SuppressPasswordRetry = false)
{
	switch (ProgressType)
	{
	case	PMT_ConnectionFailure :
	case	PMT_PeerConnectionFailure :
		KFExtendedHUD(myHUD).NotifyLevelChange();
		KFExtendedHUD(myHUD).ShowProgressMsg(ConnectionError@ProgressTitle$"|"$ProgressDescription$"|"$Disconnecting,true);
		return true;
	case	PMT_DownloadProgress :
		KFExtendedHUD(myHUD).NotifyLevelChange();
	case	PMT_AdminMessage :
		KFExtendedHUD(myHUD).ShowProgressMsg(ProgressTitle$"|"$ProgressDescription);
		return true;
	}
	return false;
}

simulated function CancelConnection()
{
	if (KFExtendedHUD(myHUD)!=None)
		KFExtendedHUD(myHUD).CancelConnection();
	else class'Engine'.Static.GetEngine().GameViewport.ConsoleCommand("Disconnect");
}

function NotifyLevelUp(class<KFPerk> PerkClass, byte PerkLevel, byte NewPrestigeLevel);

function ShowBossNameplate(KFInterface_MonsterBoss KFBoss, optional string PlayerName)
{
	if (!bNamePlateShown) // Dont make multiple bosses pop this up multiple times.
	{
		bNamePlateShown = true;
		Super.ShowBossNameplate(KFBoss,PlayerName);
		SetTimer(8,false,'HideBossNameplate'); // MAKE sure it goes hidden.
	}
}

function HideBossNameplate()
{
	if (!bNamePlateHidden)
	{
		bNamePlateHidden = false;
		Super.HideBossNameplate();
		ClearTimer('HideBossNameplate');
		if (MyGFxHUD!=None)
			MyGFxHUD.MusicNotification.SetVisible(true);
	}
}

function UpdateRotation(float DeltaTime)
{
	if (OldViewRot!=Rotation && Pawn!=None && Pawn.IsAliveAndWell())
		NotifyFixed(1);
	Super.UpdateRotation(DeltaTime);
	OldViewRot = Rotation;
}

reliable server function ServerGetUnloadInfo(byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload)
{
	OnRequestUnload(Self,CallID,PerkClass,bUnload);
}

delegate OnRequestUnload(ExtPlayerController PC, byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload);

reliable client function ClientGotUnloadInfo(byte CallID, byte Code, optional int DataA, optional int DataB)
{
	OnClientGetResponse(CallID,Code,DataA,DataB);
}

delegate OnClientGetResponse(byte CallID, byte Code, int DataA, int DataB);
function DefClientResponse(byte CallID, byte Code, int DataA, int DataB);

reliable client function ClientUsedAmmo(Ext_T_SupplierInteract S)
{
	if (Pawn!=None && S!=None)
		S.UsedOnClient(Pawn);
}

unreliable server function ServerNextSpectateMode()
{
	local Pawn HumanViewTarget;

	if (!IsSpectating())
		return;

	// switch to roaming if human viewtarget is dead
	if (CurrentSpectateMode != SMODE_Roaming)
	{
		HumanViewTarget = Pawn(ViewTarget);
		if (HumanViewTarget == none || !HumanViewTarget.IsAliveAndWell())
		{
			SpectateRoaming();
			return;
		}
	}

	switch (CurrentSpectateMode)
	{
	case SMODE_PawnFreeCam:
		SpectatePlayer(SMODE_PawnThirdPerson);
		break;
	case SMODE_PawnThirdPerson:
		SpectatePlayer(SMODE_PawnFirstPerson);
		break;
	case SMODE_PawnFirstPerson:
	case SMODE_Roaming:
		SpectatePlayer(SMODE_PawnFreeCam);
		break;
	}
}

function ViewAPlayer(int dir)
{
	local PlayerReplicationInfo PRI;

	PRI = GetNextViewablePlayer(dir);
	if (PRI!=None)
	{
		SetViewTarget(PRI);
		ClientMessage(NowViewingFrom@PRI.GetHumanReadableName());
	}
}

exec function ViewPlayerID(int ID)
{
	ServerViewPlayerID(ID);
}

reliable server function ServerViewPlayerID(int ID)
{
	local PlayerReplicationInfo PRI;

	if (!IsSpectating())
		return;

	// Find matching player by ID
	foreach WorldInfo.GRI.PRIArray(PRI)
	{
		if (PRI.PlayerID==ID)
			break;
	}
	if (PRI==None || PRI.PlayerID!=ID || Controller(PRI.Owner)==None || Controller(PRI.Owner).Pawn==None || !WorldInfo.Game.CanSpectate(self, PRI))
		return;

	SetViewTarget(PRI);
	ClientMessage(NowViewingFrom@PRI.GetHumanReadableName());
	if (CurrentSpectateMode==SMODE_Roaming)
		SpectatePlayer(SMODE_PawnFreeCam);
}

reliable server function SpectateRoaming()
{
	local Pawn P;

	P = Pawn(ViewTarget);
	ClientMessage(ViewingFromOwnCamera);
	Super.SpectateRoaming();
	if (P!=None)
	{
		SetLocation(P.Location);
		SetRotation(P.GetViewRotation());
		ClientSetLocation(Location,Rotation);
	}
}

reliable client function ClientSetLocation(vector NewLocation, rotator NewRotation)
{
	SetLocation(NewLocation);
	Super.ClientSetLocation(NewLocation,NewRotation);
}

unreliable server function ServerPlayLevelUpDialog()
{
	if (NextCommTime<WorldInfo.TimeSeconds)
	{
		NextCommTime = WorldInfo.TimeSeconds+2.f;
		Super.ServerPlayLevelUpDialog();
	}
}

unreliable server function ServerPlayVoiceCommsDialog(int CommsIndex)
{
	if (NextCommTime<WorldInfo.TimeSeconds)
	{
		NextCommTime = WorldInfo.TimeSeconds+2.f;
		Super.ServerPlayVoiceCommsDialog(CommsIndex);
	}
}

// The player wants to fire.
// Setup bFire/bAltFire so that Auto-Fire trait will work.
exec function StartFire(optional byte FireModeNum)
{
	if (FireModeNum==0)
		bFire = 1;
	else if (FireModeNum==1)
		bAltFire = 1;
	Super.StartFire(FireModeNum);
}

exec function StopFire(optional byte FireModeNum)
{
	if (FireModeNum==0)
		bFire = 0;
	else if (FireModeNum==1)
		bAltFire = 0;
	Super.StopFire(FireModeNum);
}

state Spectating
{
	function BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);
		bCollideWorld = false;
	}
	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
	{
		Acceleration = Normal(NewAccel) * SpectatorCameraSpeed;
		Velocity = Acceleration;
		MoveSmooth(Acceleration * DeltaTime);
	}
	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;
		local rotator OldRotation;

		OldRotation = Rotation;
		GetAxes(Rotation,X,Y,Z);
		Acceleration = (Normal(PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1)) - bDuck*vect(0,0,1))*100.f;
		UpdateRotation(DeltaTime);

		if (Role < ROLE_Authority) // then save this move and replicate it
		{
			ReplicateMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));

			// only done for clients, as LastActiveTime only affects idle kicking
			if ((!IsZero(Acceleration) || OldRotation != Rotation) && LastUpdateSpectatorActiveTime<WorldInfo.TimeSeconds)
			{
				LastUpdateSpectatorActiveTime = WorldInfo.TimeSeconds+UpdateSpectatorActiveInterval;
				ServerSetSpectatorActive();
			}
		}
		else
		{
			ProcessMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
		}
	}
	exec function SpectateNextPlayer()
	{
		SpectateRoaming();
	}
	exec function SpectatePreviousPlayer()
	{
		ServerViewNextPlayer();
		if (Role == ROLE_Authority)
		{
			NotifyChangeSpectateViewTarget();
		}
	}
	unreliable server function ServerViewNextPlayer()
	{
		if (CurrentSpectateMode==SMODE_Roaming)
		{
			CurrentSpectateMode = SMODE_PawnFreeCam;
			SetCameraMode('FreeCam');
		}
		Global.ServerViewNextPlayer();
	}
	reliable client function ClientSetCameraMode(name NewCamMode)
	{
		Global.ClientSetCameraMode(NewCamMode);
		if (NewCamMode=='FirstPerson' && ViewTarget==Self && MyGFxHUD!=None)
			MyGFxHUD.SpectatorInfoWidget.SetSpectatedKFPRI(None); // Possibly went to first person, hide player info.
	}
}

// Feign death:
function EnterRagdollMode(bool bEnable)
{
	if (bEnable)
		GoToState('RagdollMove');
	else if (Pawn==None)
		GotoState('Dead');
	else if (Pawn.PhysicsVolume.bWaterVolume)
		GotoState(Pawn.WaterMovementState);
	else GotoState(Pawn.LandMovementState);
}

// Optional dramatic end-game camera!
simulated function EndGameCamFocus(vector Pos)
{
	local vector CamPos;
	local rotator CamRot;

	GetPlayerViewPoint(CamPos,CamRot);
	bEndGameCamFocus = true;
	EndGameCamFocusPos[0] = Pos;
	EndGameCamFocusPos[1] = CamPos;
	EndGameCamRot = CamRot;
	EndGameCamTimer = WorldInfo.RealTimeSeconds;

	if (LocalPlayer(Player)==None)
		ClientFocusView(Pos);
	else if (KFPawn(ViewTarget)!=None)
		KFPawn(ViewTarget).SetMeshVisibility(true);
}

reliable client function ClientFocusView(vector Pos)
{
	if (WorldInfo.NetMode==NM_Client)
		EndGameCamFocus(Pos);
}

final function bool CalcEndGameCam()
{
	local float T,RT;
	local vector HL,HN;

	if (LastPlayerCalcView==WorldInfo.TimeSeconds)
		return true;

	T = WorldInfo.RealTimeSeconds-EndGameCamTimer;

	if (T>=20.f) // Finished view.
	{
		bEndGameCamFocus = false;
		if (LocalPlayer(Player)!=None && KFPawn(ViewTarget)!=None)
			KFPawn(ViewTarget).SetMeshVisibility(!Global.UsingFirstPersonCamera());
		return false;
	}
	// Setup other cache params.
	LastPlayerCalcView	= WorldInfo.TimeSeconds;

	CalcViewLocation.Z = 1.f;
	RT = WorldInfo.RealTimeSeconds;
	if (T<4.f)
		RT += (4.f-T);
	CalcViewLocation.X = Sin(RT*0.08f);
	CalcViewLocation.Y = Cos(RT*0.08f);
	CalcViewLocation = EndGameCamFocusPos[0] + Normal(CalcViewLocation)*350.f;
	if (Trace(HL,HN,CalcViewLocation,EndGameCamFocusPos[0],false,vect(16,16,16))!=None)
		CalcViewLocation = HL;

	CalcViewRotation = rotator(EndGameCamFocusPos[0]-CalcViewLocation);

	if (T<4.f && LocalPlayer(Player)!=None) // Zoom in to epic death.
	{
		T*=0.25;
		CalcViewLocation = CalcViewLocation*T + EndGameCamFocusPos[1]*(1.f-T);
		CalcViewRotation = RLerp(EndGameCamRot,CalcViewRotation,T,true);
	}
	return true;
}

simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
{
	if (bEndGameCamFocus && CalcEndGameCam())
	{
		out_Location = CalcViewLocation;
		out_Rotation = CalcViewRotation;
		return;
	}
	Super.GetPlayerViewPoint(out_Location,out_Rotation);
}

exec function DebugRenderMode()
{
	if (WorldInfo.NetMode!=NM_Client)
	{
		bRenderModes = !bRenderModes;
		SaveConfig();
		ClientMessage(bRenderModes);
	}
}

// Stats traffic.
reliable server function ServerRequestStats(byte ListNum)
{
	if (ListNum<3)
	{
		TransitListNum = ListNum;
		TransitIndex = 0;
		SetTimer(0.001,true,'SendNextList');
	}
}

function SendNextList()
{
	if (!OnClientGetStat(Self,TransitListNum,TransitIndex++))
	{
		ClientGetStat(TransitListNum,true);
		ClearTimer('SendNextList');
	}
}

simulated reliable client function ClientGetStat(byte ListNum, bool bFinal, optional string N, optional UniqueNetId ID, optional int V)
{
	OnClientReceiveStat(ListNum,bFinal,N,ID,V);
}

Delegate OnClientReceiveStat(byte ListNum, bool bFinal, string N, UniqueNetId ID, int V);
Delegate bool OnClientGetStat(ExtPlayerController PC, byte ListNum, int StatIndex);

reliable server function ChangeSpectateMode(bool bSpectator)
{
	OnSpectateChange(Self,bSpectator);
}

simulated reliable client function ClientSpectateMode(bool bSpectator)
{
	UpdateURL("SpectatorOnly",(bSpectator ? "1" : "0"),false);
}

Delegate OnSpectateChange(ExtPlayerController PC, bool bSpectator);

state RagdollMove extends PlayerWalking
{
Ignores NotifyPhysicsVolumeChange,ServerCamera,ResetCameraMode;

	event BeginState(Name PreviousStateName)
	{
		FOVAngle = DesiredFOV;

		if (WorldInfo.NetMode!=NM_Client)
			SetCameraMode('ThirdPerson');
	}
	event EndState(Name NewState)
	{
		FOVAngle = DesiredFOV;

		if (Pawn!=none && NewState!='Dead')
			Global.SetCameraMode('FirstPerson');
	}
	function PlayerMove(float DeltaTime)
	{
		local rotator			OldRotation;

		if (Pawn == None)
			GotoState('Dead');
		else
		{
			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation(DeltaTime);
			bDoubleJump = false;
			bPressedJump = false;

			if (Role < ROLE_Authority) // then save this move and replicate it
				ReplicateMove(DeltaTime, vect(0,0,0), DCLICK_None, OldRotation - Rotation);
			else ProcessMove(DeltaTime, vect(0,0,0), DCLICK_None, OldRotation - Rotation);
		}
	}
	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Actor TheViewTarget;
		local vector HL,HN,EndOffset;

		if (bEndGameCamFocus && CalcEndGameCam())
		{
			out_Location = CalcViewLocation;
			out_Rotation = CalcViewRotation;
			return;
		}
		if (Global.UsingFirstPersonCamera())
			Global.GetPlayerViewPoint(out_Location,out_Rotation);
		else
		{
			out_Rotation = Rotation;
			TheViewTarget = GetViewTarget();
			if (TheViewTarget==None)
				TheViewTarget = Self;
			out_Location = TheViewTarget.Location;
			EndOffset = out_Location-vector(Rotation)*250.f;

			if (TheViewTarget.Trace(HL,HN,EndOffset,out_Location,false,vect(16,16,16))!=None)
				out_Location = HL;
			else out_Location = EndOffset;
		}
	}
}

state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

	function PlayerMove(float DeltaTime)
	{
		local vector			X,Y,Z, NewAccel;
		local eDoubleClickDir	DoubleClickMove;
		local rotator			OldRotation;
		local bool				bSaveJump;

		if (Pawn == None)
		{
			GotoState('Dead');
		}
		else
		{
			GetAxes(Pawn.Rotation,X,Y,Z);
			if (VSZombie(Pawn)!=None)
				VSZombie(Pawn).ModifyPlayerInput(Self,DeltaTime);

			// Update acceleration.
			NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
			NewAccel.Z	= 0;
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			if (IsLocalPlayerController())
			{
				AdjustPlayerWalkingMoveAccel(NewAccel);
			}

			DoubleClickMove = PlayerInput.CheckForDoubleClickMove(DeltaTime/WorldInfo.TimeDilation);

			// Update rotation.
			OldRotation = Rotation;
			UpdateRotation(DeltaTime);
			bDoubleJump = false;

			if (bPressedJump && Pawn.CannotJumpNow())
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			if (Role < ROLE_Authority) // then save this move and replicate it
			{
				ReplicateMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DoubleClickMove, OldRotation - Rotation);
			}
			bPressedJump = bSaveJump;
		}
	}
}

state Dead
{
	event BeginState(Name PreviousStateName)
	{
		local KFPlayerInput KFPI;

		SetTimer(5.f, false, nameof(StartSpectate));
		if ((Pawn != None) && (Pawn.Controller == self))
			Pawn.Controller = None;
		Pawn = None;
		FOVAngle = DesiredFOV;
		Enemy = None;
		bPressedJump = false;
		FindGoodView();
		CleanOutSavedMoves();

		if (KFPawn(ViewTarget)!=none)
		{
			KFPawn(ViewTarget).SetMeshVisibility(true);
		}

		// Deactivate any post process effects when we die
		ResetGameplayPostProcessFX();

		if (CurrentPerk != none)
			CurrentPerk.PlayerDied();

		KFPI = KFPlayerInput(PlayerInput);
		if (KFPI != none)
			KFPI.HideVoiceComms();

		if (MyGFxManager != none)
			MyGFxManager.CloseMenus();

		if (MyGFxHUD != none)
			MyGFxHUD.ClearBuffIcons();
	}
	simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation)
	{
		local Actor TheViewTarget;
		local vector HL,HN,EndOffset;

		if (bEndGameCamFocus && CalcEndGameCam())
		{
			out_Location = CalcViewLocation;
			out_Rotation = CalcViewRotation;
			return;
		}
		out_Rotation = Rotation;
		TheViewTarget = GetViewTarget();
		if (TheViewTarget==None)
			TheViewTarget = Self;
		out_Location = TheViewTarget.Location;
		EndOffset = out_Location-vector(Rotation)*400.f;

		if (TheViewTarget.Trace(HL,HN,EndOffset,out_Location,false,vect(16,16,16))!=None)
			out_Location = HL;
		else out_Location = EndOffset;
	}
}

exec function RequestSwitchTeam()
{
	ConsoleCommand("disconnect");
}

exec function SwitchTeam()
{
	ConsoleCommand("disconnect");
}

defaultproperties
{
	InputClass=Class'ExtPlayerInput'
	// Trader crash diagnostic: use the vanilla purchase helper while isolating
	// the native GFx crash that happens after ExtAutoPurchaseHelper initializes.
	PurchaseHelperClass=class'KFAutoPurchaseHelper'
	bIgnoreEncroachers=true
	SpectatorCameraSpeed=900
	bVampUIEndMatchEnabled=false
	ZvampextBuildID="ServerExt 2026-05-19 mapvote-player-progress-vote-chat"
	ZvampextClientTraderFilterIndex=-1
	MidGameMenuClass=class'UI_MidGameMenu'
	PerkList.Empty()
	PerkList.Add((PerkClass=class'KFPerk_Berserker'))
	PerkList.Add((PerkClass=class'KFPerk_Commando'))
	PerkList.Add((PerkClass=class'KFPerk_Support'))
	PerkList.Add((PerkClass=class'KFPerk_FieldMedic'))
	PerkList.Add((PerkClass=class'KFPerk_Demolitionist'))
	PerkList.Add((PerkClass=class'KFPerk_Firebug'))
	PerkList.Add((PerkClass=class'KFPerk_Gunslinger'))
	PerkList.Add((PerkClass=class'KFPerk_Sharpshooter'))
	PerkList.Add((PerkClass=class'KFPerk_SWAT'))
	PerkList.Add((PerkClass=class'KFPerk_Survivalist'))

	NVG_DOF_FocalDistance=3800.0
	NVG_DOF_SharpRadius=2500.0
	NVG_DOF_FocalRadius=3500.0
	NVG_DOF_MaxNearBlurSize=0.25
}
