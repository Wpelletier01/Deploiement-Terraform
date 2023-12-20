
BASE_URL="https://dynupdate.no-ip.com/nic/update"
username=""
passwd=""
domain_name=""
ip=""

if [ "$#" -eq 0 ]; then 
    echo "vous avez passer aucun arguments"
    exit 1
fi


while [ $# -gt 0 ]; do 

    case "${1}" in 

        -u | --username)
            
            if [ "$2" == "" ]; then
                echo "vous devez entrer un nom d'utilisateur"
                exit 1
            fi 

            username="$2"

            shift
            ;;

        -p | --password)

            if [ "$2" == "" ]; then
                echo "vous devez entrer un mot de passe"
                exit 1
            fi 

            passwd="$2"
            shift
            ;;

        -d | --domain-name)

            if [ "$2" == "" ]; then
                echo "vous devez entrer un nom de domain"
                exit 1
            fi 

            domain_name="$2"
            shift
            
            ;;
        -i | --ip)

            if [ "$2" == "" ]; then
                echo "vous devez entrer un adresse IP"
                exit 1
            fi 

            ip=$2
            shift
            ;;

        *)
            echo "$1 argument inconnu a ete passer"
            exit 1

    esac
    shift 

done 



encoded_auth=$( echo -n "$username:$passwd" | base64)


resp=$( curl \
  --silent \
  --header "Authorization: Basic $encoded_auth" \
  --header 'User-Agent: Rosemont tp3/Linux manjarov2 6.5.9-1-MANJARO 1834089@crosemont.qc.ca' \
  "$BASE_URL?myip=$ip&hostname=$domain_name"
)

if [[ $resp == *"good"* ]]; then 

    echo "L'adresse ip $ip a ete attribuer a $domain_name avec succes"

elif [[ $resp == *"nochg"* ]]; then 

    echo "L'adresse ip $ip etait deja attribue a $domain_name"

else 

    echo "Statut inconnu: $resp"
    exit 1

fi 

