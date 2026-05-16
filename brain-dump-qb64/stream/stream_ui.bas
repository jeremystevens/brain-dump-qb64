' stream_ui.bas - Thought Stream Mode UI screens
' Part of Brain Dump QB64 - Thought Stream Mode (Phase 3)
' Responsibility: ALL screen rendering for the stream system.
'                 Calls stream_input for data operations.
'                 The capture loop is the core UX — chrome drawn
'                 ONCE, then entries scroll live inside the frame.
'                 NO storage logic. NO business logic.
'$INCLUDEONCE

' ============================================================
' ThoughtStreamScreen
' Main stream hub — called from main menu option 8.
' ============================================================
SUB ThoughtStreamScreen
    DIM choice      AS STRING
    DIM crow        AS INTEGER
    DIM totalThoughts AS INTEGER
    DIM totalSessions AS INTEGER

    totalThoughts = Stream_CountTotal%
    totalSessions = Stream_CountSessions%

    crow = Window_DrawScreen%("THOUGHT STREAM", "[STREAM MODE]  [" + LTRIM$(STR$(totalThoughts)) + " THOUGHTS]  [" + LTRIM$(STR$(totalSessions)) + " SESSIONS]")

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow, 3 : PRINT "  Rapid thought capture — type and press Enter to save each thought."
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE crow + 2, 3 : PRINT "  1.  Start new stream session"
    LOCATE crow + 3, 3 : PRINT "  2.  Browse recent thoughts"
    LOCATE crow + 4, 3 : PRINT "  3.  Search thoughts"
    LOCATE crow + 5, 3 : PRINT "  4.  Export stream"
    LOCATE crow + 6, 3 : PRINT "  5.  Return to main menu"

    LOCATE crow + 8, 3
    INPUT "  Choose (1-5): ", choice

    SELECT CASE LTRIM$(RTRIM$(choice))
        CASE "1" : CALL RetroAudio_PlayMenuMove : CALL Stream_CaptureScreen
        CASE "2" : CALL RetroAudio_PlayMenuMove : CALL Stream_BrowseScreen
        CASE "3" : CALL RetroAudio_PlayMenuMove : CALL Stream_SearchScreen
        CASE "4" : CALL RetroAudio_PlayMenuMove : CALL Stream_ExportScreen
        CASE "5" : EXIT SUB
        CASE ELSE
            CALL RetroAudio_PlayError
            LOCATE crow + 10, 3 : PRINT "  Invalid. Press any key..."
            SLEEP
    END SELECT
END SUB

' ============================================================
' Stream_CaptureScreen
' THE core experience — immersive fullscreen thought capture.
'
' Design principles:
'   - Screen chrome drawn ONCE at session start
'   - Each thought is saved the moment Enter is pressed
'   - Confirmation line printed inline (no CLS)
'   - Thoughts scroll live inside the content frame
'   - Commands start with / — shown in accent color
'   - /done or /exit ends the session
'   - /help shows inline command reference
'   - /clear redraws the frame (doesn't delete entries)
' ============================================================
SUB Stream_CaptureScreen
    DIM sessionID  AS INTEGER
    DIM thought    AS STRING
    DIM timestamp  AS STRING
    DIM printRow   AS INTEGER
    DIM entryCount AS INTEGER
    DIM maxRow     AS INTEGER
    DIM startTime  AS STRING

    sessionID  = Stream_StartSession%
    startTime  = Date_GetTimestamp$
    entryCount = 0
    maxRow     = UI_ROWS - 4   ' leave room for input prompt + status

    ' Draw chrome ONCE — content area becomes the live stream
    CALL Stream_DrawCaptureChrome(sessionID, startTime)
    printRow = 7   ' first available content row inside the frame

    ' Show command hint
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE printRow, 3
    PRINT "  Commands: /done  /clear  /help"
    COLOR g_ThemeFG, g_ThemeBG
    printRow = printRow + 1

    LOCATE printRow, 3
    PRINT ASCII_Repeat$("-", UI_COLS - 6)
    printRow = printRow + 1

    ' ---- Main capture loop --------------------------------
    DO
        ' Input prompt at the fixed bottom prompt row
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[SESSION " + LTRIM$(STR$(sessionID)) + "]  [" + LTRIM$(STR$(entryCount)) + " THOUGHTS]  [/done to end]")

        LOCATE UI_ROWS - 2, 3
        PRINT SPACE$(UI_COLS - 4);   ' clear previous prompt line
        LOCATE UI_ROWS - 2, 3

        COLOR g_ThemeAccentFG, g_ThemeBG
        PRINT ">> ";
        COLOR g_ThemeFG, g_ThemeBG
        LINE INPUT "", thought

        thought = LTRIM$(RTRIM$(thought))
        IF thought = "" THEN GoTo StreamContinue

        ' ---- Command handling ----
        IF LEFT$(thought, 1) = "/" THEN
            SELECT CASE LCASE$(thought)
                CASE "/done", "/exit", "/end"
                    GoTo StreamDone

                CASE "/clear"
                    CALL Stream_DrawCaptureChrome(sessionID, startTime)
                    printRow   = 7
                    entryCount = 0   ' visual reset only — file unchanged
                    COLOR g_ThemeAccentFG, g_ThemeBG
                    LOCATE printRow, 3 : PRINT "  [display cleared — all thoughts saved]"
                    COLOR g_ThemeFG, g_ThemeBG
                    printRow = printRow + 1

                CASE "/help"
                    IF printRow <= maxRow THEN
                        COLOR g_ThemeAccentFG, g_ThemeBG
                        LOCATE printRow, 3
                        PRINT "  /done = end session  /clear = reset display  /help = this"
                        COLOR g_ThemeFG, g_ThemeBG
                        printRow = printRow + 1
                    END IF

                CASE ELSE
                    IF printRow <= maxRow THEN
                        COLOR g_ThemeAccentFG, g_ThemeBG
                        LOCATE printRow, 3 : PRINT "  Unknown command. Try /done /clear /help"
                        COLOR g_ThemeFG, g_ThemeBG
                        printRow = printRow + 1
                    END IF
            END SELECT
            GoTo StreamContinue
        END IF

        ' ---- Save the thought immediately ----
        timestamp  = Stream_AddEntry$(thought)
        entryCount = entryCount + 1
        CALL Sound_Play(SND_STREAM_ENTRY)

        ' Print confirmation line in the live stream area
        IF printRow > maxRow THEN
            ' Content area full — scroll by redrawing chrome
            CALL Stream_DrawCaptureChrome(sessionID, startTime)
            printRow = 7
        END IF

        LOCATE printRow, 3
        COLOR g_ThemeAccentFG, g_ThemeBG
        PRINT LTRIM$(STR$(entryCount)) + ". ";
        COLOR g_ThemeFG, g_ThemeBG
        PRINT LEFT$(thought, UI_COLS - 8)
        printRow = printRow + 1

StreamContinue:
    LOOP

StreamDone:
    CALL Stream_EndSession
    CALL RetroAudio_PlayConfirm

    ' Summary screen
    DIM crow AS INTEGER
    crow = Window_DrawScreen%("SESSION COMPLETE", "[STREAM MODE]  [SESSION " + LTRIM$(STR$(sessionID)) + " SAVED]")

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow,     3 : PRINT "  Stream session " + LTRIM$(STR$(sessionID)) + " complete."
    COLOR g_ThemeFG, g_ThemeBG
    LOCATE crow + 1, 3 : PRINT "  Thoughts captured this session: " + LTRIM$(STR$(entryCount))
    LOCATE crow + 2, 3 : PRINT "  All thoughts saved to " + STREAM_FILE
    LOCATE crow + 4, 3 : PRINT "  Thoughts are searchable from Search Everything."
    LOCATE crow + 6, 3 : PRINT "  Press any key to return..."
    SLEEP
END SUB

' ============================================================
' Stream_DrawCaptureChrome
' Draws the fullscreen capture frame — called once at start
' and again on /clear. Keeps the stream feel immersive.
' ============================================================
SUB Stream_DrawCaptureChrome (sessionID AS INTEGER, startTime AS STRING)
    DIM r AS INTEGER

    COLOR g_ThemeFG, g_ThemeBG
    CLS

    ' App bar row 1
    CALL Window_DrawAppBar(1)

    ' Title row 2-4 — compact, no full Window_DrawScreen overhead
    LOCATE 2, 1 : PRINT ASCII_BoxTop$(UI_COLS, Window_ActiveBorder%);
    LOCATE 3, 1
    COLOR g_ThemeAccentFG, g_ThemeBG
    PRINT ASCII_BoxSide$(ASCII_CenterText$("THOUGHT STREAM // SESSION " + LTRIM$(STR$(sessionID)), UI_COLS - 2), UI_COLS, Window_ActiveBorder%);
    COLOR g_ThemeFG, g_ThemeBG
    LOCATE 4, 1 : PRINT ASCII_BoxBottom$(UI_COLS, Window_ActiveBorder%);

    ' Content frame rows 5 to UI_ROWS-2
    LOCATE 5, 1 : PRINT ASCII_BoxTop$(UI_COLS, Window_ActiveBorder%);
    FOR r = 6 TO UI_ROWS - 3
        LOCATE r, 1 : PRINT ASCII_BoxSide$(STRING$(UI_COLS - 2, " "), UI_COLS, Window_ActiveBorder%);
    NEXT r
    LOCATE UI_ROWS - 2, 1 : PRINT ASCII_BoxBottom$(UI_COLS, Window_ActiveBorder%);
END SUB

' ============================================================
' Stream_BrowseScreen
' Shows the most recent stream entries with timestamps.
' ============================================================
SUB Stream_BrowseScreen
    DIM recentBlock AS STRING
    DIM remaining   AS STRING
    DIM lineText    AS STRING
    DIM nlPos       AS INTEGER
    DIM crow        AS INTEGER
    DIM printRow    AS INTEGER
    DIM count       AS INTEGER
    DIM maxRows     AS INTEGER
    DIM entryDate   AS STRING
    DIM thought     AS STRING
    DIM sid         AS INTEGER

    crow    = Window_DrawScreen%("RECENT THOUGHTS", "[STREAM MODE]  [BROWSE]")
    maxRows = UI_ROWS - 5

    recentBlock = Stream_GetRecentEntries$(15)

    IF recentBlock = "" THEN
        LOCATE crow, 3 : PRINT "No stream entries yet. Start a session!"
        LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
        SLEEP
        EXIT SUB
    END IF

    ' Column header
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow, 3
    PRINT ASCII_PadRight$("  #  S#  DATE        THOUGHT", UI_COLS - 4);
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
            count     = count + 1
            entryDate = Date_Parse$(lineText)
            sid       = Stream_ParseSessionID%(lineText)
            thought   = Stream_ParseThought$(lineText)

            LOCATE printRow, 3
            PRINT "  " + RIGHT$("  " + LTRIM$(STR$(count)), 2) + "  ";
            COLOR g_ThemeAccentFG, g_ThemeBG
            PRINT RIGHT$(" " + LTRIM$(STR$(sid)), 2);
            COLOR g_ThemeFG, g_ThemeBG
            PRINT "  " + LEFT$(entryDate + "          ", 10) + "  ";
            PRINT LEFT$(thought, UI_COLS - 26)

            printRow = printRow + 1
        END IF
    LOOP

    CALL Window_DrawStatusBar(UI_ROWS - 1, "[STREAM BROWSE]  [" + LTRIM$(STR$(count)) + " SHOWN]  [" + LTRIM$(STR$(Stream_CountSessions%)) + " SESSIONS TOTAL]")
    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB

' ============================================================
' Stream_SearchScreen
' Searches stream.txt for matching thoughts.
' Reuses Search_Match% and Search_Score% from search_engine.
' Result block format identical to Search_Query$ so
' RenderSearchResults renders it without modification.
' ============================================================
SUB Stream_SearchScreen
    DIM rawQuery    AS STRING
    DIM keywords    AS STRING
    DIM tokenList   AS STRING
    DIM resultBlock AS STRING
    DIM lineCount   AS INTEGER
    DIM crow        AS INTEGER

    crow = Window_DrawScreen%("SEARCH THOUGHTS", "[STREAM SEARCH MODE]")

    LOCATE crow,     3 : PRINT "Search your thought stream by keyword or date:"
    LOCATE crow + 1, 3 : PRINT "  Examples:  project idea   2026-05   app design"
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

    resultBlock = Stream_SearchEntries$(keywords, tokenList)

    crow = Window_DrawScreen%("STREAM RESULTS", "[STREAM SEARCH]  [QUERY: " + LEFT$(rawQuery, 25) + "]")

    lineCount = Stream_RenderResults(resultBlock, crow)

    IF lineCount = 0 THEN
        CALL RetroAudio_PlayError
        LOCATE crow, 3 : PRINT "No thoughts matched: "; rawQuery
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[STREAM SEARCH]  [0 RESULTS]")
    ELSE
        CALL RetroAudio_PlayNotify
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[STREAM SEARCH]  [" + LTRIM$(STR$(lineCount)) + " RESULTS]")
    END IF

    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB

' ============================================================
' Stream_RenderResults%
' Renders stream search result block.
' Shows session number, date, and thought preview per result.
' ============================================================
FUNCTION Stream_RenderResults% (resultBlock AS STRING, startRow AS INTEGER)
    DIM remaining  AS STRING
    DIM record     AS STRING
    DIM rawText    AS STRING
    DIM nlPos      AS INTEGER
    DIM displayNum AS INTEGER
    DIM printRow   AS INTEGER
    DIM maxRows    AS INTEGER
    DIM entryDate  AS STRING
    DIM thought    AS STRING
    DIM sid        AS INTEGER

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
            entryDate  = Date_Parse$(rawText)
            sid        = Stream_ParseSessionID%(rawText)
            thought    = Stream_ParseThought$(rawText)

            IF printRow <= maxRows THEN
                LOCATE printRow, 3
                PRINT LTRIM$(STR$(displayNum)) + ". ";
                COLOR g_ThemeAccentFG, g_ThemeBG
                PRINT "[S:" + LTRIM$(STR$(sid)) + "]";
                COLOR g_ThemeFG, g_ThemeBG
                PRINT " [" + entryDate + "] " + LEFT$(thought, UI_COLS - 30)
                printRow = printRow + 1
            END IF
        END IF
    LOOP

    Stream_RenderResults = displayNum
END FUNCTION

' ============================================================
' Stream_ExportScreen
' Export stream entries — all sessions or a specific one.
' ============================================================
SUB Stream_ExportScreen
    DIM choice    AS STRING
    DIM fmt       AS INTEGER
    DIM filename  AS STRING
    DIM sessionID AS INTEGER
    DIM crow      AS INTEGER
    DIM totalSess AS INTEGER

    totalSess = Stream_CountSessions%

    crow = Window_DrawScreen%("EXPORT STREAM", "[STREAM EXPORT MODE]")

    LOCATE crow,     3 : PRINT "  What would you like to export?"
    LOCATE crow + 2, 3 : PRINT "  1.  All sessions (complete stream)"
    LOCATE crow + 3, 3 : PRINT "  2.  Current / latest session (#" + LTRIM$(STR$(totalSess)) + ")"
    LOCATE crow + 4, 3 : PRINT "  3.  Cancel"
    LOCATE crow + 6, 3
    INPUT "Choose (1-3): ", choice

    SELECT CASE LTRIM$(RTRIM$(choice))
        CASE "1"
            LOCATE crow + 8, 3
            fmt      = Export_SelectFormat%
            LOCATE crow + 10, 3 : PRINT "  Exporting all stream entries..."
            filename = Stream_ExportSession$(0, fmt)   ' 0 = all sessions
            LOCATE crow + 11, 3
            IF LEN(LTRIM$(filename)) > 0 THEN
                CALL RetroAudio_PlayExport
                COLOR g_ThemeAccentFG, g_ThemeBG
                PRINT "  Export complete!  File: " + filename
                COLOR g_ThemeFG, g_ThemeBG
            ELSE
                CALL RetroAudio_PlayError
                PRINT "  No stream entries found."
            END IF

        CASE "2"
            IF totalSess = 0 THEN
                LOCATE crow + 8, 3 : PRINT "  No sessions recorded yet."
            ELSE
                LOCATE crow + 8, 3
                fmt      = Export_SelectFormat%
                LOCATE crow + 10, 3 : PRINT "  Exporting session " + LTRIM$(STR$(totalSess)) + "..."
                filename = Stream_ExportSession$(totalSess, fmt)
                LOCATE crow + 11, 3
                IF LEN(LTRIM$(filename)) > 0 THEN
                    CALL RetroAudio_PlayExport
                    COLOR g_ThemeAccentFG, g_ThemeBG
                    PRINT "  Export complete!  File: " + filename
                    COLOR g_ThemeFG, g_ThemeBG
                ELSE
                    CALL RetroAudio_PlayError
                    PRINT "  No entries found for session " + LTRIM$(STR$(totalSess)) + "."
                END IF
            END IF

        CASE ELSE
            LOCATE crow + 8, 3 : PRINT "  Export cancelled."
            SLEEP 1
            EXIT SUB
    END SELECT

    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return..."
    SLEEP
END SUB
