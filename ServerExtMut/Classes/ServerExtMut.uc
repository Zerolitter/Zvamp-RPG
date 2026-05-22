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

// Server extension mutator, by Marco.
Class ServerExtMut extends KFMutator
	config(ServerExtMut);

// Webadmin
var array<FWebAdminConfigInfo> WebConfigs;

struct FInventory
{
	var class<Inventory> ItemClass;
	var int Values[4];
};
struct CFGCustomZedXP
{
	var string zed; // zed name
	var float XP1; // normal
	var float XP2; // hard
	var float XP3; // suicidal
	var float XP4; // hoe
};
struct FSavedInvEntry
{
	var Controller OwnerPlayer;
	var byte Gren;
	var array<FInventory> Inv;
};
var array<FSavedInvEntry> PlayerInv;

var config array<string> PerkClasses,CustomChars,AdminCommands,BonusGameSongs,BonusGameFX,RevampAdminSteamIDs,SpawnedPerkUILayout,MidGameMenuLayout,AutoMessageTexts;
var config array<string> ZvampextAdminIDs;
var config array<CFGCustomZedXP> CustomZedXP;
var array< class<Ext_PerkBase> > LoadedPerks;
var array<FCustomCharEntry> CustomCharList;
var ExtPlayerStat ServerStatLoader;

var KFPawn LastHitZed;
var int LastHitHP;
var ExtPlayerController LastDamageDealer;
var vector LastDamagePosition;
var private const array<string> DevList;
var transient private array<UniqueNetId> DevNetID;
var ExtXMLOutput FileOutput;
var transient class<DamageType> LastKillDamageType;
var transient bool bZvampextTraderItemsApplied;
var transient bool bZvampCompatDefaultsApplied;

var SoundCue BonusGameCue;
var Object BonusGameFXObj;
var bool bSMLRuntimeActor,bSMLTraderAutoPaused,bSMLTraderCloseTimerCleared;
var int SMLTraderPausedRemainingTime;

const SettingsTagVer=18;
var KFGameReplicationInfo KF;
var config int SettingsInit;
var config int ForcedMaxPlayers,PlayerRespawnTime,LargeMonsterHP,StatAutoSaveWaves,MinUnloadPerkLevel,PostGameRespawnCost,MaxTopPlayers,DoshThrowAmount,AutoMessageIntervalSeconds,PlayerProgressWaveVoteMax,PlayerProgressWaveVoteSeconds,NextMapChoiceWave,NextMapChoiceSeconds;
var config float UnloadPerkExpCost,AdminGrenadeDamageValue,AdminGrenadeRadiusValue,AdminGrenadeThrowRangeValue,AdminAmmoPickupValue,AdminItemPickupValue,AdminArmorPickupValue,ZvampextTraderSpeedBoostMultiplier,PlayerProgressWaveVotePct,NextMapChoicePct;
var config float AdminAmmoBoxCountValue,AdminItemBoxCountValue,AdminPickupRespawnTimeValue,AdminGrenadesFromAmmoValue,AdminAmmoBoxArmorValue;
var globalconfig string ServerMOTD,StatFileDir;
var config string AutoMessageText,AutoMessageColor;
var string ZvampextBuildID;
var array<Controller> PendingSpawners;
var int LastWaveNum,NumWaveSwitches,AutoMessageIndex,ProgressWaveVoteTarget,NextMapChoiceWaveNum;
var ExtSpawnPointHelper SpawnPointer;
var bool bRespawnCheck,bSpecialSpawn,bGameHasEnded,bIsPostGame,bRevampSpawnsPaused,bProgressWaveVoteActive,bNextMapChoiceActive,bNextMapChoiceOffered;
var config bool bKillMessages,bDamageMessages,bEnableMapVote,bNoAdminCommands,bNoWebAdmin,bNoBoomstickJumping,bDumpXMLStats,bRagdollFromFall,bRagdollFromMomentum,bRagdollFromBackhit,bAddCountryTags,bThrowAllWeaponsOnDeath,bRevampTraderGuard,bRevampTraderGuardBlockSkip,bRevampTraderGuardPublicOpenTrader,bZvampextAutoEnableCheats,bZvampextUIOnly,bVampUIEndMatchEnabled,bZvampextAutoPauseTrader,bZvampextTraderSpeedBoost,bAdminGrenadeDamage,bAdminGrenadeRadius,bAdminGrenadeThrowRange,bAdminAmmoPickup,bAdminItemPickup,bAdminArmorPickup,bAutoMessageEnabled,bPlayerProgressWaveVoteEnabled,bNextMapChoiceEnabled;
var config bool bAdminAmmoBoxCount,bAdminItemBoxCount,bAdminPickupRespawnTime,bAdminGrenadesFromAmmo,bAdminAmmoBoxArmor;
var transient float NextAutoMessageTime;
var array<ExtPlayerController> ProgressWaveYesVotes,ProgressWaveNoVotes,NextMapYesVotes,NextMapNoVotes;
var ExtPlayerController ProgressWaveVoteCaller;
var transient array<KFProj_Grenade> ZvampextTunedGrenades;

var KFGI_Access KFGIA;

//Custom XP lightly array
struct CustomZedXPStruct
{
	var class<KFPawn_Monster> zedclass;
	var float XPValues[4];
};
var array<CustomZedXPStruct> CustomZedXPArray;

final function bool AddPerkClassIfMissing(class<Ext_PerkBase> P)
{
	local int i;
	local string S;

	if (P==None)
		return false;

	S = PathName(P);
	for (i=0; i<PerkClasses.Length; ++i)
		if (PerkClasses[i] ~= S)
			return false;

	PerkClasses.AddItem(S);
	return true;
}

final function bool RemoveDuplicatePerkClasses()
{
	local int i,j;
	local bool bChanged;

	for (i=PerkClasses.Length-1; i>=0; --i)
	{
		if (PerkClasses[i]=="")
		{
			PerkClasses.Remove(i,1);
			bChanged = true;
		}
	}

	for (i=0; i<PerkClasses.Length; ++i)
	{
		for (j=PerkClasses.Length-1; j>i; --j)
		{
			if (PerkClasses[i] ~= PerkClasses[j])
			{
				PerkClasses.Remove(j,1);
				bChanged = true;
			}
		}
	}

	return bChanged;
}

final function bool EnsureCoreRPGPerkClasses()
{
	local bool bChanged;

	bChanged = RemoveDuplicatePerkClasses();
	bChanged = AddPerkClassIfMissing(class'Ext_PerkBerserker') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkCommando') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkFieldMedic') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkSupport') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkDemolition') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkFirebug') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkGunslinger') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkSharpshooter') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkSWAT') || bChanged;
	bChanged = AddPerkClassIfMissing(class'Ext_PerkSurvivalist') || bChanged;

	return bChanged;
}

final function string DefaultSpawnedPerkUILayout()
{
	return "HeaderX=0.075;HeaderY=0.015;HeaderW=0.49;HeaderH=0.13;HeaderAlpha=70;RailX=0.025;RailY=0.055;RailW=0.09;RailH=1.0;RailTuck=-0.35;RailPoppedTileScale=1.0;RailInactiveAlpha=45;RailPendingAlpha=150;RailSelectedAlpha=190;RailInactiveR=32;RailInactiveG=32;RailInactiveB=128;RailPendingR=164;RailPendingG=86;RailPendingB=32;RailSelectedR=164;RailSelectedG=164;RailSelectedB=32;"
		$"SkillX=0.10;SkillY=0.16;SkillW=0.47;SkillH=0.74;SkillLeftBorderAlpha=0;DividerX=0.57;DividerY=0.16;DividerW=0.015;DividerH=0.74;SummaryX=0.585;SummaryY=0.16;SummaryW=0.405;SummaryH=0.74;"
		$"StatsX=0.115;StatsY=0.29;StatsW=0.43;StatsH=0.47;SkillsLabelX=0.115;SkillsLabelY=0.18;SkillsLabelW=0.16;SkillsLabelH=0.045;BonusesLabelX=0.61;BonusesLabelY=0.18;BonusesLabelW=0.22;BonusesLabelH=0.045;"
		$"BonusSummaryX=0.62;BonusSummaryY=0.25;BonusSummaryW=0.34;BonusSummaryH=0.36;LoadoutLabelX=0.61;LoadoutLabelY=0.66;LoadoutLabelW=0.28;LoadoutLabelH=0.04;LoadoutSummaryX=0.675;LoadoutSummaryY=0.77;LoadoutSummaryW=0.15;LoadoutSummaryH=0.055;"
		$"ConfigureX=0.125;ConfigureY=0.82;ConfigureW=0.40;ConfigureH=0.06;GrenadePrevX=0.61;GrenadePrevY=0.77;GrenadePrevW=0.055;GrenadePrevH=0.055;GrenadeNextX=0.80;GrenadeNextY=0.77;GrenadeNextW=0.055;GrenadeNextH=0.055;"
		$"ResetX=0.13;ResetY=0.215;ResetW=0.12;ResetH=0.045;UnloadX=0.255;UnloadY=0.215;UnloadW=0.12;UnloadH=0.045;PrestigeX=0.38;PrestigeY=0.215;PrestigeW=0.12;PrestigeH=0.045";
}

final function string DefaultMidGameMenuLayout()
{
	return "MenuX=0.1;MenuY=0.1;MenuW=0.8;MenuH=0.8;PagerX=0.01;PagerY=0.08;PagerW=0.98;PagerH=0.775;PagerBorder=0.04;PagerButtonSize=0.08;"
		$"OuterR=24;OuterG=24;OuterB=28;OuterA=48;BackX=0;BackY=0;BackW=1;BackH=1;BackR=40;BackG=40;BackB=44;BackA=56;FooterY=0.89;FooterH=0.045;"
		$"ButtonPanelX=0.09;ButtonPanelY=0.925;ButtonPanelW=0.82;ButtonPanelH=0.045;ButtonPanelR=96;ButtonPanelG=88;ButtonPanelB=92;ButtonPanelA=175;ButtonPanelRailR=12;ButtonPanelRailG=10;ButtonPanelRailB=18;ButtonPanelRailA=210;ButtonPanelAccentR=76;ButtonPanelAccentG=50;ButtonPanelAccentB=150;ButtonPanelAccentA=0;ButtonPanelAccentW=0.007;"
		$"SpectateX=0.09;SpectateW=0.12;SkipTraderX=0.22;SkipTraderW=0.13;MapVoteX=0.36;MapVoteW=0.12;SettingsX=0.49;SettingsW=0.13;CloseX=0.63;CloseW=0.09;DisconnectX=0.73;DisconnectW=0.11;ExitX=0.85;ExitW=0.06";
}

final function string BuildSpawnedPerkUILayoutString()
{
	local int i;
	local string S;

	for (i=0; i<SpawnedPerkUILayout.Length; ++i)
		S $= SpawnedPerkUILayout[i];
	if (S=="")
		S = DefaultSpawnedPerkUILayout();
	return S;
}

final function string BuildMidGameMenuLayoutString()
{
	local int i;
	local string S;

	for (i=0; i<MidGameMenuLayout.Length; ++i)
		S $= MidGameMenuLayout[i];
	if (S=="")
		S = DefaultMidGameMenuLayout();
	return S;
}

final function SendSpawnedPerkUILayout(ExtPlayerController PC)
{
	local int i;

	PC.ClientClearSpawnedPerkUILayout();
	if (SpawnedPerkUILayout.Length==0)
		return;
	for (i=0; i<SpawnedPerkUILayout.Length; ++i)
		PC.ClientAddSpawnedPerkUILayoutChunk(SpawnedPerkUILayout[i]);
}

final function SendMidGameMenuLayout(ExtPlayerController PC)
{
	local int i;

	PC.ClientClearMidGameMenuLayout();
	if (MidGameMenuLayout.Length==0)
	{
		PC.ClientAddMidGameMenuLayoutChunk(DefaultMidGameMenuLayout());
		return;
	}
	for (i=0; i<MidGameMenuLayout.Length; ++i)
		PC.ClientAddMidGameMenuLayoutChunk(MidGameMenuLayout[i]);
}

final function SendZvampextTraderItems(ExtPlayerController PC)
{
	local int i;
	local Zvamp_CustomItems CustomItems;
	local int StorePrice;
	local string ItemSpec;

	if (PC == None)
	{
		return;
	}

	CustomItems = new(None) class'Zvamp_CustomItems';
	PC.ClientClearZvampextTraderItems();
	for (i = 0; i < CustomItems.Item.Length; ++i)
	{
		ItemSpec = CustomItems.Item[i];
		StorePrice = GetZvampextStorePrice(CustomItems, CustomItems.Item[i]);
		if (StorePrice >= 0)
		{
			ItemSpec $= "|"$StorePrice;
		}
		PC.ClientAddZvampextTraderItemPath(ItemSpec);
	}
	PC.ClientApplyZvampextTraderItems();
}

final function ApplyZvampCompatibilityDefaults()
{
	class'Zvamp_Knife'.static.InitDefaults();
	class'Zvamp_Syringe'.static.InitDefaults();
	class'Zvamp_Camera'.static.InitDefaults();

	if (bZvampCompatDefaultsApplied)
		return;

	if (class'Zvamp_Knife'.default.bEnabled)
	{
		ConsoleCommand("set KFWeap_Knife_Berserker MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Commando MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Demolitionist MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_FieldMedic MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Firebug MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Gunslinger MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Sharpshooter MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Support MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_Survivalist MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Knife_SWAT MovementSpeedMod "$class'Zvamp_Knife'.default.MovespeedMultiplier);
		ConsoleCommand("set KFWeap_Edged_Knife ParryDamageMitigationPercent "$class'Zvamp_Knife'.default.ParryBlockMultiplier);
		ConsoleCommand("set KFWeap_Edged_Knife BlockDamageMitigation "$class'Zvamp_Knife'.default.ParryBlockMultiplier);
		`log("[Zvamp] knife compatibility enabled: move="$class'Zvamp_Knife'.default.MovespeedMultiplier@"parryBlock="$class'Zvamp_Knife'.default.ParryBlockMultiplier);
	}

	if (class'Zvamp_Syringe'.default.bEnabled)
	{
		ConsoleCommand("set KFWeap_Healer_Syringe HealAmount "$class'Zvamp_Syringe'.default.OthersHealAmount);
		ConsoleCommand("set KFWeap_Healer_Syringe HealRechargeTime "$class'Zvamp_Syringe'.default.HealOthersRechargeSeconds);
		ConsoleCommand("set KFWeap_HealerBase HealAmount "$class'Zvamp_Syringe'.default.OthersHealAmount);
		ConsoleCommand("set KFWeap_HealerBase HealRechargeTime "$class'Zvamp_Syringe'.default.HealOthersRechargeSeconds);
		`log("[Zvamp] syringe compatibility enabled: selfHeal="$class'Zvamp_Syringe'.default.StandAloneHealAmount@"otherHeal="$class'Zvamp_Syringe'.default.OthersHealAmount@"selfRecharge="$class'Zvamp_Syringe'.default.HealSelfRechargeSeconds@"otherRecharge="$class'Zvamp_Syringe'.default.HealOthersRechargeSeconds);
	}

	if (class'Zvamp_Camera'.default.bEnabled)
		`log("[Zvamp] camera compatibility enabled.");

	bZvampCompatDefaultsApplied = true;
}

function PostBeginPlay()
{
	local xVotingHandler MV;
	local int i,j;
	local class<Ext_PerkBase> PK;
	local UniqueNetId Id;
	local KFCharacterInfo_Human CH;
	local ObjectReferencer OR;
	local Object O;
	local string S;
	local bool bLock;

	Super.PostBeginPlay();
	if (!bSMLRuntimeActor)
	{
		if (WorldInfo.Game.BaseMutator==None)
			WorldInfo.Game.BaseMutator = Self;
		else WorldInfo.Game.BaseMutator.AddMutator(Self);
	}
	else
	{
		`log("[SMLCompat] ServerExtMut runtime actor mode; not adding to BaseMutator chain.");
	}

	if (bDeleteMe) // This was a duplicate instance of the mutator.
		return;

	if (!bZvampextUIOnly)
	{
		ApplyZvampCompatibilityDefaults();
	}
	else
	{
		`log("[Zvamp] UI-only mode enabled; skipping compatibility defaults, pawn replacement, and custom trader item injection.");
	}
	if (!bZvampextUIOnly)
		SetTimer(1.f,true,'MaintainSMLTraderFeatures');
	UpdateGrenadeTuningTimer();

	SpawnPointer = class'ExtSpawnPointHelper'.Static.FindHelper(WorldInfo); // Start init world pathlist.

	//OnlineSubsystemSteamworks(class'GameEngine'.Static.GetOnlineSubsystem()).Int64ToUniqueNetId("",Id);
	//`Log("TEST"@class'OnlineSubsystem'.Static.UniqueNetIdToString(Id));

	DevNetID.Length = DevList.Length;
	for (i=0; i<DevList.Length; ++i)
	{
		class'OnlineSubsystem'.Static.StringToUniqueNetId(DevList[i],Id);
		DevNetID[i] = Id;
	}
	ServerStatLoader = new (None) class'ExtPlayerStat';
	WorldInfo.Game.HUDType = class'KFExtendedHUD';
	WorldInfo.Game.PlayerControllerClass = class'ExtPlayerController';
	WorldInfo.Game.PlayerReplicationInfoClass = class'ExtPlayerReplicationInfo';
	if (!bZvampextUIOnly)
	{
		WorldInfo.Game.DefaultPawnClass = class'ExtHumanPawn';
		KFGameInfo(WorldInfo.Game).CustomizationPawnClass = class'ExtPawn_Customization';
	}
	KFGameInfo(WorldInfo.Game).KFGFxManagerClass = class'ExtMoviePlayer_Manager';

	KFGIA = new(KFGameInfo(WorldInfo.Game)) class'KFGI_Access';

	if (ServerMOTD=="")
		ServerMOTD = "Message of the Day";
	if (StatFileDir=="")
	{
		StatFileDir = "../../KFGame/Script/%s.usa";
		Default.StatFileDir = "../../KFGame/Script/%s.usa";
	}
	if (SettingsInit!=SettingsTagVer)
	{
		if (SettingsInit==0)
			ForcedMaxPlayers = 6;
		if (SettingsInit<2)
		{
			bKillMessages = true;
			bDamageMessages = true;
			LargeMonsterHP = 800;
		}
		if (SettingsInit<3)
			bEnableMapVote = true;
		if (SettingsInit<5)
		{
			StatAutoSaveWaves = 1;
			PerkClasses.Length = 10;
			PerkClasses[0] = PathName(class'Ext_PerkBerserker');
			PerkClasses[1] = PathName(class'Ext_PerkCommando');
			PerkClasses[2] = PathName(class'Ext_PerkFieldMedic');
			PerkClasses[3] = PathName(class'Ext_PerkSupport');
			PerkClasses[4] = PathName(class'Ext_PerkDemolition');
			PerkClasses[5] = PathName(class'Ext_PerkFirebug');
			PerkClasses[6] = PathName(class'Ext_PerkGunslinger');
			PerkClasses[7] = PathName(class'Ext_PerkSharpshooter');
			PerkClasses[8] = PathName(class'Ext_PerkSWAT');
			PerkClasses[9] = PathName(class'Ext_PerkSurvivalist');
		}
		else if (SettingsInit<11)
		{
			PerkClasses.AddItem(PathName(class'Ext_PerkSharpshooter'));
			PerkClasses.AddItem(PathName(class'Ext_PerkSWAT'));
			PerkClasses.AddItem(PathName(class'Ext_PerkSurvivalist'));
		}
		else if (SettingsInit==11)
			PerkClasses.AddItem(PathName(class'Ext_PerkSurvivalist'));
		if (SettingsInit<6)
		{
			MinUnloadPerkLevel = 25;
			UnloadPerkExpCost = 0.1;
		}
		if (SettingsInit<8)
		{
			AdminCommands.Length = 2;
			AdminCommands[0] = "Kick:Kick Player";
			AdminCommands[1] = "KickBan:Kick-Ban Player";
		}
		if (SettingsInit<9)
			MaxTopPlayers = 50;

		if (SettingsInit < 14)
		{
			bThrowAllWeaponsOnDeath = False;
		}
		if (SettingsInit < 15)
		{
			AdminGrenadeDamageValue = 1.f;
			AdminGrenadeRadiusValue = 1.f;
			AdminGrenadeThrowRangeValue = 1.f;
			AdminAmmoPickupValue = 1.f;
			AdminItemPickupValue = 1.f;
			AdminArmorPickupValue = 1.f;
		}
		if (SettingsInit < 16)
		{
			DoshThrowAmount = 50;
		}
		if (SettingsInit < 17)
		{
			bPlayerProgressWaveVoteEnabled = true;
			PlayerProgressWaveVoteMax = 5;
			PlayerProgressWaveVotePct = 0.51;
			PlayerProgressWaveVoteSeconds = 20;
			bNextMapChoiceEnabled = false;
			NextMapChoiceWave = 0;
			NextMapChoicePct = 0.51;
			NextMapChoiceSeconds = 20;
		}
		if (SettingsInit < 18)
		{
			AdminAmmoBoxCountValue = 0.f;
			AdminItemBoxCountValue = 0.f;
			AdminPickupRespawnTimeValue = 30.f;
			AdminGrenadesFromAmmoValue = 1.f;
			AdminAmmoBoxArmorValue = 0.25f;
		}
		SettingsInit = SettingsTagVer;
		SaveConfig();
	}
	if (EnsureCoreRPGPerkClasses())
		SaveConfig();

	for (i=0; i<PerkClasses.Length; ++i)
	{
		PK = class<Ext_PerkBase>(DynamicLoadObject(PerkClasses[i],class'Class'));
		if (PK!=None)
		{
			LoadedPerks.AddItem(PK);
			PK.Static.CheckConfig();
		}
	}
	j = 0;
	for (i=0; i<CustomChars.Length; ++i)
	{
		bLock = Left(CustomChars[i],1)=="*";
		S = (bLock ? Mid(CustomChars[i],1) : CustomChars[i]);
		CH = KFCharacterInfo_Human(DynamicLoadObject(S,class'KFCharacterInfo_Human',true));
		if (CH!=None)
		{
			CustomCharList.Length = j+1;
			CustomCharList[j].bLock = bLock;
			CustomCharList[j].Char = CH;
			++j;
			continue;
		}

		OR = ObjectReferencer(DynamicLoadObject(S,class'ObjectReferencer'));
		if (OR!=None)
		{
			foreach OR.ReferencedObjects(O)
			{
				if (KFCharacterInfo_Human(O)!=None)
				{
					CustomCharList.Length = j+1;
					CustomCharList[j].bLock = bLock;
					CustomCharList[j].Char = KFCharacterInfo_Human(O);
					CustomCharList[j].Ref = OR;
					++j;
				}
			}
		}
	}

	// Bonus (pong) game contents.
	if (BonusGameSongs.Length>0)
	{
		BonusGameCue = SoundCue(DynamicLoadObject(BonusGameSongs[Rand(BonusGameSongs.Length)],class'SoundCue'));
	}
	if (BonusGameFX.Length>0)
	{
		BonusGameFXObj = DynamicLoadObject(BonusGameFX[Rand(BonusGameFX.Length)],class'Object');
		if (SoundCue(BonusGameFXObj)==None && ObjectReferencer(BonusGameFXObj)==None) // Check valid type.
			BonusGameFXObj = None;
	}

	if (ForcedMaxPlayers>0)
	{
		SetMaxPlayers();
		SetTimer(0.001,false,'SetMaxPlayers');
	}
	bRespawnCheck = (PlayerRespawnTime>0);
	if (bRespawnCheck)
		SetTimer(1,true);
	if (bEnableMapVote)
	{
		foreach DynamicActors(class'xVotingHandler',MV)
			break;
		if (MV==None)
			MV = Spawn(class'xVotingHandler');
		MV.BaseMutator = Class;
	}
	SetTimer(1,true,'CheckWave');
	SetTimer(1,true,'AutoMessageTick');
	if (!bZvampextUIOnly)
	{
		SetTimer(1,false,'ApplyZvampextTraderItems');
	}
	if (!bNoWebAdmin && WorldInfo.NetMode!=NM_StandAlone)
		SetTimer(0.1,false,'SetupWebAdmin');

	if (bDumpXMLStats)
		FileOutput = Spawn(class'ExtXMLOutput');

	UpdateCustomZedXPArray();
	// Causes bugs
	// SetTimer(0.1,'CheckPickupFactories')
}

function ApplyZvampextTraderItems()
{
	RefreshZvampextTraderItems();
}

function int RefreshZvampextTraderItems(optional bool bForceRefresh, optional PlayerController Sender)
{
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TraderItems;
	local int i;
	local int Added;
	local STraderItem NewItem;
	local Zvamp_CustomItems CustomItems;
	local int StorePrice;
	local bool bChanged;

	if (bZvampextTraderItemsApplied && !bForceRefresh)
	{
		return 0;
	}

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None || KFGRI.TraderItems == None)
	{
		SetTimer(1,false,'ApplyZvampextTraderItems');
		return 0;
	}

	CustomItems = new(None) class'Zvamp_CustomItems';
	TraderItems = KFGRI.TraderItems;

	for (i = 0; i < CustomItems.Item.Length; ++i)
	{
		if (BuildZvampextTraderItem(CustomItems.Item[i], NewItem))
		{
			if (TraderItems.SaleItems.Find('WeaponDef', NewItem.WeaponDef) != INDEX_NONE
				|| TraderItems.SaleItems.Find('ClassName', NewItem.ClassName) != INDEX_NONE)
			{
				StorePrice = GetZvampextStorePrice(CustomItems, CustomItems.Item[i]);
				if (StorePrice >= 0)
				{
					ApplyZvampextStorePriceToTraderItems(TraderItems, NewItem, StorePrice);
					bChanged = true;
				}
				continue;
			}

			StorePrice = GetZvampextStorePrice(CustomItems, CustomItems.Item[i]);
			if (StorePrice >= 0)
			{
				ApplyZvampextStorePrice(NewItem.WeaponDef, StorePrice);
				bChanged = true;
			}

			NewItem.ItemID = GetNextZvampextTraderItemID(TraderItems);
			TraderItems.SaleItems.AddItem(NewItem);
			++Added;
			LogZvampextTraderItem("added custom trader item: "$CustomItems.Item[i], NewItem);
		}
		else
		{
			`log("[Zvamp] skipped custom trader item, could not load weapon def/class: "$CustomItems.Item[i]);
		}
	}

	if (Added > 0 || bChanged)
	{
		TraderItems.SetItemsInfo(TraderItems.SaleItems);
		KFGRI.TraderItems = TraderItems;
		KFGRI.bForceNetUpdate = true;
	}

	bZvampextTraderItemsApplied = true;
	if (Sender != None)
	{
		Sender.ClientMessage("[Zvamp] custom trader items refreshed; added "$Added$" new item(s).", 'Priority');
	}

	return Added;
}

final function ApplyZvampextStorePrice(class<KFWeaponDefinition> WeaponDef, int StorePrice)
{
	local string DefPath;
	local int OldPrice;

	if (WeaponDef == None || StorePrice < 0)
	{
		return;
	}

	DefPath = NormalizeZvampextClassPath(PathName(WeaponDef));
	OldPrice = WeaponDef.default.BuyPrice;
	ConsoleCommand("set" @ DefPath @ "BuyPrice" @ StorePrice);
	`log("[Zvamp] custom item price override: "$DefPath@"old="$OldPrice@"new="$StorePrice@"effective="$WeaponDef.default.BuyPrice);
}

final function ApplyZvampextStorePriceToTraderItems(out KFGFxObject_TraderItems TraderItems, const out STraderItem MatchItem, int StorePrice)
{
	local int i;

	ApplyZvampextStorePrice(MatchItem.WeaponDef, StorePrice);
	for (i = 0; i < TraderItems.SaleItems.Length; ++i)
	{
		if ((MatchItem.WeaponDef != None && TraderItems.SaleItems[i].WeaponDef == MatchItem.WeaponDef)
			|| (MatchItem.ClassName != '' && TraderItems.SaleItems[i].ClassName == MatchItem.ClassName))
		{
			ApplyZvampextStorePrice(TraderItems.SaleItems[i].WeaponDef, StorePrice);
		}
	}
}

final function string NormalizeZvampextClassPath(string ClassPath)
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

final function int GetZvampextStorePrice(Zvamp_CustomItems CustomItems, string ItemPath)
{
	local int i;
	local string PricePath;
	local int PriceValue;

	if (CustomItems == None)
	{
		return -1;
	}

	for (i = 0; i < CustomItems.StorePrice.Length; ++i)
	{
		if (ParseZvampextStorePrice(CustomItems.StorePrice[i], PricePath, PriceValue)
			&& PricePath ~= ItemPath)
		{
			return PriceValue;
		}
	}

	return -1;
}

final function bool ParseZvampextStorePrice(string Row, out string ItemPath, out int PriceValue)
{
	local int SplitAt;
	local string PriceText;

	Row = TrimAdminID(Row);
	SplitAt = InStr(Row, "=");
	if (SplitAt == INDEX_NONE)
	{
		SplitAt = InStr(Row, ":");
	}
	if (SplitAt == INDEX_NONE)
	{
		return false;
	}

	ItemPath = TrimAdminID(Left(Row, SplitAt));
	PriceText = TrimAdminID(Mid(Row, SplitAt + 1));
	PriceValue = int(PriceText);
	return (ItemPath != "" && PriceValue >= 0);
}

final function LogZvampextTraderItem(string Prefix, const out STraderItem Item)
{
	local int i;
	local string PerkNames;

	for (i = 0; i < Item.AssociatedPerkClasses.Length; ++i)
	{
		if (PerkNames != "")
		{
			PerkNames $= ",";
		}
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

final function int GetNextZvampextTraderItemID(KFGFxObject_TraderItems TraderItems)
{
	local int ItemID;

	ItemID = TraderItems.SaleItems.Length;
	while (TraderItems.SaleItems.Find('ItemID', ItemID) != INDEX_NONE)
	{
		++ItemID;
	}

	return ItemID;
}

final function bool BuildZvampextTraderItem(string WeaponDefPath, out STraderItem NewItem)
{
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> WeaponClass;
	local class<KFWeap_DualBase> DualClass;
	local array<STraderItemWeaponStats> WeaponStats;
	local string CandidateDefPath;
	local int DotPos;
	local string PackageName;
	local string ClassName;

	WeaponDefPath = TrimAdminID(WeaponDefPath);
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

	if (WeaponClass == None)
	{
		return false;
	}
	if (WeaponDef == None)
	{
		return false;
	}

	NewItem.WeaponDef = WeaponDef;
	NewItem.ClassName = WeaponClass.Name;

	DualClass = class<KFWeap_DualBase>(WeaponClass);
	if (DualClass != None && DualClass.default.SingleClass != None)
	{
		NewItem.SingleClassName = DualClass.default.SingleClass.Name;
	}
	else
	{
		NewItem.SingleClassName = WeaponClass.Name;
	}

	NewItem.DualClassName = WeaponClass.default.DualClass != None ? WeaponClass.default.DualClass.Name : '';
	NewItem.AssociatedPerkClasses = WeaponClass.static.GetAssociatedPerkClasses();
	NormalizeZvampextAssociatedPerks(NewItem.AssociatedPerkClasses);
	if (NewItem.AssociatedPerkClasses.Find(class'KFPerk_Survivalist') == INDEX_NONE)
	{
		NewItem.AssociatedPerkClasses.AddItem(class'KFPerk_Survivalist');
	}
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

final function NormalizeZvampextAssociatedPerks(out array<class<KFPerk> > AssociatedPerks)
{
	local int i;
	local int j;

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

function UpdateCustomZedXPArray()
{
	local int i;
	local CustomZedXPStruct zedxp;
	CustomZedXPArray.Length = 0;
	// Custom XP for custom zeds
	for (i=0;i<CustomZedXP.Length;i++)
	{
		zedxp.zedclass = class<KFPawn_Monster>(DynamicLoadObject(CustomZedXP[i].zed,Class'Class'));
		if (zedxp.zedclass == none)
		{
			`log("Error loading"@CustomZedXP[i].zed);
			continue;
		}
		zedxp.XPValues[0] = CustomZedXP[i].XP1;
		zedxp.XPValues[1] = CustomZedXP[i].XP2;
		zedxp.XPValues[2] = CustomZedXP[i].XP3;
		zedxp.XPValues[3] = CustomZedXP[i].XP4;
		CustomZedXPArray.AddItem(zedxp);
		`log("CustomXP: Loaded"@PathName(zedxp.zedclass));
	}
}

static final function string GetStatFile(const out UniqueNetId UID)
{
	return Repl(Default.StatFileDir,"%s","U_"$class'OnlineSubsystem'.Static.UniqueNetIdToString(UID));
}

final function bool IsDev(const out UniqueNetId UID)
{
	local int i;

	for (i=(DevNetID.Length-1); i>=0; --i)
		if (DevNetID[i]==UID)
			return true;
	return false;
}

static final function string TrimAdminID(string S)
{
	local int i;

	i = InStr(S,";");
	if (i!=-1)
		S = Left(S,i);
	while (Len(S)>0 && (Left(S,1)==" " || Left(S,1)==Chr(9)))
		S = Mid(S,1);
	while (Len(S)>0 && (Right(S,1)==" " || Right(S,1)==Chr(9)))
		S = Left(S,Len(S)-1);
	return S;
}

static final function int HexDigit(string S)
{
	S = Caps(S);
	switch (S)
	{
	case "0": return 0;
	case "1": return 1;
	case "2": return 2;
	case "3": return 3;
	case "4": return 4;
	case "5": return 5;
	case "6": return 6;
	case "7": return 7;
	case "8": return 8;
	case "9": return 9;
	case "A": return 10;
	case "B": return 11;
	case "C": return 12;
	case "D": return 13;
	case "E": return 14;
	case "F": return 15;
	}
	return 0;
}

static final function string DecimalDouble(string S)
{
	local int i,D,C,V;
	local string R;

	C = 0;
	for (i=Len(S)-1; i>=0; --i)
	{
		D = int(Mid(S,i,1));
		V = D*2+C;
		R = string(V%10)$R;
		C = V/10;
	}
	if (C>0)
		R = string(C)$R;
	return R;
}

static final function string DecimalAddSmall(string S, int Add)
{
	local int i,D,C,V;
	local string R;

	C = Add;
	for (i=Len(S)-1; i>=0; --i)
	{
		D = int(Mid(S,i,1));
		V = D+C;
		R = string(V%10)$R;
		C = V/10;
	}
	while (C>0)
	{
		R = string(C%10)$R;
		C = C/10;
	}
	while (Len(R)>1 && Left(R,1)=="0")
		R = Mid(R,1);
	return R;
}

static final function string HexToDecimalString(string Hex)
{
	local int i,j,N;
	local string R;

	R = "0";
	if (Left(Hex,2)~="0x")
		j = 2;
	for (i=j; i<Len(Hex); ++i)
	{
		for (N=0; N<4; ++N)
			R = DecimalDouble(R);
		R = DecimalAddSmall(R,HexDigit(Mid(Hex,i,1)));
	}
	return R;
}

static final function int HexToAccountInt(string Hex)
{
	local int i,j,R;

	j = Max(Len(Hex)-8,0);
	for (i=j; i<Len(Hex); ++i)
		R = R*16+HexDigit(Mid(Hex,i,1));
	return R;
}

static final function string HexToSteam2String(string Hex)
{
	local int Account,Y,Z;

	Account = HexToAccountInt(Hex);
	Y = Account%2;
	Z = Account/2;
	return "STEAM_0:"$Y$":"$Z;
}

final function bool AdminIDMatches(string ConfigID, string HexID, string Steam64ID, string Steam2ID)
{
	ConfigID = TrimAdminID(ConfigID);
	if (ConfigID=="" || ConfigID~="0x0000000000000000")
		return false;
	if (ConfigID ~= HexID || ConfigID ~= Steam64ID || ConfigID ~= Steam2ID)
		return true;
	return false;
}

final function bool IsRevampAdmin(const out UniqueNetId UID)
{
	local int i;
	local string HexID,Steam64ID,Steam2ID;

	HexID = class'OnlineSubsystem'.Static.UniqueNetIdToString(UID);
	Steam64ID = HexToDecimalString(HexID);
	Steam2ID = HexToSteam2String(HexID);
	for (i=(RevampAdminSteamIDs.Length-1); i>=0; --i)
		if (AdminIDMatches(RevampAdminSteamIDs[i],HexID,Steam64ID,Steam2ID))
			return true;
	for (i=(ZvampextAdminIDs.Length-1); i>=0; --i)
		if (AdminIDMatches(ZvampextAdminIDs[i],HexID,Steam64ID,Steam2ID))
			return true;
	return false;
}

final function GrantRevampAdminIfConfigured(ExtPlayerReplicationInfo PRI)
{
	local ExtPlayerController PC;

	if (PRI==None || !IsRevampAdmin(PRI.UniqueId))
		return;

	PC = ExtPlayerController(PRI.Owner);
	PRI.bAdmin = true;
	PRI.AdminType = AT_Admin;
	PRI.bForceNetUpdate = true;
	`Log("Zvampext: granted admin UI access to "$PRI.PlayerName@"("$class'OnlineSubsystem'.Static.UniqueNetIdToString(PRI.UniqueId)$")");
	if (bZvampextAutoEnableCheats && PC!=None)
	{
		PC.AddCheats(true);
		PC.ClientMessage("Zvampext admin cheats enabled.",'Priority');
		`Log("Zvampext: enabled admin cheats for "$PRI.PlayerName);
	}
}

function CheckWave()
{
	if (KF==None)
	{
		KF = KFGameReplicationInfo(WorldInfo.GRI);
		if (KF==None)
			return;
	}
	if (LastWaveNum!=KF.WaveNum)
	{
		LastWaveNum = KF.WaveNum;
		NotifyWaveChange();
	}
	if (!bGameHasEnded && KF.bMatchIsOver) // HACK, since KFGameInfo_Survival doesn't properly notify mutators of this!
	{
		SaveAllPerks(true);
		bGameHasEnded = true;
	}
}

function NotifyWaveChange()
{
	local ExtPlayerController ExtPC;
	local KFProj_RicochetStickBullet KFBolt;

	if (bRespawnCheck)
	{
		bIsPostGame = (KF.WaveMax<KF.WaveNum);
		bRespawnCheck = (!bIsPostGame || PostGameRespawnCost>=0);
		if (bRespawnCheck)
			SavePlayerInventory();
	}
	if (StatAutoSaveWaves>0 && ++NumWaveSwitches>=StatAutoSaveWaves)
	{
		NumWaveSwitches = 0;
		SaveAllPerks();
	}

	if (bNextMapChoiceEnabled && !bNextMapChoiceOffered && NextMapChoiceWave>0 && KF.WaveNum>=NextMapChoiceWave)
		StartNextMapChoiceVote();

	if (!KF.bTraderIsOpen)
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',ExtPC)
			ExtPC.bSetPerk = false;
	}

	foreach WorldInfo.AllActors(class'KFProj_RicochetStickBullet', KFBolt)
	{
		if (KFProj_Bolt_CompoundBowSharp(KFBolt) != none ||
			KFProj_Bolt_Crossbow(KFBolt) != none)
			KFBolt.Destroy();
	}
}

function SetupWebAdmin()
{
	local WebServer W;
	local WebAdmin A;
	local ExtWebApp xW;
	local byte i;

	foreach AllActors(class'WebServer',W)
		break;
	if (W!=None)
	{
		for (i=0; (i<10 && A==None); ++i)
			A = WebAdmin(W.ApplicationObjects[i]);
		if (A!=None)
		{
			xW = new (None) class'ExtWebApp';
			xW.MyMutator = Self;
			A.addQueryHandler(xW);
		}
		else `Log("ExtWebAdmin ERROR: No valid WebAdmin application found!");
	}
	else `Log("ExtWebAdmin ERROR: No WebServer object found!");
}

function SetMaxPlayers()
{
	local OnlineGameSettings GameSettings;

	WorldInfo.Game.MaxPlayers = ForcedMaxPlayers;
	WorldInfo.Game.MaxPlayersAllowed = ForcedMaxPlayers;
	if (WorldInfo.Game.GameInterface!=None)
	{
		GameSettings = WorldInfo.Game.GameInterface.GetGameSettings(WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
		if (GameSettings!=None)
			GameSettings.NumPublicConnections = ForcedMaxPlayers;
	}
}

function AddMutator(Mutator M)
{
	if (M!=Self) // Make sure we don't get added twice.
	{
		if (M.Class==Class)
			M.Destroy();
		else Super.AddMutator(M);
	}
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	return string(class'SML_ServerExtMutActor');
}

function bool IsFromMod(Object O)
{
	local string PackageName;

	if (O == None)
		return false;

	PackageName = string(O.GetPackageName());
	if (Len(PackageName)>1 && InStr(Caps(PackageName), "KF") == 0)
	{
		PackageName = string(O);
		if (Len(PackageName)>1 && InStr(Caps(PackageName), "KF") == 0)
			return false;
	}

	return true;
}

function bool HasModsInDamageInfo(DamageInfo DI)
{
	local class<Actor>  DamageCauser;
	local class<KFDamageType> DamageType;

	foreach DI.DamageCausers(DamageCauser)
		if (IsFromMod(DamageCauser))
			return true;

	foreach DI.DamageTypes(DamageType)
		if (IsFromMod(DamageType))
			return true;

	return false;
}

function CustomXP(Controller Killer, Controller Killed)
{
	local KFPlayerController KFPC;
	local KFPawn_Monster KFM;
	local int i;
	local KFPlayerReplicationInfo DamagerKFPRI;
	local float XP;
	local KFPerk InstigatorPerk;
	local DamageInfo DamageInfo;
	local class<KFPerk> DamagePerk;

	KFM = KFPawn_Monster(Killed.Pawn);
	foreach KFM.DamageHistory(DamageInfo)
	{
		DamagerKFPRI = KFPlayerReplicationInfo(DamageInfo.DamagerPRI);
		if (DamagerKFPRI == None) continue;

		// if no mods - exit the loop, the game will add experience by itself
		if (!HasModsInDamageInfo(DamageInfo) && !KFGIA.IsCustomZed(KFM.class)) continue;

		KFPC = KFPlayerController(DamagerKFPRI.Owner);
		if (KFPC == None) continue;

		i = CustomZedXPArray.Find('zedclass', KFM.Class);
		if (i != INDEX_NONE)
		{
			XP = CustomZedXPArray[i].XPValues[MyKFGI.GameDifficulty];
		}
		else
		{
			XP = KFM.static.GetXPValue(MyKFGI.GameDifficulty);
		}

		InstigatorPerk = KFPC.GetPerk();

		// Special for survivalist - he gets experience for everything
		// and for TF2Sentry - it has no perk in DamageHistory
		if (InstigatorPerk.ShouldGetAllTheXP() || DamageInfo.DamagePerks.Length == 0)
		{
			KFPC.OnPlayerXPAdded(XP, InstigatorPerk.Class);
			continue;
		}

		XP /= DamageInfo.DamagePerks.Length;
		foreach DamageInfo.DamagePerks(DamagePerk)
		{
			KFPC.OnPlayerXPAdded(FCeil(XP), DamagePerk);
		}
	}
}

function ScoreKill(Controller Killer, Controller Killed)
{
	local KFPlayerController  KFPC;
	local ExtPlayerController ExtPC;
	local ExtPerkManager      KillersPerk;
	local KFPawn_Monster      KFPM;

	if (bRespawnCheck && Killed.bIsPlayer)
		CheckRespawn(Killed);

	KFPM = KFPawn_Monster(Killed.Pawn);
	if (KFPM != None && Killed.GetTeamNum() != 0
	&& Killer != None && Killer.bIsPlayer && Killer.GetTeamNum() == 0)
	{
		ExtPC = ExtPlayerController(Killer);
		if (ExtPC != None && ExtPC.ActivePerkManager != None)
			ExtPC.ActivePerkManager.PlayerKilled(KFPM, LastKillDamageType);

		if (bKillMessages && Killer.PlayerReplicationInfo != None)
			BroadcastKillMessage(Killed.Pawn, Killer);

		CustomXP(Killer, Killed);
	}

	if (MyKFGI != None && MyKFGI.IsZedTimeActive() && KFPM != None)
	{
		KFPC = KFPlayerController(Killer);
		if (KFPC != None)
		{
			KillersPerk = ExtPerkManager(KFPC.GetPerk());
			if (MyKFGI.ZedTimeRemaining > 0.f && KillersPerk != None && KillersPerk.GetZedTimeExtensions(KFPC.GetLevel() ) > MyKFGI.ZedTimeExtensionsUsed)
			{
				MyKFGI.DramaticEvent(1.0);
				MyKFGI.ZedTimeExtensionsUsed++;
			}
		}
	}

	ExtPC = ExtPlayerController(Killed);
	if (ExtPC != None)
		CheckPerkChange(ExtPC);

	if (NextMutator != None)
		NextMutator.ScoreKill(Killer, Killed);
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	if ((KFPawn_Human(Killed)!=None && CheckPreventDeath(KFPawn_Human(Killed),Killer,damageType)) || Super.PreventDeath(Killed,Killer,damageType,HitLocation))
		return true;

	LastKillDamageType = damageType;
	if (Killed.Controller!=None && KFPawn_Monster(Killed)!=None)
	{
		// Hack for when pet kills a zed.
		if (Killed.GetTeamNum()!=0)
		{
			if (Killer!=None && Killer!=Killed.Controller && Killer.GetTeamNum()==0 && Ext_T_MonsterPRI(Killer.PlayerReplicationInfo)!=None)
				GT_PlayerKilled(Ext_T_MonsterPRI(Killer.PlayerReplicationInfo).OwnerController,Killed.Controller,damageType);
		}
		// Broadcast pet's deathmessage.
		else if (Killed.PlayerReplicationInfo!=None && PlayerController(Killed.Controller)==None && damageType!=class'KFDT_Healing')
			BroadcastFFDeath(Killer,Killed,damageType);
	}
	return false;
}

// Replica of KFGameInfo.Killed base.
final function GT_PlayerKilled(Controller Killer, Controller Killed, class<DamageType> damageType)
{
	local ExtPlayerController KFPC;
	local KFPawn_Monster MonsterPawn;
	local KFGameInfo KFG;

	KFG = KFGameInfo(WorldInfo.Game);
	ScoreKill(Killer,Killed); // Broadcast kill message.

	KFPC = ExtPlayerController(Killer);
	MonsterPawn = KFPawn_Monster(Killed.Pawn);
	if (KFG!=None && KFPC != none && MonsterPawn!=none)
	{
		//Chris: We have to do it earlier here because we need a damage type
		KFPC.AddZedKill(MonsterPawn.class, KFG.GameDifficulty, damageType, false);

		// Not support in v1096: KFGameInfo.CheckForBerserkerSmallRadiusKill
		//if (KFPC.ActivePerkManager!=none && KFPC.ActivePerkManager.CanEarnSmallRadiusKillXP(damageType))
		//	KFG.CheckForBerserkerSmallRadiusKill(MonsterPawn, KFPC);
	}
}

final function bool CheckPreventDeath(KFPawn_Human Victim, Controller Killer, class<DamageType> damageType)
{
	local ExtPlayerController E;

	if (Victim.IsA('KFPawn_Customization'))
		return false;
	E = ExtPlayerController(Victim.Controller);
	if (E!=None && E.bRevampGodMode)
	{
		Victim.Health = Max(Victim.Health, 1);
		return true;
	}
	return (E!=None && E.ActivePerkManager!=None && E.ActivePerkManager.CurrentPerk!=None && E.ActivePerkManager.CurrentPerk.PreventDeath(Victim,Killer,damageType));
}

final function BroadcastKillMessage(Pawn Killed, Controller Killer)
{
	local ExtPlayerController E;

	if (Killer==None || Killer.PlayerReplicationInfo==None)
		return;

	if (Killed.Default.Health>=LargeMonsterHP)
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			if (!E.bClientHideKillMsg)
				E.ReceiveKillMessage(Killed.Class,true,Killer.PlayerReplicationInfo);
	}
	else if (ExtPlayerController(Killer)!=None && !ExtPlayerController(Killer).bClientHideKillMsg)
		ExtPlayerController(Killer).ReceiveKillMessage(Killed.Class);
}

final function BroadcastFFDeath(Controller Killer, Pawn Killed, class<DamageType> damageType)
{
	local ExtPlayerController E;
	local PlayerReplicationInfo KillerPRI;
	local string P;
	local bool bFF;

	P = Killed.PlayerReplicationInfo.PlayerName;
	if (Killer==None || Killer==Killed.Controller)
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			E.ClientZedKillMessage(damageType,P);
		return;
	}
	bFF = (Killer.GetTeamNum()==0);
	KillerPRI = Killer.PlayerReplicationInfo;
	if (PlayerController(Killer)==None)
		KillerPRI = None;

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		E.ClientZedKillMessage(damageType,P,KillerPRI,Killer.Pawn.Class,bFF);
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
	local ExtPlayerController InjuredPC;

	if (NextMutator != None)
		NextMutator.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);

	if (KFPawn_Human(Injured)!=None)
	{
		InjuredPC = ExtPlayerController(Injured.Controller);
		if (InjuredPC!=None && InjuredPC.bRevampGodMode)
		{
			Damage = 0;
			Momentum = vect(0,0,0);
			return;
		}
	}

	if (LastDamageDealer!=None) // Make sure no other damagers interfear with the old thing going on.
	{
		ClearTimer('CheckDamageDone');
		CheckDamageDone();
	}
	if (KFPawn_Monster(Injured) != None && InstigatedBy != none && InstigatedBy.GetTeamNum() == Injured.GetTeamNum())
	{
		Momentum = vect(0,0,0);
		Damage = 0;
		return;
	}
	if (Damage>0 && InstigatedBy!=None)
	{
		if (bAdminGrenadeDamage && IsAdminGrenadeDamage(DamageType,DamageCauser))
			Damage = Max(Round(float(Damage) * AdminGrenadeDamageValue),0);

		if (KFPawn_Monster(Injured)!=None)
		{
			if (Injured.GetTeamNum()!=0)
			{
				LastDamageDealer = ExtPlayerController(InstigatedBy);
				if (bDamageMessages && LastDamageDealer!=None && !LastDamageDealer.bNoDamageTracking)
				{
					// Must delay this until next to get accurate damage dealt result.
					LastHitZed = KFPawn(Injured);
					LastHitHP = LastHitZed.Health;
					LastDamagePosition = HitLocation;
					SetTimer(0.001,false,'CheckDamageDone');
				}
				else
				{
					LastDamageDealer = None;
					// Give credits to pet's owner.
					if (Ext_T_MonsterPRI(InstigatedBy.PlayerReplicationInfo)!=None)
						HackSetHistory(KFPawn(Injured),Injured,Ext_T_MonsterPRI(InstigatedBy.PlayerReplicationInfo).OwnerController,Damage,HitLocation);
				}
			}
			else if (InstigatedBy.Pawn != None && KFPawn(InstigatedBy.Pawn).GetTeamNum() != KFPawn(Injured).GetTeamNum())
			{
				Momentum = vect(0,0,0);
				Damage = 0;
			}
		}
		else if (bDamageMessages && KFPawn_Human(Injured)!=None && Injured.GetTeamNum()==0 && InstigatedBy.GetTeamNum()!=0 && ExtPlayerController(InstigatedBy)!=None)
		{
			LastDamageDealer = ExtPlayerController(InstigatedBy);
			if (bDamageMessages && !LastDamageDealer.bClientHideNumbers)
			{
				// Must delay this until next to get accurate damage dealt result.
				LastHitZed = KFPawn(Injured);
				LastHitHP = LastHitZed.Health;
				LastDamagePosition = HitLocation;
				SetTimer(0.001,false,'CheckDamageDone');
			}
		}
	}
}

final function CheckDamageDone()
{
	local int Damage;

	if (LastDamageDealer!=None && LastHitZed!=None && LastHitHP!=LastHitZed.Health)
	{
		Damage = LastHitHP-Max(LastHitZed.Health,0);
		if (Damage>0)
		{
			if (!LastDamageDealer.bClientHideDamageMsg && KFPawn_Monster(LastHitZed)!=None)
				LastDamageDealer.ReceiveDamageMessage(LastHitZed.Class,Damage);
			if (!LastDamageDealer.bClientHideNumbers)
				LastDamageDealer.ClientNumberMsg(Damage,LastDamagePosition,DMG_PawnDamage);
		}
	}
	LastDamageDealer = None;
}

final function HackSetHistory(KFPawn C, Pawn Injured, Controller Player, int Damage, vector HitLocation)
{
	local int i;
	local ExtPlayerController PC;

	if (Player==None)
		return;
	PC = ExtPlayerController(Player);
	if (bDamageMessages && PC!=None)
	{
		if (!PC.bClientHideDamageMsg)
			PC.ReceiveDamageMessage(Injured.Class,Damage);
		if (!PC.bClientHideNumbers)
			PC.ClientNumberMsg(Damage,HitLocation,DMG_PawnDamage);
	}
	i = C.DamageHistory.Find('DamagerController',Player);
	if (i==-1)
	{
		i = C.DamageHistory.Length;
		C.DamageHistory.Length = i+1;
		C.DamageHistory[i].DamagerController = Player;
		C.DamageHistory[i].DamagerPRI = Player.PlayerReplicationInfo;
		C.DamageHistory[i].DamagePerks.AddItem(class'ExtPerkManager');
		C.DamageHistory[i].Damage = Damage;
	}
	else if ((WorldInfo.TimeSeconds-C.DamageHistory[i].LastTimeDamaged)<10)
		C.DamageHistory[i].Damage += Damage;
	else C.DamageHistory[i].Damage = Damage;

	C.DamageHistory[i].LastTimeDamaged = WorldInfo.TimeSeconds;
	C.DamageHistory[i].TotalDamage += Damage;
}

function bool HandleRestartGame()
{
	if (!bGameHasEnded)
	{
		SaveAllPerks(true);
		bGameHasEnded = true;
	}
	return Super.HandleRestartGame();
}

function NotifyLogout(Controller Exiting)
{
	if (KFPlayerController(Exiting)!=None)
		RemoveRespawn(Exiting);
	if (!bGameHasEnded && ExtPlayerController(Exiting)!=None)
	{
		CheckPerkChange(ExtPlayerController(Exiting));
		SavePlayerPerk(ExtPlayerController(Exiting));
	}
	if (NextMutator != None)
		NextMutator.NotifyLogout(Exiting);
}

function NotifyLogin(Controller NewPlayer)
{
	local ExtPlayerReplicationInfo EPRI;

	if (ExtPlayerController(NewPlayer)!=None)
	{
		EPRI = ExtPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
		if (EPRI!=None)
		{
			InitCustomChars(EPRI);
			GrantRevampAdminIfConfigured(EPRI);
		}
		if (EPRI!=None && bAddCountryTags && NetConnection(PlayerController(NewPlayer).Player)!=None)
			EPRI.SetPlayerNameTag(class'CtryDatabase'.Static.GetClientCountryStr(PlayerController(NewPlayer).GetPlayerNetworkAddress()));
		if (EPRI!=None)
			EPRI.bIsDev = IsDev(NewPlayer.PlayerReplicationInfo.UniqueId);
		if (BonusGameCue!=None || BonusGameFXObj!=None)
			ExtPlayerController(NewPlayer).ClientSetBonus(BonusGameCue,BonusGameFXObj);
		if (bRespawnCheck)
			CheckRespawn(NewPlayer);
		if (!bGameHasEnded)
			InitializePerks(ExtPlayerController(NewPlayer));
		if (!bZvampextUIOnly)
		{
			SendZvampextTraderItems(ExtPlayerController(NewPlayer));
		}
		SendMOTD(ExtPlayerController(NewPlayer));
	}
	if (NextMutator != None)
		NextMutator.NotifyLogin(NewPlayer);
}

final function InitializePerks(ExtPlayerController Other)
{
	local ExtPerkManager PM;
	local Ext_PerkBase P;
	local int i;

	Other.OnChangePerk = PlayerChangePerk;
	Other.OnBoughtStats = PlayerBuyStats;
	Other.OnBoughtTrait = PlayerBoughtTrait;
	Other.OnPerkReset = ResetPlayerPerk;
	Other.OnAdminHandle = AdminCommand;
	Other.OnAdminRevampAction = AdminRevampAction;
	Other.OnAdminSetTraderGuard = AdminSetTraderGuard;
	Other.OnAdminSetPickupOverrides = AdminSetPickupOverrides;
	Other.OnAdminSetGrenadeThrowRange = AdminSetGrenadeThrowRange;
	Other.OnAdminSetGrenadeTuning = AdminSetGrenadeTuning;
	Other.OnAdminSetResourceLimits = AdminSetResourceLimits;
		Other.OnAdminFastForwardTrader = AdminFastForwardTrader;
		Other.OnAdminOpenTrader = AdminOpenTrader;
		Other.OnPublicOpenTrader = PublicOpenTrader;
		Other.OnRefreshNewItems = RefreshNewItemsFor;
		Other.OnAdminGiveDosh = AdminGiveDosh;
		Other.OnAdminSetDoshThrowAmount = AdminSetDoshThrowAmount;
		Other.OnAdminProgressWave = AdminProgressWave;
		Other.OnAdminBuildID = AdminBuildID;
		Other.OnAdminSetAutoMessage = AdminSetAutoMessage;
		Other.OnPlayerProgressWaveVoteCall = PlayerProgressWaveVoteCall;
		Other.OnPlayerProgressWaveVoteAnswer = PlayerProgressWaveVoteAnswer;
		Other.OnPlayerNextMapVoteAnswer = PlayerNextMapVoteAnswer;
	Other.OnSetMOTD = AdminSetMOTD;
	Other.OnRequestUnload = PlayerUnloadInfo;
	Other.OnSpectateChange = PlayerChangeSpec;
	Other.OnClientGetStat = class'ExtStatList'.Static.GetStat;
	PM = Other.ActivePerkManager;
	if (PM==None)
	{
		PM = Other.Spawn(class'ExtPerkManager',Other);
		Other.ActivePerkManager = PM;
		PM.PlayerOwner = Other;
		PM.PRIOwner = ExtPlayerReplicationInfo(Other.PlayerReplicationInfo);
		if (PM.PRIOwner!=None)
			PM.PRIOwner.PerkManager = PM;
		PM.bForceNetUpdate = true;
		Other.bForceNetUpdate = true;
	}
	PM.InitPerks();
	for (i=0; i<LoadedPerks.Length; ++i)
	{
		P = Spawn(LoadedPerks[i],Other);
		PM.RegisterPerk(P);
	}
	ServerStatLoader.FlushData();
	if (ServerStatLoader.LoadStatFile(Other))
	{
		ServerStatLoader.ToStart();
		PM.LoadData(ServerStatLoader);
		if (Default.MaxTopPlayers>0)
			class'ExtStatList'.Static.SetTopPlayers(Other);
	}
	PM.ServerInitPerks();
	PM.InitiateClientRep();
	PM.ForceZvampextReplicationUpdate();
	if (PM.ZvampextNeedsReplicationKick())
		SetTimer(1.f,true,'ZvampextPerkReplicationWatchdog');
}

final function SendMOTD(ExtPlayerController PC)
{
	local string S;
	local int i;

	S = ServerMOTD;
	while (Len(S)>510)
	{
		PC.ReceiveServerMOTD(Left(S,500),false);
		S = Mid(S,500);
	}
	PC.ReceiveServerMOTD(S,true);

	for (i=0; i<AdminCommands.Length; ++i)
		PC.AddAdminCmd(AdminCommands[i]);
	PC.ClientSetRevampTraderGuard(bRevampTraderGuard,bRevampTraderGuardBlockSkip,bRevampTraderGuardPublicOpenTrader);
	PC.ClientSetVampUIEndMatchEnabled(bVampUIEndMatchEnabled);
	PC.ClientSetAdminPickupOverrides(bAdminGrenadeDamage,AdminGrenadeDamageValue,bAdminGrenadeRadius,AdminGrenadeRadiusValue,bAdminAmmoPickup,AdminAmmoPickupValue,bAdminItemPickup,AdminItemPickupValue,bAdminArmorPickup,AdminArmorPickupValue);
	PC.ClientSetAdminGrenadeThrowRange(bAdminGrenadeThrowRange,AdminGrenadeThrowRangeValue);
	PC.ClientSetAdminResourceLimits(bAdminAmmoBoxCount,AdminAmmoBoxCountValue,bAdminItemBoxCount,AdminItemBoxCountValue,bAdminPickupRespawnTime,AdminPickupRespawnTimeValue,bAdminGrenadesFromAmmo,AdminGrenadesFromAmmoValue,bAdminAmmoBoxArmor,AdminAmmoBoxArmorValue);
	PC.ClientRefreshZvampextSettings();
	ApplyPickupOverridesToController(PC);
	PC.ApplyPlayerDoshThrowAmount();
	PC.ClientSetZvampCamera(class'Zvamp_Camera'.default.bEnabled,class'Zvamp_Camera'.default.bDisableCamShakes,class'Zvamp_Camera'.default.bDisableSprintFOVChange,class'Zvamp_Camera'.default.bDisableEarsRinging,class'Zvamp_Camera'.default.bDisableCameraAnims,class'Zvamp_Camera'.default.ZedTimeEffectReduction);
	SendMidGameMenuLayout(PC);
	SendSpawnedPerkUILayout(PC);
}

final function SavePlayerPerk(ExtPlayerController PC)
{
	if (PC.ActivePerkManager!=None && PC.ActivePerkManager.bStatsDirty)
	{
		// Verify broken stats.
		if (PC.ActivePerkManager.bUserStatsBroken)
		{
			PC.ClientMessage("Warning: Your stats are broken, not saving.",'Priority');
			return;
		}
		ServerStatLoader.FlushData();
		if (ServerStatLoader.LoadStatFile(PC) && ServerStatLoader.GetSaveVersion()!=PC.ActivePerkManager.UserDataVersion)
		{
			PC.ActivePerkManager.bUserStatsBroken = true;
			PC.ClientMessage("Warning: Your stats save data version differs from what is loaded, stat saving disabled to prevent stats loss.",'Priority');
			return;
		}

		// Actually save.
		ServerStatLoader.FlushData();
		PC.ActivePerkManager.SaveData(ServerStatLoader);
		ServerStatLoader.SaveStatFile(PC);
		PC.ActivePerkManager.bStatsDirty = false;

		// Write XML output.
		if (FileOutput!=None)
			FileOutput.DumpXML(PC.ActivePerkManager);
	}
}

function SaveAllPerks(optional bool bOnEndGame)
{
	local ExtPlayerController PC;

	if (bGameHasEnded)
		return;
	foreach WorldInfo.AllControllers(class'ExtPlayerController',PC)
		if (PC.ActivePerkManager!=None && PC.ActivePerkManager.bStatsDirty)
		{
			if (bOnEndGame)
				CheckPerkChange(PC);
			SavePlayerPerk(PC);
		}
}

function CheckRespawn(Controller PC)
{
	if (!PC.bIsPlayer || ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)==None || PC.PlayerReplicationInfo.bOnlySpectator || WorldInfo.Game.bWaitingToStartMatch || WorldInfo.Game.bGameEnded)
		return;

	// VS redead.
	if (ExtHumanPawn(PC.Pawn)!=None && ExtHumanPawn(PC.Pawn).bPendingRedead)
		return;

	if (bIsPostGame && PC.PlayerReplicationInfo.Score<PostGameRespawnCost)
	{
		if (PlayerController(PC)!=None)
			PlayerController(PC).ClientMessage("You can't afford to respawn anymore (need "$PostGameRespawnCost@Chr(163)$")!",'LowCriticalEvent');
		return;
	}
	ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = PlayerRespawnTime;
	PC.PlayerReplicationInfo.bForceNetUpdate = true;
	if (PendingSpawners.Find(PC)<0)
		PendingSpawners.AddItem(PC);
}

function RemoveRespawn(Controller PC)
{
	ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
	PendingSpawners.RemoveItem(PC);
}

final function InitPlayer(ExtHumanPawn Other)
{
	local ExtPlayerReplicationInfo PRI;

	PRI = ExtPlayerReplicationInfo(Other.PlayerReplicationInfo);
	if (PRI!=None && PRI.PerkManager!=None && PRI.PerkManager.CurrentPerk!=None)
		PRI.PerkManager.CurrentPerk.ApplyEffectsTo(Other);
	Other.bRagdollFromFalling = bRagdollFromFall;
	Other.bRagdollFromMomentum = bRagdollFromMomentum;
	Other.bRagdollFromBackhit = bRagdollFromBackhit;
	Other.bThrowAllWeaponsOnDeath = bThrowAllWeaponsOnDeath;
}

function ModifyPlayer(Pawn Other)
{
	local ExtPlayerController PC;

	if (ExtHumanPawn(Other)!=None)
		InitPlayer(ExtHumanPawn(Other));
	ApplyPickupOverridesTo(Other);
	if (NextMutator != None)
		NextMutator.ModifyPlayer(Other);

	PC = ExtPlayerController(Other.Controller);
	if (PC!=None)
		PC.ApplyPlayerDoshThrowAmount();
	if (PC!=None && PC.ActivePerkManager!=None && PC.ActivePerkManager.ZvampextNeedsReplicationKick())
	{
		PC.ActivePerkManager.ZvampextKickClientReplication(true);
		SetTimer(1.f,true,'ZvampextPerkReplicationWatchdog');
	}
}

function ZvampextPerkReplicationWatchdog()
{
	local ExtPlayerController PC;
	local bool bNeedRetry;

	foreach WorldInfo.AllControllers(class'ExtPlayerController',PC)
	{
		if (PC!=None && PC.ActivePerkManager!=None && PC.ActivePerkManager.ZvampextNeedsReplicationKick())
		{
			PC.ActivePerkManager.ZvampextKickClientReplication();
			bNeedRetry = true;
		}
	}

	if (!bNeedRetry)
		ClearTimer('ZvampextPerkReplicationWatchdog');
}

final function HoldSMLTraderTimer(string Source)
{
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None || !KFGRI.bTraderIsOpen)
		return;

	if (!bSMLTraderAutoPaused)
	{
		bSMLTraderAutoPaused = true;
		SMLTraderPausedRemainingTime = Max(KFGRI.RemainingTime, 1);
		`log("[SMLCompat] trader auto-hold enabled by "$Source$".");
	}
	KFGRI.bStopCountDown = true;
	KFGRI.RemainingTime = Max(SMLTraderPausedRemainingTime, 1);
	KFGRI.bForceNetUpdate = true;
	if (KFGI != None && !bSMLTraderCloseTimerCleared)
	{
		KFGI.ClearTimer('CloseTraderTimer');
		bSMLTraderCloseTimerCleared = true;
		`log("[SMLCompat] trader close timer cleared on GameInfo by "$Source$".");
	}
}

function MaintainSMLTraderFeatures()
{
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None && KFGRI.bTraderIsOpen)
	{
		if (bZvampextAutoPauseTrader || bSMLTraderAutoPaused)
			HoldSMLTraderTimer("mutator monitor");
		ApplySMLTraderSpeedBoost();
	}
	else
	{
		bSMLTraderAutoPaused = false;
		bSMLTraderCloseTimerCleared = false;
		ClearSMLTraderSpeedBoost();
	}
}

function ReleaseSMLTraderPause()
{
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None)
	{
		KFGRI.bStopCountDown = false;
		KFGRI.bForceNetUpdate = true;
	}
	bSMLTraderAutoPaused = false;
	bSMLTraderCloseTimerCleared = false;
	SMLTraderPausedRemainingTime = 0;
}

function ApplySMLTraderSpeedBoost()
{
	local ExtHumanPawn P;
	local float SpeedBoostMod;

	SpeedBoostMod = class'Zvamp_Knife'.static.GetQuickTraderKnife();
	if (bZvampextTraderSpeedBoost)
		SpeedBoostMod = FMax(SpeedBoostMod, ZvampextTraderSpeedBoostMultiplier);
	SpeedBoostMod = FMax(SpeedBoostMod, 1.f);
	if (SpeedBoostMod <= 1.f)
	{
		ClearSMLTraderSpeedBoost();
		return;
	}

	foreach WorldInfo.AllPawns(class'ExtHumanPawn', P)
	{
		if (P != None && !P.bDeleteMe && P.IsAliveAndWell())
			P.SetZvampextTraderSpeedBoost(SpeedBoostMod);
	}
}

function ClearSMLTraderSpeedBoost()
{
	local ExtHumanPawn P;

	foreach WorldInfo.AllPawns(class'ExtHumanPawn', P)
	{
		if (P != None && P.ZvampextTraderSpeedBoostMod > 1.f)
			P.SetZvampextTraderSpeedBoost(1.f);
	}
}

function Timer()
{
	local int i;
	local Controller PC;
	local bool bSpawned,bAllDead;

	bAllDead = (KFGameInfo(WorldInfo.Game).GetLivingPlayerCount()<=0 || WorldInfo.Game.bGameEnded || !bRespawnCheck);
	for (i=0; i<PendingSpawners.Length; ++i)
	{
		PC = PendingSpawners[i];
		if (bAllDead || PC==None || PC.PlayerReplicationInfo.bOnlySpectator || (PC.Pawn!=None && PC.Pawn.IsAliveAndWell()))
		{
			if (PC!=None)
			{
				ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
				PC.PlayerReplicationInfo.bForceNetUpdate = true;
			}
			PendingSpawners.Remove(i--,1);
		}
		else if (bIsPostGame && PC.PlayerReplicationInfo.Score<PostGameRespawnCost)
		{
			ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
			PC.PlayerReplicationInfo.bForceNetUpdate = true;

			if (PlayerController(PC)!=None)
				PlayerController(PC).ClientMessage("You can't afford to respawn anymore (need "$PostGameRespawnCost@Chr(163)$")!",'LowCriticalEvent');
			PendingSpawners.Remove(i--,1);
		}
		else if (--ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter<=0)
		{
			PC.PlayerReplicationInfo.bForceNetUpdate = true;
			ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = 0;
			if (!bSpawned) // Spawn only one player at time (so game doesn't crash if many players spawn in same time).
			{
				bSpawned = true;
				if (RespawnPlayer(PC))
				{
					if (bIsPostGame)
					{
						if (PlayerController(PC)!=None)
							PlayerController(PC).ClientMessage("This respawn cost you "$PostGameRespawnCost@Chr(163)$"!",'LowCriticalEvent');
						PC.PlayerReplicationInfo.Score-=PostGameRespawnCost;
					}
					ExtPlayerReplicationInfo(PC.PlayerReplicationInfo).RespawnCounter = -1;
					PC.PlayerReplicationInfo.bForceNetUpdate = true;
				}
			}
		}
		else PC.PlayerReplicationInfo.bForceNetUpdate = true;
	}
}

final function SavePlayerInventory()
{
	local KFPawn_Human P;
	local int i,j;
	local Inventory Inv;
	local KFWeapon K;

	PlayerInv.Length = 0;
	i = 0;
	foreach WorldInfo.AllPawns(class'KFPawn_Human',P)
		if (P.IsAliveAndWell() && P.InvManager!=None && P.Controller!=None && P.Controller.PlayerReplicationInfo!=None)
		{
			PlayerInv.Length = i+1;
			PlayerInv[i].OwnerPlayer = P.Controller;
			PlayerInv[i].Gren = KFInventoryManager(P.InvManager).GrenadeCount;
			j = 0;

			foreach P.InvManager.InventoryActors(class'Inventory',Inv)
			{
				if (KFInventory_Money(Inv)!=None)
					continue;
				K = KFWeapon(Inv);
				if (K!=None && !K.bCanThrow) // Skip non-throwable items.
					continue;
				PlayerInv[i].Inv.Length = j+1;
				PlayerInv[i].Inv[j].ItemClass = Inv.Class;
				if (K!=None)
				{
					PlayerInv[i].Inv[j].Values[0] = K.SpareAmmoCount[0];
					PlayerInv[i].Inv[j].Values[1] = K.SpareAmmoCount[1];
					PlayerInv[i].Inv[j].Values[2] = K.AmmoCount[0];
					PlayerInv[i].Inv[j].Values[3] = K.AmmoCount[1];
				}
				++j;
			}
			++i;
		}
}

final function bool AddPlayerSpecificInv(Pawn Other)
{
	local int i,j;
	local Inventory Inv;
	local KFWeapon K;

	for (i=(PlayerInv.Length-1); i>=0; --i)
		if (PlayerInv[i].OwnerPlayer==Other.Controller)
		{
			KFInventoryManager(Other.InvManager).bInfiniteWeight = true;
			KFInventoryManager(Other.InvManager).GrenadeCount = PlayerInv[i].Gren;
			for (j=(PlayerInv[i].Inv.Length-1); j>=0; --j)
			{
				Inv = Other.InvManager.FindInventoryType(PlayerInv[i].Inv[j].ItemClass,false);
				if (Inv==None)
				{
					Inv = Other.InvManager.CreateInventory(PlayerInv[i].Inv[j].ItemClass);
				}
				K = KFWeapon(Inv);
				if (K!=None)
				{
					K.SpareAmmoCount[0] = PlayerInv[i].Inv[j].Values[0];
					K.SpareAmmoCount[1] = PlayerInv[i].Inv[j].Values[1];
					K.AmmoCount[0] = PlayerInv[i].Inv[j].Values[2];
					K.AmmoCount[1] = PlayerInv[i].Inv[j].Values[3];
					K.ClientForceAmmoUpdate(K.AmmoCount[0],K.SpareAmmoCount[0]);
					K.ClientForceSecondaryAmmoUpdate(K.AmmoCount[1]);
				}
			}
			if (Other.InvManager.FindInventoryType(class'KFInventory_Money',true)==None)
				Other.InvManager.CreateInventory(class'KFInventory_Money');
			KFInventoryManager(Other.InvManager).bInfiniteWeight = false;
			return true;
		}
	return false;
}

final function Pawn SpawnDefaultPawnfor (Controller NewPlayer, Actor StartSpot) // Clone of GameInfo one, but with Actor StartSpot.
{
	local class<Pawn> PlayerClass;
	local Rotator R;
	local Pawn ResultPawn;

	PlayerClass = WorldInfo.Game.GetDefaultPlayerClass(NewPlayer);
	R.Yaw = StartSpot.Rotation.Yaw;
	ResultPawn = Spawn(PlayerClass,,,StartSpot.Location,R,,true);
	return ResultPawn;
}

final function bool RespawnPlayer(Controller NewPlayer)
{
	local KFPlayerReplicationInfo KFPRI;
	local KFPlayerController KFPC;
	local Actor startSpot;
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local LocalPlayer LP;

	if (NewPlayer.Pawn!=None)
		NewPlayer.Pawn.Destroy();

	// figure out the team number and find the start spot
	StartSpot = SpawnPointer.PickBestSpawn();

	// if a start spot wasn't found,
	if (startSpot == None)
	{
		// check for a previously assigned spot
		if (NewPlayer.StartSpot != None)
		{
			StartSpot = NewPlayer.StartSpot;
			`warn("Player start not found, using last start spot");
		}
		else
		{
			// otherwise abort
			`warn("Player start not found, failed to restart player");
			return false;
		}
	}

	// try to create a pawn to use of the default class for this player
	NewPlayer.Pawn = SpawnDefaultPawnfor (NewPlayer, StartSpot);

	if (NewPlayer.Pawn == None)
	{
		NewPlayer.GotoState('Dead');
		if (PlayerController(NewPlayer) != None)
			PlayerController(NewPlayer).ClientGotoState('Dead','Begin');
		return false;
	}
	else
	{
		// initialize and start it up
		if (NavigationPoint(startSpot)!=None)
			NewPlayer.Pawn.SetAnchor(NavigationPoint(startSpot));
		if (PlayerController(NewPlayer) != None)
		{
			PlayerController(NewPlayer).TimeMargin = -0.1;
			if (NavigationPoint(startSpot)!=None)
				NavigationPoint(startSpot).AnchoredPawn = None; // SetAnchor() will set this since IsHumanControlled() won't return true for the Pawn yet
		}
		NewPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
		NewPlayer.Pawn.LastStartTime = WorldInfo.TimeSeconds;
		NewPlayer.Possess(NewPlayer.Pawn, false);
		NewPlayer.Pawn.PlayTeleportEffect(true, true);
		NewPlayer.ClientSetRotation(NewPlayer.Pawn.Rotation, TRUE);

		if (!WorldInfo.bNoDefaultInventoryForPlayer)
		{
			AddPlayerSpecificInv(NewPlayer.Pawn);
			WorldInfo.Game.AddDefaultInventory(NewPlayer.Pawn);
		}
		WorldInfo.Game.SetPlayerDefaults(NewPlayer.Pawn);

		// activate spawned events
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned',TRUE,Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None &&
					SpawnedEvent.CheckActivate(NewPlayer,NewPlayer))
				{
					SpawnedEvent.SpawnPoint = startSpot;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
	}

	KFPC = KFPlayerController(NewPlayer);
	KFPRI = KFPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);

	// To fix custom post processing chain when not running in editor or PIE.
	if (KFPC != none)
	{
		LP = LocalPlayer(KFPC.Player);
		if (LP != None)
		{
			LP.RemoveAllPostProcessingChains();
			LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true);
			if (KFPC.myHUD != None)
			{
				KFPC.myHUD.NotifyBindPostProcessEffects();
			}
		}
	}

	KFGameInfo(WorldInfo.Game).SetTeam(NewPlayer, KFGameInfo(WorldInfo.Game).Teams[0]);

	if (KFPC != none)
	{
		// Initialize game play post process effects such as damage, low health, etc.
		KFPC.InitGameplayPostProcessFX();
	}
	if (KFPRI!=None)
	{
		if (KFPRI.Deaths == 0)
			KFPRI.Score = KFGameInfo(WorldInfo.Game).DifficultyInfo.GetAdjustedStartingCash();
		KFPRI.PlayerHealth = NewPlayer.Pawn.Health;
		KFPRI.PlayerHealthPercent = FloatToByte(float(NewPlayer.Pawn.Health) / float(NewPlayer.Pawn.HealthMax));
	}
	return true;
}

function PlayerBuyStats(ExtPlayerController PC, class<Ext_PerkBase> Perk, int iStat, int Amount)
{
	local Ext_PerkBase P;
	local int i;

	if (bGameHasEnded)
		return;

	P = PC.ActivePerkManager.FindPerk(Perk);
	if (P==None || !P.bPerkNetReady || iStat>=P.PerkStats.Length)
		return;
	Amount = Max(Amount,1);
	Amount = Min(Amount,P.PerkStats[iStat].MaxValue-P.PerkStats[iStat].CurrentValue);
	if (Amount<=0)
		return;
	i = Amount*P.PerkStats[iStat].CostPerValue;
	if (i>P.CurrentSP)
	{
		Amount = P.CurrentSP/P.PerkStats[iStat].CostPerValue;
		if (Amount<=0)
			return;
		i = Amount*P.PerkStats[iStat].CostPerValue;
	}
	P.CurrentSP-=i;
	if (P.bOwnerNetClient)
		P.ClientSetCurrentSP(P.CurrentSP);
	if (!P.IncrementStat(iStat,Amount))
		PC.ClientMessage("Failed to buy stat.");
	else SavePlayerPerk(PC);
}

function PlayerChangePerk(ExtPlayerController PC, class<Ext_PerkBase> NewPerk)
{
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;

	if (bGameHasEnded)
		return;
	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (NewPerk==PC.ActivePerkManager.CurrentPerk.Class)
	{
		if (PC.PendingPerkClass!=None)
		{
			PC.ClientMessage("You will remain the same perk now.");
			PC.PendingPerkClass = None;
		}
	}
	else if (PC.ActivePerkManager.CurrentPerk==None || KFPawn_Customization(PC.Pawn)!=None
		|| (KFGRI!=None && KFGRI.bTraderIsOpen) || (KFGI!=None && KFGI.GetStateName()!='PlayingWave'))
	{
		if (PC.ActivePerkManager.ApplyPerkClass(NewPerk))
		{
			PC.ClientMessage("You have changed your perk to "$NewPerk.Default.PerkName);
			PC.bSetPerk = true;
		}
		else PC.ClientMessage("Invalid perk "$NewPerk.Default.PerkName);
	}
	else if (PC.bSetPerk)
		PC.ClientMessage("Can only change perks once per wave");
	else
	{
		PC.ClientMessage("You will change to perk '"$NewPerk.Default.PerkName$"' during trader time.");
		PC.PendingPerkClass = NewPerk;
	}
}

function CheckPerkChange(ExtPlayerController PC)
{
	if (PC.PendingPerkClass!=None)
	{
		if (PC.ActivePerkManager.ApplyPerkClass(PC.PendingPerkClass))
		{
			PC.ClientMessage("You have changed your perk to "$PC.PendingPerkClass.Default.PerkName);
			PC.bSetPerk = true;
		}
		else PC.ClientMessage("Invalid perk "$PC.PendingPerkClass.Default.PerkName);
		PC.PendingPerkClass = None;
	}
}

function Tick(float DeltaTime)
{
	local bool bCheckedWave;
	local ExtPlayerController ExtPC;

	if (KFGameReplicationInfo(WorldInfo.GRI).bTraderIsOpen && !bCheckedWave)
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController',ExtPC)
			CheckPerkChange(ExtPC);

		bCheckedWave = true;
	}
	else if (bCheckedWave)
		bCheckedWave = false;
}

function PlayerBoughtTrait(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait)
{
	local Ext_PerkBase P;
	local int i,cost;

	if (bGameHasEnded)
		return;

	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if (P==None || !P.bPerkNetReady)
		return;

	for (i=0; i<P.PerkTraits.Length; ++i)
	{
		if (P.PerkTraits[i].TraitType==Trait)
		{
			if (P.PerkTraits[i].CurrentLevel>=Trait.Default.NumLevels)
				return;
			cost = Trait.Static.GetTraitCost(P.PerkTraits[i].CurrentLevel);
			if (cost>P.CurrentSP || !Trait.Static.MeetsRequirements(P.PerkTraits[i].CurrentLevel,P))
				return;

			PC.ActivePerkManager.bStatsDirty = true;
			P.CurrentSP-=cost;
			P.bForceNetUpdate = true;
			if (P.bOwnerNetClient)
				P.ClientSetCurrentSP(P.CurrentSP);
			++P.PerkTraits[i].CurrentLevel;
			P.ClientReceiveTraitLvl(i,P.PerkTraits[i].CurrentLevel);
			if (P.PerkTraits[i].CurrentLevel==1)
				P.PerkTraits[i].Data = Trait.Static.Initializefor (P,PC);

			if (PC.ActivePerkManager.CurrentPerk==P)
			{
				Trait.Static.TraitDeActivate(P,P.PerkTraits[i].CurrentLevel-1,P.PerkTraits[i].Data);
				Trait.Static.TraitActivate(P,P.PerkTraits[i].CurrentLevel,P.PerkTraits[i].Data);
				if (KFPawn_Human(PC.Pawn)!=None)
				{
					Trait.Static.CancelEffectOn(KFPawn_Human(PC.Pawn),P,P.PerkTraits[i].CurrentLevel-1,P.PerkTraits[i].Data);
					Trait.Static.ApplyEffectOn(KFPawn_Human(PC.Pawn),P,P.PerkTraits[i].CurrentLevel,P.PerkTraits[i].Data);
				}
			}
			SavePlayerPerk(PC);
			break;
		}
	}
}

function PlayerUnloadInfo(ExtPlayerController PC, byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload)
{
	local Ext_PerkBase P;
	local int LostExp,NewLvl;

	// Verify if client tries to cause errors.
	if (PC==None || PerkClass==None || PC.ActivePerkManager==None)
		return;

	// Perk unloading disabled on this server.
	if (MinUnloadPerkLevel==-1)
	{
		if (!bUnload)
			PC.ClientGotUnloadInfo(CallID,0);
		return;
	}

	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if (P==None) // More client hack attempts.
		return;

	if (P.CurrentLevel<MinUnloadPerkLevel) // Verify minimum level.
	{
		if (!bUnload)
			PC.ClientGotUnloadInfo(CallID,1,MinUnloadPerkLevel);
		return;
	}

	// Calc how much EXP is lost on this progress.
	LostExp = Round(float(P.CurrentEXP) * UnloadPerkExpCost);

	if (!bUnload)
	{
		if (LostExp==0) // Generous server admin!
			PC.ClientGotUnloadInfo(CallID,2,0,0);
		else
		{
			// Calc how many levels are dropped.
			NewLvl = P.CalcLevelForExp(P.CurrentEXP-LostExp);
			PC.ClientGotUnloadInfo(CallID,2,LostExp,P.CurrentLevel-NewLvl);
		}
		return;
	}
	P.UnloadStats();
	P.CurrentEXP -= LostExp;
	P.SetInitialLevel();
	PC.ActivePerkManager.PRIOwner.SetLevelProgress(P.CurrentLevel,P.CurrentPrestige,P.MinimumLevel,P.MaximumLevel);
	PC.ActivePerkManager.bStatsDirty = true;
	SavePlayerPerk(PC);
	if (PC.Pawn!=None)
		PC.Pawn.Suicide();
}


function ResetPlayerPerk(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, bool bPrestige)
{
	local Ext_PerkBase P;

	if (bGameHasEnded)
		return;

	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if (P==None || !P.bPerkNetReady)
		return;
	if (bPrestige)
	{
		if (!P.CanPrestige())
		{
			PC.ClientMessage("Prestige for this perk is not allowed.");
			return;
		}
		++P.CurrentPrestige;
	}
	P.FullReset(bPrestige);
	PC.ActivePerkManager.bStatsDirty = true;
	SavePlayerPerk(PC);
}

function bool CheckReplacement(Actor Other)
{
	if (bNoBoomstickJumping && KFWeap_Shotgun_DoubleBarrel(Other)!=None)
		KFWeap_Shotgun_DoubleBarrel(Other).DoubleBarrelKickMomentum = 5.f;
	return true;
}

final function UpdateGrenadeTuningTimer()
{
	if (bAdminGrenadeRadius || bAdminGrenadeThrowRange)
	{
		SetTimer(0.02f,true,'ApplyGrenadeTuningToLiveProjectiles');
	}
	else
	{
		ClearTimer('ApplyGrenadeTuningToLiveProjectiles');
		ZvampextTunedGrenades.Length = 0;
	}
}

final function ApplyGrenadeTuningToLiveProjectiles()
{
	local int i;
	local float ThrowScale;
	local KFProj_Grenade GrenadeProj;

	for (i=ZvampextTunedGrenades.Length-1; i>=0; --i)
	{
		if (ZvampextTunedGrenades[i] == None || ZvampextTunedGrenades[i].bDeleteMe)
		{
			ZvampextTunedGrenades.Remove(i,1);
		}
	}

	foreach WorldInfo.DynamicActors(class'KFProj_Grenade',GrenadeProj)
	{
		if (GrenadeProj == None || GrenadeProj.bDeleteMe || GrenadeProj.Instigator == None
			|| ExtPlayerController(GrenadeProj.Instigator.Controller) == None
			|| ZvampextTunedGrenades.Find(GrenadeProj) != INDEX_NONE)
		{
			continue;
		}

		if (bAdminGrenadeRadius)
		{
			GrenadeProj.DamageRadius *= AdminGrenadeRadiusValue;
		}

		if (bAdminGrenadeThrowRange)
		{
			ThrowScale = FMax(AdminGrenadeThrowRangeValue,0.f);
			GrenadeProj.Speed *= ThrowScale;
			GrenadeProj.MaxSpeed *= ThrowScale;
			GrenadeProj.TossZ *= ThrowScale;
			if (!IsZero(GrenadeProj.Velocity))
			{
				GrenadeProj.Velocity *= ThrowScale;
				GrenadeProj.Speed = VSize(GrenadeProj.Velocity);
			}
			GrenadeProj.SetPhysics(PHYS_Falling);
			`log("[Zvamp] grenade throw tuning applied player="$GrenadeProj.Instigator.PlayerReplicationInfo.PlayerName$" class="$GrenadeProj.Class$" scale="$ThrowScale$" radius="$GrenadeProj.DamageRadius);
		}

		ZvampextTunedGrenades.AddItem(GrenadeProj);
	}
}

final function bool IsAdminGrenadeDamage(class<DamageType> DamageType, Actor DamageCauser)
{
	return KFProj_Grenade(DamageCauser)!=None || (DamageType!=None && InStr(string(DamageType.Name),"Grenade")>=0);
}

final function ApplyPickupOverridesTo(Pawn Other)
{
	local ExtInventoryManager IM;

	if (Other==None)
		return;

	IM = ExtInventoryManager(Other.InvManager);
	if (IM!=None)
	{
		IM.SetAdminPickupOverrides(bAdminAmmoPickup,AdminAmmoPickupValue,bAdminItemPickup,AdminItemPickupValue,bAdminArmorPickup,AdminArmorPickupValue);
		IM.SetAdminResourcePickupOverrides(bAdminGrenadesFromAmmo,AdminGrenadesFromAmmoValue,bAdminAmmoBoxArmor,AdminAmmoBoxArmorValue);
		IM.SetDoshThrowAmount(DoshThrowAmount);
	}
}

function ModifyPickupFactories()
{
	Super.ModifyPickupFactories();
	ApplyResourcePickupFactoryCounts(false);
}

function ModifyActivatedPickupFactory(PickupFactory out_ActivatedFactory, out float out_RespawnDelay)
{
	Super.ModifyActivatedPickupFactory(out_ActivatedFactory,out_RespawnDelay);
	if (bAdminPickupRespawnTime && KFPickupFactory(out_ActivatedFactory) != None)
	{
		out_RespawnDelay = FMax(AdminPickupRespawnTimeValue,1.f);
	}
}

final function ApplyResourcePickupFactoryCounts(bool bResetPickups)
{
	local KFGameInfo KFGI;
	local int AmmoCount, ItemCount;

	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None || KFGI.DifficultyInfo == None)
	{
		return;
	}

	AmmoCount = bAdminAmmoBoxCount
		? Clamp(Round(AdminAmmoBoxCountValue),0,KFGI.AmmoPickups.Length)
		: Clamp(Round(float(KFGI.AmmoPickups.Length) * KFGI.DifficultyInfo.GetAmmoPickupModifier()),0,KFGI.AmmoPickups.Length);
	ItemCount = bAdminItemBoxCount
		? Clamp(Round(AdminItemBoxCountValue),0,KFGI.ItemPickups.Length)
		: Clamp(Round(float(KFGI.ItemPickups.Length) * KFGI.DifficultyInfo.GetItemPickupModifier()),0,KFGI.ItemPickups.Length);

	KFGI.NumAmmoPickups = AmmoCount;
	KFGI.NumWeaponPickups = ItemCount;
	if (bResetPickups)
	{
		KFGI.ResetAllPickups();
	}
	`log("[Zvamp] Resource limits applied ammoBoxes="$AmmoCount$"/"$KFGI.AmmoPickups.Length@"itemBoxes="$ItemCount$"/"$KFGI.ItemPickups.Length@"reset="$bResetPickups);
}

final function ApplyPickupOverridesToController(ExtPlayerController PC)
{
	if (PC!=None)
		ApplyPickupOverridesTo(PC.Pawn);
}

final function InitCustomChars(ExtPlayerReplicationInfo PRI)
{
	PRI.CustomCharList = CustomCharList;
}

final function bool HasPrivs(ExtPlayerReplicationInfo P)
{
	return WorldInfo.NetMode==NM_StandAlone || (P != None && P.ShowAdminName() && (P.AdminType <= AT_Admin || P.AdminType == AT_Player));
}

function AdminCommand(ExtPlayerController PC, int PlayerID, int Action)
{
	local ExtPlayerController E;
	local int i;

	if (bNoAdminCommands)
	{
		PC.ClientMessage("Admin level commands are disabled.",'Priority');
		return;
	}
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		if (E.PlayerReplicationInfo.PlayerID==PlayerID)
			break;

	if (E==None)
	{
		PC.ClientMessage("Action failed, missing playerID: "$PlayerID,'Priority');
		return;
	}

	if (Action>=100) // Set perk level.
	{
		if (E.ActivePerkManager.CurrentPerk==None)
		{
			PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
			return;
		}
		if (Action>=100000) // Set prestige level.
		{
			if (E.ActivePerkManager.CurrentPerk.MinLevelForPrestige<0)
			{
				PC.ClientMessage("Perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" has prestige disabled!",'Priority');
				return;
			}
			Action = Min(Action-100000,E.ActivePerkManager.CurrentPerk.MaxPrestige);
			E.ActivePerkManager.CurrentPerk.CurrentPrestige = Action;
			PC.ClientMessage("Set "$E.PlayerReplicationInfo.PlayerName$"' perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" prestige level to "$Action,'Priority');

			E.ActivePerkManager.CurrentPerk.FullReset(true);
		}
		else
		{
			Action = Clamp(Action-100,E.ActivePerkManager.CurrentPerk.MinimumLevel,E.ActivePerkManager.CurrentPerk.MaximumLevel);
			E.ActivePerkManager.CurrentPerk.CurrentEXP = E.ActivePerkManager.CurrentPerk.GetNeededExp(Action-1);
			PC.ClientMessage("Set "$E.PlayerReplicationInfo.PlayerName$"' perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" level to "$Action,'Priority');

			E.ActivePerkManager.CurrentPerk.SetInitialLevel();
			E.ActivePerkManager.CurrentPerk.UpdatePRILevel();
		}
		E.ActivePerkManager.bStatsDirty = true;
		SavePlayerPerk(E);
		return;
	}

	switch (Action)
	{
	case 0: // Reset ALL Stats
		for (i=0; i<E.ActivePerkManager.UserPerks.Length; ++i)
			E.ActivePerkManager.UserPerks[i].FullReset();
		PC.ClientMessage("Reset EVERY perk for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		break;
	case 1: // Reset Current Perk Stats
		if (E.ActivePerkManager.CurrentPerk!=None)
		{
			E.ActivePerkManager.CurrentPerk.FullReset();
			PC.ClientMessage("Reset perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 2: // Add 1,000 XP
	case 3: // Add 10,000 XP
	case 4: // Advance Perk Level
		if (E.ActivePerkManager.CurrentPerk!=None)
		{
			if (Action==2)
				i = 1000;
			else if (Action==3)
				i = 10000;
			else i = Max(E.ActivePerkManager.CurrentPerk.NextLevelEXP - E.ActivePerkManager.CurrentPerk.CurrentEXP,0);
			E.ActivePerkManager.EarnedEXP(i);
			PC.ClientMessage("Gave "$i$" XP for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 5: // Unload all stats
		if (E.ActivePerkManager.CurrentPerk!=None)
		{
			E.ActivePerkManager.CurrentPerk.UnloadStats(1);
			PC.ClientMessage("Unloaded all stats for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 6: // Unload all traits
		if (E.ActivePerkManager.CurrentPerk!=None)
		{
			E.ActivePerkManager.CurrentPerk.UnloadStats(2);
			PC.ClientMessage("Unloaded all traits for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 7: // Remove 1,000 XP
	case 8: // Remove 10,000 XP
		if (E.ActivePerkManager.CurrentPerk!=None)
		{
			if (Action==6)
				i = 1000;
			else i = 10000;
			E.ActivePerkManager.CurrentPerk.CurrentEXP = Max(E.ActivePerkManager.CurrentPerk.CurrentEXP-i,0);
			PC.ClientMessage("Removed "$i$" XP from "$E.PlayerReplicationInfo.PlayerName,'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!",'Priority');
		break;
	case 9: // Show Debug Info
		PC.ClientMessage("DEBUG info for "$E.PlayerReplicationInfo.PlayerName,'Priority');
		PC.ClientMessage("PerkManager "$E.ActivePerkManager$" Current Perk: "$E.ActivePerkManager.CurrentPerk,'Priority');
		PC.ClientMessage("Perks Count: "$E.ActivePerkManager.UserPerks.Length,'Priority');
		for (i=0; i<E.ActivePerkManager.UserPerks.Length; ++i)
			PC.ClientMessage("Perk "$i$": "$E.ActivePerkManager.UserPerks[i]$" XP:"$E.ActivePerkManager.UserPerks[i].CurrentEXP$" Lv:"$E.ActivePerkManager.UserPerks[i].CurrentLevel$" Rep:"$E.ActivePerkManager.UserPerks[i].bPerkNetReady,'Priority');
		break;
	default:
		PC.ClientMessage("Unknown admin action.",'Priority');
		return;
	}
	if (Action>=0 && Action<=8 && E!=None && E.ActivePerkManager!=None)
	{
		E.ActivePerkManager.bStatsDirty = true;
		SavePlayerPerk(E);
	}
}

function AdminSetMOTD(ExtPlayerController PC, string S)
{
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
		return;
	ServerMOTD = S;
	SaveConfig();
	PC.ClientMessage("Message of the Day updated.",'Priority');
}

final function string SanitizeAutoMessageColor(string S)
{
	if (Len(S)!=6)
		return "9B7CFF";
	return Caps(S);
}

final function string ExtractAutoMessageColor(out string MessageText, string DefaultColor)
{
	local string ColorText;

	if (Len(MessageText)>=8 && Left(MessageText,1)=="<" && Mid(MessageText,7,1)==">")
	{
		ColorText = SanitizeAutoMessageColor(Mid(MessageText,1,6));
		MessageText = TrimAutoMessageEntry(Mid(MessageText,8));
		return ColorText;
	}
	return SanitizeAutoMessageColor(DefaultColor);
}

final function string TrimAutoMessageEntry(string S)
{
	while (Len(S)>0 && (Left(S,1)==" " || Left(S,1)==Chr(9)))
		S = Mid(S,1);
	while (Len(S)>0 && (Right(S,1)==" " || Right(S,1)==Chr(9)))
		S = Left(S,Len(S)-1);
	return S;
}

final function BuildAutoMessageList(string MessageText)
{
	local int SplitAt;
	local string Entry;

	AutoMessageTexts.Length = 0;
	while (MessageText!="")
	{
		SplitAt = InStr(MessageText,";;");
		if (SplitAt>=0)
		{
			Entry = TrimAutoMessageEntry(Left(MessageText,SplitAt));
			MessageText = Mid(MessageText,SplitAt+2);
		}
		else
		{
			Entry = TrimAutoMessageEntry(MessageText);
			MessageText = "";
		}
		if (Entry!="")
			AutoMessageTexts.AddItem(Left(Entry,512));
	}
	AutoMessageIndex = 0;
}

function AdminSetAutoMessage(ExtPlayerController PC, bool bEnabled, int IntervalSeconds, string MessageText, string MessageColor)
{
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	bAutoMessageEnabled = bEnabled;
	AutoMessageIntervalSeconds = Clamp(IntervalSeconds,30,3600);
	AutoMessageText = Left(MessageText,512);
	BuildAutoMessageList(MessageText);
	AutoMessageColor = SanitizeAutoMessageColor(MessageColor);
	NextAutoMessageTime = WorldInfo.TimeSeconds + AutoMessageIntervalSeconds;
	SaveConfig();
	PC.ClientMessage("Auto message "$(bAutoMessageEnabled ? "enabled." : "disabled."),'Priority');
}

function AutoMessageTick()
{
	local ExtPlayerController E;
	local string MessageText, MessageColor;

	if (!bAutoMessageEnabled || WorldInfo.TimeSeconds<NextAutoMessageTime || (AutoMessageText=="" && AutoMessageTexts.Length==0))
		return;

	NextAutoMessageTime = WorldInfo.TimeSeconds + Max(AutoMessageIntervalSeconds,30);
	if (AutoMessageTexts.Length>0)
	{
		AutoMessageIndex = AutoMessageIndex % AutoMessageTexts.Length;
		MessageText = AutoMessageTexts[AutoMessageIndex++];
	}
	else
		MessageText = AutoMessageText;
	MessageColor = ExtractAutoMessageColor(MessageText,AutoMessageColor);
	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		E.ClientZvampextAutoMessage(MessageText,MessageColor);
}

function bool FastForwardTrader(ExtPlayerController PC, bool bAdminForce)
{
	local KFGameReplicationInfo KFGRI;
	local KFGameInfo KFGI;
	local Zvampext_Endless ZGI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGRI==None || KFGI==None || !KFGRI.bTraderIsOpen)
	{
		PC.ClientMessage("Trader is not open.",'Priority');
		return false;
	}

	ZGI = Zvampext_Endless(KFGI);
	if (ZGI!=None)
		ZGI.ReleaseTraderAutoPause();
	else
		ReleaseSMLTraderPause();
	KFGRI.bStopCountDown = false;
	KFGRI.RemainingTime = 1;
	KFGRI.RemainingMinute = 1;
	KFGI.SkipTrader(1);
	PC.ClientMessage(bAdminForce ? "Admin fast-forwarded trader time." : "Public fast-forwarded trader time.",'Priority');
	return true;
}

function bool OpenTraderFor(ExtPlayerController PC, bool bAdminForce)
{
	local ExtPlayerController E;
	local KFGameReplicationInfo KFGRI;
	local KFGameInfo KFGI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGRI==None || KFGI==None || KFGI.MyKFGRI==None)
	{
		PC.ClientMessage("Open trader is unavailable in this game state.",'Priority');
		return false;
	}
	if (!KFGRI.bTraderIsOpen)
	{
		KFGI.MyKFGRI.bTraderIsOpen = true;
		if (KFGI.MyKFGRI.NextTrader!=None)
			KFGI.MyKFGRI.OpenTrader(300);
		else if (KFGI.ScriptedTrader!=None || KFGI.TraderList.Length>0)
			KFGI.MyKFGRI.OpenTraderNext(300);
		else
		{
			PC.ClientMessage("Open trader failed: this map has no trader pod.",'Priority');
			return false;
		}
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			E.ClientMessage((bAdminForce ? "Admin opened trader time." : "Trader time opened."),'Priority');
	}
	PC.OpenTraderMenu(true);
	PC.ClientRevampOpenTraderMenu();
	PC.ClientMessage("Opened trader menu.",'Priority');
	return true;
}

function PublicOpenTrader(ExtPlayerController PC)
{
	if (!bRevampTraderGuard || !bRevampTraderGuardPublicOpenTrader)
	{
		PC.ClientMessage("Public open trader is disabled.",'Priority');
		return;
	}
	OpenTraderFor(PC,false);
}

function AdminFastForwardTrader(ExtPlayerController PC)
{
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}
	FastForwardTrader(PC,true);
}

function AdminOpenTrader(ExtPlayerController PC)
{
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}
	OpenTraderFor(PC,true);
}

function AdminGiveDosh(ExtPlayerController PC, int DoshAmount)
{
	local KFPlayerReplicationInfo KFPRI;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	KFPRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if (KFPRI == None)
	{
		PC.ClientMessage("DoshMe failed: player replication info unavailable.",'Priority');
		return;
	}

	DoshAmount = Clamp(DoshAmount, 1, 1000000);
	KFPRI.AddDosh(DoshAmount, true);
	KFPRI.bForceNetUpdate = true;
	PC.ClientMessage("DoshMe added "$DoshAmount$" dosh.",'Priority');
}

final function int CountVoteEligiblePlayers()
{
	local ExtPlayerController E;
	local int Count;

	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		if (E!=None && E.PlayerReplicationInfo!=None && !E.PlayerReplicationInfo.bOnlySpectator)
			++Count;
	return Max(Count,1);
}

final function bool HasProgressWaveVoted(ExtPlayerController PC)
{
	return (ProgressWaveYesVotes.Find(PC)!=INDEX_NONE || ProgressWaveNoVotes.Find(PC)!=INDEX_NONE);
}

final function bool HasNextMapVoted(ExtPlayerController PC)
{
	return (NextMapYesVotes.Find(PC)!=INDEX_NONE || NextMapNoVotes.Find(PC)!=INDEX_NONE);
}

function PlayerProgressWaveVoteCall(ExtPlayerController PC, int WaveCount)
{
	local ExtPlayerController E;
	local string CallerName;

	if (!bPlayerProgressWaveVoteEnabled)
	{
		PC.ClientMessage("[Zvamp] Player ProgressWave voting is disabled.",'Priority');
		return;
	}
	if (bProgressWaveVoteActive)
	{
		PC.ClientMessage("[Zvamp] A ProgressWave vote is already active.",'Priority');
		return;
	}
	WaveCount = Clamp(WaveCount,1,Max(PlayerProgressWaveVoteMax,1));
	ProgressWaveVoteTarget = WaveCount;
	ProgressWaveVoteCaller = PC;
	ProgressWaveYesVotes.Length = 0;
	ProgressWaveNoVotes.Length = 0;
	ProgressWaveYesVotes.AddItem(PC);
	bProgressWaveVoteActive = true;
	CallerName = (PC.PlayerReplicationInfo!=None ? PC.PlayerReplicationInfo.PlayerName : "A player");

	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
	{
		if (E!=None && E.PlayerReplicationInfo!=None && !E.PlayerReplicationInfo.bOnlySpectator)
		{
			E.ClientMessage("[Zvamp] "$CallerName$" called vote: ProgressWave "$WaveCount$". Use Zvote yes/no or the popup.",'Priority');
			E.ClientOpenProgressWaveVote(CallerName,WaveCount,Max(PlayerProgressWaveVoteSeconds,10));
		}
	}
	SetTimer(Max(PlayerProgressWaveVoteSeconds,10),false,'FinishProgressWaveVote');
	CheckProgressWaveVote();
}

function PlayerProgressWaveVoteAnswer(ExtPlayerController PC, bool bAccept)
{
	if (!bProgressWaveVoteActive || PC==None || HasProgressWaveVoted(PC))
		return;
	if (bAccept)
		ProgressWaveYesVotes.AddItem(PC);
	else ProgressWaveNoVotes.AddItem(PC);
	PC.ClientMessage("[Zvamp] ProgressWave vote recorded: "$(bAccept ? "yes" : "no")$".",'Priority');
	CheckProgressWaveVote();
}

function CheckProgressWaveVote()
{
	local int Needed;

	if (!bProgressWaveVoteActive)
		return;
	Needed = Max(1,FCeil(float(CountVoteEligiblePlayers()) * FClamp(PlayerProgressWaveVotePct,0.01,1.f)));
	if (ProgressWaveYesVotes.Length>=Needed)
	{
		FinishProgressWaveVote(true);
	}
	else if (ProgressWaveNoVotes.Length>CountVoteEligiblePlayers()-Needed)
	{
		FinishProgressWaveVote(false);
	}
}

function FinishProgressWaveVote(optional bool bPassed)
{
	local ExtPlayerController E;

	if (!bProgressWaveVoteActive)
		return;
	bProgressWaveVoteActive = false;
	ClearTimer('FinishProgressWaveVote');
	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		if (E!=None)
			E.ClientMessage("[Zvamp] ProgressWave vote "$(bPassed ? "passed" : "failed")$" ("$ProgressWaveYesVotes.Length$" yes, "$ProgressWaveNoVotes.Length$" no).",'Priority');
	if (bPassed)
		ExecuteProgressWave(ProgressWaveVoteCaller,ProgressWaveVoteTarget,false);
	ProgressWaveYesVotes.Length = 0;
	ProgressWaveNoVotes.Length = 0;
	ProgressWaveVoteCaller = None;
}

function StartNextMapChoiceVote()
{
	local ExtPlayerController E;

	if (bNextMapChoiceActive)
		return;
	bNextMapChoiceOffered = true;
	bNextMapChoiceActive = true;
	if (KF!=None)
		NextMapChoiceWaveNum = KF.WaveNum;
	else NextMapChoiceWaveNum = NextMapChoiceWave;
	NextMapYesVotes.Length = 0;
	NextMapNoVotes.Length = 0;
	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
	{
		if (E!=None && E.PlayerReplicationInfo!=None && !E.PlayerReplicationInfo.bOnlySpectator)
		{
			E.ClientMessage("[Zvamp] Wave "$NextMapChoiceWaveNum$" reached. Vote Keep Playing or Next Map.",'Priority');
			E.ClientOpenNextMapVote(NextMapChoiceWaveNum,Max(NextMapChoiceSeconds,10));
		}
	}
	SetTimer(Max(NextMapChoiceSeconds,10),false,'FinishNextMapChoiceVote');
}

function PlayerNextMapVoteAnswer(ExtPlayerController PC, bool bNextMap)
{
	if (!bNextMapChoiceActive || PC==None || HasNextMapVoted(PC))
		return;
	if (bNextMap)
		NextMapYesVotes.AddItem(PC);
	else NextMapNoVotes.AddItem(PC);
	PC.ClientMessage("[Zvamp] Next map vote recorded: "$(bNextMap ? "next map" : "keep playing")$".",'Priority');
	CheckNextMapChoiceVote();
}

function CheckNextMapChoiceVote()
{
	local int Needed;

	if (!bNextMapChoiceActive)
		return;
	Needed = Max(1,FCeil(float(CountVoteEligiblePlayers()) * FClamp(NextMapChoicePct,0.01,1.f)));
	if (NextMapYesVotes.Length>=Needed)
		FinishNextMapChoiceVote(true);
	else if (NextMapNoVotes.Length>CountVoteEligiblePlayers()-Needed)
		FinishNextMapChoiceVote(false);
}

function OpenMapVoteForNextMap()
{
	local xVotingHandler MV;

	if (!bEnableMapVote)
		return;
	foreach DynamicActors(class'xVotingHandler',MV)
		break;
	if (MV==None)
	{
		MV = Spawn(class'xVotingHandler');
		MV.BaseMutator = Class;
	}
	if (MV!=None)
		MV.StartMidGameVote(true);
}

function FinishNextMapChoiceVote(optional bool bNextMap)
{
	local ExtPlayerController E;

	if (!bNextMapChoiceActive)
		return;
	bNextMapChoiceActive = false;
	ClearTimer('FinishNextMapChoiceVote');
	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		if (E!=None)
			E.ClientMessage("[Zvamp] Next map vote "$(bNextMap ? "passed" : "kept playing")$" ("$NextMapYesVotes.Length$" next, "$NextMapNoVotes.Length$" keep).",'Priority');
	if (bNextMap)
		OpenMapVoteForNextMap();
	NextMapYesVotes.Length = 0;
	NextMapNoVotes.Length = 0;
}

function AdminProgressWave(ExtPlayerController PC, int WaveCount)
{
	ExecuteProgressWave(PC,WaveCount,true,"ProgressWave");
}

function ExecuteProgressWave(ExtPlayerController PC, int WaveCount, bool bRequireAdmin, optional string SourceLabel)
{
	local KFGameInfo KFGI;
	local KFGameInfo_Survival SurvivalGI;
	local KFGameReplicationInfo KFGRI;
	local KFAISpawnManager SpawnManager;
	local KFPawn_Monster Zed;
	local Zvampext_Endless ZGI;
	local int OldWave;
	local int NewWave;
	local int Damaged;
	local int Removed;
	local int TargetWave;

	if (SourceLabel == "")
		SourceLabel = "ProgressWave";

	if (PC==None)
		return;
	if (bRequireAdmin && !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGI == None || KFGRI == None)
	{
		PC.ClientMessage(SourceLabel$" failed: game state unavailable.",'Priority');
		return;
	}

	ZGI = Zvampext_Endless(KFGI);
	SurvivalGI = KFGameInfo_Survival(KFGI);
	if (SurvivalGI == None)
	{
		PC.ClientMessage(SourceLabel$" failed: Survival-style game state unavailable.",'Priority');
		return;
	}
	WaveCount = Clamp(WaveCount, 1, 100);
	OldWave = KFGRI.WaveNum;
	NewWave = Max(OldWave + WaveCount, 1);
	TargetWave = Max(NewWave - 1, 0);
	SpawnManager = KFGI.SpawnManager;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', Zed)
	{
		if (Zed != None && Zed.IsAliveAndWell() && PlayerController(Zed.Controller) == None)
		{
			if (AdminKillZed(PC, Zed))
			{
				++Damaged;
			}
		}
	}
	Removed = ForceRemoveRemainingZeds(PC);

	KFGI.AIAliveCount = 0;
	KFGI.NumAISpawnsQueued = 0;
	if (SpawnManager != None)
	{
		SpawnManager.WaveTotalAI = 0;
		SpawnManager.LeftoverSpawnSquad.Length = 0;
		if (SpawnManager.ActiveSpawner != None)
		{
			SpawnManager.ActiveSpawner.PendingSpawns.Length = 0;
			SpawnManager.ActiveSpawner.bIsSpawning = false;
		}
	}

	if (ZGI != None)
	{
		ZGI.WaveNum = TargetWave;
	}
	else if (SurvivalGI != None)
	{
		SurvivalGI.WaveNum = TargetWave;
	}
	KFGRI.WaveNum = TargetWave;
	KFGRI.AIRemaining = 0;
	KFGRI.bForceNetUpdate = true;

	if (ZGI != None)
	{
		ZGI.ReleaseTraderAutoPause();
	}
	else
	{
		ReleaseSMLTraderPause();
	}

	SurvivalGI.WaveEnded(WEC_WaveWon);
	`log("[Zvamp] "$SourceLabel$" advanced from "$OldWave$" to "$NewWave$"; damaged="$Damaged@"removed="$Removed);
	PC.ClientMessage(SourceLabel$" advanced from "$OldWave$" to "$NewWave$" and opened trader through wave-end flow. Removed "$Removed$" leftover zeds.",'Priority');
}

function RefreshNewItemsFor(ExtPlayerController PC)
{
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}
	if (bZvampextUIOnly)
	{
		PC.ClientMessage("[Zvamp] custom item refresh is disabled while bZvampextUIOnly=True.",'Priority');
		return;
	}

	RefreshZvampextTraderItems(true, PC);
	SendZvampextTraderItems(PC);
}

final function bool AdminKillZed(ExtPlayerController PC, KFPawn_Monster Zed)
{
	local int KillDamage;

	if (PC==None || Zed==None || Zed.bDeleteMe || !Zed.IsAliveAndWell())
		return false;

	KillDamage = Max(Max(Zed.HealthMax,Zed.Health) + 100000, 1000000);
	Zed.TakeDamage(KillDamage,PC,Zed.Location,vect(0,0,0),class'ExtDT_Ballistic_9mm',,PC.Pawn);
	return true;
}

final function int ForceRemoveRemainingZeds(ExtPlayerController PC)
{
	local KFPawn_Monster Zed;
	local int Count;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', Zed)
	{
		if (Zed == None || Zed.bDeleteMe || PlayerController(Zed.Controller) != None)
			continue;

		if (Zed.IsAliveAndWell())
		{
			Zed.Health = 0;
			Zed.Died(PC, class'DmgType_Suicided', Zed.Location);
		}
		if (!Zed.bDeleteMe)
			Zed.Destroy();
		++Count;
	}

	return Count;
}

function AdminBuildID(ExtPlayerController PC)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	PC.ClientMessage("[Zvamp] BuildID "$PC.ZvampextBuildID$" | "$ZvampextBuildID,'Priority');
	`log("[Zvamp] BuildID requested by "$PC.PlayerReplicationInfo.PlayerName$": "$PC.ZvampextBuildID$" | "$ZvampextBuildID);
}

function AdminSetDoshThrowAmount(ExtPlayerController PC, int NewAmount)
{
	local ExtPlayerController E;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	DoshThrowAmount = Clamp(NewAmount, 1, 1000000);
	SaveConfig();
	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		ApplyPickupOverridesToController(E);

	PC.ClientMessage("[Zvamp] DoshThrowAmount set to "$DoshThrowAmount$".",'Priority');
	`log("[Zvamp] DoshThrowAmount set to "$DoshThrowAmount@"by "$PC.PlayerReplicationInfo.PlayerName);
}

final function int ApplyZedSpawnerAliveLimit(int NewLimit)
{
	local Mutator M;
	local string ClassName;

	if (WorldInfo == None || WorldInfo.Game == None)
		return -1;

	for (M=WorldInfo.Game.BaseMutator; M!=None; M=M.NextMutator)
	{
		ClassName = Caps(string(M.Class));
		if (M.IsA('ZedSpawner') || M.IsA('ZedSpawnerMut') || InStr(ClassName,"ZEDSPAWNER.")>=0)
		{
			ConsoleCommand("set ZedSpawner.ZedSpawner AliveSpawnLimit "$NewLimit);
			ConsoleCommand("set ZedSpawner.ZedSpawnerMut AliveSpawnLimit "$NewLimit);
			ConsoleCommand("set ZedSpawner.Mut AliveSpawnLimit "$NewLimit);
			return NewLimit;
		}
	}
	return -1;
}

function AdminRevampAction(ExtPlayerController PC, int Action)
{
	local ExtPlayerController E;
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;
	local KFPawn_Monster Zed;
	local KFAISpawnManager SpawnManager;
	local int Count;
	local int i, DifficultyIndex, PlayerIndex, LivingPlayers, NewMaxMonsters, ZedSpawnerLimit;
	local float SpawnMod;
	local Controller C;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	switch (Action)
	{
	case 10: // Save all stats.
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			SavePlayerPerk(E);
		PC.ClientMessage("Saved all dirty RPG player stats.",'Priority');
		break;
	case 11: // Admin force skip trader.
		FastForwardTrader(PC,true);
		break;
	case 12: // Broadcast MOTD.
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		{
			SendMOTD(E);
			E.ClientMessage("MOTD broadcast by admin.",'Priority');
		}
		break;
	case 13: // Open trader.
		OpenTraderFor(PC,true);
		break;
	case 14: // Restart map.
		PC.ClientMessage("Restart map is disabled until the safe KF2 restart path is verified.",'Priority');
		break;
	case 15: // Enable cheats for local testing.
		PC.ClientRevampSetCheats(true);
		break;
	case 16: // Toggle god mode for the admin.
		PC.bRevampGodMode = !PC.bRevampGodMode;
		if (PC.Pawn!=None && PC.bRevampGodMode)
			PC.Pawn.Health = Max(PC.Pawn.Health, 1);
		PC.ClientMessage("God mode "$(PC.bRevampGodMode ? "enabled." : "disabled."),'Priority');
		break;
	case 17: // Kill active zeds.
		foreach WorldInfo.AllPawns(class'KFPawn_Monster',Zed)
		{
			if (Zed!=None && Zed.IsAliveAndWell() && PlayerController(Zed.Controller)==None
				&& (PC.Pawn==None || VSizeSq(Zed.Location-PC.Pawn.Location) <= 810000000000.f))
			{
				if (AdminKillZed(PC,Zed))
					++Count;
			}
		}
		PC.ClientMessage("Damaged "$Count$" active zeds.",'Priority');
		break;
	case 18: // End wave.
		ExecuteProgressWave(PC,1,true,"EndWave");
		break;
	case 19: // Pause or resume spawning.
		KFGI = KFGameInfo(WorldInfo.Game);
		if (KFGI==None || KFGI.SpawnManager==None)
		{
			PC.ClientMessage("Spawn manager unavailable.",'Priority');
			break;
		}
		bRevampSpawnsPaused = !bRevampSpawnsPaused;
		for (i=0; i<KFGI.SpawnManager.SpawnVolumes.Length; ++i)
			if (KFGI.SpawnManager.SpawnVolumes[i]!=None)
				KFGI.SpawnManager.SpawnVolumes[i].bCanUseForSpawning = !bRevampSpawnsPaused;
		if (bRevampSpawnsPaused && KFGI.SpawnManager.ActiveSpawner!=None)
		{
			KFGI.SpawnManager.ActiveSpawner.PendingSpawns.Length = 0;
			KFGI.SpawnManager.ActiveSpawner.bIsSpawning = false;
		}
		if (bRevampSpawnsPaused)
		{
			KFGI.NumAISpawnsQueued = 0;
			KFGI.SpawnManager.LeftoverSpawnSquad.Length = 0;
			KFGI.SpawnManager.TimeUntilNextSpawn = 999999.f;
		}
		else KFGI.SpawnManager.TimeUntilNextSpawn = FMin(KFGI.SpawnManager.TimeUntilNextSpawn,1.f);
		PC.ClientMessage(bRevampSpawnsPaused ? "Spawns paused." : "Spawns resumed.",'Priority');
		break;
	case 20: // Increase max monsters.
	case 21: // Decrease max monsters.
		KFGI = KFGameInfo(WorldInfo.Game);
		SpawnManager = (KFGI!=None) ? KFGI.SpawnManager : None;
		if (SpawnManager==None)
		{
			PC.ClientMessage("Spawn manager unavailable.",'Priority');
			break;
		}
		DifficultyIndex = Clamp(KFGI.GameDifficulty,0,SpawnManager.PerDifficultyMaxMonsters.Length-1);
		foreach WorldInfo.AllControllers(class'Controller',C)
			if (C!=None && C.PlayerReplicationInfo!=None && !C.PlayerReplicationInfo.bOnlySpectator && C.GetTeamNum()==0 && C.Pawn!=None && C.Pawn.Health>0)
				++LivingPlayers;
		if (LivingPlayers<=0)
			LivingPlayers = Max(KFGI.GetNumPlayers(),1);
		PlayerIndex = Clamp(LivingPlayers-1,0,SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters.Length-1);
		NewMaxMonsters = Clamp(SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters[PlayerIndex] + (Action==20 ? 4 : -4),1,200);
		SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters[PlayerIndex] = NewMaxMonsters;
		ZedSpawnerLimit = ApplyZedSpawnerAliveLimit(NewMaxMonsters);
		if (KFGameReplicationInfo(WorldInfo.GRI)!=None)
			KFGameReplicationInfo(WorldInfo.GRI).CurrentMaxMonsters = SpawnManager.GetMaxMonsters();
		if (ZedSpawnerLimit>=0)
			PC.ClientMessage("Max monsters now "$SpawnManager.GetMaxMonsters()$" for "$LivingPlayers$" living player(s). ZedSpawner alive limit "$ZedSpawnerLimit$".",'Priority');
		else PC.ClientMessage("Max monsters now "$SpawnManager.GetMaxMonsters()$" for "$LivingPlayers$" living player(s). ZedSpawner limit not found.",'Priority');
		break;
	case 22: // Faster spawns.
	case 23: // Slower spawns.
		KFGI = KFGameInfo(WorldInfo.Game);
		SpawnManager = (KFGI!=None) ? KFGI.SpawnManager : None;
		if (SpawnManager==None)
		{
			PC.ClientMessage("Spawn manager unavailable.",'Priority');
			break;
		}
		for (i=0; i<ArrayCount(SpawnManager.EarlyWavesSpawnTimeModByPlayers); ++i)
		{
			if (SpawnManager.EarlyWavesSpawnTimeModByPlayers[i]<=0.f)
				SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] = 1.f;
			if (SpawnManager.LateWavesSpawnTimeModByPlayers[i]<=0.f)
				SpawnManager.LateWavesSpawnTimeModByPlayers[i] = 1.f;
			SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] = FClamp(SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] * (Action==22 ? 0.85 : 1.15),0.05,5.0);
			SpawnManager.LateWavesSpawnTimeModByPlayers[i] = FClamp(SpawnManager.LateWavesSpawnTimeModByPlayers[i] * (Action==22 ? 0.85 : 1.15),0.05,5.0);
		}
		PlayerIndex = Clamp(Max(KFGI.GetNumPlayers(),1)-1,0,ArrayCount(SpawnManager.EarlyWavesSpawnTimeModByPlayers)-1);
		SpawnMod = FMax(SpawnManager.EarlyWavesSpawnTimeModByPlayers[PlayerIndex],SpawnManager.LateWavesSpawnTimeModByPlayers[PlayerIndex]);
		if (Action==22)
			SpawnManager.TimeUntilNextSpawn = FMin(SpawnManager.TimeUntilNextSpawn,1.f);
		PC.ClientMessage((Action==22 ? "Spawn rate increased. " : "Spawn rate decreased. ")$"Spawn time mod: "$SpawnMod,'Priority');
		break;
	case 24: // Pause trader countdown.
		KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
		if (KFGRI==None || !KFGRI.bTraderIsOpen)
		{
			PC.ClientMessage("Trader is not open.",'Priority');
			break;
		}
		HoldSMLTraderTimer("admin pause");
		PC.ClientMessage("Trader timer paused. Players can still vote/skip trader normally.",'Priority');
		break;
	default:
		PC.ClientMessage("Unknown revamp admin action.",'Priority');
	}
}

function AdminSetTraderGuard(ExtPlayerController PC, bool bEnabled, bool bBlockSkip, bool bPublicOpenTrader)
{
	local ExtPlayerController E;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	bRevampTraderGuard = bEnabled;
	bRevampTraderGuardBlockSkip = bBlockSkip;
	bRevampTraderGuardPublicOpenTrader = bPublicOpenTrader;
	SaveConfig();

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
		E.ClientSetRevampTraderGuard(bRevampTraderGuard,bRevampTraderGuardBlockSkip,bRevampTraderGuardPublicOpenTrader);

	PC.ClientMessage("TraderGuard settings updated.",'Priority');
}

final function string ZvampAdminSettingText(string Label, bool bEnabled, float Value)
{
	return Label$"="$(bEnabled ? string(Value) : "off");
}

function AdminSetPickupOverrides(ExtPlayerController PC, bool bGrenadeDamage, float GrenadeDamageValue, bool bGrenadeRadius, float GrenadeRadiusValue, bool bAmmoPickup, float AmmoPickupValue, bool bItemPickup, float ItemPickupValue, bool bArmorPickup, float ArmorPickupValue)
{
	local ExtPlayerController E;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	bAdminGrenadeDamage = bGrenadeDamage;
	AdminGrenadeDamageValue = FMax(GrenadeDamageValue,0.f);
	bAdminGrenadeRadius = bGrenadeRadius;
	AdminGrenadeRadiusValue = FMax(GrenadeRadiusValue,0.f);
	bAdminAmmoPickup = bAmmoPickup;
	AdminAmmoPickupValue = FMax(AmmoPickupValue,0.f);
	bAdminItemPickup = bItemPickup;
	AdminItemPickupValue = FMax(ItemPickupValue,0.f);
	bAdminArmorPickup = bArmorPickup;
	AdminArmorPickupValue = FMax(ArmorPickupValue,0.f);
	SaveConfig();
	UpdateGrenadeTuningTimer();

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
	{
		E.ClientSetAdminPickupOverrides(bAdminGrenadeDamage,AdminGrenadeDamageValue,bAdminGrenadeRadius,AdminGrenadeRadiusValue,bAdminAmmoPickup,AdminAmmoPickupValue,bAdminItemPickup,AdminItemPickupValue,bAdminArmorPickup,AdminArmorPickupValue);
		ApplyPickupOverridesToController(E);
		SendSpawnedPerkUILayout(E);
	}

	PC.ClientMessage("Pickup and grenade override settings updated.",'Priority');
}

function AdminSetGrenadeTuning(ExtPlayerController PC, bool bGrenadeDamage, float GrenadeDamageValue, bool bGrenadeRadius, float GrenadeRadiusValue, bool bThrowRange, float ThrowRangeValue)
{
	local ExtPlayerController E;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	bAdminGrenadeDamage = bGrenadeDamage;
	AdminGrenadeDamageValue = FMax(GrenadeDamageValue,0.f);
	bAdminGrenadeRadius = bGrenadeRadius;
	AdminGrenadeRadiusValue = FMax(GrenadeRadiusValue,0.f);
	bAdminGrenadeThrowRange = bThrowRange;
	AdminGrenadeThrowRangeValue = FMax(ThrowRangeValue,0.f);
	SaveConfig();
	UpdateGrenadeTuningTimer();

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
	{
		E.ClientSetAdminPickupOverrides(bAdminGrenadeDamage,AdminGrenadeDamageValue,bAdminGrenadeRadius,AdminGrenadeRadiusValue,bAdminAmmoPickup,AdminAmmoPickupValue,bAdminItemPickup,AdminItemPickupValue,bAdminArmorPickup,AdminArmorPickupValue);
		E.ClientSetAdminGrenadeThrowRange(bAdminGrenadeThrowRange,AdminGrenadeThrowRangeValue);
	}

	PC.ClientMessage("Grenade tuning applied: "$ZvampAdminSettingText("Damage",bAdminGrenadeDamage,AdminGrenadeDamageValue)$", "$ZvampAdminSettingText("Radius",bAdminGrenadeRadius,AdminGrenadeRadiusValue)$", "$ZvampAdminSettingText("Throw Range",bAdminGrenadeThrowRange,AdminGrenadeThrowRangeValue), 'Priority');
}

function AdminSetGrenadeThrowRange(ExtPlayerController PC, bool bThrowRange, float ThrowRangeValue)
{
	local ExtPlayerController E;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	bAdminGrenadeThrowRange = bThrowRange;
	AdminGrenadeThrowRangeValue = FMax(ThrowRangeValue,0.f);
	SaveConfig();
	UpdateGrenadeTuningTimer();

	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
	{
		E.ClientSetAdminGrenadeThrowRange(bAdminGrenadeThrowRange,AdminGrenadeThrowRangeValue);
	}

	PC.ClientMessage("Grenade throw range settings updated.",'Priority');
}

function AdminSetResourceLimits(ExtPlayerController PC, bool bAmmoBoxCount, float AmmoBoxCountValue, bool bItemBoxCount, float ItemBoxCountValue, bool bPickupRespawnTime, float PickupRespawnTimeValue, bool bGrenadesFromAmmo, float GrenadesFromAmmoValue, bool bAmmoBoxArmor, float AmmoBoxArmorValue)
{
	local ExtPlayerController E;

	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.",'Priority');
		return;
	}

	bAdminAmmoBoxCount = bAmmoBoxCount;
	AdminAmmoBoxCountValue = FMax(AmmoBoxCountValue,0.f);
	bAdminItemBoxCount = bItemBoxCount;
	AdminItemBoxCountValue = FMax(ItemBoxCountValue,0.f);
	bAdminPickupRespawnTime = bPickupRespawnTime;
	AdminPickupRespawnTimeValue = FMax(PickupRespawnTimeValue,1.f);
	bAdminGrenadesFromAmmo = bGrenadesFromAmmo;
	AdminGrenadesFromAmmoValue = FMax(GrenadesFromAmmoValue,0.f);
	bAdminAmmoBoxArmor = bAmmoBoxArmor;
	AdminAmmoBoxArmorValue = FMax(AmmoBoxArmorValue,0.f);
	SaveConfig();

	ApplyResourcePickupFactoryCounts(true);
	foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
	{
		E.ClientSetAdminResourceLimits(bAdminAmmoBoxCount,AdminAmmoBoxCountValue,bAdminItemBoxCount,AdminItemBoxCountValue,bAdminPickupRespawnTime,AdminPickupRespawnTimeValue,bAdminGrenadesFromAmmo,AdminGrenadesFromAmmoValue,bAdminAmmoBoxArmor,AdminAmmoBoxArmorValue);
		ApplyPickupOverridesToController(E);
	}

	PC.ClientMessage("Resource limits applied: "$ZvampAdminSettingText("Ammo Boxes",bAdminAmmoBoxCount,AdminAmmoBoxCountValue)$", "$ZvampAdminSettingText("Weapons / Items",bAdminItemBoxCount,AdminItemBoxCountValue)$", "$ZvampAdminSettingText("Respawn Seconds",bAdminPickupRespawnTime,AdminPickupRespawnTimeValue)$", "$ZvampAdminSettingText("Grenades / Ammo Box",bAdminGrenadesFromAmmo,AdminGrenadesFromAmmoValue)$", "$ZvampAdminSettingText("Armor / Ammo Box",bAdminAmmoBoxArmor,AdminAmmoBoxArmorValue), 'Priority');
}

function PlayerChangeSpec(ExtPlayerController PC, bool bSpectator)
{
	if (bSpectator==PC.PlayerReplicationInfo.bOnlySpectator || PC.NextSpectateChange>WorldInfo.TimeSeconds)
		return;
	PC.NextSpectateChange = WorldInfo.TimeSeconds+0.5;

	if (WorldInfo.Game.bGameEnded)
		PC.ClientMessage("Can't change spectate mode after end-game.");
	else if (WorldInfo.Game.bWaitingToStartMatch)
		PC.ClientMessage("Can't change spectate mode before game has started.");
	else if (WorldInfo.Game.AtCapacity(bSpectator,PC.PlayerReplicationInfo.UniqueId))
		PC.ClientMessage("Can't change spectate mode because game is at its maximum capacity.");
	else if (bSpectator)
	{
		PC.NextSpectateChange = WorldInfo.TimeSeconds+2.5;
		if (PC.PlayerReplicationInfo.Team!=None)
			PC.PlayerReplicationInfo.Team.RemoveFromTeam(PC);
		PC.PlayerReplicationInfo.bOnlySpectator = true;
		if (PC.Pawn!=None)
			PC.Pawn.KilledBy(None);
		PC.Reset();
		--WorldInfo.Game.NumPlayers;
		++WorldInfo.Game.NumSpectators;
		WorldInfo.Game.Broadcast(PC,PC.PlayerReplicationInfo.GetHumanReadableName()@"became a spectator");
		RemoveRespawn(PC);
	}
	else
	{
		PC.PlayerReplicationInfo.bOnlySpectator = false;
		if (!WorldInfo.Game.ChangeTeam(PC,WorldInfo.Game.PickTeam(0,PC,PC.PlayerReplicationInfo.UniqueId),false))
		{
			PC.PlayerReplicationInfo.bOnlySpectator = true;
			PC.ClientMessage("Can't become an active player, failed to set a team.");
			return;
		}
		PC.NextSpectateChange = WorldInfo.TimeSeconds+2.5;
		++WorldInfo.Game.NumPlayers;
		--WorldInfo.Game.NumSpectators;
		PC.Reset();
		WorldInfo.Game.Broadcast(PC,PC.PlayerReplicationInfo.GetHumanReadableName()@"became an active player");
		if (bRespawnCheck)
			CheckRespawn(PC);
	}
}

function InitWebAdmin(ExtWebAdmin_UI UI)
{
	local int i;

	UI.AddSettingsPage("Zvampext",Class,WebConfigs,WebAdminGetValue,WebAdminSetValue);
	for (i=0; i<LoadedPerks.Length; ++i)
		LoadedPerks[i].Static.InitWebAdmin(UI);
}

function string WebAdminGetValue(name PropName, int ElementIndex)
{
	switch (PropName)
	{
	case 'StatFileDir':
		return StatFileDir;
	case 'ForcedMaxPlayers':
		return string(ForcedMaxPlayers);
	case 'PlayerRespawnTime':
		return string(PlayerRespawnTime);
	case 'StatAutoSaveWaves':
		return string(StatAutoSaveWaves);
	case 'PostGameRespawnCost':
		return string(PostGameRespawnCost);
	case 'DoshThrowAmount':
		return string(DoshThrowAmount);
	case 'bPlayerProgressWaveVoteEnabled':
		return string(bPlayerProgressWaveVoteEnabled);
	case 'PlayerProgressWaveVoteMax':
		return string(PlayerProgressWaveVoteMax);
	case 'PlayerProgressWaveVotePct':
		return string(PlayerProgressWaveVotePct);
	case 'PlayerProgressWaveVoteSeconds':
		return string(PlayerProgressWaveVoteSeconds);
	case 'bNextMapChoiceEnabled':
		return string(bNextMapChoiceEnabled);
	case 'NextMapChoiceWave':
		return string(NextMapChoiceWave);
	case 'NextMapChoicePct':
		return string(NextMapChoicePct);
	case 'NextMapChoiceSeconds':
		return string(NextMapChoiceSeconds);
	case 'bKillMessages':
		return string(bKillMessages);
	case 'LargeMonsterHP':
		return string(LargeMonsterHP);
	case 'bDamageMessages':
		return string(bDamageMessages);
	case 'bEnableMapVote':
		return string(bEnableMapVote);
	case 'bNoBoomstickJumping':
		return string(bNoBoomstickJumping);
	case 'bNoAdminCommands':
		return string(bNoAdminCommands);
	case 'bRevampTraderGuard':
		return string(bRevampTraderGuard);
	case 'bRevampTraderGuardBlockSkip':
		return string(bRevampTraderGuardBlockSkip);
	case 'bRevampTraderGuardPublicOpenTrader':
		return string(bRevampTraderGuardPublicOpenTrader);
	case 'bZvampextAutoEnableCheats':
		return string(bZvampextAutoEnableCheats);
	case 'bZvampextUIOnly':
		return string(bZvampextUIOnly);
	case 'bVampUIEndMatchEnabled':
		return string(bVampUIEndMatchEnabled);
	case 'bAdminGrenadeDamage':
		return string(bAdminGrenadeDamage);
	case 'AdminGrenadeDamageValue':
		return string(AdminGrenadeDamageValue);
	case 'bAdminGrenadeRadius':
		return string(bAdminGrenadeRadius);
	case 'AdminGrenadeRadiusValue':
		return string(AdminGrenadeRadiusValue);
	case 'bAdminAmmoPickup':
		return string(bAdminAmmoPickup);
	case 'AdminAmmoPickupValue':
		return string(AdminAmmoPickupValue);
	case 'bAdminItemPickup':
		return string(bAdminItemPickup);
	case 'AdminItemPickupValue':
		return string(AdminItemPickupValue);
	case 'bAdminArmorPickup':
		return string(bAdminArmorPickup);
	case 'AdminArmorPickupValue':
		return string(AdminArmorPickupValue);
	case 'SpawnedPerkUILayout':
		return (ElementIndex==-1 ? string(SpawnedPerkUILayout.Length) : SpawnedPerkUILayout[ElementIndex]);
	case 'MidGameMenuLayout':
		return (ElementIndex==-1 ? string(MidGameMenuLayout.Length) : MidGameMenuLayout[ElementIndex]);
	case 'bDumpXMLStats':
		return string(bDumpXMLStats);
	case 'bRagdollFromFall':
		return string(bRagdollFromFall);
	case 'bRagdollFromMomentum':
		return string(bRagdollFromMomentum);
	case 'bRagdollFromBackhit':
		return string(bRagdollFromBackhit);
	case 'bAddCountryTags':
		return string(bAddCountryTags);
	case 'MaxTopPlayers':
		return string(MaxTopPlayers);
	case 'MinUnloadPerkLevel':
		return string(MinUnloadPerkLevel);
	case 'UnloadPerkExpCost':
		return string(UnloadPerkExpCost);
	case 'PerkClasses':
		return (ElementIndex==-1 ? string(PerkClasses.Length) : PerkClasses[ElementIndex]);
	case 'CustomChars':
		return (ElementIndex==-1 ? string(CustomChars.Length) : CustomChars[ElementIndex]);
	case 'AdminCommands':
		return (ElementIndex==-1 ? string(AdminCommands.Length) : AdminCommands[ElementIndex]);
	case 'RevampAdminSteamIDs':
		return (ElementIndex==-1 ? string(RevampAdminSteamIDs.Length) : RevampAdminSteamIDs[ElementIndex]);
	case 'ZvampextAdminIDs':
		return (ElementIndex==-1 ? string(ZvampextAdminIDs.Length) : ZvampextAdminIDs[ElementIndex]);
	case 'ServerMOTD':
		return Repl(ServerMOTD,"|",Chr(10));
	case 'BonusGameSongs':
		return (ElementIndex==-1 ? string(BonusGameSongs.Length) : BonusGameSongs[ElementIndex]);
	case 'BonusGameFX':
		return (ElementIndex==-1 ? string(BonusGameFX.Length) : BonusGameFX[ElementIndex]);
	case 'bThrowAllWeaponsOnDeath':
		return string(bThrowAllWeaponsOnDeath);
	}
}

final function UpdateArray(out array<string> Ar, int Index, const out string Value)
{
	if (Value=="#DELETE")
		Ar.Remove(Index,1);
	else
	{
		if (Index>=Ar.Length)
			Ar.Length = Index+1;
		Ar[Index] = Value;
	}
}

function WebAdminSetValue(name PropName, int ElementIndex, string Value)
{
	local ExtPlayerController E;

	switch (PropName)
	{
	case 'StatFileDir':
		StatFileDir = Value;				break;
	case 'ForcedMaxPlayers':
		ForcedMaxPlayers = int(Value);		break;
	case 'PlayerRespawnTime':
		PlayerRespawnTime = int(Value);		break;
	case 'StatAutoSaveWaves':
		StatAutoSaveWaves = int(Value);		break;
	case 'PostGameRespawnCost':
		PostGameRespawnCost = int(Value);	break;
	case 'DoshThrowAmount':
		DoshThrowAmount = Clamp(int(Value),1,1000000);
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			ApplyPickupOverridesToController(E);
		break;
	case 'bPlayerProgressWaveVoteEnabled':
		bPlayerProgressWaveVoteEnabled = bool(Value);	break;
	case 'PlayerProgressWaveVoteMax':
		PlayerProgressWaveVoteMax = Clamp(int(Value),1,100);	break;
	case 'PlayerProgressWaveVotePct':
		PlayerProgressWaveVotePct = FClamp(float(Value),0.01,1.f);	break;
	case 'PlayerProgressWaveVoteSeconds':
		PlayerProgressWaveVoteSeconds = Max(int(Value),10);	break;
	case 'bNextMapChoiceEnabled':
		bNextMapChoiceEnabled = bool(Value);	break;
	case 'NextMapChoiceWave':
		NextMapChoiceWave = Max(int(Value),0);	break;
	case 'NextMapChoicePct':
		NextMapChoicePct = FClamp(float(Value),0.01,1.f);	break;
	case 'NextMapChoiceSeconds':
		NextMapChoiceSeconds = Max(int(Value),10);	break;
	case 'bKillMessages':
		bKillMessages = bool(Value);		break;
	case 'LargeMonsterHP':
		LargeMonsterHP = int(Value);		break;
	case 'MinUnloadPerkLevel':
		MinUnloadPerkLevel = int(Value);	break;
	case 'UnloadPerkExpCost':
		UnloadPerkExpCost = float(Value);	break;
	case 'bDamageMessages':
		bDamageMessages = bool(Value);		break;
	case 'bEnableMapVote':
		bEnableMapVote = bool(Value);		break;
	case 'bNoAdminCommands':
		bNoAdminCommands = bool(Value);		break;
	case 'bRevampTraderGuard':
		bRevampTraderGuard = bool(Value);		break;
	case 'bRevampTraderGuardBlockSkip':
		bRevampTraderGuardBlockSkip = bool(Value);	break;
	case 'bRevampTraderGuardPublicOpenTrader':
		bRevampTraderGuardPublicOpenTrader = bool(Value);	break;
	case 'bZvampextAutoEnableCheats':
		bZvampextAutoEnableCheats = bool(Value);	break;
	case 'bZvampextUIOnly':
		bZvampextUIOnly = bool(Value);	break;
	case 'bVampUIEndMatchEnabled':
		bVampUIEndMatchEnabled = bool(Value);
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			E.ClientSetVampUIEndMatchEnabled(bVampUIEndMatchEnabled);
		break;
	case 'bAdminGrenadeDamage':
		bAdminGrenadeDamage = bool(Value);	break;
	case 'AdminGrenadeDamageValue':
		AdminGrenadeDamageValue = float(Value);	break;
	case 'bAdminGrenadeRadius':
		bAdminGrenadeRadius = bool(Value);	break;
	case 'AdminGrenadeRadiusValue':
		AdminGrenadeRadiusValue = float(Value);	break;
	case 'bAdminAmmoPickup':
		bAdminAmmoPickup = bool(Value);	break;
	case 'AdminAmmoPickupValue':
		AdminAmmoPickupValue = float(Value);	break;
	case 'bAdminItemPickup':
		bAdminItemPickup = bool(Value);	break;
	case 'AdminItemPickupValue':
		AdminItemPickupValue = float(Value);	break;
	case 'bAdminArmorPickup':
		bAdminArmorPickup = bool(Value);	break;
	case 'AdminArmorPickupValue':
		AdminArmorPickupValue = float(Value);	break;
	case 'SpawnedPerkUILayout':
		UpdateArray(SpawnedPerkUILayout,ElementIndex,Value);
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			SendSpawnedPerkUILayout(E);
		break;
	case 'MidGameMenuLayout':
		UpdateArray(MidGameMenuLayout,ElementIndex,Value);
		foreach WorldInfo.AllControllers(class'ExtPlayerController',E)
			SendMidGameMenuLayout(E);
		break;
	case 'bDumpXMLStats':
		bDumpXMLStats = bool(Value);		break;
	case 'bNoBoomstickJumping':
		bNoBoomstickJumping = bool(Value);	break;
	case 'bRagdollFromFall':
		bRagdollFromFall = bool(Value);		break;
	case 'bRagdollFromMomentum':
		bRagdollFromMomentum = bool(Value);	break;
	case 'bRagdollFromBackhit':
		bRagdollFromBackhit = bool(Value);	break;
	case 'bAddCountryTags':
		bAddCountryTags = bool(Value);		break;
	case 'MaxTopPlayers':
		MaxTopPlayers = int(Value);			break;
	case 'ServerMOTD':
		ServerMOTD = Repl(Value,Chr(13)$Chr(10),"|"); break;
	case 'PerkClasses':
		UpdateArray(PerkClasses,ElementIndex,Value);	break;
	case 'CustomChars':
		UpdateArray(CustomChars,ElementIndex,Value);	break;
	case 'AdminCommands':
		UpdateArray(AdminCommands,ElementIndex,Value);	break;
	case 'RevampAdminSteamIDs':
		UpdateArray(RevampAdminSteamIDs,ElementIndex,Value);
		break;
	case 'ZvampextAdminIDs':
		UpdateArray(ZvampextAdminIDs,ElementIndex,Value);
		break;
	case 'BonusGameSongs':
		UpdateArray(BonusGameSongs,ElementIndex,Value);	break;
	case 'BonusGameFX':
		UpdateArray(BonusGameFX,ElementIndex,Value);	break;
	case 'bThrowAllWeaponsOnDeath':
		bThrowAllWeaponsOnDeath = bool(Value);	break;
	default:
		return;
	}
	SaveConfig();
}

defaultproperties
{
	GroupNames.Add("Zvampext")
	ZvampextBuildID="ServerExtMut V2.1.0 2026-05-22 public-release"

	// Main devs
	DevList.Add("0x0110000100E8984E") // Marco
	DevList.Add("0x01100001023DF8A8") // ForrestMarkX

	// Some fixes and changes
	DevList.Add("0x011000010AF1C7CA") // inklesspen
	DevList.Add("0x011000010276FBCB") // GenZmeY

	WebConfigs.Add((PropType=0,PropName="StatFileDir",UIName="Stat File Dir",UIDesc="Location of the stat files on the HDD (%s = unique player ID)"))
	WebConfigs.Add((PropType=0,PropName="ForcedMaxPlayers",UIName="Server Max Players",UIDesc="A forced max players value of the server (0 = use standard KF2 setting)"))
	WebConfigs.Add((PropType=0,PropName="PlayerRespawnTime",UIName="Respawn Time",UIDesc="Players respawn time in seconds after they die (0 = no respawning)"))
	WebConfigs.Add((PropType=0,PropName="PostGameRespawnCost",UIName="Post-Game Respawn Cost",UIDesc="Amount of dosh it'll cost to be respawned after end-game (only for custom gametypes that support this)."))
	WebConfigs.Add((PropType=0,PropName="DoshThrowAmount",UIName="Dosh Throw Amount",UIDesc="Amount of dosh dropped per money throw."))
	WebConfigs.Add((PropType=1,PropName="bPlayerProgressWaveVoteEnabled",UIName="Enable Player ProgressWave Vote",UIDesc="Allow players to call Zvote progresswave <waves>."))
	WebConfigs.Add((PropType=0,PropName="PlayerProgressWaveVoteMax",UIName="Player ProgressWave Max",UIDesc="Maximum wave jump a player vote can request."))
	WebConfigs.Add((PropType=0,PropName="PlayerProgressWaveVotePct",UIName="Player ProgressWave Vote Pct",UIDesc="Fraction of eligible players needed for ProgressWave vote success, for example 0.51."))
	WebConfigs.Add((PropType=0,PropName="PlayerProgressWaveVoteSeconds",UIName="Player ProgressWave Vote Seconds",UIDesc="Seconds before a player ProgressWave vote expires."))
	WebConfigs.Add((PropType=1,PropName="bNextMapChoiceEnabled",UIName="Enable Next Map Choice",UIDesc="At the configured wave, ask players to keep playing or open mapvote."))
	WebConfigs.Add((PropType=0,PropName="NextMapChoiceWave",UIName="Next Map Choice Wave",UIDesc="Wave number that opens the Keep Playing / Next Map prompt. 0 disables until configured."))
	WebConfigs.Add((PropType=0,PropName="NextMapChoicePct",UIName="Next Map Choice Vote Pct",UIDesc="Fraction of eligible players needed to open mapvote, for example 0.51."))
	WebConfigs.Add((PropType=0,PropName="NextMapChoiceSeconds",UIName="Next Map Choice Seconds",UIDesc="Seconds before the Keep Playing / Next Map vote expires."))
	WebConfigs.Add((PropType=0,PropName="StatAutoSaveWaves",UIName="Stat Auto-Save Waves",UIDesc="How often should stats be auto-saved (1 = every wave, 2 = every second wave etc)"))
	WebConfigs.Add((PropType=0,PropName="MinUnloadPerkLevel",UIName="Min Unload Perk Level",UIDesc="Minimum level a player should be on before they can use the perk stat unload (-1 = never)."))
	WebConfigs.Add((PropType=0,PropName="UnloadPerkExpCost",UIName="Perk Unload XP Cost",UIDesc="The percent of XP it costs for a player to use a perk unload (1 = all XP, 0 = none)."))
	WebConfigs.Add((PropType=1,PropName="bKillMessages",UIName="Show Kill Messages",UIDesc="Display on players HUD a kill counter every time they kill something"))
	WebConfigs.Add((PropType=0,PropName="LargeMonsterHP",UIName="Large Monster HP",UIDesc="If the enemy kill a monster with more HP then this, broadcast kill message to everyone"))
	WebConfigs.Add((PropType=1,PropName="bDamageMessages",UIName="Show Damage Messages",UIDesc="Display on players HUD a damage counter every time they damage an enemy"))
	WebConfigs.Add((PropType=1,PropName="bEnableMapVote",UIName="Enable MapVote",UIDesc="Enable MapVote X on this server"))
	WebConfigs.Add((PropType=1,PropName="bNoBoomstickJumping",UIName="No Boomstick Jumps",UIDesc="Disable boomstick knockback, so people can't glitch with it on maps"))
	WebConfigs.Add((PropType=1,PropName="bNoAdminCommands",UIName="Disable Admin menu",UIDesc="Disable admin menu commands so admins can't modify XP or levels of players"))
	WebConfigs.Add((PropType=1,PropName="bRevampTraderGuard",UIName="Enable TraderGuard",UIDesc="Enable revamp trader-time protection controls for Endless servers"))
	WebConfigs.Add((PropType=1,PropName="bRevampTraderGuardBlockSkip",UIName="TraderGuard Blocks Skip",UIDesc="Block non-admin skip-trader votes while TraderGuard is enabled"))
	WebConfigs.Add((PropType=1,PropName="bRevampTraderGuardPublicOpenTrader",UIName="Public Open Trader",UIDesc="Let non-admin players use RvOpenTrader while TraderGuard is enabled"))
	WebConfigs.Add((PropType=1,PropName="bZvampextAutoEnableCheats",UIName="Auto Enable Admin Cheats",UIDesc="Automatically request Admin EnableCheats for configured Zvampext admins after login."))
	WebConfigs.Add((PropType=1,PropName="bZvampextUIOnly",UIName="Zvampext UI Only",UIDesc="Keep ServerExt/Zvampext UI plumbing active while skipping pawn replacement, compatibility defaults, and custom trader item injection for experimental use with another Game= class."))
	WebConfigs.Add((PropType=1,PropName="bVampUIEndMatchEnabled",UIName="Vamp UI End Match Handoff",UIDesc="Close Zvampext custom UI after victory or defeat so vanilla endmatch and mapvote UI can take over."))
	WebConfigs.Add((PropType=1,PropName="bAdminGrenadeDamage",UIName="Override Grenade Damage",UIDesc="Admin/server-rule toggle for custom grenade damage scaling."))
	WebConfigs.Add((PropType=0,PropName="AdminGrenadeDamageValue",UIName="Grenade Damage Value",UIDesc="Custom grenade damage scale used when Override Grenade Damage is enabled."))
	WebConfigs.Add((PropType=1,PropName="bAdminGrenadeRadius",UIName="Override Grenade Radius",UIDesc="Admin/server-rule toggle for custom grenade radius scaling."))
	WebConfigs.Add((PropType=0,PropName="AdminGrenadeRadiusValue",UIName="Grenade Radius Value",UIDesc="Custom grenade radius scale used when Override Grenade Radius is enabled."))
	WebConfigs.Add((PropType=1,PropName="bAdminAmmoPickup",UIName="Override Ammo Pickup",UIDesc="Admin/server-rule toggle for custom ammo pickup scaling."))
	WebConfigs.Add((PropType=0,PropName="AdminAmmoPickupValue",UIName="Ammo Pickup Value",UIDesc="Custom ammo pickup scale used when Override Ammo Pickup is enabled."))
	WebConfigs.Add((PropType=1,PropName="bAdminItemPickup",UIName="Override Item Pickup",UIDesc="Admin/server-rule toggle for custom item pickup scaling."))
	WebConfigs.Add((PropType=0,PropName="AdminItemPickupValue",UIName="Item Pickup Value",UIDesc="Custom item pickup scale used when Override Item Pickup is enabled."))
	WebConfigs.Add((PropType=1,PropName="bAdminArmorPickup",UIName="Override Armor Pickup",UIDesc="Admin/server-rule toggle for custom armor pickup scaling."))
	WebConfigs.Add((PropType=0,PropName="AdminArmorPickupValue",UIName="Armor Pickup Value",UIDesc="Custom armor pickup scale used when Override Armor Pickup is enabled."))
	WebConfigs.Add((PropType=2,PropName="SpawnedPerkUILayout",UIName="Spawned Perk UI Layout",UIDesc="Semicolon-separated spawned perk menu layout chunks; split long layout text across multiple rows to keep the server config stable.",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="MidGameMenuLayout",UIName="Midgame Menu Layout",UIDesc="Semicolon-separated midgame menu shell/pager/button/color layout chunks; split long layout text across multiple rows to keep the server config stable.",NumElements=-1))
	WebConfigs.Add((PropType=1,PropName="bDumpXMLStats",UIName="Dump XML stats",UIDesc="Dump XML stat files for some external stat loggers"))
	WebConfigs.Add((PropType=1,PropName="bRagdollFromFall",UIName="Ragdoll From Fall",UIDesc="Make players ragdoll if they fall from a high place"))
	WebConfigs.Add((PropType=1,PropName="bRagdollFromMomentum",UIName="Ragdoll From Momentum",UIDesc="Make players ragdoll if they take a damage with high momentum transfer"))
	WebConfigs.Add((PropType=1,PropName="bRagdollFromBackhit",UIName="Ragdoll From Backhit",UIDesc="Make players ragdoll if they take a big hit to their back"))
	WebConfigs.Add((PropType=1,PropName="bAddCountryTags",UIName="Add Country Tags",UIDesc="Add player country tags to their names"))
	WebConfigs.Add((PropType=1,PropName="bThrowAllWeaponsOnDeath",UIName="Throw all weapons on death",UIDesc="Forces players to throw all their weapons on death"))
	WebConfigs.Add((PropType=0,PropName="MaxTopPlayers",UIName="Max top players",UIDesc="Maximum top players to broadcast of and to keep track of."))
	WebConfigs.Add((PropType=2,PropName="PerkClasses",UIName="Perk Classes",UIDesc="List of RPG perks players can play as (careful with removing them, because any perks removed will permanently delete the gained XP for every player for that perk)!",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="CustomChars",UIName="Custom Chars",UIDesc="List of custom characters for this server (prefix with * to mark as admin character).",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="AdminCommands",UIName="Admin Commands",UIDesc="List of Admin commands to show on scoreboard UI for admins (use : to split actual command with display name for the command)",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="RevampAdminSteamIDs",UIName="Zvampext Admin SteamIDs",UIDesc="Steam Unique IDs that should automatically receive Zvampext admin UI access, for example 0x0110000104BC56AA.",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="ZvampextAdminIDs",UIName="Zvampext Admin IDs",UIDesc="Admin IDs accepted as SteamID64, STEAM_0:X:Y, or KF2 hex UniqueNetId.",NumElements=-1))
	WebConfigs.Add((PropType=3,PropName="ServerMOTD",UIName="MOTD",UIDesc="Message of the Day"))
	WebConfigs.Add((PropType=2,PropName="BonusGameSongs",UIName="Bonus Game Songs",UIDesc="List of custom musics to play during level change pong game.",NumElements=-1))
	WebConfigs.Add((PropType=2,PropName="BonusGameFX",UIName="Bonus Game FX",UIDesc="List of custom FX to play on pong game.",NumElements=-1))
}
