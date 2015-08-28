#!/usr/bin/env python3

import os
import babeltrace
from ctl import trace_dest

def getFolderSize(folder):
    total_size = os.path.getsize(folder)
    for item in os.listdir(folder):
        itempath = os.path.join(folder, item)
        if os.path.isfile(itempath):
            total_size += os.path.getsize(itempath)
        elif os.path.isdir(itempath):
            total_size += getFolderSize(itempath)
    return total_size

def find_metadata_dir(dir, fname='metadata'):
    for parent, dirs, files in os.walk(dir):
        if fname in files:
            return parent
    return None

trace = babeltrace.TraceCollection()
path = find_metadata_dir(trace_dest)
trace.add_trace(path, "ctf")

cnt = 0
for event in trace.events:
    cnt += 1

size = getFolderSize(trace_dest)
avg_ev_size = float(size) / cnt
print("{}".format({ 'count':cnt, 'size':size, 'avg':avg_ev_size }))
