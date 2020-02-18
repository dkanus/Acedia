/**
 *      This rule detects any pickup events to allow us to
 *	properly record and/or fix pistols' prices.
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
class DualiesCostRule extends GameRules;

function bool OverridePickupQuery
(
	Pawn other,
	Pickup item,
	out byte allowPickup
)
{
	local KFWeaponPickup weaponPickup;
	local FixDualiesCost dualiesCostFix;
	weaponPickup = KFWeaponPickup(item);
	dualiesCostFix = FixDualiesCost(class'FixDualiesCost'.static.GetInstance());
	if (weaponPickup != none && dualiesCostFix != none)
	{
		dualiesCostFix.ApplyPendingValues();
		dualiesCostFix.StoreSinglePistolValues();
		dualiesCostFix.SetNextSellValue(weaponPickup.sellValue);
	}
	return super.OverridePickupQuery(other, item, allowPickup);
}

defaultproperties
{
}