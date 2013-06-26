-- committed resources by minute
CREATE OR REPLACE VIEW res_committed AS
    select count(*), date_trunc('minute', to_timestamp(itime/1000)) as timestamp  from rhq_resource where inventory_status='COMMITTED'  group by 2 order by timestamp;
    
-- normalize time (all committed resources)
CREATE OR REPLACE VIEW res_committed_norm AS
        select extract(epoch from age(timestamp ,(select min(timestamp) from res_committed)))/60+1 as minute, count, timestamp 
                from res_committed;
                
COPY (SELECT inv.minute, inv.count FROM res_committed_norm inv) TO '/tmp/inventory_throughput.csv' DELIMITER '|' CSV HEADER;

CREATE OR REPLACE VIEW inventory_with_sysstats AS
    SELECT res.timestamp, res.count, date_trunc('second', to_timestamp(vmstat.ts)) vmstat_ts, vmstat.* 
    FROM res_committed res 
    LEFT OUTER JOIN perf_vmstat vmstat 
    ON res.timestamp = date_trunc('minute', to_timestamp(vmstat.ts));


-- sync system statistics with inventory timestamp
CREATE OR REPLACE VIEW inventory_with_sysstats_norm AS
   SELECT 
        extract(epoch from age(inv.vmstat_ts, (select min(i.vmstat_ts) from inventory_with_sysstats i))) + 1 as sec,
        inv.*
    FROM inventory_with_sysstats inv
    ORDER BY inv.ts;
    
COPY (
    SELECT * FROM inventory_with_sysstats_norm WHERE source='rhq'
) 
TO '/tmp/vmstat_rhq.csv' DELIMITER '|' CSV HEADER;

COPY (
    SELECT * FROM inventory_with_sysstats_norm WHERE source='agent'
) 
TO '/tmp/vmstat_agent.csv' DELIMITER '|' CSV HEADER;
