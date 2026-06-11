-- Seeds are idempotent. Safe to run multiple times (e.g. make fresh).
-- Fixed UUIDs for parent category rows allow reliable FK references in
-- 03_attribute_definitions.sql without subquery lookups.
-- Subcategory rows use uuid_generate_v4() — referenced in seed 03 via slug.
-- sort_order uses multiples of 10 — insert between items without renumbering.

BEGIN;

-- ============================================================
-- V1 SERVICE CATEGORIES (is_active = TRUE)
-- ============================================================

-- ------------------------------------------------------------
-- Crop Services
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000001', NULL, 'Crop Services', 'crop-services', TRUE, 10)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000001', 'Drone Seeding & Spraying',  'drone-seeding-spraying',  TRUE, 10),
    ('10000000-0000-0000-0000-000000000001', 'Crop Health Assessment',    'crop-health-assessment',  TRUE, 20),
    ('10000000-0000-0000-0000-000000000001', 'Farm Advisory',             'farm-advisory',           TRUE, 30),
    ('10000000-0000-0000-0000-000000000001', 'Land Preparation',          'land-preparation',        TRUE, 40)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Farm Inputs
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000002', NULL, 'Farm Inputs', 'farm-inputs', TRUE, 20)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000002', 'Seeds & Seedlings',          'seeds-seedlings',          TRUE, 10),
    ('10000000-0000-0000-0000-000000000002', 'Fertilisers',                'fertilisers',              TRUE, 20),
    ('10000000-0000-0000-0000-000000000002', 'Pesticides & Bio-controls',  'pesticides-bio-controls',  TRUE, 30),
    ('10000000-0000-0000-0000-000000000002', 'Compost & Manure',           'compost-manure',           TRUE, 40)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Equipment & Machinery
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000003', NULL, 'Equipment & Machinery', 'equipment-machinery', TRUE, 30)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000003', 'Equipment Rental',      'equipment-rental',      TRUE, 10),
    ('10000000-0000-0000-0000-000000000003', 'Equipment Repair',      'equipment-repair',      TRUE, 20),
    ('10000000-0000-0000-0000-000000000003', 'Equipment Sales',       'equipment-sales',       TRUE, 30),
    -- Heavy machinery operators (excavators, bulldozers, cranes) whose equipment
    -- may be hired for agricultural or adjacent uses (land clearing, borewell,
    -- construction on farm land).
    ('10000000-0000-0000-0000-000000000003', 'Heavy Machinery',       'heavy-machinery',       TRUE, 40),
    -- Lorries, flatbeds, tippers used for produce transport and equipment haulage.
    -- Operators often serve both agricultural and general commercial cargo.
    ('10000000-0000-0000-0000-000000000003', 'Commercial Vehicles',   'commercial-vehicles',   TRUE, 50)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Harvest Services
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000004', NULL, 'Harvest Services', 'harvest-services', TRUE, 40)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000004', 'Harvesting',               'harvesting',               TRUE, 10),
    ('10000000-0000-0000-0000-000000000004', 'Threshing & Processing',   'threshing-processing',     TRUE, 20),
    ('10000000-0000-0000-0000-000000000004', 'Post-harvest Handling',    'post-harvest-handling',    TRUE, 30)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Transport & Logistics
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000005', NULL, 'Transport & Logistics', 'transport-logistics', TRUE, 50)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    -- Renamed from "Crop Transport" — lorry operators serve both agricultural
    -- and general haulage. Name reflects actual service scope.
    ('10000000-0000-0000-0000-000000000005', 'Transport & Haulage',  'transport-haulage',   TRUE, 10),
    ('10000000-0000-0000-0000-000000000005', 'Cold Storage',         'cold-storage',        TRUE, 20),
    ('10000000-0000-0000-0000-000000000005', 'Warehouse Storage',    'warehouse-storage',   TRUE, 30)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Water & Irrigation
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000006', NULL, 'Water & Irrigation', 'water-irrigation', TRUE, 60)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000006', 'Drip Irrigation Setup',   'drip-irrigation-setup',   TRUE, 10),
    ('10000000-0000-0000-0000-000000000006', 'Sprinkler Systems',       'sprinkler-systems',       TRUE, 20),
    ('10000000-0000-0000-0000-000000000006', 'Borewell Services',       'borewell-services',       TRUE, 30),
    ('10000000-0000-0000-0000-000000000006', 'Water Pump Services',     'water-pump-services',     TRUE, 40)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Testing & Certification
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000007', NULL, 'Testing & Certification', 'testing-certification', TRUE, 70)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000007', 'Soil Testing',             'soil-testing',             TRUE, 10),
    ('10000000-0000-0000-0000-000000000007', 'Water Testing',            'water-testing',            TRUE, 20),
    ('10000000-0000-0000-0000-000000000007', 'Organic Certification',    'organic-certification',    TRUE, 30),
    ('10000000-0000-0000-0000-000000000007', 'Produce Quality Testing',  'produce-quality-testing',  TRUE, 40)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Finance & Advisory
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000008', NULL, 'Finance & Advisory', 'finance-advisory', TRUE, 80)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('10000000-0000-0000-0000-000000000008', 'Agricultural Loans',    'agricultural-loans',    TRUE, 10),
    ('10000000-0000-0000-0000-000000000008', 'Crop Insurance',        'crop-insurance',        TRUE, 20),
    ('10000000-0000-0000-0000-000000000008', 'Government Schemes',    'government-schemes',    TRUE, 30)
ON CONFLICT DO NOTHING;

-- ============================================================
-- V2 PRODUCE CATEGORIES (is_active = FALSE)
-- Seeded now so taxonomy is ready when V2 activates produce listings.
-- Flipping parent is_active = TRUE on launch is sufficient —
-- children are already present. Do not activate these for V1.
-- ============================================================

-- ------------------------------------------------------------
-- Grains & Cereals
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000001', NULL, 'Grains & Cereals', 'grains-cereals', FALSE, 100)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000001', 'Rice',    'rice',    FALSE, 10),
    ('20000000-0000-0000-0000-000000000001', 'Wheat',   'wheat',   FALSE, 20),
    ('20000000-0000-0000-0000-000000000001', 'Maize',   'maize',   FALSE, 30),
    ('20000000-0000-0000-0000-000000000001', 'Ragi',    'ragi',    FALSE, 40),
    ('20000000-0000-0000-0000-000000000001', 'Jowar',   'jowar',   FALSE, 50),
    ('20000000-0000-0000-0000-000000000001', 'Bajra',   'bajra',   FALSE, 60)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Spices
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000002', NULL, 'Spices', 'spices', FALSE, 110)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000002', 'Black Pepper',  'black-pepper',  FALSE, 10),
    ('20000000-0000-0000-0000-000000000002', 'Cardamom',      'cardamom',      FALSE, 20),
    ('20000000-0000-0000-0000-000000000002', 'Turmeric',      'turmeric',      FALSE, 30),
    ('20000000-0000-0000-0000-000000000002', 'Ginger',        'ginger',        FALSE, 40),
    ('20000000-0000-0000-0000-000000000002', 'Chilli',        'chilli',        FALSE, 50),
    ('20000000-0000-0000-0000-000000000002', 'Coriander',     'coriander',     FALSE, 60),
    ('20000000-0000-0000-0000-000000000002', 'Cumin',         'cumin',         FALSE, 70)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Fruits & Vegetables
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000003', NULL, 'Fruits & Vegetables', 'fruits-vegetables', FALSE, 120)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000003', 'Banana',       'banana',       FALSE, 10),
    ('20000000-0000-0000-0000-000000000003', 'Mango',        'mango',        FALSE, 20),
    ('20000000-0000-0000-0000-000000000003', 'Tomato',       'tomato',       FALSE, 30),
    ('20000000-0000-0000-0000-000000000003', 'Onion',        'onion',        FALSE, 40),
    ('20000000-0000-0000-0000-000000000003', 'Potato',       'potato',       FALSE, 50),
    ('20000000-0000-0000-0000-000000000003', 'Tapioca',      'tapioca',      FALSE, 60),
    ('20000000-0000-0000-0000-000000000003', 'Jackfruit',    'jackfruit',    FALSE, 70)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Dried Goods
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000004', NULL, 'Dried Goods', 'dried-goods', FALSE, 130)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000004', 'Dried Chilli',      'dried-chilli',      FALSE, 10),
    ('20000000-0000-0000-0000-000000000004', 'Dried Coconut',     'dried-coconut',     FALSE, 20),
    ('20000000-0000-0000-0000-000000000004', 'Tamarind',          'tamarind',          FALSE, 30),
    ('20000000-0000-0000-0000-000000000004', 'Dried Ginger',      'dried-ginger',      FALSE, 40),
    ('20000000-0000-0000-0000-000000000004', 'Pulses & Lentils',  'pulses-lentils',    FALSE, 50)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Plantation Crops
-- ------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000005', NULL, 'Plantation Crops', 'plantation-crops', FALSE, 140)
ON CONFLICT DO NOTHING;

INSERT INTO categories (parent_id, name, slug, is_active, sort_order) VALUES
    ('20000000-0000-0000-0000-000000000005', 'Coconut',       'coconut',       FALSE, 10),
    ('20000000-0000-0000-0000-000000000005', 'Rubber',        'rubber',        FALSE, 20),
    ('20000000-0000-0000-0000-000000000005', 'Coffee',        'coffee',        FALSE, 30),
    ('20000000-0000-0000-0000-000000000005', 'Tea',           'tea',           FALSE, 40),
    ('20000000-0000-0000-0000-000000000005', 'Arecanut',      'arecanut',      FALSE, 50),
    ('20000000-0000-0000-0000-000000000005', 'Cashew',        'cashew',        FALSE, 60)
ON CONFLICT DO NOTHING;

COMMIT;
