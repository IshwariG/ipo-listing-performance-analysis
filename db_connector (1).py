#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import mysql.connector
import pandas as pd

DB_CONFIG = {
    "host": "localhost",
    "port": 3306******,
    "user": "ipo_user",
    "password": "I********3",
    "database": "ipo_db",
}

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def fetch_ipo_data():
    conn = get_connection()
    df = pd.read_sql("SELECT * FROM ipo_clean;", conn)
    conn.close()
    return df

