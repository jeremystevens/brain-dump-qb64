' favorites_manager.bas - Favorites system business logic
' Part of Brain Dump QB64 - Favorites / Starred Ideas System
' Responsibility: All favorite state logic, validation, file-format
'                 integration, filtering support, sorting support.
'                 NEVER renders UI. NEVER prints to screen.
' NOTE: CONST FAV_FALSE / FAV_TRUE declared in main.bas (global scope).
'       QB64 requires CONST before any SUB/FUNCTION in compiled unit.
'$INCLUDEONCE

' ============================================================
' Favorites_Init
' Called once at startup. Reserved for future work such as
' loading a favorites index or cache from disk.
' ============================================================
SUB Favorites_Init
    ' Reserved for future initialization
END SUB

' ============================================================
' Favorites_IsFavorite%
' Reads a raw idea line and returns FAV_TRUE (-1) if the line
' contains the fav:1 marker, FAV_FALSE (0) otherwise.
' Backward-compatible: old ideas without fav: return FAV_FALSE.
' ============================================================
FUNCTION Favorites_IsFavorite% (ideaLine AS STRING)
    IF INSTR(LCASE$(ideaLine), "fav:1") > 0 THEN
        Favorites_IsFavorite = FAV_TRUE
    ELSE
        Favorites_IsFavorite = FAV_FALSE
    END IF
END FUNCTION

' ============================================================
' Favorites_BuildTag$
' Returns the token written into ideas.txt for a favorite.
' Returns "fav:1" when enabled, "" when not (keeps file clean).
' ============================================================
FUNCTION Favorites_BuildTag$ (enabled AS INTEGER)
    IF enabled = FAV_TRUE THEN
        Favorites_BuildTag = "fav:1"
    ELSE
        Favorites_BuildTag = ""
    END IF
END FUNCTION

' ============================================================
' Favorites_GetWeight%
' Returns the search score bonus for a favorited idea.
' Spec: Favorite = +20
' Combined with priority weight for future weighted ranking.
' ============================================================
FUNCTION Favorites_GetWeight% (ideaLine AS STRING)
    IF Favorites_IsFavorite%(ideaLine) THEN
        Favorites_GetWeight = 20
    ELSE
        Favorites_GetWeight = 0
    END IF
END FUNCTION

' ============================================================
' Favorites_SortCompare%
' Compares two favorite states for sorting.
' Returns:  1 if a is favorite and b is not  (a sorts first)
'           0 if both equal
'          -1 if b is favorite and a is not  (b sorts first)
' Designed for favorites-first descending sort.
' ============================================================
FUNCTION Favorites_SortCompare% (a AS INTEGER, b AS INTEGER)
    IF a > b THEN
        Favorites_SortCompare = 1
    ELSEIF a < b THEN
        Favorites_SortCompare = -1
    ELSE
        Favorites_SortCompare = 0
    END IF
END FUNCTION
