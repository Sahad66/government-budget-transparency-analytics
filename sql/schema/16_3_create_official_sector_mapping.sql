
BEGIN;

-- =========================================================
-- 1. CREATE OFFICIAL SECTORS
-- =========================================================

INSERT INTO analytics.dim_sector
    (sector_name, sector_description)
VALUES
    (
        'Human Resource',
        'Human resource related social infrastructure'
    ),
    (
        'Food and Social Safety',
        'Food security and social safety related services'
    ),
    (
        'Agriculture and Rural Development',
        'Agriculture, water resources and rural development'
    ),
    (
        'Power and Energy',
        'Power and energy infrastructure'
    ),
    (
        'Communication Infrastructure',
        'Road, railway and bridge infrastructure'
    )
ON CONFLICT (sector_name) DO NOTHING;


-- =========================================================
-- 2. MAP 13 OFFICIALLY IDENTIFIED MINISTRIES
-- =========================================================

WITH official_mapping (
    ministry_code,
    sector_name,
    mapping_notes
) AS (
    VALUES
        ('124', 'Human Resource',
         'Ministry of Primary and Mass Education'),

        ('125', 'Human Resource',
         'Secondary and Higher Education Division'),

        ('127', 'Human Resource',
         'Health Services Division'),

        ('148', 'Food and Social Safety',
         'Ministry of Food'),

        ('149', 'Food and Social Safety',
         'Ministry of Disaster Management and Relief'),

        ('143', 'Agriculture and Rural Development',
         'Ministry of Agriculture'),

        ('147', 'Agriculture and Rural Development',
         'Ministry of Water Resources'),

        ('137', 'Agriculture and Rural Development',
         'Local Government Division'),

        ('156', 'Power and Energy',
         'Power Division'),

        ('142', 'Power and Energy',
         'Energy and Mineral Resources Division'),

        ('150', 'Communication Infrastructure',
         'Road Transport and Highways Division'),

        ('151', 'Communication Infrastructure',
         'Ministry of Railways'),

        ('159', 'Communication Infrastructure',
         'Bridges Division')
)

INSERT INTO analytics.bridge_ministry_sector (
    ministry_id,
    sector_id,
    allocation_share,
    mapping_status,
    mapping_source,
    mapping_notes
)
SELECT
    dm.ministry_id,
    ds.sector_id,
    100.0000,
    'approved',
    'Bangladesh Budget Speech 2024-25, Annexure A, Table 6, pp. 178-179. https://nbr.gov.bd/uploads/budget/2024-25_Budget_Speech_English.pdf',
    om.mapping_notes
FROM official_mapping om
JOIN analytics.dim_ministry dm
    ON dm.ministry_code = om.ministry_code
JOIN analytics.dim_sector ds
    ON ds.sector_name = om.sector_name

ON CONFLICT (ministry_id, sector_id)
DO UPDATE SET
    allocation_share = EXCLUDED.allocation_share,
    mapping_status = EXCLUDED.mapping_status,
    mapping_source = EXCLUDED.mapping_source,
    mapping_notes = EXCLUDED.mapping_notes;


COMMIT;


-- =========================================================
-- 3. SECTOR VALIDATION
-- =========================================================

SELECT
    sector_id,
    sector_name
FROM analytics.dim_sector
ORDER BY sector_id;


-- =========================================================
-- 4. MINISTRY MAPPING VALIDATION
-- =========================================================

SELECT
    dm.ministry_code,
    dm.ministry_name,
    ds.sector_name,
    bms.allocation_share,
    bms.mapping_status,
    bms.mapping_source
FROM analytics.bridge_ministry_sector bms
JOIN analytics.dim_ministry dm
    ON dm.ministry_id = bms.ministry_id
JOIN analytics.dim_sector ds
    ON ds.sector_id = bms.sector_id
WHERE bms.mapping_status = 'approved'
ORDER BY ds.sector_name, dm.ministry_code;


-- =========================================================
-- 5. MAPPING SUMMARY
-- =========================================================

SELECT
    COUNT(DISTINCT dm.ministry_id) AS mapped_ministries,
    COUNT(*) AS approved_mapping_records,
    COUNT(*) FILTER (
        WHERE bms.allocation_share <> 100
    ) AS invalid_allocation_records
FROM analytics.bridge_ministry_sector bms
JOIN analytics.dim_ministry dm
    ON dm.ministry_id = bms.ministry_id
WHERE bms.mapping_status = 'approved';
