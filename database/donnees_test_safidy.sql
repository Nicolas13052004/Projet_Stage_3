-- =====================================================================
-- SAFIDY - Jeu de donnees de test 2024-2026
-- 10 contribuables : 1000000001 a 1000000010
-- Executable dans psql et pgAdmin4, rejouable sans conflit.
-- =====================================================================

SET client_encoding = 'UTF8';

BEGIN;

-- ---------------------------------------------------------------------
-- 0. Contexte et cibles
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_target_nif (nif VARCHAR(20) PRIMARY KEY) ON COMMIT DROP;
INSERT INTO tmp_target_nif (nif) VALUES
('1000000001'), ('1000000002'), ('1000000003'), ('1000000004'), ('1000000005'),
('1000000006'), ('1000000007'), ('1000000008'), ('1000000009'), ('1000000010');

CREATE TEMP TABLE tmp_ctx ON COMMIT DROP AS
SELECT
    (SELECT id_centre FROM centre_fiscal WHERE code = 'CF-ANT-01' LIMIT 1) AS id_centre,
    (SELECT id_agent FROM agent WHERE email = 'agent@safidy.mg' LIMIT 1) AS id_agent;

INSERT INTO tmp_ctx (id_centre, id_agent)
SELECT (SELECT id_centre FROM centre_fiscal WHERE code = 'CF-ANT-01' LIMIT 1),
       (SELECT id_agent FROM agent ORDER BY id_agent LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM tmp_ctx);

-- ---------------------------------------------------------------------
-- 1. Nettoyage des anciennes executions
-- ---------------------------------------------------------------------

DELETE FROM journal_audit j
USING contribuable c
WHERE j.id_cible = c.id_contribuable
  AND j.table_cible = 'CONTRIBUABLE'
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM journal_audit
WHERE details LIKE 'SEED_v1%';

DELETE FROM paiement p
USING contribuable c
WHERE p.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM penalite p
USING declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE p.id_declaration = d.id_declaration
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM suspension_activite s
USING contribuable c
WHERE s.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM acompte a
USING contribuable c
WHERE a.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM utilisation_deficit u
USING declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE u.id_declaration = d.id_declaration
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM utilisation_deficit u
USING deficit f
JOIN contribuable c ON c.id_contribuable = f.id_contribuable
WHERE u.id_deficit = f.id_deficit
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM ligne_charge l
USING declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE l.id_declaration = d.id_declaration
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM ajustement_fiscal a
USING declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE a.id_declaration = d.id_declaration
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM declaration_ir d
USING contribuable c
WHERE d.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM deficit f
USING contribuable c
WHERE f.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

DELETE FROM contribuable c
WHERE c.nif IN (SELECT nif FROM tmp_target_nif);

-- ---------------------------------------------------------------------
-- 2. Contribuables
-- ---------------------------------------------------------------------

INSERT INTO contribuable (
    nif, raison_sociale, forme_juridique, nom_dirigeant, cin_dirigeant,
    adresse, telephone, email, id_secteur, regime, date_immatriculation,
    mois_cloture, statut, id_centre, id_agent, stat
)
SELECT
    v.nif, v.raison_sociale, v.forme_juridique, v.nom_dirigeant, v.cin_dirigeant,
    v.adresse, v.telephone, v.email, s.id_secteur, 'REEL_OBLIGATOIRE',
    v.date_immatriculation, 12, v.statut, ctx.id_centre, ctx.id_agent, v.stat
FROM (
    VALUES
    ('1000000001', 'SARL Antananarivo Commerce', 'SARL', 'RAKOTO Jean', '101234567890', 'Lot II A 12 Antananarivo', '0341111111', 'contact@test1.mg', 'ACTIF', 'COMMERCE', DATE '2019-01-10', '10345678901234567'),
    ('1000000002', 'SA Industrie Toamasina', 'SA', 'RANDRIA Paul', '102234567891', 'Zone industrielle Toamasina', '0342222222', 'contact@test2.mg', 'ACTIF', 'INDUSTRIEL', DATE '2018-01-10', '10345678901234568'),
    ('1000000003', 'SARL Services Fianarantsoa', 'SARL', 'RAVELO Marie', '103234567892', 'Rue des Services Fianarantsoa', '0343333333', 'contact@test3.mg', 'ACTIF', 'SERVICES', DATE '2020-01-10', '10345678901234569'),
    ('1000000004', 'SARL Hotel Antsirabe', 'SARL', 'RAKOTOMALALA Pierre', '104234567893', 'Avenue Hotel Antsirabe', '0344444444', 'contact@test4.mg', 'ACTIF', 'HOTELIER', DATE '2017-01-10', '10345678901234570'),
    ('1000000005', 'SARL Carburant Madagascar', 'SARL', 'ANDRIAMANANA Luc', '105234567894', 'Route nationale Antananarivo', '0345555555', 'contact@test5.mg', 'ACTIF', 'CARBURANT', DATE '2016-01-10', '10345678901234571'),
    ('1000000006', 'SARL Artisanat Mahajanga', 'SARL', 'RAZAFINDRAKOTO Sophie', '106234567895', 'Marche artisanal Mahajanga', '0346666666', 'contact@test6.mg', 'VEILLEUSE', 'ARTISANAL', DATE '2021-01-10', '10345678901234572'),
    ('1000000007', 'SARL Agriculture Toliara', 'SARL', 'RAJAONARIVELO Michel', '107234567896', 'Route rurale Toliara', '0347777777', 'contact@test7.mg', 'ACTIF', 'AGRICOLE', DATE '2019-01-10', '10345678901234573'),
    ('1000000008', 'SA Industrie Antsirabe', 'SA', 'RABEMANANJARA Bernard', '108234567897', 'Parc industriel Antsirabe', '0348888888', 'contact@test8.mg', 'ACTIF', 'INDUSTRIEL', DATE '2015-01-10', '10345678901234574'),
    ('1000000009', 'SARL Services Transport', 'SARL', 'RAHARISON Nadia', '109234567898', 'Gare routiere Antananarivo', '0349999999', 'contact@test9.mg', 'ACTIF', 'SERVICES', DATE '2016-01-10', '10345678901234575'),
    ('1000000010', 'EI Services Numeriques', 'EI', 'RAKOTOARISOA Alain', '110234567899', 'Lot 45 Antananarivo', '0340000000', 'contact@test10.mg', 'CESSE', 'SERVICES', DATE '2011-01-10', '10345678901234576')
) AS v(nif, raison_sociale, forme_juridique, nom_dirigeant, cin_dirigeant, adresse, telephone, email, statut, secteur, date_immatriculation, stat)
JOIN secteur_activite s ON s.code = v.secteur
CROSS JOIN tmp_ctx ctx;

-- ---------------------------------------------------------------------
-- 3. Declarations : valeurs de base
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_decl ON COMMIT DROP AS
SELECT
    c.id_contribuable,
    c.nif,
    c.id_agent,
    v.annee,
    v.ca_ht,
    v.charges,
    v.reintegrations_manuelles,
    v.deductions,
    v.deficit_impute,
    v.mois_actifs,
    v.date_fin,
    v.date_depot,
    v.statut,
    v.total_charges,
    v.resultat_comptable,
    v.minimum_perception
FROM (
    VALUES
    ('1000000001', 2024, 600000000::bigint, 400000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-05-10', 'PAYEE', 400000000::bigint, 200000000::bigint, 7000000::bigint),
    ('1000000001', 2025, 650000000::bigint, 420000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'PAYEE', 420000000::bigint, 230000000::bigint, 7500000::bigint),
    ('1000000001', 2026, 700000000::bigint, 450000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, NULL::date, 'BROUILLON', 450000000::bigint, 250000000::bigint, 8000000::bigint),

    ('1000000002', 2024, 420000000::bigint, 280000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-07-20', 'PAYEE', 280000000::bigint, 140000000::bigint, 5200000::bigint),
    ('1000000002', 2025, 450000000::bigint, 300000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-10-20', 'EN_RETARD', 300000000::bigint, 150000000::bigint, 5500000::bigint),
    ('1000000002', 2026, 480000000::bigint, 320000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-10-10', 'VALIDEE', 320000000::bigint, 160000000::bigint, 5800000::bigint),

    ('1000000003', 2024, 400000000::bigint, 450000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-05-10', 'PAYEE', 450000000::bigint, (-50000000)::bigint, 5000000::bigint),
    ('1000000003', 2025, 450000000::bigint, 250000000::bigint, 0::bigint, 0::bigint, 40000000::bigint, 12, NULL::date, DATE '2026-05-10', 'PAYEE', 250000000::bigint, 200000000::bigint, 5500000::bigint),
    ('1000000003', 2026, 500000000::bigint, 300000000::bigint, 0::bigint, 0::bigint, 10000000::bigint, 12, NULL::date, DATE '2026-05-10', 'VALIDEE', 300000000::bigint, 200000000::bigint, 6000000::bigint),

    ('1000000004', 2024, 430000000::bigint, 300000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-11-20', 'EN_RETARD', 300000000::bigint, 130000000::bigint, 5300000::bigint),
    ('1000000004', 2025, 460000000::bigint, 320000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-10-20', 'EN_RETARD', 320000000::bigint, 140000000::bigint, 5600000::bigint),
    ('1000000004', 2026, 490000000::bigint, 340000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, NULL::date, 'BROUILLON', 340000000::bigint, 150000000::bigint, 5900000::bigint),

    ('1000000005', 2024, 1200000000::bigint, 1080000000::bigint, 0::bigint, 2000000::bigint, 5000000::bigint, 12, NULL::date, DATE '2025-05-10', 'PAYEE', 1080000000::bigint, 120000000::bigint, 3400000::bigint),
    ('1000000005', 2025, 1300000000::bigint, 1170000000::bigint, 3000000::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'PAYEE', 1170000000::bigint, 130000000::bigint, 3600000::bigint),
    ('1000000005', 2026, 1400000000::bigint, 1260000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'VALIDEE', 1260000000::bigint, 140000000::bigint, 3800000::bigint),

    ('1000000006', 2024, 410000000::bigint, 310000000::bigint, 0::bigint, 0::bigint, 0::bigint, 6, NULL::date, DATE '2025-05-10', 'PAYEE', 310000000::bigint, 100000000::bigint, 4350000::bigint),
    ('1000000006', 2025, 440000000::bigint, 330000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'PAYEE', 330000000::bigint, 110000000::bigint, 5400000::bigint),
    ('1000000006', 2026, 470000000::bigint, 350000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'VALIDEE', 350000000::bigint, 120000000::bigint, 5700000::bigint),

    ('1000000007', 2024, 405000000::bigint, 300000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-05-10', 'PAYEE', 300000000::bigint, 105000000::bigint, 5050000::bigint),
    ('1000000007', 2025, 425000000::bigint, 316000000::bigint, 1000000::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-10-20', 'EN_RETARD', 316000000::bigint, 109000000::bigint, 5250000::bigint),
    ('1000000007', 2026, 450000000::bigint, 330000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'VALIDEE', 330000000::bigint, 120000000::bigint, 5500000::bigint),

    ('1000000008', 2024, 800000000::bigint, 600000000::bigint, 0::bigint, 0::bigint, 10000000::bigint, 12, NULL::date, DATE '2025-05-10', 'PAYEE', 600000000::bigint, 200000000::bigint, 9000000::bigint),
    ('1000000008', 2025, 900000000::bigint, 690000000::bigint, 2000000::bigint, 0::bigint, 20000000::bigint, 12, NULL::date, DATE '2026-05-10', 'PAYEE', 690000000::bigint, 210000000::bigint, 10000000::bigint),
    ('1000000008', 2026, 950000000::bigint, 730000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'VALIDEE', 730000000::bigint, 220000000::bigint, 10500000::bigint),

    ('1000000009', 2024, 430000000::bigint, 300000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-05-10', 'PAYEE', 300000000::bigint, 130000000::bigint, 5300000::bigint),
    ('1000000009', 2025, 450000000::bigint, 310000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-06-05', 'PAYEE', 310000000::bigint, 140000000::bigint, 5500000::bigint),
    ('1000000009', 2026, 470000000::bigint, 330000000::bigint, 1000000::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-05-10', 'VALIDEE', 330000000::bigint, 140000000::bigint, 5700000::bigint),

    ('1000000010', 2024, 400000000::bigint, 310000000::bigint, 0::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2025-05-10', 'EN_RETARD', 310000000::bigint, 90000000::bigint, 5000000::bigint),
    ('1000000010', 2025, 420000000::bigint, 311000000::bigint, 1000000::bigint, 0::bigint, 0::bigint, 12, NULL::date, DATE '2026-10-20', 'EN_RETARD', 311000000::bigint, 109000000::bigint, 5200000::bigint),
    ('1000000010', 2026, 400000000::bigint, 310000000::bigint, 0::bigint, 0::bigint, 0::bigint, 6, DATE '2026-06-30', NULL::date, 'BROUILLON', 310000000::bigint, 90000000::bigint, 4500000::bigint)
) AS v(nif, annee, ca_ht, charges, reintegrations_manuelles, deductions, deficit_impute, mois_actifs, date_fin, date_depot, statut, total_charges, resultat_comptable, minimum_perception)
JOIN contribuable c ON c.nif = v.nif;

INSERT INTO declaration_ir (
    id_contribuable, annee, date_debut, date_fin, date_depot, date_limite,
    ca_ht, total_charges, resultat_comptable, total_deductions,
    deficit_impute, reintegrations_manuelles, total_reintegrations,
    base_imposable, taux_ir, ir_brut, minimum_perception, ir_du,
    penalite_due_ar, premier_acompte_ar, acomptes_verses,
    credit_impot, solde_a_payer, statut, mois_actifs, id_agent
)
SELECT
    td.id_contribuable,
    td.annee,
    make_date(td.annee, 1, 1),
    COALESCE(td.date_fin, make_date(td.annee, 12, 31)),
    td.date_depot,
    make_date(td.annee, 5, 15) + CASE WHEN td.annee = 2026 AND td.nif = '1000000010' THEN INTERVAL '56 days' ELSE INTERVAL '0 days' END,
    td.ca_ht,
    td.total_charges,
    td.resultat_comptable,
    td.deductions,
    td.deficit_impute,
    td.reintegrations_manuelles,
    0,
    0,
    20,
    0,
    td.minimum_perception,
    0,
    0,
    0,
    0,
    0,
    0,
    td.statut,
    td.mois_actifs,
    td.id_agent
FROM tmp_decl td;

-- ---------------------------------------------------------------------
-- 4. Charges et ajustements
-- ---------------------------------------------------------------------

INSERT INTO ligne_charge (id_declaration, categorie, categorie_libre, montant_ar, justificatif_ref)
SELECT d.id_declaration, 'SALAIRE', NULL, (d.total_charges * 60) / 100, 'SEED-' || c.nif || '-' || d.annee || '-SAL'
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT d.id_declaration, 'LOYER', NULL, d.total_charges - ((d.total_charges * 60) / 100), 'SEED-' || c.nif || '-' || d.annee || '-LOY'
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif);

INSERT INTO ajustement_fiscal (id_declaration, type, motif, montant_ar, article_ref)
SELECT d.id_declaration, v.type_ajustement, 'AUTRE', v.montant, 'SEED'
FROM (
    VALUES
    ('1000000005', 2024, 'DEDUCTION', 2000000::bigint),
    ('1000000005', 2025, 'REINTEGRATION', 3000000::bigint),
    ('1000000007', 2025, 'REINTEGRATION', 1000000::bigint),
    ('1000000008', 2025, 'REINTEGRATION', 2000000::bigint),
    ('1000000009', 2026, 'REINTEGRATION', 1000000::bigint),
    ('1000000010', 2025, 'REINTEGRATION', 1000000::bigint)
) AS v(nif, annee, type_ajustement, montant)
JOIN contribuable c ON c.nif = v.nif
JOIN declaration_ir d ON d.id_contribuable = c.id_contribuable AND d.annee = v.annee;

-- ---------------------------------------------------------------------
-- 5. Penalites (montants historiques explicites)
-- ---------------------------------------------------------------------

INSERT INTO penalite (
    id_declaration, type, base_calcul_ar, taux_pct, nb_mois, montant_ar,
    date_limite, date_regularisation, statut, motif, article_ref, motif_annulation
)
SELECT
    d.id_declaration, v.type_penalite, v.base, v.taux, v.nb_mois, v.montant,
    v.date_limite, v.date_reg, v.statut, v.motif, v.article, v.motif_annulation
FROM (
    VALUES
    ('1000000002', 2024, 'AMENDE_DEPOT', 420000000::bigint, 0::numeric, 0, 200000::bigint, DATE '2025-05-15', DATE '2025-07-20', 'PAYEE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.01', NULL::varchar),
    ('1000000002', 2024, 'INTERET_RETARD', 28000000::bigint, 1::numeric, 2, 560000::bigint, DATE '2025-05-15', DATE '2025-07-20', 'PAYEE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.02', NULL::varchar),
    ('1000000002', 2025, 'AMENDE_DEPOT', 450000000::bigint, 0::numeric, 0, 200000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.01', NULL::varchar),
    ('1000000002', 2025, 'INTERET_RETARD', 30000000::bigint, 1::numeric, 5, 1500000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.02', NULL::varchar),

    ('1000000004', 2024, 'AMENDE_DEPOT', 430000000::bigint, 0::numeric, 0, 200000::bigint, DATE '2025-05-15', DATE '2025-11-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.01', NULL::varchar),
    ('1000000004', 2024, 'INTERET_RETARD', 30333333::bigint, 1::numeric, 6, 1820000::bigint, DATE '2025-05-15', DATE '2025-11-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.02', NULL::varchar),
    ('1000000004', 2024, 'AMENDE_SPECIFIQUE', 12000000::bigint, 80::numeric, 0, 9600000::bigint, DATE '2025-05-15', DATE '2025-11-20', 'DUE', 'SUSPENSION_ABUSIVE', 'CDI art. 05.01.06', NULL::varchar),
    ('1000000004', 2024, 'MAJORATION', 16666667::bigint, 3::numeric, 0, 500000::bigint, DATE '2025-05-15', DATE '2025-11-20', 'ANNULEE', 'RETARD_PAIEMENT_GRANDE', 'CPF art. 01.02.04', 'Erreur de calcul'),
    ('1000000004', 2025, 'AMENDE_DEPOT', 460000000::bigint, 0::numeric, 0, 200000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.01', NULL::varchar),
    ('1000000004', 2025, 'INTERET_RETARD', 28000000::bigint, 1::numeric, 5, 1400000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.02', NULL::varchar),

    ('1000000007', 2025, 'AMENDE_DEPOT', 425000000::bigint, 0::numeric, 0, 200000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.01', NULL::varchar),
    ('1000000007', 2025, 'INTERET_RETARD', 22000000::bigint, 1::numeric, 5, 1100000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.02', NULL::varchar),

    ('1000000009', 2025, 'MAJORATION', 16000000::bigint, 3::numeric, 0, 480000::bigint, DATE '2026-05-15', DATE '2026-05-10', 'PAYEE', 'RETARD_PAIEMENT_GRANDE', 'CPF art. 01.02.04', NULL::varchar),
    ('1000000009', 2025, 'MAJORATION_80', 18062500::bigint, 80::numeric, 0, 14450000::bigint, DATE '2026-05-15', DATE '2026-05-10', 'ANNULEE', 'SUSPENSION_ABUSIVE', 'CDI art. 05.01.06', 'Remise gracieuse'),

    ('1000000010', 2025, 'AMENDE_DEPOT', 420000000::bigint, 0::numeric, 0, 200000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.01', NULL::varchar),
    ('1000000010', 2025, 'INTERET_RETARD', 22000000::bigint, 1::numeric, 5, 1100000::bigint, DATE '2026-05-15', DATE '2026-10-20', 'DUE', 'RETARD_DEPOT_IR', 'CDI art. 05.01.02', NULL::varchar)
) AS v(nif, annee, type_penalite, base, taux, nb_mois, montant, date_limite, date_reg, statut, motif, article, motif_annulation)
JOIN contribuable c ON c.nif = v.nif
JOIN declaration_ir d ON d.id_contribuable = c.id_contribuable AND d.annee = v.annee;

-- ---------------------------------------------------------------------
-- 6. Calcul final des declarations
-- ---------------------------------------------------------------------

CREATE TEMP TABLE tmp_decl_final ON COMMIT DROP AS
WITH pen AS (
    SELECT d.id_declaration,
           COALESCE(SUM(p.montant_ar), 0)::bigint AS penalite
    FROM declaration_ir d
    JOIN contribuable c ON c.id_contribuable = d.id_contribuable
    LEFT JOIN penalite p ON p.id_declaration = d.id_declaration AND p.statut <> 'ANNULEE'
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
    GROUP BY d.id_declaration
),
calc AS (
    SELECT
        td.*,
        COALESCE(pen.penalite, 0)::bigint AS penalite,
        td.resultat_comptable + td.reintegrations_manuelles + COALESCE(pen.penalite, 0)
            - td.deductions - td.deficit_impute AS base_raw
    FROM tmp_decl td
    LEFT JOIN pen ON pen.id_declaration = (
        SELECT d2.id_declaration
        FROM declaration_ir d2
        WHERE d2.id_contribuable = td.id_contribuable AND d2.annee = td.annee
    )
),
rounded AS (
    SELECT
        calc.*,
        CASE WHEN calc.base_raw > 0 THEN (calc.base_raw / 1000) * 1000 ELSE 0 END AS base_final,
        CASE WHEN calc.base_raw > 0 THEN ((calc.base_raw / 1000) * 1000) * 20 / 100 ELSE 0 END AS ir_brut_final
    FROM calc
),
final AS (
    SELECT
        rounded.*,
        GREATEST(rounded.ir_brut_final, rounded.minimum_perception) AS ir_du_final
    FROM rounded
)
SELECT
    final.*,
    (final.ir_du_final * 50 / 100)::bigint AS premier_acompte
FROM final;

UPDATE declaration_ir d
SET
    penalite_due_ar = f.penalite,
    total_reintegrations = f.reintegrations_manuelles + f.penalite,
    base_imposable = f.base_final,
    ir_brut = f.ir_brut_final,
    minimum_perception = f.minimum_perception,
    ir_du = f.ir_du_final,
    premier_acompte_ar = f.premier_acompte
FROM tmp_decl_final f
WHERE d.id_declaration = (
    SELECT d2.id_declaration
    FROM declaration_ir d2
    WHERE d2.id_contribuable = f.id_contribuable AND d2.annee = f.annee
);

-- ---------------------------------------------------------------------
-- 7. Deficits et utilisations
-- ---------------------------------------------------------------------

INSERT INTO deficit (id_contribuable, annee_origine, montant_initial, montant_utilise, solde, annee_expiration, statut)
SELECT c.id_contribuable, v.annee_origine, v.initial, v.utilise, v.initial - v.utilise, v.expiration, v.statut
FROM (
    VALUES
    ('1000000003', 2024, 50000000::bigint, 50000000::bigint, 2029, 'EPUISE'),
    ('1000000005', 2023, 20000000::bigint, 5000000::bigint, 2028, 'ACTIF'),
    ('1000000007', 2019, 30000000::bigint, 0::bigint, 2024, 'EXPIRE'),
    ('1000000008', 2023, 30000000::bigint, 30000000::bigint, 2028, 'EPUISE')
) AS v(nif, annee_origine, initial, utilise, expiration, statut)
JOIN contribuable c ON c.nif = v.nif;

INSERT INTO utilisation_deficit (id_deficit, id_declaration, montant_impute)
SELECT f.id_deficit, d.id_declaration, v.montant
FROM (
    VALUES
    ('1000000003', 2024, 2025, 40000000::bigint),
    ('1000000003', 2024, 2026, 10000000::bigint),
    ('1000000005', 2023, 2024, 5000000::bigint),
    ('1000000008', 2023, 2024, 10000000::bigint),
    ('1000000008', 2023, 2025, 20000000::bigint)
) AS v(nif, annee_origine, annee_declaration, montant)
JOIN contribuable c ON c.nif = v.nif
JOIN deficit f ON f.id_contribuable = c.id_contribuable AND f.annee_origine = v.annee_origine
JOIN declaration_ir d ON d.id_contribuable = c.id_contribuable AND d.annee = v.annee_declaration;

-- ---------------------------------------------------------------------
-- 8. Acomptes provisionnels, creation et douane
-- ---------------------------------------------------------------------

INSERT INTO acompte (id_contribuable, annee, numero, taux_pct, base_ir_n1, montant_ar, date_echeance, statut, type_acompte)
SELECT
    d.id_contribuable,
    d.annee + 1,
    n.numero,
    50,
    d.ir_du,
    (d.ir_du * 50 / 100)::bigint,
    make_date(d.annee + 1, CASE WHEN n.numero = 1 THEN 5 ELSE 11 END, 15),
    'A_PAYER',
    'PROVISIONNEL'
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
CROSS JOIN (VALUES (1), (2)) AS n(numero)
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
  AND d.statut <> 'BROUILLON'
  AND d.ir_du > 0;

UPDATE acompte a
SET statut = CASE
    WHEN a.annee = 2025 THEN
        CASE WHEN d.statut = 'PAYEE' THEN 'PAYE' ELSE 'EN_RETARD' END
    WHEN a.annee = 2026 THEN
        CASE
            WHEN d.statut = 'PAYEE' THEN
                CASE WHEN a.numero = 1 THEN 'PAYE' ELSE 'A_PAYER' END
            ELSE
                CASE WHEN a.numero = 1 THEN 'EN_RETARD' ELSE 'A_PAYER' END
        END
    ELSE 'A_PAYER'
END
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE a.id_contribuable = d.id_contribuable
  AND a.annee = d.annee + 1
  AND a.type_acompte = 'PROVISIONNEL'
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

UPDATE acompte a
SET statut = 'SUSPENDU'
FROM contribuable c
WHERE a.id_contribuable = c.id_contribuable
  AND c.nif IN ('1000000006', '1000000010')
  AND a.annee = 2026
  AND a.type_acompte = 'PROVISIONNEL'
  AND a.numero = 2;

INSERT INTO acompte (id_contribuable, annee, numero, taux_pct, base_ir_n1, montant_ar, date_echeance, date_paiement, statut, type_acompte)
SELECT
    c.id_contribuable,
    EXTRACT(YEAR FROM c.date_immatriculation)::int,
    1,
    0,
    0,
    CASE
        WHEN c.id_secteur IN (SELECT id_secteur FROM secteur_activite WHERE code IN ('INDUSTRIEL','AGRICOLE','ARTISANAL','MINIER','HOTELIER','TOURISTIQUE')) THEN 500000
        ELSE 1000000
    END,
    c.date_immatriculation,
    c.date_immatriculation + 5,
    'PAYE',
    'CREATION'
FROM contribuable c
WHERE c.nif IN (SELECT nif FROM tmp_target_nif);

INSERT INTO acompte (id_contribuable, annee, numero, taux_pct, base_ir_n1, montant_ar, date_echeance, date_paiement, statut, reference_douane, type_acompte)
SELECT c.id_contribuable, v.annee, v.numero, 2, v.base, v.montant, v.echeance, v.paiement, v.statut, v.ref_douane, 'DOUANE'
FROM (
    VALUES
    (2024, 1, 50000000::bigint, 1000000::bigint, DATE '2024-06-30', DATE '2024-07-05', 'PAYE', 'SEED-DOUANE-2024'),
    (2025, 2, 60000000::bigint, 1200000::bigint, DATE '2025-06-30', DATE '2025-07-05', 'PAYE', 'SEED-DOUANE-2025'),
    (2026, 3, 70000000::bigint, 1400000::bigint, DATE '2026-06-30', NULL::date, 'A_PAYER', 'SEED-DOUANE-2026')
) AS v(annee, numero, base, montant, echeance, paiement, statut, ref_douane)
JOIN contribuable c ON c.nif = '1000000005';

-- ---------------------------------------------------------------------
-- 9. Paiements
-- ---------------------------------------------------------------------

INSERT INTO paiement (
    id_contribuable, id_declaration, id_acompte, type_paiement, montant_ar,
    date_paiement, mode, reference_quittance, id_agent, annule,
    motif_annulation, type_reglement
)
SELECT
    c.id_contribuable,
    d.id_declaration,
    NULL,
    'SOLDE_IR',
    GREATEST(d.ir_du + d.penalite_due_ar + d.premier_acompte_ar - d.acomptes_verses, 0),
    CASE
        WHEN d.annee = 2024 THEN CASE WHEN c.nif = '1000000002' THEN DATE '2025-07-20' ELSE DATE '2025-05-10' END
        WHEN d.annee = 2025 THEN CASE WHEN c.nif = '1000000009' THEN DATE '2026-06-05' ELSE DATE '2026-05-10' END
    END,
    'VIREMENT',
    'Q-' || RIGHT(c.nif, 4) || '-' || d.annee || '-T',
    ctx.id_agent,
    FALSE,
    NULL,
    'TOUS'
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
CROSS JOIN tmp_ctx ctx
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
  AND d.statut = 'PAYEE'
  AND d.annee IN (2024, 2025)
  AND (d.ir_du + d.penalite_due_ar + d.premier_acompte_ar - d.acomptes_verses) > 0;

INSERT INTO paiement (
    id_contribuable, id_declaration, id_acompte, type_paiement, montant_ar,
    date_paiement, mode, reference_quittance, id_agent, annule,
    motif_annulation, type_reglement
)
SELECT
    c.id_contribuable,
    d.id_declaration,
    NULL,
    'ACOMPTE',
    (d.ir_du * 50 / 100) + CASE WHEN c.nif = '1000000002' THEN (d.ir_du * 50 / 100) * 1 / 100 ELSE 0 END,
    CASE WHEN c.nif = '1000000002' THEN DATE '2025-11-20' ELSE DATE '2025-11-10' END,
    'VIREMENT',
    'Q-' || RIGHT(c.nif, 4) || '-' || d.annee || '-2',
    ctx.id_agent,
    FALSE,
    NULL,
    '2EME_ACOMPTE'
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
CROSS JOIN tmp_ctx ctx
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
  AND d.statut = 'PAYEE'
  AND d.annee = 2024;

INSERT INTO paiement (
    id_contribuable, id_declaration, id_acompte, type_paiement, montant_ar,
    date_paiement, mode, reference_quittance, id_agent, annule,
    motif_annulation, type_reglement
)
SELECT
    c.id_contribuable,
    d.id_declaration,
    NULL,
    'SOLDE_IR',
    1000000,
    DATE '2025-05-10',
    'ESPECES',
    'Q-TEST-0004-2024-A',
    ctx.id_agent,
    TRUE,
    'Paiement annule pour test',
    'TOUS'
FROM declaration_ir d
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
CROSS JOIN tmp_ctx ctx
WHERE c.nif = '1000000004' AND d.annee = 2024;

UPDATE declaration_ir d
SET acomptes_verses = COALESCE((
    SELECT SUM(a.montant_ar)
    FROM acompte a
    WHERE a.id_contribuable = d.id_contribuable
      AND a.annee = d.annee
      AND a.type_acompte = 'PROVISIONNEL'
      AND a.statut = 'PAYE'
), 0)
FROM contribuable c
WHERE d.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

UPDATE declaration_ir d
SET
    solde_a_payer = GREATEST(d.ir_du + d.penalite_due_ar + d.premier_acompte_ar - d.acomptes_verses, 0),
    credit_impot = GREATEST(d.acomptes_verses - (d.ir_du + d.penalite_due_ar + d.premier_acompte_ar), 0)
FROM contribuable c
WHERE d.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

UPDATE declaration_ir d
SET solde_a_payer = 0, credit_impot = 0
FROM contribuable c
WHERE d.id_contribuable = c.id_contribuable
  AND c.nif IN (SELECT nif FROM tmp_target_nif)
  AND d.statut = 'PAYEE';

UPDATE acompte a
SET date_paiement = p.date_paiement
FROM paiement p
JOIN declaration_ir d ON d.id_declaration = p.id_declaration
WHERE p.annule = FALSE
  AND p.type_reglement = 'TOUS'
  AND a.id_contribuable = p.id_contribuable
  AND a.annee = d.annee + 1
  AND a.type_acompte = 'PROVISIONNEL'
  AND a.numero = 1
  AND a.statut = 'PAYE';

UPDATE acompte a
SET date_paiement = p.date_paiement
FROM paiement p
JOIN declaration_ir d ON d.id_declaration = p.id_declaration
WHERE p.annule = FALSE
  AND p.type_reglement = '2EME_ACOMPTE'
  AND a.id_contribuable = p.id_contribuable
  AND a.annee = d.annee + 1
  AND a.type_acompte = 'PROVISIONNEL'
  AND a.numero = 2
  AND a.statut = 'PAYE';

-- ---------------------------------------------------------------------
-- 10. Suspensions et audit
-- ---------------------------------------------------------------------

INSERT INTO suspension_activite (
    id_contribuable, date_arret, date_reprise, motif, ref_declaration,
    statut, type_evenement, date_limite_declaration, justificatif_ref,
    carte_fiscale_restituee, id_agent_arret, id_agent_reprise,
    impact_minimum_prorata, impact_acompte_suspendu, impact_credit_impot
)
SELECT
    c.id_contribuable, v.date_arret, v.date_reprise, v.motif, v.ref_declaration,
    v.statut, v.type_evenement, v.date_limite, v.justificatif,
    FALSE, ctx.id_agent,
    CASE WHEN v.has_reprise THEN ctx.id_agent ELSE NULL END,
    v.impact_minimum, v.impact_acompte, v.impact_credit
FROM (
    VALUES
    ('1000000006', DATE '2024-06-30', DATE '2024-12-31', 'MANQUE_ACTIVITE', 'SEED-6-2024', 'TERMINEE', 'REPRISE', DATE '2024-07-20', 'SEED-SUSP-6-2024', TRUE, NULL::bigint, NULL::bigint, NULL::bigint),
    ('1000000006', DATE '2026-09-01', NULL::date, 'SAISON', 'SEED-6-2026', 'EN_COURS', 'VEILLEUSE', DATE '2026-09-21', 'SEED-SUSP-6-2026', FALSE, 5075000::bigint, 12000000::bigint, 6925000::bigint),
    ('1000000009', DATE '2025-03-01', DATE '2025-04-01', 'TRAVAUX', 'SEED-9-2025', 'ANNULEE', 'VEILLEUSE', DATE '2025-03-21', 'SEED-SUSP-9-2025', TRUE, NULL::bigint, NULL::bigint, NULL::bigint),
    ('1000000010', DATE '2026-06-30', NULL::date, 'DIFFICULTE_FINANCIERE', 'SEED-10-2026', 'EN_COURS', 'CESSATION', DATE '2026-07-10', 'SEED-CESS-10', FALSE, NULL::bigint, NULL::bigint, NULL::bigint)
) AS v(nif, date_arret, date_reprise, motif, ref_declaration, statut, type_evenement, date_limite, justificatif, has_reprise, impact_minimum, impact_acompte, impact_credit)
JOIN contribuable c ON c.nif = v.nif
CROSS JOIN tmp_ctx ctx;

INSERT INTO journal_audit (id_agent, action, table_cible, id_cible, details, adresse_ip)
SELECT ctx.id_agent, 'SEED_TEST', 'CONTRIBUABLE', c.id_contribuable,
       'SEED_v1 - jeu de donnees complet 2024-2026', '127.0.0.1'
FROM contribuable c
CROSS JOIN tmp_ctx ctx
WHERE c.nif IN (SELECT nif FROM tmp_target_nif);

-- ---------------------------------------------------------------------
-- 11. Controles avant validation
-- ---------------------------------------------------------------------

DO $$
DECLARE
    n integer;
BEGIN
    SELECT COUNT(*) INTO n
    FROM contribuable c
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif);
    IF n <> 10 THEN
        RAISE EXCEPTION 'Seed: % contribuables au lieu de 10', n;
    END IF;

    SELECT COUNT(*) INTO n
    FROM declaration_ir d
    JOIN contribuable c ON c.id_contribuable = d.id_contribuable
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif);
    IF n <> 30 THEN
        RAISE EXCEPTION 'Seed: % declarations au lieu de 30', n;
    END IF;

    SELECT COUNT(*) INTO n
    FROM declaration_ir d
    JOIN contribuable c ON c.id_contribuable = d.id_contribuable
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
      AND d.statut = 'PAYEE'
      AND d.solde_a_payer <> 0;
    IF n <> 0 THEN
        RAISE EXCEPTION 'Seed: % declarations PAYEE avec un solde non nul', n;
    END IF;

    SELECT COUNT(*) INTO n
    FROM paiement p
    JOIN contribuable c ON c.id_contribuable = p.id_contribuable
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
      AND p.annule = FALSE;
    IF n <> 22 THEN
        RAISE EXCEPTION 'Seed: % paiements actifs au lieu de 22', n;
    END IF;

    SELECT COUNT(*) INTO n
    FROM paiement p
    JOIN contribuable c ON c.id_contribuable = p.id_contribuable
    WHERE c.nif = '1000000010'
      AND p.annule = FALSE;
    IF n <> 0 THEN
        RAISE EXCEPTION 'Seed: % paiements actifs pour un contribuable CESSE', n;
    END IF;

    SELECT COUNT(*) INTO n
    FROM acompte a
    JOIN contribuable c ON c.id_contribuable = a.id_contribuable
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
      AND a.type_acompte = 'PROVISIONNEL';
    IF n <> 54 THEN
        RAISE EXCEPTION 'Seed: % acomptes provisionnels au lieu de 54', n;
    END IF;

    SELECT COUNT(*) INTO n
    FROM penalite p
    JOIN declaration_ir d ON d.id_declaration = p.id_declaration
    JOIN contribuable c ON c.id_contribuable = d.id_contribuable
    WHERE c.nif IN (SELECT nif FROM tmp_target_nif);
    IF n <> 16 THEN
        RAISE EXCEPTION 'Seed: % penalites au lieu de 16', n;
    END IF;
END $$;

SELECT c.nif, c.raison_sociale, d.annee, d.statut, d.ir_du,
       d.penalite_due_ar, d.acomptes_verses, d.premier_acompte_ar,
       d.solde_a_payer, d.credit_impot
FROM contribuable c
JOIN declaration_ir d ON d.id_contribuable = c.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
ORDER BY c.nif, d.annee;

SELECT 'CONTRIBUABLES' AS table_cible, COUNT(*) AS total
FROM contribuable WHERE nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'DECLARATIONS', COUNT(*)
FROM declaration_ir d JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'LIGNES_CHARGE', COUNT(*)
FROM ligne_charge l JOIN declaration_ir d ON d.id_declaration = l.id_declaration
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'AJUSTEMENTS', COUNT(*)
FROM ajustement_fiscal a JOIN declaration_ir d ON d.id_declaration = a.id_declaration
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'PENALITES', COUNT(*)
FROM penalite p JOIN declaration_ir d ON d.id_declaration = p.id_declaration
JOIN contribuable c ON c.id_contribuable = d.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'PAIEMENTS', COUNT(*)
FROM paiement p JOIN contribuable c ON c.id_contribuable = p.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'ACOMPTES', COUNT(*)
FROM acompte a JOIN contribuable c ON c.id_contribuable = a.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'DEFICITS', COUNT(*)
FROM deficit f JOIN contribuable c ON c.id_contribuable = f.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'UTILISATIONS_DEFICIT', COUNT(*)
FROM utilisation_deficit u JOIN deficit f ON f.id_deficit = u.id_deficit
JOIN contribuable c ON c.id_contribuable = f.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'SUSPENSIONS', COUNT(*)
FROM suspension_activite s JOIN contribuable c ON c.id_contribuable = s.id_contribuable
WHERE c.nif IN (SELECT nif FROM tmp_target_nif)
UNION ALL
SELECT 'AUDITS', COUNT(*)
FROM journal_audit j JOIN contribuable c ON c.id_contribuable = j.id_cible
WHERE j.table_cible = 'CONTRIBUABLE'
  AND c.nif IN (SELECT nif FROM tmp_target_nif);

COMMIT;
