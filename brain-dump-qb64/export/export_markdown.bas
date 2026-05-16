' export_markdown.bas - Markdown export formatter
' Part of Brain Dump QB64 - Export Modes System
' Responsibility: Format and write idea records as Markdown.
'                 GitHub-compatible. Future wiki/docs ready.
'                 NEVER reads files. NEVER renders UI.
'$INCLUDEONCE

' ============================================================
' ExportMd_WriteHeader
' Writes the Markdown document header to an open file.
' ============================================================
SUB ExportMd_WriteHeader (fileNum AS INTEGER, title AS STRING)
    PRINT #fileNum, "# Brain Dump QB64 — " + title
    PRINT #fileNum, ""
    PRINT #fileNum, "_Exported: " + DATE$ + " " + TIME$ + "_"
    PRINT #fileNum, ""
    PRINT #fileNum, "---"
    PRINT #fileNum, ""
END SUB

' ============================================================
' ExportMd_WriteIdea
' Writes one formatted idea block to an open file.
' ============================================================
SUB ExportMd_WriteIdea (fileNum AS INTEGER, ideaNum AS INTEGER, timestamp AS STRING, ideaText AS STRING, tags AS STRING, priorityLabel AS STRING, isFav AS INTEGER)
    DIM favText AS STRING

    IF isFav THEN
        favText = "Yes ★"
    ELSE
        favText = "No"
    END IF

    PRINT #fileNum, "## Idea #" + LTRIM$(STR$(ideaNum))
    PRINT #fileNum, ""
    PRINT #fileNum, "**Date:** " + timestamp
    PRINT #fileNum, ""
    PRINT #fileNum, "**Priority:** " + priorityLabel
    PRINT #fileNum, ""
    PRINT #fileNum, "**Favorite:** " + favText
    PRINT #fileNum, ""

    IF LEN(LTRIM$(tags)) > 0 THEN
        PRINT #fileNum, "**Tags:** " + tags
        PRINT #fileNum, ""
    END IF

    PRINT #fileNum, ideaText
    PRINT #fileNum, ""
    PRINT #fileNum, "---"
    PRINT #fileNum, ""
END SUB

' ============================================================
' ExportMd_WriteFooter
' Writes the Markdown document footer to an open file.
' ============================================================
SUB ExportMd_WriteFooter (fileNum AS INTEGER, ideaCount AS INTEGER)
    PRINT #fileNum, "_Total ideas exported: " + LTRIM$(STR$(ideaCount)) + "_"
END SUB
