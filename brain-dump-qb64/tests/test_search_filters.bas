' test_search_filters.bas - Unit tests for search_filters.bas
' Covers: Extract_Field$, Extract_RawText$,
'         Filter_By_Tag%, Filter_By_Priority%, Filter_Favorites%
'
' Result record format used throughout: "lineNum|score|rawIdeaText"
' where rawIdeaText is the full line from ideas.txt, e.g.
'   "[01-01-2025 12:00:00] idea body | #tag priority:3 fav:1"
'$INCLUDEONCE

' ============================================================
' TestSuite_SearchFilters — master entry point
' ============================================================
SUB TestSuite_SearchFilters
    CALL T_BeginSuite("SearchFilters")
    CALL Test_Extract_Field
    CALL Test_Extract_RawText
    CALL Test_Filter_By_Tag
    CALL Test_Filter_By_Priority
    CALL Test_Filter_Favorites
END SUB

' ============================================================
' Extract_Field$
' Splits a pipe-delimited string and returns field N (1-based).
' Note: splits on ALL pipes — use Extract_RawText$ when field 3
'       is a raw idea line that itself contains " | ".
' ============================================================
SUB Test_Extract_Field
    ' Basic three-field extraction
    CALL T_AssertStr(Extract_Field$("1|5|some idea text #tag", 1), "1", _
        "ExtractField: field 1 of 3-field record")
    CALL T_AssertStr(Extract_Field$("1|5|some idea text #tag", 2), "5", _
        "ExtractField: field 2 of 3-field record")
    CALL T_AssertStr(Extract_Field$("1|5|some idea text #tag", 3), "some idea text #tag", _
        "ExtractField: field 3 (no pipe in field 3 content)")

    ' Field beyond end -> empty
    CALL T_AssertStr(Extract_Field$("1|5|some idea text #tag", 4), "", _
        "ExtractField: field 4 beyond end -> empty")
    CALL T_AssertStr(Extract_Field$("a", 2), "", _
        "ExtractField: single-field record, requesting field 2 -> empty")

    ' Simple a|b|c record
    CALL T_AssertStr(Extract_Field$("a|b|c", 1), "a", "ExtractField: a|b|c field 1")
    CALL T_AssertStr(Extract_Field$("a|b|c", 2), "b", "ExtractField: a|b|c field 2")
    CALL T_AssertStr(Extract_Field$("a|b|c", 3), "c", "ExtractField: a|b|c field 3")

    ' Single field, no pipe
    CALL T_AssertStr(Extract_Field$("single", 1), "single", _
        "ExtractField: single field, no pipes")

    ' Empty record
    CALL T_AssertStr(Extract_Field$("", 1), "", _
        "ExtractField: empty record -> empty")

    ' When field 3 contains pipes (raw idea text format), only
    ' the sub-field before the next pipe is returned.
    CALL T_AssertStr(Extract_Field$("1|5|idea body | #tag", 3), "idea body ", _
        "ExtractField: field 3 truncated at embedded pipe (known behaviour)")
END SUB

' ============================================================
' Extract_RawText$
' Returns everything after the first 2 pipe separators,
' preserving any additional pipes in the raw idea text.
' ============================================================
SUB Test_Extract_RawText
    ' Standard result record with tagged idea
    CALL T_AssertStr(Extract_RawText$("1|15|[ts] idea | #game priority:3"), _
        "[ts] idea | #game priority:3", _
        "ExtractRawText: full raw text including tags section")

    ' Idea without tags (no extra pipe)
    CALL T_AssertStr(Extract_RawText$("3|8|[ts] plain idea text"), _
        "[ts] plain idea text", _
        "ExtractRawText: idea without pipe separator")

    ' Multiple internal pipes preserved
    CALL T_AssertStr(Extract_RawText$("2|20|[ts] idea | #a | #b"), _
        "[ts] idea | #a | #b", _
        "ExtractRawText: multiple pipes in raw text all preserved")

    ' Only one field (no pipes at all) -> returns full record
    CALL T_AssertStr(Extract_RawText$("nofields"), _
        "nofields", _
        "ExtractRawText: no pipes at all -> returns full string")

    ' Only one pipe -> returns everything after it
    CALL T_AssertStr(Extract_RawText$("1|rawtext"), _
        "rawtext", _
        "ExtractRawText: one pipe -> returns field 2 onward")
END SUB

' ============================================================
' Filter_By_Tag%
' Filters result block to records whose raw text contains tag.
' ============================================================
SUB Test_Filter_By_Tag
    DIM outResults AS STRING
    DIM count AS INTEGER
    DIM block AS STRING

    ' Single matching record (tag in tag section)
    block = "1|5|[ts] some idea | #game priority:2"
    count = Filter_By_Tag%(block, "game", outResults)
    CALL T_AssertInt(count, 1, "FilterByTag: single record with matching tag -> 1")
    CALL T_Assert(INSTR(outResults, "game") > 0, "FilterByTag: result contains 'game'")

    ' Single record without the tag
    block = "1|5|[ts] some idea | #work priority:2"
    count = Filter_By_Tag%(block, "game", outResults)
    CALL T_AssertInt(count, 0, "FilterByTag: tag not present -> 0")
    CALL T_AssertStr(outResults, "", "FilterByTag: no match -> empty outResults")

    ' Auto-prefix: tagValue without # -> # added automatically
    block = "1|5|[ts] idea | #game"
    count = Filter_By_Tag%(block, "game", outResults)
    CALL T_AssertInt(count, 1, "FilterByTag: auto-adds # prefix when missing")

    ' tagValue already has # prefix -> not double-prefixed
    block = "1|5|[ts] idea | #game"
    count = Filter_By_Tag%(block, "#game", outResults)
    CALL T_AssertInt(count, 1, "FilterByTag: existing # prefix handled correctly")

    ' Two records, one match
    block = "1|5|[ts] idea A | #game" + CHR$(10) + _
            "2|3|[ts] idea B | #work"
    count = Filter_By_Tag%(block, "game", outResults)
    CALL T_AssertInt(count, 1, "FilterByTag: two records, one match -> 1")
    CALL T_Assert(INSTR(outResults, "idea A") > 0, "FilterByTag: matched record preserved")
    CALL T_Assert(INSTR(outResults, "idea B") = 0, "FilterByTag: non-matching record excluded")

    ' Two records, both match
    block = "1|5|[ts] idea A | #game" + CHR$(10) + _
            "2|8|[ts] idea B | #game #dev"
    count = Filter_By_Tag%(block, "game", outResults)
    CALL T_AssertInt(count, 2, "FilterByTag: two records both matching -> 2")

    ' Case-insensitive tag matching
    block = "1|5|[ts] idea | #GAME"
    count = Filter_By_Tag%(block, "game", outResults)
    CALL T_AssertInt(count, 1, "FilterByTag: case-insensitive match -> 1")

    ' Empty block
    count = Filter_By_Tag%("", "game", outResults)
    CALL T_AssertInt(count, 0, "FilterByTag: empty block -> 0")
    CALL T_AssertStr(outResults, "", "FilterByTag: empty block -> empty outResults")
END SUB

' ============================================================
' Filter_By_Priority%
' Filters result block to records at or above a priority level.
' ============================================================
SUB Test_Filter_By_Priority
    DIM outResults AS STRING
    DIM count AS INTEGER
    DIM block AS STRING

    ' Exact match: HIGH record passes "high" threshold
    block = "1|10|[ts] idea | priority:3"
    count = Filter_By_Priority%(block, "high", outResults)
    CALL T_AssertInt(count, 1, "FilterByPriority: HIGH (3) >= threshold HIGH -> 1")

    ' CRITICAL passes "high" threshold
    block = "1|15|[ts] idea | priority:4"
    count = Filter_By_Priority%(block, "high", outResults)
    CALL T_AssertInt(count, 1, "FilterByPriority: CRITICAL (4) >= HIGH (3) -> 1")

    ' MEDIUM does NOT pass "high" threshold
    block = "1|5|[ts] idea | priority:2"
    count = Filter_By_Priority%(block, "high", outResults)
    CALL T_AssertInt(count, 0, "FilterByPriority: MEDIUM (2) < HIGH (3) -> excluded")

    ' "critical" threshold: only CRITICAL passes
    block = "1|10|[ts] idea | priority:3"
    count = Filter_By_Priority%(block, "critical", outResults)
    CALL T_AssertInt(count, 0, "FilterByPriority: HIGH (3) < CRITICAL (4) -> excluded")

    block = "1|15|[ts] idea | priority:4"
    count = Filter_By_Priority%(block, "critical", outResults)
    CALL T_AssertInt(count, 1, "FilterByPriority: CRITICAL (4) >= CRITICAL (4) -> 1")

    ' "low" threshold: LOW and above pass
    block = "1|2|[ts] idea | priority:1"
    count = Filter_By_Priority%(block, "low", outResults)
    CALL T_AssertInt(count, 1, "FilterByPriority: LOW (1) >= LOW (1) -> 1")

    ' NONE (0) does NOT pass "low" threshold
    block = "1|0|[ts] idea without priority"
    count = Filter_By_Priority%(block, "low", outResults)
    CALL T_AssertInt(count, 0, "FilterByPriority: NONE (0) < LOW (1) -> excluded")

    ' "med" threshold: MED, HIGH, CRITICAL pass; LOW and NONE excluded
    block = "1|5|[ts] idea | priority:2"
    count = Filter_By_Priority%(block, "med", outResults)
    CALL T_AssertInt(count, 1, "FilterByPriority: MED (2) >= MED (2) -> 1")

    block = "1|2|[ts] idea | priority:1"
    count = Filter_By_Priority%(block, "med", outResults)
    CALL T_AssertInt(count, 0, "FilterByPriority: LOW (1) < MED (2) -> excluded")

    ' Multi-record block: mixed priorities filtered correctly
    block = "1|15|[ts] critical idea | priority:4" + CHR$(10) + _
            "2|10|[ts] high idea | priority:3" + CHR$(10) + _
            "3|5|[ts] medium idea | priority:2"
    count = Filter_By_Priority%(block, "high", outResults)
    CALL T_AssertInt(count, 2, "FilterByPriority: 3 records, 2 pass high threshold")

    ' Empty block
    count = Filter_By_Priority%("", "high", outResults)
    CALL T_AssertInt(count, 0, "FilterByPriority: empty block -> 0")
END SUB

' ============================================================
' Filter_Favorites%
' Filters result block to records that have fav:1.
' ============================================================
SUB Test_Filter_Favorites
    DIM outResults AS STRING
    DIM count AS INTEGER
    DIM block AS STRING

    ' Single favorited record passes
    block = "1|20|[ts] starred idea | #tag fav:1"
    count = Filter_Favorites%(block, outResults)
    CALL T_AssertInt(count, 1, "FilterFavorites: fav:1 record -> 1")
    CALL T_Assert(INSTR(outResults, "fav:1") > 0, "FilterFavorites: result preserves fav:1")

    ' Non-favorited record excluded
    block = "1|5|[ts] plain idea | #tag"
    count = Filter_Favorites%(block, outResults)
    CALL T_AssertInt(count, 0, "FilterFavorites: non-favorite -> 0")
    CALL T_AssertStr(outResults, "", "FilterFavorites: non-favorite -> empty outResults")

    ' Mixed block: one favorite, one not
    block = "1|20|[ts] starred idea | fav:1" + CHR$(10) + _
            "2|5|[ts] plain idea | #tag"
    count = Filter_Favorites%(block, outResults)
    CALL T_AssertInt(count, 1, "FilterFavorites: mixed block -> 1 favorite")
    CALL T_Assert(INSTR(outResults, "starred idea") > 0, "FilterFavorites: favorited record retained")
    CALL T_Assert(INSTR(outResults, "plain idea") = 0, "FilterFavorites: non-favorited record excluded")

    ' All records are favorites
    block = "1|20|[ts] idea A | fav:1" + CHR$(10) + _
            "2|25|[ts] idea B | priority:3 fav:1"
    count = Filter_Favorites%(block, outResults)
    CALL T_AssertInt(count, 2, "FilterFavorites: all favorites -> 2")

    ' fav:1 combined with priority tag in tag section
    block = "1|35|[ts] top idea | priority:4 fav:1"
    count = Filter_Favorites%(block, outResults)
    CALL T_AssertInt(count, 1, "FilterFavorites: fav:1 with priority -> 1")

    ' Empty block
    count = Filter_Favorites%("", outResults)
    CALL T_AssertInt(count, 0, "FilterFavorites: empty block -> 0")
    CALL T_AssertStr(outResults, "", "FilterFavorites: empty block -> empty outResults")
END SUB
