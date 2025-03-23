#!/bin/bash
#
### This module is responsible for the database operations (just an sqlite file for cache and speed up things)
#
db_dir="$HOME/.config/k8"
db_path="$HOME/.config/k8/k8.db"

db_create_if_not_exists() {
    if [ ! -d "$db_dir" ]; then
        mkdir "$db_dir"
    fi
    if [ ! -f "$db_path" ]; then
        touch "$db_path"
    echo "created $db_path"
    else
    echo "db already exists"
    fi
}

db_add_cmd_to_history(){
sqlite3 "$db_path" << EOF
    INSERT INTO history (cmd, label) VALUES ('$1', '$2');
EOF
}


db_reset(){
sqlite3 "$db_path" << EOF
    DROP TABLE IF EXISTS namespaces;
    DROP TABLE IF EXISTS contexts;
    DROP TABLE IF EXISTS favorites;
EOF
echo "tables dropped"
db_run_migrations
}

db_run_migrations(){
sqlite3 "$db_path" << EOF
    CREATE TABLE IF NOT EXISTS namespaces (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS contexts (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS history (
        id INTEGER PRIMARY KEY,
        cmd TEXT NOT NULL,
        label TEXT NOT NULL
    );
EOF
echo "tables created"
}

print_help() {
    echo "Usage: database [create|reset|migrate|help]"
    printf "\treset - reset the database\n"
    printf "\add_cmd_to_history - add a command to the history table\n"
    printf "\thelp - print this help\n"
}

if [ "$1" == "reset" ]; then
    db_create_if_not_exists
    db_reset
elif [ "$1" == "add_cmd_to_history" ]; then
    db_add_cmd_to_history $2 $3
else
    print_help
fi


