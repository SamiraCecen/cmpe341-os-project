#!/bin/bash

# ------------------------------------------
# SAMIRA – ONBOARDING
# ------------------------------------------

create_linux_user() {
    local username="$1"
    local department="$2"

    # Skip if it is avaliable on system
    if id "$username" &>/dev/null; then
        echo "[INFO] $username already exists, skipping."
        return
    fi

    # Departmant group check; if not exists, create
    if ! getent group "$department" >/dev/null; then
        sudo groupadd "$department"
    fi

    # adding user  (for -m home file)
    sudo useradd -m -g "$department" "$username"

    echo "[INFO] Created user: $username"
}

onboard_active_employees() {
    echo "[INFO] Onboarding active employees..."

    while IFS=',' read -r emp_id username name_surname department status; do
        if [ "$status" = "active" ]; then
            create_linux_user "$username" "$department"
        fi
    done < <(tail -n +2 employees.csv)
}

main() {
    onboard_active_employees
}

main "$@"
