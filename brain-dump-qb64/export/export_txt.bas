' export_txt.bas - Plain text export formatter
' Part of Brain Dump QB64 - Export Modes System
' Responsibility: Format and write idea records as plain text.
'                 Receives pre-parsed fields from export_manager.
'                 NEVER reads files. NEVER renders UI.
'$INCLUDEONCE

' ============================================================
' ExportTxt_WriteHeader
' Writes the TXT document header to an open file.
' ============================================================
SUB ExportTxt_WriteHeader (fileNum AS INTEGER, title AS STRING)
    PRINT #fileNum, STRING$(40, "=")
    PRINT #fileNum, "BRAIN DUMP QB64 — EXPORT"
    PRINT #fileNum, title
    PRINT #fileNum, "Exported: " + DATE$ + " " + TIME$
    PRINT #fileNum, STRING$(40, "=")
    PRINT #fileNum, ""
END SUB

' ============================================================
' ExportTxt_WriteIdea
' Writes one formatted idea block to an open file.
' ============================================================
SUB ExportTxt_WriteIdea (fileNum AS INTEGER, ideaNum AS INTEGER, timestamp AS STRING, ideaText AS STRING, tags AS STRING, priorityLabel AS STRING, isFav AS INTEGER)
    DIM favText AS STRING

    IF isFav THEN
        favText = "YES [*]"
    ELSE
        favText = "NO"
    END IF

    PRINT #fileNum, STRING$(40, "-")
    PRINT #fileNum, "IDEA #" + LTRIM$(STR$(ideaNum))
    PRINT #fileNum, STRING$(40, "-")
    PRINT #fileNum, "DATE:     " + timestamp
    PRINT #fileNum, "PRIORITY: " + priorityLabel
    PRINT #fileNum, "FAVORITE: " + favText

    IF LEN(LTRIM$(tags)) > 0 THEN
        PRINT #fileNum, "TAGS:     " + tags
    END IF

    PRINT #fileNum, ""
    PRINT #fileNum, ideaText
    PRINT #fileNum, ""
END SUB

' ============================================================
' ExportTxt_WriteFooter
' Writes the TXT document footer to an open file.
' ============================================================
SUB ExportTxt_WriteFooter (fileNum AS INTEGER, ideaCount AS INTEGER)
    PRINT #fileNum, STRING$(40, "=")
    PRINT #fileNum, "TOTAL IDEAS EXPORTED: " + LTRIM$(STR$(ideaCount))
    PRINT #fileNum, STRING$(40, "=")
END SUB
