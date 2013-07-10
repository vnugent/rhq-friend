-- committed resources by minute
DROP VIEW res_committed CASCADE;
CREATE OR REPLACE VIEW res_committed AS
    select count(*), date_trunc('minute', to_timestamp(itime/1000)) as timestamp  from rhq_resource where inventory_status='COMMITTED'  group by 2 order by timestamp;

ALTER TABLE res_committed OWNER TO rhqadmin;



-- normalize committed time
CREATE OR REPLACE VIEW res_committed_norm AS
        select extract(epoch from age(timestamp ,(select min(timestamp) from res_committed)))/60+1 as minute, count, timestamp 
                from res_committed;

ALTER TABLE res_committed_norm OWNER TO rhqadmin;

COPY (
    select minute*60 as sec, count, timestamp from res_committed_norm
) TO '/tmp/inventory_throughput_exp.csv' DELIMITER ',' CSV HEADER;



-- join inventory throughput with system statistics
DROP VIEW inventory_with_sysstats CASCADE;
CREATE OR REPLACE VIEW inventory_with_sysstats AS
    SELECT res.timestamp, COALESCE(res.count,0) AS count, date_trunc('second', to_timestamp(vmstat.ts)) vmstat_ts, vmstat.*
    FROM perf_vmstat vmstat
    LEFT OUTER JOIN res_committed res
    ON res.timestamp = date_trunc('minute', to_timestamp(vmstat.ts))
    WHERE  vmstat.ts >= (select extract(epoch from min(res_committed.timestamp)) from res_committed) AND
           vmstat.ts < (select extract(epoch from max(res_committed.timestamp + interval '5 minutes')) from res_committed);

ALTER TABLE inventory_with_sysstats OWNER TO rhqadmin;


-- sync system statistics with inventory timestamp
DROP VIEW inventory_with_sysstats_norm CASCADE;
CREATE OR REPLACE VIEW inventory_with_sysstats_norm AS
   SELECT
        extract(epoch from age(inv.vmstat_ts, (select min(i.vmstat_ts) from inventory_with_sysstats i))) + 1 as sec,
        inv.*
    FROM inventory_with_sysstats inv
    ORDER BY inv.ts;

ALTER TABLE inventory_with_sysstats_norm OWNER TO rhqadmin;

COPY (
    SELECT * FROM inventory_with_sysstats_norm WHERE source='rhq'
)
TO '/tmp/vmstat_server_exp.csv' DELIMITER ',' CSV HEADER;

COPY (
    SELECT * FROM inventory_with_sysstats_norm WHERE source='agent'
)
TO '/tmp/vmstat_agent_exp.csv' DELIMITER ',' CSV HEADER;




DROP VIEW perf_gc_inv CASCADE;

CREATE OR REPLACE VIEW perf_gc_inv AS
	SELECT gc.*
	FROM perf_gc gc
	WHERE  gc.ts >= (select min(res_committed.timestamp) from res_committed) AND
	       gc.ts < (select max(res_committed.timestamp + interval '5 minutes') from res_committed);

ALTER TABLE perf_gc_inv OWNER TO rhqadmin;


DROP VIEW perf_gc_inv_norm CASCADE;
CREATE OR REPLACE VIEW perf_gc_inv_norm AS 
 SELECT
        extract(epoch from age(gc.ts, (select min(i.timestamp) from res_committed_norm i))) + 1 as sec,
        gc.*
    FROM perf_gc_inv gc
    ORDER BY gc.ts;

ALTER TABLE perf_gc_inv_norm OWNER TO rhqadmin;


COPY (
select round(gc.sec) as sec, gc.ts, gc.type, gc.gc_time from perf_gc_inv_norm gc where source='agent' 
) TO '/tmp/gc_agent_exp.csv' DELIMITER ',' CSV HEADER;

COPY (
select round(gc.sec) as sec, gc.ts, gc.type, gc.gc_time from perf_gc_inv_norm gc where source='rhq'
) TO '/tmp/gc_server_exp.csv' DELIMITER ',' CSV HEADER;
