#!/bin/bash
ttymidi -s /dev/ttyAMA2 -b 38400 -v &

aconnect 129:1 130:0

aconnect 130:0 129:1

