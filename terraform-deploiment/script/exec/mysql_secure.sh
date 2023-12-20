#!/bin/bash

mysqladmin password "crosemont"

mysql -e "DELETE FROM mysql.user WHERE User=''"

mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"

mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"

mysql -e "FLUSH PRIVILEGES"

