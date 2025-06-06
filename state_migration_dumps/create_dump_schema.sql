drop schema if exists simple_dump_data cascade;
create schema simple_dump_data;

--
-- facilities
--
CREATE TABLE simple_dump_data.facilities AS
SELECT * FROM public.facilities WHERE state = 'West Bengal';

--
-- patients 
--
CREATE TABLE simple_dump_data.patients AS
SELECT * FROM public.patients
WHERE assigned_facility_id IN (SELECT id FROM simple_dump_data.facilities);

-- In case of cross state migration of patients
UPDATE simple_dump_data.patients
SET registration_facility_id = assigned_facility_id 
WHERE registration_facility_id NOT IN (SELECT id FROM simple_dump_data.facilities);

--
-- appointments
--
CREATE TABLE simple_dump_data.appointments AS
SELECT * FROM public.appointments
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities); -- Doing both to ensure FK will be satisfied

--
-- addresses 
--
CREATE TABLE simple_dump_data.addresses AS
SELECT * FROM public.addresses
WHERE id IN (SELECT address_id FROM simple_dump_data.patients);

--
-- blood_pressures
--
CREATE TABLE simple_dump_data.blood_pressures AS
SELECT * FROM public.blood_pressures
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities); -- Doing both to ensure FK will be satisfied

--
-- blood_sugars
--
CREATE TABLE simple_dump_data.blood_sugars AS
SELECT * FROM public.blood_sugars
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities); -- Doing both to ensure FK will be satisfied

--
-- protocol_drugs
-- 
CREATE TABLE simple_dump_data.protocol_drugs AS
SELECT * FROM public.protocol_drugs;

--
-- ar_internal_metadata
--
CREATE TABLE simple_dump_data.ar_internal_metadata AS
SELECT * FROM public.ar_internal_metadata;

--
-- patient_phone_numbers
--
CREATE TABLE simple_dump_data.patient_phone_numbers AS
SELECT * FROM public.patient_phone_numbers WHERE patient_id IN (SELECT id FROM simple_dump_data.patients);

--
-- call_logs
--
CREATE TABLE simple_dump_data.call_logs AS
SELECT * FROM public.call_logs WHERE callee_phone_number IN
  (SELECT number from simple_dump_data.patient_phone_numbers WHERE patient_id IN (SELECT id FROM simple_dump_data.patients));

--
-- call_results
--
CREATE TABLE simple_dump_data.call_results AS
SELECT * FROM public.call_results
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities)
AND appointment_id IN (SELECT id FROM simple_dump_data.appointments); -- Doing all to ensure FK will be satisfied


--
-- clean_medicine_to_dosages
--
CREATE TABLE simple_dump_data.clean_medicine_to_dosages AS
SELECT * FROM public.clean_medicine_to_dosages;

--
-- configurations
--
CREATE TABLE simple_dump_data.configurations AS
SELECT * FROM public.configurations WHERE name = 'bsnl_sms_jwt';

--
-- data_migrations
--
CREATE TABLE simple_dump_data.data_migrations AS
SELECT * FROM public.data_migrations;

--
-- drug_stocks
--
CREATE TABLE simple_dump_data.drug_stocks AS
SELECT * FROM public.drug_stocks WHERE facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- encounters
--
CREATE TABLE simple_dump_data.encounters AS
SELECT * FROM public.encounters
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- exotel_phone_number_details
--
CREATE TABLE simple_dump_data.exotel_phone_number_details AS
SELECT * FROM public.exotel_phone_number_details
WHERE patient_phone_number_id in (SELECT id FROM simple_dump_data.patient_phone_numbers);

--
-- facilities_teleconsultation_medical_officers
--
CREATE TABLE simple_dump_data.facilities_teleconsultation_medical_officers AS
SELECT * FROM public.facilities_teleconsultation_medical_officers
WHERE facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- facility_business_identifiers
--
CREATE TABLE simple_dump_data.facility_business_identifiers AS
SELECT * FROM public.facility_business_identifiers
WHERE facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- facility_groups
--
CREATE TABLE simple_dump_data.facility_groups AS
SELECT * FROM public.facility_groups
WHERE id IN (SELECT DISTINCT facility_group_id FROM simple_dump_data.facilities);

--
-- flipper_features
--
CREATE TABLE simple_dump_data.flipper_features AS
SELECT * FROM public.flipper_features;

--
-- flipper_gates
--
CREATE TABLE simple_dump_data.flipper_gates AS
SELECT * FROM public.flipper_gates;

--
-- medical_histories
--
CREATE TABLE simple_dump_data.medical_histories AS
SELECT * FROM public.medical_histories
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients);

--
-- medicine_purposes
--
CREATE TABLE simple_dump_data.medicine_purposes AS
SELECT * FROM public.medicine_purposes;

--
-- observations
--
CREATE TABLE simple_dump_data.observations AS
SELECT * FROM public.observations
WHERE encounter_id IN (SELECT id FROM simple_dump_data.encounters);

--
-- organizations
--
CREATE TABLE simple_dump_data.organizations AS
SELECT * FROM public.organizations WHERE name = 'IHCI';

--
-- patient_attributes
--
CREATE TABLE simple_dump_data.patient_attributes AS
SELECT * FROM public.patient_attributes
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients);

--
-- patient_business_identifiers
--
CREATE TABLE simple_dump_data.patient_business_identifiers AS
SELECT * FROM public.patient_business_identifiers
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients);

--
-- passport_authentications
--
CREATE TABLE simple_dump_data.passport_authentications AS
SELECT * FROM public.passport_authentications
WHERE patient_business_identifier_id IN (SELECT id FROM simple_dump_data.patient_business_identifiers);

--
-- phone_number_authentications
--
CREATE TABLE simple_dump_data.phone_number_authentications AS
SELECT * FROM public.phone_number_authentications
WHERE registration_facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- prescription_drugs
--
CREATE TABLE simple_dump_data.prescription_drugs AS
SELECT * FROM public.prescription_drugs
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- protocols
--
CREATE TABLE simple_dump_data.protocols AS
SELECT * FROM public.protocols WHERE name = 'West Bengal';

--
-- questionnaires
--
CREATE TABLE simple_dump_data.questionnaires AS
SELECT * FROM public.questionnaires;

--
-- questionnaire_responses
--
CREATE TABLE simple_dump_data.questionnaire_responses AS
SELECT * FROM public.questionnaire_responses
WHERE questionnaire_id IN (SELECT id FROM simple_dump_data.questionnaires)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- raw_to_clean_medicines
--
CREATE TABLE simple_dump_data.raw_to_clean_medicines AS
SELECT * FROM public.raw_to_clean_medicines;

--
-- regions
--
CREATE TABLE simple_dump_data.regions AS
WITH REF AS (SELECT path FROM public.regions WHERE name ='West Bengal')
SELECT * FROM public.regions
WHERE path @> (SELECT path FROM REF)
OR path <@ (SELECT path FROM REF);

--
-- schema_migrations
--
CREATE TABLE simple_dump_data.schema_migrations AS
SELECT * FROM public.schema_migrations;

--
-- teleconsultations
--
CREATE TABLE simple_dump_data.teleconsultations AS
SELECT * FROM public.teleconsultations
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND facility_id IN (SELECT id FROM simple_dump_data.facilities);

--
-- treatment_group_memberships
--
CREATE TABLE simple_dump_data.treatment_group_memberships AS
SELECT * FROM public.treatment_group_memberships
WHERE patient_id IN (SELECT id FROM simple_dump_data.patients)
AND appointment_id IN (SELECT id FROM simple_dump_data.appointments);

--
-- treatment_groups
--
CREATE TABLE simple_dump_data.treatment_groups AS
SELECT * FROM public.treatment_groups
WHERE id IN (SELECT DISTINCT treatment_group_id FROM simple_dump_data.treatment_group_memberships);

--
-- estimated_populations
--
CREATE TABLE simple_dump_data.estimated_populations AS
SELECT * FROM public.estimated_populations
WHERE region_id IN (SELECT id FROM simple_dump_data.regions);

--
-- deduplication_logs
--
CREATE TABLE simple_dump_data.deduplication_logs AS
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.patient_phone_numbers)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.patient_phone_numbers))
AND record_type = 'PatientPhoneNumber'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.patient_business_identifiers)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.patient_business_identifiers))
AND record_type = 'PatientBusinessIdentifier'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.patients)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.patients))
AND record_type = 'Patient'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.prescription_drugs)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.prescription_drugs))
AND record_type = 'PrescriptionDrug'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.blood_sugars)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.blood_sugars))
AND record_type = 'BloodSugar'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.blood_pressures)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.blood_pressures))
AND record_type = 'BloodPressure'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.observations)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.observations))
AND record_type = 'Observation'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.addresses)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.addresses))
AND record_type = 'Address'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.teleconsultations)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.teleconsultations))
AND record_type = 'Teleconsultation'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.appointments)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.appointments))
AND record_type = 'Appointment'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.encounters)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.encounters))
AND record_type = 'Encounter'
UNION
SELECT * FROM public.deduplication_logs
WHERE (deleted_record_id IN (SELECT id::text FROM simple_dump_data.medical_histories)
  OR deduped_record_id IN (SELECT id::text FROM simple_dump_data.medical_histories))
AND record_type = 'MedicalHistory';

--
-- accesses
--
CREATE TABLE simple_dump_data.accesses AS
SELECT * FROM public.accesses
WHERE resource_id IN (SELECT id FROM simple_dump_data.facilities)
OR resource_id IN (SELECT id FROM simple_dump_data.facility_groups)
OR resource_id IN (SELECT id FROM simple_dump_data.organizations);

--
-- users
--
CREATE TABLE simple_dump_data.users AS
SELECT * FROM public.users
WHERE id IN (SELECT DISTINCT user_id FROM simple_dump_data.accesses)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.appointments)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.blood_pressures)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.blood_sugars)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.call_results)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.deduplication_logs)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.drug_stocks)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.facilities_teleconsultation_medical_officers)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.medical_histories)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.observations)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.patient_attributes)
OR id IN (SELECT DISTINCT medical_officer_id FROM simple_dump_data.teleconsultations)
OR id IN (SELECT DISTINCT requested_medical_officer_id FROM simple_dump_data.teleconsultations)
OR id IN (SELECT DISTINCT requester_id FROM simple_dump_data.teleconsultations)
OR id IN (SELECT DISTINCT user_id FROM simple_dump_data.prescription_drugs)
UNION
SELECT * FROM users WHERE access_level = 'power_user';

--
-- user_authentications
--
CREATE TABLE simple_dump_data.user_authentications AS
SELECT * FROM public.user_authentications
WHERE user_id IN (SELECT id FROM simple_dump_data.users);

--
-- email_authentications
--
CREATE TABLE simple_dump_data.email_authentications AS
SELECT * FROM public.email_authentications
WHERE id IN (SELECT authenticatable_id FROM simple_dump_data.user_authentications
  WHERE authenticatable_type = 'EmailAuthentication');

--
-- reminder_templates
--
CREATE TABLE simple_dump_data.reminder_templates AS
SELECT * FROM public.reminder_templates
WHERE treatment_group_id IN (SELECT id FROM simple_dump_data.treatment_groups);

--
-- experiments
--
CREATE TABLE simple_dump_data.experiments AS
SELECT * FROM public.experiments
WHERE id IN (SELECT DISTINCT experiment_id FROM simple_dump_data.treatment_groups);

--
-- notifications
--
CREATE TABLE simple_dump_data.notifications AS
SELECT * FROM public.notifications
WHERE patient_id IN (SELECT id from simple_dump_data.patients)
AND reminder_template_id IN (SELECT id from simple_dump_data.reminder_templates)
AND experiment_id IN (SELECT id from simple_dump_data.experiments);

--
-- communications
--
CREATE TABLE simple_dump_data.communications AS
SELECT * FROM public.communications
WHERE (notification_id in (SELECT id FROM simple_dump_data.notifications)
AND appointment_id IN (SELECT id FROM simple_dump_data.appointments))
OR (appointment_id IS NULL AND notification_id IN (SELECT id FROM notifications))
OR (notification_id IS NULL AND appointment_id IN (SELECT id FROM appointments));

--
-- twilio_sms_delivery_details
--
CREATE TABLE simple_dump_data.twilio_sms_delivery_details AS
SELECT * FROM public.twilio_sms_delivery_details
WHERE id IN (SELECT detailable_id FROM simple_dump_data.communications WHERE detailable_type = 'TwilioSmsDeliveryDetail');

--
-- bsnl_delivery_details
--
CREATE TABLE simple_dump_data.bsnl_delivery_details AS
SELECT * FROM public.bsnl_delivery_details
WHERE id IN (SELECT detailable_id FROM simple_dump_data.communications WHERE detailable_type = 'BsnlDeliveryDetail');

-- Creating sequences

DO $$
DECLARE
  start_val bigint;
BEGIN
  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.bsnl_delivery_details;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.bsnl_delivery_details_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.call_logs;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.call_logs_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.facility_business_identifiers;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.facility_business_identifiers_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.flipper_features;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.flipper_features_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.flipper_gates;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.flipper_gates_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.observations;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.observations_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.passport_authentications;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.passport_authentications_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.treatment_group_memberships;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.treatment_group_memberships_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);

  SELECT COALESCE(MAX(id), 0) + 1 INTO start_val FROM simple_dump_data.twilio_sms_delivery_details;

  EXECUTE format('
    CREATE SEQUENCE simple_dump_data.twilio_sms_delivery_details_id_seq
    START WITH %s
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
', start_val);
END $$;
