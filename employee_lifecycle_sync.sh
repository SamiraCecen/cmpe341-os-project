#!/bin/bash

# ------------------------------------------------------
# CMPE341 – Employee Lifecycle Automation Script
# ------------------------------------------------------

mkdir -p output
mkdir -p output/archives

SNAPSHOT="output/archives/last_employees.csv"

# ------------------------------------------------------
# Initialize snapshot if it does not exist
# ------------------------------------------------------
init_snapshot() {
    if [ ! -f "$SNAPSHOT" ]; then
        cp employees.csv "$SNAPSHOT"
    fi
}

# ------------------------------------------------------
# Detect added, removed, and terminated employees
# ------------------------------------------------------
detect_changes() {

    echo "username,department" > output/added_users.csv
    echo "username,department" > output/removed_users.csv
    echo "username,department" > output/terminated_users.csv

    # Added users
    while IFS=',' read -r id username name dept status; do
        if [ "$id" = "emp_id" ]; then
            continue
        fi

        if ! grep -q ",$username," "$SNAPSHOT"; then
            if [ "$status" = "active" ]; then
                echo "$username,$dept" >> output/added_users.csv
            fi
        fi
    done < employees.csv

    # Removed users
    while IFS=',' read -r id username name dept status; do
        if [ "$id" = "emp_id" ]; then
            continue
        fi

        if ! grep -q ",$username," employees.csv; then
            echo "$username,$dept" >> output/removed_users.csv
        fi
    done < "$SNAPSHOT"

    # Terminated users
    while IFS=',' read -r id username name dept status; do
        if [ "$id" = "emp_id" ]; then
            continue
        fi

        if [ "$status" = "terminated" ]; then
            echo "$username,$dept" >> output/terminated_users.csv
        fi
    done < employees.csv
}

# ------------------------------------------------------
# Onboard new active employees
# ------------------------------------------------------
onboard_users() {
    while IFS=',' read -r username dept; do
        if [ "$username" = "username" ]; then
            continue
        fi

        if id "$username" &>/dev/null; then
            continue
        fi

        if ! getent group "$dept" >/dev/null; then
            sudo groupadd "$dept"
        fi

        sudo useradd -m -g "$dept" "$username"
    done < output/added_users.csv
}

# ------------------------------------------------------
# Archive user's home directory as tar.gz
# ------------------------------------------------------
archive_home_folder() {
    user=$1
    home="/home/$user"

    if [ ! -d "$home" ]; then
        echo "[WARN] Home directory not found for $user"
        return
    fi

    tar -czf "output/archives/${user}.tar.gz" -C /home "$user"
}

# ------------------------------------------------------
# Lock user and archive home directory
# ------------------------------------------------------
offboard_user() {
    user=$1

    if id "$user" &>/dev/null; then
        sudo usermod -L "$user"
    fi

    archive_home_folder "$user"
}

# ------------------------------------------------------
# Offboard removed and terminated users
# ------------------------------------------------------
offboard_users() {

    # Removed users
    while IFS=',' read -r username dept; do
        if [ "$username" != "username" ]; then
            offboard_user "$username"
        fi
    done < output/removed_users.csv

    # Terminated users
    while IFS=',' read -r username dept; do
        if [ "$username" != "username" ]; then
            offboard_user "$username"
        fi
    done < output/terminated_users.csv
}

# ------------------------------------------------------
# Update snapshot
# ------------------------------------------------------
update_snapshot() {
    cp employees.csv "$SNAPSHOT"
}

# ------------------------------------------------------
# MAIN
# ------------------------------------------------------
main() {
    init_snapshot
    detect_changes
    onboard_users
    offboard_users
    update_snapshot

    echo "Process Completed."
}

main
