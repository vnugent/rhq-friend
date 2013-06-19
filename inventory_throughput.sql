-- committed resources by minute
CREATE OR REPLACE VIEW res_committed AS
    select count(*), date_trunc('minute', to_timestamp(itime/1000)) as timestamp  from rhq_resource where inventory_status='COMMITTED'  group by 2 order by timestamp;

-- normalize time (all committed resources)
CREATE OR REPLACE VIEW res_committed_norm AS
        select count, extract(epoch from age(timestamp ,(select min(timestamp) from res_committed)))/60+1 as minute, timestamp
                from res_committed;

-- select * from res_committed_norm;

COPY (SELECT * FROM res_committed_norm) TO '/tmp/inventory_throughput.csv' DELIMITER '|' CSV HEADER;

SELECT  (select sum(count) from res_committed) as total_committed;
