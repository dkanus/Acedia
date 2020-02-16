# Acedia

## Installation

Add `Acedia.StartUp` to the list of server actors in your `KillingFloor.ini`.
**Do not** manually add `Acedia.Acedia` mutator.

## Change log

Acedia's versioning will differ from that of NicePack's and is as follows: `X.Y.Z`, where

* `X` is a major version, will be increased to 1 when most of planned features are implements. Further increases aren't planned, but are possible should Acedia change in a significant enough way.
* `Y` is a minor version, increased with every public release that adds some new functionality.
* `Z` is a bug fix versioning, increased after fixing bugs in a corresponding public release.

For development release following notation will be used: `X.Y.devZ`. The only change is that `Z` is now also increases as functionality for the next version is getting implemented.

### Development of version 0.1

For the first public release we aim to implement a variety of server-side fixes to the following issues:

1. **[DONE]** Zed time lags.
2. **[DONE]** Ignoring friendly-fire restrictions.
3. **[DONE]** Infinite grenades.
4. **[DONE]** Ability to crash server by spawning excessive amounts of dosh actors.
5. **[DONE]** Ability to crash server by spamming becoming spectator and back.
6. Pipes dealing way more damage when quickly shot several times.
7. Error message spam in server's log even on clean, un-modded servers.
8. **[PARTIALLY DONE]** Money printing.
9. Inventory abuse that allows to carry too many weapon or duplicates of the same weapon.

#### Version 0.0.dev3 `Worst exploits`

*Release date: 16.02.2020*
*This isn't a release version and is meant for testing.*

##### [NEW] Fix ammo selling

This feature addressed an oversight in vanilla code that allows clients to sell weapon's ammunition. Moreover, when being sold, ammunition cost is always multiplied by $0.75$, without taking into an account possible discount a player might have. This allows cheaters to "print money" by buying and selling ammo over and over again ammunition for some weapons, notably pipe bombs ($74$% discount for lvl6 demolition) and crossbow ($42$% discount for lvl6 sharpshooter).
This feature fixes this problem by setting `pickupClass` variable in potentially abusable weapons to our own value that won't receive a discount. Luckily for us, discount checks are the only place where variable is directly checked in a vanilla game's code (`default.pickupClass` is used everywhere else), so we can easily deal with the only side effect of such change.

##### [NEW] Fix spectator-related crashes

This feature attempts to prevent server crashes caused by someone quickly switching between being spectator and an active player.
We do so by disconnecting players who start switching way too fast (more than twice in a short amount of time) and temporarily faking a large amount of players on the server, to prevent such spam from affecting the server.

#### Version 0.0.dev2 `More vanilla bug fixes`

*Release date: 02.11.2019*
*This isn't a release version and is meant for testing.*

##### [NEW] Fix dosh spam

This feature addressed two dosh-related issues:

1. Crashing servers by spamming `CashPickup` actors with `TossCash`;
2. Breaking collision detection logic by stacking large amount of `CashPickup` actors in one place, which allows one to either reach unintended locations or even instantly kill zeds.

First, we limit amount of dosh that can be spawned simultaneously.The simplest method is to place a cooldown on spawning `CashPickup` actors, i.e. after spawning one `CashPickup` we'd completely prevent spawning any other instances of it for a fixed amount of time. However, that might allow a malicious spammer to block others from throwing dosh, - all he needs to do is to spam dosh at right time intervals.
We'll resolve this issue by recording how many `CashPickup` actors each player has spawned as their "contribution" and decay that value with time, only allowing to spawn new dosh after contribution decayed to zero. Speed of decay is derived from current dosh spawning speed limit and decreases with amount of players with non-zero contributions (since it means that they're throwing dosh).
Second issue is player amassing a large amount of dosh in one point that leads  to skipping collision checks, which then allows players to pass through level geometry or enter zeds' collisions, instantly killing them. Since dosh disappears on it's own, the easiest method to prevent this issue is to severely limit how much dosh players can throw per second, so that there's never enough dosh laying around to affect collision logic. The downside to such severe limitations is that game behaves less vanilla-like, where you could throw away streams of dosh. To solve that we'll first use a more generous limit on dosh players can throw per second, but will track how much dosh is currently present in a level and linearly decelerate speed, according to that amount.

##### [NEW] Fix friendly fire hack

It's possible to bypass friendly fire damage scaling and always deal full damage to other players, if one were to either leave the server or spectate right after shooting a projectile. We use game rules to catch such occurrences and apply friendly fire scaling to weapons, specified by server admins.
To specify required subset of weapons, one must first chose a general rule (scale by default / don't scale by default) and then, optionally, add exceptions to it.
Choosing `scaleByDefault == true` as a general rule will make this fix behave in the similar way to `KFExplosiveFix` by mutant and will disable some environmental sources of damage on some maps. One can then add relevant damage classes as exceptions to fix that downside, but making an extensive list of such sources might prove problematic.
On the other hand, setting `scaleByDefault == false` will allow to get rid of team-killing exploits by simply adding damage types of all projectile weapons, used on a server. This fix comes with such filled-in list of all vanilla projectile classes.

##### [NEW] Fix infinite nades exploit

This feature fixes a vulnerability in a code of `Frag` that can allow player to throw grenades even when he no longer has any. There's also no cooldowns on the throw, which can lead to a server crash.
It is possible to call `ServerThrow` function from client, forcing it to get executed on a server. This function consumes the grenade ammo and spawns a nade, but it doesn't check if player had any grenade ammo in the first place, allowing you him to throw however many grenades he wants. Moreover, unlike a regular throwing method, calling this function allows to spawn many grenades without any delay, which can lead to a server crash.
This fix tracks every instance of 'Frag' weapon that's responsible for throwing grenades and records how much ammo they have have. This is necessary, because whatever means we use, when we get a say in preventing grenade from spawning the ammo was already reduced. This means that we can't distinguished between a player abusing a bug by throwing grenade when he doesn't have necessary ammo and player throwing his last nade, as in both cases current ammo visible to us will be $0$. Then, before every nade throw, it checks if player has enough ammo and blocks grenade from spawning if he doesn't.
We change a `FireModeClass[0]` from `FragFire` to `FixedFragFire` and only call `super.DoFireEffect()` if we decide spawning grenade should be allowed. The side effect is a change in server's `FireModeClass`.

#### Version 0.0.dev1 `First draft`

*Release date: 27.10.2019*
*This isn't a release version and is meant for testing.*

This is a first version of Acedia that introduces some basic building blocks, service for tracking player connections and a first feature that aims to fix lags related to zed time.

##### [NEW] Connection service

Connection module players connecting and disconnecting from the server. Service is lightweight and doesn't have to go through the full controller list to check for new players, relying instead on detecting when `KFSteamStatsAndAchievements` is spawned.

##### [NEW] Fix zed time lags

When zed time activates, game speed is immediately set to `zedTimeSlomoScale` ($0.2$ by default), defined, like all other variables, in `KFGameType`. Zed time lasts `zedTimeDuration` seconds ($3.0$ by default), but during last `zedTimeDuration * 0.166` seconds (by default $0.498$) it starts to speed back up, causing game speed to update every tick.
This makes animations look more smooth when exiting zed-time; however, updating speed every tick for that purpose seems like an overkill and, combined with things like increased tick rate, certain maps and raised zed limit, it can lead to noticeable lags at the end of zed time.
To fix this issue we disable `Tick` event in `KFGameType` and then repeat that functionality in our own `Tick` event, but only perform game speed updates occasionally, to make sure that overall amount of updates won't go over a limit, that can be configured via `maxGameSpeedUpdatesAmount`.
Author's test (looking really hard on clots' animations) seem to suggest that there shouldn't be much visible difference if we limit game speed updates to about 2 or 3.
