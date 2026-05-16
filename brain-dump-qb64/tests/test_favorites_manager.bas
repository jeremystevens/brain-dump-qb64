' test_favorites_manager.bas - Unit tests for favorites_manager.bas
' Covers: Favorites_IsFavorite%, Favorites_BuildTag$,
'         Favorites_GetWeight%, Favorites_SortCompare%
'$INCLUDEONCE

' ============================================================
' TestSuite_FavoritesManager — master entry point
' ============================================================
SUB TestSuite_FavoritesManager
    CALL T_BeginSuite("FavoritesManager")
    CALL Test_Favorites_IsFavorite
    CALL Test_Favorites_BuildTag
    CALL Test_Favorites_GetWeight
    CALL Test_Favorites_SortCompare
END SUB

' ============================================================
' Favorites_IsFavorite%
' ============================================================
SUB Test_Favorites_IsFavorite
    ' Lines containing "fav:1" are favorites (FAV_TRUE = -1)
    CALL T_AssertInt(Favorites_IsFavorite%("[01-01-2025 12:00:00] idea | #tag fav:1"), FAV_TRUE, _
        "IsFavorite: line with fav:1 -> FAV_TRUE")
    CALL T_AssertInt(Favorites_IsFavorite%("[01-01-2025 12:00:00] idea | priority:3 fav:1"), FAV_TRUE, _
        "IsFavorite: fav:1 after priority tag -> FAV_TRUE")
    CALL T_AssertInt(Favorites_IsFavorite%("simple idea fav:1"), FAV_TRUE, _
        "IsFavorite: fav:1 in plain text -> FAV_TRUE")

    ' LCASE$ normalises the search — uppercase variant also matches
    CALL T_AssertInt(Favorites_IsFavorite%("idea FAV:1 in uppercase"), FAV_TRUE, _
        "IsFavorite: FAV:1 uppercase -> FAV_TRUE")

    ' Lines without fav:1 return FAV_FALSE (0)
    CALL T_AssertInt(Favorites_IsFavorite%("[01-01-2025 12:00:00] idea | #tag"), FAV_FALSE, _
        "IsFavorite: no fav marker -> FAV_FALSE")
    CALL T_AssertInt(Favorites_IsFavorite%("[01-01-2025 12:00:00] idea | fav:0"), FAV_FALSE, _
        "IsFavorite: fav:0 is not fav:1 -> FAV_FALSE")
    CALL T_AssertInt(Favorites_IsFavorite%("fav:2 is not a starred idea"), FAV_FALSE, _
        "IsFavorite: fav:2 without fav:1 -> FAV_FALSE")
    CALL T_AssertInt(Favorites_IsFavorite%(""), FAV_FALSE, _
        "IsFavorite: empty string -> FAV_FALSE")

    ' Substring safety: "fav:10" contains "fav:1" as a substring -> matches
    CALL T_AssertInt(Favorites_IsFavorite%("idea | fav:10"), FAV_TRUE, _
        "IsFavorite: fav:10 contains fav:1 substring -> FAV_TRUE")
END SUB

' ============================================================
' Favorites_BuildTag$
' ============================================================
SUB Test_Favorites_BuildTag
    ' FAV_TRUE (-1) produces the file marker
    CALL T_AssertStr(Favorites_BuildTag$(FAV_TRUE), "fav:1", _
        "BuildTag: FAV_TRUE -> fav:1")

    ' FAV_FALSE (0) produces no tag (keeps file clean)
    CALL T_AssertStr(Favorites_BuildTag$(FAV_FALSE), "", _
        "BuildTag: FAV_FALSE -> empty string")

    ' Any value other than FAV_TRUE (-1) produces no tag
    CALL T_AssertStr(Favorites_BuildTag$(1), "", _
        "BuildTag: 1 (not FAV_TRUE) -> empty string")
    CALL T_AssertStr(Favorites_BuildTag$(-2), "", _
        "BuildTag: -2 (not FAV_TRUE) -> empty string")
END SUB

' ============================================================
' Favorites_GetWeight%
' ============================================================
SUB Test_Favorites_GetWeight
    ' Favorited ideas receive a +20 search-score bonus
    CALL T_AssertInt(Favorites_GetWeight%("[01-01-2025 12:00:00] idea | fav:1"), 20, _
        "GetWeight: line with fav:1 -> 20")
    CALL T_AssertInt(Favorites_GetWeight%("[01-01-2025 12:00:00] idea | priority:3 fav:1"), 20, _
        "GetWeight: fav:1 with priority -> 20")

    ' Non-favorited ideas contribute 0
    CALL T_AssertInt(Favorites_GetWeight%("[01-01-2025 12:00:00] idea | #tag"), 0, _
        "GetWeight: non-favorited idea -> 0")
    CALL T_AssertInt(Favorites_GetWeight%(""), 0, _
        "GetWeight: empty string -> 0")
END SUB

' ============================================================
' Favorites_SortCompare%
' ============================================================
SUB Test_Favorites_SortCompare
    ' NOTE: FAV_TRUE = -1, FAV_FALSE = 0.
    ' The comparison is purely numeric: a > b => 1, a < b => -1, equal => 0.
    ' Because FAV_TRUE (-1) < FAV_FALSE (0), a FAV_TRUE argument yields -1
    ' when a < b. Callers that want favorites-first sort should reverse the
    ' result or pass arguments in the (b, a) order.

    CALL T_AssertInt(Favorites_SortCompare%(FAV_FALSE, FAV_TRUE), 1, _
        "SortCompare: FAV_FALSE (0) > FAV_TRUE (-1) -> 1")
    CALL T_AssertInt(Favorites_SortCompare%(FAV_TRUE, FAV_FALSE), -1, _
        "SortCompare: FAV_TRUE (-1) < FAV_FALSE (0) -> -1")
    CALL T_AssertInt(Favorites_SortCompare%(FAV_TRUE, FAV_TRUE), 0, _
        "SortCompare: FAV_TRUE = FAV_TRUE -> 0")
    CALL T_AssertInt(Favorites_SortCompare%(FAV_FALSE, FAV_FALSE), 0, _
        "SortCompare: FAV_FALSE = FAV_FALSE -> 0")
END SUB
