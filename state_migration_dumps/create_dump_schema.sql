drop schema if exists simple_dump_data cascade;
create schema simple_dump_data;

--
-- facilitie's
--
CREATE TABLE simple_dump_data.facilities as 
select * from public.facilities where state= 'West Bengal';

--
-- patients 
--
CREATE TABLE simple_dump_data.patients as 
SELECT * FROM public.patients
where assigned_facility_id in (select id from simple_dump_data.facilities);

--
-- appointments
--
CREATE TABLE simple_dump_data.appointments as 
SELECT * FROM public.appointments
where patient_id in (select id from simple_dump_data.patients);



-- select count(*) from simple_dump_data.patients;
-- select count(*) from public.patients;