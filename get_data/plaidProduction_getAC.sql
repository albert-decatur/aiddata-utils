COPY
(
	SELECT 
	-- internal project IDs
	p.id AS plaidProduction_id
	-- donor project IDs
	,p.donor_project_id as donor_project_id
	,p.donor_secondary_project_id as donor_secondary_project_id
	-- donor info
	,donor.id as donor_id
	,donor.name as donor_name
	,donor.iso3 as donor_iso3
	-- recipient info
	,recipient.id as recipient_id
	,recipient.name as recipient_name
	,recipient.iso3 as recipient_iso3
	-- date fields
	,p.start_date
	,p.end_date
	,p.commitment_date
	,p.effective_date
	,p.year
	-- financials
	-- how to get deflated values?
	,project_amount.value as commitment_currentUSD
	-- get tite,short, and long without newlines, carriage returns, or tabs
	,regexp_replace(p.title, E'[\\n\\r\\t]+', ' ', 'g' ) AS title
	,regexp_replace(p.short_description, E'[\\n\\r\\t]+', ' ', 'g' ) AS short_description
	,regexp_replace(p.long_description, E'[\\n\\r\\t]+', ' ', 'g' ) AS long_description
	-- CRS purpose code
	,cfv.value as crs_purpose_code
	-- AidData purpose code
	,purpose_code.code as aiddata_purpose_code
	-- pipe separated AidData activity codes
	,array_to_string(array_agg(distinct(c.code)),'|') as aiddata_activity_codes

	FROM
	project AS p
	-- pick up CRS purpose codes
	INNER JOIN custom_field_value AS cfv ON p.id = cfv.project_id
	-- pick up is_master to determine arbitration
	INNER JOIN code_round AS r ON p.ID = r.project_id
	-- pick up AidData purpose codes
	INNER JOIN purpose_code ON r.purpose_code_id = purpose_code."id"
	-- need this to join to crs_code to eventually get AidData activity codes
	INNER JOIN code_round_crs_code AS crcc ON r.ID = crcc.code_round_id
	-- pick up AidData activity codes
	INNER JOIN crs_code AS c ON crcc.crs_code_id = c."id"
	-- pick up recipients
	INNER JOIN recipient ON p.recipient_id = recipient."id"
	-- pick up donors
	INNER JOIN donor ON p.donor_id = donor."id"
	-- pick up commitments in current USD
	INNER JOIN project_amount ON p.id = project_amount.project_id

	WHERE
	-- this field_id number is needed to ensure CRS purpose codes are being used
	cfv.field_id = 4735940
	-- -- ensure govt purpose code
	-- AND cfv.value ~ '^(15)' 
	-- make sure has arbitration
	AND r.is_master = TRUE
	-- get activity codes
	AND crcc.crs_code_id = c.id
	-- -- ensure year less than equal to 2008
	-- AND p.year <= 2008
	-- get *commitments* in current USD
	AND project_amount.amount_type_id = '1'	
	-- group by code rule
	GROUP BY p.id,p.title,p.short_description,p.long_description,cfv.value,purpose_code.code,recipient.id,donor.id,project_amount.value
)
TO STDOUT
-- -- export to text file with tab delimiters
-- WITH DELIMITER '	'
-- keep column header
CSV HEADER
