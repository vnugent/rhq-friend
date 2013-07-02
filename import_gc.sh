#!/bin/bash

awk '/Full GC \[/ {sub(/.$/, "", $1); print $1 ",agent,FULL," $12}' /tmp/rhq-agent-gc.log>/tmp/rhq-agent-gc.csv
awk '/Full GC \[/ {sub(/.$/, "", $1); print $1 ",rhq,FULL," $12}' /tmp/rhq-server-gc.log>/tmp/rhq-server-gc.csv
psql -U postgres -d rhq -f import_gc.sql
