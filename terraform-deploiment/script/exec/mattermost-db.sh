#!/bin/bash

# Creer un utilisateur pour mattermost
mysql -e "create user 'mmuser'@'localhost' identified by 'tp3-crosemont'"
# Creer la base de donner qu'il utillisera
mysql -e "create database mattermost"
# Donne acces complet a l'utilisateur mmuser pour la base de donne mattermost
mysql -e "grant all privileges on mattermost.* to 'mmuser'@'localhost'"

mysql -e "FLUSH PRIVILEGES"