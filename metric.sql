-- Active Metric collection schedule (excluding availability check and non-inventoried resources)
SELECT 
	s.id,
	s.coll_interval/1000 as interval,
	d.name as metric,
	r.name as resource
FROM 
	rhq_measurement_sched s, 
	rhq_resource r, 
	rhq_measurement_def d  
WHERE
	s.resource_id=r.id 
	and s.enabled='t' 
	and s.definition=d.id 
	and r.inventory_status='COMMITTED' 
	and d.name not like '%availability' 
ORDER BY
	s.coll_interval;

-- metric count per interval
SELECT 
	s.coll_interval/1000 as interval, 
	count(s.*) 
FROM
	rhq_measurement_sched s,
	rhq_resource r, 
	rhq_measurement_def d  
WHERE
	s.resource_id=r.id 
	and s.enabled='t' 
	and s.definition=d.id 
	and r.inventory_status='COMMITTED' 
	and d.name not like '%availability' 
	and d.name not like '%Trait%'
GROUP BY s.coll_interval
ORDER BY   s.coll_interval;



-- Metrics in rollup table
SELECT to_timestamp(m.time_stamp/1000) as ts, m.value, m.minValue, m.maxValue, s.coll_interval, d.name as metric, r.name as resource
FROM
  rhq_measurement_data_num_1h m,
  rhq_measurement_sched s, 
  rhq_resource r, 
  rhq_measurement_def d
WHERE
   m.schedule_id=s.id
   and s.resource_id=r.id 
   and s.enabled='t' 
   and s.definition=d.id 
   and r.inventory_status='COMMITTED' 
ORDER BY
	m.time_stamp,
	m.schedule_id,
	r.id;


-- Metrics count per minute
SELECT
	date_trunc('minute', to_timestamp(time_stamp/1000)) as timestamp, count(*)
FROM
	RHQ_MEAS_DATA_NUM_R04 m
GROUP BY
	1
ORDER BY
	1;



-- Metrics in Raw table
SELECT to_timestamp(m.time_stamp/1000) as ts, m.value, s.coll_interval, d.name as metric, r.name as resource
FROM
  RHQ_MEAS_DATA_NUM_R04 m,
  rhq_measurement_sched s, 
  rhq_resource r, 
  rhq_measurement_def d
WHERE
   m.schedule_id=s.id
   and s.resource_id=r.id 
   and s.enabled='t' 
   and s.definition=d.id 
   and r.inventory_status='COMMITTED' 
ORDER BY
	m.time_stamp,
	m.schedule_id,
	r.id;
