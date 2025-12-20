
CMPE 341 - OPERATING SYSTEMS(Program in Python) Code for Project 2 Task 4 and onwards: #STUDENTS ARE TO COMPLETE THIS PORTION AS THEIR PROJECT$form of a file.

Employee Lifecycle Project
This project is implemented for the course CMPE341 Operating Systems. It deals with employee account details management on the Linux system and getting them from a CSV file. 
The script reads employees.csv, compares it with a previous copy, and performs the following actions:
Onboard active new employees.
Lock and archiving of inactive employees.
Detect removed employees.
Maintain a snapshot file with its state information.
Issue such as reports and logs every run.
Somehow synchronize the HR records and the Linux user accounts in a reproducible manner.


How it works 
The employees file is read and parsed:getValue((Name,Age,Job,)):normal(Age,Position):time(Weekday,HStart,,HEnd) the weight for normalisation. csv.
It checks the present file with output/last_employees.csv.
From this point forward the changes can be assessed using the comm command.
New users: Exist in the current CSV but do not exist in snapshot 
Deleted users: are in the snapshot but are not listed in the current CSV 
Terminated users: still appearing but with a status of "terminated"
Users added are onboarded:
Birthday Party: User added to Linux group if it does not exist 
New User added to Group 
When users are deleted or deactivated, they have been off-boarded: 
Account Is Locked 
Home Directory Is Archived in output/archives/ 
For every run, a management report is generated. 
Logs are written to `output/logs/lifecycle_sync.log`. 
In the snapshot file, the next run will be updated.
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

It contains employee_id, username, name_surname, department, and status in employees.csv.

The status field has only two values.
* **active**: It means that the account should be open or newly created.
* AN ACCOUNT MAY CHANGE FROM ACTIVE TO TERMINATED, MEANS ACCOUNT PUT OFF FOR REALISE, BUT FOR USANCE PERIOD.

***.

Running the Script.

Before executing employee_lifecycle_sync.sh, give the file execute permission using the command below.
Give execute permission to file employee_lifecycle_sync.sh

After the permissions have been set, the script can be initiated by running it
`./employee_lifecycle_sync.sh`.

The report will indicate zero changes if the employees.csv file is not modified. The system will perform relevant onboarding or offboarding if any changes are noted.

***.

Essential Things and Checks. 

This script has undergone rigorous testing under multiple conditions including adding new users, deleting current users, handling deactivated users, and manipulating their status change, among others.

Essentially, it means that on re-executing the script just as it is, without changing `employees.csv`, nothing will happen twice. Also, all old user home directories are time-stamped for their creation, and unique user groups are created without duplication.

This is a great project that shows a practical application of Linux Scripting.
Processing CSV files, automating accounts, storage and logging.
