#!/bin/bash

# ------------------------------------------
# EMPLOYEE LIFECYCLE MANAGEMENT SCRIPT
# ------------------------------------------

# Initialize snapshot if it does not exist
init_snapshot_if_needed() {
    mkdir -p output/archives

    if [ ! -f output/archives/last_employees.csv ]; then
        echo "[INFO] No snapshot found. Creating initial snapshot."
        cp employees.csv output/archives/last_employees.csv
    else
        echo "[INFO] Snapshot already exists."
    fi
}

# Detect added, removed and terminated employees
detect_changes() {
    echo "[INFO] Detecting changes..."

    echo "username,department" > output/added_users.csv
    echo "username,department" > output/removed_users.csv
    echo "username,department" > output/terminated_users.csv

    # ADDED USERS
    tail -n +2 employees.csv | while IFS=',' read -r id username name dept status; do
        if ! awk -F',' -v u="$username" '$2==u {found=1} END{exit !found}' output/archives/last_employees.csv; then
            if [ "$status" = "active" ]; then
                echo "$username,$dept" >> output/added_users.csv
            fi
        fi
    done

    # REMOVED USERS
    tail -n +2 output/archives/last_employees.csv | while IFS=',' read -r id username name dept status; do
        if ! awk -F',' -v u="$username" '$2==u {found=1} END{exit !found}' employees.csv; then
            echo "$username,$dept" >> output/removed_users.csv
        fi
    done

    # TERMINATED USERS
    tail -n +2 employees.csv | while IFS=',' read -r id username name dept status; do
        if [ "$status" = "terminated" ]; then
            echo "$username,$dept" >> output/terminated_users.csv
        fi
    done
}

# Create Linux user for active employees
create_linux_user() {
    local username="$1"
    local department="$2"

    if id "$username" &>/dev/null; then
        echo "[INFO] $username already exists, skipping."
        return
    fi

    if ! getent group "$department" >/dev/null; then
        sudo groupadd "$department"
    fi

    sudo useradd -m -g "$department" "$username"
    echo "[INFO] Created user: $username"
}

# Onboard active employees
onboard_active_employees() {
    echo "[INFO] Onboarding active employees..."

    tail -n +2 employees.csv | while IFS=',' read -r id username name dept status; do
        if [ "$status" = "active" ]; then
            create_linux_user "$username" "$dept"
        fi
    done
}

# Update snapshot after processing
update_snapshot() {
    echo "[INFO] Updating snapshot..."

    mkdir -p output/archives
    rm -f output/archives/last_employees.csv

    if cp employees.csv output/archives/last_employees.csv; then
        echo "[INFO] Snapshot updated successfully."
    else
        echo "[ERROR] Snapshot update failed!" >&2
        exit 1
    fi
}

# MAIN FUNCTION (ORDER IS CRITICAL)
main() {
    init_snapshot_if_needed
    detect_changes
    onboard_active_employees
    update_snapshot
}

main "$@"
