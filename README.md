## MS_SQL_analysis

In this pluto notebook, an example is shown on how to connect to a MS SQL
server on Linux using Julia.

### Prerequisites

#### SQL Server 2022
You need to have a SQL server running. Easiest way to set it up is via Docker.
Instructions for SQL Server 2022 are given [here.](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-linux-ver16&preserve-view=true&pivots=cs1-bash#pullandrun2022)

#### Microsoft ODBC driver 17 for Linux
Instructions are given [here.](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16&tabs=alpine18-install%2Cubuntu17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline#17)

#### sqlcmd utility (optional)
The sqlcmd utility lets you enter Transact-SQL statements, and is great to test if
everything is working as expected. Follow instructions [here.](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-linux-ver16&tabs=redhat-install%2Credhat-offline#install-tools-on-linux)