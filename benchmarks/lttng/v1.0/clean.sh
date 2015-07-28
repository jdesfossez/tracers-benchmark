#!/bin/bash

shopt -s extglob

if [ "$(ls calibration)" != "calibrate.param" ]; then rm calibration/!(calibrate.param); fi
if [ "$(ls lttng | tr '\r\n' ' ')" != "figs lttng.param " ]; then 
	rm lttng/!(figs|lttng.param)
fi
if [ "$(ls lttng/figs/lost_events)" ]; then rm lttng/figs/lost_events/*; fi
if [ "$(ls lttng/figs/overhead)" ]; then rm lttng/figs/overhead/*; fi

shopt -u extglob
