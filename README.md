# H73-A23-TP3-william

Un projet Terraform dans le but d'automatiser l'installation d'un serveur MatterMost. Ce projet est construit pour être utilisé sur une machine Linux.


## Table des matières
1. [Prérequis](#prérequis)
2. [Environnement](#environnement)
3. [Automatisation](#automatisation)
  1. [Enregistrer un nom de domaine](#enregistrer-un-nom-de-domaine)
  2. [Obtenir un certificat par Let's Encrypt](#obtenir-un-certificat-par-lets-encrypt)
  3. [Modifier la configuration de Mattermost](#modifier-la-configuration-de-mattermost)
4. [Instance AWS](#instance-aws)
5. [Mode d'emploi](#mode-demploi)



## Prérequis

* Un compte chez [NoIP](https://www.noip.com)
* Un nom de domaine déjà enregistré à votre nom chez Noip
* Awscli installé sur votre machine
* Vos informations de connexion chez AWS dans le fichier ~/.aws/credentials. Exemple:
    ```
    aws_access_key_id=<L'id de votre clé d'accès>
    aws_secret_access_key=<Votre clé secrète d'accès>
    aws_session_token=<Votre token de session>
    ```
* Terraform installé

## Environnement

Le serveur Mattermost sera hébergé dans une instance AWS d'une machine Ubuntu. Celle-ci aura le service Mattermost avec un serveur reverse proxy Nginx qui permet à notre serveur de se connecter par HTTPS. En temps normal, celui-ci devrait être sur une autre machine se trouvant souvent dans une zone accessible par le public dans un pare-feu.


## Automatisation

Voici différentes parties du projet qui permettent au projet d'être automatisé au maximum.

### Enregistrer un nom de domaine
-----
Le script [update-domain-ip](./terraform-deploiment/script/exec/update-domain-ip.sh) envoie une requête HTTP à NoIP qui permet de mettre à jour les valeurs d'une entrée de domaine enregistrée par vous. Vos informations d'authentification sont encodées avec base64 et sont placées dans l'entrée authentication de l'en-tête de la requête. Voici un exemple d'URL utilisé pour faire la requête:
```
https://dynupdate.no-ip.com/nic/update?myip=127.0.0.1&hostname=tp3-will.ddns.net
```

### Obtenir un certificat par Let's Encrypt
------

Pour obtenir un certificat SSL, le script exécutera simplement cette commande de certbot:
```
certbot \
    # Permet d'éviter d'avoir à entrer des valeurs manuellement
    --agree-tos \
    --register-unsafely-without-email \
    # vu que nous utilisons un serveur nginx comme proxy
    --nginx \
    # rediriger http vers https
    --redirect \
    # nom de domaine fourni
    d domain.com 
``` 

### Modifier la configuration de Mattermost
------

Le fichier de configuration de Mattermost est dans le format JSON. Pour cette raison, j'ai utilisé le programme en ligne de commande appelé jq. Celui-ci permet d'interagir avec un fichier JSON plus adéquatement qu'un utilitaire comme sed.


## Instance AWS

Type: t2.small

Ports:
* 80 et 443 sont ouverts à tous le monde
* 22 est seulement ouvert pour l'adresse IP de l'exécuteur



## Mode d'emploi

1. Installer ce dépôt à votre emplacement de choix
2. Si vous ne voulez pas avoir à entrer à l'exécution vos informations, vous devez ajouter ces variables d'environnement à votre session:
    ```
    export TF_VAR_DOMAIN=<Votre nom de domaine>
    export TF_VAR_NOIP_USER=<Votre nom d'utilisateur de NoIP>
    export TF_VAR_NOIP_PASSWD=<Votre mot de passe de NoIP>
    ```
3. Dirigez-vous dans le dossier terraform-deploiement:
    ```
    cd terraform-deploiment
    ```
4. Initialiser votre environnement:
    ```
    terraform init
    ```
5. Démarrer votre exécution:
    ```
    terraform apply --auto-approve
    ```