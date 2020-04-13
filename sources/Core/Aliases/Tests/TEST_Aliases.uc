/**
 *  Set of tests for Aliases system.
 *      Copyright 2020 Anton Tarasenko
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
class TEST_Aliases extends TestCase
    abstract;

protected static function TESTS()
{
    local string result;
    Context("Testing Aliases loading.");
    Issue("`Try` cannot resolve correct alias");
    TEST_ExpectTrue(_().alias.Try("test", "Ford") == "car");
    TEST_ExpectTrue(_().alias.Try("test", "Delorean") == "car");
    TEST_ExpectTrue(_().alias.Try("test", "HardToBeAGod") == "scifi");

    Issue("`Resolve` cannot resolve correct alias");
    _().alias.Resolve("test", "Ford", result);
    TEST_ExpectTrue(result == "car");
    _().alias.Resolve("test", "Audi", result);
    TEST_ExpectTrue(result == "car");
    _().alias.Resolve("test", "Spice", result);
    TEST_ExpectTrue(result == "scifi");

    Issue("`Try` does not return original alias for non-existing alias record");
    TEST_ExpectTrue(_().alias.Try("test", "AllFiction") == "AllFiction");

    Issue("`Resolve` reports success when it failed");
    TEST_ExpectFalse(_().alias.Resolve("test", "KarmicJustice", result));

    Issue("`Resolve` reports failure when it succeeds");
    TEST_ExpectTrue(_().alias.Resolve("test", "Delorean", result));
}

defaultproperties
{
    caseName = "Aliases"
}