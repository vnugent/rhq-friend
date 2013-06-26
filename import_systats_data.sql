DROP TABLE perf_vmstat;

CREATE TABLE perf_vmstat(
                     source char(5),
                     r  integer, 
                     b integer,
                     swpd integer, 
                     free integer,
                     buff integer,
                     cache integer,
                     si integer, 
                     so integer,
                     bi integer,
                     bo integer,
                     inz integer,
                     cs integer,
                     us integer,
                     sy integer,
                     id integer,
                     wa integer, 
                     st integer,
                     ts bigint
);

ALTER TABLE perf_vmstat OWNER TO rhqadmin;

COPY perf_vmstat FROM '/tmp/rhq-server-vmstat.csv' DELIMITERS ',' CSV;
COPY perf_vmstat FROM '/tmp/rhq-agent-vmstat.csv' DELIMITERS ',' CSV;
