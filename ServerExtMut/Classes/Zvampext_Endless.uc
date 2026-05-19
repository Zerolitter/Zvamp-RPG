// Zvampext-owned Endless game class.
//
// This is the first compatibility layer for replacing external Controlled
// Difficulty packages with code we own. Keep it close to vanilla Endless until
// each controlled-difficulty feature is intentionally reimplemented.
class Zvampext_Endless extends KFGameInfo_Endless
	config(ServerExtMut);

var config bool bZvampextCompatVerboseLog;
var config bool bZvampextAutoPauseTrader;
var config bool bZvampextEnableMaxMonsters;
var config bool bZvampextEnableWaveTotalZed;
var config bool bZvampextEnableMissingZedWaveGuard;
var config bool bZvampextTraderSpeedBoost;
var config bool bZvampextStopOnCrashRestart, bZvampextCrashRestartArmed;
var config int ZvampextMaxMonsters, ZvampextWaveSizeFakes, ZvampextWaveTotalZed;
var config float ZvampextMissingZedGraceSeconds;
var config float ZvampextTraderSpeedBoostMultiplier;
var transient bool bZvampextTraderAutoPaused;
var transient bool bZvampextWaveTotalZedActive;
var transient bool bZvampextDeferredTraderWaveStart;
var transient float ZvampextNoLiveZedSince;
var transient int ZvampextMissingZedWatchWave;

event InitGame(string Options, out string ErrorMessage)
{
	local int LegacyWaveTotalAI;

	super.InitGame(Options, ErrorMessage);

	if (bZvampextStopOnCrashRestart && bZvampextCrashRestartArmed)
	{
		`log("[Zvamp] Previous server run did not clear the crash-restart sentinel; stopping this auto-restart boot.");
		bZvampextCrashRestartArmed = false;
		SaveConfig();
		SetTimer(0.25, false, nameof(StopCrashRestartBoot));
		return;
	}
	if (bZvampextEnableMaxMonsters)
	{
		ZvampextMaxMonsters = Clamp(GetIntOption(Options, "MaxMonsters", ZvampextMaxMonsters), 0, 200);
	}
	else
	{
		ZvampextMaxMonsters = 0;
	}
	ZvampextWaveSizeFakes = Clamp(GetIntOption(Options, "WaveSizeFakes", ZvampextWaveSizeFakes), 0, 128);
	bZvampextWaveTotalZedActive = bZvampextEnableWaveTotalZed;
	if (bZvampextWaveTotalZedActive)
	{
		ZvampextWaveTotalZed = Clamp(GetIntOption(Options, "WaveTotalZed", ZvampextWaveTotalZed), 0, 512);
		LegacyWaveTotalAI = Clamp(GetIntOption(Options, "WaveTotalAI", 0), 0, 512);
		if (ZvampextWaveTotalZed <= 0 && LegacyWaveTotalAI > 0)
		{
			ZvampextWaveTotalZed = LegacyWaveTotalAI;
		}
		`log("[Zvamp] WaveTotalZed direct spawn-manager limiter is disabled for stability; ignoring WaveTotalZed="$ZvampextWaveTotalZed);
		bZvampextWaveTotalZedActive = false;
		bZvampextEnableWaveTotalZed = false;
		SaveConfig();
	}
	else
	{
		ZvampextWaveTotalZed = 0;
	}

	CompatLog("InitGame complete for" @ WorldInfo.GetMapName(true)
		@"EnableMaxMonsters="$bZvampextEnableMaxMonsters
		@"MaxMonsters="$ZvampextMaxMonsters
		@"WaveSizeFakes="$ZvampextWaveSizeFakes
		@"WaveTotalZedActive="$bZvampextWaveTotalZedActive
		@"WaveTotalZed="$ZvampextWaveTotalZed);
}

final function RestoreZvampextServerGameClass()
{
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None)
	{
		KFGRI.GameClass = class'Zvampext_Endless';
		KFGRI.bForceNetUpdate = true;
		CompatLog("Restored server GameClass="$KFGRI.GameClass);
	}
}

final function PublishZvampextGameClass(optional bool bForce)
{
	local KFGameReplicationInfo KFGRI;

	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	if (KFGRI != None)
	{
		if (!bForce && GetStateName() == 'PlayingWave' && !KFGRI.bTraderIsOpen)
		{
			return;
		}

		// Client GFx code reads GameClass for presentation data. Replicating the
		// custom ServerExtMut game class can resolve to None on clients that have
		// not loaded this package yet, so publish the stock Endless class instead.
		KFGRI.GameClass = class'KFGameInfo_Endless';
		KFGRI.bForceNetUpdate = true;
		CompatLog("Published replicated GameClass="$KFGRI.GameClass);
	}
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	PublishZvampextGameClass();
	SetTimer(1.0, true, nameof(PublishZvampextGameClass));
	SetTimer(1.0, true, nameof(ZvampextMissingZedWaveGuard));
	SetTimer(1.0, true, nameof(MaintainZvampextTraderSpeedBoost));
}

function StopCrashRestartBoot()
{
	ConsoleCommand("exit");
}

final function ArmCrashRestartSentinel()
{
	if (bZvampextStopOnCrashRestart && !bZvampextCrashRestartArmed)
	{
		`log("[Zvamp] Arming crash-restart sentinel for active wave runtime.");
		bZvampextCrashRestartArmed = true;
		SaveConfig();
		CompatLog("Crash-restart sentinel armed for active wave runtime.");
	}
}

function Destroyed()
{
	if (bZvampextStopOnCrashRestart && bZvampextCrashRestartArmed)
	{
		bZvampextCrashRestartArmed = false;
		SaveConfig();
	}

	super.Destroyed();
}

final function CompatLog(string S)
{
	if (bZvampextCompatVerboseLog)
	{
		`log("[Zvamp]" @ S);
	}
}

final function DiagLog(string Label)
{
	local int RemainingAI, CurrentMaxMonsters;
	local bool bTraderOpen, bStopCountDown;

	RemainingAI = -1;
	CurrentMaxMonsters = -1;
	if (MyKFGRI != None)
	{
		RemainingAI = MyKFGRI.AIRemaining;
		CurrentMaxMonsters = MyKFGRI.CurrentMaxMonsters;
		bTraderOpen = MyKFGRI.bTraderIsOpen;
		bStopCountDown = MyKFGRI.bStopCountDown;
	}

	`log("[ZvampDiag] "$Label
		@"Wave="$WaveNum
		@"State="$GetStateName()
		@"GameClass="$((MyKFGRI != None) ? string(MyKFGRI.GameClass) : "None")
		@"TraderOpen="$bTraderOpen
		@"StopCountdown="$bStopCountDown
		@"AutoPause="$bZvampextAutoPauseTrader
		@"AutoPaused="$bZvampextTraderAutoPaused
		@"DeferredWaveStart="$bZvampextDeferredTraderWaveStart
		@"AIAlive="$AIAliveCount
		@"AIRemaining="$RemainingAI
		@"CurrentMaxMonsters="$CurrentMaxMonsters
		@"SpawnManager="$SpawnManager);
}

final function EnsureZvampextCurrentMaxMonsters(string Label)
{
	local int NewMax;

	if (MyKFGRI == None || SpawnManager == None || MyKFGRI.CurrentMaxMonsters > 0)
	{
		return;
	}

	NewMax = SpawnManager.GetMaxMonsters();
	if (NewMax <= 0)
	{
		NewMax = 1;
	}

	MyKFGRI.CurrentMaxMonsters = NewMax;
	MyKFGRI.bForceNetUpdate = true;
	`log("[Zvamp] corrected CurrentMaxMonsters from 0 to "$NewMax@"("$Label$")");
	DiagLog("CurrentMaxMonsters corrected "$Label);
}

final function int CountZvampextLiveHostileZeds()
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

final function int CountZvampextQueuedZedWork()
{
	local int Count;

	if (SpawnManager == None)
	{
		return 0;
	}

	Count = NumAISpawnsQueued + SpawnManager.LeftoverSpawnSquad.Length;
	if (SpawnManager.ActiveSpawner != None)
	{
		Count += SpawnManager.ActiveSpawner.PendingSpawns.Length;
	}

	return Count;
}

function ZvampextMissingZedWaveGuard()
{
	local int LiveZeds, QueuedZedWork, RemainingAI;
	local float GraceSeconds;

	if (!bZvampextEnableMissingZedWaveGuard || MyKFGRI == None || SpawnManager == None
		|| GetStateName() != 'PlayingWave' || MyKFGRI.bTraderIsOpen)
	{
		ZvampextNoLiveZedSince = 0.f;
		ZvampextMissingZedWatchWave = WaveNum;
		return;
	}

	if (ZvampextMissingZedWatchWave != WaveNum)
	{
		ZvampextNoLiveZedSince = 0.f;
		ZvampextMissingZedWatchWave = WaveNum;
	}

	LiveZeds = CountZvampextLiveHostileZeds();
	QueuedZedWork = CountZvampextQueuedZedWork();
	RemainingAI = MyKFGRI.AIRemaining;

	if (LiveZeds > 0 || (QueuedZedWork > 0 && (AIAliveCount > 1 || RemainingAI > 1)) || (AIAliveCount <= 0 && RemainingAI <= 0))
	{
		ZvampextNoLiveZedSince = 0.f;
		return;
	}

	if (ZvampextNoLiveZedSince <= 0.f)
	{
		ZvampextNoLiveZedSince = WorldInfo.TimeSeconds;
		return;
	}

	GraceSeconds = FMax(ZvampextMissingZedGraceSeconds, 5.f);
	if (WorldInfo.TimeSeconds - ZvampextNoLiveZedSince < GraceSeconds)
	{
		return;
	}

	ClearZvampextOrphanedWaveCounter("missing-zed guard", QueuedZedWork, GraceSeconds);
}

function ClearZvampextOrphanedWaveCounter(string Source, int QueuedZedWork, optional float GraceSeconds)
{
	if (MyKFGRI == None)
	{
		return;
	}

	`log("[Zvamp] cleared orphaned wave counters."
		@"Source="$Source
		@"Wave="$WaveNum
		@"AIAlive="$AIAliveCount
		@"AIRemaining="$MyKFGRI.AIRemaining
		@"Queued="$QueuedZedWork
		@"Grace="$GraceSeconds);

	AIAliveCount = 0;
	MyKFGRI.AIRemaining = 0;
	MyKFGRI.bForceNetUpdate = true;
	ZvampextNoLiveZedSince = 0.f;
	CheckWaveEnd();
}

function StartMatch()
{
	`log("[Zvamp] StartMatch entry WaveNum="$WaveNum@"State="$GetStateName());
	CompatLog("StartMatch begin NumPlayers="$NumPlayers@"NetMode="$WorldInfo.NetMode@"State="$GetStateName());
	DiagLog("StartMatch entry");
	RestoreZvampextServerGameClass();
	super.StartMatch();
	PublishZvampextGameClass(true);
	`log("[Zvamp] StartMatch returned WaveNum="$WaveNum@"State="$GetStateName());
	DiagLog("StartMatch returned");
	CompatLog("StartMatch end WaveNum="$WaveNum@"State="$GetStateName());
}

function StartHumans()
{
	CompatLog("StartPlayers begin");
	RestoreZvampextServerGameClass();
	super.StartHumans();
	PublishZvampextGameClass(true);
	CompatLog("StartPlayers end");
}

function StartWave()
{
	local int RemainingAI;

	`log("[Zvamp] StartWave entry WaveNum="$WaveNum@"State="$GetStateName());
	CompatLog("StartWave entry WaveNum="$WaveNum@"State="$GetStateName()@"MyKFGRI="$MyKFGRI);
	DiagLog("StartWave entry");
	if (bZvampextTraderAutoPaused && MyKFGRI != None && !MyKFGRI.bStopCountDown)
	{
		bZvampextTraderAutoPaused = false;
		`log("[Zvamp] Trader auto-hold already released by skip request.");
	}
	else if (bZvampextTraderAutoPaused && MyKFGRI != None && MyKFGRI.bStopCountDown && !bZvampextDeferredTraderWaveStart)
	{
		ReleaseTraderAutoPause(true);
		bZvampextDeferredTraderWaveStart = true;
		`log("[Zvamp] Deferred wave start after trader auto-hold release.");
		SetTimer(0.25, false, nameof(StartWave));
		return;
	}
	bZvampextDeferredTraderWaveStart = false;
	ClearZvampextTraderSpeedBoost();

	CompatLog("StartWave begin WaveNum="$WaveNum@"GRI="$MyKFGRI@"SpawnManager="$SpawnManager@"EndlessDifficulty="$EndlessDifficulty);
	`log("[Zvamp] StartWave before super WaveNum="$WaveNum);
	RestoreZvampextServerGameClass();
	DiagLog("StartWave before super");
	super.StartWave();
	PublishZvampextGameClass(true);
	`log("[Zvamp] StartWave returned from super WaveNum="$WaveNum);
	EnsureZvampextCurrentMaxMonsters("StartWave");
	DiagLog("StartWave returned");
	CompatLog("StartWave returned from super");
	RemainingAI = -1;
	if (MyKFGRI != None)
	{
		RemainingAI = MyKFGRI.AIRemaining;
	}
	CompatLog("StartWave end WaveNum="$WaveNum@"AIAliveCount="$AIAliveCount@"AIRemaining="$RemainingAI);
}

final function ReleaseTraderAutoPause(optional bool bClosingTrader=false)
{
	DiagLog("ReleaseTraderAutoPause before");
	if (MyKFGRI != None)
	{
		MyKFGRI.bStopCountDown = false;
		if (bClosingTrader)
		{
			MyKFGRI.bTraderIsOpen = false;
		}
		MyKFGRI.bForceNetUpdate = true;
	}

	if (bZvampextTraderAutoPaused)
	{
		bZvampextTraderAutoPaused = false;
		`log("[Zvamp] Released trader auto-hold before "$(bClosingTrader ? "wave start." : "trader skip."));
	}
	DiagLog("ReleaseTraderAutoPause after");
}

function OpenTrader()
{
	DiagLog("OpenTrader before super");
	RestoreZvampextServerGameClass();
	super.OpenTrader();
	PublishZvampextGameClass(true);
	DiagLog("OpenTrader returned");

	if (bZvampextAutoPauseTrader)
	{
		SetTimer(0.05, false, nameof(ApplyTraderAutoPause));
		`log("[ZvampDiag] OpenTrader scheduled auto-pause.");
	}

	SetTimer(0.05, false, nameof(ApplyZvampextTraderSpeedBoost));
}

function MaintainZvampextTraderSpeedBoost()
{
	if (MyKFGRI != None && MyKFGRI.bTraderIsOpen)
	{
		ApplyZvampextTraderSpeedBoost();
	}
	else
	{
		ClearZvampextTraderSpeedBoost();
	}
}

function ApplyZvampextTraderSpeedBoost()
{
	local ExtHumanPawn P;
	local float SpeedBoostMod;

	if (MyKFGRI == None || !MyKFGRI.bTraderIsOpen)
	{
		ClearZvampextTraderSpeedBoost();
		return;
	}

	SpeedBoostMod = class'Zvamp_Knife'.static.GetQuickTraderKnife();
	if (bZvampextTraderSpeedBoost)
	{
		SpeedBoostMod = FMax(SpeedBoostMod, ZvampextTraderSpeedBoostMultiplier);
	}
	SpeedBoostMod = FMax(SpeedBoostMod, 1.f);
	if (SpeedBoostMod <= 1.f)
	{
		ClearZvampextTraderSpeedBoost();
		return;
	}

	foreach WorldInfo.AllPawns(class'ExtHumanPawn', P)
	{
		if (P != None && !P.bDeleteMe && P.IsAliveAndWell())
		{
			P.SetZvampextTraderSpeedBoost(SpeedBoostMod);
		}
	}
}

function ClearZvampextTraderSpeedBoost()
{
	local ExtHumanPawn P;

	foreach WorldInfo.AllPawns(class'ExtHumanPawn', P)
	{
		if (P != None && P.ZvampextTraderSpeedBoostMod > 1.f)
		{
			P.SetZvampextTraderSpeedBoost(1.f);
		}
	}
}

function ApplyTraderAutoPause()
{
	if (!bZvampextAutoPauseTrader || MyKFGRI == None || !MyKFGRI.bTraderIsOpen)
	{
		DiagLog("ApplyTraderAutoPause skipped");
		return;
	}

	DiagLog("ApplyTraderAutoPause before");
	bZvampextTraderAutoPaused = true;
	MyKFGRI.bStopCountDown = true;
	ClearTimer(nameof(CloseTraderTimer));
	DiagLog("ApplyTraderAutoPause after");
	CompatLog("Trader auto-hold enabled; close timer cleared.");
}

function InitSpawnManager()
{
	super.InitSpawnManager();
	ApplyZvampextMaxMonsters();
}

final function ApplyZvampextMaxMonsters()
{
	local int DifficultyIndex, PlayerIndex;

	if (SpawnManager == None || ZvampextMaxMonsters <= 0)
	{
		return;
	}

	for (DifficultyIndex=0; DifficultyIndex<SpawnManager.PerDifficultyMaxMonsters.Length; ++DifficultyIndex)
	{
		for (PlayerIndex=0; PlayerIndex<SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters.Length; ++PlayerIndex)
		{
			SpawnManager.PerDifficultyMaxMonsters[DifficultyIndex].MaxMonsters[PlayerIndex] = ZvampextMaxMonsters;
		}
	}

	if (MyKFGRI != None)
	{
		MyKFGRI.CurrentMaxMonsters = SpawnManager.GetMaxMonsters();
	}

	CompatLog("Applied MaxMonsters="$ZvampextMaxMonsters);
}

function float GetTotalWaveCountScale()
{
	local int LivingPlayerCount, EffectivePlayerCount;
	local float ActualScale, FakeScale;

	ActualScale = Super.GetTotalWaveCountScale();
	if (ZvampextWaveSizeFakes <= 0 || DifficultyInfo == None || MyKFGRI == None || MyKFGRI.IsBossWave())
	{
		return ActualScale;
	}

	LivingPlayerCount = Max(1, GetLivingPlayerCount());
	EffectivePlayerCount = Clamp(ZvampextWaveSizeFakes, 1, 128);

	FakeScale = DifficultyInfo.GetPlayerNumMaxAIModifier(EffectivePlayerCount) / DifficultyInfo.GetPlayerNumMaxAIModifier(LivingPlayerCount);
	CompatLog("WaveSizeFakes scale actualPlayers="$LivingPlayerCount@"effectivePlayers="$EffectivePlayerCount@"scale="$FakeScale);

	return ActualScale * FakeScale;
}

function bool ShouldOverrideDoshOnKill(class<KFPawn_Monster> KilledPawn, out float DoshGiven)
{
	if (MyKFGRI == None)
	{
		CompatLog("Skipping dosh override because MyKFGRI is None.");

		return false;
	}

	if (EndlessDifficulty == None)
	{
		CompatLog("Skipping dosh override because EndlessDifficulty is None.");

		return false;
	}

	return Super.ShouldOverrideDoshOnKill(KilledPawn, DoshGiven);
}

defaultproperties
{
	PlayerControllerClass=class'ExtPlayerController'
	DefaultPawnClass=class'ExtHumanPawn'
	GameInfoClassAliases.Add((ShortName="Zvampext_Endless",GameClassName="ServerExtMut.Zvampext_Endless"))
}
