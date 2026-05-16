# Zvamp RPG

Zvamp RPG is a Killing Floor 2 ServerExt RPG revamp focused on perk progression, Endless server play, custom zeds, and safer custom trader support.

## Links

- Steam Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3726663955
- Website: https://zerolitter.github.io/Zvamp-RPG/
- Bug Reports: https://steamcommunity.com/workshop/filedetails/discussion/3726663955/841754306657912133/

## Features

- Perk V2 lobby and in-game UI
- RPG stat and trait progression
- Prestige, reset, and unload flows
- Owned Endless game class: `ServerExtMut.Zvampext_Endless`
- ZedSpawner support for custom zeds
- TraderGuard compatibility support
- Custom trait icons
- Custom item support
- Health and armor scaling up to 500
- Magazine capacity support up to 2000 when supported by the weapon

## Basic Server Setup

Use the owned Endless game class:

```text
?Game=ServerExtMut.Zvampext_Endless
```

Recommended first mutator stack:

```text
?Mutator=ServerExtMut.ServerExtMut,TraderGuard.TraderGuardMut,ZedSpawner.Mut,ZedCosmetic.ZedCosmeticMut,TF2SentryMod.SentryTurret
```

Avoid adding `TIM.TIMut`, external Controlled Difficulty game classes, or trader replacement mutators to the first setup pass.

## Credits

Zvamp RPG builds on ServerExt and community Killing Floor 2 mod work.

Special thanks to:

- GenZmeY - ServerExt / CTI / ZedSpawner
- HickDead_ - TIM
- humam2104 - CustomSyringe
- [Insert Name Here] - KFStaticCameraMod
- Ameisenber - Weaponized Mayhem
- Open-source contributors and people in comments
- zerolitter - rebuild effort

## License

GPL-3.0-or-later
