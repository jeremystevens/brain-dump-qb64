' idea_manager.bas - Core idea management functions
'$INCLUDEONCE

' Write a new idea (main interface)
SUB WriteNewIdea
    DIM ideaText AS STRING
    DIM tags AS STRING
    
    CLS
    PRINT "=== WRITE NEW IDEA ==="
    PRINT
    PRINT "Enter your idea (press Enter when done):"
    LINE INPUT ideaText
    
    IF LTRIM$(ideaText) = "" THEN
        PRINT "No idea entered. Returning to menu..."
        SLEEP 2
        EXIT SUB
    END IF
    
    PRINT
    PRINT "Add tags (optional, like #project #dream #reminder):"
    LINE INPUT tags
    
    CALL WriteIdeaToFile(ideaText, tags)
    PRINT "Press any key to continue..."
    SLEEP
END SUB

' Review all ideas
SUB ReviewIdeas
    DIM totalIdeas AS INTEGER
    
    CLS
    PRINT "=== REVIEW IDEAS ==="
    PRINT
    
    totalIdeas = CountIdeas
    PRINT "Total ideas: "; totalIdeas
    PRINT STRING$(40, "=")
    PRINT
    
    CALL ReadAllIdeas
    
    PRINT
    PRINT "Press any key to return to menu..."
    SLEEP
END SUB

' Search for ideas by tag
SUB SearchByTag
    DIM searchTag AS STRING
    DIM fileNum AS INTEGER
    DIM lineText AS STRING
    DIM count AS INTEGER
    DIM found AS INTEGER
    
    CLS
    PRINT "=== SEARCH BY TAG ==="
    PRINT
    INPUT "Enter tag to search for (without #): ", searchTag
    
    IF searchTag = "" THEN
        PRINT "No tag entered. Returning to menu..."
        SLEEP 2
        EXIT SUB
    END IF
    
    ' Add # if not provided
    IF LEFT$(searchTag, 1) <> "#" THEN
        searchTag = "#" + searchTag
    END IF
    
    PRINT
    PRINT "Searching for: "; searchTag
    PRINT STRING$(40, "=")
    PRINT
    
    fileNum = FREEFILE
    count = 0
    found = 0
    
    OPEN "ideas.txt" FOR INPUT AS fileNum
    
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            count = count + 1
            ' Check if tag exists in the line (case insensitive)
            IF INSTR(UCASE$(lineText), UCASE$(searchTag)) > 0 THEN
                found = found + 1
                PRINT STR$(count) + ". " + lineText
            END IF
        END IF
    WEND
    
    CLOSE fileNum
    
    IF found = 0 THEN
        PRINT "No ideas found with tag: "; searchTag
    ELSE
        PRINT
        PRINT "Found "; found; " idea(s) with tag: "; searchTag
    END IF
    
    PRINT
    PRINT "Press any key to return to menu..."
    SLEEP
END SUB

' Delete an idea (placeholder for now)
SUB DeleteIdea
    CLS
    PRINT "=== DELETE IDEA ==="
    PRINT
    PRINT "Delete functionality coming soon!"
    PRINT "For now, you can manually edit 'ideas.txt' file."
    PRINT
    PRINT "Press any key to return to menu..."
    SLEEP
END SUB