
CMPE 341 - OPERATING SYSTEMS(Program in Python) Code for Project 2 Task 4 and onwards: #STUDENTS ARE TO COMPLETE THIS PORTION AS THEIR PROJECT$form of a file.

Employee Lifecycle Project
This project is implemented for the course CMPE341 Operating Systems.
It is for managing employee account details on a Linux system and grabbing them from a CSV file.
The script reads employees. csv, compares to a previous copy and undertakes the actions:
Onboards new active employees
Locks and archives inactive employees
Detects removed employees
Retains its state information in a snapshot file.
Issue such as reports and logs per each run
The idea is to somehow sync HR records with Linux user accounts in a reproducible fashion.


 How It Works
 The employees file is read and parsed:getValue((Name,Age,Job,)):normal(Age,Position):time(Weekday,HStart,,HEnd) the weight for normalisation. csv.
 It check the present file with output/last_employees. csv`.
 Then you can figure out the changes with the help of the comm command:
 New users: Exist in the current CSV but do not exist in snapshot.
 Deleted users: are in the snapshot but are not listed in the current CSV
 Terminated users: still appearing, but the status is "terminated"
 Added users are onboarded:
 Added creation of a Linux group if it does not exist
 a new user is added to the group
 When a user is deleted or deactivated, that user has been offboarded:
 Their account is locked
 Their home directory is archived in output/archives/
 A manager report is generated for every run.
 Logs are written to `output/logs/lifecycle_sync.log`.
 The snapshot file updates for the next run.

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

The `employees.csv` file is structured to include the following fields: `employee_id`, `username`, `name_surname`, `department`, and `status`.

The `status` field accepts two primary values:
*   **active**: This indicates that an account should be present or newly established.
*   **terminated**: This signifies that an account should be deactivated and archived.

***

### Executing the Script

Before execution, the `employee_lifecycle_sync.sh` script must be granted executable permissions using the command:
`chmod +x employee_lifecycle_sync.sh`

Once permissions are set, the script can be initiated by running:
`./employee_lifecycle_sync.sh`

If the `employees.csv` file contains no modifications, the generated report will reflect a zero change count. Conversely, if alterations are detected, the system will proceed with the appropriate onboarding or offboarding sequences.

***

### Important Considerations and Verification

This script has undergone comprehensive testing across a range of scenarios, including the addition of new user accounts, the removal of existing users, the management of terminated accounts, and various status adjustments.

A key feature is that re-executing the script without any modifications to `employees.csv` will not result in redundant actions. Furthermore, archived user home directories are automatically timestamped for precise record-keeping, and user groups are established uniquely, preventing any duplication.

This project demonstrates practical Linux scripting:
CSV parsing, account automation, archiving, and logging.
