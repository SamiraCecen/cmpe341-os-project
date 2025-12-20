# CMPE 341 - OPERATING SYSTEMS  
 # Code for Project 2 Task 4 and onwards  
---

# Employee Lifecycle Project

This project is implemented for the course CMPE 341 Operating Systems.  
It deals with employee account details management on the Linux system and
getting them from a CSV file.

The script reads `employees.csv`, compares it with a previous copy, and
performs the following actions:

- Onboard active new employees.  
- Locks and archives inactive employees.  
- Detects removed employees.  
- Maintains a snapshot file with its state information.  
- Issues such as reports and logs every run.  
- Somehow synchronize the HR records and the Linux user accounts in a reproducible manner.

---

# How it works

The employees file is read and parsed:  
`getValue((Name,Age,Job,)):normal(Age,Position):time(Weekday,HStart,,HEnd)`  
the weight for normalisation. csv.

It checks the present file with `output/last_employees.csv`.

From this point forward the changes can be assessed using the `comm` command.

- **New users**: Exist in the current CSV but do not exist the snapshot  
- **Deleted users**: are in the snapshot but are not listed in the current CSV  
- **Terminated users**: still appearing but with a status of `"terminated"`

---

# Users added are onboarded

- Birthday Party: User added to Linux group if it does not exist  
- New User added to Group  

---

# Off-boarding

When users are deleted or deactivated, they have been off-boarded:

- Account Is Locked  
- Home Directory Is Archived in `output/archives/`

For every run, a management report is generated.  
Logs are written to `output/logs/lifecycle_sync.log`.

In the snapshot file, the next run will be updated.

---

# Files and Folders Created

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

# CSV File Content

It contains `employee_id`, `username`, `name_surname`, `department`,
and `status` in `employees.csv`.

# Status Field

The status field has only two values:

- **active**: It means that the account should be open or newly created.  
- **terminated**: AN ACCOUNT MAY CHANGE FROM ACTIVE TO TERMINATED,  
  MEANS ACCOUNT PUT OFF FOR REALISE, BUT FOR USANCE PERIOD.
# Running the Script

Before executing `employee_lifecycle_sync.sh`, give the file execute permission
using the command below:

chmod +x employee_lifecycle_sync.sh

#Essential Things and Checks

-This script has undergone rigorous testing under multiple conditions including
adding new users, deleting current users, handling deactivated users, and
manipulating their status change, among others.

-Essentially, it means that on re-executing the script just as it is, without
changing employees.csv, nothing will happen twice.

-Also, all old user home directories are time-stamped for their creation, and
unique user groups are created without duplication.
