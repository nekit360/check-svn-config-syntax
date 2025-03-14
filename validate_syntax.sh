#!/bin/bash

# Check the first line in block
check_block_line1() {
    [[ "$1" =~ ^\[([a-zA-Z0-9_:\/*]*[a-zA-Z0-9]|[a-zA-Z0-9_:\/]*:\/)\]$ ]] && [[ ! "$1" =~ \/$ ]] 
}

# Check the second line in block
check_block_line2() {
    [[ "$1" =~ ^@svn_prj_rw_[a-zA-Z0-9_]+\ =\ rw$ ]] 
}

# Check the third line in block
check_block_line3() {
    [[ "$1" =~ ^@svn_prj_ro_[a-zA-Z0-9_]+\ =\ r$ ]] 
}

# Check the fourth line in block
check_block_line4() {
    [[ "$1" =~ ^\*\ =\ (rw|r)?$ ]] || [[ "$1" =~ ^\*\ =$ ]] || [[ -z "$1" ]] }

# Validate a file
check_file() {
    local file="$1"
    local line_num=0
    local block_started=0  # 0-no block, 1-beginning, 2-line2, 3-line3, 4-line4
    local prev_line_empty=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Validate first tree lines
        if [ $line_num -le 3 ]; then
            case $line_num in
                1)
                    [[ "$line" != "[/]" ]] && { echo "Error 1: '[/]'"; return 1; } ;;
                2)
                    [[ "$line" != "* = r" ]] && { echo "Error 2: '* = r'"; return 1; } ;;
                3)
                    [[ -n "$line" ]] && { echo "Error 3: empty line"; return 1; } 
                    prev_line_empty=1 ;;
            esac
            continue
        fi

        # Check the blocks
        if [ -z "$line" ]; then
            # An empty line is only possible between blocks!
            if [ $block_started -eq 4 ] || [ $block_started -eq 3 ]; then
                # A block is completed
                block_started=0
                prev_line_empty=1
            elif [ $block_started -ne 0 ]; then
                echo "Error $line_num: an epty line inside a block!"
                return 1
            fi
        else
            if [ $block_started -eq 0 ]; then
                # Beginning of a new block
                check_block_line1 "$line" || { echo "Error $line_num: repository path"; return 1; }
                block_started=1
                prev_line_empty=0
            elif [ $block_started -eq 1 ]; then
                check_block_line2 "$line" || { echo "Error $line_num: line2"; return 1; }
                block_started=2
            elif [ $block_started -eq 2 ]; then
                check_block_line3 "$line" || { echo "Error $line_num: line3"; return 1; }
                block_started=3
            elif [ $block_started -eq 3 ]; then
                # 4-th line can be empty (considering a block as completed)
                if check_block_line4 "$line"; then
                    block_started=4
                else
                    echo "Error $line_num: line4"
                    return 1
                fi
            else
                echo "Error $line_num: extra lines"
                return 1
            fi
        fi
    done < "$file"

    # Check the completion of the last block
    if ! { [ $block_started -eq 3 ] || [ $block_started -eq 4 ] || [ $block_started -eq 0 ]; }; then
        echo "Error: the block is not completed"
        return 1
    fi

    echo "File syntax is correct."
    return 0
}

# Основной код
if [ $# -ne 1 ]; then
    echo "Использование: $0 <файл>"
    exit 1
fi

[ -f "$1" ] || { echo "Файл не найден"; exit 1; }

check_file "$1"
exit $?
