# CMPE 341 - OPERATING SYSTEMS
# Employee Lifecycle Project

This project was developed for the CMPE341 Operating Systems course.  
It automates employee account management on a Linux system using data from a CSV file.

The script reads `employees.csv`, compares it with a previous snapshot, and performs the necessary actions:

- Onboards new active employees
- Locks and archives terminated employees
- Detects removed employees
- Keeps state information using a snapshot file
- Generates reports and logs for each run

The goal is to synchronize HR records with Linux user accounts in a repeatable way.

---

## How It Works

1. The script reads and normalizes `employees.csv`.
2. It compares the current file with `output/last_employees.csv`.
3. Changes are detected using the `comm` command:
   - Added users: appear in the current CSV but not in the snapshot
   - Removed users: appear in the snapshot but not in the current CSV
   - Terminated users: still listed, but status is "terminated"
4. Added users are onboarded:
   - A Linux group is created if missing
   - A user account is created and assigned to the group
5. Removed or terminated users are offboarded:
   - Their account is locked
   - Their home folder is archived under `output/archives/`
6. A manager report is generated for every run.
7. Logs are written to `output/logs/lifecycle_sync.log`.
8. The snapshot file updates for the next run.

---

## Files and Folders Created

The script automatically builds the following structure:

```
output/
├── last_employees.csv
├── logs/
│   └── lifecycle_sync.log
├── reports/
│   └── manager_update_*.txt
└── archives/
    └── *.tar.gz
```
---

## CSV Format

The employees.csv file must follow this structure:
employee_id,username,name_surname,department,status
Status values used:
- active → account should exist or be created
- terminated → account should be locked and archived

---

## Running the Script

Make it executable:
chmod +x employee_lifecycle_sync.sh

Run it:
./employee_lifecycle_sync.sh

If nothing changes in employees.csv, the output report will show zeros.  
If changes exist, onboarding or offboarding steps run accordingly.

---

## Notes and Testing

- The script was tested multiple times with:
  - new users added
  - removed users
  - terminated users
  - status changes
- Re-running the script without modifying employees.csv does not repeat actions.
- Archived home directories are stored with timestamps.
- Groups are created once and not duplicated.

This project demonstrates practical Linux scripting:
CSV parsing, account automation, archiving, and logging.
