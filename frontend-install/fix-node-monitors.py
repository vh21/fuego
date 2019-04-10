#!/usr/bin/python
# fix-node-monitors.py turns off some features in Jenkins' nodeMonitors.xml
# file
#  Specifically, it changes the 'ignored' status to 'true' for the
# following monitors:
#    DiskSpaceMonitor
#    SwapSpaceMonitor
#    TemporarySpaceMonitor
#
# It does not use XML parsing, because that's a pain. (tm)
#
# Usage: fix-node-monitors.py <xml-file>
#
# entry looks like:
#   <hudson.node__monitors.DiskSpaceMonitor>
#      <ignored>false</ignored>
#      <freeSpaceThreshold>1GB</freeSpaceThreshold>
#   </hudson.node__monitors.DiskSpaceMonitor>
#

import os
import sys
import re

def usage(rcode):
    print("Usage: fix-node-monitors.py <xml-file>")
    sys.exit(rcode)

try:
    filename = sys.argv[1]
except:
    print("Error: missing nodeMonitors.xml file path argument")
    usage(1)

if filename == "-h" or filename == "--help":
    usage(0)

if not os.path.exists(filename):
    print("Error: missing file - cannot open %s" % filename)
    usage(1)

lines = open(filename).readlines()

monitors_to_ignore = ["DiskSpaceMonitor",
        "SwapSpaceMonitor",
        "TemporarySpaceMonitor"]

monitor_re = "<hudson.node__monitors.([a-zA-Z]*)>"

cur_monitor = None
new_lines = []
for line in lines:
    # keep track of current monitor node
    m = re.search(monitor_re, line)
    if m:
        cur_monitor = m.group(1)
        #print("cur_monitor=", cur_monitor)

    new_line = line
    if "<ignored>" in line and cur_monitor in monitors_to_ignore:
        print("Setting %s to be ignored" % cur_monitor)
        new_line = line.replace('false', 'true')
    new_lines.append(new_line)

with open(filename, "w") as fd:
    fd.write("".join(new_lines))
