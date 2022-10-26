#!/bin/bash

function cert(){
        echo "---------------------------"
        echo "Certification: "$1
        echo "---------------------------"
        sudo certbot --nginx -d $1
}

function add(){
        if [[ "$#" -ne 2 ]];then
                echo "Erreur"
        else
                echo "$1;$2" >> ./listeSite.txt
        fi
}

function list(){
         while read ligne;
         do
                key=$(echo $ligne | cut -d ";" -f 1)
                valeur=$(echo $ligne | cut -d ";" -f 2)
                echo "Nom :"$key
                echo "Sous domaine: "$valeur
        done < listeSite.txt
}

function precertification(){
        declare -A domaine=()
        while read ligne;
        do
                key=$(echo $ligne | cut -d ";" -f 1)
                valeur=$(echo $ligne | cut -d ";" -f 2)
                domaine[$key]=$valeur
        done < listeSite.txt
        doma=${domaine[$1]}
        if [[ $doma ]]
        then
                echo "Sous domaine: "$doma
                certification=$doma".domaine.fr"
                echo "Domaine à certifier: "$certification
                cert $certification
        else
                echo "Error"
        fi
}
function addproxy(){
        echo "Création dossier log $4:"
        error=$(mkdir /var/log/nginx/$4 2>&1)
        if [[ $error == *"Le fichier existe"* ]];
        then
                echo "Le dossier existe déjà"
        else
                echo "Ok"
        fi
        echo -e "\n\n"
        echo "Ecriture dans le fichier de configuration: $3"
        proxyconf="server {"
        proxyconf="$proxyconf\n         server_name $1.domaine.fr;"
        proxyconf="$proxyconf\n"
        proxyconf="$proxyconf\n         access_log /var/log/nginx/$4/https.access.log;"
        proxyconf="$proxyconf\n         error_log /var/log/nginx/$4/https.error.log;"
        proxyconf="$proxyconf\n"
        proxyconf="$proxyconf\n         location / {"
        proxyconf="$proxyconf\n                         proxy_set_header Host \$host;"
        [[ $2 == *"80"* ]] && proxyconf="$proxyconf\n                           proxy_pass http://$2;" || proxyconf="$proxyconf\n                                proxy_pass https://$2;"
        proxyconf="$proxyconf\n         }"
        proxyconf="$proxyconf\n"
        proxyconf="$proxyconf\n         listen 443 ssl;"
        proxyconf="$proxyconf\n}"
        echo "Configuration port 443 ok"
        proxyconf+="\n\nserver {"
        proxyconf+="\n  if (\$host = $1.domaine.fr) {"
        proxyconf+="\n          return 301 https://\$host\$request_uri;"
        proxyconf+="\n  }"
        proxyconf+="\n"
        proxyconf+="\n  listen 80;"
        proxyconf+="\n  server_name $1.domaine.fr;"
        proxyconf+="\n  return 404;"
        proxyconf+="\n}"
        echo "Configuration redirection port 80 Ok"

        echo -e $proxyconf >> /etc/nginx/sites-available/$3

        echo "Redemarage service nginx"
        systemctl restart nginx
        certification $2
}

function help(){
        echo "-a | -add: Permet d'ajouter un domain dans la liste"
        echo "          ex: ./certbot.sh --add ex exemple"
        echo "-c | --cert: Permet de lancer la certification d'un domaine de la liste"
        echo "          ex: ./certbot.sh --cert ex"
        echo "-l | --list: Permet d'afficher la liste des sites disponibles"
        echo "          ex: ./certbot.sh --list "
        echo "-p | --proxy: Permet d'ajouter un domain au reverse proxy"
        echo "          Parametre: sous-domaine"
        echo "                     Ip et port forme ip:port"
        echo "                     fichier de destination"
        echo "                     chemin des log (path racine /nginx"
        echo "          ex: ./certbot.sh --proxy exemple 127.0.0.1 domaine.com exemple"
}
function proxy(){
        if [[ "$#" -eq 4 ]];then
        addproxy $1 $2 $3 $4 # domaine ip fichierecriture chemainlog
        else
        help
        fi
}

case $1 in
-a | --add)
add $2 $3;;
-c | --cert)
precertification $2;;
-l | --list)
list $2;;
-p | --proxy)
proxy $2 $3 $4 $5;;
-h | --help)
help;;
*)
help;;
esac
