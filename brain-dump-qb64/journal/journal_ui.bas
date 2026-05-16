' journal_ui.bas - Daily Journal Mode UI screens
' Part of Brain Dump QB64 - Daily Journal Mode (Phase 3)
' Responsibility: ALL screen rendering for the journal system.
'                 Calls journal_manager for data operations.
'                 Uses window_renderer for screen chrome.
'                 NO storage logic. NO business logic.
'$INCLUDEONCE

' ============================================================
' JournalScreen
' Main journal hub — called from main menu option 7.
' Lets user choose: write, browse, search, export, or return.
' ============================================================
SUB JournalScreen
    DIM choice    AS STRING
    DIM crow      AS INTEGER
    DIM entryCount AS INTEGER
    DIM today     AS STRING

    today      = Date_GetCurrent$
    entryCount = Journal_CountEntries%

    crow = Window_DrawScreen%("DAILY JOURNAL", "[JOURNAL MODE]  [" + Date_Format$(today) + "]  [" + LTRIM$(STR$(entryCount)) + " ENTRIES]")

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow, 3 : PRINT "  " + Date_GetWeekday$(today) + ", " + Date_Format$(today)
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE crow + 2, 3 : PRINT "  1.  Write new journal entry"
    LOCATE crow + 3, 3 : PRINT "  2.  Browse recent entries"
    LOCATE crow + 4, 3 : PRINT "  3.  View today's entries"
    LOCATE crow + 5, 3 : PRINT "  4.  Search journal"
    LOCATE crow + 6, 3 : PRINT "  5.  Export journal"
    LOCATE crow + 7, 3 : PRINT "  6.  Return to main menu"

    LOCATE crow + 9, 3
    INPUT "  Choose (1-6): ", choice

    SELECT CASE LTRIM$(RTRIM$(choice))
        CASE "1" : CALL RetroAudio_PlayMenuMove : CALL Journal_WriteScreen
        CASE "2" : CALL RetroAudio_PlayMenuMove : CALL Journal_BrowseScreen
        CASE "3" : CALL RetroAudio_PlayMenuMove : CALL Journal_TodayScreen
        CASE "4" : CALL RetroAudio_PlayMenuMove : CALL Journal_SearchScreen
        CASE "5" : CALL RetroAudio_PlayMenuMove : CALL Journal_ExportScreen
        CASE "6" : EXIT SUB
        CASE ELSE
            CALL RetroAudio_PlayError
            LOCATE crow + 11, 3 : PRINT "  Invalid. Press any key..."
            SLEEP
    END SELECT
END SUB

' ============================================================
' Journal_WriteScreen
' Full-screen journal entry form.
' Prompts for title, body, tags, priority, and favorite.
' ============================================================
SUB Journal_WriteScreen
    DIM title         AS STRING
    DIM body          AS STRING
    DIM tags          AS STRING
    DIM priorityLevel AS INTEGER
    DIM favoriteFlag  AS INTEGER
    DIM crow          AS INTEGER
    DIM today         AS STRING

    today = Date_GetCurrent$

    crow = Window_DrawScreen%("WRITE JOURNAL ENTRY", "[JOURNAL MODE]  [" + Date_Format$(today) + "]")

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow, 3 : PRINT "  " + Date_GetWeekday$(today) + " — " + Date_Format$(today)
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE crow + 2, 3 : PRINT "Entry title (press Enter for today's date):"
    LOCATE crow + 3, 3
    LINE INPUT "", title
    IF LTRIM$(title) = "" THEN title = Date_Format$(today)

    LOCATE crow + 5, 3 : PRINT "Write your entry (press Enter when done):"
    LOCATE crow + 6, 3
    LINE INPUT "", body

    IF LTRIM$(body) = "" THEN
        CALL RetroAudio_PlayError
        LOCATE crow + 8, 3 : PRINT "No content entered. Entry not saved."
        SLEEP 2
        EXIT SUB
    END IF

    LOCATE crow + 8, 3 : PRINT "Tags (optional, e.g. #reflection #work #ideas):"
    LOCATE crow + 9, 3
    LINE INPUT "", tags

    PRINT
    priorityLevel = Priority_SelectLevel%

    PRINT
    favoriteFlag = Favorites_SelectState%

    CALL Journal_SaveEntry(title, body, tags, priorityLevel, favoriteFlag)
    CALL RetroAudio_PlayConfirm

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow + 14, 3 : PRINT "  Entry saved: " + title
    COLOR g_ThemeFG, g_ThemeBG
    LOCATE crow + 15, 3 : PRINT "  Press any key to continue..."
    SLEEP
END SUB

' ============================================================
' Journal_BrowseScreen
' Displays the most recent journal entries with date, title,
' priority badge, and favorite badge. Shows up to 12 entries.
' ============================================================
SUB Journal_BrowseScreen
    DIM recentBlock AS STRING
    DIM remaining   AS STRING
    DIM lineText    AS STRING
    DIM nlPos       AS INTEGER
    DIM crow        AS INTEGER
    DIM printRow    AS INTEGER
    DIM count       AS INTEGER
    DIM maxRows     AS INTEGER
    DIM entryDate   AS STRING
    DIM entryTitle  AS STRING
    DIM pLevel      AS INTEGER

    crow    = Window_DrawScreen%("BROWSE JOURNAL", "[JOURNAL MODE]  [RECENT ENTRIES]")
    maxRows = UI_ROWS - 5

    recentBlock = Journal_GetRecentEntries$(12)

    IF recentBlock = "" THEN
        LOCATE crow, 3 : PRINT "No journal entries found. Start writing!"
        LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
        SLEEP
        EXIT SUB
    END IF

    ' Column headers
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow, 3
    PRINT ASCII_PadRight$("  #  DATE        PRI FAV  TITLE", UI_COLS - 4);
    COLOR g_ThemeFG, g_ThemeBG
    LOCATE crow + 1, 3 : PRINT ASCII_Repeat$("-", UI_COLS - 6)

    printRow  = crow + 2
    count     = 0
    remaining = recentBlock

    DO WHILE LEN(remaining) > 0
        nlPos = INSTR(remaining, CHR$(10))
        IF nlPos = 0 THEN
            lineText  = remaining
            remaining = ""
        ELSE
            lineText  = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF

        IF LEN(LTRIM$(lineText)) > 0 AND printRow <= maxRows THEN
            count      = count + 1
            entryDate  = Date_Parse$(lineText)
            entryTitle = Journal_ParseTitle$(lineText)
            pLevel     = Priority_Parse%(lineText)

            LOCATE printRow, 3
            PRINT "  " + RIGHT$("  " + LTRIM$(STR$(count)), 2) + "  ";
            PRINT LEFT$(entryDate + "          ", 10) + "  ";
            CALL Priority_RenderLabel(pLevel)
            PRINT " ";
            CALL Favorites_RenderBadge(lineText)
            PRINT "  " + LEFT$(entryTitle, UI_COLS - 30)

            printRow = printRow + 1
        END IF
    LOOP

    CALL Window_DrawStatusBar(UI_ROWS - 1, "[JOURNAL BROWSE]  [" + LTRIM$(STR$(count)) + " ENTRIES SHOWN]")
    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB

' ============================================================
' Journal_TodayScreen
' Shows all of today's journal entries inline.
' ============================================================
SUB Journal_TodayScreen
    DIM todayBlock AS STRING
    DIM remaining  AS STRING
    DIM lineText   AS STRING
    DIM nlPos      AS INTEGER
    DIM crow       AS INTEGER
    DIM printRow   AS INTEGER
    DIM count      AS INTEGER
    DIM today      AS STRING
    DIM entryTitle AS STRING
    DIM pLevel     AS INTEGER

    today = Date_GetCurrent$
    crow  = Window_DrawScreen%("TODAY'S JOURNAL", "[JOURNAL MODE]  [" + Date_Format$(today) + "]")

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow, 3 : PRINT "  " + Date_GetWeekday$(today) + " — " + Date_Format$(today)
    COLOR g_ThemeFG, g_ThemeBG
    LOCATE crow + 1, 3 : PRINT ASCII_Repeat$("-", UI_COLS - 6)

    todayBlock = Journal_GetTodayEntries$

    IF todayBlock = "" THEN
        LOCATE crow + 3, 3 : PRINT "No entries for today yet."
        COLOR g_ThemeAccentFG, g_ThemeBG
        LOCATE crow + 4, 3 : PRINT "Use option 1 from the journal menu to start writing."
        COLOR g_ThemeFG, g_ThemeBG
        LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
        SLEEP
        EXIT SUB
    END IF

    printRow  = crow + 3
    count     = 0
    remaining = todayBlock

    DO WHILE LEN(remaining) > 0 AND printRow <= UI_ROWS - 4
        nlPos = INSTR(remaining, CHR$(10))
        IF nlPos = 0 THEN
            lineText  = remaining
            remaining = ""
        ELSE
            lineText  = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF

        IF LEN(LTRIM$(lineText)) > 0 THEN
            count      = count + 1
            entryTitle = Journal_ParseTitle$(lineText)
            pLevel     = Priority_Parse%(lineText)

            LOCATE printRow, 3
            PRINT "  " + LTRIM$(STR$(count)) + ". ";
            CALL Priority_RenderLabel(pLevel)
            PRINT " ";
            CALL Favorites_RenderBadge(lineText)
            PRINT "  " + LEFT$(entryTitle, 30) + " — " + LEFT$(Journal_ParseBody$(lineText), UI_COLS - 44)
            printRow = printRow + 1
        END IF
    LOOP

    CALL Window_DrawStatusBar(UI_ROWS - 1, "[TODAY]  [" + LTRIM$(STR$(count)) + " ENTRIES]  [" + today + "]")
    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB

' ============================================================
' Journal_SearchScreen
' Full journal search — reuses Search_Match% and Search_Score%
' from search_engine.bas. Result block format is identical to
' Search_Query$ so RenderSearchResults renders it unchanged.
' ============================================================
SUB Journal_SearchScreen
    DIM rawQuery    AS STRING
    DIM keywords    AS STRING
    DIM tokenList   AS STRING
    DIM resultBlock AS STRING
    DIM lineCount   AS INTEGER
    DIM crow        AS INTEGER

    crow = Window_DrawScreen%("SEARCH JOURNAL", "[JOURNAL SEARCH MODE]")

    LOCATE crow,     3 : PRINT "Search your journal by keyword, tag, or date:"
    LOCATE crow + 1, 3 : PRINT "  Examples:  reflection   tag:work   2026-05"
    LOCATE crow + 2, 3 : PRINT "  Leave blank and press Enter to cancel."
    LOCATE crow + 4, 3
    LINE INPUT "Search: ", rawQuery

    IF LTRIM$(RTRIM$(rawQuery)) = "" THEN
        LOCATE crow + 6, 3 : PRINT "Search cancelled."
        SLEEP 1
        EXIT SUB
    END IF

    keywords  = Parse_Search_Query$(rawQuery)
    tokenList = Extract_Search_Tokens$(rawQuery)
    IF LEN(LTRIM$(tokenList)) = 0 THEN tokenList = LTRIM$(RTRIM$(rawQuery))

    resultBlock = Journal_SearchEntries$(keywords, tokenList)

    crow = Window_DrawScreen%("JOURNAL RESULTS", "[JOURNAL SEARCH]  [QUERY: " + LEFT$(rawQuery, 25) + "]")

    lineCount = Journal_RenderResults(resultBlock, crow)

    IF lineCount = 0 THEN
        CALL RetroAudio_PlayError
        LOCATE crow, 3 : PRINT "No journal entries matched: "; rawQuery
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[JOURNAL SEARCH]  [0 RESULTS]")
    ELSE
        CALL RetroAudio_PlayNotify
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[JOURNAL SEARCH]  [" + LTRIM$(STR$(lineCount)) + " RESULTS]")
    END IF

    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB

' ============================================================
' Journal_RenderResults%
' Renders journal search result block inside the content area.
' Same format as RenderSearchResults in search_ui.bas.
' Shows date + title + body preview per result.
' Returns count rendered.
' ============================================================
FUNCTION Journal_RenderResults% (resultBlock AS STRING, startRow AS INTEGER)
    DIM remaining  AS STRING
    DIM record     AS STRING
    DIM rawText    AS STRING
    DIM nlPos      AS INTEGER
    DIM displayNum AS INTEGER
    DIM pLevel     AS INTEGER
    DIM printRow   AS INTEGER
    DIM maxRows    AS INTEGER
    DIM entryDate  AS STRING
    DIM entryTitle AS STRING

    displayNum = 0
    remaining  = resultBlock
    printRow   = startRow
    maxRows    = UI_ROWS - 4

    DO WHILE LEN(remaining) > 0
        nlPos = INSTR(remaining, CHR$(10))
        IF nlPos = 0 THEN
            record    = remaining
            remaining = ""
        ELSE
            record    = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF

        IF LEN(LTRIM$(record)) > 0 THEN
            displayNum = displayNum + 1
            rawText    = Extract_Field$(record, 3)
            pLevel     = Priority_Parse%(rawText)
            entryDate  = Date_Parse$(rawText)
            entryTitle = Journal_ParseTitle$(rawText)

            IF printRow <= maxRows THEN
                LOCATE printRow, 3
                PRINT LTRIM$(STR$(displayNum)) + ". ";
                CALL Priority_RenderLabel(pLevel)
                PRINT " ";
                CALL Favorites_RenderBadge(rawText)
                PRINT " [" + entryDate + "] " + LEFT$(entryTitle, 20) + " — " + LEFT$(Journal_ParseBody$(rawText), UI_COLS - 42)
                printRow = printRow + 1
            END IF
        END IF
    LOOP

    Journal_RenderResults = displayNum
END FUNCTION

' ============================================================
' Journal_ExportScreen
' Export journal entries in a chosen format.
' ============================================================
SUB Journal_ExportScreen
    DIM fmt      AS INTEGER
    DIM filename AS STRING
    DIM crow     AS INTEGER

    crow = Window_DrawScreen%("EXPORT JOURNAL", "[JOURNAL EXPORT MODE]")

    LOCATE crow,     3 : PRINT "Export all journal entries."
    LOCATE crow + 2, 3
    fmt      = Export_SelectFormat%
    LOCATE crow + 4, 3 : PRINT "Exporting journal..."
    filename = Journal_ExportAll$(fmt)

    LOCATE crow + 5, 3
    IF LEN(LTRIM$(filename)) > 0 THEN
        CALL RetroAudio_PlayExport
        COLOR g_ThemeAccentFG, g_ThemeBG
        PRINT "  Export complete!  File: " + filename
        COLOR g_ThemeFG, g_ThemeBG
    ELSE
        CALL RetroAudio_PlayError
        PRINT "  No journal entries to export."
    END IF

    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB
