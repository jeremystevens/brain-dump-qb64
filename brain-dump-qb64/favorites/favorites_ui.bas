' favorites_ui.bas - Favorites system UI rendering
' Part of Brain Dump QB64 - Favorites / Starred Ideas System
' Responsibility: ALL screen rendering related to favorites.
'                 Calls favorites_manager for data — never stores anything.
'                 No file I/O. No business logic.
'$INCLUDEONCE

' ============================================================
' Favorites_RenderBadge
' Prints the favorite indicator inline when listing ideas.
' Favorited:     [*]
' Not favorited: [ ]
' Keeps columns aligned for clean retro display.
' ============================================================
SUB Favorites_RenderBadge (ideaLine AS STRING)
    IF Favorites_IsFavorite%(ideaLine) THEN
        PRINT "[*]";
    ELSE
        PRINT "[ ]";
    END IF
END SUB

' ============================================================
' Favorites_ShowLegend
' Prints a quick reference for the favorite indicator.
' Called from help screens or before selection prompts.
' ============================================================
SUB Favorites_ShowLegend
    PRINT "  Favorite Status:"
    PRINT "    [*] = Starred / Favorite idea"
    PRINT "    [ ] = Not starred"
    PRINT
END SUB

' ============================================================
' Favorites_SelectState%
' Interactive prompt — asks user whether to star the idea.
' Returns FAV_TRUE (-1) or FAV_FALSE (0).
' ============================================================
FUNCTION Favorites_SelectState%
    DIM inputStr AS STRING

    PRINT "  Star this idea as a favorite?"
    PRINT "    Y = [*] Yes, star it"
    PRINT "    N = [ ] No  (default)"
    PRINT
    INPUT "  Favorite (Y/N, or Enter for No): ", inputStr

    IF UCASE$(LEFT$(LTRIM$(inputStr), 1)) = "Y" THEN
        Favorites_SelectState = FAV_TRUE
    ELSE
        Favorites_SelectState = FAV_FALSE
    END IF
END FUNCTION
