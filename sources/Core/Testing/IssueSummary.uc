/**
 *      Class for storing and processing the information about how well testing
 *  against a certain issue went.
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
class IssueSummary extends AcediaObject;

//  Each issue is uniquely identified by these values.
var private class<TestCase> ownerCase;
var private string          context;
var private string          description;

//  Records, in chronological order, results of the tests that were
//  run to test this issue.
var private array<byte>     successRecords;

private final function byte BoolToByte(bool boolToConvert)
{
    if (boolToConvert) return 1;
    return 0;
}

/**
 *  Sets `TestCase`, context and description for the issue,
 *  tracked in this summary.
 *
 *  Can only be successfully called once, but will fail if passed a `none`
 *  class reference to `TestCase`.
 *
 *  @param  targetCase          `TestCase`, in which issue,
 *      relevant to this summary, is defined.
 *  @param  targetContext       Context, in which this issue,
 *      relevant to this summary, is defined.
 *  @param  targetDescription   Description of the issue relevant to
 *      this summary.
 *  @return `true` if `TestCase`, context and description were successfully set,
 *      `false` otherwise.
 */
public final function bool SetIssue(
    class<TestCase> targetCase,
    string          targetContext,
    string          targetDescription
)
{
    if (ownerCase != none)  return false;
    if (initCase == none)   return false;
    ownerCase   = targetCase;
    context     = targetContext;
    description = targetDescription;
    return true;
}

/**
 *  Returns context for the issue in question.
 *
 *  `TestCase` can be important for both displaying information about testing to
 *  the user and distinguishing between two different issues with the same
 *  description and context.
 *  @see `TestCase` for more information.
 *
 *  @return Test case that tested for relevant issue.
 */
public final function class<TestCase> GetTestCase()
{
    return ownerCase;
}

/**
 *  Returns context for the issue in question.
 *
 *  Context can be important for both displaying information about testing to
 *  the user and distinguishing between two different issues with
 *  the same description and in the same `TestCase`.
 *  @see `TestCase` for more information.
 *
 *  @return Context for relevant issue.
 */
public final function string GetContext()
{
    if (ownerCase == none) return "";
    return context;
}

/**
 *  Returns description for the issue in question.
 *
 *      Description of an issue is the main way to distinguish between
 *  different possibly arising problems.
 *      Two different issues can have the same description if they are defined
 *  in different `TestCase`s and/or in different context.
 *  @see `TestCase` for more information.
 *
 *  @return Description for the issue in question.
 */
public final function string GetDescription()
{
    if (ownerCase == none) return "";
    return description;
}

/**
 *  Adds result of another test (success or not) to the records of this summary.
 *
 *  @param  success `true` if test was successful and had passed,
 *      `false` otherwise.
 */
public final function AddTestResult(bool success)
{
    successRecords[successRecords.length] = BoolToByte(success);
}

/**
 *  Returns total amount of test results recorded in caller summary.
 *  Never a negative value.
 *
 *  @return Amount of tests that were run.
 */
public final function int GetTotalTestsAmount()
{
    return successRecords.length;
}

/**
 *  Returns total amount of recorded successful test results in caller summary.
 *  Never a negative value.
 *
 *  @return Amount of recorded successfully performed tests for
 *      the relevant issue.
 */
public final function int GetSuccessfulTestsAmount()
{
    local int i;
    local int counter;
    counter = 0;
    for (i = 0; i < successRecords.length; i += 1)
    {
        if (successRecords[i] > 0) {
            counter += 1;
        }
    }
    return counter;
}

/**
 *  Returns total amount of recorded failed test results in caller summary.
 *  Never a negative value.
 *
 *  @return Amount of recorded failed tests for the relevant issue.
 */
public final function int GetFailedTestsAmount()
{
    return GetTotalTestsAmount() - GetSuccessfulTestsAmount();
}

/**
 *  Returns total success rate ("amount of successes" / "total amount of tests")
 *  of recorded test results for relevant issue
 *  (value between 0 and 1, including boundaries).
 *
 *  If there are no test results recorded - returns `-1`.
 *
 *  @return Success rate of recorded test results for the relevant issue
 *      Returns values outside [0; 1] segment (specifically, negative values)
 *      iff no test results at all were recorded.
 */
public final function float GetSuccessRate()
{
    local int totalTestsAmount;
    totalTestsAmount = GetTotalTestsAmount();
    if (totalTestsAmount <= 0) {
        return -1;
    }
    return GetSuccessfulTestsAmount() / totalTestsAmount;
}

/**
 *  Checks whether all tests recorded in this summary have passed.
 *
 *  @return `true` if all tests for relevant issue have passed,
 *      `false` otherwise.
 */
public final function bool HasPassedAllTests()
{
    return (GetFailedTestsAmount() <= 0);
}

/**
 *  Returns boolean array of test results: each element recording whether test
 *  was a success (`>0`) or a failure (`0`).
 *
 *  All results in the array are in a chronological order of arrival.
 *
 *  @return Returns copy of boolean array of recorded test results.
 */
public final function array<byte> GetTestRecords()
{
    return successRecords;
}

/**
 *      Returns index numbers (starting from 1, not 0) of tests that ended in
 *  a success, while performed for the same test case, context and issue.
 *      So if tests went:   [success, success, failure, success, failure],
 *      method will return: [1, 2, 4].
 *
 *  All results in the array are in a chronological order of arrival.
 *
 *  @return index numbers of successful tests.
 */
public final function array<int> GetSuccessfulTests()
{
    local int           i;
    local array<int>    result;
    for (i = 0; i < successRecords.length; i += 1)
    {
        if (successRecords[i] > 0) {
            result[result.length] = i + 1;
        }
    }
    return result;
}

/**
 *      Returns index numbers (starting from 1, not 0) of tests that ended in
 *  a failure, while performed for the same test case, context and issue.
 *      So if tests went:   [success, success, failure, success, failure],
 *      method will return: [3, 5].
 *
 *  All results in the array are in a chronological order of arrival.
 *
 *  @return index numbers of successful tests.
 */
public final function array<int> GetFailedTests()
{
    local int           i;
    local array<int>    result;
    for (i = 0; i < successRecords.length; i += 1)
    {
        if (successRecords[i] == 0) {
            result[result.length] = i + 1;
        }
    }
    return result;
}

/**
 *  Returns a formatted text representation of the caller `IssueSummary`
 *  in a following format:
 *  "{$text_default <issue_description>} {$text_subtle [<failed_test_numbers>]}"
 *
 *  @return Formatted string with text representation of the
 *      caller `IssueSummary`.
 */
public final function string ToString()
{
    local int           i;
    local string        result;
    local array<int>    failedTests;
    result = "{$text_default" @ GetDescription() $ "}";
    if (GetFailedTestsAmount() <= 0) {
        return result;
    }
    result @= "{$text_subtle [";
    failedTests = GetFailedTests();
    for (i = 0; i < failedTests.length; i += 1)
    {
        if (i < failedTests.length - 1) {
            result $= string(failedTests[i]) $ ", ";
        }
        else {
            result $= string(failedTests[i]);
        }
    }
    return (result $ "]");
}

defaultproperties
{
}