' sound_manager.bas - Centralized sound playback coordinator
' Part of Brain Dump QB64 - Retro Sound Design (Phase 2 P3)
' Responsibility: All SOUND/BEEP/PLAY statements live here.
'                 Routes sound events to the correct tone.
'                 Never called directly — retro_audio.bas
'                 provides named wrappers for all callers.
'                 NO rendering. NO business logic.
' NOTE: SND_* constants and SOUND_ENABLED declared in main.bas.
'       g_ActiveTheme shared var from theme_manager.bas.
'$INCLUDEONCE

' ============================================================
' Shared sound state
' ============================================================
' NOTE: g_SoundEnabled and g_SoundVolume are declared as
'       DIM SHARED in main.bas (global scope) — QB64 requires
'       DIM SHARED before any SUB/FUNCTION in compiled unit.

' ============================================================
' Sound_Init
' Called once at startup. Copies the compile-time constant
' into the runtime flag so it can be toggled at runtime.
' ============================================================
SUB Sound_Init
    g_SoundEnabled = SOUND_ENABLED
    g_SoundVolume  = 100
END SUB

' ============================================================
' Sound_IsEnabled%
' Returns -1 if sound is currently active, 0 if muted.
' ============================================================
FUNCTION Sound_IsEnabled%
    Sound_IsEnabled = g_SoundEnabled
END FUNCTION

' ============================================================
' Sound_Mute / Sound_Unmute
' Runtime toggle — does not affect the saved config.
' ============================================================
SUB Sound_Mute
    g_SoundEnabled = 0
END SUB

SUB Sound_Unmute
    g_SoundEnabled = -1
END SUB

' ============================================================
' Sound_SetVolume
' Future hook — stores volume level for future audio systems.
' QB64 SOUND does not support volume natively; reserved for
' future MIDI or WAV playback integration.
' ============================================================
SUB Sound_SetVolume (vol AS INTEGER)
    IF vol < 0   THEN vol = 0
    IF vol > 100 THEN vol = 100
    g_SoundVolume = vol
END SUB

' ============================================================
' Sound_Stop
' Stops any currently playing background PLAY music.
' Safe to call even if nothing is playing.
' ============================================================
SUB Sound_Stop
    IF NOT g_SoundEnabled THEN EXIT SUB
    PLAY "MF"    ' MF = Music Foreground, stops background play
END SUB

' ============================================================
' Sound_Play
' THE single gateway for all audio output in the application.
' Routes a SND_* event constant to the correct SOUND call,
' choosing tone variants based on the active theme.
'
' Tone parameters:
'   SOUND freq, duration
'   freq     = Hz (37-32767)
'   duration = clock ticks (18.2 ticks/sec)
'              1 tick ≈ 55ms | 2 ≈ 110ms | 4 ≈ 220ms
'
' Theme tone profiles:
'   THEME_FALLOUT   — warm, lower frequencies, analog feel
'   THEME_DOS       — sharp, mid-high PC speaker tones
'   THEME_CYBERDECK — synth, multi-tone digital pulses
' ============================================================
SUB Sound_Play (soundEvent AS INTEGER)
    IF NOT g_SoundEnabled THEN EXIT SUB

    SELECT CASE soundEvent

        ' ---- Keypress / typing tick -------------------------
        CASE SND_KEYPRESS
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS       : SOUND 1200, 1
                CASE THEME_CYBERDECK : SOUND 900,  1
                CASE ELSE            : SOUND 440,  1   ' Fallout warm tick
            END SELECT

        ' ---- Menu navigation move ---------------------------
        CASE SND_MENU_MOVE
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS       : SOUND 800,  1
                CASE THEME_CYBERDECK : SOUND 1100, 1
                CASE ELSE            : SOUND 330,  1
            END SELECT

        ' ---- Confirm / success ------------------------------
        CASE SND_CONFIRM
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS
                    SOUND 880, 2
                    SOUND 1100, 2
                CASE THEME_CYBERDECK
                    SOUND 1200, 1
                    SOUND 1600, 2
                    SOUND 2000, 1
                CASE ELSE   ' Fallout
                    SOUND 440, 2
                    SOUND 550, 3
            END SELECT

        ' ---- Error / invalid --------------------------------
        CASE SND_ERROR
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS
                    SOUND 200, 3
                    SOUND 150, 3
                CASE THEME_CYBERDECK
                    SOUND 180, 2
                    SOUND 100, 4
                CASE ELSE   ' Fallout
                    SOUND 220, 4
                    SOUND 180, 3
            END SELECT

        ' ---- Notification / result found --------------------
        CASE SND_NOTIFY
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS
                    SOUND 660,  2
                    SOUND 880,  2
                CASE THEME_CYBERDECK
                    SOUND 1400, 1
                    SOUND 1800, 1
                    SOUND 2200, 2
                CASE ELSE   ' Fallout
                    SOUND 330,  2
                    SOUND 440,  3
            END SELECT

        ' ---- Boot line beep (one per boot line) -------------
        CASE SND_BOOT_BEEP
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS       : SOUND 1000, 1
                CASE THEME_CYBERDECK : SOUND 1500, 1
                CASE ELSE            : SOUND 370,  1
            END SELECT

        ' ---- System ready chime (multi-note) ----------------
        CASE SND_READY
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS
                    PLAY "MB T180 L16 C E G > C"
                CASE THEME_CYBERDECK
                    PLAY "MB T220 L16 > C E G > C"
                CASE ELSE   ' Fallout — warm ascending tone
                    PLAY "MB T120 L8 A B > C"
            END SELECT

        ' ---- Export complete --------------------------------
        CASE SND_EXPORT
            SELECT CASE g_ActiveTheme
                CASE THEME_DOS
                    SOUND 880, 2
                    SOUND 1320, 3
                CASE THEME_CYBERDECK
                    SOUND 1600, 1
                    SOUND 2000, 1
                    SOUND 1600, 2
                CASE ELSE
                    SOUND 440, 2
                    SOUND 660, 3
            END SELECT

        ' ---- Theme changed ----------------------------------
        CASE SND_THEME_CHANGE
            ' This plays in the NEW theme's style — called
            ' after Theme_Apply so g_ActiveTheme is already set
            PLAY "MB T200 L16 C E G > C"

    END SELECT
END SUB
