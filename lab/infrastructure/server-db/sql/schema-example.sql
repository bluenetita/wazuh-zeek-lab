-- ServerDB PostgreSQL schema example
-- This file documents the database structure used in the lab.
-- It contains only synthetic data and must not contain real credentials,
-- real card numbers, real CVV, real IBANs, or personal information.

-- Table: utenti
CREATE TABLE utenti (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    ruolo VARCHAR(20) NOT NULL
);

-- Table: dati_sensibili
CREATE TABLE dati_sensibili (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    numero_carta_masked VARCHAR(20),
    cvv_masked VARCHAR(5),
    iban_masked VARCHAR(34),
    FOREIGN KEY (user_id) REFERENCES utenti(id)
);

-- Synthetic demo data
-- Passwords are represented as placeholders, not real plaintext passwords.
INSERT INTO utenti (username, password_hash, email, ruolo)
VALUES
    ('demo_admin', 'HASH_REDACTED', 'admin@example.local', 'admin'),
    ('demo_user1', 'HASH_REDACTED', 'user1@example.local', 'user'),
    ('demo_user2', 'HASH_REDACTED', 'user2@example.local', 'user');

-- Synthetic masked data
INSERT INTO dati_sensibili (user_id, numero_carta_masked, cvv_masked, iban_masked)
VALUES
    (1, 'CARD_REDACTED_0001', 'XXX', 'IBAN_REDACTED_0001'),
    (2, 'CARD_REDACTED_0002', 'XXX', 'IBAN_REDACTED_0002'),
    (3, 'CARD_REDACTED_0003', 'XXX', 'IBAN_REDACTED_0003');

-- Example query used to verify the relationship between the two tables.
SELECT u.username, d.numero_carta_masked, d.cvv_masked
FROM utenti u
JOIN dati_sensibili d ON u.id = d.user_id;
