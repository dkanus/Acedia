# Change log

Acedia's versioning is as follows: `X.Y.Z`, where

* `X` is a major version, will be increased to 1 when most of planned features are implements. Further increases aren't planned, but are possible should Acedia change in a significant enough way.
* `Y` is a minor version, increased with every public release that adds some new functionality.
* `Z` is a bug fix versioning, increased after fixing bugs in a corresponding public release.

For development release following notation will be used: `X.Y.devZ`. The only change is that `Z` is now also increases as functionality for the next version is getting implemented.

## Version 0.1 `Bug crusher`

*Release date: 19.02.2020*
This release is focused on fixing most critical and well-known exploits, related to crashes, infinite ammo generation, clear breaking of game mechanics such as infinite inventory.

All fixes are able to function without breaking whitelisted status of the server.

A couple of feature planned for this version were moved to a later date because:

1. They weren't considered critical issues, which is the main focus of this version.
2. Some other features have proved to be more trouble than expected, already delaying the release.

### [NEW] Fix for pistols cost issues

A feature that fixes several issues, related to the selling price of both single and dual pistols, all originating from the existence of dual weapons. Most notable issue is the ability to "print" money by buying and selling pistols in a certain way.

### [NEW] Fix for printing dosh with ammo selling

This feature addresses an oversight in vanilla code, that allows clients to sell ammunition. Moreover, when being sold, ammunition cost is always multiplied by 0.75, without taking into an account possible discount a player might have. This allows cheaters to "print money" by buying and selling ammo over and over again for some weapons, notably pipe bombs (74% discount for lvl6 demolition) and crossbow (42% discount for lvl6 sharpshooter).

### [NEW] Fix for inventory abuse

This feature addressed two inventory issues:

1. Players carrying amount of weapons that shouldn't be allowed by the weight limit.
2. Players carrying two variants of the same gun. For example carrying both M32 and camo M32. Single and dual version of the same weapon are also considered the same type of gun, so you shouldn't be able to carry both MK23 and dual MK23 or dual handcannons and golden handcannon. But cheaters do. But not with this fix.

### [NEW] Fix for infinite grenades exploit

This feature fixes a vulnerability in a code of `Frag` that can allow player to throw grenades even when he no longer has any. There's also no cooldowns on the throw, which can allow a player to even crash the server.

### [NEW] Fix for dosh spam

This feature addressed two dosh-related issues:

1. Crashing servers by spamming `CashPickup` actors with `TossCash`;
2. Breaking collision detection logic by stacking large amount of `CashPickup` actors in one place, which allows one to either reach unintended locations or even instantly kill zeds.

Unlike ServerPerk's method we dynamically limit the speed at which players can throw the dosh, making it, in most circumstances, unnoticeable for players that this fix even runs at all.

### [NEW] Fix for spectator-related crashes

This feature attempts to prevent server crashes caused by someone quickly switching between being spectator and an active player.

### [NEW] Fix for friendly fire hack

This feature fixes a bug that can allow players to bypass server's friendly fire limitations and teamkill. Usual fixes apply friendly fire scale to suspicious damage themselves, which also disables some of the environmental damage. In order to avoid that, this fix allows server owner to define precisely to what damage types to apply the friendly fire scaling. It should be all damage types related to projectiles.

### [NEW] Fix for zed time lags

When zed time activates, game speed is immediately set to `zedTimeSlomoScale` (0.2 by default), defined, like all other variables, in `KFGameType`. Zed time lasts `zedTimeDuration` seconds (3.0 by default), but during last `zedTimeDuration * 0.166` seconds (by default 0.498) it starts to speed back up, causing game speed to update every tick.

This makes animations look more smooth when exiting zed-time; however, updating speed every tick for that purpose seems like an overkill and, combined with things like increased tick rate, certain maps and raised zed limit, it can lead to noticeable lags at the end of zed time.

To fix this issue we disable `Tick` event in `KFGameType` and then repeat that functionality in our own `Tick` event, but only perform game speed updates occasionally, to make sure that overall amount of updates won't go over a limit, that can be configured via `maxGameSpeedUpdatesAmount`.

Our tests (looking really hard on clots' animations) seem to suggest that there shouldn't be much visible difference if we limit game speed updates to about 2 or 3.

### [NEW] Connection service

Connection service tracks players connecting and disconnecting from the server. Service is lightweight and doesn't have to go through the full controller list to check for new players, relying instead on detecting when `KFSteamStatsAndAchievements` is spawned.
