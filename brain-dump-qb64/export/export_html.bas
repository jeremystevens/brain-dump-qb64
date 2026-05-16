' export_html.bas - HTML export formatter
' Part of Brain Dump QB64 - Export Modes System
' Responsibility: Format and write idea records as HTML.
'                 Retro-themed. Browser-friendly. CSS-ready.
'                 NEVER reads files. NEVER renders UI.
'$INCLUDEONCE

' ============================================================
' ExportHtml_EscapeStr$
' Escapes characters that would break HTML content:
'   & -> &amp;    < -> &lt;    > -> &gt;
' Keeps output safe for any browser.
' ============================================================
FUNCTION ExportHtml_EscapeStr$ (s AS STRING)
    DIM result AS STRING
    DIM i      AS INTEGER
    DIM ch     AS STRING

    result = ""
    FOR i = 1 TO LEN(s)
        ch = MID$(s, i, 1)
        SELECT CASE ch
            CASE "&"
                result = result + "&amp;"
            CASE "<"
                result = result + "&lt;"
            CASE ">"
                result = result + "&gt;"
            CASE ELSE
                result = result + ch
        END SELECT
    NEXT i

    ExportHtml_EscapeStr = result
END FUNCTION

' ============================================================
' ExportHtml_WriteHeader
' Writes the full HTML document head and opening body.
' Includes retro-style embedded CSS with future theme hooks.
' ============================================================
SUB ExportHtml_WriteHeader (fileNum AS INTEGER, title AS STRING)
    PRINT #fileNum, "<!DOCTYPE html>"
    PRINT #fileNum, "<html lang=" + CHR$(34) + "en" + CHR$(34) + ">"
    PRINT #fileNum, "<head>"
    PRINT #fileNum, "  <meta charset=" + CHR$(34) + "UTF-8" + CHR$(34) + ">"
    PRINT #fileNum, "  <title>Brain Dump QB64 — " + ExportHtml_EscapeStr$(title) + "</title>"
    PRINT #fileNum, "  <style>"
    PRINT #fileNum, "    /* Brain Dump QB64 Export — Retro Theme */"
    PRINT #fileNum, "    /* Future: swap this block for CRT/dark/ASCII themes */"
    PRINT #fileNum, "    body { background:#1a1a1a; color:#c0c0c0; font-family:monospace; padding:2em; }"
    PRINT #fileNum, "    h1   { color:#00ff00; border-bottom:2px solid #00ff00; }"
    PRINT #fileNum, "    h2   { color:#ffff00; }"
    PRINT #fileNum, "    .idea-card  { border:1px solid #444; padding:1em; margin-bottom:1.5em; }"
    PRINT #fileNum, "    .meta       { color:#888; font-size:0.9em; margin-bottom:0.5em; }"
    PRINT #fileNum, "    .priority   { font-weight:bold; color:#ff8800; }"
    PRINT #fileNum, "    .fav-yes    { color:#ffff00; }"
    PRINT #fileNum, "    .fav-no     { color:#555; }"
    PRINT #fileNum, "    .idea-text  { color:#e0e0e0; white-space:pre-wrap; }"
    PRINT #fileNum, "    .tags       { color:#00cccc; font-size:0.85em; }"
    PRINT #fileNum, "    .footer     { border-top:1px solid #444; margin-top:2em; color:#666; }"
    PRINT #fileNum, "  </style>"
    PRINT #fileNum, "</head>"
    PRINT #fileNum, "<body>"
    PRINT #fileNum, "<h1>&#x1F9E0; Brain Dump QB64 — " + ExportHtml_EscapeStr$(title) + "</h1>"
    PRINT #fileNum, "<p class=" + CHR$(34) + "meta" + CHR$(34) + ">Exported: " + DATE$ + " " + TIME$ + "</p>"
    PRINT #fileNum, ""
END SUB

' ============================================================
' ExportHtml_WriteIdea
' Writes one styled idea card to an open file.
' ============================================================
SUB ExportHtml_WriteIdea (fileNum AS INTEGER, ideaNum AS INTEGER, timestamp AS STRING, ideaText AS STRING, tags AS STRING, priorityLabel AS STRING, isFav AS INTEGER)
    DIM favClass AS STRING
    DIM favText  AS STRING

    IF isFav THEN
        favClass = "fav-yes"
        favText  = "&#9733; Starred"
    ELSE
        favClass = "fav-no"
        favText  = "&#9734; Not starred"
    END IF

    PRINT #fileNum, "<div class=" + CHR$(34) + "idea-card" + CHR$(34) + ">"
    PRINT #fileNum, "  <h2>Idea #" + LTRIM$(STR$(ideaNum)) + "</h2>"
    PRINT #fileNum, "  <div class=" + CHR$(34) + "meta" + CHR$(34) + ">"
    PRINT #fileNum, "    <span>&#128197; " + ExportHtml_EscapeStr$(timestamp) + "</span> &nbsp;"
    PRINT #fileNum, "    <span class=" + CHR$(34) + "priority" + CHR$(34) + ">[" + priorityLabel + "]</span> &nbsp;"
    PRINT #fileNum, "    <span class=" + CHR$(34) + favClass + CHR$(34) + ">" + favText + "</span>"
    PRINT #fileNum, "  </div>"

    IF LEN(LTRIM$(tags)) > 0 THEN
        PRINT #fileNum, "  <p class=" + CHR$(34) + "tags" + CHR$(34) + ">" + ExportHtml_EscapeStr$(tags) + "</p>"
    END IF

    PRINT #fileNum, "  <p class=" + CHR$(34) + "idea-text" + CHR$(34) + ">" + ExportHtml_EscapeStr$(ideaText) + "</p>"
    PRINT #fileNum, "</div>"
    PRINT #fileNum, ""
END SUB

' ============================================================
' ExportHtml_WriteFooter
' Closes the HTML document body.
' ============================================================
SUB ExportHtml_WriteFooter (fileNum AS INTEGER, ideaCount AS INTEGER)
    PRINT #fileNum, "<div class=" + CHR$(34) + "footer" + CHR$(34) + ">"
    PRINT #fileNum, "  <p>Total ideas exported: " + LTRIM$(STR$(ideaCount)) + "</p>"
    PRINT #fileNum, "  <p><em>Generated by Brain Dump QB64</em></p>"
    PRINT #fileNum, "</div>"
    PRINT #fileNum, "</body>"
    PRINT #fileNum, "</html>"
END SUB
