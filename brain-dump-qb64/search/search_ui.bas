' search_ui.bas - Search Everything UI screen
' Part of Brain Dump QB64 - Search Everything System
' Responsibility: ALL screen rendering for the search feature.
'                 Uses window_renderer for screen chrome.
'$INCLUDEONCE

' ============================================================
' SearchEverything
' Main entry point called from main.bas menu option 5.
' ============================================================
SUB SearchEverything
    DIM rawQuery       AS STRING
    DIM keywords       AS STRING
    DIM tokenList      AS STRING
    DIM tagFilter      AS STRING
    DIM favFilter      AS STRING
    DIM priorityFilter AS STRING
    DIM resultBlock    AS STRING
    DIM lineCount      AS INTEGER
    DIM crow           AS INTEGER

    crow = Window_DrawScreen%("SEARCH EVERYTHING", "[SEARCH MODE]")

    LOCATE crow,     3 : PRINT "Search by keyword, tag, or operators:"
    LOCATE crow + 1, 3 : PRINT "  tag:game    priority:high    fav:true    starred:true"
    LOCATE crow + 2, 3 : PRINT "  Leave blank and press Enter to cancel."
    LOCATE crow + 4, 3
    LINE INPUT "Search: ", rawQuery

    IF LTRIM$(RTRIM$(rawQuery)) = "" THEN
        LOCATE crow + 6, 3 : PRINT "Search cancelled."
        SLEEP 1
        EXIT SUB
    END IF

    ' Parse
    keywords  = Parse_Search_Query$(rawQuery)
    tokenList = Extract_Search_Tokens$(rawQuery)
    IF LEN(LTRIM$(tokenList)) = 0 THEN tokenList = LTRIM$(RTRIM$(rawQuery))

    ' Execute
    resultBlock = Search_Query$(keywords, tokenList)

    ' Filters
    tagFilter      = Extract_Search_Filters$(rawQuery, "tag")
    priorityFilter = Extract_Search_Filters$(rawQuery, "priority")
    favFilter      = Extract_Search_Filters$(rawQuery, "fav")
    IF favFilter = "" THEN favFilter = Extract_Search_Filters$(rawQuery, "favorite")
    IF favFilter = "" THEN favFilter = Extract_Search_Filters$(rawQuery, "starred")

    IF LEN(tagFilter) > 0 THEN
        DIM tagOut   AS STRING
        DIM tagCount AS INTEGER
        tagCount    = Filter_By_Tag%(resultBlock, tagFilter, tagOut)
        resultBlock = tagOut
    END IF

    IF LEN(priorityFilter) > 0 THEN
        DIM priOut   AS STRING
        DIM priCount AS INTEGER
        priCount    = Filter_By_Priority%(resultBlock, priorityFilter, priOut)
        resultBlock = priOut
    END IF

    IF LCASE$(favFilter) = "true" THEN
        DIM favOut   AS STRING
        DIM favCount AS INTEGER
        favCount    = Filter_Favorites%(resultBlock, favOut)
        resultBlock = favOut
    END IF

    ' Results screen
    crow = Window_DrawScreen%("SEARCH RESULTS", "[SEARCH MODE]  [QUERY: " + LEFT$(rawQuery, 30) + "]")

    lineCount = RenderSearchResults(resultBlock, crow)

    IF lineCount = 0 THEN
        CALL RetroAudio_PlayError
        LOCATE crow, 3 : PRINT "No matches found for: "; rawQuery
        LOCATE crow + 2, 3 : PRINT "Tips: fewer keywords, check tag: spelling, use priority: / fav:true"
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[SEARCH]  [0 RESULTS]")
        LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return to menu..."
        SLEEP
    ELSE
        CALL RetroAudio_PlayNotify
        CALL Window_DrawStatusBar(UI_ROWS - 1, "[SEARCH]  [" + LTRIM$(STR$(lineCount)) + " RESULTS]  [QUERY: " + LEFT$(rawQuery, 25) + "]")
        CALL ExportSearchResultsScreen(resultBlock)
        LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return to menu..."
        SLEEP
    END IF
END SUB

' ============================================================
' RenderSearchResults%
' Renders result records inside the content area.
' startRow = first content row returned by Window_DrawScreen%.
' Returns total count rendered.
' ============================================================
FUNCTION RenderSearchResults% (resultBlock AS STRING, startRow AS INTEGER)
    DIM remaining  AS STRING
    DIM record     AS STRING
    DIM rawText    AS STRING
    DIM nlPos      AS INTEGER
    DIM displayNum AS INTEGER
    DIM pLevel     AS INTEGER
    DIM printRow   AS INTEGER
    DIM maxRows    AS INTEGER

    displayNum = 0
    remaining  = resultBlock
    printRow   = startRow
    maxRows    = UI_ROWS - 4    ' leave room for status + prompt

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

            rawText = Extract_Field$(record, 3)
            pLevel  = Priority_Parse%(rawText)

            IF printRow <= maxRows THEN
                LOCATE printRow, 3
                PRINT STR$(displayNum) + ". ";
                CALL Priority_RenderLabel(pLevel)
                PRINT " ";
                CALL Favorites_RenderBadge(rawText)
                PRINT " " + LEFT$(Export_ParseIdeaText$(rawText), UI_COLS - 16)
                printRow = printRow + 1
            END IF
        END IF
    LOOP

    RenderSearchResults = displayNum
END FUNCTION
