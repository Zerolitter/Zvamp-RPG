# Zvampext RPG V2.0

Zvampext RPG is a Killing Floor 2 ServerExt revamp focused on RPG perk
progression, custom trader support, and stable Endless server play.

The mod keeps the original package names, `ServerExt` and `ServerExtMut`, for
compatibility with existing ServerExt servers and clients.

- Steam Workshop: <https://steamcommunity.com/sharedfiles/filedetails/?id=3726663955>
- License: GPL-3.0-or-later

## Steam Workshop

The Steam Workshop page is the release hub for players and server hosts:

- Workshop item: <https://steamcommunity.com/sharedfiles/filedetails/?id=3726663955>
- Bug reports: <https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754306657912133/>
- TraderGuard and custom item setup: <https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754202758794773/>
- Compatibility notes: <https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754202758794368/>
- Project motivation note: <https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754306657910790/>

When reporting bugs, include the map, game mode, difficulty, wave or trader
state, active perk, loadout, active mods, crash text, and any useful screenshots
or logs. Detailed reports are much easier to reproduce and fix.

## Highlights

- Perk V2 lobby and in-game UI.
- Buyable RPG stats, traits, prestige, reset, and unload flows.
- Owned Endless game class: `ServerExtMut.Zvampext_Endless`.
- Custom trait icons through `ServerExtTraitIcons.upk`.
- Custom trader items through `KFZvampCustomItems.ini`.
- Dosh raffle planning notes: [main map](dosh-raffle.md),
  [server-side version](dosh-raffle-server-side.md), and
  [animated SpinTheWheel version](dosh-raffle-animated-wheel.md).
- ZedSpawner support for custom zed classes.
- TraderGuard support for safe trader aliases and public trader controls.
- Optional compatibility helpers for knife, syringe, and camera behavior.
- Health and armor scaling up to 500.
- Magazine capacity support up to 2000 when the weapon supports it.

## Basic Server Setup

Use Zvampext's owned Endless game class:

```text
?Game=ServerExtMut.Zvampext_Endless
```

Recommended first mutator stack:

```text
?Mutator=ServerExtMut.ServerExtMut,TraderGuard.TraderGuardMut,ZedSpawner.Mut,ZedCosmetic.ZedCosmeticMut,TF2SentryMod.SentryTurret
```

Recommended first launch shape:

```text
KF-MegaBiotics_v2?Difficulty=3?Game=ServerExtMut.Zvampext_Endless?AllowSeasonalSkins=0?MaxPlayers=64?Mutator=ServerExtMut.ServerExtMut,TraderGuard.TraderGuardMut,ZedSpawner.Mut,ZedCosmetic.ZedCosmeticMut,TF2SentryMod.SentryTurret
```

Do not add `TIM.TIMut`, external Controlled Difficulty game classes, or trader
replacement mutators to the first setup pass.

## Workshop Download

For Linux dedicated servers, add the Workshop item to
`LinuxServer-KFEngine.ini`:

```ini
[OnlineSubsystemSteamworks.KFWorkshopSteamworks]
ServerSubscribedWorkshopItems=3726663955
```

Make sure Workshop download is enabled:

```ini
[IpDrv.TcpNetDriver]
DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload
DownloadManagers=IpDrv.HTTPDownload
DownloadManagers=Engine.ChannelDownload
```

## Core Zvampext Config

Recommended first `KFServerExtMut.ini` Endless section:

```ini
[serverextmut.Zvampext_Endless]
ZvampextMaxMonsters=0
ZvampextWaveSizeFakes=0
bZvampextCompatVerboseLog=False
bZvampextEnableMaxMonsters=False
bZvampextAutoPauseTrader=False
ZvampextWaveTotalZed=0
bZvampextEnableWaveTotalZed=False
bZvampextStopOnCrashRestart=True
bZvampextCrashRestartArmed=False
```

For V2.0, avoid using URL `MaxMonsters` as the main spawn control. Use
ZedSpawner for custom spawn behavior.

## ZedSpawner

Old `KFZedSpawner.ini` configs can usually be reused. If a zed package is not
installed, comment out that spawn row and keep the rest of the config.

Safe first-test pattern:

```ini
Spawn=(Wave=2,ZedClass="ZedCustom.BlueHusk",Probability=5,SpawnCountBase=1,SingleSpawnLimit=1)
Spawn=(Wave=3,ZedClass="ZedCustom.RedScrake",Probability=5,SpawnCountBase=1,SingleSpawnLimit=1)
Spawn=(Wave=4,ZedClass="ZedCustom.BaronHell",Probability=3,SpawnCountBase=1,SingleSpawnLimit=1)
```

Start conservative:

```ini
Probability=3-5
SpawnCountBase=1
SingleSpawnLimit=1
```

Raise counts only after several waves survive cleanly.

## Custom Trader Items

Custom trader items belong in `KFZvampCustomItems.ini`.

Example:

```ini
[ServerExtMut.Zvamp_CustomItems]
bAddNewWeaponsToConfig=False
Item=TF2SentryMod.SentryWeaponDef
StorePrice=TF2SentryMod.SentryWeaponDef=5000
```

Use one `Item=` row per weapon. Prefer the weapon definition class when one is
available, for example `TF2SentryMod.SentryWeaponDef`.

Use `StorePrice=` to override trader price:

```ini
StorePrice=TF2SentryMod.SentryWeaponDef=5000
```

After editing item rows while the server is running:

```text
admin ZRefreshnewitems
```

or:

```text
admin refreshitems
```

Restart the server after adding new package files.

## TraderGuard

TraderGuard is used as a conservative trader helper. It is useful for sell
aliases, public trader controls, and custom trader safety. It is not intended to
replace the Zvampext trader or rebuild owned items automatically.

Recommended safe settings:

```ini
bUseExperimentalAllItemsSellLookup=False
bFastPurchaseHelperRefresh=False
bUseStateCheckpoints=False
bAutoRebuildOwnedItemsOnTraderOpen=False
bAutoRebuildOwnedItemsOnTraderMenuOpen=False
```

Use `SellableWeaponAliases=` only when an owned weapon does not get a proper
sell button or sell value.

For the longer server-host guide, see the pinned Steam discussion:
<https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754202758794773/>

## TIM / CTI Notes

TIM and CTI are respected parts of the ServerExt ecosystem, but they are not
recommended as runtime mutators for the V2.0 baseline.

Use this safer approach instead:

- Import TIM custom item rows into `KFZvampCustomItems.ini`.
- Use ZedSpawner for custom zeds.
- Keep Zvampext as the game class with `ServerExtMut.Zvampext_Endless`.
- Add external systems one at a time after the core server is stable.

## Compatibility

| Mod | Status | Notes |
| --- | --- | --- |
| ZedSpawner | Recommended | Best path for custom zeds. Old configs can usually be reused. |
| TraderGuard | Recommended | Keep conservative settings. Use for sell aliases and trader controls. |
| ZedCosmetic | Tested | Works in the current compatibility stack. |
| TF2 Sentry | Tested | Add the Sentry Hammer through `KFZvampCustomItems.ini`. |
| Loot Beams | Likely safe | Watch dropped weapon, pickup, and sell-list edge cases. |
| FriendlyHUD | Likely safe | Test after perk/trader UI is stable. |
| Auto Healing | Conditional | May overlap RPG perk balance. |
| Bonus Zeds | Conditional | Prefer porting desired spawns into `KFZedSpawner.ini`. |
| Zed Varients | Conditional | Use pawn classes through ZedSpawner, not the mutator. |
| Zedternal Zeds | Conditional | Use as a class library through ZedSpawner. |
| TIM runtime mutator | Hold off | Import item rows instead of running TIM. |
| TraderDash | Hold off | Overlaps trader skip and trader state behavior. |
| Unofficial Patch | Hold off | High overlap with UI, trader, inventory, and HUD changes. |
| External Controlled Difficulty game classes | Hold off | Zvampext should own the game class for V2.0. |

The Steam compatibility discussion is kept as the quick host-facing version:
<https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754202758794368/>

## Known V2.0 Notes

- Changing perk through the Zvampext Perk V2 UI is the recommended path.
- Vanilla trader perk-change behavior is still on the follow-up list.
- Add custom zed packs through ZedSpawner class rows rather than stacking more
  spawn-manager mutators.
- Restart after adding new packages, then refresh custom trader rows if needed.

## Credits

Zvampext builds on years of ServerExt community work.

Special thanks to GenZmeY for ServerExt, CTI, and ZedSpawner; Marco and Forrest
Mark X for the original ServerExt foundation; HickDead_ for TIM; humam2104 for
CustomSyringe; `[Insert Name Here]` for KFStaticCameraMod; Ameisenber for
WeaponizedMayhem; everyone who contributed through open-source repositories and
comment sections; and Zerolitter for the effort behind this rebuild.

## Status

Zvampext RPG V2.0 is the first public release baseline. Future patches will
continue from here with compatibility fixes, config cleanup, and quality-of-life
improvements for server hosts.
