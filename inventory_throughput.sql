
-- committed resources by minute
CREATE OR REPLACE VIEW res_committed AS
    select count(*), date_trunc('minute', to_timestamp(itime/1000)) as timestamp  from rhq_resource where inventory_status='COMMITTED'  group by 2 order by timestamp;

-- committed wars by minute
CREATE OR REPLACE VIEW res_committed_war AS
    select count(*), date_trunc('minute', to_timestamp(itime/1000)) as timestamp  from rhq_resource where inventory_status='COMMITTED' and name like 'war%'  group by 2 order by timestamp; 



-- normalize time (all committed resources)
CREATE OR REPLACE VIEW res_committed_norm AS
    select count, extract(epoch from age(timestamp ,(select min(timestamp) from res_committed)))/60+1 as minute, timestamp 
  		from res_committed;

-- normalize time (committed war resources)
CREATE OR REPLACE VIEW res_committed_war_norm AS
        select count, extract(epoch from age(timestamp ,(select min(timestamp) from res_committed)))/60+1 as minute, timestamp
                from res_committed_war;


-- tabulate data for graphing
CREATE OR REPLACE VIEW import_throughput AS
    SELECT l.minute, COALESCE(r.count,0) as war, l.count-COALESCE(r.count,0) as other, l.count as total_committed,
       (l.timestamp-(select min(timestamp) from res_committed)) + interval '1 minute' as normalized_time, l.timestamp 
    FROM res_committed_norm l 
    LEFT OUTER JOIN res_committed_war_norm r ON (l.minute=r.minute);

COPY (SELECT * FROM import_throughput) TO '/tmp/inventory_throughput.csv' DELIMITER '|' CSV HEADER;

-- summary
SELECT (select sum(count) from res_committed_war) as total_war, (select sum(count) from res_committed) as total_committed;
