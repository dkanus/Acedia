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
    Test_AliasHash();
    Test_AliasLoading();
}

protected static function Test_AliasLoading()
{
    Context("Testing loading aliases from a mock object `MockAliasSource`.");
    SubTest_AliasLoadingCorrect();
    SubTest_AliasLoadingIncorrect();
}

protected static function SubTest_AliasLoadingCorrect()
{
    local AliasSource   source;
    local string        outValue;

    Issue("`Resolve()` fails to return alias that should be loaded.");
    source = _().alias.GetCustomSource(class'MockAliasSource');
    TEST_ExpectTrue(source.Resolve("Global", outValue));
    TEST_ExpectTrue(outValue == "value");
    TEST_ExpectTrue(source.Resolve("ford", outValue));
    TEST_ExpectTrue(outValue == "car");

    Issue("`Try()` fails to return alias that should be loaded.");
    TEST_ExpectTrue(source.Try("question") == "response");
    TEST_ExpectTrue(source.Try("delorean") == "car");

    Issue("`ContainsAlias()` reports alias, that should be present,"
        @ "as missing.");
    TEST_ExpectTrue(source.ContainsAlias("Global"));
    TEST_ExpectTrue(source.ContainsAlias("audi"));

    Issue("Aliases in per-object-configs incorrectly handle ':'.");
    TEST_ExpectTrue(source.Try("HardToBeAGod") == "sci.fi");

    Issue("Aliases with empty values in alias name or their value are handled"
        @ "incorrectly.");
    TEST_ExpectTrue(source.Try("") == "empty");
    TEST_ExpectTrue(source.Try("also") == "");
}

protected static function SubTest_AliasLoadingIncorrect()
{
    local AliasSource   source;
    local string        outValue;
    Context("Testing loading aliases from a mock object `MockAliasSource`.");
    Issue("`AliasAPI` cannot return value custom source.");
    source = _().alias.GetCustomSource(class'MockAliasSource');
    TEST_ExpectNotNone(source);

    Issue("`Resolve()` reports success of finding inexistent alias.");
    source = _().alias.GetCustomSource(class'MockAliasSource');
    TEST_ExpectFalse(source.Resolve("noSuchThing", outValue));

    Issue("`Try()` does not return given value for non-existent alias.");
    TEST_ExpectTrue(source.Try("TheHellIsThis") == "TheHellIsThis");

    Issue("`ContainsAlias()` reports inexistent alias as present.");
    TEST_ExpectFalse(source.ContainsAlias("FordК"));
}

protected static function Test_AliasHash()
{
    Context("Testing `AliasHasher`.");
    SubTest_AliasHashInsertingRemoval();
}

protected static function SubTest_AliasHashInsertingRemoval()
{
    local AliasHash hasher;
    local string    outValue;
    hasher = new class'AliasHash';
    hasher.Initialize();
    Issue("`AliasHash` cannot properly store added aliases.");
    hasher.Insert("alias", "value").Insert("one", "more");
    TEST_ExpectTrue(hasher.Contains("alias"));
    TEST_ExpectTrue(hasher.Contains("one"));
    TEST_ExpectTrue(hasher.Find("alias", outValue));
    TEST_ExpectTrue(outValue == "value");
    TEST_ExpectTrue(hasher.Find("one", outValue));
    TEST_ExpectTrue(outValue == "more");

    Issue("`AliasHash` reports hashing aliases that never were hashed.");
    TEST_ExpectFalse(hasher.Contains("alia"));

    Issue("`AliasHash` cannot properly remove stored aliases.");
    hasher.Remove("alias");
    TEST_ExpectFalse(hasher.Contains("alias"));
    TEST_ExpectTrue(hasher.Contains("one"));
    TEST_ExpectFalse(hasher.Find("alias", outValue));
    outValue = "wrong";
    TEST_ExpectTrue(hasher.Find("one", outValue));
    TEST_ExpectTrue(outValue == "more");

    Issue("`InsertIfMissing()` function cannot properly store added aliases.");
    TEST_ExpectTrue(hasher.InsertIfMissing("another", "var", outValue));
    TEST_ExpectTrue(hasher.Find("another", outValue));
    TEST_ExpectTrue(outValue == "var");

    Issue("`InsertIfMissing()` function incorrectly resolves a conflict with"
        @ "an existing value.");
    TEST_ExpectFalse(hasher.InsertIfMissing("one", "something", outValue));
    TEST_ExpectTrue(outValue == "more");
}

defaultproperties
{
    caseName = "Aliases"
}