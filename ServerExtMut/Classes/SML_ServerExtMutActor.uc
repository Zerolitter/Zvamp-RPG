class SML_ServerExtMutActor extends Info
	config(ServerExtMut);

struct FSMLDamageHistoryMark
{
	var KFPawn_Monster Zed;
	var Controller Damager;
	var int TotalDamage;
};

var config array<string> PerkClasses, AdminCommands, SpawnedPerkUILayout, MidGameMenuLayout, RevampAdminSteamIDs, ZvampextAdminIDs, AutoMessageTexts;
var config int ForcedMaxPlayers, MinUnloadPerkLevel, MaxTopPlayers, AutoHealingAmount, DoshThrowAmount, AutoMessageIntervalSeconds;
var config float UnloadPerkExpCost, AdminGrenadeDamageValue, AdminGrenadeRadiusValue, AdminAmmoPickupValue, AdminItemPickupValue, AdminArmorPickupValue, ZvampextTraderSpeedBoostMultiplier, ZvampextMissingZedGraceSeconds;
var config bool bNoAdminCommands, bRevampTraderGuard, bRevampTraderGuardBlockSkip, bRevampTraderGuardPublicOpenTrader, bVampUIEndMatchEnabled, bEnableAutoHealing, bEnableAutoHealingChat;
var config bool bZvampextAutoEnableCheats, bZvampextAutoPauseTrader, bZvampextTraderSpeedBoost, bZvampextEnableMissingZedWaveGuard, bAdminGrenadeDamage, bAdminGrenadeRadius, bAdminAmmoPickup, bAdminItemPickup, bAdminArmorPickup;
var string ZvampextBuildID;
var globalconfig string ServerMOTD, StatFileDir;
var config string AutoMessageText, AutoMessageColor;
var array<class<Ext_PerkBase> > LoadedPerks;
var array<ExtHumanPawn> SMLInitializedPawns;
var transient array<FSMLDamageHistoryMark> SMLDamageHistoryMarks;
var transient array<KFPawn_Monster> SMLXPProcessedZeds;
var ExtPlayerStat ServerStatLoader;
var bool bGameHasEnded, bZvampextTraderItemsApplied, bSMLTraderAutoPaused, bRevampSpawnsPaused, bSMLDamageMessages;
var config bool bAutoMessageEnabled;
var transient float NextAutoMessageTime;
var transient float SMLNoLiveZedSince;
var transient int SMLMissingZedWatchWave, AutoMessageIndex;

event PreBeginPlay()
{
	super.PreBeginPlay();

	if (WorldInfo.NetMode == NM_Client)
		return;

	SetupGameClasses();
	bSMLDamageMessages = class'ServerExtMut'.default.bDamageMessages;
	if (DoshThrowAmount <= 0)
	{
		DoshThrowAmount = 50;
		SaveConfig();
	}
	if (ForcedMaxPlayers > 0)
	{
		SetMaxPlayers();
		SetTimer(0.1f, false, 'SetMaxPlayers');
	}
	LoadPerks();
	ServerStatLoader = new(None) class'ExtPlayerStat';
	SetTimer(1.f, true, 'AutoHealingTick');
	SetTimer(1.f, true, 'MaintainSMLTraderFeatures');
	SetTimer(1.f, true, 'MissingZedWaveGuard');
	SetTimer(1.f, true, 'AutoMessageTick');
	SetTimer(0.5f, true, 'MonitorSMLSpawnedPlayers');
	SetTimer(0.1f, true, 'SMLDamageMessageTick');
	SetTimer(1.f, false, 'ApplyZvampextTraderItems');
	`log("[SMLCompat] Active Info runtime ServerExtMut.SML_ServerExtMutActor");
}

final function SetupGameClasses()
{
	if (WorldInfo == None || WorldInfo.Game == None)
		return;

	WorldInfo.Game.HUDType = class'KFExtendedHUD';
	WorldInfo.Game.PlayerControllerClass = class'ExtPlayerController';
	WorldInfo.Game.PlayerReplicationInfoClass = class'ExtPlayerReplicationInfo';
	WorldInfo.Game.DefaultPawnClass = class'ExtHumanPawn';
	if (KFGameInfo(WorldInfo.Game) != None)
	{
		KFGameInfo(WorldInfo.Game).CustomizationPawnClass = class'ExtPawn_Customization';
		KFGameInfo(WorldInfo.Game).KFGFxManagerClass = class'ExtMoviePlayer_Manager';
	}
}

function SetMaxPlayers()
{
	local OnlineGameSettings GameSettings;

	if (WorldInfo == None || WorldInfo.Game == None || ForcedMaxPlayers <= 0)
		return;

	WorldInfo.Game.MaxPlayers = ForcedMaxPlayers;
	WorldInfo.Game.MaxPlayersAllowed = ForcedMaxPlayers;
	if (WorldInfo.Game.GameInterface != None)
	{
		GameSettings = WorldInfo.Game.GameInterface.GetGameSettings(WorldInfo.Game.PlayerReplicationInfoClass.default.SessionName);
		if (GameSettings != None)
			GameSettings.NumPublicConnections = ForcedMaxPlayers;
	}
	`log("[SMLCompat] Forced max players advertised as "$ForcedMaxPlayers);
}

final function LoadPerks()
{
	local int i;
	local class<Ext_PerkBase> PK;

	if (PerkClasses.Length == 0)
	{
		PerkClasses.AddItem("ServerExt.Ext_PerkBerserker");
		PerkClasses.AddItem("ServerExt.Ext_PerkCommando");
		PerkClasses.AddItem("ServerExt.Ext_PerkFieldMedic");
		PerkClasses.AddItem("ServerExt.Ext_PerkSupport");
		PerkClasses.AddItem("ServerExt.Ext_PerkDemolition");
		PerkClasses.AddItem("ServerExt.Ext_PerkFirebug");
		PerkClasses.AddItem("ServerExt.Ext_PerkGunslinger");
		PerkClasses.AddItem("ServerExt.Ext_PerkSharpshooter");
		PerkClasses.AddItem("ServerExt.Ext_PerkSWAT");
		PerkClasses.AddItem("ServerExt.Ext_PerkSurvivalist");
		SaveConfig();
	}

	for (i=0; i<PerkClasses.Length; ++i)
	{
		if (PerkClasses[i] == "")
			continue;
		PK = class<Ext_PerkBase>(DynamicLoadObject(PerkClasses[i], class'Class'));
		if (PK != None && LoadedPerks.Find(PK) == INDEX_NONE)
		{
			PK.static.CheckConfig();
			LoadedPerks.AddItem(PK);
		}
		else if (PK == None)
		{
			`log("[SMLCompat] Failed to load perk class" @ PerkClasses[i]);
		}
	}
}

simulated function vector GetTargetLocation(optional Actor RequestedBy, optional bool bRequestAlternateLoc)
{
	local Controller C;

	C = Controller(RequestedBy);
	if (C != None)
	{
		if (bRequestAlternateLoc)
			HandleLogout(C);
		else
			HandleLogin(C);
	}

	return Super.GetTargetLocation(RequestedBy, bRequestAlternateLoc);
}

final function HandleLogin(Controller NewPlayer)
{
	local ExtPlayerController EPC;
	local ExtPlayerReplicationInfo EPRI;

	EPC = ExtPlayerController(NewPlayer);
	if (EPC == None)
		return;

	EPRI = ExtPlayerReplicationInfo(EPC.PlayerReplicationInfo);
	if (EPRI != None)
		GrantRevampAdminIfConfigured(EPRI);
	InitializePerks(EPC);
	SendMOTD(EPC);
}

final function HandleLogout(Controller Exiting)
{
	if (!bGameHasEnded && ExtPlayerController(Exiting) != None)
		SavePlayerPerk(ExtPlayerController(Exiting));
}

final function InitializePerks(ExtPlayerController Other)
{
	local ExtPerkManager PM;
	local Ext_PerkBase P;
	local int i;

	if (Other == None)
		return;

	Other.OnChangePerk = PlayerChangePerk;
	Other.OnBoughtStats = PlayerBuyStats;
	Other.OnBoughtTrait = PlayerBoughtTrait;
	Other.OnPerkReset = ResetPlayerPerk;
	Other.OnRequestUnload = PlayerUnloadInfo;
	Other.OnSetMOTD = AdminSetMOTD;
	Other.OnAdminHandle = AdminCommand;
	Other.OnAdminRevampAction = AdminRevampAction;
	Other.OnAdminSetTraderGuard = AdminSetTraderGuard;
	Other.OnAdminSetPickupOverrides = AdminSetPickupOverrides;
	Other.OnAdminFastForwardTrader = AdminFastForwardTrader;
	Other.OnAdminOpenTrader = AdminOpenTrader;
	Other.OnPublicOpenTrader = PublicOpenTrader;
	Other.OnRefreshNewItems = RefreshNewItemsFor;
	Other.OnAdminGiveDosh = AdminGiveDosh;
	Other.OnAdminSetDoshThrowAmount = AdminSetDoshThrowAmount;
	Other.OnAdminSetAutoMessage = AdminSetAutoMessage;
	Other.OnAdminProgressWave = AdminProgressWave;
	Other.OnAdminBuildID = AdminBuildID;
	Other.OnClientGetStat = class'ExtStatList'.Static.GetStat;

	PM = Other.ActivePerkManager;
	if (PM == None)
	{
		PM = Other.Spawn(class'ExtPerkManager', Other);
		Other.ActivePerkManager = PM;
		PM.PlayerOwner = Other;
		PM.PRIOwner = ExtPlayerReplicationInfo(Other.PlayerReplicationInfo);
		if (PM.PRIOwner != None)
			PM.PRIOwner.PerkManager = PM;
		PM.bForceNetUpdate = true;
		Other.bForceNetUpdate = true;
	}

	PM.InitPerks();
	for (i=0; i<LoadedPerks.Length; ++i)
	{
		P = Spawn(LoadedPerks[i], Other);
		PM.RegisterPerk(P);
	}

	ServerStatLoader.FlushData();
	if (ServerStatLoader.LoadStatFile(Other))
	{
		ServerStatLoader.ToStart();
		PM.LoadData(ServerStatLoader);
		if (MaxTopPlayers > 0)
			class'ExtStatList'.Static.SetTopPlayers(Other);
	}
	PM.ServerInitPerks();
	PM.InitiateClientRep();
	SyncSMLPerkLevel(Other);
	if (PM.ZvampextNeedsReplicationKick())
		SetTimer(1.f, true, 'PerkReplicationWatchdog');
}

function PerkReplicationWatchdog()
{
	local ExtPlayerController PC;
	local bool bNeedRetry;

	foreach WorldInfo.AllControllers(class'ExtPlayerController', PC)
	{
		if (PC != None && PC.ActivePerkManager != None && PC.ActivePerkManager.ZvampextNeedsReplicationKick())
		{
			PC.ActivePerkManager.ZvampextKickClientReplication();
			bNeedRetry = true;
		}
	}

	if (!bNeedRetry)
		ClearTimer('PerkReplicationWatchdog');
}

final function SendMOTD(ExtPlayerController PC)
{
	local string S;
	local int i;

	if (PC == None)
		return;

	S = ServerMOTD;
	while (Len(S) > 510)
	{
		PC.ReceiveServerMOTD(Left(S, 500), false);
		S = Mid(S, 500);
	}
	PC.ReceiveServerMOTD(S, true);

	for (i=0; i<AdminCommands.Length; ++i)
		PC.AddAdminCmd(AdminCommands[i]);
	PC.ClientSetRevampTraderGuard(bRevampTraderGuard, bRevampTraderGuardBlockSkip, bRevampTraderGuardPublicOpenTrader);
	PC.ClientSetVampUIEndMatchEnabled(bVampUIEndMatchEnabled);
	PC.ClientSetAdminPickupOverrides(bAdminGrenadeDamage, AdminGrenadeDamageValue, bAdminGrenadeRadius, AdminGrenadeRadiusValue, bAdminAmmoPickup, AdminAmmoPickupValue, bAdminItemPickup, AdminItemPickupValue, bAdminArmorPickup, AdminArmorPickupValue);
	PC.ClientRefreshZvampextSettings();
	SendMidGameMenuLayout(PC);
	SendSpawnedPerkUILayout(PC);
	SendZvampextTraderItems(PC);
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

final function SendSpawnedPerkUILayout(ExtPlayerController PC)
{
	local int i;

	if (PC == None)
		return;

	PC.ClientClearSpawnedPerkUILayout();
	if (SpawnedPerkUILayout.Length == 0)
	{
		PC.ClientAddSpawnedPerkUILayoutChunk(DefaultSpawnedPerkUILayout());
		return;
	}
	for (i=0; i<SpawnedPerkUILayout.Length; ++i)
		PC.ClientAddSpawnedPerkUILayoutChunk(SpawnedPerkUILayout[i]);
}

final function SendMidGameMenuLayout(ExtPlayerController PC)
{
	local int i;

	if (PC == None)
		return;

	PC.ClientClearMidGameMenuLayout();
	if (MidGameMenuLayout.Length == 0)
	{
		PC.ClientAddMidGameMenuLayoutChunk(DefaultMidGameMenuLayout());
		return;
	}
	for (i=0; i<MidGameMenuLayout.Length; ++i)
		PC.ClientAddMidGameMenuLayoutChunk(MidGameMenuLayout[i]);
}

final function SavePlayerPerk(ExtPlayerController PC)
{
	if (PC == None || PC.ActivePerkManager == None || !PC.ActivePerkManager.bStatsDirty)
		return;

	SyncSMLPerkLevel(PC);
	ServerStatLoader.FlushData();
	if (ServerStatLoader.LoadStatFile(PC) && ServerStatLoader.GetSaveVersion() != PC.ActivePerkManager.UserDataVersion)
	{
		PC.ActivePerkManager.bUserStatsBroken = true;
		PC.ClientMessage("Warning: stat save version differs from loaded data; saving disabled.", 'Priority');
		return;
	}

	ServerStatLoader.FlushData();
	PC.ActivePerkManager.SaveData(ServerStatLoader);
	ServerStatLoader.SaveStatFile(PC);
	PC.ActivePerkManager.bStatsDirty = false;
}

final function SaveAllSMLPerks(optional bool bOnEndGame)
{
	local ExtPlayerController PC;

	foreach WorldInfo.AllControllers(class'ExtPlayerController', PC)
	{
		if (PC == None || PC.ActivePerkManager == None)
			continue;

		if (bOnEndGame)
			CheckSMLPerkChange(PC);
		SyncSMLPerkLevel(PC);
		if (PC.ActivePerkManager.bStatsDirty)
			SavePlayerPerk(PC);
	}
}

final function CheckSMLPerkChange(ExtPlayerController PC)
{
	if (PC == None || PC.ActivePerkManager == None || PC.PendingPerkClass == None)
		return;

	if (PC.ActivePerkManager.ApplyPerkClass(PC.PendingPerkClass))
	{
		PC.ClientMessage("You have changed your perk to "$PC.PendingPerkClass.Default.PerkName);
		PC.bSetPerk = true;
	}
	else PC.ClientMessage("Invalid perk "$PC.PendingPerkClass.Default.PerkName);
	PC.PendingPerkClass = None;
}

final function SyncSMLPerkLevel(ExtPlayerController PC)
{
	local ExtPerkManager PM;
	local ExtPlayerReplicationInfo EPRI;

	if (PC == None || PC.ActivePerkManager == None)
		return;

	PM = PC.ActivePerkManager;
	EPRI = ExtPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if (EPRI == None)
		return;

	PM.PRIOwner = EPRI;
	EPRI.PerkManager = PM;
	EPRI.RepKills = PM.TotalKills;
	EPRI.RepEXP = PM.TotalEXP;
	EPRI.SetInitPlayTime(PM.TotalPlayTime);
	if (PM.CurrentPerk != None)
	{
		EPRI.ECurrentPerk = PM.CurrentPerk.Class;
		EPRI.CurrentPerkClass = PM.CurrentPerk.BasePerk;
		PM.CurrentPerk.UpdatePRILevel();
		PC.SyncZvampextPerkToStock();
	}
	EPRI.bForceNetUpdate = true;
	PC.bForceNetUpdate = true;
}

final function bool HasPrivs(ExtPlayerReplicationInfo P)
{
	return WorldInfo.NetMode == NM_StandAlone || (P != None && P.ShowAdminName() && (P.AdminType <= AT_Admin || P.AdminType == AT_Player));
}

static final function string TrimAdminID(string S)
{
	local int i;

	i = InStr(S, ";");
	if (i != INDEX_NONE)
		S = Left(S, i);
	while (Len(S) > 0 && (Left(S, 1) == " " || Left(S, 1) == Chr(9)))
		S = Mid(S, 1);
	while (Len(S) > 0 && (Right(S, 1) == " " || Right(S, 1) == Chr(9)))
		S = Left(S, Len(S)-1);
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
	local int i, D, C, V;
	local string R;

	C = 0;
	for (i=Len(S)-1; i>=0; --i)
	{
		D = int(Mid(S, i, 1));
		V = D * 2 + C;
		R = string(V % 10) $ R;
		C = V / 10;
	}
	if (C > 0)
		R = string(C) $ R;
	return R;
}

static final function string DecimalAddSmall(string S, int Add)
{
	local int i, D, C, V;
	local string R;

	C = Add;
	for (i=Len(S)-1; i>=0; --i)
	{
		D = int(Mid(S, i, 1));
		V = D + C;
		R = string(V % 10) $ R;
		C = V / 10;
	}
	while (C > 0)
	{
		R = string(C % 10) $ R;
		C = C / 10;
	}
	while (Len(R) > 1 && Left(R, 1) == "0")
		R = Mid(R, 1);
	return R;
}

static final function string HexToDecimalString(string Hex)
{
	local int i, j, N;
	local string R;

	R = "0";
	if (Left(Hex, 2) ~= "0x")
		j = 2;
	for (i=j; i<Len(Hex); ++i)
	{
		for (N=0; N<4; ++N)
			R = DecimalDouble(R);
		R = DecimalAddSmall(R, HexDigit(Mid(Hex, i, 1)));
	}
	return R;
}

static final function int HexToAccountInt(string Hex)
{
	local int i, j, R;

	j = Max(Len(Hex)-8, 0);
	for (i=j; i<Len(Hex); ++i)
		R = R * 16 + HexDigit(Mid(Hex, i, 1));
	return R;
}

static final function string HexToSteam2String(string Hex)
{
	local int Account, Y, Z;

	Account = HexToAccountInt(Hex);
	Y = Account % 2;
	Z = Account / 2;
	return "STEAM_0:" $ Y $ ":" $ Z;
}

final function bool AdminIDMatches(string ConfigID, string HexID, string Steam64ID, string Steam2ID)
{
	ConfigID = TrimAdminID(ConfigID);
	if (ConfigID == "" || ConfigID ~= "0x0000000000000000")
		return false;
	return ConfigID ~= HexID || ConfigID ~= Steam64ID || ConfigID ~= Steam2ID;
}

final function bool IsRevampAdmin(const out UniqueNetId UID)
{
	local int i;
	local string HexID, Steam64ID, Steam2ID;

	HexID = class'OnlineSubsystem'.static.UniqueNetIdToString(UID);
	Steam64ID = HexToDecimalString(HexID);
	Steam2ID = HexToSteam2String(HexID);
	for (i=RevampAdminSteamIDs.Length-1; i>=0; --i)
		if (AdminIDMatches(RevampAdminSteamIDs[i], HexID, Steam64ID, Steam2ID))
			return true;
	for (i=ZvampextAdminIDs.Length-1; i>=0; --i)
		if (AdminIDMatches(ZvampextAdminIDs[i], HexID, Steam64ID, Steam2ID))
			return true;
	return false;
}

final function GrantRevampAdminIfConfigured(ExtPlayerReplicationInfo PRI)
{
	local ExtPlayerController PC;

	if (PRI == None || !IsRevampAdmin(PRI.UniqueId))
		return;

	PC = ExtPlayerController(PRI.Owner);
	PRI.bAdmin = true;
	PRI.AdminType = AT_Admin;
	PRI.bForceNetUpdate = true;
	`log("[SMLCompat] granted Zvampext admin access to "$PRI.PlayerName@"("$class'OnlineSubsystem'.static.UniqueNetIdToString(PRI.UniqueId)$")");
	if (bZvampextAutoEnableCheats && PC != None)
	{
		PC.AddCheats(true);
		PC.ClientMessage("Zvampext admin cheats enabled.", 'Priority');
		`log("[SMLCompat] enabled admin cheats for "$PRI.PlayerName);
	}
}

function PlayerBuyStats(ExtPlayerController PC, class<Ext_PerkBase> Perk, int iStat, int Amount)
{
	local Ext_PerkBase P;
	local int Cost;

	if (bGameHasEnded || PC == None || PC.ActivePerkManager == None)
		return;

	P = PC.ActivePerkManager.FindPerk(Perk);
	if (P == None || !P.bPerkNetReady || iStat >= P.PerkStats.Length)
		return;

	Amount = Max(Amount, 1);
	Amount = Min(Amount, P.PerkStats[iStat].MaxValue - P.PerkStats[iStat].CurrentValue);
	if (Amount <= 0)
		return;

	Cost = Amount * P.PerkStats[iStat].CostPerValue;
	if (Cost > P.CurrentSP)
	{
		Amount = P.CurrentSP / P.PerkStats[iStat].CostPerValue;
		if (Amount <= 0)
			return;
		Cost = Amount * P.PerkStats[iStat].CostPerValue;
	}

	P.CurrentSP -= Cost;
	if (P.bOwnerNetClient)
		P.ClientSetCurrentSP(P.CurrentSP);
	if (!P.IncrementStat(iStat, Amount))
		PC.ClientMessage("Failed to buy stat.");
	else SavePlayerPerk(PC);
}

function PlayerChangePerk(ExtPlayerController PC, class<Ext_PerkBase> NewPerk)
{
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;

	if (PC == None || PC.ActivePerkManager == None || NewPerk == None || bGameHasEnded)
		return;

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);

	if (PC.ActivePerkManager.CurrentPerk != None && NewPerk == PC.ActivePerkManager.CurrentPerk.Class)
	{
		PC.PendingPerkClass = None;
		return;
	}

	if (PC.ActivePerkManager.CurrentPerk == None || KFPawn_Customization(PC.Pawn) != None
		|| (KFGRI != None && KFGRI.bTraderIsOpen) || (KFGI != None && KFGI.GetStateName() != 'PlayingWave'))
	{
		if (PC.ActivePerkManager.ApplyPerkClass(NewPerk))
		{
			PC.ClientMessage("You have changed your perk to "$NewPerk.default.PerkName);
			PC.bSetPerk = true;
			PC.SyncZvampextPerkToStock();
			InitSMLPlayer(ExtHumanPawn(PC.Pawn));
		}
		return;
	}

	PC.PendingPerkClass = NewPerk;
	PC.ClientMessage("You will change to perk '"$NewPerk.default.PerkName$"' during trader time.");
}

function PlayerBoughtTrait(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, class<Ext_TraitBase> Trait)
{
	local Ext_PerkBase P;
	local int i, Cost;

	if (PC == None || PC.ActivePerkManager == None || bGameHasEnded)
		return;

	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if (P == None || !P.bPerkNetReady)
		return;

	for (i=0; i<P.PerkTraits.Length; ++i)
	{
		if (P.PerkTraits[i].TraitType == Trait)
		{
			if (P.PerkTraits[i].CurrentLevel >= Trait.default.NumLevels)
				return;
			Cost = Trait.static.GetTraitCost(P.PerkTraits[i].CurrentLevel);
			if (Cost > P.CurrentSP || !Trait.static.MeetsRequirements(P.PerkTraits[i].CurrentLevel, P))
				return;

			PC.ActivePerkManager.bStatsDirty = true;
			P.CurrentSP -= Cost;
			P.bForceNetUpdate = true;
			if (P.bOwnerNetClient)
				P.ClientSetCurrentSP(P.CurrentSP);
			++P.PerkTraits[i].CurrentLevel;
			P.ClientReceiveTraitLvl(i, P.PerkTraits[i].CurrentLevel);
			if (P.PerkTraits[i].CurrentLevel == 1)
				P.PerkTraits[i].Data = Trait.static.Initializefor(P, PC);
			if (PC.ActivePerkManager.CurrentPerk == P)
			{
				Trait.static.TraitDeActivate(P, P.PerkTraits[i].CurrentLevel-1, P.PerkTraits[i].Data);
				Trait.static.TraitActivate(P, P.PerkTraits[i].CurrentLevel, P.PerkTraits[i].Data);
				if (KFPawn_Human(PC.Pawn) != None)
				{
					Trait.static.CancelEffectOn(KFPawn_Human(PC.Pawn), P, P.PerkTraits[i].CurrentLevel-1, P.PerkTraits[i].Data);
					Trait.static.ApplyEffectOn(KFPawn_Human(PC.Pawn), P, P.PerkTraits[i].CurrentLevel, P.PerkTraits[i].Data);
				}
			}
			SavePlayerPerk(PC);
			break;
		}
	}
}

function ResetPlayerPerk(ExtPlayerController PC, class<Ext_PerkBase> PerkClass, bool bPrestige)
{
	local Ext_PerkBase P;

	if (PC == None || PC.ActivePerkManager == None || bGameHasEnded)
		return;

	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if (P == None || !P.bPerkNetReady)
		return;
	if (bPrestige)
	{
		if (!P.CanPrestige())
			return;
		++P.CurrentPrestige;
	}
	P.FullReset(bPrestige);
	PC.ActivePerkManager.bStatsDirty = true;
	SavePlayerPerk(PC);
}

function PlayerUnloadInfo(ExtPlayerController PC, byte CallID, class<Ext_PerkBase> PerkClass, bool bUnload)
{
	local Ext_PerkBase P;
	local int LostExp, NewLvl;

	if (PC == None || PerkClass == None || PC.ActivePerkManager == None)
		return;
	if (MinUnloadPerkLevel == -1)
	{
		if (!bUnload)
			PC.ClientGotUnloadInfo(CallID, 0);
		return;
	}

	P = PC.ActivePerkManager.FindPerk(PerkClass);
	if (P == None)
		return;
	if (P.CurrentLevel < MinUnloadPerkLevel)
	{
		if (!bUnload)
			PC.ClientGotUnloadInfo(CallID, 1, MinUnloadPerkLevel);
		return;
	}

	LostExp = Round(float(P.CurrentEXP) * UnloadPerkExpCost);
	if (!bUnload)
	{
		NewLvl = P.CalcLevelForExp(P.CurrentEXP - LostExp);
		PC.ClientGotUnloadInfo(CallID, 2, LostExp, P.CurrentLevel - NewLvl);
		return;
	}

	P.UnloadStats();
	P.CurrentEXP -= LostExp;
	P.SetInitialLevel();
	PC.ActivePerkManager.bStatsDirty = true;
	SavePlayerPerk(PC);
	if (PC.Pawn != None)
		PC.Pawn.Suicide();
}

function AdminSetMOTD(ExtPlayerController PC, string S)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
		return;
	ServerMOTD = S;
	SaveConfig();
}

function AdminGiveDosh(ExtPlayerController PC, int DoshAmount)
{
	local KFPlayerReplicationInfo KFPRI;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}
	KFPRI = KFPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if (KFPRI == None)
	{
		PC.ClientMessage("DoshMe failed: player replication info unavailable.", 'Priority');
		return;
	}
	DoshAmount = Clamp(DoshAmount, 1, 1000000);
	KFPRI.AddDosh(DoshAmount, true);
	KFPRI.bForceNetUpdate = true;
	PC.ClientMessage("DoshMe added "$DoshAmount$" dosh.", 'Priority');
}

function bool FastForwardTrader(ExtPlayerController PC, bool bAdminForce)
{
	local KFGameReplicationInfo KFGRI;
	local KFGameInfo KFGI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFGI = KFGameInfo(WorldInfo.Game);
	if (PC == None || KFGRI == None || KFGI == None || !KFGRI.bTraderIsOpen)
	{
		if (PC != None)
			PC.ClientMessage("Trader is not open.", 'Priority');
		return false;
	}

	KFGRI.bStopCountDown = false;
	KFGRI.RemainingTime = 1;
	KFGRI.RemainingMinute = 1;
	KFGRI.bForceNetUpdate = true;
	KFGI.SkipTrader(1);
	PC.ClientMessage(bAdminForce ? "Admin fast-forwarded trader time." : "Public fast-forwarded trader time.", 'Priority');
	return true;
}

function bool OpenTraderFor(ExtPlayerController PC, bool bAdminForce)
{
	local ExtPlayerController E;
	local KFGameReplicationInfo KFGRI;
	local KFGameInfo KFGI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFGI = KFGameInfo(WorldInfo.Game);
	if (PC == None || KFGRI == None || KFGI == None || KFGI.MyKFGRI == None)
	{
		if (PC != None)
			PC.ClientMessage("Open trader is unavailable in this game state.", 'Priority');
		return false;
	}

	if (!KFGRI.bTraderIsOpen)
	{
		KFGI.MyKFGRI.bTraderIsOpen = true;
		if (KFGI.MyKFGRI.NextTrader != None)
			KFGI.MyKFGRI.OpenTrader(300);
		else if (KFGI.ScriptedTrader != None || KFGI.TraderList.Length > 0)
			KFGI.MyKFGRI.OpenTraderNext(300);
		else
		{
			PC.ClientMessage("Open trader failed: this map has no trader pod.", 'Priority');
			return false;
		}

		foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
			E.ClientMessage((bAdminForce ? "Admin opened trader time." : "Trader time opened."), 'Priority');
	}

	PC.OpenTraderMenu(true);
	PC.ClientRevampOpenTraderMenu();
	return true;
}

function PublicOpenTrader(ExtPlayerController PC)
{
	if (!bRevampTraderGuard || !bRevampTraderGuardPublicOpenTrader)
	{
		if (PC != None)
			PC.ClientMessage("Public open trader is disabled.", 'Priority');
		return;
	}
	OpenTraderFor(PC, false);
}

function AdminFastForwardTrader(ExtPlayerController PC)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}
	FastForwardTrader(PC, true);
}

function AdminOpenTrader(ExtPlayerController PC)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}
	OpenTraderFor(PC, true);
}

function AdminSetTraderGuard(ExtPlayerController PC, bool bEnabled, bool bBlockSkip, bool bPublicOpenTrader)
{
	local ExtPlayerController E;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	bRevampTraderGuard = bEnabled;
	bRevampTraderGuardBlockSkip = bBlockSkip;
	bRevampTraderGuardPublicOpenTrader = bPublicOpenTrader;
	SaveConfig();

	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		E.ClientSetRevampTraderGuard(bRevampTraderGuard, bRevampTraderGuardBlockSkip, bRevampTraderGuardPublicOpenTrader);

	PC.ClientMessage("TraderGuard settings updated.", 'Priority');
}

function AdminProgressWave(ExtPlayerController PC, int WaveCount)
{
	local KFGameInfo KFGI;
	local KFGameInfo_Endless EndlessGI;
	local KFGameReplicationInfo KFGRI;
	local KFAISpawnManager SpawnManager;
	local KFPawn_Monster Zed;
	local int OldWave;
	local int NewWave;
	local int Damaged;
	local int Removed;
	local int TargetWave;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGI == None || KFGRI == None)
	{
		PC.ClientMessage("ProgressWave failed: game state unavailable.", 'Priority');
		return;
	}

	EndlessGI = KFGameInfo_Endless(KFGI);
	if (EndlessGI == None)
	{
		PC.ClientMessage("ProgressWave failed: Endless game state unavailable.", 'Priority');
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
				++Damaged;
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

	if (EndlessGI != None)
		EndlessGI.WaveNum = TargetWave;
	KFGRI.WaveNum = TargetWave;
	KFGRI.AIRemaining = 0;
	KFGRI.bForceNetUpdate = true;

	ReleaseSMLTraderPause();
	EndlessGI.WaveEnded(WEC_WaveWon);
	`log("[Zvamp] ProgressWave advanced from "$OldWave$" to "$NewWave$"; damaged="$Damaged@"removed="$Removed);
	PC.ClientMessage("ProgressWave advanced from "$OldWave$" to "$NewWave$" and opened trader through wave-end flow. Removed "$Removed$" leftover zeds.", 'Priority');
}

final function bool AdminKillZed(ExtPlayerController PC, KFPawn_Monster Zed)
{
	local int KillDamage;

	if (PC == None || Zed == None || Zed.bDeleteMe || !Zed.IsAliveAndWell())
		return false;

	KillDamage = Max(Max(Zed.HealthMax, Zed.Health) + 100000, 1000000);
	Zed.TakeDamage(KillDamage, PC, Zed.Location, vect(0,0,0), class'ExtDT_Ballistic_9mm',, PC.Pawn);
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

final function int FindSMLDamageHistoryMark(KFPawn_Monster Zed, Controller Damager)
{
	local int i;

	for (i=0; i<SMLDamageHistoryMarks.Length; ++i)
	{
		if (SMLDamageHistoryMarks[i].Zed == Zed && SMLDamageHistoryMarks[i].Damager == Damager)
			return i;
	}
	return INDEX_NONE;
}

final function ExtPlayerController ResolveSMLDamageOwner(DamageInfo DI)
{
	local ExtPlayerController PC;
	local Ext_T_MonsterPRI PetPRI;

	PC = ExtPlayerController(DI.DamagerController);
	if (PC != None)
		return PC;

	if (DI.DamagerPRI != None)
	{
		PC = ExtPlayerController(DI.DamagerPRI.Owner);
		if (PC != None)
			return PC;

		PetPRI = Ext_T_MonsterPRI(DI.DamagerPRI);
		if (PetPRI != None)
			return ExtPlayerController(PetPRI.OwnerController);
	}

	PC = ResolveActorOwnerController(DI.DamagerController);
	if (PC != None)
		return PC;

	if (DI.DamagerController != None)
	{
		PC = ResolveActorOwnerController(DI.DamagerController.Pawn);
		if (PC != None)
			return PC;
	}
	return None;
}

final function ExtPlayerController ResolveActorOwnerController(Actor SourceActor)
{
	local ExtPlayerController E;
	local Actor A;
	local int Guard;

	if (SourceActor == None)
		return None;

	A = SourceActor;
	while (A != None && Guard < 8)
	{
		E = ExtPlayerController(A);
		if (E != None)
			return E;

		if (Pawn(A) != None)
		{
			E = ExtPlayerController(Pawn(A).Controller);
			if (E != None)
				return E;
		}
		if (A.Instigator != None)
		{
			E = ExtPlayerController(A.Instigator.Controller);
			if (E != None)
				return E;
		}
		if (A.Owner == None || A.Owner == A)
			return None;

		E = ExtPlayerController(A.Owner);
		if (E != None)
			return E;
		if (Pawn(A.Owner) != None)
		{
			E = ExtPlayerController(Pawn(A.Owner).Controller);
			if (E != None)
				return E;
		}

		A = A.Owner;
		++Guard;
	}
	return None;
}

final function bool PatchSMLDamageOwner(KFPawn_Monster Zed, int DamageIndex, ExtPlayerController PC)
{
	if (Zed == None || DamageIndex < 0 || DamageIndex >= Zed.DamageHistory.Length
		|| PC == None || PC.PlayerReplicationInfo == None)
	{
		return false;
	}
	if (Zed.DamageHistory[DamageIndex].DamagerController == PC)
		return false;

	Zed.DamageHistory[DamageIndex].DamagerController = PC;
	Zed.DamageHistory[DamageIndex].DamagerPRI = PC.PlayerReplicationInfo;
	if (Zed.DamageHistory[DamageIndex].DamagePerks.Length == 0)
		Zed.DamageHistory[DamageIndex].DamagePerks.AddItem(class'ExtPerkManager');
	return true;
}

final function bool IsSMLXPProcessed(KFPawn_Monster Zed)
{
	return SMLXPProcessedZeds.Find(Zed) != INDEX_NONE;
}

final function MarkSMLXPProcessed(KFPawn_Monster Zed)
{
	if (Zed != None && SMLXPProcessedZeds.Find(Zed) == INDEX_NONE)
		SMLXPProcessedZeds.AddItem(Zed);
}

final function bool IsSMLDeadZed(KFPawn_Monster Zed)
{
	return Zed != None && Zed.Health <= 0 && Zed.bPlayedDeath;
}

final function NormalizeSMLDamageOwners(KFPawn_Monster Zed)
{
	local int i;
	local ExtPlayerController PC;

	if (Zed == None)
		return;

	for (i=0; i<Zed.DamageHistory.Length; ++i)
	{
		PC = ResolveSMLDamageOwner(Zed.DamageHistory[i]);
		if (PC != None)
			PatchSMLDamageOwner(Zed, i, PC);
	}
}

final function PruneSMLDamageHistoryMarks()
{
	local int i;

	for (i=SMLDamageHistoryMarks.Length-1; i>=0; --i)
	{
		if (SMLDamageHistoryMarks[i].Zed == None || SMLDamageHistoryMarks[i].Zed.bDeleteMe
			|| SMLDamageHistoryMarks[i].Damager == None || SMLDamageHistoryMarks[i].Damager.bDeleteMe)
		{
			SMLDamageHistoryMarks.Remove(i, 1);
		}
	}

	for (i=SMLXPProcessedZeds.Length-1; i>=0; --i)
	{
		if (SMLXPProcessedZeds[i] == None || SMLXPProcessedZeds[i].bDeleteMe)
			SMLXPProcessedZeds.Remove(i, 1);
	}
}

final function AwardSMLZedXP(KFPawn_Monster Zed)
{
	local DamageInfo DI;
	local ExtPlayerController PC;
	local KFPlayerController KFPC;
	local KFPerk InstigatorPerk;
	local class<KFPerk> DamagePerk;
	local KFGameInfo KFGI;
	local int XP, Difficulty;
	local bool bAwarded;

	if (Zed == None || IsSMLXPProcessed(Zed) || !IsSMLDeadZed(Zed))
		return;

	NormalizeSMLDamageOwners(Zed);
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI != None)
		Difficulty = KFGI.GameDifficulty;
	else Difficulty = 0;
	XP = Max(Zed.static.GetXPValue(Difficulty), 0);

	foreach Zed.DamageHistory(DI)
	{
		PC = ResolveSMLDamageOwner(DI);
		if (PC == None)
			continue;

		KFPC = PC;
		if (XP <= 0)
			continue;

		InstigatorPerk = KFPC.GetPerk();
		if (InstigatorPerk == None)
			continue;

		if (InstigatorPerk.ShouldGetAllTheXP() || DI.DamagePerks.Length == 0)
		{
			KFPC.OnPlayerXPAdded(XP, InstigatorPerk.Class);
			bAwarded = true;
			continue;
		}

		foreach DI.DamagePerks(DamagePerk)
		{
			if (DamagePerk != None)
			{
				KFPC.OnPlayerXPAdded(FCeil(float(XP) / float(DI.DamagePerks.Length)), DamagePerk);
				bAwarded = true;
			}
		}
	}

	if (bAwarded)
	{
		MarkSMLXPProcessed(Zed);
		`log("[SMLCompat] Awarded passive SML zed XP for "$PathName(Zed.Class)@"XP="$XP);
	}
}

function SMLDamageMessageTick()
{
	local KFPawn_Monster Zed;
	local DamageInfo DI;
	local ExtPlayerController PC;
	local Controller Damager;
	local int TotalDamage, Delta, MarkIndex;
	local vector PopupLocation;

	PruneSMLDamageHistoryMarks();

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', Zed)
	{
		if (Zed == None || Zed.bDeleteMe || Zed.GetTeamNum() == 0)
			continue;

		NormalizeSMLDamageOwners(Zed);
		AwardSMLZedXP(Zed);
		if (!bSMLDamageMessages)
			continue;

		foreach Zed.DamageHistory(DI)
		{
			PC = ResolveSMLDamageOwner(DI);
			if (PC == None || PC.bNoDamageTracking)
				continue;

			Damager = DI.DamagerController;
			if (Damager == None)
				Damager = PC;

			TotalDamage = Max(DI.TotalDamage, DI.Damage);
			if (TotalDamage <= 0)
				continue;

			MarkIndex = FindSMLDamageHistoryMark(Zed, Damager);
			if (MarkIndex == INDEX_NONE)
			{
				MarkIndex = SMLDamageHistoryMarks.Length;
				SMLDamageHistoryMarks.Length = MarkIndex + 1;
				SMLDamageHistoryMarks[MarkIndex].Zed = Zed;
				SMLDamageHistoryMarks[MarkIndex].Damager = Damager;
				SMLDamageHistoryMarks[MarkIndex].TotalDamage = TotalDamage;
				if (WorldInfo.TimeSeconds - DI.LastTimeDamaged <= 0.35f)
					Delta = Min(Max(DI.Damage, 0), TotalDamage);
				else Delta = 0;
			}
			else
			{
				Delta = TotalDamage - SMLDamageHistoryMarks[MarkIndex].TotalDamage;
				SMLDamageHistoryMarks[MarkIndex].TotalDamage = TotalDamage;
			}

			if (Delta <= 0)
				continue;

			PopupLocation = Zed.Location + vect(0,0,50);
			if (!PC.bClientHideDamageMsg)
				PC.ReceiveDamageMessage(Zed.Class, Delta);
			if (!PC.bClientHideNumbers)
				PC.ClientNumberMsg(Delta, PopupLocation, DMG_PawnDamage);
		}
	}
}

function AdminBuildID(ExtPlayerController PC)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	PC.ClientMessage("[Zvamp] BuildID "$PC.ZvampextBuildID$" | "$ZvampextBuildID, 'Priority');
	`log("[SMLCompat] BuildID requested by "$PC.PlayerReplicationInfo.PlayerName$": "$PC.ZvampextBuildID$" | "$ZvampextBuildID);
}

function AdminSetDoshThrowAmount(ExtPlayerController PC, int NewAmount)
{
	local ExtPlayerController E;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	DoshThrowAmount = Clamp(NewAmount, 1, 1000000);
	SaveConfig();
	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		ApplyPickupOverridesToController(E);

	PC.ClientMessage("[Zvamp] DoshThrowAmount set to "$DoshThrowAmount$".", 'Priority');
	`log("[SMLCompat] DoshThrowAmount set to "$DoshThrowAmount@"by "$PC.PlayerReplicationInfo.PlayerName);
}

final function string SanitizeAutoMessageColor(string S)
{
	if (Len(S) != 6)
		return "9B7CFF";
	return Caps(S);
}

final function string ExtractAutoMessageColor(out string MessageText, string DefaultColor)
{
	local string ColorText;

	if (Len(MessageText) >= 8 && Left(MessageText, 1) == "<" && Mid(MessageText, 7, 1) == ">")
	{
		ColorText = SanitizeAutoMessageColor(Mid(MessageText, 1, 6));
		MessageText = TrimAutoMessageEntry(Mid(MessageText, 8));
		return ColorText;
	}
	return SanitizeAutoMessageColor(DefaultColor);
}

final function string TrimAutoMessageEntry(string S)
{
	while (Len(S) > 0 && (Left(S, 1) == " " || Left(S, 1) == Chr(9)))
		S = Mid(S, 1);
	while (Len(S) > 0 && (Right(S, 1) == " " || Right(S, 1) == Chr(9)))
		S = Left(S, Len(S) - 1);
	return S;
}

final function BuildAutoMessageList(string MessageText)
{
	local int SplitAt;
	local string Entry;

	AutoMessageTexts.Length = 0;
	while (MessageText != "")
	{
		SplitAt = InStr(MessageText, ";;");
		if (SplitAt >= 0)
		{
			Entry = TrimAutoMessageEntry(Left(MessageText, SplitAt));
			MessageText = Mid(MessageText, SplitAt + 2);
		}
		else
		{
			Entry = TrimAutoMessageEntry(MessageText);
			MessageText = "";
		}
		if (Entry != "")
			AutoMessageTexts.AddItem(Left(Entry, 512));
	}
	AutoMessageIndex = 0;
}

function AdminSetAutoMessage(ExtPlayerController PC, bool bEnabled, int IntervalSeconds, string MessageText, string MessageColor)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	bAutoMessageEnabled = bEnabled;
	AutoMessageIntervalSeconds = Clamp(IntervalSeconds, 30, 3600);
	AutoMessageText = Left(MessageText, 512);
	BuildAutoMessageList(MessageText);
	AutoMessageColor = SanitizeAutoMessageColor(MessageColor);
	NextAutoMessageTime = WorldInfo.TimeSeconds + AutoMessageIntervalSeconds;
	SaveConfig();
	PC.ClientMessage("Auto message "$(bAutoMessageEnabled ? "enabled." : "disabled."), 'Priority');
	`log("[SMLCompat] auto message "$(bAutoMessageEnabled ? "enabled" : "disabled")@"by "$PC.PlayerReplicationInfo.PlayerName);
}

function AutoMessageTick()
{
	local ExtPlayerController E;
	local string MessageText, MessageColor;

	if (!bAutoMessageEnabled || WorldInfo.TimeSeconds < NextAutoMessageTime || (AutoMessageText == "" && AutoMessageTexts.Length == 0))
		return;

	NextAutoMessageTime = WorldInfo.TimeSeconds + Max(AutoMessageIntervalSeconds, 30);
	if (AutoMessageTexts.Length > 0)
	{
		AutoMessageIndex = AutoMessageIndex % AutoMessageTexts.Length;
		MessageText = AutoMessageTexts[AutoMessageIndex++];
	}
	else
		MessageText = AutoMessageText;
	MessageColor = ExtractAutoMessageColor(MessageText, AutoMessageColor);
	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		E.ClientZvampextAutoMessage(MessageText, MessageColor);
}

final function InitSMLPlayer(ExtHumanPawn Other)
{
	local ExtPlayerController PC;
	local ExtPlayerReplicationInfo PRI;

	if (Other == None || Other.bDeleteMe || !Other.IsAliveAndWell())
		return;

	PC = ExtPlayerController(Other.Controller);
	PRI = ExtPlayerReplicationInfo(Other.PlayerReplicationInfo);
	if (PRI != None && PRI.PerkManager != None && PRI.PerkManager.CurrentPerk != None)
	{
		PRI.PerkManager.CurrentPerk.ApplyEffectsTo(Other);
	}
	Other.bRagdollFromFalling = false;
	Other.bRagdollFromMomentum = false;
	Other.bRagdollFromBackhit = false;
	Other.bThrowAllWeaponsOnDeath = false;
	ApplyPickupOverridesTo(Other);
	if (PC != None)
	{
		PC.ApplyPlayerDoshThrowAmount();
		PC.SyncZvampextPerkToStock();
		PC.ClientRefreshZvampextSettings();
		if (PC.ActivePerkManager != None && PC.ActivePerkManager.ZvampextNeedsReplicationKick())
		{
			PC.ActivePerkManager.ZvampextKickClientReplication(true);
			SetTimer(1.f, true, 'PerkReplicationWatchdog');
		}
	}
}

function MonitorSMLSpawnedPlayers()
{
	local int i;
	local ExtHumanPawn P;

	for (i=SMLInitializedPawns.Length-1; i>=0; --i)
	{
		if (SMLInitializedPawns[i] == None || SMLInitializedPawns[i].bDeleteMe || !SMLInitializedPawns[i].IsAliveAndWell())
			SMLInitializedPawns.Remove(i, 1);
	}

	foreach WorldInfo.AllPawns(class'ExtHumanPawn', P)
	{
		if (P != None && P.IsAliveAndWell() && SMLInitializedPawns.Find(P) == INDEX_NONE)
		{
			InitSMLPlayer(P);
			SMLInitializedPawns.AddItem(P);
			`log("[SMLCompat] initialized spawned player pawn "$P);
		}
	}
}

final function int CountLiveHostileZeds()
{
	local KFPawn_Monster Zed;
	local int Count;

	foreach WorldInfo.AllPawns(class'KFPawn_Monster', Zed)
	{
		if (Zed != None && !Zed.bDeleteMe && Zed.IsAliveAndWell()
			&& PlayerController(Zed.Controller) == None && Zed.GetTeamNum() != 0)
		{
			++Count;
		}
	}

	return Count;
}

final function int CountQueuedZedWork(KFGameInfo KFGI)
{
	local KFAISpawnManager SpawnManager;
	local int Count;

	if (KFGI == None)
		return 0;

	SpawnManager = KFGI.SpawnManager;
	if (SpawnManager == None)
		return KFGI.NumAISpawnsQueued;

	Count = KFGI.NumAISpawnsQueued + SpawnManager.LeftoverSpawnSquad.Length;
	if (SpawnManager.ActiveSpawner != None)
		Count += SpawnManager.ActiveSpawner.PendingSpawns.Length;

	return Count;
}

function MissingZedWaveGuard()
{
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;
	local int LiveZeds, QueuedZedWork, RemainingAI, CurrentWave;
	local float GraceSeconds;

	KFGI = KFGameInfo(WorldInfo.Game);
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (!bZvampextEnableMissingZedWaveGuard || KFGI == None || KFGRI == None || KFGI.SpawnManager == None
		|| KFGI.GetStateName() != 'PlayingWave' || KFGRI.bTraderIsOpen)
	{
		SMLNoLiveZedSince = 0.f;
		if (KFGRI != None)
			SMLMissingZedWatchWave = KFGRI.WaveNum;
		else SMLMissingZedWatchWave = 0;
		return;
	}

	CurrentWave = KFGRI.WaveNum;
	if (SMLMissingZedWatchWave != CurrentWave)
	{
		SMLNoLiveZedSince = 0.f;
		SMLMissingZedWatchWave = CurrentWave;
	}

	LiveZeds = CountLiveHostileZeds();
	QueuedZedWork = CountQueuedZedWork(KFGI);
	RemainingAI = KFGRI.AIRemaining;

	if (LiveZeds > 0 || (QueuedZedWork > 0 && (KFGI.AIAliveCount > 1 || RemainingAI > 1)) || (KFGI.AIAliveCount <= 0 && RemainingAI <= 0))
	{
		SMLNoLiveZedSince = 0.f;
		return;
	}

	if (SMLNoLiveZedSince <= 0.f)
	{
		SMLNoLiveZedSince = WorldInfo.TimeSeconds;
		return;
	}

	GraceSeconds = FMax(ZvampextMissingZedGraceSeconds, 5.f);
	if (WorldInfo.TimeSeconds - SMLNoLiveZedSince < GraceSeconds)
		return;

	ClearOrphanedWaveCounter(KFGI, KFGRI, "SML missing-zed guard", QueuedZedWork, GraceSeconds);
}

function ClearOrphanedWaveCounter(KFGameInfo KFGI, KFGameReplicationInfo KFGRI, string Source, int QueuedZedWork, optional float GraceSeconds)
{
	local KFGameInfo_Endless EndlessGI;

	if (KFGI == None || KFGRI == None)
		return;

	`log("[SMLCompat] cleared orphaned wave counters."
		@"Source="$Source
		@"Wave="$KFGRI.WaveNum
		@"AIAlive="$KFGI.AIAliveCount
		@"AIRemaining="$KFGRI.AIRemaining
		@"Queued="$QueuedZedWork
		@"Grace="$GraceSeconds);

	KFGI.AIAliveCount = 0;
	KFGRI.AIRemaining = 0;
	KFGRI.bForceNetUpdate = true;
	SMLNoLiveZedSince = 0.f;
	EndlessGI = KFGameInfo_Endless(KFGI);
	if (EndlessGI != None)
		EndlessGI.CheckWaveEnd();
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
}

function MaintainSMLTraderFeatures()
{
	local ExtPlayerController ExtPC;
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None && KFGRI.bMatchIsOver)
	{
		if (!bGameHasEnded)
		{
			SaveAllSMLPerks(true);
			bGameHasEnded = true;
			`log("[SMLCompat] synced perk levels and saved dirty perks for endmatch.");
		}
		ClearSMLTraderSpeedBoost();
		return;
	}
	if (KFGRI != None && KFGRI.bTraderIsOpen)
	{
		foreach WorldInfo.AllControllers(class'ExtPlayerController', ExtPC)
			CheckSMLPerkChange(ExtPC);

		if (bZvampextAutoPauseTrader)
		{
			KFGRI.bStopCountDown = true;
			KFGRI.bForceNetUpdate = true;
			if (!bSMLTraderAutoPaused)
			{
				bSMLTraderAutoPaused = true;
				`log("[SMLCompat] trader auto-hold enabled.");
			}
		}
		ApplySMLTraderSpeedBoost();
	}
	else
	{
		bSMLTraderAutoPaused = false;
		ClearSMLTraderSpeedBoost();
	}
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

function AdminCommand(ExtPlayerController PC, int PlayerID, int Action)
{
	local ExtPlayerController E;
	local int i;

	if (PC == None)
		return;
	if (bNoAdminCommands)
	{
		PC.ClientMessage("Admin level commands are disabled.", 'Priority');
		return;
	}
	if (!HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
		if (E.PlayerReplicationInfo != None && E.PlayerReplicationInfo.PlayerID == PlayerID)
			break;

	if (E == None || E.ActivePerkManager == None)
	{
		PC.ClientMessage("Action failed, missing playerID: "$PlayerID, 'Priority');
		return;
	}

	if (Action >= 100)
	{
		if (E.ActivePerkManager.CurrentPerk == None)
		{
			PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!", 'Priority');
			return;
		}
		if (Action >= 100000)
		{
			if (E.ActivePerkManager.CurrentPerk.MinLevelForPrestige < 0)
			{
				PC.ClientMessage("Perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" has prestige disabled!", 'Priority');
				return;
			}
			Action = Min(Action - 100000, E.ActivePerkManager.CurrentPerk.MaxPrestige);
			E.ActivePerkManager.CurrentPerk.CurrentPrestige = Action;
			E.ActivePerkManager.CurrentPerk.FullReset(true);
			E.ActivePerkManager.bStatsDirty = true;
			SyncSMLPerkLevel(E);
			PC.ClientMessage("Set "$E.PlayerReplicationInfo.PlayerName$"' perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" prestige level to "$Action, 'Priority');
		}
		else
		{
			Action = Clamp(Action - 100, E.ActivePerkManager.CurrentPerk.MinimumLevel, E.ActivePerkManager.CurrentPerk.MaximumLevel);
			E.ActivePerkManager.CurrentPerk.CurrentEXP = E.ActivePerkManager.CurrentPerk.GetNeededExp(Action - 1);
			E.ActivePerkManager.CurrentPerk.SetInitialLevel();
			E.ActivePerkManager.CurrentPerk.UpdatePRILevel();
			E.ActivePerkManager.bStatsDirty = true;
			SyncSMLPerkLevel(E);
			PC.ClientMessage("Set "$E.PlayerReplicationInfo.PlayerName$"' perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" level to "$Action, 'Priority');
		}
		SavePlayerPerk(E);
		return;
	}

	switch (Action)
	{
	case 0:
		for (i=0; i<E.ActivePerkManager.UserPerks.Length; ++i)
			E.ActivePerkManager.UserPerks[i].FullReset();
		PC.ClientMessage("Reset EVERY perk for "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		break;
	case 1:
		if (E.ActivePerkManager.CurrentPerk != None)
		{
			E.ActivePerkManager.CurrentPerk.FullReset();
			PC.ClientMessage("Reset perk "$E.ActivePerkManager.CurrentPerk.Default.PerkName$" for "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!", 'Priority');
		break;
	case 2:
	case 3:
	case 4:
		if (E.ActivePerkManager.CurrentPerk == None)
		{
			PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!", 'Priority');
			return;
		}
		i = (Action == 2) ? 1000 : ((Action == 3) ? 10000 : Max(E.ActivePerkManager.CurrentPerk.NextLevelEXP - E.ActivePerkManager.CurrentPerk.CurrentEXP, 0));
		E.ActivePerkManager.EarnedEXP(i);
		PC.ClientMessage("Gave "$i$" XP for "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		break;
	case 5:
		if (E.ActivePerkManager.CurrentPerk != None)
		{
			E.ActivePerkManager.CurrentPerk.UnloadStats(1);
			PC.ClientMessage("Unloaded all stats for "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!", 'Priority');
		break;
	case 6:
		if (E.ActivePerkManager.CurrentPerk != None)
		{
			E.ActivePerkManager.CurrentPerk.UnloadStats(2);
			PC.ClientMessage("Unloaded all traits for "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!", 'Priority');
		break;
	case 7:
	case 8:
		if (E.ActivePerkManager.CurrentPerk != None)
		{
			i = (Action == 7) ? 1000 : 10000;
			E.ActivePerkManager.CurrentPerk.CurrentEXP = Max(E.ActivePerkManager.CurrentPerk.CurrentEXP - i, 0);
			E.ActivePerkManager.CurrentPerk.SetInitialLevel();
			E.ActivePerkManager.CurrentPerk.UpdatePRILevel();
			E.ActivePerkManager.bStatsDirty = true;
			SyncSMLPerkLevel(E);
			SavePlayerPerk(E);
			PC.ClientMessage("Removed "$i$" XP from "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		}
		else PC.ClientMessage(E.PlayerReplicationInfo.PlayerName$" has no perk selected!!!", 'Priority');
		break;
	case 9:
		PC.ClientMessage("DEBUG info for "$E.PlayerReplicationInfo.PlayerName, 'Priority');
		PC.ClientMessage("PerkManager "$E.ActivePerkManager$" Current Perk: "$E.ActivePerkManager.CurrentPerk, 'Priority');
		PC.ClientMessage("Perks Count: "$E.ActivePerkManager.UserPerks.Length, 'Priority');
		for (i=0; i<E.ActivePerkManager.UserPerks.Length; ++i)
			PC.ClientMessage("Perk "$i$": "$E.ActivePerkManager.UserPerks[i]$" XP:"$E.ActivePerkManager.UserPerks[i].CurrentEXP$" Lv:"$E.ActivePerkManager.UserPerks[i].CurrentLevel$" Rep:"$E.ActivePerkManager.UserPerks[i].bPerkNetReady, 'Priority');
		break;
	default:
		PC.ClientMessage("Unknown admin action.", 'Priority');
		return;
	}
	if (Action>=0 && Action<=8 && E!=None && E.ActivePerkManager!=None)
	{
		E.ActivePerkManager.bStatsDirty = true;
		SavePlayerPerk(E);
	}
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
	local Controller C;
	local KFGameInfo KFGI;
	local KFGameReplicationInfo KFGRI;
	local KFPawn_Monster Zed;
	local KFAISpawnManager SpawnManager;
	local int Count, i, DifficultyIndex, PlayerIndex, LivingPlayers, NewMaxMonsters, ZedSpawnerLimit;
	local float SpawnMod;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	switch (Action)
	{
	case 10:
		foreach WorldInfo.AllControllers(class'ExtPlayerController', PC)
			SavePlayerPerk(PC);
		break;
	case 11:
		FastForwardTrader(PC, true);
		break;
	case 13:
		OpenTraderFor(PC, true);
		break;
	case 16:
		PC.bRevampGodMode = !PC.bRevampGodMode;
		if (PC.Pawn != None && PC.bRevampGodMode)
			PC.Pawn.Health = Max(PC.Pawn.Health, 1);
		PC.ClientMessage("God mode "$(PC.bRevampGodMode ? "enabled." : "disabled."), 'Priority');
		break;
	case 17:
	case 18:
		foreach WorldInfo.AllPawns(class'KFPawn_Monster', Zed)
		{
			if (Zed != None && Zed.IsAliveAndWell() && PlayerController(Zed.Controller) == None)
			{
				if (AdminKillZed(PC, Zed))
					++Count;
			}
		}
		PC.ClientMessage((Action == 18 ? "Endwave damaged " : "Damaged ")$Count$" active zeds.", 'Priority');
		break;
	case 19:
		KFGI = KFGameInfo(WorldInfo.Game);
		if (KFGI == None || KFGI.SpawnManager == None)
		{
			PC.ClientMessage("Spawn manager unavailable.", 'Priority');
			break;
		}
		bRevampSpawnsPaused = !bRevampSpawnsPaused;
		for (i=0; i<KFGI.SpawnManager.SpawnVolumes.Length; ++i)
			if (KFGI.SpawnManager.SpawnVolumes[i] != None)
				KFGI.SpawnManager.SpawnVolumes[i].bCanUseForSpawning = !bRevampSpawnsPaused;
		if (bRevampSpawnsPaused && KFGI.SpawnManager.ActiveSpawner != None)
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
		else KFGI.SpawnManager.TimeUntilNextSpawn = FMin(KFGI.SpawnManager.TimeUntilNextSpawn, 1.f);
		PC.ClientMessage(bRevampSpawnsPaused ? "Spawns paused." : "Spawns resumed.", 'Priority');
		break;
	case 20:
	case 21:
		KFGI = KFGameInfo(WorldInfo.Game);
		SpawnManager = (KFGI != None) ? KFGI.SpawnManager : None;
		if (SpawnManager == None)
		{
			PC.ClientMessage("Spawn manager unavailable.", 'Priority');
			break;
		}
		DifficultyIndex = Clamp(KFGI.GameDifficulty, 0, SpawnManager.PerDifficultyMaxMonsters.Length-1);
		foreach WorldInfo.AllControllers(class'Controller', C)
			if (C != None && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOnlySpectator && C.GetTeamNum() == 0 && C.Pawn != None && C.Pawn.Health > 0)
				++LivingPlayers;
		if (LivingPlayers <= 0)
			LivingPlayers = Max(KFGI.GetNumPlayers(), 1);
		PlayerIndex = Clamp(LivingPlayers-1, 0, SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters.Length-1);
		NewMaxMonsters = Clamp(SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters[PlayerIndex] + (Action == 20 ? 4 : -4), 1, 200);
		SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters[PlayerIndex] = NewMaxMonsters;
		ZedSpawnerLimit = ApplyZedSpawnerAliveLimit(NewMaxMonsters);
		if (KFGameReplicationInfo(WorldInfo.GRI) != None)
			KFGameReplicationInfo(WorldInfo.GRI).CurrentMaxMonsters = SpawnManager.GetMaxMonsters();
		if (ZedSpawnerLimit>=0)
			PC.ClientMessage("Max monsters now "$SpawnManager.GetMaxMonsters()$" for "$LivingPlayers$" living player(s). ZedSpawner alive limit "$ZedSpawnerLimit$".", 'Priority');
		else PC.ClientMessage("Max monsters now "$SpawnManager.GetMaxMonsters()$" for "$LivingPlayers$" living player(s). ZedSpawner limit not found.", 'Priority');
		break;
	case 22:
	case 23:
		KFGI = KFGameInfo(WorldInfo.Game);
		SpawnManager = (KFGI != None) ? KFGI.SpawnManager : None;
		if (SpawnManager == None)
		{
			PC.ClientMessage("Spawn manager unavailable.", 'Priority');
			break;
		}
		for (i=0; i<ArrayCount(SpawnManager.EarlyWavesSpawnTimeModByPlayers); ++i)
		{
			if (SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] <= 0.f)
				SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] = 1.f;
			if (SpawnManager.LateWavesSpawnTimeModByPlayers[i] <= 0.f)
				SpawnManager.LateWavesSpawnTimeModByPlayers[i] = 1.f;
			SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] = FClamp(SpawnManager.EarlyWavesSpawnTimeModByPlayers[i] * (Action == 22 ? 0.85 : 1.15), 0.05, 5.0);
			SpawnManager.LateWavesSpawnTimeModByPlayers[i] = FClamp(SpawnManager.LateWavesSpawnTimeModByPlayers[i] * (Action == 22 ? 0.85 : 1.15), 0.05, 5.0);
		}
		PlayerIndex = Clamp(Max(KFGI.GetNumPlayers(), 1)-1, 0, ArrayCount(SpawnManager.EarlyWavesSpawnTimeModByPlayers)-1);
		SpawnMod = FMax(SpawnManager.EarlyWavesSpawnTimeModByPlayers[PlayerIndex], SpawnManager.LateWavesSpawnTimeModByPlayers[PlayerIndex]);
		if (Action == 22)
			SpawnManager.TimeUntilNextSpawn = FMin(SpawnManager.TimeUntilNextSpawn, 1.f);
		PC.ClientMessage((Action == 22 ? "Spawn rate increased. " : "Spawn rate decreased. ")$"Spawn time mod: "$SpawnMod, 'Priority');
		break;
	case 24:
		KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
		if (KFGRI == None || !KFGRI.bTraderIsOpen)
		{
			PC.ClientMessage("Trader is not open.", 'Priority');
			break;
		}
		KFGRI.bStopCountDown = true;
		KFGRI.bForceNetUpdate = true;
		PC.ClientMessage("Trader timer paused. Players can still vote/skip trader normally.", 'Priority');
		break;
	default:
		PC.ClientMessage("Unknown revamp admin action.", 'Priority');
	}
}

function RefreshNewItemsFor(ExtPlayerController PC)
{
	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	RefreshZvampextTraderItems(true, PC);
	SendZvampextTraderItems(PC);
}

function ApplyZvampextTraderItems()
{
	RefreshZvampextTraderItems();
}

function int RefreshZvampextTraderItems(optional bool bForceRefresh, optional PlayerController Sender)
{
	local KFGameReplicationInfo KFGRI;
	local KFGFxObject_TraderItems TraderItems;
	local int i, Added, StorePrice;
	local STraderItem NewItem;
	local Zvamp_CustomItems CustomItems;
	local bool bChanged;

	if (bZvampextTraderItemsApplied && !bForceRefresh)
		return 0;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI == None || KFGRI.TraderItems == None)
	{
		SetTimer(1.f, false, 'ApplyZvampextTraderItems');
		return 0;
	}

	CustomItems = new(None) class'Zvamp_CustomItems';
	TraderItems = KFGRI.TraderItems;
	for (i=0; i<CustomItems.Item.Length; ++i)
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
		}
		else `log("[Zvamp] skipped custom trader item, could not load weapon def/class: "$CustomItems.Item[i]);
	}

	if (Added > 0 || bChanged)
	{
		TraderItems.SetItemsInfo(TraderItems.SaleItems);
		KFGRI.TraderItems = TraderItems;
		KFGRI.bForceNetUpdate = true;
	}

	bZvampextTraderItemsApplied = true;
	if (Sender != None)
		Sender.ClientMessage("[Zvamp] custom trader items refreshed; added "$Added$" new item(s).", 'Priority');
	return Added;
}

final function SendZvampextTraderItems(ExtPlayerController PC)
{
	local int i, StorePrice;
	local Zvamp_CustomItems CustomItems;
	local string ItemSpec;

	if (PC == None)
		return;

	CustomItems = new(None) class'Zvamp_CustomItems';
	PC.ClientClearZvampextTraderItems();
	for (i=0; i<CustomItems.Item.Length; ++i)
	{
		ItemSpec = CustomItems.Item[i];
		StorePrice = GetZvampextStorePrice(CustomItems, CustomItems.Item[i]);
		if (StorePrice >= 0)
			ItemSpec $= "|"$StorePrice;
		PC.ClientAddZvampextTraderItemPath(ItemSpec);
	}
	PC.ClientApplyZvampextTraderItems();
}

final function int GetNextZvampextTraderItemID(KFGFxObject_TraderItems TraderItems)
{
	local int ItemID;

	ItemID = TraderItems.SaleItems.Length;
	while (TraderItems.SaleItems.Find('ItemID', ItemID) != INDEX_NONE)
		++ItemID;
	return ItemID;
}

final function int GetZvampextStorePrice(Zvamp_CustomItems CustomItems, string ItemPath)
{
	local int i, PriceValue;
	local string PricePath;

	if (CustomItems == None)
		return -1;

	for (i=0; i<CustomItems.StorePrice.Length; ++i)
	{
		if (ParseZvampextStorePrice(CustomItems.StorePrice[i], PricePath, PriceValue) && PricePath ~= ItemPath)
			return PriceValue;
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
		SplitAt = InStr(Row, ":");
	if (SplitAt == INDEX_NONE)
		return false;

	ItemPath = TrimAdminID(Left(Row, SplitAt));
	PriceText = TrimAdminID(Mid(Row, SplitAt + 1));
	PriceValue = int(PriceText);
	return ItemPath != "" && PriceValue >= 0;
}

final function ApplyZvampextStorePrice(class<KFWeaponDefinition> WeaponDef, int StorePrice)
{
	local string DefPath;
	local int OldPrice;

	if (WeaponDef == None || StorePrice < 0)
		return;

	DefPath = NormalizeZvampextClassPath(PathName(WeaponDef));
	OldPrice = WeaponDef.default.BuyPrice;
	ConsoleCommand("set" @ DefPath @ "BuyPrice" @ StorePrice);
	`log("[Zvamp] custom item price override: "$DefPath@"old="$OldPrice@"new="$StorePrice@"effective="$WeaponDef.default.BuyPrice);
}

final function ApplyZvampextStorePriceToTraderItems(out KFGFxObject_TraderItems TraderItems, const out STraderItem MatchItem, int StorePrice)
{
	local int i;

	ApplyZvampextStorePrice(MatchItem.WeaponDef, StorePrice);
	for (i=0; i<TraderItems.SaleItems.Length; ++i)
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
		ClassPath = Mid(ClassPath, 6);
	if (Left(ClassPath, 6) ~= "Class'")
	{
		ClassPath = Mid(ClassPath, 6);
		if (Right(ClassPath, 1) == "'")
			ClassPath = Left(ClassPath, Len(ClassPath)-1);
	}
	return ClassPath;
}

final function bool BuildZvampextTraderItem(string WeaponDefPath, out STraderItem NewItem)
{
	local class<KFWeaponDefinition> WeaponDef;
	local class<KFWeapon> WeaponClass;
	local class<KFWeap_DualBase> DualClass;
	local array<STraderItemWeaponStats> WeaponStats;
	local string CandidateDefPath, PackageName, ClassName;
	local int DotPos;

	WeaponDefPath = TrimAdminID(WeaponDefPath);
	if (WeaponDefPath == "")
		return false;

	WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(WeaponDefPath, class'Class', true));
	if (WeaponDef != None && WeaponDef.default.WeaponClassPath != "")
		WeaponClass = class<KFWeapon>(DynamicLoadObject(WeaponDef.default.WeaponClassPath, class'Class', true));
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
			CandidateDefPath = PackageName$"."$ClassName$"Def";
			WeaponDef = class<KFWeaponDefinition>(DynamicLoadObject(CandidateDefPath, class'Class', true));
		}
	}
	if (WeaponClass == None || WeaponDef == None)
		return false;

	NewItem.WeaponDef = WeaponDef;
	NewItem.ClassName = WeaponClass.Name;
	DualClass = class<KFWeap_DualBase>(WeaponClass);
	if (DualClass != None && DualClass.default.SingleClass != None)
		NewItem.SingleClassName = DualClass.default.SingleClass.Name;
	else NewItem.SingleClassName = WeaponClass.Name;
	NewItem.DualClassName = WeaponClass.default.DualClass != None ? WeaponClass.default.DualClass.Name : '';
	NewItem.AssociatedPerkClasses = WeaponClass.static.GetAssociatedPerkClasses();
	NormalizeZvampextAssociatedPerks(NewItem.AssociatedPerkClasses);
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

final function NormalizeZvampextAssociatedPerks(out array<class<KFPerk> > AssociatedPerks)
{
	local int i, j;

	for (i=AssociatedPerks.Length-1; i>=0; --i)
	{
		if (AssociatedPerks[i] == None)
		{
			AssociatedPerks.Remove(i, 1);
			continue;
		}
		for (j=i-1; j>=0; --j)
		{
			if (AssociatedPerks[j] == AssociatedPerks[i])
			{
				AssociatedPerks.Remove(i, 1);
				break;
			}
		}
	}
}

final function ApplyPickupOverridesTo(Pawn Other)
{
	local ExtInventoryManager IM;

	if (Other == None)
		return;
	IM = ExtInventoryManager(Other.InvManager);
	if (IM != None)
	{
		IM.SetAdminPickupOverrides(bAdminAmmoPickup, AdminAmmoPickupValue, bAdminItemPickup, AdminItemPickupValue, bAdminArmorPickup, AdminArmorPickupValue);
		IM.SetDoshThrowAmount(DoshThrowAmount);
	}
}

final function ApplyPickupOverridesToController(ExtPlayerController PC)
{
	if (PC != None)
		ApplyPickupOverridesTo(PC.Pawn);
}

function AdminSetPickupOverrides(ExtPlayerController PC, bool bGrenadeDamage, float GrenadeDamageValue, bool bGrenadeRadius, float GrenadeRadiusValue, bool bAmmoPickup, float AmmoPickupValue, bool bItemPickup, float ItemPickupValue, bool bArmorPickup, float ArmorPickupValue)
{
	local ExtPlayerController E;

	if (PC == None || !HasPrivs(ExtPlayerReplicationInfo(PC.PlayerReplicationInfo)))
	{
		if (PC != None)
			PC.ClientMessage("You do not have enough admin priveleges.", 'Priority');
		return;
	}

	bAdminGrenadeDamage = bGrenadeDamage;
	AdminGrenadeDamageValue = FMax(GrenadeDamageValue, 0.f);
	bAdminGrenadeRadius = bGrenadeRadius;
	AdminGrenadeRadiusValue = FMax(GrenadeRadiusValue, 0.f);
	bAdminAmmoPickup = bAmmoPickup;
	AdminAmmoPickupValue = FMax(AmmoPickupValue, 0.f);
	bAdminItemPickup = bItemPickup;
	AdminItemPickupValue = FMax(ItemPickupValue, 0.f);
	bAdminArmorPickup = bArmorPickup;
	AdminArmorPickupValue = FMax(ArmorPickupValue, 0.f);
	SaveConfig();

	foreach WorldInfo.AllControllers(class'ExtPlayerController', E)
	{
		E.ClientSetAdminPickupOverrides(bAdminGrenadeDamage, AdminGrenadeDamageValue, bAdminGrenadeRadius, AdminGrenadeRadiusValue, bAdminAmmoPickup, AdminAmmoPickupValue, bAdminItemPickup, AdminItemPickupValue, bAdminArmorPickup, AdminArmorPickupValue);
		ApplyPickupOverridesToController(E);
	}

	PC.ClientMessage("Pickup and grenade override settings updated.", 'Priority');
}

function AutoHealingTick()
{
	local KFPawn_Human P;
	local int HealAmount;

	if (!bEnableAutoHealing)
		return;

	HealAmount = Clamp(AutoHealingAmount, 1, 100);
	foreach WorldInfo.AllPawns(class'KFPawn_Human', P)
	{
		if (P != None && !P.bDeleteMe && P.IsAliveAndWell() && P.Health > 0 && P.Health < P.HealthMax)
		{
			P.HealDamage(Min(HealAmount, P.HealthMax - P.Health), P.Controller, class'KFDT_Healing');
			if (bEnableAutoHealingChat && PlayerController(P.Controller) != None)
				PlayerController(P.Controller).ClientMessage("AutoHealing +"$HealAmount, 'Event');
		}
	}
}

defaultproperties
{
	ZvampextBuildID="ServerExtMut SML 2026-05-19 quick-add-automsg-colors"
}
