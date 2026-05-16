' file_manager.bas - File operations for Idea Catcher
'$INCLUDEONCE

' ============================================================
' InitializeSystem
' Called after RetroUI_DrawBootScreen to finalize file setup.
' Boot visuals are handled by retro_ui.bas — this SUB only
' handles the file-system side of initialization.
' ============================================================
SUB InitializeSystem
    DIM testFile AS INTEGER

    ' Ensure ideas.txt exists (already done in boot screen
    ' but we guard here for safety on subsequent calls)
    testFile = FREEFILE
    OPEN "ideas.txt" FOR APPEND AS testFile
    CLOSE testFile
END SUB

' Get current timestamp string
FUNCTION GetTimestamp$
    GetTimestamp = "[" + DATE$ + " " + TIME$ + "]"
END FUNCTION

' ============================================================
' WriteIdeaToFile
' Saves a new idea to ideas.txt.
' Format: [timestamp] idea_text | #tags priority:N fav:1
' ============================================================
SUB WriteIdeaToFile (ideaText AS STRING, tags AS STRING, priorityLevel AS INTEGER, favoriteFlag AS INTEGER)
    DIM fileNum     AS INTEGER
    DIM timestamp   AS STRING
    DIM fullEntry   AS STRING
    DIM priorityTag AS STRING
    DIM favTag      AS STRING
    DIM tagSection  AS STRING

    fileNum   = FREEFILE
    timestamp = GetTimestamp$

    priorityTag = Priority_BuildTag$(priorityLevel)
    favTag      = Favorites_BuildTag$(favoriteFlag)
    tagSection  = LTRIM$(RTRIM$(tags))

    IF LEN(priorityTag) > 0 THEN
        IF LEN(tagSection) > 0 THEN
            tagSection = tagSection + " " + priorityTag
        ELSE
            tagSection = priorityTag
        END IF
    END IF

    IF LEN(favTag) > 0 THEN
        IF LEN(tagSection) > 0 THEN
            tagSection = tagSection + " " + favTag
        ELSE
            tagSection = favTag
        END IF
    END IF

    fullEntry = timestamp + " " + ideaText
    IF LEN(tagSection) > 0 THEN
        fullEntry = fullEntry + " | " + tagSection
    END IF

    OPEN "ideas.txt" FOR APPEND AS fileNum
    PRINT #fileNum, fullEntry
    CLOSE fileNum

    ' Confirmation in accent color
    COLOR g_ThemeAccentFG, g_ThemeBG
    PRINT "  Idea saved!";
    COLOR g_ThemeFG, g_ThemeBG
    PRINT "  Priority: [" + Priority_GetLabel$(priorityLevel) + "]";
    IF favoriteFlag = FAV_TRUE THEN PRINT "  [*] Starred" ELSE PRINT
END SUB

' Count non-blank lines in ideas.txt
FUNCTION CountIdeas
    DIM fileNum  AS INTEGER
    DIM lineText AS STRING
    DIM count    AS INTEGER

    count   = 0
    fileNum = FREEFILE

    OPEN "ideas.txt" FOR INPUT AS fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN count = count + 1
    WEND
    CLOSE fileNum

    CountIdeas = count
END FUNCTION

' ============================================================
' ReadAllIdeas
' Lists every idea with priority and favorite badges.
' Caller positions cursor before calling this.
' ============================================================
SUB ReadAllIdeas
    DIM fileNum  AS INTEGER
    DIM lineText AS STRING
    DIM count    AS INTEGER
    DIM pLevel   AS INTEGER

    fileNum = FREEFILE
    count   = 0

    OPEN "ideas.txt" FOR INPUT AS fileNum

    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            count  = count + 1
            pLevel = Priority_Parse%(lineText)
            PRINT "  " + STR$(count) + ". ";
            CALL Priority_RenderLabel(pLevel)
            PRINT " ";
            CALL Favorites_RenderBadge(lineText)
            PRINT " " + LEFT$(Export_ParseIdeaText$(lineText), UI_COLS - 18)
        END IF
    WEND

    CLOSE fileNum

    IF count = 0 THEN
        COLOR g_ThemeAccentFG, g_ThemeBG
        PRINT "  No ideas found. Start writing some!"
        COLOR g_ThemeFG, g_ThemeBG
    END IF
END SUB
