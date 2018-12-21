#!/bin/bash
g++ -lpulse pulsetest.cc -o pulsetest
cp pulsetest /usr/local/bin/
echo "copy and enable the service."
