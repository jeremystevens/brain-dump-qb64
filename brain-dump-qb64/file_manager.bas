' file_manager.bas - File operations for Idea Catcher
'$INCLUDEONCE

' Initialize the system and create ideas file if needed
SUB InitializeSystem
    DIM testFile AS INTEGER
    
    ' Try to open ideas.txt, create if doesn't exist
    testFile = FREEFILE
    OPEN "ideas.txt" FOR APPEND AS testFile
    CLOSE testFile
    
    PRINT "System initialized. Ideas file ready."
    SLEEP 1
END SUB

' Get current timestamp string
FUNCTION GetTimestamp$
    DIM timeStr AS STRING
    DIM dateStr AS STRING
    
    timeStr = TIME$
    dateStr = DATE$
    
    GetTimestamp = "[" + dateStr + " " + timeStr + "]"
END FUNCTION

' Write a new idea to file
SUB WriteIdeaToFile (ideaText AS STRING, tags AS STRING)
    DIM fileNum AS INTEGER
    DIM timestamp AS STRING
    DIM fullEntry AS STRING
    
    fileNum = FREEFILE
    timestamp = GetTimestamp$
    
    ' Format: [timestamp] idea_text | tags
    fullEntry = timestamp + " " + ideaText
    IF tags <> "" THEN
        fullEntry = fullEntry + " | " + tags
    END IF
    
    OPEN "ideas.txt" FOR APPEND AS fileNum
    PRINT #fileNum, fullEntry
    CLOSE fileNum
    
    PRINT "Idea saved successfully!"
END SUB

' Count total number of ideas in file
FUNCTION CountIdeas
    DIM fileNum AS INTEGER
    DIM lineText AS STRING
    DIM count AS INTEGER
    
    count = 0
    fileNum = FREEFILE
    
    ' Check if file exists by trying to open it
    OPEN "ideas.txt" FOR INPUT AS fileNum
    
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN count = count + 1
    WEND
    
    CLOSE fileNum
    CountIdeas = count
END FUNCTION

' Read all ideas from file
SUB ReadAllIdeas
    DIM fileNum AS INTEGER
    DIM lineText AS STRING
    DIM count AS INTEGER
    
    fileNum = FREEFILE
    count = 0
    
    OPEN "ideas.txt" FOR INPUT AS fileNum
    
    WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            count = count + 1
            PRINT STR$(count) + ". " + lineText
        END IF
    WEND
    
    CLOSE fileNum
    
    IF count = 0 THEN
        PRINT "No ideas found. Start writing some!"
    END IF
END SUB