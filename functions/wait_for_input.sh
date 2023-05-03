#!/usr/bin/env bash

function wait_for_input {
    # Disable echo and special characters, set input timeout to 0.2 seconds.
    stty -echo -icanon time 1 || exit $?

    # String containing all keypresses.
    KEYS=""

    # Set field separator to BEL (should not occur in keypresses)
    IFS=$'\a'

    # Input loop.
    while true; do

        # Read more input from keyboard when necessary.
        while read -t 0 ; do
            read -s -r -d "" -N 1 -t 0.2 CHAR && KEYS="$KEYS$CHAR" || break
        done

        # If no keys to process, wait 0.01 seconds and retry.
        if [ -z "$KEYS" ]; then
            sleep 0.01
            return 
        fi

        # Check the first (next) keypress in the buffer.
        case "$KEYS" in
        $'\x1B\x5B\x41'*) # Up
            KEYS="${KEYS##???}"
            key_stroke="up"
            ;;
        $'\x1B\x5B\x42'*) # Down
            KEYS="${KEYS##???}"
            key_stroke="down"
            ;;
        $'\x1B\x5B\x44'*) # Left
            KEYS="${KEYS##???}"
            key_stroke="left"
            ;;
        $'\x1B\x5B\x43'*) # Right
            KEYS="${KEYS##???}"
            key_stroke="right"
            ;;
        $'\x1B\x4F\x48'*|$'\x1b\x5b\x48') # Home
            KEYS="${KEYS##???}"
            ;;
        $'\x1B\x5B\x31\x7E'*) # Home (Numpad)
            KEYS="${KEYS##????}"
            ;;
        $'\x1B\x4F\x46'*|$'\x1b\x5b\x46') # End
            KEYS="${KEYS##???}"
            ;;
        $'\x1B\x5B\x34\x7E'*) # End (Numpad)
            KEYS="${KEYS##????}"
            ;;
        $'\x1B\x5B\x45'*) # 5 (Numpad)
            KEYS="${KEYS#???}"
            ;;
        $'\x1B\x5B\x35\x7e'*) # PageUp
            KEYS="${KEYS##????}"
            key_stroke="page_up"
            ;;
        $'\x1B\x5B\x36\x7e'*) # PageDown
            KEYS="${KEYS##????}"
            key_stroke="page_down"
            ;;
        $'\x1B\x5B\x32\x7e'*) # Insert
            KEYS="${KEYS##????}"
            ;;
        $'\x1B\x5B\x33\x7e'*) # Delete
            KEYS="${KEYS##????}"
            ;;
        $'\r'*) # Return
            KEYS="${KEYS##?}"
            key_stroke="cancel"
            ;;
        $'\n'*) # Enter
            KEYS="${KEYS##?}"
            key_stroke="confirm"
            ;;
        $'\t'*) # Tab
            KEYS="${KEYS##?}"
            #echo "Tab"
            ;;
        $'\x1B') # Esc (without anything following!)
            KEYS="${KEYS##?}"
            key_stroke="cancel"
            #echo "Esc - Quitting"
            #exit 0
            ;;
        $'\x1B'*) # Unknown escape sequences
            echo -n "Unknown escape sequence (${#KEYS} chars): \$'"
            echo -n "$KEYS" | od --width=256 -t x1 | sed -e '2,99 d; s|^[0-9A-Fa-f]* ||; s| |\\x|g; s|$|'"'|"
            KEYS=""
            ;;
        [$'\x01'-$'\x1F'$'\x7F']*) # Consume control characters
            KEYS="${KEYS##?}"
            key_stroke="cancel"
            ;;
        *) # Printable characters.
            KEY="${KEYS:0:1}"
            KEYS="${KEYS#?}"

            case ${KEY} in   
                w) key_stroke="up" ;;
                a) key_stroke="left" ;;
                s) key_stroke="down" ;;
                d) key_stroke="right" ;;
                j) key_stroke="confirm" ;;
                k) key_stroke="cancel" ;;
                :) key_stroke="command" ;;
                *) key_stroke="" ;;
            esac
            ;;
        esac
    done
}