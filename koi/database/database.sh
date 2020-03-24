#!/bin/bash
set -e
function create_database()
{
echo "Creating database role: $2"
POSTGRES="PGPASSWORD=${POSTGRES_PASSWORD} psql --username ${POSTGRES_USER}"

$POSTGRES <<-EOSQL
CREATE USER ${2} WITH CREATEDB PASSWORD '${3}';
EOSQL

POSTGRES="PGPASSWORD=${POSTGRES_PASSWORD} psql --username ${POSTGRES_USER}"

echo "Creating database: $1"

$POSTGRES <<EOSQL
CREATE DATABASE ${1} OWNER ${2};
EOSQL
}

function get_env()
{
    DB_TNT_NAME=tnt
    DB_TNT_PASSWORD=tnt
    DB_TNT_USER=tnt
    DB_ADM_NAME=adm
    DB_ADM_PASSWORD=adm
    DB_ADM_USER=adm
    DB_ALFRESCO_NAME=alfresco
    DB_ALFRESCO_PASSWORD=alfresco
    DB_ALFRESCO_USER=alfresco
    DB_KEYCLOAK_NAME=keycloak
    DB_KEYCLOAK_PASSWORD=keycloak
    DB_KEYCLOAK_USER=keycloak
    DB_GDOC_NAME=gdoc
    DB_GDOC_PASSWORD=gdoc
    DB_GDOC_USER=gdoc
    DB_ENT_NAME=ent
    DB_ENT_PASSWORD=ent
    DB_ENT_USER=ent
    DB_FEI_NAME=fei
    DB_FEI_PASSWORD=fei
    DB_FEI_USER=fei
    DB_AMA_NAME=ama
    DB_AMA_PASSWORD=ama
    DB_AMA_USER=ama

    databases=($(compgen -A variable | grep "DB_.*_NAME"))
    users=($(compgen -A variable | grep "DB_.*_USER"))
    passwords=($(compgen -A variable | grep "DB_.*_PASSWORD"))
    i=0
    for iter in "${databases[@]}"
    do
        db=${!databases[$i]}
        user=${!users[$i]}
        create_database ${db} ${user} ${!passwords[$i]}

        DB_LABEL=$(echo ${databases[$i]} | grep -o -P '(?<=DB_).*(?=_NAME)');
        # DB Schemas
        DB_SCHEMAS="DB_"$DB_LABEL"_SCHEMAS";
        if [[ -v $DB_SCHEMAS ]]; then
            POSTGRES="psql --username ${POSTGRES_USER} -d ${db}"
            for schema in $(echo ${!DB_SCHEMAS} | tr ',' ' '); do
                echo "Creating schema: $schema"
                $POSTGRES <<EOSQL
CREATE SCHEMA IF NOT EXISTS $schema;
GRANT ALL ON SCHEMA $schema to "${user}";
EOSQL
            done
        fi

        # DB Extensions
        DB_EXTENSIONS="DB_"$DB_LABEL"_EXTENSIONS";
        if [[ -v $DB_EXTENSIONS ]]; then
            POSTGRES="psql --username ${POSTGRES_USER} -d ${db}"
            for extension in $(echo ${!DB_EXTENSIONS} | tr ',' ' '); do
                echo "Creating extension: $extension"
                $POSTGRES <<EOSQL
CREATE EXTENSION IF NOT EXISTS $extension;
EOSQL
            done
        fi
        i=$i+1
    done
}

get_env