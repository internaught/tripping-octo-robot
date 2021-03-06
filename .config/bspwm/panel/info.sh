#!/bin/bash
# info.sh
# Output information with formatted background colors in lemonbar format
# This script can take arguments for what bar information to display(meant to be the names of the functions)

# clickable area aliases
AC='%{A:'           # start click area
AB=':}'             # end click area cmd
AE='%{A}'           # end click area

icon() {
    echo -n -e "%{F$pIcon}\u$1 %{F$pFG}"
}

weather() {
    icon f0c2
    weatherURL='http://www.accuweather.com/en/us/san-antonio-tx/78205/weather-forecast/351198'
    wget -q -T 1 -O- "$weatherURL" | awk -F\' '/acm_RecentLocationsCarousel\.push/ {print $12"°F"; exit; }'
}

clock() {
    icon f017
    echo ${AC}'dzen_cal &'${AB}$(date '+%a, %b%e - %l:%M %p')${AE}
}

mail() {
    # todo: this
    icon f0e0
    echo '0'
}

battery() {
    BATC=/sys/class/power_supply/BAT0/capacity
    BATS=/sys/class/power_supply/BAT0/status
    icon f0e7
    if [ -f $BATC ]; then
        [ "`cat $BATS`" = "Charging" ] && echo -n '+' || echo -n '-'
        cat $BATC
    else
        #no battery information found.
        echo '+100'
    fi
}

volume() {
    display="$(icon f028) $(amixer get Master | sed -n 's/^.*\[\([0-9]\+%\).*$/\1/p')"
    command='termite -e "alsamixer"'
    echo ${AC}$command${AB}$display${AE}
}

network() {
    read lo int1 int2 <<< `ip link | sed -n 's/^[0-9]: \(.*\):.*$/\1/p'`
    if iwconfig $int1 >/dev/null 2>&1; then
        wifi=$int1
        eth0=$int2
    else
        wifi=$int2
        eth0=$int1
    fi
    ip link show $eth0 | grep 'state UP' >/dev/null && int=$eth0 ||int=$wifi
    icon f0ac
    echo $int
    ping -W 1 -c 1 8.8.8.8 >/dev/null 2>&1 &&
        echo -e '\uf00c' || echo -e '\uf00d'
}

mpd() {
    cur_song=$(basename "$(mpc current)" | sed "s/^\(.*\)\..*$/\1/")
    icon f025
    if [ -z "$cur_song" ]; then
        echo "Stopped"
    else
        paused=$(mpc | grep paused)
        [ -z "$paused" ] && toggle="${AC}mpc pause${AB}$(icon f04c)${AE}" ||
            toggle="${AC}mpc play${AB}$(icon f04b)${AE}"
        prev="${AC}mpc prev${AB}$(icon f049)${AE}"
        next="${AC}mpc next${AB}$(icon f050)${AE}"
        cur_song="${AC}${AB}$cur_song${AE}"
        echo "$cur_song $prev $toggle $next"
    fi
}

yaourtUpdates() {
    updates=$(eval yaourt -Qu | wc --lines)
    command='termite -e "yaourt -Syua"'
    echo ${AC}$command${AB}$(icon f062)$updates${AE}
}

themeSwitch() {
    cur_theme=$(grep THEME_NAME ~/.bspwm_theme | cut -c12-)
    icon f01e
    echo ${AC}'dzen_theme &'${AB}$cur_theme${AE}
}

#determine what to display based on arguments, unless there are none, then display all.
blockActive=false;
while :; do
    buf="S"

    [ -z "$*" ] && items="battery network weather clock themeSwitch" \
                || items="$@"

    for item in $items; do
        buf="${buf}$(block $($item))";
    done

    echo "$buf"
    sleep 2 # update interval
done
