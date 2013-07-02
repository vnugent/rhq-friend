DROP TABLE perf_gc CASCADE;

CREATE TABLE perf_gc(
		ts timestamp,                    
 		source char(20),
		type char(4),
                gc_time float8
);

ALTER TABLE perf_gc OWNER TO rhqadmin;

COPY perf_gc FROM '/tmp/rhq-server-gc.csv' DELIMITERS ',' CSV;
COPY perf_gc FROM '/tmp/rhq-agent-gc.csv' DELIMITERS ',' CSV;
