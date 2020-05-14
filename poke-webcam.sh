#!/bin/bash

v4l2-ctl -d /dev/video2 -c gain_automatic=1
sleep 20
v4l2-ctl -d /dev/video2 -c gain_automatic=0

