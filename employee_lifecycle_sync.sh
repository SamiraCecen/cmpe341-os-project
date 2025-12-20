#!/bin/bash

# ---------------------------------------------------------
# CMPE341 - Employee Lifecycle CSV Sync
# Onboarding + Offboarding automation
# ---------------------------------------------------------

EMP_FILE="employees.csv"

OUTPUT_DIR="output"
LOG_DIR="$OUTPUT_DIR/logs"
REPORT_DIR="$OUTPUT_DIR/reports"
ARCHIVE_DIR="$OUTPUT_DIR/archives"

SNAPSHOT="$OUTPUT_DIR/last_employees.csv"
CURRENT_NORM="$OUTPUT_DIR/current_employees.csv"

ADDED_USERS="$OUTPUT_DIR/added_users.csv"
REMOVED_USERS="$OUTPUT_DIR/removed_users.csv"
TERMINATED_USERS="$OUTPUT_DIR/terminated_users.csv"

LOG_FILE="$LOG_DIR/lifecycle_sync.log"

# Pass manager email as first argument if you want real mail
MANAGER_EMAIL="$1"

# ---------------------------------------------------------
# Basic helpers
# ---------------------------------------------------------

log_msg() {
    local msg="$1"
    local ts
    ts=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$ts  $msg" >> "$LOG_FILE"
}

init_structure() {
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$REPORT_DIR"
    mkdir -p "$ARCHIVE_DIR"
    touch "$LOG_FILE"
}

# ---------------------------------------------------------
# Normalize employees.csv (remove header, sort)
# We keep: id,username,department,status
# ---------------------------------------------------------

normalize_current_csv() {
    if [ ! -f "$EMP_FILE" ]; then
        echo "employees.csv not found. Exiting."
        exit 1
    fi

    awk -F',' 'NR>1 {print $1","$2","$4","$5}' "$EMP_FILE" | sort > "$CURRENT_NORM"
}

# ---------------------------------------------------------
# First run: no snapshot yet
# ---------------------------------------------------------

first_run_setup() {
    log_msg "First run detected. Creating initial snapshot."

    cp "$CURRENT_NORM" "$SNAPSHOT"

    echo "username,department" > "$ADDED_USERS"
    echo "username,department" > "$REMOVED_USERS"
    echo "username,department" > "$TERMINATED_USERS"

    # All active employees in the first CSV are considered "added"
    while IFS=',' read -r id username dept status; do
        [ -z "$id" ] && continue
        if [ "$status" = "active" ]; then
            echo "$username,$dept" >> "$ADDED_USERS"
        fi
        if [ "$status" = "terminated" ]; then
            echo "$username,$dept" >> "$TERMINATED_USERS"
        fi
    done < "$CURRENT_NORM"
}

# ---------------------------------------------------------
# Detect added / removed / terminated using comm
# ---------------------------------------------------------

detect_changes() {
    log_msg "Detecting changes compared to last snapshot."

    echo "username,department" > "$ADDED_USERS"
    echo "username,department" > "$REMOVED_USERS"
    echo "username,department" > "$TERMINATED_USERS"

    local new_only="$OUTPUT_DIR/new_only.tmp"
    local old_only="$OUTPUT_DIR/old_only.tmp"

    # Lines only in current (added) and only in snapshot (removed)
    comm -13 "$SNAPSHOT" "$CURRENT_NORM" > "$new_only"
    comm -23 "$SNAPSHOT" "$CURRENT_NORM" > "$old_only"

    # Added employees: only in new, and status = active
    while IFS=',' read -r id username dept status; do
    [ -z "$id" ] && continue

    # if username existed before snapshot → NOT added
    if grep -q "$username" "$SNAPSHOT"; then
        continue
    fi

    # if user truly new and active
    if [ "$status" = "active" ]; then
        echo "$username,$dept" >> "$ADDED_USERS"
    fi
    done < "$new_only"
    # Removed employees: only those truly gone (not terminated)
    while IFS=',' read -r id username dept status; do
    [ -z "$id" ] && continue
    if ! grep -q "$username" "$CURRENT_NORM"; then
        echo "$username,$dept" >> "$REMOVED_USERS"
    fi
    done < "$old_only"
    # Terminated employees: still in CSV but status = terminated
    while IFS=',' read -r id username dept status; do
        [ -z "$id" ] && continue
        if [ "$status" = "terminated" ]; then
            echo "$username,$dept" >> "$TERMINATED_USERS"
        fi
    done < "$CURRENT_NORM"

    rm -f "$new_only" "$old_only"
}

# ---------------------------------------------------------
# Onboarding: create group and user for added employees
# ---------------------------------------------------------

onboard_users() {
    log_msg "Onboarding phase started."

    # skip header
    tail -n +2 "$ADDED_USERS" | while IFS=',' read -r username dept; do
        [ -z "$username" ] && continue

        # Create group if missing
        if ! getent group "$dept" > /dev/null 2>&1; then
            log_msg "Creating group: $dept"
            sudo groupadd "$dept"
        fi

        # Create user if missing
        if ! id "$username" > /dev/null 2>&1; then
            log_msg "Creating user: $username (group: $dept)"
            sudo useradd -m -g "$dept" "$username"
        else
            # If user exists, make sure they are in the department group
            log_msg "User $username already exists, ensuring group membership."
            sudo usermod -aG "$dept" "$username"
        fi
    done
}

# ---------------------------------------------------------
# Archive home directory of a user
# ---------------------------------------------------------

archive_home() {
    local user="$1"

    # Find home directory via getent
    local home_dir
    home_dir=$(getent passwd "$user" | cut -d: -f6)

    if [ -z "$home_dir" ] || [ ! -d "$home_dir" ]; then
        log_msg "Home directory not found for user $user, skipping archive."
        return
    fi

    local ts
    ts=$(date "+%Y%m%d_%H%M%S")
    local archive_file="$ARCHIVE_DIR/${user}_${ts}.tar.gz"

    log_msg "Archiving home of $user to $archive_file"
    sudo tar -czf "$archive_file" -C "$home_dir/.." "$(basename "$home_dir")"
}

# ---------------------------------------------------------
# Offboard (lock + archive) users
# ---------------------------------------------------------

offboard_users() {
    log_msg "Offboarding phase started."

    local combined="$OUTPUT_DIR/offboard_raw.csv"
    local final_list="$OUTPUT_DIR/offboard_final.csv"

    # Merge removed and terminated lists (without headers)
    tail -n +2 "$REMOVED_USERS" > "$combined"
    tail -n +2 "$TERMINATED_USERS" >> "$combined"

    # If there is nothing, just return
    if [ ! -s "$combined" ]; then
        rm -f "$combined"
        return
    fi

    # Sort and keep unique usernames (by first column)
    sort -t',' -k1,1 -u "$combined" > "$final_list"

    while IFS=',' read -r username dept; do
        [ -z "$username" ] && continue

        if id "$username" > /dev/null 2>&1; then
            log_msg "Locking user account: $username"
            sudo usermod -L "$username"
            archive_home "$username"
        else
            log_msg "User $username does not exist on system, skipping."
        fi
    done < "$final_list"

    rm -f "$combined" "$final_list"
}

# ---------------------------------------------------------
# Manager report (human readable)
# ---------------------------------------------------------

generate_report() {
    local ts
    ts=$(date "+%Y-%m-%d %H:%M:%S")
    local file_ts
    file_ts=$(date "+%Y%m%d_%H%M%S")

    local report_file="$REPORT_DIR/manager_update_${file_ts}.txt"

    # Count entries (ignore header)
    local added_count removed_count terminated_count

    if [ -f "$ADDED_USERS" ]; then
        added_count=$(( $(wc -l < "$ADDED_USERS") - 1 ))
    else
        added_count=0
    fi

    if [ -f "$REMOVED_USERS" ]; then
        removed_count=$(( $(wc -l < "$REMOVED_USERS") - 1 ))
    else
        removed_count=0
    fi

    if [ -f "$TERMINATED_USERS" ]; then
        terminated_count=$(( $(wc -l < "$TERMINATED_USERS") - 1 ))
    else
        terminated_count=0
    fi

    {
        echo "Manager Employee Update"
        echo "Timestamp: $ts"
        echo "Mode: LIVE"
        echo
        echo "Summary"
        echo "--------"
        echo "Added employees (active): $added_count"
        echo "Removed employees:        $removed_count"
        echo "Offboarded by status:     $terminated_count"
        echo
        echo "Added employees (username, department)"
        echo "--------------------------------------"
        tail -n +2 "$ADDED_USERS"
        echo
        echo "Removed employees (username, department)"
        echo "----------------------------------------"
        tail -n +2 "$REMOVED_USERS"
        echo
        echo "Terminated employees processed by status"
        echo "----------------------------------------"
        tail -n +2 "$TERMINATED_USERS"
        echo
        echo "Paths"
        echo "-----"
        echo "Log file       : $LOG_FILE"
        echo "Archives folder: $ARCHIVE_DIR"
        echo "Snapshot file  : $SNAPSHOT"
    } > "$report_file"

    log_msg "Manager report generated: $report_file"

    # Optional mailing (only if mail exists and email is given)
    if command -v mail > /dev/null 2>&1 && [ -n "$MANAGER_EMAIL" ]; then
        log_msg "Sending report by email to $MANAGER_EMAIL"
        mail -s "Employee Lifecycle Update" "$MANAGER_EMAIL" < "$report_file"
    fi
}

# ---------------------------------------------------------
# Update snapshot for the next run
# ---------------------------------------------------------

update_snapshot() {
    log_msg "Updating snapshot file."
    cp "$CURRENT_NORM" "$SNAPSHOT"
}

# ---------------------------------------------------------
# Main flow
# ---------------------------------------------------------

main() {
    init_structure
    normalize_current_csv

    if [ ! -f "$SNAPSHOT" ]; then
        first_run_setup
    else
        detect_changes
    fi

    onboard_users
    offboard_users
    generate_report
    update_snapshot

    echo "Lifecycle sync finished. Check $LOG_FILE and $REPORT_DIR."
}

main "$@"
