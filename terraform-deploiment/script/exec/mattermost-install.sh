
DSOURCE="mmuser:tp3-crosemont@tcp(localhost:3306)/mattermost?charset=utf8mb4,utf8\u0026writeTimeout=30s"

# Entrepose l'adress ip public du serveur
pubip=$(curl https://ipv4.icanhazip.com/)
# Mettre a jour les info sur notre domaine
./script/exec/update-domain-ip.sh \
    --domain-name "$1" \
    --username "$2" \
    --password "$3" \
    --ip $pubip

# Installer les programmes qu'on a besoin
apt update -y
apt install mysql-server mysql-client jq nginx python3-certbot-nginx -y

# Securiter de base de notre service mysqld
script/exec/mysql_secure.sh
# Initialiser une base de donner pour mattermost
script/exec/mattermost-db.sh
# Installer Mattermost
wget https://releases.mattermost.com/9.1.2/mattermost-9.1.2-linux-amd64.tar.gz

tar -xvzf mattermost*.gz
# Creer un utilisateur pour mattermost
useradd --system --user-group mattermost
# Donne tous les droit pour modifier le fichier de config de base
chmod 777 mattermost/config/config.json
# Changer les paremetres sql pour specifier qu'on utilise mysql. Il utilise postgresql
jq \
    --arg dsrc $DSOURCE  \
    --arg url "https://$1" \
    '.SqlSettings.DriverName="mysql" | .SqlSettings.DataSource=$dsrc | .ServiceSettings.SiteURL=$url' \
    mattermost/config/config.json > mattermost/config/tmp.json
# Redonne les droit que le fichier avait au depart
chmod 620 mattermost/config/tmp.json && mv mattermost/config/tmp.json mattermost/config/config.json

mv mattermost /opt/
mkdir /opt/mattermost/data

chown -R mattermost:mattermost /opt/mattermost

chmod -R g+w /opt/mattermost

# Registrer notre service mattermost
mv script/config/mattermost.service /lib/systemd/system/
systemctl daemon-reload
systemctl enable mattermost
# Initialiser la config de base du proxy Nginx et deplacer au bon endroit celle-ci
sed "s/server_name d0main;/server_name $1;/g" script/config/nginx-base.conf > script/config/$1.conf
mv script/config/$1.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf

systemctl restart nginx

systemctl start mattermost
# Recevoir un certificat ssl pour notre proxy Nginx
certbot --agree-tos --register-unsafely-without-email --nginx --redirect -d $1