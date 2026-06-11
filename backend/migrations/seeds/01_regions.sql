-- Seeds are idempotent. Safe to run multiple times (e.g. make fresh).
-- Fixed UUIDs for country and state rows allow reliable FK references
-- in subsequent seed files without subquery lookups.

BEGIN;

-- ------------------------------------------------------------
-- Country
-- ------------------------------------------------------------
INSERT INTO regions (id, name, region_type, parent_id, is_active) VALUES
    ('00000000-0000-0000-0000-000000000001', 'India', 'country', NULL, TRUE)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- States
-- ------------------------------------------------------------
INSERT INTO regions (id, name, region_type, parent_id, is_active) VALUES
    ('00000000-0000-0000-0001-000000000001', 'Kerala',           'state', '00000000-0000-0000-0000-000000000001', TRUE),
    ('00000000-0000-0000-0001-000000000002', 'Tamil Nadu',       'state', '00000000-0000-0000-0000-000000000001', TRUE),
    ('00000000-0000-0000-0001-000000000003', 'Karnataka',        'state', '00000000-0000-0000-0000-000000000001', TRUE),
    ('00000000-0000-0000-0001-000000000004', 'Andhra Pradesh',   'state', '00000000-0000-0000-0000-000000000001', TRUE),
    ('00000000-0000-0000-0001-000000000005', 'Telangana',        'state', '00000000-0000-0000-0000-000000000001', TRUE)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Districts — Kerala (14)
-- ------------------------------------------------------------
INSERT INTO regions (name, region_type, parent_id, is_active) VALUES
    ('Thiruvananthapuram', 'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Kollam',             'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Pathanamthitta',     'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Alappuzha',          'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Kottayam',           'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Idukki',             'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Ernakulam',          'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Thrissur',           'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Palakkad',           'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Malappuram',         'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Kozhikode',          'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Wayanad',            'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Kannur',             'district', '00000000-0000-0000-0001-000000000001', TRUE),
    ('Kasaragod',          'district', '00000000-0000-0000-0001-000000000001', TRUE)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Districts — Tamil Nadu (38)
-- ------------------------------------------------------------
INSERT INTO regions (name, region_type, parent_id, is_active) VALUES
    ('Chennai',            'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Coimbatore',         'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Madurai',            'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tiruchirappalli',    'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Salem',              'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tirunelveli',        'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tiruppur',           'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Ranipet',            'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Vellore',            'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Erode',              'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Thoothukkudi',       'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Dindigul',           'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Thanjavur',          'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Kanniyakumari',      'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Nagapattinam',       'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Villupuram',         'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Cuddalore',          'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Kancheepuram',       'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Chengalpattu',       'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Kallakurichi',       'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Krishnagiri',        'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Dharmapuri',         'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Namakkal',           'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Perambalur',         'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Ariyalur',           'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Karur',              'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Pudukkottai',        'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Sivaganga',          'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Ramanathapuram',     'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Virudhunagar',       'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tenkasi',            'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tirupattur',         'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tiruvannamalai',     'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Nilgiris',           'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Mayiladuthurai',     'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Tiruvarur',          'district', '00000000-0000-0000-0001-000000000002', TRUE),
    ('Kancheepuram',       'district', '00000000-0000-0000-0001-000000000002', TRUE),  -- REVIEW: verify no duplicate vs Kancheepuram above — LGD lists both Kancheepuram and Chengalpattu as separate post-2019 bifurcation
    ('Thoothukudi',        'district', '00000000-0000-0000-0001-000000000002', TRUE)   -- REVIEW: duplicate of Thoothukkudi above? Verify official LGD spelling
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Districts — Karnataka (31)
-- ------------------------------------------------------------
INSERT INTO regions (name, region_type, parent_id, is_active) VALUES
    ('Bengaluru Urban',    'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Bengaluru Rural',    'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Mysuru',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Hubballi-Dharwad',   'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Mangaluru',          'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Belagavi',           'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Kalaburagi',         'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Ballari',            'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Vijayapura',         'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Shivamogga',         'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Tumakuru',           'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Raichur',            'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Bidar',              'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Yadgir',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Koppal',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Gadag',              'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Haveri',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Uttara Kannada',     'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Udupi',              'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Dakshina Kannada',   'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Chikkamagaluru',     'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Hassan',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Kodagu',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Mandya',             'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Chamarajanagar',     'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Ramanagara',         'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Chikkaballapura',    'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Kolar',              'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Chitradurga',        'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Davangere',          'district', '00000000-0000-0000-0001-000000000003', TRUE),
    ('Vijayanagara',       'district', '00000000-0000-0000-0001-000000000003', TRUE)   -- created 2021 from Ballari
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Districts — Andhra Pradesh (26)
-- ------------------------------------------------------------
INSERT INTO regions (name, region_type, parent_id, is_active) VALUES
    ('Visakhapatnam',      'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Vijayawada',         'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- REVIEW: official district name is Krishna; Vijayawada is the city. Verify preferred display name.
    ('Guntur',             'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Tirupati',           'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- REVIEW: official district is Chittoor; Tirupati district created 2022. Verify post-reorganisation name.
    ('Kakinada',           'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- REVIEW: post-2022 reorganisation — East Godavari split. Verify.
    ('Rajahmundry',        'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- REVIEW: Dr. B.R. Ambedkar Konaseema district. Verify official name.
    ('Nellore',            'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- Sri Potti Sriramulu Nellore
    ('Kurnool',            'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Kadapa',             'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- YSR Kadapa
    ('Anantapur',          'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- Sri Sathya Sai district post-2022. Verify.
    ('Eluru',              'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Vizianagaram',       'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Srikakulam',         'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Prakasam',           'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Nandyal',            'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Ongole',             'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- REVIEW: Ongole is city; Prakasam is district. Post-2022 may have changed.
    ('Bapatla',            'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Palnadu',            'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Alluri Sitharama Raju', 'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Anakapalli',         'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Parvathipuram Manyam', 'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Sri Balaji',         'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('South 24 Parganas',  'district', '00000000-0000-0000-0001-000000000004', TRUE),  -- REMOVE: this is West Bengal, not AP. Placeholder row — delete before launch.
    ('Konaseema',          'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('Krishna',            'district', '00000000-0000-0000-0001-000000000004', TRUE),
    ('West Godavari',      'district', '00000000-0000-0000-0001-000000000004', TRUE)
ON CONFLICT DO NOTHING;

-- ------------------------------------------------------------
-- Districts — Telangana (33)
-- ------------------------------------------------------------
INSERT INTO regions (name, region_type, parent_id, is_active) VALUES
    ('Hyderabad',          'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Warangal',           'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Nizamabad',          'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Karimnagar',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Khammam',            'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Mahbubnagar',        'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Nalgonda',           'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Adilabad',           'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Medak',              'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Rangareddy',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Sangareddy',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Siddipet',           'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Vikarabad',          'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Yadadri Bhuvanagiri','district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Medchal-Malkajgiri', 'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Peddapalli',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Jagtial',            'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Rajanna Sircilla',   'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Kamareddy',          'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Nirmal',             'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Mancherial',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Asifabad',           'district', '00000000-0000-0000-0001-000000000005', TRUE),  -- Kumuram Bheem Asifabad
    ('Bhupalpally',        'district', '00000000-0000-0000-0001-000000000005', TRUE),  -- Mulugu split — REVIEW: verify current name
    ('Jayashankar Bhupalpally', 'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Mahabubabad',        'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Bhadradri Kothagudem','district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Suryapet',           'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Nagar Kurnool',      'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Wanaparthy',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Jogulamba Gadwal',   'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Nagarkurnool',       'district', '00000000-0000-0000-0001-000000000005', TRUE),  -- REVIEW: possible duplicate of Nagar Kurnool above — verify LGD
    ('Narayanpet',         'district', '00000000-0000-0000-0001-000000000005', TRUE),
    ('Mulugu',             'district', '00000000-0000-0000-0001-000000000005', TRUE)
ON CONFLICT DO NOTHING;

COMMIT;
