#!/usr/bin/env bash

data=$(curl -s 'wttr.in/Stockholm?format=%C|%t')
condition=$(echo "$data" | cut -d'|' -f1 | xargs)
temp=$(echo "$data" | cut -d'|' -f2 | tr -d ' ')

condition_lower=$(echo "$condition" | tr '[:upper:]' '[:lower:]')

case "$condition_lower" in
  *"thunderstorm"*|*"thunder"*)       icon="󰖓" ;;
  *"heavy rain"*|*"heavy shower"*)    icon="󰖖" ;;
  *"light rain"*|*"light drizzle"*|*"patchy light rain"*|*"light shower"*) icon="󰖗" ;;
  *"rain"*|*"drizzle"*|*"shower"*)    icon="󰖖" ;;
  *"sleet"*)                          icon="󰙿" ;;
  *"blizzard"*|*"heavy snow"*)        icon="󰼶" ;;
  *"light snow"*|*"patchy light snow"*) icon="󰖘" ;;
  *"snow"*|*"ice"*)                   icon="󰖘" ;;
  *"mist"*|*"fog"*)                   icon="󰖑" ;;
  *"overcast"*)                       icon="󰖐" ;;
  *"partly cloudy"*|*"patchy"*)       icon="󰖕" ;;
  *"cloudy"*|*"cloud"*)               icon="󰖐" ;;
  *"clear"*|*"sunny"*)                icon="󰖙" ;;
  *)                                  icon="󰖐" ;;
esac

echo "$icon $temp"
