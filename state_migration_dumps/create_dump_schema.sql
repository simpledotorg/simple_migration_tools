drop schema if exists simple_dump_data cascade;
create schema simple_dump_data;

--
-- facilities
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
where patient_id in (select id from simple_dump_data.patients)
and facility_id in (select id from simple_dump_data.facilities); -- Doing both to ensure FK will be satisfied

--
-- addresses 
--
CREATE TABLE simple_dump_data.addresses as 
SELECT * FROM public.addresses
where id in (select address_id from simple_dump_data.patients);

--
-- blood_pressures
--
CREATE TABLE simple_dump_data.blood_pressures as 
SELECT * FROM public.blood_pressures
where patient_id in (select id from simple_dump_data.patients)
and facility_id in (select id from simple_dump_data.facilities); -- Doing both to ensure FK will be satisfied

--
-- blood_sugars
--
CREATE TABLE simple_dump_data.blood_sugars as 
SELECT * FROM public.blood_sugars
where patient_id in (select id from simple_dump_data.patients)
and facility_id in (select id from simple_dump_data.facilities); -- Doing both to ensure FK will be satisfied

--
-- protocol_drugs
-- 
CREATE TABLE simple_dump_data.protocol_drugs as 
SELECT * FROM public.protocol_drugs



