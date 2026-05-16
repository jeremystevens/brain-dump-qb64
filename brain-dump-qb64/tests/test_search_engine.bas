' test_search_engine.bas - Unit tests for pure functions in search_engine.bas
' Covers: Search_Match%, Search_Score%
' NOTE: Search_Query$ reads ideas.txt (file I/O) and is covered by
'       integration tests in test_integration.bas rather than here.
'$INCLUDEONCE

' ============================================================
' TestSuite_SearchEngine — master entry point
' ============================================================
SUB TestSuite_SearchEngine
    CALL T_BeginSuite("SearchEngine")
    CALL Test_Search_Match
    CALL Test_Search_Score
END SUB

' ============================================================
' Search_Match%
' Returns -1 (true) if ANY pipe-delimited token is found in
' source (case-insensitive). Returns 0 when no token matches.
' ============================================================
SUB Test_Search_Match
    ' Single token found
    CALL T_Assert(Search_Match%("hello world idea", "hello"), _
        "Match: single token found in source -> true")
    CALL T_Assert(Search_Match%("hello world idea", "world"), _
        "Match: token in middle of source -> true")
    CALL T_Assert(Search_Match%("hello world idea", "idea"), _
        "Match: token at end of source -> true")

    ' Case-insensitive matching
    CALL T_Assert(Search_Match%("Hello World Idea", "hello"), _
        "Match: mixed-case source, lowercase token -> true")
    CALL T_Assert(Search_Match%("HELLO WORLD", "hello"), _
        "Match: uppercase source, lowercase token -> true")
    CALL T_Assert(Search_Match%("hello world", "HELLO"), _
        "Match: lowercase source, uppercase token -> true")

    ' Pipe-delimited token list — ANY match returns true
    CALL T_Assert(Search_Match%("build the app", "build|deploy"), _
        "Match: first of pipe tokens found -> true")
    CALL T_Assert(Search_Match%("deploy the app", "build|deploy"), _
        "Match: second of pipe tokens found -> true")
    CALL T_Assert(Search_Match%("only middle here", "first|middle|last"), _
        "Match: middle token of three found -> true")

    ' No match
    CALL T_Assert(NOT Search_Match%("hello world", "missing"), _
        "Match: token not present in source -> false")
    CALL T_Assert(NOT Search_Match%("hello world", "foo|bar|baz"), _
        "Match: none of the pipe tokens found -> false")

    ' Empty token list -> always false
    CALL T_Assert(NOT Search_Match%("hello world", ""), _
        "Match: empty token list -> false")

    ' Empty source
    CALL T_Assert(NOT Search_Match%("", "hello"), _
        "Match: empty source -> false")

    ' Substring matching (token found within a longer word)
    CALL T_Assert(Search_Match%("brainstorm ideas", "brain"), _
        "Match: token is prefix of word -> true (substring match)")

    ' Whitespace-only token list
    CALL T_Assert(NOT Search_Match%("hello world", "   "), _
        "Match: whitespace-only token list -> false")
END SUB

' ============================================================
' Search_Score%
' Scores a source line against a token list and raw query.
' Scoring breakdown used in tests (no priority/fav):
'   +3 per token found in idea body (before " | ")
'   +2 per token found in tags section (after " | ")
'   +1 if full rawQuery phrase appears in idea body
'   + Priority_GetWeight% bonus
'   + Favorites_GetWeight% bonus (20 if fav:1)
' ============================================================
SUB Test_Search_Score
    DIM score AS INTEGER
    DIM ideaLine AS STRING

    ' --- Body match: +3 per token ---
    ideaLine = "[01-01-2025 12:00:00] build the app | #dev"
    score = Search_Score%(ideaLine, "build", "build")
    ' +3 (body) +1 (phrase in body) = 4
    CALL T_AssertInt(score, 4, "Score: one token in body, phrase match -> 4")

    ' Tag-section match: +2 per token (token NOT in body)
    ideaLine = "[01-01-2025 12:00:00] some idea | #build"
    score = Search_Score%(ideaLine, "build", "build")
    ' +2 (tag) — phrase "build" is NOT in the body "[ts] some idea" -> +0
    CALL T_AssertInt(score, 2, "Score: token in tags only -> 2")

    ' Token in both body AND tags: +3 + +2
    ideaLine = "[01-01-2025 12:00:00] build project | #build"
    score = Search_Score%(ideaLine, "build", "build")
    ' +3 (body) +2 (tag) +1 (phrase in body) = 6
    CALL T_AssertInt(score, 6, "Score: token in both body and tags -> 6")

    ' Two tokens each in body: +3 +3 = 6, plus phrase bonus +1 = 7
    ideaLine = "[01-01-2025 12:00:00] build app here | #dev"
    score = Search_Score%(ideaLine, "build|app", "build app")
    ' +3 (build in body) +3 (app in body) +1 (phrase "build app" in body) = 7
    CALL T_AssertInt(score, 7, "Score: two tokens in body, phrase match -> 7")

    ' Priority bonus: CRITICAL (+15)
    ideaLine = "[01-01-2025 12:00:00] great idea | priority:4"
    score = Search_Score%(ideaLine, "idea", "idea")
    ' +3 (body) +1 (phrase) +15 (CRITICAL weight) = 19
    CALL T_AssertInt(score, 19, "Score: token in body + CRITICAL priority -> 19")

    ' Priority bonus: HIGH (+10)
    ideaLine = "[01-01-2025 12:00:00] great idea | priority:3"
    score = Search_Score%(ideaLine, "idea", "idea")
    ' +3 +1 +10 = 14
    CALL T_AssertInt(score, 14, "Score: token in body + HIGH priority -> 14")

    ' Priority bonus: MEDIUM (+5)
    ideaLine = "[01-01-2025 12:00:00] great idea | priority:2"
    score = Search_Score%(ideaLine, "idea", "idea")
    ' +3 +1 +5 = 9
    CALL T_AssertInt(score, 9, "Score: token in body + MEDIUM priority -> 9")

    ' Priority bonus: LOW (+2)
    ideaLine = "[01-01-2025 12:00:00] great idea | priority:1"
    score = Search_Score%(ideaLine, "idea", "idea")
    ' +3 +1 +2 = 6
    CALL T_AssertInt(score, 6, "Score: token in body + LOW priority -> 6")

    ' Favorite bonus (+20)
    ideaLine = "[01-01-2025 12:00:00] great idea | fav:1"
    score = Search_Score%(ideaLine, "idea", "idea")
    ' +3 (body) +1 (phrase) +20 (favorite) = 24
    CALL T_AssertInt(score, 24, "Score: token in body + favorite bonus -> 24")

    ' All bonuses: body match + CRITICAL + favorite
    ideaLine = "[01-01-2025 12:00:00] build app | #dev priority:4 fav:1"
    score = Search_Score%(ideaLine, "build", "build")
    ' +3 (body) +1 (phrase) +15 (CRITICAL) +20 (fav) = 39
    CALL T_AssertInt(score, 39, "Score: body + CRITICAL + favorite -> 39")

    ' No match: plain idea with no matching token
    ideaLine = "[01-01-2025 12:00:00] completely different text"
    score = Search_Score%(ideaLine, "xyz", "xyz")
    CALL T_AssertInt(score, 0, "Score: no match on plain idea -> 0")

    ' rawQuery phrase bonus only when phrase appears in body
    ideaLine = "[01-01-2025 12:00:00] app build order | #dev"
    score = Search_Score%(ideaLine, "build|app", "build app")
    ' Both tokens in body: +3+3=6. Phrase "build app" NOT in body -> +0 bonus
    CALL T_AssertInt(score, 6, "Score: tokens found but phrase absent -> no phrase bonus")

    ' Empty rawQuery -> no phrase bonus (LEN check in function)
    ideaLine = "[01-01-2025 12:00:00] build the thing"
    score = Search_Score%(ideaLine, "build", "")
    ' +3 (body) +0 (empty rawQuery, phrase bonus skipped) = 3
    CALL T_AssertInt(score, 3, "Score: empty rawQuery -> no phrase bonus")
END SUB
