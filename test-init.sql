CREATE TABLE clicks (
    rate_table_offer_id VARCHAR PRIMARY KEY,
    num_clicks INTEGER,
    last_click TIMESTAMP,
    first_click TIMESTAMP
);

CREATE TABLE leads (
    lead_uuid UUID PRIMARY KEY,
    requested FLOAT,
    state VARCHAR,
    loan_purpose VARCHAR,
    credit VARCHAR,
    annual_income FLOAT,
    is_employed VARCHAR,
    monthly_net_income FLOAT,
    morgate_property_type VARCHAR,
    has_morgate VARCHAR,
    zipcode VARCHAR,
    lead_created_at TIMESTAMP
);

CREATE TABLE rate_tables(
    lead_uuid UUID NOT NULL,
    rate_table_id VARCHAR NOT NULL,
    rate_table_offer_id VARCHAR PRIMARY KEY,
    rate_table_offer_created_at TIMESTAMP,
    offer_apr FLOAT,
    offer_fee_fixed FLOAT,
    offer_fee_rate FLOAT,
    offer_monthly_payment FLOAT,
    offer_rec_score FLOAT,
    offer_rank_table INTEGER,
    demand_sub_account_id VARCHAR NOT NULL
);