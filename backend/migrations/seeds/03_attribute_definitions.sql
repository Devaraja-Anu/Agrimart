-- Seeds are idempotent. Safe to run multiple times (e.g. make fresh).
-- category_id references use subquery lookups by slug — subcategory UUIDs
-- are generated, not fixed. slug is the stable identifier.
-- Global attributes have category_id = NULL and apply to all listings.
-- sort_order uses multiples of 10.

BEGIN;

-- ============================================================
-- GLOBAL ATTRIBUTES (category_id = NULL)
-- Apply to all listings regardless of category.
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
VALUES
    (NULL, 'Languages Spoken', 'languages-spoken', 'multiselect',
        '["Malayalam", "Tamil", "Kannada", "Telugu", "Hindi", "English"]',
        NULL, FALSE, 10),

    (NULL, 'Years of Experience', 'years-of-experience', 'select',
        '["Less than 1 year", "1–3 years", "3–5 years", "5–10 years", "More than 10 years"]',
        NULL, FALSE, 20),

    (NULL, 'Payment Accepted', 'payment-accepted', 'multiselect',
        '["Cash", "UPI", "Bank Transfer", "Cheque"]',
        NULL, FALSE, 30)

ON CONFLICT DO NOTHING;

-- ============================================================
-- DRONE SEEDING & SPRAYING
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Service Type',        'drone-service-type',       'multiselect',
        '["Seeding", "Spraying", "Both"]',
        NULL, TRUE, 10),

    ('Coverage Capacity',   'drone-coverage-capacity',  'select',
        '["Up to 5 acres/day", "5–15 acres/day", "15–30 acres/day", "More than 30 acres/day"]',
        NULL, FALSE, 20),

    ('Drone Type',          'drone-type',               'select',
        '["Fixed-wing", "Multi-rotor", "Hybrid"]',
        NULL, FALSE, 30),

    ('Tank Capacity',       'drone-tank-capacity',      'select',
        '["Up to 10 litres", "10–16 litres", "16–25 litres", "More than 25 litres"]',
        'litres', FALSE, 40),

    ('Crops Serviced',      'drone-crops-serviced',     'multiselect',
        '["Paddy", "Sugarcane", "Cotton", "Vegetables", "Banana", "Coconut", "Other"]',
        NULL, FALSE, 50),

    ('DGCA Certified',      'drone-dgca-certified',     'boolean',
        NULL,
        NULL, FALSE, 60)  -- REVIEW: should DGCA certification be required = TRUE? Regulatory requirement for commercial drone ops.

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'drone-seeding-spraying'
ON CONFLICT DO NOTHING;

-- ============================================================
-- SOIL TESTING
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Test Type',               'soil-test-type',           'multiselect',
        '["Basic (NPK)", "Micronutrient", "pH & EC", "Organic Carbon", "Full Panel"]',
        NULL, TRUE, 10),

    ('Turnaround Time',         'soil-turnaround-time',     'select',
        '["Same day", "1–2 days", "3–5 days", "More than 5 days"]',
        NULL, FALSE, 20),

    ('Sample Collection',       'soil-sample-collection',   'boolean',
        NULL,
        NULL, FALSE, 30),  -- does the provider collect samples from the farm?

    ('Report Format',           'soil-report-format',       'multiselect',
        '["Physical report", "PDF via WhatsApp", "PDF via Email", "Online portal"]',
        NULL, FALSE, 40),

    ('Government Accredited',   'soil-govt-accredited',     'boolean',
        NULL,
        NULL, FALSE, 50)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'soil-testing'
ON CONFLICT DO NOTHING;

-- ============================================================
-- EQUIPMENT RENTAL
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Equipment Type',      'equip-rental-type',        'multiselect',
        '["Tractor", "Power Tiller", "Rotavator", "Harvester", "Transplanter", "Sprayer", "Pump Set", "Other"]',
        NULL, TRUE, 10),

    ('Pricing Period',      'equip-rental-pricing',     'select',
        '["Per hour", "Per day", "Per acre"]',
        NULL, FALSE, 20),  -- REVIEW: redundant with price_unit on listings? Consider removing.

    ('Operator Included',   'equip-rental-operator',    'boolean',
        NULL,
        NULL, FALSE, 30),

    ('Fuel Included',       'equip-rental-fuel',        'boolean',
        NULL,
        NULL, FALSE, 40),

    ('Delivery Available',  'equip-rental-delivery',    'boolean',
        NULL,
        NULL, FALSE, 50)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'equipment-rental'
ON CONFLICT DO NOTHING;

-- ============================================================
-- HEAVY MACHINERY
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Machinery Type',      'heavy-machinery-type',     'multiselect',
        '["Excavator", "Bulldozer", "Crane", "Backhoe Loader", "Motor Grader", "Compactor", "Other"]',
        NULL, TRUE, 10),

    ('Operator Included',   'heavy-machinery-operator', 'boolean',
        NULL,
        NULL, FALSE, 20),

    ('Min Hire Period',     'heavy-machinery-min-hire', 'select',
        '["Half day", "Full day", "Weekly"]',
        NULL, FALSE, 30)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'heavy-machinery'
ON CONFLICT DO NOTHING;

-- ============================================================
-- COMMERCIAL VEHICLES
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Vehicle Type',        'vehicle-type',             'select',
        '["Mini Lorry (up to 1T)", "Light Lorry (1–3T)", "Medium Lorry (3–7T)", "Heavy Lorry (7T+)", "Flatbed", "Tipper", "Container"]',
        NULL, TRUE, 10),

    ('Load Capacity',       'vehicle-load-capacity',    'select',
        '["Up to 1 tonne", "1–3 tonnes", "3–7 tonnes", "7–12 tonnes", "More than 12 tonnes"]',
        NULL, FALSE, 20),

    ('Driver Included',     'vehicle-driver-included',  'boolean',
        NULL,
        NULL, FALSE, 30),

    ('Refrigerated',        'vehicle-refrigerated',     'boolean',
        NULL,
        NULL, FALSE, 40)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'commercial-vehicles'
ON CONFLICT DO NOTHING;

-- ============================================================
-- TRANSPORT & HAULAGE
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Cargo Type',          'haulage-cargo-type',       'multiselect',
        '["Paddy & Grains", "Vegetables & Fruits", "Spices", "Fertilisers & Inputs", "Equipment", "General Cargo"]',
        NULL, FALSE, 10),

    ('Handling',            'haulage-handling',         'multiselect',
        '["Loading assistance", "Unloading assistance", "Weighing on site"]',
        NULL, FALSE, 20)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'transport-haulage'
ON CONFLICT DO NOTHING;

-- ============================================================
-- HARVESTING
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Harvest Method',      'harvest-method',           'multiselect',
        '["Manual", "Semi-mechanised", "Combine Harvester", "Reaper"]',
        NULL, TRUE, 10),

    ('Crops Handled',       'harvest-crops',            'multiselect',
        '["Paddy", "Wheat", "Sugarcane", "Vegetables", "Banana", "Coconut", "Other"]',
        NULL, FALSE, 20),

    ('Team Size',           'harvest-team-size',        'select',
        '["1–5 workers", "5–10 workers", "10–20 workers", "More than 20 workers"]',
        NULL, FALSE, 30)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'harvesting'
ON CONFLICT DO NOTHING;

-- ============================================================
-- COLD STORAGE
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Storage Capacity',    'cold-storage-capacity',    'select',
        '["Up to 5 tonnes", "5–20 tonnes", "20–50 tonnes", "50–100 tonnes", "More than 100 tonnes"]',
        NULL, FALSE, 10),

    ('Temperature Range',   'cold-storage-temp',        'select',
        '["0–4°C (fruits & vegetables)", "4–10°C (general produce)", "Below 0°C (frozen)"]',
        NULL, FALSE, 20),

    ('Produce Types',       'cold-storage-produce',     'multiselect',
        '["Fruits", "Vegetables", "Flowers", "Spices", "Dairy", "Meat & Fish", "Other"]',
        NULL, FALSE, 30),

    ('Min Storage Period',  'cold-storage-min-period',  'select',
        '["Daily", "Weekly", "Monthly"]',
        NULL, FALSE, 40),

    ('Loading Dock',        'cold-storage-dock',        'boolean',
        NULL,
        NULL, FALSE, 50)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'cold-storage'
ON CONFLICT DO NOTHING;

-- ============================================================
-- DRIP IRRIGATION SETUP
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('System Type',         'drip-system-type',         'multiselect',
        '["Drip Irrigation", "Sprinkler", "Micro-sprinkler", "Fogger"]',
        NULL, TRUE, 10),

    ('Coverage Capacity',   'drip-coverage',            'select',
        '["Up to 1 acre", "1–5 acres", "5–15 acres", "More than 15 acres"]',
        NULL, FALSE, 20),

    ('Brands Supplied',     'drip-brands',              'multiselect',
        '["Jain Irrigation", "Netafim", "Finolex", "Premier", "Other"]',
        NULL, FALSE, 30),  -- REVIEW: are these the dominant brands in Kerala/southern markets?

    ('AMC Available',       'drip-amc',                 'boolean',
        NULL,
        NULL, FALSE, 40),  -- Annual Maintenance Contract

    ('Subsidy Assistance',  'drip-subsidy',             'boolean',
        NULL,
        NULL, FALSE, 50)   -- helps farmer apply for govt drip irrigation subsidy

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'drip-irrigation-setup'
ON CONFLICT DO NOTHING;

-- ============================================================
-- ORGANIC CERTIFICATION
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Certification Body',  'organic-cert-body',        'multiselect',
        '["APEDA (India Organic)", "PGS-India", "NPOP", "EU Organic", "USDA NOP", "Other"]',
        NULL, TRUE, 10),

    ('Certification Type',  'organic-cert-type',        'multiselect',
        '["Farm Certification", "Processing Certification", "Group Certification"]',
        NULL, FALSE, 20),

    ('Typical Timeline',    'organic-cert-timeline',    'select',
        '["3–6 months", "6–12 months", "12–24 months", "More than 24 months"]',
        NULL, FALSE, 30),

    ('Farm Visits Included','organic-cert-visits',      'boolean',
        NULL,
        NULL, FALSE, 40)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'organic-certification'
ON CONFLICT DO NOTHING;

-- ============================================================
-- AGRICULTURAL LOANS
-- ============================================================

INSERT INTO attribute_definitions
    (category_id, name, slug, input_type, options, unit, is_required, sort_order)
SELECT
    c.id,
    v.name, v.slug, v.input_type::attribute_input_type, v.options::jsonb,
    v.unit, v.is_required, v.sort_order
FROM categories c
CROSS JOIN (VALUES
    ('Loan Type',           'loan-type',                'multiselect',
        '["Kisan Credit Card", "Crop Loan", "Equipment Loan", "Land Development Loan", "Allied Activities Loan", "Other"]',
        NULL, TRUE, 10),

    ('Institutions Covered','loan-institutions',        'multiselect',
        '["Nationalised Banks", "Regional Rural Banks", "Cooperative Banks", "NABARD Schemes", "Private Banks", "MFIs"]',
        NULL, FALSE, 20),

    ('Max Loan Amount',     'loan-max-amount',          'select',
        '["Up to ₹50,000", "₹50,000–₹2 lakh", "₹2–₹5 lakh", "₹5–₹10 lakh", "More than ₹10 lakh"]',
        NULL, FALSE, 30),

    ('Doorstep Service',    'loan-doorstep',            'boolean',
        NULL,
        NULL, FALSE, 40)

) AS v(name, slug, input_type, options, unit, is_required, sort_order)
WHERE c.slug = 'agricultural-loans'
ON CONFLICT DO NOTHING;

COMMIT;
