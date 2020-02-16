/**
 *      This rule detects suspicious attempts to deal damage and
 *	applies friendly fire scaling according to 'FixFFHack's rules.
 *      Copyright 2019 Anton Tarasenko
 *------------------------------------------------------------------------------
 * This file is part of Acedia.
 *
 * Acedia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License, or
 * (at your option) any later version.
 *
 * Acedia is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Acedia.  If not, see <https://www.gnu.org/licenses/>.
 */
class FFHackRule extends GameRules;

function int NetDamage
(
	int 				originalDamage,
	int 				damage,
	Pawn 				injured,
	Pawn 				instigator,
	Vector				hitLocation,
	out Vector			momentum,
	class<DamageType>	damageType
)
{
	local KFGameType	gameType;
	local FixFFHack		ffHackFix;
	gameType = KFGameType(level.game);
	//	Something is very wrong and we can just bail on this damage
	if (damageType == none || gameType == none) return 0;

	//	We only check when suspicious instigators that aren't a world
	if (!damageType.default.bCausedByWorld && IsSuspicious(instigator))
	{
		ffHackFix = FixFFHack(class'FixFFHack'.static.GetInstance());
		if (ffHackFix != none && ffHackFix.ShouldScaleDamage(damageType))
		{
			//	Remove pushback to avoid environmental kills
			momentum = Vect(0.0, 0.0, 0.0);
			damage *= gameType.friendlyFireScale;
		}
	}
	return super.NetDamage(	originalDamage, damage, injured, instigator,
							hitLocation, momentum, damageType);
}

private function bool IsSuspicious(Pawn instigator)
{
	//	Instigator vanished
	if (instigator == none) return true;

	//	Instigator already became spectator
	if (KFPawn(instigator) != none)
	{
		if (instigator.playerReplicationInfo != none)
		{
			return instigator.playerReplicationInfo.bOnlySpectator;
		}
		return true; // Replication info is gone => suspicious
	}
	return false;
}

defaultproperties
{
}