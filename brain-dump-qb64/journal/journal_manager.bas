' journal_manager.bas - Journal entry management and file I/O
' Part of Brain Dump QB64 - Daily Journal Mode (Phase 3)
' Responsibility: All journal data operations — save, load,
'                 count, search, delete. Centralized journal
'                 management. NO rendering. NO UI logic.
' File: journal.txt — one entry per line, format:
'   [YYYY-MM-DD HH:MM:SS] [TITLE] body text | #tags priority:N fav:1
' NOTE: JournalEntry TYPE and JOURNAL_* constants in main.bas.
'$INCLUDEONCE

' NOTE: JOURNAL_FILE constant declared in main.bas per QB64 rules.
'       JournalEntry TYPE also declared in main.bas.

' ============================================================
' Journal_Init
' Called once at startup. Creates journal.txt if missing.
' ============================================================
SUB Journal_Init
    DIM fileNum AS INTEGER
    fileNum = FREEFILE
    OPEN JOURNAL_FILE FOR APPEND AS #fileNum
    CLOSE #fileNum
END SUB

' ============================================================
' Journal_CountEntries%
' Returns the total number of non-blank lines in journal.txt.
' ============================================================
FUNCTION Journal_CountEntries%
    DIM fileNum  AS INTEGER
    DIM lineText AS STRING
    DIM count    AS INTEGER

    count   = 0
    fileNum = FREEFILE

    OPEN JOURNAL_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN count = count + 1
    WEND
    CLOSE #fileNum

    Journal_CountEntries = count
END FUNCTION

' ============================================================
' Journal_SaveEntry
' Appends one journal entry to journal.txt.
' Parameters are the raw field values — formatting done here.
' File format: [YYYY-MM-DD HH:MM:SS] [title] body | #tags priority:N fav:1
' ============================================================
SUB Journal_SaveEntry (title AS STRING, body AS STRING, tags AS STRING, priorityLevel AS INTEGER, favoriteFlag AS INTEGER)
    DIM fileNum     AS INTEGER
    DIM timestamp   AS STRING
    DIM fullEntry   AS STRING
    DIM tagSection  AS STRING
    DIM priorityTag AS STRING
    DIM favTag      AS STRING
    DIM titlePart   AS STRING

    fileNum   = FREEFILE
    timestamp = Date_GetTimestamp$

    ' Bracket the title so it's parseable separately from body
    titlePart = "[" + LTRIM$(RTRIM$(title)) + "]"

    ' Build tag section (same pattern as ideas.txt)
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

    ' Full line: [timestamp] [title] body | tags
    fullEntry = timestamp + " " + titlePart + " " + LTRIM$(RTRIM$(body))
    IF LEN(tagSection) > 0 THEN
        fullEntry = fullEntry + " | " + tagSection
    END IF

    OPEN JOURNAL_FILE FOR APPEND AS #fileNum
    PRINT #fileNum, fullEntry
    CLOSE #fileNum
END SUB

' ============================================================
' Journal_ParseTitle$
' Extracts the [title] portion from a raw journal line.
' Format after timestamp: [TITLE] body text
' Returns the title without brackets, or "" if not found.
' ============================================================
FUNCTION Journal_ParseTitle$ (rawLine AS STRING)
    DIM afterTs   AS STRING
    DIM endTs     AS INTEGER
    DIM titleStart AS INTEGER
    DIM titleEnd  AS INTEGER

    ' Skip past the timestamp bracket
    endTs = INSTR(rawLine, "]")
    IF endTs = 0 THEN
        Journal_ParseTitle = ""
        EXIT FUNCTION
    END IF

    afterTs    = LTRIM$(MID$(rawLine, endTs + 1))
    titleStart = INSTR(afterTs, "[")
    titleEnd   = INSTR(afterTs, "]")

    IF titleStart = 0 OR titleEnd <= titleStart THEN
        Journal_ParseTitle = ""
        EXIT FUNCTION
    END IF

    Journal_ParseTitle = MID$(afterTs, titleStart + 1, titleEnd - titleStart - 1)
END FUNCTION

' ============================================================
' Journal_ParseBody$
' Extracts the body text from a raw journal line.
' Format: [timestamp] [title] body text | tags
' Returns everything between title-bracket and the | separator.
' ============================================================
FUNCTION Journal_ParseBody$ (rawLine AS STRING)
    DIM afterTs    AS STRING
    DIM endTs      AS INTEGER
    DIM titleEnd   AS INTEGER
    DIM pipePos    AS INTEGER
    DIM body       AS STRING

    endTs = INSTR(rawLine, "]")
    IF endTs = 0 THEN
        Journal_ParseBody = LTRIM$(RTRIM$(rawLine))
        EXIT FUNCTION
    END IF

    afterTs = LTRIM$(MID$(rawLine, endTs + 1))

    ' Skip past the title bracket
    titleEnd = INSTR(afterTs, "]")
    IF titleEnd > 0 THEN
        afterTs = LTRIM$(MID$(afterTs, titleEnd + 1))
    END IF

    pipePos = INSTR(afterTs, " | ")
    IF pipePos > 0 THEN
        body = LTRIM$(RTRIM$(LEFT$(afterTs, pipePos - 1)))
    ELSE
        body = LTRIM$(RTRIM$(afterTs))
    END IF

    Journal_ParseBody = body
END FUNCTION

' ============================================================
' Journal_GetTodayEntries$
' Returns all journal lines from today as a CHR$(10)-delimited
' string. Uses Date_GetCurrent$ for today's YYYY-MM-DD.
' ============================================================
FUNCTION Journal_GetTodayEntries$
    DIM fileNum  AS INTEGER
    DIM lineText AS STRING
    DIM today    AS STRING
    DIM entryDate AS STRING
    DIM result   AS STRING

    today   = Date_GetCurrent$
    result  = ""
    fileNum = FREEFILE

    OPEN JOURNAL_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            entryDate = Date_Parse$(lineText)
            IF entryDate = today THEN
                IF result = "" THEN
                    result = lineText
                ELSE
                    result = result + CHR$(10) + lineText
                END IF
            END IF
        END IF
    WEND
    CLOSE #fileNum

    Journal_GetTodayEntries = result
END FUNCTION

' ============================================================
' Journal_GetRecentEntries$
' Returns the most recent <maxCount> journal lines as a
' CHR$(10)-delimited string, in reverse order (newest first).
' Reads all entries into a temp block then reverses.
' ============================================================
FUNCTION Journal_GetRecentEntries$ (maxCount AS INTEGER)
    DIM fileNum   AS INTEGER
    DIM lineText  AS STRING
    DIM allLines  AS STRING
    DIM result    AS STRING
    DIM remaining AS STRING
    DIM lineStr   AS STRING
    DIM nlPos     AS INTEGER
    DIM count     AS INTEGER

    ' Collect all non-blank lines
    allLines = ""
    fileNum  = FREEFILE

    OPEN JOURNAL_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            IF allLines = "" THEN
                allLines = lineText
            ELSE
                allLines = allLines + CHR$(10) + lineText
            END IF
        END IF
    WEND
    CLOSE #fileNum

    IF allLines = "" THEN
        Journal_GetRecentEntries = ""
        EXIT FUNCTION
    END IF

    ' Walk backwards through the lines to get most recent first
    result    = ""
    count     = 0
    remaining = allLines

    ' Build reversed list by prepending each line
    DIM lines(500) AS STRING
    DIM lineCount  AS INTEGER
    lineCount = 0
    remaining = allLines

    DO WHILE LEN(remaining) > 0 AND lineCount < 500
        nlPos = INSTR(remaining, CHR$(10))
        IF nlPos = 0 THEN
            lineStr   = remaining
            remaining = ""
        ELSE
            lineStr   = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF
        IF LEN(LTRIM$(lineStr)) > 0 THEN
            lineCount          = lineCount + 1
            lines(lineCount)   = lineStr
        END IF
    LOOP

    ' Output in reverse order up to maxCount
    DIM i AS INTEGER
    FOR i = lineCount TO 1 STEP -1
        IF count < maxCount THEN
            count = count + 1
            IF result = "" THEN
                result = lines(i)
            ELSE
                result = result + CHR$(10) + lines(i)
            END IF
        END IF
    NEXT i

    Journal_GetRecentEntries = result
END FUNCTION

' ============================================================
' Journal_SearchEntries$
' Searches journal.txt for lines matching tokenList.
' Returns a result block in the same format as Search_Query$:
'   lineNumber|score|rawJournalLine  (CHR$(10)-delimited)
' This means RenderSearchResults in search_ui.bas works
' directly on journal results with no modification.
' ============================================================
FUNCTION Journal_SearchEntries$ (rawQuery AS STRING, tokenList AS STRING)
    DIM fileNum    AS INTEGER
    DIM lineText   AS STRING
    DIM lineNum    AS INTEGER
    DIM matchScore AS INTEGER
    DIM result     AS STRING
    DIM entry      AS STRING

    result  = ""
    lineNum = 0

    fileNum = FREEFILE
    OPEN JOURNAL_FILE FOR INPUT AS #fileNum

    DO WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            lineNum = lineNum + 1
            IF Search_Match%(lineText, tokenList) THEN
                matchScore = Search_Score%(lineText, tokenList, rawQuery)
                entry = LTRIM$(STR$(lineNum)) + "|" + _
                        LTRIM$(STR$(matchScore)) + "|" + _
                        lineText
                IF result = "" THEN
                    result = entry
                ELSE
                    result = result + CHR$(10) + entry
                END IF
            END IF
        END IF
    LOOP

    CLOSE #fileNum
    Journal_SearchEntries = result
END FUNCTION

' ============================================================
' Journal_ExportAll$
' Exports all journal entries in the given format.
' Reuses Export_WriteIdea from export_manager.bas.
' The journal line format is compatible with the idea
' export parser (same timestamp + pipe-tag structure).
' Returns the output filename, or "" if nothing to export.
' ============================================================
FUNCTION Journal_ExportAll$ (fmt AS INTEGER)
    DIM filename  AS STRING
    DIM fileNum   AS INTEGER
    DIM srcNum    AS INTEGER
    DIM lineText  AS STRING
    DIM entryCount AS INTEGER
    DIM ext       AS STRING

    ext      = Export_ExtForFormat$(fmt)
    filename = Export_GenerateFilename$("journal_export", ext)

    fileNum = FREEFILE
    OPEN filename FOR OUTPUT AS #fileNum

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteHeader(fileNum,  "Journal Export")
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteHeader(fileNum, "Journal Export")
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteHeader(fileNum)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteHeader(fileNum,   "Journal Export")
    END SELECT

    srcNum     = FREEFILE
    entryCount = 0

    OPEN JOURNAL_FILE FOR INPUT AS #srcNum
    DO WHILE NOT EOF(srcNum)
        LINE INPUT #srcNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            entryCount = entryCount + 1
            IF fmt = EXPORT_FMT_JSON AND entryCount > 1 THEN
                PRINT #fileNum, ","
            END IF
            CALL Export_WriteIdea(fileNum, lineText, fmt, entryCount)
        END IF
    LOOP
    CLOSE #srcNum

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteFooter(fileNum,  entryCount)
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteFooter(fileNum, entryCount)
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteFooter(fileNum, entryCount)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteFooter(fileNum,   entryCount)
    END SELECT

    CLOSE #fileNum

    IF entryCount = 0 THEN
        KILL filename
        Journal_ExportAll = ""
    ELSE
        Journal_ExportAll = filename
    END IF
END FUNCTION

' ============================================================
' Journal_DeleteEntry
' Placeholder — full implementation in a future phase.
' ============================================================
SUB Journal_DeleteEntry
    ' Future: rewrite journal.txt excluding the target line
    ' (same pattern as DeleteIdea when implemented)
END SUB
