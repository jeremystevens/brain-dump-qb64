' test_export_manager.bas - Unit tests for pure functions in export_manager.bas
'                           and escape helpers in export_json.bas / export_html.bas
' Covers: Export_ExtForFormat$, Export_ParseTimestamp$,
'         Export_ParseIdeaText$, Export_ParseTags$,
'         ExportJson_EscapeStr$, ExportHtml_EscapeStr$
'
' NOTE: Export_AllIdeas$, Export_FavoritesOnly$, Export_SearchResults$,
'       and Export_GenerateFilename$ all perform file I/O or use
'       real-time DATE$/TIME$ and are therefore covered by integration
'       tests rather than unit tests.
'$INCLUDEONCE

' ============================================================
' TestSuite_ExportManager — master entry point
' ============================================================
SUB TestSuite_ExportManager
    CALL T_BeginSuite("ExportManager")
    CALL Test_Export_ExtForFormat
    CALL Test_Export_ParseTimestamp
    CALL Test_Export_ParseIdeaText
    CALL Test_Export_ParseTags
    CALL T_BeginSuite("ExportJson_EscapeStr")
    CALL Test_ExportJson_EscapeStr
    CALL T_BeginSuite("ExportHtml_EscapeStr")
    CALL Test_ExportHtml_EscapeStr
END SUB

' ============================================================
' Export_ExtForFormat$
' Maps an EXPORT_FMT_* constant to a file extension string.
' ============================================================
SUB Test_Export_ExtForFormat
    CALL T_AssertStr(Export_ExtForFormat$(EXPORT_FMT_HTML), "html", _
        "ExtForFormat: EXPORT_FMT_HTML -> html")
    CALL T_AssertStr(Export_ExtForFormat$(EXPORT_FMT_JSON), "json", _
        "ExtForFormat: EXPORT_FMT_JSON -> json")
    CALL T_AssertStr(Export_ExtForFormat$(EXPORT_FMT_MD),   "md",   _
        "ExtForFormat: EXPORT_FMT_MD -> md")
    CALL T_AssertStr(Export_ExtForFormat$(EXPORT_FMT_TXT),  "txt",  _
        "ExtForFormat: EXPORT_FMT_TXT -> txt")

    ' Unknown / unrecognised constants fall to ELSE -> txt
    CALL T_AssertStr(Export_ExtForFormat$(0),  "txt", "ExtForFormat: 0 (unknown) -> txt (ELSE)")
    CALL T_AssertStr(Export_ExtForFormat$(99), "txt", "ExtForFormat: 99 (unknown) -> txt (ELSE)")
END SUB

' ============================================================
' Export_ParseTimestamp$
' Extracts the bracketed timestamp from the start of a raw line.
' Format: [MM-DD-YYYY HH:MM:SS] rest of line
' Returns "" when no valid bracket at position 1.
' ============================================================
SUB Test_Export_ParseTimestamp
    ' Standard full-line format
    CALL T_AssertStr(Export_ParseTimestamp$("[05-15-2026 21:37:00] idea text"), _
        "[05-15-2026 21:37:00]", _
        "ParseTimestamp: standard format -> bracketed timestamp")

    CALL T_AssertStr(Export_ParseTimestamp$("[01-01-2025 00:00:00] note | #tag"), _
        "[01-01-2025 00:00:00]", _
        "ParseTimestamp: with tags section -> just timestamp")

    ' Shorter bracket content is still extracted
    CALL T_AssertStr(Export_ParseTimestamp$("[ts] content"), "[ts]", _
        "ParseTimestamp: short bracket content")

    ' Opening bracket must be at position 1
    CALL T_AssertStr(Export_ParseTimestamp$("text [05-15-2026 21:37:00] more"), "", _
        "ParseTimestamp: bracket not at position 1 -> empty")

    ' No bracket at all
    CALL T_AssertStr(Export_ParseTimestamp$("no timestamp here"), "", _
        "ParseTimestamp: no brackets -> empty")

    ' Empty string
    CALL T_AssertStr(Export_ParseTimestamp$(""), "", _
        "ParseTimestamp: empty string -> empty")

    ' Only opening bracket, no closing bracket
    CALL T_AssertStr(Export_ParseTimestamp$("[no closing"), "", _
        "ParseTimestamp: no closing bracket -> empty")
END SUB

' ============================================================
' Export_ParseIdeaText$
' Extracts the idea body: text between timestamp and " | ".
' When no " | " separator, returns everything after timestamp.
' When no timestamp, returns the full trimmed string.
' ============================================================
SUB Test_Export_ParseIdeaText
    ' Standard format with tags
    CALL T_AssertStr(Export_ParseIdeaText$("[05-15-2026 21:37:00] My idea text | #tag priority:3"), _
        "My idea text", _
        "ParseIdeaText: standard format -> idea body only")

    ' No pipe separator: everything after timestamp is the idea
    CALL T_AssertStr(Export_ParseIdeaText$("[05-15-2026 21:37:00] Just an idea"), _
        "Just an idea", _
        "ParseIdeaText: no pipe -> everything after timestamp")

    ' Whitespace trimming around the idea body
    CALL T_AssertStr(Export_ParseIdeaText$("[05-15-2026 21:37:00] Idea with spaces  | #tag"), _
        "Idea with spaces", _
        "ParseIdeaText: trailing spaces before pipe are trimmed")

    ' No timestamp: full trimmed string returned
    CALL T_AssertStr(Export_ParseIdeaText$("no timestamp plain text"), _
        "no timestamp plain text", _
        "ParseIdeaText: no timestamp -> full trimmed text")

    CALL T_AssertStr(Export_ParseIdeaText$("  trimmed  "), "trimmed", _
        "ParseIdeaText: no timestamp, only spaces -> trimmed text")

    ' Empty string
    CALL T_AssertStr(Export_ParseIdeaText$(""), "", _
        "ParseIdeaText: empty string -> empty")

    ' Timestamp only (nothing after closing bracket)
    CALL T_AssertStr(Export_ParseIdeaText$("[05-15-2026 21:37:00]"), "", _
        "ParseIdeaText: timestamp only -> empty idea body")

    ' Idea body is a single word
    CALL T_AssertStr(Export_ParseIdeaText$("[01-01-2025 00:00:00] Dream"), _
        "Dream", _
        "ParseIdeaText: single-word idea body")
END SUB

' ============================================================
' Export_ParseTags$
' Returns user-visible tags from the " | " section, stripping
' system tokens (priority:N and fav:1).
' ============================================================
SUB Test_Export_ParseTags
    ' User tags preserved; system tokens removed
    CALL T_AssertStr(Export_ParseTags$("[ts] idea | #project #work priority:3"), _
        "#project #work", _
        "ParseTags: user tags preserved, priority: stripped")

    CALL T_AssertStr(Export_ParseTags$("[ts] idea | #project fav:1 priority:2"), _
        "#project", _
        "ParseTags: fav:1 and priority: stripped, #project kept")

    ' Only system tokens -> empty
    CALL T_AssertStr(Export_ParseTags$("[ts] idea | priority:3 fav:1"), "", _
        "ParseTags: only system tokens -> empty string")

    ' No pipe separator -> empty
    CALL T_AssertStr(Export_ParseTags$("[ts] idea"), "", _
        "ParseTags: no pipe -> empty string")

    ' Single user tag
    CALL T_AssertStr(Export_ParseTags$("[ts] idea | #single"), "#single", _
        "ParseTags: single user tag")

    ' Multiple user tags, system tokens mixed in
    CALL T_AssertStr(Export_ParseTags$("[ts] idea | #a #b #c priority:4 fav:1"), _
        "#a #b #c", _
        "ParseTags: multiple user tags, system tokens stripped")

    ' Empty string
    CALL T_AssertStr(Export_ParseTags$(""), "", _
        "ParseTags: empty string -> empty")

    ' Pipe present but tag section is empty after trimming
    CALL T_AssertStr(Export_ParseTags$("[ts] idea |   "), "", _
        "ParseTags: tag section is only whitespace -> empty")

    ' Tag section with only priority (no fav)
    CALL T_AssertStr(Export_ParseTags$("[ts] idea | priority:1"), "", _
        "ParseTags: only priority system token -> empty")

    ' Tags section starting with fav:1
    CALL T_AssertStr(Export_ParseTags$("[ts] idea | fav:1 #note"), "#note", _
        "ParseTags: fav:1 first, user tag after -> user tag preserved")
END SUB

' ============================================================
' ExportJson_EscapeStr$
' Escapes backslash (\) and double-quote (") for JSON strings.
' ============================================================
SUB Test_ExportJson_EscapeStr
    ' No special characters -> unchanged
    CALL T_AssertStr(ExportJson_EscapeStr$("plain text"), "plain text", _
        "JsonEscape: no special chars -> unchanged")
    CALL T_AssertStr(ExportJson_EscapeStr$("alphanumeric 0123456789"), _
        "alphanumeric 0123456789", _
        "JsonEscape: alphanumeric unchanged")
    CALL T_AssertStr(ExportJson_EscapeStr$(""), "", _
        "JsonEscape: empty string -> empty")

    ' Backslash escaped: \ -> \\
    CALL T_AssertStr(ExportJson_EscapeStr$("path\to\file"), "path\\to\\file", _
        "JsonEscape: backslashes escaped")
    CALL T_AssertStr(ExportJson_EscapeStr$("\"), "\\", _
        "JsonEscape: single backslash -> double backslash")

    ' Double-quote escaped: " -> \"
    CALL T_AssertStr(ExportJson_EscapeStr$(CHR$(34)), "\" + CHR$(34), _
        "JsonEscape: single double-quote -> backslash + double-quote")
    CALL T_AssertStr( _
        ExportJson_EscapeStr$("say " + CHR$(34) + "hello" + CHR$(34)), _
        "say \" + CHR$(34) + "hello\" + CHR$(34), _
        "JsonEscape: double-quotes in phrase escaped")

    ' Mixed: backslash and double-quote
    CALL T_AssertStr( _
        ExportJson_EscapeStr$("a\b" + CHR$(34) + "c"), _
        "a\\b\" + CHR$(34) + "c", _
        "JsonEscape: mixed backslash and double-quote")
END SUB

' ============================================================
' ExportHtml_EscapeStr$
' Escapes & -> &amp;  < -> &lt;  > -> &gt; for HTML content.
' ============================================================
SUB Test_ExportHtml_EscapeStr
    ' No special characters -> unchanged
    CALL T_AssertStr(ExportHtml_EscapeStr$("plain text"), "plain text", _
        "HtmlEscape: no special chars -> unchanged")
    CALL T_AssertStr(ExportHtml_EscapeStr$(""), "", _
        "HtmlEscape: empty string -> empty")

    ' Ampersand
    CALL T_AssertStr(ExportHtml_EscapeStr$("a & b"), "a &amp; b", _
        "HtmlEscape: ampersand -> &amp;")
    CALL T_AssertStr(ExportHtml_EscapeStr$("&&"), "&amp;&amp;", _
        "HtmlEscape: two ampersands -> &amp;&amp;")

    ' Less-than
    CALL T_AssertStr(ExportHtml_EscapeStr$("a < b"), "a &lt; b", _
        "HtmlEscape: less-than -> &lt;")

    ' Greater-than
    CALL T_AssertStr(ExportHtml_EscapeStr$("a > b"), "a &gt; b", _
        "HtmlEscape: greater-than -> &gt;")

    ' HTML tag (both < and >)
    CALL T_AssertStr(ExportHtml_EscapeStr$("<script>"), "&lt;script&gt;", _
        "HtmlEscape: HTML tag -> both brackets escaped")

    ' Mixed special characters
    CALL T_AssertStr(ExportHtml_EscapeStr$("a < b & c > d"), _
        "a &lt; b &amp; c &gt; d", _
        "HtmlEscape: mixed < & > -> all escaped")

    ' Normal text with no HTML-sensitive chars
    CALL T_AssertStr(ExportHtml_EscapeStr$("Brain Dump QB64 v2.0"), _
        "Brain Dump QB64 v2.0", _
        "HtmlEscape: text with numbers and symbols -> unchanged")
END SUB
