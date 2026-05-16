' test_search_parser.bas - Unit tests for search_parser.bas
' Covers: Parse_Search_Query$, Extract_Search_Tokens$,
'         Extract_Search_Filters$
'$INCLUDEONCE

' ============================================================
' TestSuite_SearchParser — master entry point
' ============================================================
SUB TestSuite_SearchParser
    CALL T_BeginSuite("SearchParser")
    CALL Test_Parse_Search_Query
    CALL Test_Extract_Search_Tokens
    CALL Test_Extract_Search_Filters
END SUB

' ============================================================
' Parse_Search_Query$
' Returns the keyword portion of a query, stripping filter ops.
' ============================================================
SUB Test_Parse_Search_Query
    ' Plain keywords pass through unchanged
    CALL T_AssertStr(Parse_Search_Query$("hello world"), "hello world", _
        "ParseQuery: plain keywords unchanged")
    CALL T_AssertStr(Parse_Search_Query$("build app fast"), "build app fast", _
        "ParseQuery: three keywords unchanged")
    CALL T_AssertStr(Parse_Search_Query$("single"), "single", _
        "ParseQuery: single keyword unchanged")

    ' Filter operators are stripped
    CALL T_AssertStr(Parse_Search_Query$("build tag:game"), "build", _
        "ParseQuery: strips tag: filter, keeps keyword")
    CALL T_AssertStr(Parse_Search_Query$("build tag:game priority:high"), "build", _
        "ParseQuery: strips multiple filters, keeps keyword")
    CALL T_AssertStr(Parse_Search_Query$("build app tag:game priority:high fav:true"), "build app", _
        "ParseQuery: keywords mixed with filters")

    ' Query containing only filter operators -> empty
    CALL T_AssertStr(Parse_Search_Query$("priority:high"), "", _
        "ParseQuery: only priority filter -> empty string")
    CALL T_AssertStr(Parse_Search_Query$("fav:true"), "", _
        "ParseQuery: only fav filter -> empty string")
    CALL T_AssertStr(Parse_Search_Query$("tag:game fav:true"), "", _
        "ParseQuery: all filters, no keywords -> empty string")

    ' All named filter variants are stripped
    CALL T_AssertStr(Parse_Search_Query$("starred:yes idea"), "idea", _
        "ParseQuery: strips starred: filter")
    CALL T_AssertStr(Parse_Search_Query$("favorite:yes notes"), "notes", _
        "ParseQuery: strips favorite: filter")

    ' Whitespace handling
    CALL T_AssertStr(Parse_Search_Query$(""), "", _
        "ParseQuery: empty query -> empty string")
    CALL T_AssertStr(Parse_Search_Query$("  hello  "), "hello", _
        "ParseQuery: leading/trailing spaces trimmed")
END SUB

' ============================================================
' Extract_Search_Tokens$
' Returns pipe-delimited keyword tokens (filters removed).
' ============================================================
SUB Test_Extract_Search_Tokens
    ' Multiple keywords become pipe-delimited
    CALL T_AssertStr(Extract_Search_Tokens$("hello world"), "hello|world", _
        "ExtractTokens: two words -> pipe-delimited")
    CALL T_AssertStr(Extract_Search_Tokens$("build app fast"), "build|app|fast", _
        "ExtractTokens: three words -> pipe-delimited")

    ' Single keyword has no pipe
    CALL T_AssertStr(Extract_Search_Tokens$("single"), "single", _
        "ExtractTokens: single word -> no pipe")

    ' Empty input -> empty output
    CALL T_AssertStr(Extract_Search_Tokens$(""), "", _
        "ExtractTokens: empty query -> empty string")

    ' Filter operators removed before tokenising
    CALL T_AssertStr(Extract_Search_Tokens$("tag:game priority:high keyword"), "keyword", _
        "ExtractTokens: filter ops stripped, one keyword remains")
    CALL T_AssertStr(Extract_Search_Tokens$("tag:game priority:high"), "", _
        "ExtractTokens: only filter ops -> empty string")
    CALL T_AssertStr(Extract_Search_Tokens$("build tag:game"), "build", _
        "ExtractTokens: one keyword with filter")

    ' Multiple keywords mixed with filter ops
    CALL T_AssertStr(Extract_Search_Tokens$("build app tag:game fav:true"), "build|app", _
        "ExtractTokens: two keywords with filters")
END SUB

' ============================================================
' Extract_Search_Filters$
' Returns the value after a named filter operator.
' ============================================================
SUB Test_Extract_Search_Filters
    ' Standard operator values
    CALL T_AssertStr(Extract_Search_Filters$("build tag:game priority:high", "tag"), "game", _
        "ExtractFilters: tag: value extracted")
    CALL T_AssertStr(Extract_Search_Filters$("build tag:game priority:high", "priority"), "high", _
        "ExtractFilters: priority: value extracted")
    CALL T_AssertStr(Extract_Search_Filters$("fav:true search", "fav"), "true", _
        "ExtractFilters: fav: value extracted")
    CALL T_AssertStr(Extract_Search_Filters$("favorite:yes idea", "favorite"), "yes", _
        "ExtractFilters: favorite: value extracted")
    CALL T_AssertStr(Extract_Search_Filters$("starred:1", "starred"), "1", _
        "ExtractFilters: starred: value extracted")
    CALL T_AssertStr(Extract_Search_Filters$("priority:critical", "priority"), "critical", _
        "ExtractFilters: priority:critical -> critical")

    ' Filter not present -> empty string
    CALL T_AssertStr(Extract_Search_Filters$("build tag:game", "fav"), "", _
        "ExtractFilters: filter not present -> empty")
    CALL T_AssertStr(Extract_Search_Filters$("build app", "tag"), "", _
        "ExtractFilters: no filters at all -> empty")

    ' Case-insensitive prefix match (LCASE$ applied inside function)
    CALL T_AssertStr(Extract_Search_Filters$("TAG:upper idea", "tag"), "upper", _
        "ExtractFilters: uppercase TAG: -> value extracted")
    CALL T_AssertStr(Extract_Search_Filters$("PRIORITY:HIGH note", "priority"), "HIGH", _
        "ExtractFilters: uppercase PRIORITY: -> value extracted")

    ' Empty query
    CALL T_AssertStr(Extract_Search_Filters$("", "tag"), "", _
        "ExtractFilters: empty query -> empty")

    ' Operator present but with empty value: "tag:" -> ""
    CALL T_AssertStr(Extract_Search_Filters$("tag:", "tag"), "", _
        "ExtractFilters: tag: with empty value -> empty")

    ' Only one token that is NOT the target filter
    CALL T_AssertStr(Extract_Search_Filters$("priority:high", "tag"), "", _
        "ExtractFilters: other filter present, target absent -> empty")
END SUB
