#!/bin/bash
psql -U postgres -d rhq -f inventory_throughput_with_systats.sql
