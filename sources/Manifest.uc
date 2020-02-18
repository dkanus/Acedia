/**
 *      Manifest is meant to describe contents of the package (mutator file)
 *  as well as what actors/objects should be automatically created when package
 *  is loaded and what event listeners should be activated.
 *      Currently only implements automatic listener activation.
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
 class Manifest extends Object
    abstract;

//  List of features in this manifest's package.
var public const array< class<Feature> >    features;

//  Listeners listed here will be automatically activated.
var public const array< class<Listener> >   requiredListeners;

defaultproperties
{
    features(0) = class'FixZedTimeLags'
    features(1) = class'FixDoshSpam'
    features(2) = class'FixFFHack'
    features(3) = class'FixInfiniteNades'
    features(4) = class'FixAmmoSelling'
    features(5) = class'FixSpectatorCrash'
    features(6) = class'FixDualiesCost'
    features(7) = class'FixInventoryAbuse'
    //  Listeners
    requiredListeners(0) = class'MutatorListener_Connection'
}