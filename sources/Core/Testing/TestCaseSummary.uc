/**
 *      Class for storing and processing the information about how well testing
 *  for a certain `TestCase` went. That information is stored as
 *  a collection of `IssueSummary`s, that can be accessed all at once
 *  or by their context.
 *      `TestCaseSummary` must be initialized for some `TestCase` before it can
 *  be used for anything (unlike `IssueSummary`).
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
class TestCaseSummary extends AcediaObject;

//  Case for which this summary was initialized.
//  `none` if it was not.
var private class<TestCase> ownerCase;

/**
 *
 *      We will store issue summaries for different contexts separately.
 *      INVARIANT: any function that adds records to `contextRecords`
 *  must guarantee that:
 *      1.  No two distinct records will have the same `context`;
 *      2.  All the `IssueSummary`s in `issueSummaries` array have different
 *          issue descriptions.
 *      Comparisons of `string`s for two above conditions are case-insensitive.
 */
struct ContextRecord
{
    var string              context;
    var array<IssueSummary> issueSummaries;
};
var private array<ContextRecord> contextRecords;

//  String literals used for displaying array of test case summaries
var private const string indent;
var private const string reportHeader;
var private const string reportSuccessfulEnding;
var private const string reportUnsuccessfulEnding;

/**
 *      Initializes caller summary for given `TestCase` class.
 *      Can only be successfully done once, but will fail if
 *  passed a `none` reference.
 *
 *  @param  targetCase  `TestCase` class for which this summary will be
 *      recording test results.
 *  @return `true` if initialization was successful and `false otherwise
 *      (either summary already initialized or passed reference is `none`).
 */
public final function bool Initialize(class<TestCase> targetCase)
{
    if (ownerCase != none)  return false;
    if (targetCase == none) return false;
    ownerCase = targetCase;
    return true;
}

/**
 *      Returns index of a context record with a given description
 *  (`context`) in `contextRecords`.
 *      Creates one if missing. Never fails.
 *
 *  @param  context  Context that desired record must match.
 *  @return Index of the context record that matches `context`.
 *      Returned index is always valid.
 */
private final function int TouchContext(string context)
{
    local int           i;
    local ContextRecord newRecord;
    //  Try to find existing record with given context description
    for (i = 0; i < contextRecords.length; i += 1)
    {
        if (context ~= contextRecords[i].context) {
            return i;
        }
    }
    //  If there is none - make a new one
    newRecord.context = context;
    contextRecords[contextRecords.length] = newRecord;
    return (contextRecords.length - 1);
}

/**
 *      Finds indices of a context record and an `IssueSummary` in
 *  a nested array that have matching `context`
 *  and `issueDescription`.
 *      Creates records and/or `IssueSummary` if missing. Never fails.
 *
 *  @param  context  Context description that
 *      desired record must match.
 *  @param  issueDescription    Issue description that
 *      desired `IssueSummary`must match.
 *  @param  recordIndex         Index of the context record that matches
 *      `context` description will be recorded here.
 *      Returned value is always valid. Passed value is discarded.
 *  @param  recordIndex         Index of the `IssueSummary` that matches
 *      `issueDescription` description will be recorded here.
 *      Returned value is always valid. Passed value is discarded.
 */
private final function TouchIssue(
    string context,
    string issueDescription,
    out int recordIndex,
    out int issueIndex
)
{
    local int                   i;
    local array<IssueSummary>   issueSummaries;
    recordIndex = TouchContext(context);
    issueSummaries = contextRecords[recordIndex].issueSummaries;
    //  Try to find existing issue summary with a given description
    for (i = 0; i < issueSummaries.length; i += 1)
    {
        if (issueSummaries[i] == none) continue;
        if (issueDescription ~= issueSummaries[i].GetDescription())
        {
            issueIndex = i;
            return;
        }
    }
    //  If there is none - add a new one
    issueIndex = issueSummaries.length;
    issueSummaries[issueIndex] = new class'IssueSummary';
    issueSummaries[issueIndex].SetIssue(ownerCase, context, issueDescription);
    contextRecords[recordIndex].issueSummaries = issueSummaries;
}

/**
 *  Checks if caller summary was correctly initialized.
 *
 *  @return `true` if summary was correctly initialized and `false` otherwise.
 */
public final function bool IsInitialized()
{
    return (ownerCase != none);
}

/**
 *  Adds result of another test (success or not) to the records of this summary.
 *
 *  @param  context             Context under which test was performed.
 *  @param  issueDescription    Description of issue,
 *      for which test was performed.
 *  @param  success `true` if test was successful and had passed,
 *      `false` otherwise.
 */
public final function AddTestResult(
    string  context,
    string  issueDescription,
    bool    success
)
{
    local int recordIndex, issueIndex;
    TouchIssue(context, issueDescription, recordIndex, issueIndex);
    contextRecords[recordIndex]
        .issueSummaries[issueIndex]
        .AddTestResult(success);
}

/**
 *  Returns all contexts, for which caller summary has any records of tests
 *  being performed.
 *
 *  To check if particular context exists you can use `DoesContextExists()`.
 *
 *  @return Array of `string`s, each representing one of the contexts,
 *      used in tests.
 *      Guarantees no duplicates (equality without accounting for case).
 */
public final function array<string> GetContexts()
{
    local int           i;
    local array<string> result;
    for (i = 0; i < contextRecords.length; i += 1) {
        result[result.length] = contextRecords[i].context;
    }
    return result;
}

/**
 *  Checks if given context has any records about performing tests
 *  (whether they ended in success or a failure) under it.
 *
 *  To get an array of all existing contexts use `GetContexts()`.
 *
 *  @param  context A context to check for existing in records.
 *  @return `true` if there was a record about a test being performed under
 *      a given context and `false` otherwise.
 */
public final function bool DoesContextExists(string context)
{
    local int i;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        if (contextRecords[i].context ~= context) {
            return true;
        }
    }
    return false;
}

/**
 *  `IssueSummary`s for every issue that was tested and recorded in
 *  the caller `TestCaseSummary`.
 *
 *  @return Array of `IssueSummary`s for every tested and recorded issue.
 */
public final function array<IssueSummary> GetIssueSummaries()
{
    local int                   i, j;
    local array<IssueSummary>   recordedSummaries;
    local array<IssueSummary>   result;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        recordedSummaries = contextRecords[i].issueSummaries;
        for (j = 0; j < recordedSummaries.length; j += 1) {
            result[result.length] = recordedSummaries[j];
        }
    }
    return result;
}

/**
 *  Returns `IssueSummary`s for every issue that was tested under
 *  a given context and recorded in caller `TestCaseSummary`.
 *
 *  @param  context Context under which issues of interest were tested.
 *  @return Array of `IssueSummary`s for every issue that was tested under
 *  given context.
 */
public final function array<IssueSummary> GetIssueSummariesForContext(
    string context
)
{
    local int                   i;
    local array<IssueSummary>   emptyResult;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        if (contextRecords[i].context ~= context) {
            return contextRecords[i].issueSummaries;
        }
    }
    return emptyResult;
}

//  Counts total amount of tests performed under the contexts
//  corresponding to `contextRecords[recordIndex]` record.
private final function int GetTotalTestsAmountForRecord(int recordIndex)
{
    local int                   i;
    local int                   result;
    local array<IssueSummary>   issueSummaries;
    issueSummaries = contextRecords[recordIndex].issueSummaries;
    result = 0;
    for (i = 0; i < issueSummaries.length; i += 1)
    {
        if (issueSummaries[i] == none) continue;
        result += issueSummaries[i].GetTotalTestsAmount();
    }
    return result;
}

/**
 *  Total amount of performed tests, recorded in caller `TestCaseSummary`.
 *
 *  If you are interested in amount of test under a specific context, -
 *  use `GetTotalTestsAmountForContext()` instead.
 *
 *  @return Total amount of performed tests.
 */
public final function int GetTotalTestsAmount()
{
    local int i;
    local int result;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        result += GetTotalTestsAmountForRecord(i);
    }
    return result;
}

/**
 *  Total amount of tests, performed under a context `context` and
 *  recorded in caller `TestCaseSummary`.
 *
 *  If you are interested in total amount of test under all contexts, -
 *  use `GetTotalTestsAmount()` instead.
 *
 *  @param  context Context for which method must count amount of
 *      performed tests.
 *  @return Total amount of tests, performed under given context.
 *      If given context does not exist in records, - returns `-1`.
 */
public final function int GetTotalTestsAmountForContext(string context)
{
    local int i;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        if (context ~= contextRecords[i].context) {
            return GetTotalTestsAmountForRecord(i);
        }
    }
    return -1;
}

//  Counts total amount of successful tests performed under the contexts
//  corresponding to `contextRecords[recordIndex]` record.
private final function int GetSuccessfulTestsAmountForRecord(int recordIndex)
{
    local int                   i;
    local int                   result;
    local array<IssueSummary>   issueSummaries;
    issueSummaries = contextRecords[recordIndex].issueSummaries;
    result = 0;
    for (i = 0; i < issueSummaries.length; i += 1)
    {
        if (issueSummaries[i] == none) continue;
        result += issueSummaries[i].GetSuccessfulTestsAmount();
    }
    return result;
}

/**
 *  Total amount of successfully performed tests,
 *  recorded in caller `TestCaseSummary`.
 *
 *  If you are interested in amount of successful test under a specific context,
 *  - use `GetSuccessfulTestsAmountForContext()` instead.
 *
 *  @return Total amount of successfully performed tests.
 */
public final function int GetSuccessfulTestsAmount()
{
    local int i;
    local int result;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        result += GetSuccessfulTestsAmountForRecord(i);
    }
    return result;
}

/**
 *  Total amount of tests, performed under a context `context` and
 *  recorded in caller `TestCaseSummary`.
 *
 *  If you are interested in total amount of successful test under all contexts,
 *  - use `GetSuccessfulTestsAmount()` instead.
 *
 *  @param  context Context for which we method must count amount of
 *      successful tests.
 *  @return Total amount of successful tests, performed under given context.
 *      If given context does not exist in records, - returns `-1`.
 */
public final function int GetSuccessfulTestsAmountForContext(string context)
{
    local int i;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        if (context ~= contextRecords[i].context) {
            return GetSuccessfulTestsAmountForRecord(i);
        }
    }
    return -1;
}

//  Counts total amount of tests, failed under the contexts
//  corresponding to `contextRecords[recordIndex]` record.
private final function int GetFailedTestsAmountForRecord(int recordIndex)
{
    local int                   i;
    local int                   result;
    local array<IssueSummary>   issueSummaries;
    issueSummaries = contextRecords[recordIndex].issueSummaries;
    result = 0;
    for (i = 0; i < issueSummaries.length; i += 1)
    {
        if (issueSummaries[i] == none) continue;
        result += issueSummaries[i].GetFailedTestsAmount();
    }
    return result;
}

/**
 *  Total amount of failed tests, recorded in caller `TestCaseSummary`.
 *
 *  If you are interested in amount of failed test under a specific context, -
 *  use `GetFailedTestsAmountForContext()` instead.
 *
 *  @return Total amount of failed tests.
 */
public final function int GetFailedTestsAmount()
{
    local int i;
    local int result;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        result += GetFailedTestsAmountForRecord(i);
    }
    return result;
}

/**
 *  Total amount of failed tests, performed under a context `context` and
 *  recorded in caller `TestCaseSummary`.
 *
 *  If you are interested in total amount of failed test under all contexts, -
 *  use `GetFailedTestsAmount()` instead.
 *
 *  @param  context Context for which method must count amount of
 *      failed tests.
 *  @return Total amount of failed tests, performed under given context.
 *      If given context does not exist in records, - returns `-1`.
 */
public final function int GetFailedTestsAmountForContext(string context)
{
    local int i;
    for (i = 0; i < contextRecords.length; i += 1)
    {
        if (context ~= contextRecords[i].context) {
            return GetFailedTestsAmountForRecord(i);
        }
    }
    return -1;
}

/**
 *  Checks whether all tests recorded in this summary have passed.
 *
 *  @return `true` if all tests have passed, `false` otherwise.
 */
public final function bool HasPassedAllTests()
{
    return (GetFailedTestsAmount() <= 0);
}

/**
 *  Checks whether all tests, performed under given context and
 *  recorded in this summary, have passed.
 *
 *  @return `true` if all tests under given context have passed,
 *      `false` otherwise.
 *      If given context does not exists - it did not fail any tests.
 */
public final function bool HasPassedAllTestsForContext(string context)
{
    return (GetFailedTestsAmountForContext(context) <= 0);
}

/**
 *  Generates a text summary for a set of results, given as array of
 *  `TestCaseSummary`s (exactly how results are returned by `TestingService`).
 *
 *  @param  summaries   `TestCase` summaries (obtained as a result of testing)
 *      that we want to display.
 *  @return    Test representation of `summaries` as an array of
 *      formatted strings, where each string corresponds to it's own line.
 */
public final static function array<string> GenerateStringSummary(
    array<TestCaseSummary> summaries)
{
    local int           i;
    local bool          allTestsPassed;
    local array<string> result;
    allTestsPassed = true;
    result[0] = default.reportHeader;
    for (i = 0; i < summaries.length; i += 1)
    {
        if (summaries[i] == none) continue;
        summaries[i].AppendCaseSummary(result);
        allTestsPassed = allTestsPassed && summaries[i].HasPassedAllTests();
    }
    if (allTestsPassed) {
        result[result.length] = default.reportSuccessfulEnding;
    }
    else {
        result[result.length] = default.reportUnsuccessfulEnding;
    }
    return result;
}

//  Add text representation of caller `TestCase` to the existing array `result`.
private final function AppendCaseSummary(out array<string> result)
{
    local int                   i, j;
    local array<string>         contexts;
    local string                testCaseAnnouncement;
    local array<IssueSummary>   issues;
    if (ownerCase == none) return;
    //  Announce case
    testCaseAnnouncement = "{$text_default Test case {$text_emphasis";
    if (ownerCase.static.GetGroup() != "") {
        testCaseAnnouncement @= "[" $ ownerCase.static.GetGroup() $ "]";
    }
    testCaseAnnouncement @= ownerCase.static.GetName() $ "}:}";
    if (GetFailedTestsAmount() > 0) {
        testCaseAnnouncement @= "{$text_failure failed}!";
    }
    else {
        testCaseAnnouncement @= "{$text_ok passed}!";
    }
    result[result.length] = testCaseAnnouncement;
    //  Report failed tests
    contexts = GetContexts();
    for (i = 0;i < contexts.length; i += 1)
    {
        if (GetFailedTestsAmountForContext(contexts[i]) <= 0) continue;
        result[result.length] = "{$text_warning " $ contexts[i] $ "}";
        issues = GetIssueSummariesForContext(contexts[i]);
        for (j = 0; j < issues.length; j += 1)
        {
            if (issues[j] == none)                      continue;
            if (issues[j].GetFailedTestsAmount() <= 0)  continue;
            result[result.length] = indent $ issues[j].ToString();
        }
    }
}

defaultproperties
{
    indent = "        "
    reportHeader = "{$text_default ############################## {$text_emphasis Test summary} ###############################}"
    reportSuccessfulEnding = "{$text_default ########################### {$text_ok All tests have passed!} ############################}"
    reportUnsuccessfulEnding = "{$text_default ########################## {$text_failure Some tests have failed :(} ###########################}"
}