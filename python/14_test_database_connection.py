from sqlalchemy import create_engine, text

DB_USER = "postgres"
DB_PASSWORD = "Password123"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "government_budget_analytics"

DATABASE_URL = (
    f"postgresql+psycopg2://{DB_USER}:"
    f"{DB_PASSWORD}@{DB_HOST}:"
    f"{DB_PORT}/{DB_NAME}"
)

engine = create_engine(DATABASE_URL)

try:
    with engine.connect() as connection:

        result = connection.execute(
            text("SELECT current_database(), version();")
        )

        for row in result:
            print("Database:", row[0])
            print("PostgreSQL:", row[1])

    print("Database connection successful!")

except Exception as error:
    print("Database connection failed!")
    print(error)