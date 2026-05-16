' stream_input.bas - Thought stream session management and file I/O
' Part of Brain Dump QB64 - Thought Stream Mode (Phase 3)
' Responsibility: All stream data operations — session tracking,
'                 rapid entry saving, search, export.
'                 NO rendering. NO UI logic.
' File: stream.txt — one entry per line, format:
'   [YYYY-MM-DD HH:MM:SS] {S:sessionID} thought text
' NOTE: STREAM_FILE, StreamEntry TYPE, g_StreamSessionID in main.bas.
'$INCLUDEONCE

' ============================================================
' Stream_Init
' Called once at startup. Creates stream.txt if missing and
' scans the file to find the highest existing session ID so
' new sessions always increment correctly.
' ============================================================
SUB Stream_Init
    DIM fileNum   AS INTEGER
    DIM lineText  AS STRING
    DIM sessionID AS INTEGER
    DIM bracePos  AS INTEGER
    DIM colonPos  AS INTEGER
    DIM endPos    AS INTEGER
    DIM idStr     AS STRING

    ' Ensure file exists
    fileNum = FREEFILE
    OPEN STREAM_FILE FOR APPEND AS #fileNum
    CLOSE #fileNum

    ' Find highest session ID in existing entries
    g_StreamSessionID = 0
    g_StreamActive    = 0

    fileNum = FREEFILE
    OPEN STREAM_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            ' Look for {S:N} token
            bracePos = INSTR(lineText, "{S:")
            IF bracePos > 0 THEN
                endPos = INSTR(bracePos, lineText, "}")
                IF endPos > bracePos + 3 THEN
                    idStr     = MID$(lineText, bracePos + 3, endPos - bracePos - 3)
                    sessionID = VAL(idStr)
                    IF sessionID > g_StreamSessionID THEN
                        g_StreamSessionID = sessionID
                    END IF
                END IF
            END IF
        END IF
    WEND
    CLOSE #fileNum
END SUB

' ============================================================
' Stream_IsActive%
' Returns -1 if a stream session is currently open, 0 if not.
' ============================================================
FUNCTION Stream_IsActive%
    Stream_IsActive = g_StreamActive
END FUNCTION

' ============================================================
' Stream_StartSession
' Opens a new session — increments g_StreamSessionID,
' sets g_StreamActive, and writes a session-start marker.
' Returns the new session ID.
' ============================================================
FUNCTION Stream_StartSession%
    DIM fileNum AS INTEGER

    g_StreamSessionID = g_StreamSessionID + 1
    g_StreamActive    = -1

    ' Write session header line (marked with {S:N}{START})
    fileNum = FREEFILE
    OPEN STREAM_FILE FOR APPEND AS #fileNum
    PRINT #fileNum, Date_GetTimestamp$ + " {S:" + LTRIM$(STR$(g_StreamSessionID)) + "}{START} SESSION STARTED"
    CLOSE #fileNum

    Stream_StartSession = g_StreamSessionID
END FUNCTION

' ============================================================
' Stream_EndSession
' Closes the current session and writes an end marker.
' ============================================================
SUB Stream_EndSession
    DIM fileNum AS INTEGER

    IF NOT g_StreamActive THEN EXIT SUB

    fileNum = FREEFILE
    OPEN STREAM_FILE FOR APPEND AS #fileNum
    PRINT #fileNum, Date_GetTimestamp$ + " {S:" + LTRIM$(STR$(g_StreamSessionID)) + "}{END} SESSION ENDED"
    CLOSE #fileNum

    g_StreamActive = 0
END SUB

' ============================================================
' Stream_AddEntry
' Saves one thought to stream.txt immediately.
' This is called the moment the user presses Enter — no buffer.
' Returns the timestamp string used for confirmation display.
' ============================================================
FUNCTION Stream_AddEntry$ (thoughtText AS STRING)
    DIM fileNum   AS INTEGER
    DIM timestamp AS STRING
    DIM fullLine  AS STRING

    timestamp = Date_GetTimestamp$
    fullLine  = timestamp + " {S:" + LTRIM$(STR$(g_StreamSessionID)) + "} " + LTRIM$(RTRIM$(thoughtText))

    fileNum = FREEFILE
    OPEN STREAM_FILE FOR APPEND AS #fileNum
    PRINT #fileNum, fullLine
    CLOSE #fileNum

    Stream_AddEntry = timestamp
END FUNCTION

' ============================================================
' Stream_ParseThought$
' Extracts the plain thought text from a raw stream line.
' Strips timestamp bracket and {S:N} session token.
' Returns "" for session marker lines ({START}/{END}).
' ============================================================
FUNCTION Stream_ParseThought$ (rawLine AS STRING)
    DIM afterTs  AS STRING
    DIM endTs    AS INTEGER
    DIM braceEnd AS INTEGER
    DIM thought  AS STRING

    ' Skip session start/end markers
    IF INSTR(rawLine, "{START}") > 0 OR INSTR(rawLine, "{END}") > 0 THEN
        Stream_ParseThought = ""
        EXIT FUNCTION
    END IF

    ' Skip past timestamp
    endTs = INSTR(rawLine, "]")
    IF endTs = 0 THEN
        Stream_ParseThought = LTRIM$(RTRIM$(rawLine))
        EXIT FUNCTION
    END IF

    afterTs = LTRIM$(MID$(rawLine, endTs + 1))

    ' Skip past {S:N} token
    IF LEFT$(afterTs, 1) = "{" THEN
        braceEnd = INSTR(afterTs, "}")
        IF braceEnd > 0 THEN
            afterTs = LTRIM$(MID$(afterTs, braceEnd + 1))
        END IF
    END IF

    Stream_ParseThought = LTRIM$(RTRIM$(afterTs))
END FUNCTION

' ============================================================
' Stream_ParseSessionID%
' Extracts the session ID integer from a raw stream line.
' Returns 0 if no {S:N} token found.
' ============================================================
FUNCTION Stream_ParseSessionID% (rawLine AS STRING)
    DIM bracePos AS INTEGER
    DIM endPos   AS INTEGER
    DIM idStr    AS STRING

    bracePos = INSTR(rawLine, "{S:")
    IF bracePos = 0 THEN
        Stream_ParseSessionID = 0
        EXIT FUNCTION
    END IF

    endPos = INSTR(bracePos, rawLine, "}")
    IF endPos <= bracePos + 3 THEN
        Stream_ParseSessionID = 0
        EXIT FUNCTION
    END IF

    idStr = MID$(rawLine, bracePos + 3, endPos - bracePos - 3)
    Stream_ParseSessionID = VAL(idStr)
END FUNCTION

' ============================================================
' Stream_CountTotal%
' Returns the total number of thought entries (not markers).
' ============================================================
FUNCTION Stream_CountTotal%
    DIM fileNum  AS INTEGER
    DIM lineText AS STRING
    DIM count    AS INTEGER

    count   = 0
    fileNum = FREEFILE

    OPEN STREAM_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            IF INSTR(lineText, "{START}") = 0 AND INSTR(lineText, "{END}") = 0 THEN
                count = count + 1
            END IF
        END IF
    WEND
    CLOSE #fileNum

    Stream_CountTotal = count
END FUNCTION

' ============================================================
' Stream_CountSessions%
' Returns the total number of sessions recorded.
' ============================================================
FUNCTION Stream_CountSessions%
    Stream_CountSessions = g_StreamSessionID
END FUNCTION

' ============================================================
' Stream_GetRecentEntries$
' Returns the most recent <maxCount> thought entries
' (excluding session markers) as a CHR$(10)-delimited block.
' Newest first.
' ============================================================
FUNCTION Stream_GetRecentEntries$ (maxCount AS INTEGER)
    DIM fileNum   AS INTEGER
    DIM lineText  AS STRING
    DIM allLines  AS STRING
    DIM remaining AS STRING
    DIM lineStr   AS STRING
    DIM nlPos     AS INTEGER
    DIM result    AS STRING
    DIM count     AS INTEGER

    allLines = ""
    fileNum  = FREEFILE

    OPEN STREAM_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            ' Exclude session markers
            IF INSTR(lineText, "{START}") = 0 AND INSTR(lineText, "{END}") = 0 THEN
                IF allLines = "" THEN
                    allLines = lineText
                ELSE
                    allLines = allLines + CHR$(10) + lineText
                END IF
            END IF
        END IF
    WEND
    CLOSE #fileNum

    IF allLines = "" THEN
        Stream_GetRecentEntries = ""
        EXIT FUNCTION
    END IF

    ' Collect into array then reverse
    DIM lines(1000) AS STRING
    DIM lineCount   AS INTEGER
    lineCount = 0
    remaining = allLines

    DO WHILE LEN(remaining) > 0 AND lineCount < 1000
        nlPos = INSTR(remaining, CHR$(10))
        IF nlPos = 0 THEN
            lineStr   = remaining
            remaining = ""
        ELSE
            lineStr   = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF
        IF LEN(LTRIM$(lineStr)) > 0 THEN
            lineCount        = lineCount + 1
            lines(lineCount) = lineStr
        END IF
    LOOP

    result = ""
    count  = 0
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

    Stream_GetRecentEntries = result
END FUNCTION

' ============================================================
' Stream_GetSessionEntries$
' Returns all thought entries for a specific session ID
' as a CHR$(10)-delimited block (markers excluded).
' ============================================================
FUNCTION Stream_GetSessionEntries$ (targetSession AS INTEGER)
    DIM fileNum  AS INTEGER
    DIM lineText AS STRING
    DIM result   AS STRING
    DIM sid      AS INTEGER

    result  = ""
    fileNum = FREEFILE

    OPEN STREAM_FILE FOR INPUT AS #fileNum
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            sid = Stream_ParseSessionID%(lineText)
            IF sid = targetSession THEN
                IF INSTR(lineText, "{START}") = 0 AND INSTR(lineText, "{END}") = 0 THEN
                    IF result = "" THEN
                        result = lineText
                    ELSE
                        result = result + CHR$(10) + lineText
                    END IF
                END IF
            END IF
        END IF
    WEND
    CLOSE #fileNum

    Stream_GetSessionEntries = result
END FUNCTION

' ============================================================
' Stream_SearchEntries$
' Searches stream.txt for entries matching tokenList.
' Excludes session markers. Returns result block in the same
' lineNum|score|rawText format as Search_Query$ so
' RenderSearchResults in search_ui.bas works unchanged.
' ============================================================
FUNCTION Stream_SearchEntries$ (rawQuery AS STRING, tokenList AS STRING)
    DIM fileNum    AS INTEGER
    DIM lineText   AS STRING
    DIM lineNum    AS INTEGER
    DIM matchScore AS INTEGER
    DIM result     AS STRING
    DIM entry      AS STRING

    result  = ""
    lineNum = 0

    fileNum = FREEFILE
    OPEN STREAM_FILE FOR INPUT AS #fileNum

    DO WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            IF INSTR(lineText, "{START}") = 0 AND INSTR(lineText, "{END}") = 0 THEN
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
        END IF
    LOOP

    CLOSE #fileNum
    Stream_SearchEntries = result
END FUNCTION

' ============================================================
' Stream_ExportSession$
' Exports all entries for a given session (or all sessions
' if sessionID = 0) in the chosen format.
' Reuses existing export formatter subs.
' Returns output filename, or "" if nothing to export.
' ============================================================
FUNCTION Stream_ExportSession$ (targetSession AS INTEGER, fmt AS INTEGER)
    DIM filename   AS STRING
    DIM fileNum    AS INTEGER
    DIM srcNum     AS INTEGER
    DIM lineText   AS STRING
    DIM entryCount AS INTEGER
    DIM ext        AS STRING
    DIM sid        AS INTEGER
    DIM prefix     AS STRING

    ext    = Export_ExtForFormat$(fmt)
    prefix = "stream_session_" + LTRIM$(STR$(targetSession))
    IF targetSession = 0 THEN prefix = "stream_export"
    filename = Export_GenerateFilename$(prefix, ext)

    fileNum = FREEFILE
    OPEN filename FOR OUTPUT AS #fileNum

    DIM headerTitle AS STRING
    IF targetSession = 0 THEN
        headerTitle = "Thought Stream — All Sessions"
    ELSE
        headerTitle = "Thought Stream — Session " + LTRIM$(STR$(targetSession))
    END IF

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteHeader(fileNum,  headerTitle)
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteHeader(fileNum, headerTitle)
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteHeader(fileNum)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteHeader(fileNum,   headerTitle)
    END SELECT

    srcNum     = FREEFILE
    entryCount = 0

    OPEN STREAM_FILE FOR INPUT AS #srcNum
    DO WHILE NOT EOF(srcNum)
        LINE INPUT #srcNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            IF INSTR(lineText, "{START}") = 0 AND INSTR(lineText, "{END}") = 0 THEN
                sid = Stream_ParseSessionID%(lineText)
                IF targetSession = 0 OR sid = targetSession THEN
                    entryCount = entryCount + 1
                    IF fmt = EXPORT_FMT_JSON AND entryCount > 1 THEN
                        PRINT #fileNum, ","
                    END IF
                    CALL Export_WriteIdea(fileNum, lineText, fmt, entryCount)
                END IF
            END IF
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
        Stream_ExportSession = ""
    ELSE
        Stream_ExportSession = filename
    END IF
END FUNCTION
