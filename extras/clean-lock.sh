#!/bin/bash

find /root/.config -name "lock-*" | xargs rm -f
rm -rf /opt/scripts/lock-*
