' priority_ui.bas - Priority system UI rendering
' Part of Brain Dump QB64 - Idea Priority System
' Responsibility: ALL screen rendering related to priority.
'                 Calls priority_manager for data — never stores anything.
'                 No file I/O. No business logic.
'$INCLUDEONCE

' ============================================================
' Priority_RenderLabel
' Prints a formatted priority badge for a given level.
' Example output:  [HIGH]   [CRITICAL]   [NONE]
' Designed to be called inline when listing ideas.
' ============================================================
SUB Priority_RenderLabel (priorityLevel AS INTEGER)
    PRINT "[" + Priority_GetLabel$(priorityLevel) + "]";
END SUB

' ============================================================
' Priority_ShowLegend
' Prints the full priority level reference table.
' Called from help screens or before selection menus.
' ============================================================
SUB Priority_ShowLegend
    PRINT "  Priority Levels:"
    PRINT "    0 = [NONE]     - No priority assigned"
    PRINT "    1 = [LOW]      - Nice to have"
    PRINT "    2 = [MED]      - Should do soon"
    PRINT "    3 = [HIGH]     - Important"
    PRINT "    4 = [CRITICAL] - Must do now"
    PRINT
END SUB

' ============================================================
' Priority_RenderMenu
' Prints the numbered priority selection menu.
' Called before Priority_SelectLevel% prompts for input.
' ============================================================
SUB Priority_RenderMenu
    PRINT "  Select Priority:"
    PRINT "    0. [NONE]"
    PRINT "    1. [LOW]"
    PRINT "    2. [MED]"
    PRINT "    3. [HIGH]"
    PRINT "    4. [CRITICAL]"
    PRINT
END SUB

' ============================================================
' Priority_SelectLevel%
' Interactive prompt — renders menu, reads user input,
' validates and returns a priority integer (0-4).
' On invalid input defaults to PRIORITY_NONE.
' ============================================================
FUNCTION Priority_SelectLevel%
    DIM inputStr AS STRING
    DIM level    AS INTEGER

    CALL Priority_RenderMenu

    INPUT "  Enter priority (0-4, or press Enter for NONE): ", inputStr

    IF LTRIM$(RTRIM$(inputStr)) = "" THEN
        Priority_SelectLevel = PRIORITY_NONE
        EXIT FUNCTION
    END IF

    level = VAL(inputStr)

    IF Priority_IsValid%(level) THEN
        Priority_SelectLevel = level
    ELSE
        PRINT "  Invalid priority. Defaulting to [NONE]."
        Priority_SelectLevel = PRIORITY_NONE
    END IF
END FUNCTION
