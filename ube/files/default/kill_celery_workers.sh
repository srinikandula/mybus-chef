#!/usr/bin/env bash

set -x

ps auxww | grep '[c]elery.*worker'
if [[ "$?" == "0" ]]; then
    ps auxww | grep '[c]elery.*worker' | awk '{print $2}' | xargs kill
fi


exit 0