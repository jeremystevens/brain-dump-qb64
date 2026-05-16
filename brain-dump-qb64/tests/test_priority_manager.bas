' test_priority_manager.bas - Unit tests for priority_manager.bas
' Covers: Priority_IsValid%, Priority_GetLabel$, Priority_GetWeight%,
'         Priority_LabelToLevel%, Priority_BuildTag$, Priority_Parse%,
'         Priority_SortCompare%
'$INCLUDEONCE

' ============================================================
' TestSuite_PriorityManager — master entry point
' ============================================================
SUB TestSuite_PriorityManager
    CALL T_BeginSuite("PriorityManager")
    CALL Test_Priority_IsValid
    CALL Test_Priority_GetLabel
    CALL Test_Priority_GetWeight
    CALL Test_Priority_LabelToLevel
    CALL Test_Priority_BuildTag
    CALL Test_Priority_Parse
    CALL Test_Priority_SortCompare
END SUB

' ============================================================
' Priority_IsValid%
' ============================================================
SUB Test_Priority_IsValid
    ' All defined levels 0-4 are valid
    CALL T_Assert(Priority_IsValid%(0), "IsValid: PRIORITY_NONE (0) is valid")
    CALL T_Assert(Priority_IsValid%(1), "IsValid: PRIORITY_LOW (1) is valid")
    CALL T_Assert(Priority_IsValid%(2), "IsValid: PRIORITY_MEDIUM (2) is valid")
    CALL T_Assert(Priority_IsValid%(3), "IsValid: PRIORITY_HIGH (3) is valid")
    CALL T_Assert(Priority_IsValid%(4), "IsValid: PRIORITY_CRITICAL (4) is valid")

    ' Values outside the range are invalid
    CALL T_Assert(NOT Priority_IsValid%(-1),  "IsValid: -1 is invalid")
    CALL T_Assert(NOT Priority_IsValid%(5),   "IsValid: 5 is invalid")
    CALL T_Assert(NOT Priority_IsValid%(100), "IsValid: 100 is invalid")
END SUB

' ============================================================
' Priority_GetLabel$
' ============================================================
SUB Test_Priority_GetLabel
    CALL T_AssertStr(Priority_GetLabel$(0),  "NONE",     "GetLabel: 0 -> NONE")
    CALL T_AssertStr(Priority_GetLabel$(1),  "LOW",      "GetLabel: 1 -> LOW")
    CALL T_AssertStr(Priority_GetLabel$(2),  "MED",      "GetLabel: 2 -> MED")
    CALL T_AssertStr(Priority_GetLabel$(3),  "HIGH",     "GetLabel: 3 -> HIGH")
    CALL T_AssertStr(Priority_GetLabel$(4),  "CRITICAL", "GetLabel: 4 -> CRITICAL")

    ' Out-of-range values fall through to ELSE -> NONE
    CALL T_AssertStr(Priority_GetLabel$(-1), "NONE", "GetLabel: -1 -> NONE (ELSE)")
    CALL T_AssertStr(Priority_GetLabel$(99), "NONE", "GetLabel: 99 -> NONE (ELSE)")
END SUB

' ============================================================
' Priority_GetWeight%
' ============================================================
SUB Test_Priority_GetWeight
    CALL T_AssertInt(Priority_GetWeight%(4),  15, "GetWeight: CRITICAL -> 15")
    CALL T_AssertInt(Priority_GetWeight%(3),  10, "GetWeight: HIGH -> 10")
    CALL T_AssertInt(Priority_GetWeight%(2),  5,  "GetWeight: MEDIUM -> 5")
    CALL T_AssertInt(Priority_GetWeight%(1),  2,  "GetWeight: LOW -> 2")
    CALL T_AssertInt(Priority_GetWeight%(0),  0,  "GetWeight: NONE -> 0")

    ' Out-of-range falls to ELSE -> 0
    CALL T_AssertInt(Priority_GetWeight%(-1), 0, "GetWeight: -1 -> 0 (ELSE)")
    CALL T_AssertInt(Priority_GetWeight%(99), 0, "GetWeight: 99 -> 0 (ELSE)")
END SUB

' ============================================================
' Priority_LabelToLevel%
' ============================================================
SUB Test_Priority_LabelToLevel
    ' Known labels (uppercase)
    CALL T_AssertInt(Priority_LabelToLevel%("CRITICAL"), 4, "LabelToLevel: CRITICAL -> 4")
    CALL T_AssertInt(Priority_LabelToLevel%("HIGH"),     3, "LabelToLevel: HIGH -> 3")
    CALL T_AssertInt(Priority_LabelToLevel%("MED"),      2, "LabelToLevel: MED -> 2")
    CALL T_AssertInt(Priority_LabelToLevel%("MEDIUM"),   2, "LabelToLevel: MEDIUM -> 2")
    CALL T_AssertInt(Priority_LabelToLevel%("LOW"),      1, "LabelToLevel: LOW -> 1")

    ' Case-insensitive via UCASE$ inside the function
    CALL T_AssertInt(Priority_LabelToLevel%("critical"), 4, "LabelToLevel: lowercase critical -> 4")
    CALL T_AssertInt(Priority_LabelToLevel%("high"),     3, "LabelToLevel: lowercase high -> 3")
    CALL T_AssertInt(Priority_LabelToLevel%("med"),      2, "LabelToLevel: lowercase med -> 2")
    CALL T_AssertInt(Priority_LabelToLevel%("medium"),   2, "LabelToLevel: lowercase medium -> 2")
    CALL T_AssertInt(Priority_LabelToLevel%("low"),      1, "LabelToLevel: lowercase low -> 1")

    ' Leading/trailing whitespace stripped by LTRIM$/RTRIM$
    CALL T_AssertInt(Priority_LabelToLevel%("  HIGH  "), 3, "LabelToLevel: padded HIGH -> 3")
    CALL T_AssertInt(Priority_LabelToLevel%("  low  "),  1, "LabelToLevel: padded low -> 1")

    ' Unknown labels fall to ELSE -> PRIORITY_NONE (0)
    CALL T_AssertInt(Priority_LabelToLevel%("EXTREME"), 0, "LabelToLevel: unknown label -> 0")
    CALL T_AssertInt(Priority_LabelToLevel%(""),        0, "LabelToLevel: empty string -> 0")
    CALL T_AssertInt(Priority_LabelToLevel%("NONE"),    0, "LabelToLevel: NONE -> 0 (ELSE)")
END SUB

' ============================================================
' Priority_BuildTag$
' ============================================================
SUB Test_Priority_BuildTag
    ' PRIORITY_NONE and below produce no tag (keeps file clean)
    CALL T_AssertStr(Priority_BuildTag$(0),  "",           "BuildTag: NONE (0) -> empty string")
    CALL T_AssertStr(Priority_BuildTag$(-1), "",           "BuildTag: -1 (< NONE) -> empty string")

    ' Levels 1-4 produce "priority:N"
    CALL T_AssertStr(Priority_BuildTag$(1),  "priority:1", "BuildTag: LOW (1) -> priority:1")
    CALL T_AssertStr(Priority_BuildTag$(2),  "priority:2", "BuildTag: MEDIUM (2) -> priority:2")
    CALL T_AssertStr(Priority_BuildTag$(3),  "priority:3", "BuildTag: HIGH (3) -> priority:3")
    CALL T_AssertStr(Priority_BuildTag$(4),  "priority:4", "BuildTag: CRITICAL (4) -> priority:4")
END SUB

' ============================================================
' Priority_Parse%
' ============================================================
SUB Test_Priority_Parse
    ' Standard full-line format written by WriteIdeaToFile
    CALL T_AssertInt(Priority_Parse%("[01-01-2025 12:00:00] Build app | #dev priority:3"), 3, _
        "Parse: extracts priority:3 from full idea line")
    CALL T_AssertInt(Priority_Parse%("[01-01-2025 12:00:00] Fix crash | priority:4 fav:1"), 4, _
        "Parse: extracts priority:4 (CRITICAL)")
    CALL T_AssertInt(Priority_Parse%("[01-01-2025 12:00:00] Task | priority:1"), 1, _
        "Parse: extracts priority:1 (LOW)")
    CALL T_AssertInt(Priority_Parse%("[01-01-2025 12:00:00] Plan | priority:2"), 2, _
        "Parse: extracts priority:2 (MEDIUM)")

    ' Backward-compatibility: no priority tag -> PRIORITY_NONE
    CALL T_AssertInt(Priority_Parse%("[01-01-2025 12:00:00] Old idea with no priority"), 0, _
        "Parse: missing priority tag -> 0")
    CALL T_AssertInt(Priority_Parse%("[01-01-2025 12:00:00] Idea | #tag"), 0, _
        "Parse: tag section present but no priority -> 0")

    ' Edge cases
    CALL T_AssertInt(Priority_Parse%(""), 0, "Parse: empty string -> 0")
    CALL T_AssertInt(Priority_Parse%("no timestamp plain text"), 0, "Parse: plain text -> 0")

    ' Invalid level beyond PRIORITY_CRITICAL -> PRIORITY_NONE
    CALL T_AssertInt(Priority_Parse%("idea | priority:5"), 0, "Parse: invalid level 5 -> 0")
    CALL T_AssertInt(Priority_Parse%("idea | priority:99"), 0, "Parse: invalid level 99 -> 0")

    ' PRIORITY_NONE (0) is valid and returns 0
    CALL T_AssertInt(Priority_Parse%("idea | priority:0"), 0, "Parse: priority:0 -> PRIORITY_NONE (0)")

    ' priority: marker with no digits -> PRIORITY_NONE
    CALL T_AssertInt(Priority_Parse%("idea | priority:"), 0, "Parse: priority: with no digits -> 0")
END SUB

' ============================================================
' Priority_SortCompare%
' ============================================================
SUB Test_Priority_SortCompare
    ' Higher priority sorts first (descending order)
    CALL T_AssertInt(Priority_SortCompare%(4, 3),  1,  "SortCompare: CRITICAL > HIGH -> 1")
    CALL T_AssertInt(Priority_SortCompare%(3, 1),  1,  "SortCompare: HIGH > LOW -> 1")
    CALL T_AssertInt(Priority_SortCompare%(4, 0),  1,  "SortCompare: CRITICAL > NONE -> 1")

    CALL T_AssertInt(Priority_SortCompare%(3, 4),  -1, "SortCompare: HIGH < CRITICAL -> -1")
    CALL T_AssertInt(Priority_SortCompare%(1, 3),  -1, "SortCompare: LOW < HIGH -> -1")
    CALL T_AssertInt(Priority_SortCompare%(0, 4),  -1, "SortCompare: NONE < CRITICAL -> -1")

    ' Equal levels
    CALL T_AssertInt(Priority_SortCompare%(4, 4),  0,  "SortCompare: CRITICAL = CRITICAL -> 0")
    CALL T_AssertInt(Priority_SortCompare%(3, 3),  0,  "SortCompare: HIGH = HIGH -> 0")
    CALL T_AssertInt(Priority_SortCompare%(0, 0),  0,  "SortCompare: NONE = NONE -> 0")
END SUB
