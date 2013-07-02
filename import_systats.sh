#!/bin/bash
psql -U postgres -d rhq -f import_systats_data.sql
