
from sqlalchemy import create_engine, text, URL
from getpass import getpass

print("=" * 65)
print("POSTGRESQL CONNECTION TEST")
print("=" * 65)

password = getpass("Enter PostgreSQL password: ")

url = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password=password,
    host="localhost",
    port=5432,
    database="government_budget_analytics"
)

engine = create_engine(url)

try:
    with engine.connect() as connection:

        result = connection.execute(
            text("""
                SELECT
                    current_database(),
                    current_user,
                    version();
            """)
        )

        database, user, version = result.fetchone()

        print("\nConnection: SUCCESS")
        print("Database:", database)
        print("User:", user)
        print("PostgreSQL Version:", version)

        print("\nExisting Project Schemas:")

        schemas = connection.execute(
            text("""
                SELECT schema_name
                FROM information_schema.schemata
                WHERE schema_name IN ('staging', 'analytics')
                ORDER BY schema_name;
            """)
        ).fetchall()

        for schema in schemas:
            print("-", schema[0])

        print("\nExisting Project Tables:")

        tables = connection.execute(
            text("""
                SELECT table_schema, table_name
                FROM information_schema.tables
                WHERE table_schema IN ('staging', 'analytics')
                  AND table_type = 'BASE TABLE'
                ORDER BY table_schema, table_name;
            """)
        ).fetchall()

        if tables:
            for schema, table in tables:
                print(f"- {schema}.{table}")
        else:
            print("No project tables found.")

        print("\nPostgreSQL connection test completed.")

except Exception as error:
    print("\nCONNECTION FAILED")
    print("Error:", error)

finally:
    engine.dispose()
