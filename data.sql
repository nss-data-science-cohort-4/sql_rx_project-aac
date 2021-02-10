/*NOTE Note that some zip codes will be associated with multiple fipscounty 
values in the zip_fips table. To resolve this, use the fipscounty with the 
highest tot_ratio for each zipcode.*/

--MAYBE: drugs that are administered as anti opioids

--Which Tennessee counties had a disproportionately high number of opioid prescriptions?
/* We want...
-the state of TN
-opioid drug names
-number prescribed
-population
-county names*/

WITH opioids AS (SELECT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y'),
--don't need generic name as it returns same number of rows.

TNdocs AS (SELECT npi, nppes_provider_zip5
FROM prescriber
WHERE nppes_provider_state = 'TN'),

opioids_prescribed AS (SELECT npi, SUM(total_claim_count) AS number_prescribed
FROM prescription
JOIN opioids
USING (drug_name)
GROUP BY npi),

opioids_TNdocs AS (SELECT number_prescribed, nppes_provider_zip5
FROM opioids_prescribed
JOIN TNdocs
USING (npi)),

counties AS (SELECT zip, fipscounty, SUM(number_prescribed) AS number_prescribed
FROM zip_fips AS z
JOIN opioids_TNdocs AS o
ON z.zip = o.nppes_provider_zip5
GROUP BY zip, fipscounty),

counties2 AS (SELECT county, fipscounty, number_prescribed
FROM fips_county
JOIN counties
USING (fipscounty))

SELECT county, (number_prescribed/population) AS opioids_per_person
FROM population
JOIN counties2
USING (fipscounty)
ORDER BY opioids_per_person DESC;

--Is there an association between rates of opioid prescriptions and overdose deaths by county?
/*What I want...
-overdose_deaths table (has fips county):
	do this for the year 2017 since that's the year these prescription stats are for
	already filtered on TN
-fips_county table (to get county name)
-*/


WITH opioids AS (SELECT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y'),
--don't need generic name as it returns same number of rows.

TNdocs AS (SELECT npi, nppes_provider_zip5
FROM prescriber
WHERE nppes_provider_state = 'TN'),

opioids_prescribed AS (SELECT npi, SUM(total_claim_count) AS number_prescribed
FROM prescription
JOIN opioids
USING (drug_name)
GROUP BY npi),

opioids_TNdocs AS (SELECT number_prescribed, nppes_provider_zip5
FROM opioids_prescribed
JOIN TNdocs
USING (npi)),

counties AS (SELECT zip, fipscounty, SUM(number_prescribed) AS number_prescribed
FROM zip_fips AS z
JOIN opioids_TNdocs AS o
ON z.zip = o.nppes_provider_zip5
GROUP BY zip, fipscounty),

counties2 AS (SELECT county, fipscounty, number_prescribed
FROM fips_county
JOIN counties
USING (fipscounty)),

overdoses AS (SELECT SUM(overdose_deaths) AS deaths, fipscounty
FROM overdose_deaths
WHERE year = 2017
GROUP BY fipscounty),

overdoses_c AS (SELECT county, deaths
FROM fips_county
JOIN overdoses
USING (fipscounty))

SELECT SUM(number_prescribed) AS num_prescribed, county, deaths
FROM overdoses_c
JOIN counties2
USING (county)
GROUP BY county, deaths
ORDER BY deaths DESC




--Is there any association between a particular type of opioid and number of overdose deaths?