/**
 *  Provides convenient access to Aliases-related functions.
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
class AliasesAPI extends Singleton;

/**
 *  Checks that passed value is a valid alias name.
 *
 *  A valid name is any name consisting out of 128 ASCII symbols.
 *
 *  @param  aliasToCheck    Alias to check for validity.
 *  @return `true` if `aliasToCheck` is a valid alias and `false` otherwise.
 */
public final function bool IsAliasValid(string aliasToCheck)
{
    return _.text.IsASCIIString(aliasToCheck);
}

/**
 *  Provides an easier access to the instance of the `AliasSource` of
 *  the given class.
 *
 *  Can fail if `customSourceClass` is incorrectly defined.
 *
 *  @param  customSourceClass   Class of the source we want.
 *  @return Instance of the requested `AliasSource`,
 *      `none` if `customSourceClass` is incorrectly defined.
 */
public final function AliasSource GetCustomSource(
    class<AliasSource> customSourceClass)
{
    return AliasSource(customSourceClass.static.GetInstance(true));
}

/**
 *  Returns `AliasSource` that is designated in configuration files as
 *  a source for weapon aliases.
 *
 *  NOTE: while by default weapon aliases source will contain only weapon
 *  aliases, you should not assume that. Acedia allows admins to store all
 *  the aliases in the same config.
 *
 *  @return Reference to the `AliasSource` that contains weapon aliases.
 *      Can return `none` if no source for weapons was configured or
 *      the configured source is incorrectly defined.
 */
public final function AliasSource GetWeaponSource()
{
    local AliasSource           weaponSource;
    local class<AliasSource>    sourceClass;
    sourceClass = class'AliasService'.default.weaponAliasesSource;
    if (sourceClass == none) {
        _.logger.Failure("No weapon aliases source configured for Acedia's"
            @ "alias API. Error is most likely cause by erroneous config.");
        return none;
    }
    weaponSource = AliasSource(sourceClass.static.GetInstance(true));
    if (weaponSource == none) {
        _.logger.Failure("`AliasSource` class `" $ string(sourceClass) $ "` is"
            @ "configured to store weapon aliases, but it seems to be invalid."
            @ "This is a bug and not configuration file problem, but issue"
            @ "might be avoided by using a different `AliasSource`.");
        return none;
    }
    return weaponSource;
}

/**
 *  Returns `AliasSource` that is designated in configuration files as
 *  a source for color aliases.
 *
 *  NOTE: while by default color aliases source will contain only color aliases,
 *  you should not assume that. Acedia allows admins to store all the aliases
 *  in the same config.
 *
 *  @return Reference to the `AliasSource` that contains color aliases.
 *      Can return `none` if no source for colors was configured or
 *      the configured source is incorrectly defined.
 */
public final function AliasSource GetColorSource()
{
    local AliasSource           colorSource;
    local class<AliasSource>    sourceClass;
    sourceClass = class'AliasService'.default.colorAliasesSource;
    if (sourceClass == none) {
        _.logger.Failure("No color aliases source configured for Acedia's"
            @ "alias API. Error is most likely cause by erroneous config.");
        return none;
    }
    colorSource = AliasSource(sourceClass.static.GetInstance(true));
    if (colorSource == none) {
        _.logger.Failure("`AliasSource` class `" $ string(sourceClass) $ "` is"
            @ "configured to store color aliases, but it seems to be invalid."
            @ "This is a bug and not configuration file problem, but issue"
            @ "might be avoided by using a different `AliasSource`.");
        return none;
    }
    return colorSource;
}

/**
 *  Tries to look up a value, stored for given alias in an `AliasSource`
 *  configured to store weapon aliases. Reports error on failure.
 *
 *      Lookup of alias can fail if either alias does not exist in weapon alias
 *  source or weapon alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if weapon alias source exists you can check
 *  `_.alias.GetWeaponSource()` value.
 *
 *  Also see `TryWeapon()` method.
 *
 *  @param  alias   Alias, for which method will attempt to look up a value.
 *      Case-insensitive.
 *  @param  value   If passed `alias` was recorded as a weapon alias,
 *      it's corresponding value will be written in this variable.
 *      Otherwise value is undefined.
 *  @return `true` if lookup was successful and `false` otherwise.
 */
public final function bool ResolveWeapon(string alias, out string result)
{
    local AliasSource source;
    source = GetWeaponSource();
    if (source != none) {
        return source.Resolve(alias, result);
    }
    return false;
}

/**
 *  Tries to look up a value, stored for given alias in an `AliasSource`
 *  configured to store weapon aliases and silently returns given `alias`
 *  value upon failure.
 *
 *      Lookup of alias can fail if either alias does not exist in weapon alias
 *  source or weapon alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if weapon alias source exists you can check
 *  `_.alias.GetWeaponSource()` value.
 *
 *  Also see `ResolveWeapon()` method.
 *
 *  @param  alias   Alias, for which method will attempt to look up a value.
 *      Case-insensitive.
 *  @return Weapon value corresponding to a given alias, if it was present in
 *      the weapon alias source and value of `alias` parameter instead.
 */
public function string TryWeapon(string alias)
{
    local AliasSource source;
    source = GetWeaponSource();
    if (source != none) {
        return source.Try(alias);
    }
    return alias;
}

/**
 *  Tries to look up a value, stored for given alias in an `AliasSource`
 *  configured to store color aliases. Reports error on failure.
 *
 *      Lookup of alias can fail if either alias does not exist in color alias
 *  source or color alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if color alias source exists you can check
 *  `_.alias.GetColorSource()` value.
 *
 *  Also see `TryColor()` method.
 *
 *  @param  alias   Alias, for which method will attempt to look up a value.
 *      Case-insensitive.
 *  @param  value   If passed `alias` was recorded as a color alias,
 *      it's corresponding value will be written in this variable.
 *      Otherwise value is undefined.
 *  @return `true` if lookup was successful and `false` otherwise.
 */
public final function bool ResolveColor(string alias, out string result)
{
    local AliasSource source;
    source = GetColorSource();
    if (source != none) {
        return source.Resolve(alias, result);
    }
    return false;
}

/**
 *  Tries to look up a value, stored for given alias in an `AliasSource`
 *  configured to store color aliases and silently returns given `alias`
 *  value upon failure.
 *
 *      Lookup of alias can fail if either alias does not exist in color alias
 *  source or color alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if color alias source exists you can check
 *  `_.alias.GetColorSource()` value.
 *
 *  Also see `ResolveColor()` method.
 *
 *  @param  alias   Alias, for which method will attempt to look up a value.
 *      Case-insensitive.
 *  @return Color value corresponding to a given alias, if it was present in
 *      the color alias source and value of `alias` parameter instead.
 */
public function string TryColor(string alias)
{
    local AliasSource source;
    source = GetColorSource();
    if (source != none) {
        return source.Try(alias);
    }
    return alias;
}

defaultproperties
{
}