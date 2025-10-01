#!/bin/bash
# VAGUS App - Database Audit Runner
# This script runs the database audit against the live Supabase database

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}VAGUS Database Audit Runner${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# Database connection string
DB_URL="postgresql://postgres.kydrpnrmqbedjflklgue:X.7achoony.X@aws-0-eu-central-1.pooler.supabase.com:5432/postgres"

echo -e "${YELLOW}Checking for database tools...${NC}"

# Check for psql
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ psql found - Using PostgreSQL client${NC}"

    echo -e "\n${YELLOW}Running database audit...${NC}"
    psql "$DB_URL" -f database_audit.sql -o database_audit_results.txt

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Audit completed successfully!${NC}"
        echo -e "Results saved to: database_audit_results.txt"
    else
        echo -e "${RED}❌ Audit failed - check connection and credentials${NC}"
        exit 1
    fi

# Check for docker (can run postgres container)
elif command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  psql not found, trying Docker...${NC}"

    docker run --rm -i postgres:15 psql "$DB_URL" -f - < database_audit.sql > database_audit_results.txt

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Audit completed via Docker!${NC}"
        echo -e "Results saved to: database_audit_results.txt"
    else
        echo -e "${RED}❌ Docker method failed${NC}"
        exit 1
    fi

else
    echo -e "${RED}❌ No database client found${NC}"
    echo ""
    echo "Please install one of:"
    echo "  - PostgreSQL client (psql)"
    echo "  - Docker"
    echo ""
    echo "Or run the audit manually by copying database_audit.sql"
    echo "into Supabase Dashboard → SQL Editor"
    exit 1
fi

echo ""
echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Generating comparison report...${NC}"
echo -e "${YELLOW}================================${NC}"

# Extract table list from code
echo -e "\n${YELLOW}Extracting tables from Dart code...${NC}"
grep -rh "\.from('" lib/ --include="*.dart" | \
  sed "s/.*\.from('\([^']*\)').*/\1/" | \
  sort -u > code_tables.txt

echo -e "${GREEN}✅ Found $(wc -l < code_tables.txt) tables referenced in code${NC}"

# Parse database tables from audit results (if successful)
if [ -f database_audit_results.txt ]; then
    echo -e "\n${YELLOW}Parsing database tables from audit...${NC}"

    # This is a placeholder - actual parsing depends on query results format
    # You may need to adjust this based on the actual output
    grep -A 200 "List all tables" database_audit_results.txt | \
      tail -n +4 | head -n -2 | \
      sed 's/^ *//' | sed 's/ *$//' > db_tables.txt

    if [ -s db_tables.txt ]; then
        echo -e "${GREEN}✅ Found $(wc -l < db_tables.txt) tables in database${NC}"

        # Compare
        echo -e "\n${YELLOW}Finding missing tables...${NC}"
        comm -23 code_tables.txt db_tables.txt > missing_tables.txt

        echo -e "\n${YELLOW}Finding unused tables...${NC}"
        comm -13 code_tables.txt db_tables.txt > unused_tables.txt

        echo ""
        echo -e "${YELLOW}=== SUMMARY ===${NC}"
        echo -e "Tables in code:     $(wc -l < code_tables.txt)"
        echo -e "Tables in database: $(wc -l < db_tables.txt)"
        echo -e "${RED}Missing tables:     $(wc -l < missing_tables.txt)${NC}"
        echo -e "${YELLOW}Unused tables:      $(wc -l < unused_tables.txt)${NC}"

        if [ -s missing_tables.txt ]; then
            echo ""
            echo -e "${RED}❌ Missing Tables (Code expects but DB lacks):${NC}"
            head -20 missing_tables.txt
            if [ $(wc -l < missing_tables.txt) -gt 20 ]; then
                echo "... and $(($(wc -l < missing_tables.txt) - 20)) more"
            fi
        fi

        if [ -s unused_tables.txt ]; then
            echo ""
            echo -e "${YELLOW}ℹ️  Unused Tables (DB has but code doesn't reference):${NC}"
            head -10 unused_tables.txt
            if [ $(wc -l < unused_tables.txt) -gt 10 ]; then
                echo "... and $(($(wc -l < unused_tables.txt) - 10)) more"
            fi
        fi
    fi
fi

echo ""
echo -e "${GREEN}✅ Audit complete!${NC}"
echo ""
echo "Generated files:"
echo "  - database_audit.sql           (Audit queries)"
echo "  - database_audit_results.txt   (Full results)"
echo "  - code_tables.txt              (Tables from Dart code)"
echo "  - db_tables.txt                (Tables from database)"
echo "  - missing_tables.txt           (Tables missing in DB)"
echo "  - unused_tables.txt            (Tables not used in code)"
echo ""
echo -e "${YELLOW}Next: Review database_audit_results.txt for detailed findings${NC}"
