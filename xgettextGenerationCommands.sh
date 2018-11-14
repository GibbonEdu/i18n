#!/bin/bash

# ensure that realpath exists in the environment
# (compatibility with macos)
if ! which realpath 2>&1 >/dev/null; then
    # declare a bash function which functions as
    # normal realpath in bash
    function realpath() {
        [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
    }
fi

# Print usage messages. First argument being the name of
# the command.
function usage() {
    echo "Usage: $1 [OPTIONS]"
    echo "Extracts translatable text from GibbonEdu source code to generate the"
    echo "i18n folder containing mo/po files."
    echo
    echo "Options:"
    echo
    echo "-h            Displaying this message."
    echo
    echo "-l <locale>   Locale to process. If not specified, all existing locale"
    echo "              will be processed."
    echo
    echo "-o <folder>   Setting output folder. Supposedly the folder(s) to output"
    echo "              the mo/po files."
    echo "              (Default: $I18N_HOME)"
    echo
    echo "-s <folder>   Source code folder of GibbonEdu/core."
    echo "              (Default: $GIBBON_HOME)"
    echo
}

# declare locale code in the array
# in alphbetical order.
declare -a LOCALES=(
    "am_ET"
    "ar_SA"
    "bg_BG"
    "bn_BD"
    "da_DK"
    "de_DE"
    "el_GR"
    "en_GB"
    "en_US"
    "es_ES"
    "et_EE"
    "fa_IR"
    "fi_FI"
    "fr_FR"
    "he_IL"
    "hr_HR"
    "hu_HU"
    "id_ID"
    "in_OR"
    "it_IT"
    "ja_JP"
    "ka_GE"
    "ko_KP"
    "nl_NL"
    "no_NO"
    "om_ET"
    "pl_PL"
    "pt_BR"
    "pt_PT"
    "ro_RO"
    "ru_RU"
    "sq_AL"
    "sw_KE"
    "th_TH"
    "uk_UA"
    "ur_IN"
    "vi_VN"
    "zh_CN"
    "zh_HK"
)

# default variables
GIBBON_HOME="/Applications/MAMP/htdocs/github_gibbonEdu/core/"
I18N_HOME=$(dirname $(realpath $0))
COLS=$(tput cols)
LOGFILE=$PWD/$(basename -s .sh $0).log

if [ ! -d "$GIBBON_HOME" ]; then
    # if the system do not have that default home directory,
    # use the parent folder of this source code repository
    # as the Gibbon source code home.
    GIBBON_HOME=$(dirname $(dirname $(realpath $0)))
fi

# get options to override default variables
while getopts "hl:o:s:" ARG; do
    case $ARG in
        h)
            usage $0
            exit 0
            ;;
        l)
            LOCALE="$OPTARG"
            ;;
        o)
            I18N_HOME=$(realpath "$OPTARG")
            ;;
        s)
            GIBBON_HOME=$(realpath "$OPTARG")
            ;;
        *)
            usage $0
            exit 1
            ;;
    esac
done

if [ ! -d "$GIBBON_HOME" ]; then
    echo "\"$GIBBON_HOME\" is not a valid directory."
    exit 1
fi
if [ ! -d "$I18N_HOME" ]; then
    echo "\"$I18N_HOME\" is not a valid directory."
    exit 1
fi

# remove trailing slash from I18N_HOME
I18N_HOME=${I18N_HOME%/}

# go to the Gibbon installation home folder
OLD_PWD=$PWD
cd $GIBBON_HOME

# generate the locale
if [ "$LOCALE" != "" ]; then
    if [ ! -d "$I18N_HOME/$LOCALE" ]; then
        echo "\"$I18N_HOME/$LOCALE\" is not a valid directory."
        exit 1
    fi
    declare -a LOCALES=($LOCALE)
fi

# loop through all the specified locale to run
# text extractions and compile catalog to binary
# format.
echo -en "" > $LOGFILE
FAIL=0
for LOCALE in "${LOCALES[@]}"
do
    echo -e "\nlocale: $LOCALE\n-------------"

    echo -en "* generate locale text file (.po)\r"
    xgettext \
        --from-code=iso-8859-1 \
        --omit-header -j \
        --language=PHP \
        --keyword=__:1,1t \
        --keyword=__:2,2t \
        -o "$I18N_HOME/$LOCALE/LC_MESSAGES/gibbon.po" \
        $(find . -type f -name "*.php" ! -path "./lib/*" ! -path "./tests/*" ! -path "./vendor/*" ! -path "./.git/*" | sed 's/ /*/g') \
        2>>$LOGFILE >/dev/null
    if [ "$?" -eq 0 ]; then
        echo -e  "* generate locale text file (.po)\t\t\e[32m✓\e[0m"
    else
        echo -e  "* generate locale text file (.po)\t\t\e[31m✘\e[0m"
        FAIL=1
    fi

    echo -en "* generate locale binary file (.mo)\r"
    msgfmt --check-header --check-domain -v \
        -o "$I18N_HOME/$LOCALE/LC_MESSAGES/gibbon.mo" \
        "$I18N_HOME/$LOCALE/LC_MESSAGES/gibbon.po" \
        2>>$LOGFILE >/dev/null
    if [ "$?" -eq 0 ]; then
        echo -e  "* generate locale binary file (.mo)\t\t\e[32m✓\e[0m"
    else
        echo -e  "* generate locale binary file (.mo)\t\t\e[31m✘\e[0m"
        FAIL=1
    fi
done

# Show log, if needed
if [ $FAIL -eq 1 ]; then
    echo
    echo Failed
    echo ------
    cat $LOGFILE
    exit 1
fi

# return to original folder
cd $OLD_PWD
