-- find out agent_id
select id, name from rhq_agent;

-- resources by agent_id
select row_number() over (), r.id, r.name, (select h.name from rhq_resource h where h.id=r.parent_resource_id) as parent from rhq_resource r where r.agent_id=10011 order by r.parent_resource_id;
