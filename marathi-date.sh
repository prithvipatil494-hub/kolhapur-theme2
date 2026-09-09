#!/usr/bin/env bash
# Marathi date/time for Waybar custom module
# Place at: ~/.config/waybar/scripts/marathi-date.sh
# chmod +x it after copying.

days=(रविवार सोमवार मंगळवार बुधवार गुरुवार शुक्रवार शनिवार)
months=(जानेवारी फेब्रुवारी मार्च एप्रिल मे जून जुलै ऑगस्ट सप्टेंबर ऑक्टोबर नोव्हेंबर डिसेंबर)

# Devanagari digit conversion (set to 0 if you'd rather keep normal 1,2,3 numerals)
USE_DEVANAGARI_DIGITS=1

to_devanagari() {
    local input="$1"
    if [ "$USE_DEVANAGARI_DIGITS" = "1" ]; then
        echo "$input" | tr '0123456789' '०१२३४५६७८९'
    else
        echo "$input"
    fi
}

dow=$(date +%u)       # 1 (Mon) - 7 (Sun)
day=$(date +%-d)
month=$(date +%-m)
year=$(date +%Y)
hour24=$(date +%-H)
min=$(date +%M)

# 12-hour clock + Marathi time-of-day word
if   [ "$hour24" -ge 4  ] && [ "$hour24" -lt 12 ]; then period="सकाळी"
elif [ "$hour24" -ge 12 ] && [ "$hour24" -lt 16 ]; then period="दुपारी"
elif [ "$hour24" -ge 16 ] && [ "$hour24" -lt 20 ]; then period="सायंकाळी"
else period="रात्री"
fi

hour12=$((hour24 % 12))
[ "$hour12" -eq 0 ] && hour12=12

day_name=${days[$((dow % 7))]}
month_name=${months[$((month - 1))]}

date_str="$day_name, $(to_devanagari "$day") $month_name $(to_devanagari "$year")"
time_str="$(to_devanagari "$hour12"):$(to_devanagari "$min") $period"

echo "$date_str  |  $time_str"
