' test_framework.bas - Minimal assertion helpers for Brain Dump QB64 tests
' Compile and run via tests/run_tests.bas (the standalone test runner).
'
' Requires the following DIM SHARED variables declared in run_tests.bas
' BEFORE any $Include directive:
'   DIM SHARED g_TestPassed AS INTEGER
'   DIM SHARED g_TestFailed AS INTEGER
'$INCLUDEONCE

' ============================================================
' T_BeginSuite
' Prints a labelled header for a group of related tests.
' ============================================================
SUB T_BeginSuite (suiteName AS STRING)
    PRINT
    PRINT "=== " + suiteName + " ==="
END SUB

' ============================================================
' T_Assert
' Passes when condition is non-zero (QB64 true = -1).
' Prints [PASS] / [FAIL] with the test label.
' ============================================================
SUB T_Assert (condition AS INTEGER, testName AS STRING)
    IF condition THEN
        g_TestPassed = g_TestPassed + 1
        PRINT "  [PASS] " + testName
    ELSE
        g_TestFailed = g_TestFailed + 1
        PRINT "  [FAIL] " + testName
    END IF
END SUB

' ============================================================
' T_AssertStr
' Passes when actual$ = expected$.
' On failure prints both values for easy debugging.
' ============================================================
SUB T_AssertStr (actual AS STRING, expected AS STRING, testName AS STRING)
    IF actual = expected THEN
        g_TestPassed = g_TestPassed + 1
        PRINT "  [PASS] " + testName
    ELSE
        g_TestFailed = g_TestFailed + 1
        PRINT "  [FAIL] " + testName
        PRINT "         got:      [" + actual + "]"
        PRINT "         expected: [" + expected + "]"
    END IF
END SUB

' ============================================================
' T_AssertInt
' Passes when actual% = expected%.
' On failure prints both values for easy debugging.
' ============================================================
SUB T_AssertInt (actual AS INTEGER, expected AS INTEGER, testName AS STRING)
    IF actual = expected THEN
        g_TestPassed = g_TestPassed + 1
        PRINT "  [PASS] " + testName
    ELSE
        g_TestFailed = g_TestFailed + 1
        PRINT "  [FAIL] " + testName
        PRINT "         got:      " + LTRIM$(STR$(actual))
        PRINT "         expected: " + LTRIM$(STR$(expected))
    END IF
END SUB
