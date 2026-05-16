' priority_manager.bas - Priority system business logic
' Part of Brain Dump QB64 - Idea Priority System
' Responsibility: All priority data logic, validation, mapping,
'                 sorting, and file-format integration.
'                 NEVER renders UI. NEVER prints to screen.
' NOTE: CONST priority levels are declared in main.bas (global scope).
'       QB64 requires CONST before any SUB/FUNCTION in compiled unit.
'$INCLUDEONCE

' ============================================================
' Priority_Init
' Called once at startup. Reserved for future work such as
' loading custom priority configs from disk.
' ============================================================
SUB Priority_Init
    ' Reserved for future initialization
END SUB

' ============================================================
' Priority_IsValid%
' Returns -1 (true) if priorityLevel is a recognized value.
' Returns 0 (false) otherwise.
' Update this when new levels are added.
' ============================================================
FUNCTION Priority_IsValid% (priorityLevel AS INTEGER)
    IF priorityLevel >= PRIORITY_NONE AND priorityLevel <= PRIORITY_CRITICAL THEN
        Priority_IsValid = -1
    ELSE
        Priority_IsValid = 0
    END IF
END FUNCTION

' ============================================================
' Priority_GetLabel$
' Returns the display label for a priority level.
' Centralised mapping — only place labels are defined.
' ============================================================
FUNCTION Priority_GetLabel$ (priorityLevel AS INTEGER)
    SELECT CASE priorityLevel
        CASE PRIORITY_NONE
            Priority_GetLabel = "NONE"
        CASE PRIORITY_LOW
            Priority_GetLabel = "LOW"
        CASE PRIORITY_MEDIUM
            Priority_GetLabel = "MED"
        CASE PRIORITY_HIGH
            Priority_GetLabel = "HIGH"
        CASE PRIORITY_CRITICAL
            Priority_GetLabel = "CRITICAL"
        CASE ELSE
            Priority_GetLabel = "NONE"
    END SELECT
END FUNCTION

' ============================================================
' Priority_GetWeight%
' Returns the numeric weight for a priority level.
' Used by search scoring and future analytics.
' Search score bonuses: Critical=+15, High=+10, Med=+5, Low=+2
' ============================================================
FUNCTION Priority_GetWeight% (priorityLevel AS INTEGER)
    SELECT CASE priorityLevel
        CASE PRIORITY_CRITICAL
            Priority_GetWeight = 15
        CASE PRIORITY_HIGH
            Priority_GetWeight = 10
        CASE PRIORITY_MEDIUM
            Priority_GetWeight = 5
        CASE PRIORITY_LOW
            Priority_GetWeight = 2
        CASE ELSE
            Priority_GetWeight = 0
    END SELECT
END FUNCTION

' ============================================================
' Priority_LabelToLevel%
' Converts a string label (from query operators or file data)
' back to the integer level. Case-insensitive.
' Returns PRIORITY_NONE if label is unrecognised.
' ============================================================
FUNCTION Priority_LabelToLevel% (label AS STRING)
    SELECT CASE UCASE$(LTRIM$(RTRIM$(label)))
        CASE "CRITICAL"
            Priority_LabelToLevel = PRIORITY_CRITICAL
        CASE "HIGH"
            Priority_LabelToLevel = PRIORITY_HIGH
        CASE "MED", "MEDIUM"
            Priority_LabelToLevel = PRIORITY_MEDIUM
        CASE "LOW"
            Priority_LabelToLevel = PRIORITY_LOW
        CASE ELSE
            Priority_LabelToLevel = PRIORITY_NONE
    END SELECT
END FUNCTION

' ============================================================
' Priority_BuildTag$
' Returns the priority marker string written into ideas.txt.
' Format: "priority:N"  (N is the integer level)
' Using integer storage avoids label-change fragility.
' ============================================================
FUNCTION Priority_BuildTag$ (priorityLevel AS INTEGER)
    IF priorityLevel <= PRIORITY_NONE THEN
        Priority_BuildTag = ""   ' No tag written for NONE — keeps file clean
    ELSE
        Priority_BuildTag = "priority:" + LTRIM$(STR$(priorityLevel))
    END IF
END FUNCTION

' ============================================================
' Priority_Parse%
' Extracts the priority level from a raw idea line.
' Scans for "priority:N" token and returns the integer N.
' Returns PRIORITY_NONE if no priority marker found.
' Compatible with old ideas that predate the priority system.
' ============================================================
FUNCTION Priority_Parse% (ideaLine AS STRING)
    DIM marker  AS STRING
    DIM startPos AS INTEGER
    DIM numStr  AS STRING
    DIM endPos  AS INTEGER
    DIM level   AS INTEGER

    marker   = "priority:"
    startPos = INSTR(LCASE$(ideaLine), marker)

    IF startPos = 0 THEN
        Priority_Parse = PRIORITY_NONE
        EXIT FUNCTION
    END IF

    ' Extract the digit(s) immediately after "priority:"
    numStr  = ""
    endPos  = startPos + LEN(marker)

    DO WHILE endPos <= LEN(ideaLine)
        DIM ch AS STRING
        ch = MID$(ideaLine, endPos, 1)
        IF ch >= "0" AND ch <= "9" THEN
            numStr = numStr + ch
            endPos = endPos + 1
        ELSE
            EXIT DO
        END IF
    LOOP

    IF numStr = "" THEN
        Priority_Parse = PRIORITY_NONE
        EXIT FUNCTION
    END IF

    level = VAL(numStr)

    IF Priority_IsValid%(level) THEN
        Priority_Parse = level
    ELSE
        Priority_Parse = PRIORITY_NONE
    END IF
END FUNCTION

' ============================================================
' Priority_SortCompare%
' Compares two priority levels for sorting.
' Returns:  1 if a > b  (a is higher priority)
'           0 if a = b
'          -1 if a < b  (a is lower priority)
' Designed for descending sort (Critical first).
' ============================================================
FUNCTION Priority_SortCompare% (a AS INTEGER, b AS INTEGER)
    IF a > b THEN
        Priority_SortCompare = 1
    ELSEIF a < b THEN
        Priority_SortCompare = -1
    ELSE
        Priority_SortCompare = 0
    END IF
END FUNCTION
