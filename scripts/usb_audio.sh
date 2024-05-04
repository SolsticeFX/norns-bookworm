#!/bin/bash

alsa_in -d hw:0,0 &
alsa_out -d hw:0,0 &
jack_connect alsa_in:capture_1 crone:input_1
jack_connect alsa_in:capture_1 crone:input_2
jack_connect crone:output_1 alsa_out:playback_1
jack_connect crone:output_2 alsa_out:playback_2
jack_connect system:capture_1 alsa_out:playback_3
jack_connect system:capture_2 alsa_out:playback_4

#a2jmidid -ue &

