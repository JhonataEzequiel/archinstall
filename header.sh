#!/bin/bash

source packages.sh

set_variables(){
    echo "Choose your installation method:"
    echo "1) Manual"
    echo "2) Gnome w/gaming packages and emulators"
    echo "3) Gnome without/gaming packages and emulators"
    echo "4) KDE w/gaming packages and emulators"
    echo "5) KDE without/gaming packages and emulators"
    echo "6) Exit"
    read -p "Enter 1-6: " mode

    if [[ ! "$mode" =~ ^[1-6]$ ]]; then
        echo "Invalid input. Please enter a number between 1 and 6."
        exit 1
    fi

    choiceTE=1
    choiceREND=1
    choiceTPKG=1
    choiceTTE=5
    choiceAUR=1
    choiceBR=1
    choiceSS=1
    choiceCA=2
    choiceCK=2

    case $mode in
        2)
            choiceDE=1
            choiceGM=1
            choiceEM=3
            ;;
        3)
            choiceDE=1
            choiceGM=2
            choiceEM=4
            ;;
        4)
            choiceDE=2
            choiceGM=1
            choiceEM=3
            ;;
        5)
            choiceDE=2
            choiceGM=2
            choiceEM=4
            ;;
        6)
            exit 1
            ;;
        *)
            ;;
    esac
    export mode choiceDE choiceTE choiceGM choiceEM choiceREND choiceTPKG choiceTTE choiceAUR choiceBR choiceSS choiceCA choiceCK
}