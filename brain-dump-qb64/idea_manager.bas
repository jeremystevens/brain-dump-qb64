' idea_manager.bas - Core idea management functions
'$INCLUDEONCE

' ============================================================
' WriteNewIdea
' Full-screen form for capturing a new idea.
' ============================================================
SUB WriteNewIdea
    DIM ideaText      AS STRING
    DIM tags          AS STRING
    DIM priorityLevel AS INTEGER
    DIM favoriteFlag  AS INTEGER
    DIM crow          AS INTEGER    ' current content row

    crow = Window_DrawScreen%("WRITE NEW IDEA", "[NEW IDEA MODE]")

    LOCATE crow,     3 : PRINT "Enter your idea (press Enter when done):"
    LOCATE crow + 1, 3
    LINE INPUT "", ideaText

    IF LTRIM$(ideaText) = "" THEN
        CALL RetroAudio_PlayError
        LOCATE crow + 3, 3 : PRINT "No idea entered. Returning to menu..."
        SLEEP 2
        EXIT SUB
    END IF

    LOCATE crow + 3, 3 : PRINT "Add tags (optional, like #project #dream #reminder):"
    LOCATE crow + 4, 3
    LINE INPUT "", tags

    PRINT
    priorityLevel = Priority_SelectLevel%

    PRINT
    favoriteFlag = Favorites_SelectState%

    CALL WriteIdeaToFile(ideaText, tags, priorityLevel, favoriteFlag)
    CALL RetroAudio_PlayConfirm

    LOCATE crow + 10, 3 : PRINT "Press any key to continue..."
    SLEEP
END SUB

' ============================================================
' ReviewIdeas
' Lists all ideas inside the content area frame.
' ============================================================
SUB ReviewIdeas
    DIM totalIdeas AS INTEGER
    DIM crow       AS INTEGER

    totalIdeas = CountIdeas

    crow = Window_DrawScreen%("REVIEW IDEAS", "[REVIEW MODE]  [" + LTRIM$(STR$(totalIdeas)) + " IDEAS]")

    LOCATE crow, 3
    PRINT "Total ideas: "; totalIdeas
    LOCATE crow + 1, 3
    PRINT ASCII_Repeat$("-", UI_COLS - 6)

    ' ReadAllIdeas prints from current cursor position downward
    LOCATE crow + 2, 1
    CALL ReadAllIdeas

    LOCATE UI_ROWS - 2, 3
    PRINT "Press any key to return to menu..."
    SLEEP
END SUB

' ============================================================
' SearchByTag
' Searches ideas by a hashtag using the ASCII window layout.
' ============================================================
SUB SearchByTag
    DIM searchTag AS STRING
    DIM fileNum   AS INTEGER
    DIM lineText  AS STRING
    DIM count     AS INTEGER
    DIM found     AS INTEGER
    DIM pLevel    AS INTEGER
    DIM crow      AS INTEGER

    crow = Window_DrawScreen%("SEARCH BY TAG", "[TAG SEARCH MODE]")

    LOCATE crow, 3
    INPUT "Enter tag to search for (without #): ", searchTag

    IF searchTag = "" THEN
        LOCATE crow + 2, 3 : PRINT "No tag entered. Returning to menu..."
        SLEEP 2
        EXIT SUB
    END IF

    IF LEFT$(searchTag, 1) <> "#" THEN
        searchTag = "#" + searchTag
    END IF

    LOCATE crow + 1, 3 : PRINT "Searching for: "; searchTag
    LOCATE crow + 2, 3 : PRINT ASCII_Repeat$("-", UI_COLS - 6)

    fileNum = FREEFILE
    count   = 0
    found   = 0

    OPEN "ideas.txt" FOR INPUT AS fileNum

    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            count = count + 1
            IF INSTR(UCASE$(lineText), UCASE$(searchTag)) > 0 THEN
                found  = found + 1
                pLevel = Priority_Parse%(lineText)
                ' Print inside content area — clamp to available rows
                IF crow + 3 + found < UI_ROWS - 3 THEN
                    LOCATE crow + 3 + found - 1, 3
                    PRINT STR$(found) + ". ";
                    CALL Priority_RenderLabel(pLevel)
                    PRINT " ";
                    CALL Favorites_RenderBadge(lineText)
                    PRINT " " + LEFT$(Export_ParseIdeaText$(lineText), UI_COLS - 14)
                END IF
            END IF
        END IF
    WEND

    CLOSE fileNum

    IF found = 0 THEN
        LOCATE crow + 3, 3 : PRINT "No ideas found with tag: "; searchTag
    END IF

    ' Update status bar with result count
    CALL Window_DrawStatusBar(UI_ROWS - 1, "[TAG SEARCH]  [" + LTRIM$(STR$(found)) + " MATCHES FOR " + searchTag + "]")

    LOCATE UI_ROWS - 2, 3
    PRINT "Press any key to return to menu..."
    SLEEP
END SUB

' ============================================================
' DeleteIdea — placeholder
' ============================================================
SUB DeleteIdea
    DIM crow AS INTEGER
    crow = Window_DrawScreen%("DELETE IDEA", "[DELETE MODE]")

    LOCATE crow,     3 : PRINT "Delete functionality coming soon!"
    LOCATE crow + 1, 3 : PRINT "For now, you can manually edit 'ideas.txt'."
    LOCATE crow + 3, 3 : PRINT "Press any key to return to menu..."
    SLEEP
END SUB
