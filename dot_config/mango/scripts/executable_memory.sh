#!/bin/sh
# Used/total RAM in GiB (MemAvailable accounts for reclaimable cache).
awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END {
    if (t > 0) printf "%.1fG\n", (t - a) / 1048576
    else print "--"
}' /proc/meminfo
