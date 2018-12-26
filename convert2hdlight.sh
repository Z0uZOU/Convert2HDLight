#!/bin/bash

# Idée :
# vérifier que le fichier_base soit bien celui du .desktop (pour autres scripts aussi)
# peut être plusieurs profiles HDLight (sans toucher le son par exemple)
# fonction optionnelle avancée (FileBot peut récup les sous titre... les ajoutés)
# prendre en charge les petits fichiers (handbrake)
# quand filebot pas installé ./convert2hdlight.sh: ligne 547: filebot : commande introuvable
# Ne pas encoder de la merde, 720p ou 1080p DVDRiP uniquement
 
########################
## Script de Z0uZOU
########################
## Installation bin: wget -q https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/convert2hdlight.sh -O convert2hdlight.sh && sed -i -e 's/\r//g' convert2hdlight.sh && shc -f convert2hdlight.sh -o convert2hdlight.bin && chmod +x convert2hdlight.bin && rm -f *.x.c && rm -f convert2hdlight.sh
## Installation sh: wget -q https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/convert2hdlight.sh -O convert2hdlight.sh && sed -i -e 's/\r//g' convert2hdlight.sh && chmod +x convert2hdlight.sh
## Micro-config
version="Version: 0.0.1.60" #base du système de mise à jour
description="Convertisseur en HDLight" #description pour le menu
script_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/convert2hdlight.sh" #emplacement du script original
changelog_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/Changelog/convert2hdlight" #emplacement du changelog de ce script
icone_github="https://github.com/Z0uZOU/Convert2HDLight/raw/master/.cache-icons/convert2hdlight.png" #emplacement de l'icône du script
#required_repos="ppa:neurobin/ppa ppa:webupd8team/java ppa:stebbins/handbrake-releases" #ajout de repository
required_repos="ppa:webupd8team/java ppa:stebbins/handbrake-releases" #ajout de repository
required_tools="oracle-java8-installer handbrake-cli trash-cli curl mlocate lm-sensors shc mediainfo nemo" #dépendances du script
required_tools_pip="" #dépendances du script (PIP)
script_cron="0 * * * *" #ne définir que la planification
verification_process="HandBrakeCLI" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
mon_fichier_json_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/hdlight-encode.json" #lien vers le fichier json, fichier nécessaire pour la conversion
mon_script_argos_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/Argos/convert2hdlight.c.1s.sh" #lien vers le script Argos
lien_filebot="https://github.com/Z0uZOU/Convert2HDLight/tree/master/FileBot" #lien vers l'installer de filebot 
########################
 
#### Vérification que le script possède les droits root
## NE PAS TOUCHER
if [[ "$EUID" != "0" ]]; then
  if [[ "$CRON_SCRIPT" == "oui" ]]; then
    exit 1
  else
    echo "Vous devrez impérativement utiliser le compte root"
    exit 1
  fi
fi
 
#### Création du fichier .stop-convert
if [[ "$1" == "--stop-convert" ]]; then
  mon_stop=`echo "/root/.config/convert2hdlight/.stop-convert"`
  touch "$mon_stop"
  echo "Création du fichier .stop-convert"
  exit 1
fi
 
#### Vérification de process pour éviter les doublons (commandes externes)
for process_travail in $verification_process ; do
  process_important=`ps aux | grep $process_travail | sed '/grep/d'`
  if [[ "$process_important" != "" ]] ; then
    if [[ "$CRON_SCRIPT" != "oui" ]] ; then
      echo $process_travail "est en cours de fonctionnement, arrêt du script"
      fin_script=`date`
      echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"
    fi
    if [[ "$1" == "--menu" ]]; then
      read -rsp $'Appuyez sur une touche pour fermer la fenêtre...\n' -n1 key
    fi
    exit 1
  fi
done
 
#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_script_base_maj=`echo ${mon_script_base^^}`
mon_script_config=`echo "/root/.config/"$mon_script_base"/"$mon_script_base".conf"`
mon_script_ini=`echo "/root/.config/"$mon_script_base"/"$mon_script_base".ini"`
mon_script_log=`echo $mon_script_base".log"`
mon_script_desktop=`echo $mon_script_base".desktop"`
mon_script_updater=`echo $mon_script_base"-update.sh"`
 
#### Initialisation des variables
ignore_range="non"
force_encodage="non"
parametre_source=""
 
#### Tests des arguments
for parametre in $@; do
  if [[ "$parametre" == "--version" ]]; then
    echo "$version"
    exit 1
  fi
  if [[ "$parametre" == "--debug" ]]; then
    debug="yes"
  fi
  if [[ "$parametre" == "--edit-config" ]]; then
    nano $mon_script_config
    exit 1
  fi
  if [[ "$parametre" == "--efface-lock" ]]; then
    mon_lock=`echo "/root/.config/"$mon_script_base"/lock-"$mon_script_base`
    rm -f "$mon_lock"
    echo "Fichier lock effacé"
    exit 1
  fi
  if [[ "$parametre" == "--statut-lock" ]]; then
    statut_lock=`cat $mon_script_config | grep "maj_force=\"oui\""`
    if [[ "$statut_lock" == "" ]]; then
      echo "Système de lock activé"
    else
      echo "Système de lock désactivé"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--active-lock" ]]; then
    sed -i 's/maj_force="oui"/maj_force="non"/g' $mon_script_config
    echo "Système de lock activé"
    exit 1
  fi
  if [[ "$parametre" == "--desactive-lock" ]]; then
    sed -i 's/maj_force="non"/maj_force="oui"/g' $mon_script_config
    echo "Système de lock désactivé"
    exit 1
  fi
  if [[ "$parametre" == "--extra-log" ]]; then
    date_log=`date +%Y%m%d`
    heure_log=`date +%H%M`
    path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
    mkdir -p $path_log 2>/dev/null
    fichier_log_perso=`echo $path_log"/"$heure_log".log"`
    mon_log_perso="| tee -a $fichier_log_perso"
  fi
  if [[ "$parametre" == "--purge-process" ]]; then
    ps aux | grep $mon_script_base | awk '{print $2}' | xargs kill -9
    echo "Les processus de ce script ont été tués"
  fi
  if [[ "$parametre" == "--purge-log" ]]; then
    path_global_log=`echo "/root/.config/"$mon_script_base"/log"`
    cd $path_global_log
    mon_chemin=`echo $PWD`
    if [[ "$mon_chemin" == "$path_global_log" ]]; then
      printf "Êtes-vous sûr de vouloir effacer l'intégralité des logs de --extra-log? (oui/non) : "
      read question_effacement
      if [[ "$question_effacement" == "oui" ]]; then
        rm -rf *
        echo "Les logs ont été effacés"
      fi
    else
      echo "Une erreur est survenue, veuillez contacter le développeur"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--changelog" ]]; then
    wget -q -O- $changelog_github
    echo ""
    exit 1
  fi
  if [[ "$parametre" == --message=* ]]; then
    source $mon_script_config
    message=`echo "$parametre" | sed 's/--message=//g'`
    curl -s \
      --form-string "token=arocr9cyb3x5fdo7i4zy7e99da6hmx" \
      --form-string "user=uauyi2fdfiu24k7xuwiwk92ovimgto" \
      --form-string "title=$mon_script_base_maj MESSAGE" \
      --form-string "message=$message" \
      --form-string "html=1" \
      --form-string "priority=0" \
      https://api.pushover.net/1/messages.json > /dev/null
    exit 1
  fi
  if [[ "$parametre" == "--help" ]]; then
    path_log=`echo "/root/.config/"$mon_script_base"/log/"$date_log`
    echo -e "\e[1m$mon_script_base_maj\e[0m ($version)"
    echo "Objectif du programme: $description"
    echo "Auteur: Z0uZOU <zouzou.is.reborn@hotmail.fr>"
    echo ""
    echo "Utilisation: \"$mon_script_fichier [--option]\""
    echo ""
    echo -e "\e[4mOptions:\e[0m"
    echo "  --version               Affiche la version de ce programme"
    echo "  --edit-config           Édite la configuration de ce programme"
    echo "  --extra-log             Génère un log à chaque exécution dans "$path_log
    echo "  --debug                 Lance ce programme en mode debug"
    echo "  --efface-lock           Supprime le fichier lock qui empêche l'exécution"
    echo "  --statut-lock           Affiche le statut de la vérification de process doublon"
    echo "  --active-lock           Active le système de vérification de process doublon"
    echo "  --desactive-lock        Désactive le système de vérification de process doublon"
    echo "  --maj-uniquement        N'exécute que la mise à jour"
    echo "  --changelog             Affiche le changelog de ce programme"
    echo "  --help                  Affiche ce menu"
    echo "  --stop-convert          Stoppe le programme après la fin de la conversion en cours"
    echo "  --ignore-range          Permet d'ignorer le fichier \"range.conf\""
    echo "  --ignore-filebot        Permet d'ignorer le renommage du fichier par FileBot"
    echo "  --force-encodage        Permet de force l'encodage si le média détecté est en 3D"
    echo "  --source:/emplacement/  Définit l'emplacement de la source des fichiers à convertir"
    echo ""
    echo "Les options \"--debug\", \"--extra-log\", \"--ignore-range\", \"--ignore-filebot\", \"--force-encodage\" et \"--source:\" sont cumulables"
    echo ""
    echo -e "\e[4mUtilisation avancée:\e[0m"
    echo "  --message=\"...\"         Envoie un message push au développeur (urgence uniquement)"
    echo "  --purge-log             Purge définitivement les logs générés par --extra-log"
    echo "  --purge-process         Tue tout les processus générés par ce programme"
    echo ""
    echo -e "\e[3m ATTENTION: CE PROGRAMME DOIT ÊTRE EXÉCUTÉ AVEC LES PRIVILÈGES ROOT \e[0m"
    echo "Des commandes comme les installations de dépendances ou les recherches nécessitent de tels privilèges."
    echo ""
    exit 1
  fi
  
  if [[ "$parametre" == "--ignore-range" ]]; then
    ignore_range="oui"
  fi
  
#  if [[ "$parametre" == "--ignore-filebot" ]]; then
#    ignore_filebot="oui"
#  else
#    ignore_filebot="non"
#  fi
  ignore_filebot="oui"
  
  if [[ "$parametre" == "--force-encodage" ]]; then
    force_encodage="oui"
  fi
  
  if [[ "$parametre" =~ "--source:" ]]; then
    parametre_source=`echo $parametre | sed 's/--source://g'`
  fi
done
 
#### je dois charger le fichier conf ici ou trouver une solution (script_url et maj_force)
dossier_config=`echo "/root/.config/"$mon_script_base`
if [[ ! -d "$dossier_config" ]]; then
  mkdir -p $dossier_config
fi
 
if [[ -f "$mon_script_config" ]] ; then
  source $mon_script_config
else
    if [[ "$script_url" != "" ]] ; then
      script_pastebin=$script_url
    fi
    if [[ "$maj_force" == "" ]] ; then
      maj_force="non"
    fi
fi

#### Vérification qu'au reboot les lock soient bien supprimés
## attention si pas de rc.local il faut virer les lock par cron (a faire)
if [[ -f "/etc/rc.local" ]]; then
  test_rc_local=`cat /etc/rc.local | grep -e 'find /root/.config -name "lock-\*" | xargs rm -f'`
  if [[ "$test_rc_local" == "" ]]; then
   sed -i -e '$i \find /root/.config -name "lock-*" | xargs rm -f\n' /etc/rc.local >/dev/null
  fi
fi
 
#### Vérification qu'une autre instance de ce script ne s'exécute pas
computer_name=`hostname`
pid_script=`echo "/root/.config/"$mon_script_base"/lock-"$mon_script_base`
if [[ "$maj_force" == "non" ]] ; then
  if [[ -f "$pid_script" ]] ; then
    echo "Il y a au moins un autre process du script en cours"
    message_alerte=`echo -e "Un process bloque mon script sur $computer_name"`
    ## petite notif pour Z0uZOU
    curl -s \
    --form-string "token=arocr9cyb3x5fdo7i4zy7e99da6hmx" \
    --form-string "user=uauyi2fdfiu24k7xuwiwk92ovimgto" \
    --form-string "title=$mon_script_base_maj HS" \
    --form-string "message=$message_alerte" \
    --form-string "html=1" \
    --form-string "priority=1" \
    https://api.pushover.net/1/messages.json > /dev/null
    if [[ "$1" == "--menu" ]]; then
      read -rsp $'Appuyez sur une touche pour fermer la fenêtre...\n' -n1 key
    fi
    exit 1
  fi
fi
 
touch $pid_script
 
#### Chemin du script
## necessaire pour le mettre dans le cron
cd /opt/scripts
 
#### Indispensable aux messages de chargement
mon_printf="\r                                                                             "
 
#### Nettoyage obligatoire
if [[ -f "$mon_script_updater" ]] ; then
  rm "$mon_script_updater"
  source $mon_script_config 2>/dev/null
  version_maj=`echo $version | awk '{print $2}'`
  message_maj=`echo -e "Le progamme $mon_script_base est désormais en version $version_maj"`
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
      --form-string "token=$token_app" \
      --form-string "user=$destinataire_1" \
      --form-string "title=Mise à jour installée" \
      --form-string "message=$message_maj" \
      --form-string "html=1" \
      --form-string "priority=0" \
      https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
fi
 
#### Vérification de version pour éventuelle mise à jour
version_distante=`wget -O- -q "$script_github" | grep "Version:" | awk '{ print $2 }' | sed -n 1p | awk '{print $1}' | sed -e 's/\r//g' | sed 's/"//g'`
version_locale=`echo $version | awk '{print $2}'`
 
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        echo "FAIL: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
    else
        echo "Pass: '$1 $op $2'"
    fi
}
compare=`testvercomp $version_locale $version_distante '<' | grep Pass`
if [[ "$compare" != "" ]] ; then
  echo "une mise à jour est disponible ($version_distante) - version actuelle: $version_locale"
  echo "téléchargement de la mise à jour et installation..."
  touch $mon_script_updater
  chmod +x $mon_script_updater
  echo "#!/bin/bash" >> $mon_script_updater
  mon_script_fichier_temp=`echo $mon_script_fichier"-temp"`
  echo "wget -q $script_github -O $mon_script_fichier_temp" >> $mon_script_updater
  echo "sed -i -e 's/\r//g' $mon_script_fichier_temp" >> $mon_script_updater
  if [[ "$mon_script_fichier" =~ \.sh$ ]]; then
    echo "mv $mon_script_fichier_temp $mon_script_fichier" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "bash $mon_script_fichier $@" >> $mon_script_updater
  else
    echo "shc -f $mon_script_fichier_temp -o $mon_script_fichier" >> $mon_script_updater
    echo "rm -f $mon_script_fichier_temp" >> $mon_script_updater
    compilateur=`echo $mon_script_fichier".x.c"`
    echo "rm -f *.x.c" >> $mon_script_updater
    echo "chmod +x $mon_script_fichier" >> $mon_script_updater
    echo "echo mise à jour mise en place" >> $mon_script_updater
    echo "./$mon_script_fichier $@" >> $mon_script_updater
  fi
  echo "exit 1" >> $mon_script_updater
  rm "$pid_script"
  bash $mon_script_updater
  exit 1
else
  eval 'echo -e "\e[43m-- $mon_script_base_maj - VERSION: $version_locale --\e[0m"' $mon_log_perso
fi
 
#### Nécessaire pour l'argument --maj-uniquement
if [[ "$1" == "--maj-uniquement" ]]; then
  rm "$pid_script"
  exit 1
fi
 
#### Vérification de la conformité du cron
crontab -l > $dossier_config/mon_cron.txt
cron_path=`cat $dossier_config/mon_cron.txt | grep "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"`
if [[ "$cron_path" == "" ]]; then
  sed -i '1iPATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
cron_lang=`cat $dossier_config/mon_cron.txt | grep "LANG=fr_FR.UTF-8"`
if [[ "$cron_lang" == "" ]]; then
  sed -i '1iLANG=fr_FR.UTF-8' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
cron_variable=`cat $dossier_config/mon_cron.txt | grep "CRON_SCRIPT=\"oui\""`
if [[ "$cron_variable" == "" ]]; then
  sed -i '1iCRON_SCRIPT="oui"' $dossier_config/mon_cron.txt
  cron_a_appliquer="oui"
fi
if [[ "$cron_a_appliquer" == "oui" ]]; then
  crontab $dossier_config/mon_cron.txt
  rm -f $dossier_config/mon_cron.txt
  eval 'echo "-- Cron mis en conformité"' $mon_log_perso
else
  rm -f $dossier_config/mon_cron.txt
fi
 
#### Mise en place éventuelle d'un cron
if [[ "$script_cron" != "" ]]; then
  mon_cron=`crontab -l`
  verif_cron=`echo "$mon_cron" | grep "$mon_script_fichier"`
  if [[ "$verif_cron" == "" ]]; then
    eval 'echo -e "\e[41mAUCUNE ENTRÉE DANS LE CRON\e[0m"' $mon_log_perso
    eval 'echo "-- Création..."' $mon_log_perso
    ajout_cron=`echo -e "$script_cron\t\t/opt/scripts/$mon_script_fichier > /var/log/$mon_script_log 2>&1"`
    eval 'echo "-- Mise en place dans le cron..."' $mon_log_perso
    crontab -l > $dossier_config/mon_cron.txt
    echo -e "$ajout_cron" >> $dossier_config/mon_cron.txt
    crontab $dossier_config/mon_cron.txt
    rm -f $dossier_config/mon_cron.txt
    eval 'echo "-- Cron mis à jour"' $mon_log_perso
  else
    eval 'echo -e "\e[101mLE SCRIPT EST PRÉSENT DANS LE CRON\e[0m"' $mon_log_perso
  fi
fi
 
#### Vérification/création du fichier conf
if [[ -f $mon_script_config ]] ; then
  eval 'echo -e "\e[42mLE FICHIER CONF EST PRESENT\e[0m"' $mon_log_perso
else
  eval 'echo -e "\e[41mLE FICHIER CONF EST ABSENT\e[0m"' $mon_log_perso
  eval 'echo "-- Création du fichier conf..."' $mon_log_perso
  touch "$mon_script_config"
  chmod 777 "$mon_script_config"
cat <<EOT >> "$mon_script_config"
####################################
## Configuration
####################################
 
#### Mise à jour forcée
## à n'utiliser qu'en cas de soucis avec la vérification de process (oui/non)
maj_force="non"
 
#### Chemin complet vers le script source (pour les maj)
script_url=""
 
##### Paramètres
## Sources
dossier_source="/mnt/sdc1/Handbrake/A_Convertir"
## Cibles
dossier_cible="/mnt/sdc1/Handbrake/Converti"
dossier_cible_erreur="/mnt/sdc1/Handbrake/Erreur"
dossier_cible_media_3D="/mnt/sdc1/Handbrake/Media_3D"
dossier_filebot_films="/mnt/sdc1/Downloads/Films_Hdlight"
dossier_filebot_series="/mnt/sdc1/Downloads/Séries_HQ"
## Température maximum avant coupure du script
temperature_max="85"
 
#### Paramètre du push
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
destinataire_1=""
destinataire_2=""
titre_push=""
push_apres_conversion="oui"
push_fin_script="non"
 
####################################
## Fin de configuration
####################################
EOT
  eval 'echo "-- Fichier conf créé"' $mon_log_perso
  eval 'echo "Vous dever éditer le fichier \"$mon_script_config\" avant de poursuivre"' $mon_log_perso
  rm $pid_script
  exit 1
fi
 
echo "------"
eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVÉRIFICATION DE(S) DÉPENDANCE(S)  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
#### Vérification et installation des repositories (apt)
for repo in $required_repos ; do
  ppa_court=`echo $repo | sed 's/.*ppa://' | sed 's/\/ppa//'`
  check_repo=`grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep "$ppa_court"`
    if [[ "$check_repo" == "" ]]; then
      add-apt-repository $repo -y
      update_a_faire="1"
    else
      eval 'echo -e "[\e[42m\u2713 \e[0m] Le dépôt apt: "$repo" est installé"' $mon_log_perso
    fi
done
if [[ "$update_a_faire" == "1" ]]; then
  apt update
fi
 
#### Vérification et installation des outils requis si besoin (apt)
for tools in $required_tools ; do
  check_tool=`dpkg --get-selections | grep -w "$tools"`
    if [[ "$check_tool" == "" ]]; then
      apt-get install $tools -y
    else
      eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: "$tools" est installée"' $mon_log_perso
    fi
done
 
#### Vérification et installation des outils requis si besoin (pip)
for tools_pip in $required_tools_pip ; do
  check_tool=`pip freeze | grep "$tools_pip"`
    if [[ "$check_tool" == "" ]]; then
      pip install $tools_pip
    else
      eval 'echo -e "[\e[42m\u2713 \e[0m] La dépendance: "$tools_pip" est installée"' $mon_log_perso
    fi
done

#### Vérification de FileBot
filebot_local=`filebot -version | awk '{print $2}' 2>/dev/null`
filebot_present=`filebot -version 2>/dev/null`
if [[ "$filebot_present" =~ "FileBot" ]]; then
  wget -O- -q $lien_filebot > $dossier_config/filebot.txt &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
  i=$(( (i+1) %4 ))
  printf "\rVérification de la dernière version de FileBot... ${spin:$i:1}"
  sleep .1
  done
  printf "$mon_printf" && printf "\r"
  filebot_distant=`cat $dossier_config/filebot.txt | grep "filebot_" | sed -n '1p' | sed 's/.*filebot_//' | sed 's/_amd64.deb<\/a><\/span>.*//'`
  useless="1"
  filebot_lien_download=`cat $dossier_config/filebot.txt | grep "filebot_$filebot_distant" | sed -n '1p' | sed 's/.*href=\"\///' | sed 's/\">.*//' | sed 's/\/blob\//\/raw\//'`
  wget -q -O filebot.deb "https://github.com/$filebot_lien_download" &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\rTéléchargement de la dernière version de FileBot... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"
  dpkg -i filebot.deb >/dev/null 2>&1 &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\rInstallation de la dernière version de FileBot... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"
  rm -f filebot.deb
  echo -e "[\e[42m\u2713 \e[0m] FileBot est installé (version "$filebot_distant")"
else
  echo -e "[\e[42m\u2713 \e[0m] La dépendance: filebot est installée ("$filebot_local")"
fi
rm -f $dossier_config/filebot.txt
 
#### Ajout de ce script dans le menu
if [[ -f "/etc/xdg/menus/applications-merged/scripts-scoony.menu" ]] ; then
  useless=1
else
  echo "... création du menu"
  mkdir -p /etc/xdg/menus/applications-merged
  touch "/etc/xdg/menus/applications-merged/scripts-scoony.menu"
  cat <<EOT >> /etc/xdg/menus/applications-merged/scripts-scoony.menu
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
<Name>Applications</Name>
 
<Menu> <!-- scripts-scoony -->
<Name>scripts-scoony</Name>
<Directory>scripts-scoony.directory</Directory>
<Include>
<Category>X-scripts-scoony</Category>
</Include>
</Menu> <!-- End scripts-scoony -->
 
</Menu> <!-- End Applications -->
EOT
  echo "... menu créé"
fi
 
if [[ -f "/usr/share/desktop-directories/scripts-scoony.directory" ]] ; then
  useless=1
else
## je met l'icone en place
  wget -q https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/.cache-icons/Scripts.png -O /usr/share/icons/scripts.png
  echo "... création du dossier du menu"
  if [[ ! -d "/usr/share/desktop-directories" ]] ; then
    mkdir -p /usr/share/desktop-directories
  fi
  touch "/usr/share/desktop-directories/scripts-scoony.directory"
  cat <<EOT >> /usr/share/desktop-directories/scripts-scoony.directory
[Desktop Entry]
Type=Directory
Name=Scripts Scoony
Icon=/usr/share/icons/scripts.png
EOT
fi
 
if [[ -f "/usr/local/share/applications/$mon_script_desktop" ]] ; then
  useless=1
else
  wget -q $icone_github -O /usr/share/icons/$mon_script_base.png
  if [[ -d "/usr/local/share/applications" ]]; then
    useless="1"
  else
    mkdir -p /usr/local/share/applications
  fi
  touch "/usr/local/share/applications/$mon_script_base.desktop"
  cat <<EOT >> /usr/local/share/applications/$mon_script_base.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Type=Application
Terminal=true
Name=Script $mon_script_base
Icon=/usr/share/icons/$mon_script_base.png
Exec=/opt/scripts/$mon_script_fichier --menu
Comment[fr_FR]=$description
Comment=$description
Categories=X-scripts-scoony;
EOT
fi
 
####################
## On commence enfin
####################
 
#### Vérification de l'extension argos
chemin_argos=`locate "/.config/argos/" | sed '/\/home\//!d' | sed 's/\/.config.*//g' | sort -u`
if [[ "$chemin_argos" != "" ]]; then
  chemin_argos+="/.config/argos"
  if [[ ! -f "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
    wget -q $mon_script_argos_github -O $chemin_argos/convert2hdlight.c.1s.sh && sed -i -e 's/\r//g' $chemin_argos/convert2hdlight.c.1s.sh && chmod 777 $chemin_argos/convert2hdlight.c.1s.sh && chmod -x $chemin_argos/convert2hdlight.c.1s.sh
  else
    if [[ -x "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
      chmod -x $chemin_argos/convert2hdlight.c.1s.sh
    fi
  fi
fi
 
#### Prise en compte du parametre --source:
if [[ "$parametre_source" != "" ]]; then
  dossier_source=$parametre_source
fi
 
#### Verifications de base
eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mVÉRIFICATIONS DE BASE  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
updatedb 2> /dev/null &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rMise à jour de la base de donnée locale... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
eval 'echo -e "[\e[42m\u2713 \e[0m] Base de donnée locale mise à jour"' $mon_log_perso
rm -f tmpfolder
chemin_json=`echo $dossier_config"/hdlight-encode.json"`
if [[ -f "$chemin_json" ]] ; then
  eval 'echo -e "[\e[42m\u2713 \e[0m] Le fichier de règlages du convertisseur est présent"' $mon_log_perso
else
  eval 'echo -e "[\e[41m\u2717 \e[0m] Le Fichier de réglages du convertisseur est absent, téléchargement du fichier"' $mon_log_perso
  wget -q $mon_fichier_json_github -O $chemin_json && sed -i -e 's/\r//g' $chemin_json
fi
 
## Espace libre
libre_dossier_source=`df --total -hl "$dossier_source" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier source: "$libre_dossier_source"\n[..... "$dossier_source' $mon_log_perso
libre_dossier_cible=`df --total -hl "$dossier_cible" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier cible: "$libre_dossier_cible"\n[..... "$dossier_cible' $mon_log_perso
locate range.conf > $dossier_config/range.txt &
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rRecherche d'un éventuel \"range.conf\"... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
#range_path=`cat $dossier_config/range.txt | sed '/\/.local\//d' | sed '/Sauvegarde_USB/d'`
range_path=`cat $dossier_config/range.txt | sed '/\/.local\//d' | sed '/Sauvegarde_USB/d' | sed '/usb_save/d'`
if [[ "$range_path" != "" ]]; then
  eval 'echo -e "[\e[42m\u2713 \e[0m] Le fichier range.conf a été détecté: "$range_path' $mon_log_perso
  if [[ "$ignore_range" == "oui" ]]; then
    eval 'echo -e "[..... Configuration ignorée"' $mon_log_perso 
  else
    eval $(source $range_path; echo destination_films_hd=$cible_auto_films_hd)
    eval $(source $range_path; echo filebot_films_hd=$download_auto_films_hd)
    libre_films_hd=`df --total -hl "$destination_films_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    libre_filebot_films_hd=`df --total -hl "$filebot_films_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier filebot films HD: "$libre_filebot_films_hd"\n[..... "$filebot_films_hd' $mon_log_perso
    eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier destination films HD: "$libre_films_hd"\n[..... "$destination_films_hd' $mon_log_perso
    # eval $(source $range_path; echo destination_series_hdtv=$cible_auto_series_hdtv)
    # eval $(source $range_path; echo filebot_series_hdtv=$download_auto_series_hdtv)
    # libre_series_hdtv=`df --total -hl "$destination_series_hdtv" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    # libre_filebot_series_hdtv=`df --total -hl "$filebot_series_hdtv" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    # eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier filebot séries HDTV: "$libre_filebot_series_hdtv"\n[..... "$filebot_series_hdtv' $mon_log_perso
    # eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier destination séries HDTV: "$libre_series_hdtv"\n[..... "$destination_series_hdtv' $mon_log_perso
    eval $(source $range_path; echo destination_series_hd=$cible_auto_series_hd)
    eval $(source $range_path; echo filebot_series_hd=$download_auto_series_hd)
    libre_series_hd=`df --total -hl "$destination_series_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    libre_filebot_series_hd=`df --total -hl "$filebot_series_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier filebot séries HD: "$libre_filebot_series_hd"\n[..... "$filebot_series_hd' $mon_log_perso
    eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier destination séries HD: "$libre_series_hd"\n[..... "$destination_series_hd' $mon_log_perso
  fi
  rm -f $dossier_config/range.txt
fi
 
#### Suppression des fichier inutiles et dossiers vides
eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mNETTOYAGE DES DOSSIERS  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
locate -ir /sample$ | sed '#'$dossier_source'#!d' > $dossier_config/tmpfolder & # -ir : ignore la casse
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rRecherche en cours... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
locate -ir /proof$ | sed '#'$dossier_source'#!d' >> $dossier_config/tmpfolder & # -ir : ignore la casse
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rRecherche en cours... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
locate -ir \]$ | sed '#'$dossier_source'#!d' >> $dossier_config/tmpfolder & # -ir : ignore la casse
pid=$!
spin='-\|/'
i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rRecherche en cours... ${spin:$i:1}"
  sleep .1
done
printf "$mon_printf" && printf "\r"
mes_dossiers_a_supprimer=()
while IFS= read -r -d $'\n'; do
  mes_dossiers_a_supprimer+=("$REPLY")
done <$dossier_config/tmpfolder
rm -f $dossier_config/tmpfolder
 
mes_fichiers_a_supprimer=()
find "$dossier_source" -type f \( -iname \*.jpg -o -iname \*.png -o -iname \*.diz -o -iname \*.txt -o -iname \*.nfo -o -iname \*.zip -o -iname \*.db \) -print0 >$dossier_config/tmpfile
while IFS= read -r -d $'\0'; do
  mes_fichiers_a_supprimer+=("$REPLY")
done <$dossier_config/tmpfile
rm -f $dossier_config/tmpfile
 
if [[ $mes_dossiers_a_supprimer != "" ]] ; then
  for i in "${mes_dossiers_a_supprimer[@]}"; do
    test_source=`echo $i | grep -o $dossier_source`
    if [[ "$test_source" != "" ]] ; then
      if [[ -d "$i" ]]; then
        eval 'echo -e "...... suppression de : "$i' $mon_log_perso
        rm -rf "$i"
      fi
    fi
  done
fi
if [[ $mes_fichiers_a_supprimer != "" ]] ; then
  for i in "${mes_fichiers_a_supprimer[@]}"; do
    test_source=`echo $i | grep -o $dossier_source`
    if [[ "$test_source" != "" ]] ; then
      if [[ -f "$i" ]]; then
        eval 'echo -e "...... suppression de : "$i' $mon_log_perso
        rm -f "$i"
      fi
    fi
  done
fi
eval 'echo -e "[\e[42m\u2713 \e[0m] Procédure de nettoyage terminée"' $mon_log_perso
 
## Trouvons les médias dans le dossier source
eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE MÉDIAS  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
cd "$dossier_source"
mes_medias=()
find "$dossier_source" -type f -iname '*[avi|mp4|mkv]' -print0 >$dossier_config/tmpfile
while IFS= read -r -d $'\0'; do
  mes_medias+=("$REPLY")
done <$dossier_config/tmpfile
rm -f $dossier_config/tmpfile
 
## Traitement des médias
if [[ "$mes_medias" != "" ]] ; then
  #### Activation du script argos
  if [[ -f "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
    chmod +x $chemin_argos/convert2hdlight.c.1s.sh 
  fi
  for mon_media in "${mes_medias[@]}"; do
    ## vérification que le fichiers de ne soit pas en copie/déplacement
    taille_1=`ls -al  "$mon_media" | awk '{print $5}'`
    sleep .5
    taille_2=`ls -al  "$mon_media" | awk '{print $5}'`
    if [[ "$taille_1" == "$taille_2" ]] && [[ -f "$mon_media" ]]; then
      fichier=$(basename "$mon_media")
      test_serie=`echo $fichier | tr [:upper:] [:lower:] | grep -E "s[0-9][0-9]e[0-9][0-9]|s[0-9]e[0-9][0-9]|- [0-9]x[0-9][0-9] -|- [0-9][0-9]x[0-9][0-9] -|- [0-9]x[0-9][0-9]-[0-9][0-9] -|- [0-9][0-9]x[0-9][0-9]-[0-9][0-9] -"`
      if [[ $test_serie != "" ]] ; then
        categorie="Série"
        categorie_text="Série détectée"
      else
        categorie="Film"
        categorie_text="Film détecté"
      fi
      eval 'echo -e "[\e[42m\u2713 \e[0m] "$categorie_text" : "$fichier' $mon_log_perso
      filebot -mediainfo "$mon_media" --format "#0¢{gigabytes}#1¢{minutes}#2¢{vf}#3¢{vc}#4¢{audio.Language}#5¢{audio.Codec}#6¢{kbps}#7¢{s3d}#8¢" 2>/dev/null > $dossier_config/mediainfo.txt &
      pid=$!
      spin='-\|/'
      i=0
      while kill -0 $pid 2>/dev/null
      do
        i=$(( (i+1) %4 ))
        printf "\rRécupération des caractéristiques du média... ${spin:$i:1}"
        sleep .1
      done
      printf "$mon_printf" && printf "\r"
      mediainfo_taille=`cat $dossier_config/mediainfo.txt | sed 's/.*#0¢//' | sed 's/#1¢.*//'`
      mediainfo_duree=`cat $dossier_config/mediainfo.txt | sed 's/.*#1¢//' | sed 's/#2¢.*//'`
      mediainfo_resolution=`cat $dossier_config/mediainfo.txt | sed 's/.*#2¢//' | sed 's/#3¢.*//'`
      mediainfo_codec=`cat $dossier_config/mediainfo.txt | sed 's/.*#3¢//' | sed 's/#4¢.*//'`
      mediainfo_langue=`cat $dossier_config/mediainfo.txt | sed 's/.*#4¢//' | sed 's/#5¢.*//'`
      mediainfo_langue_codec=`cat $dossier_config/mediainfo.txt | sed 's/.*#5¢//' | sed 's/#6¢.*//'`
      mediainfo_bitrate=`cat $dossier_config/mediainfo.txt | sed 's/.*#6¢//' | sed 's/#7¢.*//'`
      mediainfo_3d=`cat $dossier_config/mediainfo.txt | sed 's/.*#7¢//' | sed 's/#8¢.*//'`
      rm -f $dossier_config/mediainfo.txt
      mediainfo_langue_clean=`echo $mediainfo_langue | sed 's/\[//g' | sed 's/\]//g'`
      mediainfo_langue_codec_clean=`echo $mediainfo_langue_codec | sed 's/\[//g' | sed 's/\]//g'`
      
#### Sauvegarde des caractéristiques du média
      if [[ -d "$chemin_argos" ]]; then
        if [[ ! -d "$chemin_argos/convert2hdlight/temp" ]]; then
          mkdir -p $chemin_argos/convert2hdlight/temp
        else
          rm -f $chemin_argos/convert2hdlight/temp/*
        fi
        echo "$mediainfo_duree" > $chemin_argos/convert2hdlight/temp/mediainfo_duree.txt
        echo "$mediainfo_resolution" > $chemin_argos/convert2hdlight/temp/mediainfo_resolution.txt
        echo "$mediainfo_langue_clean" > $chemin_argos/convert2hdlight/temp/mediainfo_langue.txt
        
        if [[ "$categorie" == "Film" ]]; then
          filebot --action test -script fn:amc --db TheMovieDB -non-strict --conflict override --lang fr --encoding UTF-8 --mode rename "$mon_media" --def minFileSize=0 --def "movieFormat=/opt/scripts/TEMP/#0¢{localize.English.n}#1¢{localize.French.n}#2¢{y}#3¢{id}#4¢{imdbid}#5¢{localize.French.genres}#6¢{rating}#7¢{info.ProductionCountries}#8¢{info.overview}#9¢" 2>/dev/null > $dossier_config/mediainfo.txt &
          pid=$!
          spin='-\|/'
          i=0
          while kill -0 $pid 2>/dev/null
          do
            i=$(( (i+1) %4 ))
            printf "\rRécupération des informations du film... ${spin:$i:1}"
            sleep .1
          done
          printf "$mon_printf" && printf "\r"
          verif_bonne_detection=`cat $dossier_config/mediainfo.txt | grep "TEST" | grep "/TV Shows/"`
          if [[ "$verif_bonne_detection" != "" ]]; then
            echo "Fichier non-valide" > $dossier_config/mediainfo.txt
          else
            film_titre_en=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#0¢//' | sed 's/#1¢.*//'`
            film_titre_fr=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#1¢//' | sed 's/#2¢.*//'`
            film_annee=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#2¢//' | sed 's/#3¢.*//'`
            film_tmdb_id=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#3¢//' | sed 's/#4¢.*//'`
            film_imdb_id=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#4¢//' | sed 's/#5¢.*//'`
            film_genres=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#5¢//' | sed 's/#6¢.*//'`
            film_note=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#6¢//' | sed 's/#7¢.*//'`
            film_origine=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#7¢//' | sed 's/#8¢.*//'`
            #film_synopsis=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#8¢//' | sed 's/#9¢.*//'`
            url_tmdb="https://www.themoviedb.org/movie/$film_tmdb_id/fr"
            wget -q -O- $url_tmdb | grep "\"description\"" | sed -n '1p' | sed 's/.*content=\"//' | sed 's/\".*//' > $chemin_argos/convert2hdlight/temp/film_synopsis.txt
            if [[ ! -d "$chemin_argos/convert2hdlight/Covers/Films" ]]; then
              mkdir -p $chemin_argos/convert2hdlight/Covers/Films
            fi
            if [[ ! -f "$chemin_argos/convert2hdlight/Covers/Films/$film_tmdb_id.jpg" ]]; then
              url_tmdb="https://www.themoviedb.org/movie/$film_tmdb_id/images/posters"
              wget -q -O- $url_tmdb | grep "og:image" | sed -n '1p' | sed 's/.*content=\"//' | sed 's/\".*//' > $dossier_config/url_tmdb.txt &
              pid=$!
              spin='-\|/'
              i=0
              while kill -0 $pid 2>/dev/null
              do
                i=$(( (i+1) %4 ))
                printf "\rRécupération de la cover du film... ${spin:$i:1}"
                sleep .1
              done
              printf "$mon_printf" && printf "\r"
              url_tmdb_cover=`cat $dossier_config/url_tmdb.txt`
              wget -q "$url_tmdb_cover" -O "$chemin_argos/convert2hdlight/Covers/Films/$film_tmdb_id.jpg" &
              pid=$!
              spin='-\|/'
              i=0
              while kill -0 $pid 2>/dev/null
              do
                i=$(( (i+1) %4 ))
                printf "\rRécupération de la cover du film... ${spin:$i:1}"
                sleep .1
              done
              printf "$mon_printf" && printf "\r"
            fi
            
            echo "$film_titre_en" > $chemin_argos/convert2hdlight/temp/film_titre_en.txt
            echo "$film_titre_fr" > $chemin_argos/convert2hdlight/temp/film_titre_fr.txt
            echo "$film_annee" > $chemin_argos/convert2hdlight/temp/film_annee.txt
            echo "$film_tmdb_id" > $chemin_argos/convert2hdlight/temp/film_tmdb_id.txt
            echo "$film_imdb_id" > $chemin_argos/convert2hdlight/temp/film_imdb_id.txt
            echo "$film_genres" > $chemin_argos/convert2hdlight/temp/film_genres.txt
            echo "$film_note" > $chemin_argos/convert2hdlight/temp/film_note.txt
            echo "$film_origine" > $chemin_argos/convert2hdlight/temp/film_origine.txt
            #echo "$film_synopsis" > $chemin_argos/convert2hdlight/temp/film_synopsis.txt
          fi
          rm -f $dossier_config/mediainfo.txt
        else
          filebot --action test -script fn:amc --db TheTVDB -non-strict --conflict override --lang fr --encoding UTF-8 --mode rename "$mon_media" --def minFileSize=0 --def "seriesFormat=/opt/scripts/TEMP/#0¢{localize.English.n}#1¢{localize.French.n}#2¢{y}#3¢{id}#4¢{airdate}#5¢{genres}#6¢{rating}#7¢{s}#8¢{e.pad(2)}#9¢{localize.French.t}#10¢{localize.English.t}#11¢" 2>/dev/null > $dossier_config/mediainfo.txt &
          pid=$!
          spin='-\|/'
          i=0
          while kill -0 $pid 2>/dev/null
          do
            i=$(( (i+1) %4 ))
            printf "\rRécupération des informations de la série... ${spin:$i:1}"
            sleep .1
          done
          printf "$mon_printf" && printf "\r"
          verif_bonne_detection=`cat $dossier_config/mediainfo.txt | grep "TEST" | grep "/Movies/"`
          if [[ "$verif_bonne_detection" != "" ]]; then
            echo "Fichier non-valide" > $dossier_config/mediainfo.txt
          else
            serie_nom_en=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#0¢//' | sed 's/#1¢.*//'`
            serie_nom_fr=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#1¢//' | sed 's/#2¢.*//'`
            serie_annee=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#2¢//' | sed 's/#3¢.*//'`
            serie_tvdb_id=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#3¢//' | sed 's/#4¢.*//'`
            serie_diffusion_episode=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#4¢//' | sed 's/#5¢.*//'`
            serie_genres=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#5¢//' | sed 's/#6¢.*//'`
            serie_note=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#6¢//' | sed 's/#7¢.*//'`
            serie_saison=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#7¢//' | sed 's/#8¢.*//'`
            serie_episode=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#8¢//' | sed 's/#9¢.*//'`
            serie_titre_fr=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#9¢//' | sed 's/#10¢.*//'`
            serie_titre_en=`cat $dossier_config/mediainfo.txt | grep "TEST" | sed 's/.*#10¢//' | sed 's/#11¢.*//'`
            
            if [[ ! -d "$chemin_argos/convert2hdlight/Covers/Séries" ]]; then
              mkdir -p $chemin_argos/convert2hdlight/Covers/Séries
            fi
            if [[ ! -f "$chemin_argos/convert2hdlight/Covers/Séries/$serie_tvdb_id.jpg" ]]; then
              wget -q "https://www.thetvdb.com/banners/_cache/posters/$serie_tvdb_id-1.jpg" -O "$chemin_argos/convert2hdlight/Covers/Séries/$serie_tvdb_id.jpg" &
              pid=$!
              spin='-\|/'
              i=0
              while kill -0 $pid 2>/dev/null
              do
                i=$(( (i+1) %4 ))
                printf "\rRécupération de la cover de la série... ${spin:$i:1}"
                sleep .1
              done
              printf "$mon_printf" && printf "\r"
            fi

            echo "$serie_nom_en" > $chemin_argos/convert2hdlight/temp/serie_nom_en.txt
            echo "$serie_nom_fr" > $chemin_argos/convert2hdlight/temp/serie_nom_fr.txt
            echo "$serie_annee" > $chemin_argos/convert2hdlight/temp/serie_annee.txt
            echo "$serie_tvdb_id" > $chemin_argos/convert2hdlight/temp/serie_tvdb_id.txt
            echo "$serie_diffusion_episode" > $chemin_argos/convert2hdlight/temp/serie_diffusion_episode.txt
            echo "$serie_genres" > $chemin_argos/convert2hdlight/temp/serie_genres.txt
            echo "$serie_note" > $chemin_argos/convert2hdlight/temp/serie_note.txt
            echo "$serie_saison" > $chemin_argos/convert2hdlight/temp/serie_saison.txt
            echo "$serie_episode" > $chemin_argos/convert2hdlight/temp/serie_episode.txt
            echo "$serie_titre_fr" > $chemin_argos/convert2hdlight/temp/serie_titre_fr.txt
            echo "$serie_titre_en" > $chemin_argos/convert2hdlight/temp/serie_titre_en.txt
          fi
          rm -f $dossier_config/mediainfo.txt
        fi
        chmod 777 -R $chemin_argos/convert2hdlight
      fi      
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| taille : $mediainfo_taille Go"' $mon_log_perso
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| durée : $mediainfo_duree mn"' $mon_log_perso
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| résolution : $mediainfo_resolution ($mediainfo_codec - $mediainfo_bitrate)"' $mon_log_perso
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| langue(s) : $mediainfo_langue_clean ($mediainfo_langue_codec_clean)"' $mon_log_perso
      if [[ "$mediainfo_3d" != "" ]] && [[ "$force_encodage" == "non" ]]; then
        if [[ ! -d "$dossier_cible_media_3D" ]]; then mkdir -p "$dossier_cible_media_3D"; fi
        mv "$mon_media" "$dossier_cible_media_3D/$fichier"
        eval 'echo -e "[..... MÉDIA 3D DÉTECTÉ, MEDIA IGNORÉ"' $mon_log_perso
        eval 'echo -e "[..... |\e[41m LE FICHIER EST DÉPLACÉ VERS "$dossier_cible_media_3D" \e[0m|"' $mon_log_perso
        push_message=`echo -e "Le média 3D $fichier ($categorie) ne sera pas converti."`
        if [[ "$push_apres_conversion" == "oui" ]] ; then
          for user in {1..10}; do
            destinataire=`eval echo "\\$destinataire_"$user`
            if [ -n "$destinataire" ]; then
              curl -s \
                --form-string "token=$token_app" \
                --form-string "user=$destinataire" \
                --form-string "title=Média 3D" \
                --form-string "message=$push_message" \
                --form-string "html=1" \
                --form-string "priority=0" \
                https://api.pushover.net/1/messages.json > /dev/null
            fi
          done
        fi
      else
        if [[ "$mediainfo_3d" != "" ]] && [[ "$force_encodage" == "oui" ]]; then
          eval 'echo -e "[..... MÉDIA 3D DÉTECTÉ, MEDIA NON IGNORÉ (--force-encodage)"' $mon_log_perso
        fi
        if [[ "$debug" != "yes" ]]; then
          heure_lancement=`date +%H:%M:%S`
          eval 'echo -e "[..... |\e[7m ENCODAGE \e[0m| début de conversion à $heure_lancement"' $mon_log_perso
          HandBrakeCLI --preset-import-file $chemin_json -Z Scoony -i "$mon_media" -o "$dossier_cible/$fichier-part" > $dossier_config/ma_conversion.txt 2>&1 &
          pid=$!
          spin='-\|/'
          e=0
          chiffre='^[0-9]+([.][0-9]+)?$'
          while kill -0 $pid 2>/dev/null
          do
            sensors 1>$dossier_config/tempcpu.txt 2>/dev/null
            #temperature=`cat $dossier_config/tempcpu.txt | grep -oP 'Core 0.*?\+\K[0-9]+'`
            temperature=`cat $dossier_config/tempcpu.txt | grep -oP 'Core 0.*?\+\K[0-9]+' | sed -n '1p'`
            rm -f $dossier_config/tempcpu.txt
            if [[ "$temperature_max" == "" ]]; then temperature_max="85"; fi
            if [[ "$temperature" != "" ]]; then
              if [ "$temperature" -gt "$temperature_max" ]; then
                kill -9 $pid
                eval 'echo -e "\n[\e[41m TEMPÉRATURE ($temperature) EXCESSIVE DÉTECTÉE, FIN DU PROGRAMME \e[0m]"' $mon_log_perso
                fin_script=`date`
                eval 'echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"' $mon_log_perso
                if [[ "$1" == "--menu" ]]; then
                  read -rsp $'Appuyez sur une touche pour fermer la fenêtre...\n' -n1 key
                fi
                rm "$pid_script"
                exit 1
              fi
            fi
            e=$(( (e+1) %4 ))
            tail -1 /root/.config/convert2hdlight/ma_conversion.txt > /root/.config/convert2hdlight/pourcent.txt
            cat -A /root/.config/convert2hdlight/pourcent.txt | tr "^M" "\n" > /root/.config/convert2hdlight/pourcent_clean.txt
            conversion_progression=`cat /root/.config/convert2hdlight/pourcent_clean.txt | tail -n 1 | awk '{print $6}'`
            rm -f /root/.config/convert2hdlight/pourcent.txt
            rm -f /root/.config/convert2hdlight/pourcent_clean.txt
            if [[ $conversion_progression =~ $chiffre ]] ; then
              printf "\rEncodage en cours ($conversion_progression %%)... ${spin:$e:1}"
              echo "Encodage ($conversion_progression %)" > /opt/scripts/.$mon_script_base
              echo "$mon_media" >> /opt/scripts/.$mon_script_base
              echo "$fichier" >> /opt/scripts/.$mon_script_base
              echo "$dossier_cible" >> /opt/scripts/.$mon_script_base
            else
              printf "\rEncodage en cours... ${spin:$e:1}"
              echo "Encodage en cours" > /opt/scripts/.$mon_script_base
              echo "$mon_media" >> /opt/scripts/.$mon_script_base
              echo "$fichier" >> /opt/scripts/.$mon_script_base
              echo "$dossier_cible" >> /opt/scripts/.$mon_script_base
            fi
            sleep .1
          done
          printf "$mon_printf" && printf "\r"
          echo "Encodage terminé" > /opt/scripts/.$mon_script_base
          rm -f /root/.config/convert2hdlight/ma_conversion.txt
          heure_fin=`date +%H:%M:%S`
          eval 'echo -e "[..... |\e[7m ENCODAGE \e[0m| fin de conversion à $heure_fin"' $mon_log_perso
          mv "$dossier_cible/$fichier-part" "$dossier_cible/$fichier"
          filebot -mediainfo "$dossier_cible/$fichier" --format "#0¢{gigabytes}#1¢{minutes}#2¢{vf}#3¢{vc}#4¢{audio.Language}#5¢{audio.Codec}#6¢{kbps}#7¢{s3d}#8¢" > $dossier_config/mediainfo.txt &
          pid=$!
          spin='-\|/'
          i=0
          while kill -0 $pid 2>/dev/null
          do
            i=$(( (i+1) %4 ))
            printf "\rRécupération des caractéristiques du nouveau média... ${spin:$i:1}"
            sleep .1
          done
          printf "$mon_printf" && printf "\r"
          mediainfo_taille_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#0¢//' | sed 's/#1¢.*//'`
          mediainfo_duree_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#1¢//' | sed 's/#2¢.*//'`
          mediainfo_resolution_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#2¢//' | sed 's/#3¢.*//'`
          mediainfo_codec_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#3¢//' | sed 's/#4¢.*//'`
          mediainfo_langue_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#4¢//' | sed 's/#5¢.*//'`
          mediainfo_langue_codec_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#5¢//' | sed 's/#6¢.*//'`
          mediainfo_bitrate_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#6¢//' | sed 's/#7¢.*//'`
          mediainfo_3d_enc=`cat $dossier_config/mediainfo.txt | sed 's/.*#7¢//' | sed 's/#8¢.*//'`
          rm -f $dossier_config/mediainfo.txt
          mediainfo_langue_enc_clean=`echo $mediainfo_langue_enc | sed 's/\[//g' | sed 's/\]//g'`
          mediainfo_langue_codec_enc_clean=`echo $mediainfo_langue_codec_enc | sed 's/\[//g' | sed 's/\]//g'`
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| taille : $mediainfo_taille_enc Go"' $mon_log_perso
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| durée : $mediainfo_duree_enc mn"' $mon_log_perso
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| résolution : $mediainfo_resolution_enc ($mediainfo_codec_enc - $mediainfo_bitrate_enc)"' $mon_log_perso
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| langue(s) : $mediainfo_langue_enc_clean ($mediainfo_langue_codec_enc_clean)"' $mon_log_perso
          mv "$dossier_cible/$fichier" "$dossier_cible/$fichier-part"
          echec_conversion="0"
          if [[ "$mediainfo_duree" == "$mediainfo_duree_enc" ]]; then
            eval 'echo -e "[..... |\e[42m CONVERSION REUSSIE, REMPLACEMENT ET MISE EN PLACE \e[0m|"' $mon_log_perso
            if [[ "$ignore_filebot" == "non" ]]; then
              if [[ "$categorie" == "Film" ]]; then
                agent="TheMovieDB"
                format="movieFormat"
                output="{n} ({y})"
              else
                agent="TheTVDB"
                format="seriesFormat"
                output="{n} - {sxe} - {t}"
              fi
              mv "$dossier_cible/$fichier-part" "$dossier_cible/$fichier"
              filebot -script fn:amc --db $agent -non-strict --conflict override --lang fr --encoding UTF-8 --mode rename "$dossier_cible/$fichier" --def "$format=$output" > $dossier_config/traitement.txt 2>/dev/null &
              pid=$!
              spin='-\|/'
              i=0
              while kill -0 $pid 2>/dev/null
              do
                i=$(( (i+1) %4 ))
                printf "\r[..... |\e[42m FILEBOT  \e[0m| Renommage du fichier... ${spin:$i:1}"
                sleep .1
              done
              printf "$mon_printf" && printf "\r"
              sed -i '/MOVE/!d' $dossier_config/traitement.txt
              fichier_filebot=`cat $dossier_config/traitement.txt | grep "MOVE" | cut -d'[' -f4 | sed 's/].*//g'`
              fichier=`basename "$fichier_filebot"`
              eval 'echo -e "[..... |\e[42m FILEBOT  \e[0m| Renommage du fichier en : $fichier"' $mon_log_perso
              mv "$dossier_cible/$fichier" "$dossier_cible/$fichier-part"
              rm -f traitement.txt
            fi
            if [[ "$categorie" == "Film" ]]; then
              if [[ "$filebot_films_hd" != "" ]]; then
                if [[ ! -d "$filebot_films_hd" ]]; then mkdir -p "$filebot_films_hd"; fi
                mv "$dossier_cible/$fichier-part" "$filebot_films_hd/$fichier"
                eval 'echo -e "[..... |\e[42m VERS "$filebot_films_hd" \e[0m|"' $mon_log_perso
              else
                if [[ "$dossier_filebot_films" != "" ]]; then
                  if [[ ! -d "$dossier_filebot_films" ]]; then mkdir -p "$dossier_filebot_films"; fi
                  mv "$dossier_cible/$fichier-part" "$dossier_filebot_films/$fichier"
                  eval 'echo -e "[..... |\e[42m VERS "$dossier_filebot_films" \e[0m|"' $mon_log_perso
                else
                  if [[ ! -d "$dossier_cible/Films" ]]; then mkdir -p "$dossier_cible/Films"; fi
                  mv "$dossier_cible/$fichier-part" "$dossier_cible/Films/$fichier"
                  eval 'echo -e "[..... |\e[42m VERS "$dossier_cible"/Films \e[0m|"' $mon_log_perso
                fi
              fi
            else
              if [[ "$filebot_series_hd" != "" ]]; then
                if [[ ! -d "$filebot_series_hd" ]]; then mkdir -p "$filebot_series_hd";  fi
                mv "$dossier_cible/$fichier-part" "$filebot_series_hd/$fichier"
                eval 'echo -e "[..... |\e[42m VERS "$filebot_series_hd" \e[0m|"' $mon_log_perso
              else
                if [[ "$dossier_filebot_series" != "" ]]; then
                  if [[ ! -d "$dossier_filebot_series" ]]; then mkdir -p "$dossier_filebot_series";  fi
                  mv "$dossier_cible/$fichier-part" "$dossier_filebot_series/$fichier"
                  eval 'echo -e "[..... |\e[42m VERS "$dossier_filebot_series" \e[0m|"' $mon_log_perso
                else
                  if [[ ! -d "$dossier_cible/Series" ]]; then mkdir -p "$dossier_cible/Series";  fi
                  mv "$dossier_cible/$fichier-part" "$dossier_cible/Series/$fichier"
                  eval 'echo -e "[..... |\e[42m VERS "$dossier_cible"/Series \e[0m|"' $mon_log_perso
                fi
              fi
            fi
            push_message=`echo "Conversion du fichier $fichier ($categorie) terminée"`
          else
            echec_conversion="1"
            eval 'echo -e "[..... |\e[41m ECHEC DE LA CONVERSION, LES DURÉES NE CORRESPONDENT PAS \e[0m|"' $mon_log_perso
            push_message=`echo -e "Échec de la conversion du fichier $fichier ($categorie)\nLes durées du film ne correspondent pas"`
            if [[ "$dossier_cible_erreur" != "" ]]; then
              if [[ ! -d "$dossier_cible_erreur" ]]; then mkdir -p "$dossier_cible_erreur";  fi
              eval 'echo -e "[..... |\e[41m LE FICHIER EST DÉPLACÉ VERS "$dossier_cible_erreur" \e[0m|"' $mon_log_perso
              mv "$mon_media" "$dossier_cible_erreur/$fichier"
            fi 
          fi
          #### Envoie du push apres conversion (si besoin)
          if [[ "$push_apres_conversion" == "oui" ]] ; then
            for user in {1..10}; do
              destinataire=`eval echo "\\$destinataire_"$user`
              if [ -n "$destinataire" ]; then
                curl -s \
                  --form-string "token=$token_app" \
                  --form-string "user=$destinataire" \
                  --form-string "title=$titre_push" \
                  --form-string "message=$push_message" \
                  --form-string "html=1" \
                  --form-string "priority=0" \
                  https://api.pushover.net/1/messages.json > /dev/null
              fi
            done
          fi
          if [[ "$echec_conversion" == "0" ]] ; then
            ## rm "$mon_media"
            trash-put "$mon_media"
          else
            eval 'echo -e "[..... |\e[41m LE FICHIER ORIGINAL EST CONSERVÉ \e[0m|"' $mon_log_perso
          fi
        else
          heure_lancement=`date +%H:%M:%S`
          eval 'echo -e "[..... |\e[7m ENCODAGE \e[0m| début de conversion à $heure_lancement"' $mon_log_perso
          heure_fin=`date +%H:%M:%S`
          eval 'echo -e "[..... |\e[7m ENCODAGE \e[0m| fin de conversion à $heure_fin"' $mon_log_perso
          eval 'echo -e "[..... |\e[42m CONVERSION REUSSIE, REMPLACEMENT ET MISE EN PLACE \e[0m|"' $mon_log_perso
          if [[ "$categorie" == "Films" ]] ; then
            if [[ "$filebot_films_hd" != "" ]] ; then
              eval 'echo -e "[..... déplacement du fichier $dossier_cible/$fichier-part\n        \u2192 $filebot_films_hd/$fichier"' $mon_log_perso
            else
              if [[ "$dossier_filebot_films" != "" ]] ; then
                eval 'echo -e "[..... déplacement du fichier $dossier_cible/$fichier-part\n        \u2192 $dossier_filebot_films/$fichier"' $mon_log_perso
              else
                eval 'echo -e "[..... déplacement du fichier $dossier_cible/$fichier-part\n        \u2192 $dossier_cible/Films/$fichier"' $mon_log_perso
              fi
            fi
          fi
          if [[ "$categorie" == "Série" ]] ; then
            if [[ "$filebot_series_hd" != "" ]] ; then
              eval 'echo -e "[..... déplacement du fichier $dossier_cible/$fichier-part\n        \u2192 $filebot_series_hd/$fichier"' $mon_log_perso
            else
              if [[ "$dossier_filebot_series" != "" ]] ; then
                eval 'echo -e "[..... déplacement du fichier $dossier_cible/$fichier-part\n        \u2192 $dossier_filebot_series/$fichier"' $mon_log_perso
              else
                eval 'echo -e "[..... déplacement du fichier $dossier_cible/$fichier-part\n        \u2192 $dossier_cible/Series/$fichier"' $mon_log_perso
              fi
            fi
          fi
        fi
      fi
    else
      if [[ ! -f "$mon_media" ]]; then
        eval 'echo -e "[\e[41m\u2717 \e[0m] Le fichier "$mon_media" est ignoré (supprimé)"' $mon_log_perso
      else
        eval 'echo -e "[\e[41m\u2717 \e[0m] Le fichier "$mon_media" est ignoré (en cours de copie/déplacement)"' $mon_log_perso
      fi
    fi
    if [[ -f "/root/.config/convert2hdlight/.stop-convert" ]]; then
      eval 'echo -e "[..... |\e[41m /\e[43m!\e[41m\ ARRÊT DU SCRIPT /\e[43m!\e[41m\ \e[0m|"' $mon_log_perso
      break
    fi
  done
  #### Désactivation du script argos
  if [[ -f "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
    chmod -x $chemin_argos/convert2hdlight.c.1s.sh 
  fi
  
  #### Suppression des dossiers vides
  eval 'echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE DOSSIERS VIDES  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"' $mon_log_perso
  find $dossier_source -depth -type d -empty -not -path "$dossier_source" > $dossier_config/dossiers_vides.txt &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\rRecherche de dossier(s) vide(s)... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"
  dossiers_vides=()
  while IFS= read -r -d $'\n'; do
    dossiers_vides+=("$REPLY")
  done <$dossier_config/dossiers_vides.txt
  rm -f $dossier_config/dossiers_vides.txt
  if [[ "${dossiers_vides[@]}" != "" ]]; then
    eval 'echo -e "[\e[41m\u2717 \e[0m] Des dossiers vides ont été détectés"' $mon_log_perso
    for l in "${dossiers_vides[@]}"; do
      test_source=`echo $l | grep -o $dossier_source`
      if [[ "$test_source" != "" ]] ; then
        if [[ -d "$l" ]]; then
          eval 'echo -e "   ... suppression de : "$l' $mon_log_perso
          rmdir "$l"
        fi
      fi
    done
  else
    eval 'echo -e "[\e[42m\u2713 \e[0m] Aucun dossier vide détecté"' $mon_log_perso
  fi
    
  #### Envoie du push de fin du script (si besoin)
  if [[ "$push_fin_script" == "oui" ]] ; then
    for user in {1..10}; do
      destinataire=`eval echo "\\$destinataire_"$user`
      if [ -n "$destinataire" ]; then
        curl -s \
          --form-string "token=$token_app" \
          --form-string "user=$destinataire" \
          --form-string "title=$titre_push" \
          --form-string "message=Traitement terminé" \
          --form-string "html=1" \
          --form-string "priority=0" \
          https://api.pushover.net/1/messages.json > /dev/null
      fi
    done
  fi
else
  eval 'echo -e "[\e[41m\u2717 \e[0m] Aucun média trouvé"' $mon_log_perso
fi
 
if [[ -f "/root/.config/convert2hdlight/.stop-convert" ]]; then
  rm "/root/.config/convert2hdlight/.stop-convert"
fi
if [[ "$mes_medias" == "" ]] ; then
  rm -f "$fichier_log_perso"
  echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE DOSSIERS LOG VIDES  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"
  dossier_log=`echo $dossier_config"/log"`
  find $dossier_log -depth -type d -empty -not -path "$dossier_log" > $dossier_config/dossiers_vides.txt &
  pid=$!
  spin='-\|/'
  i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\rRecherche de dossier(s) log vide(s)... ${spin:$i:1}"
    sleep .1
  done
  printf "$mon_printf" && printf "\r"
  dossiers_vides=()
  while IFS= read -r -d $'\n'; do
    dossiers_vides+=("$REPLY")
  done <$dossier_config/dossiers_vides.txt
  rm -f $dossier_config/dossiers_vides.txt
  if [[ "${dossiers_vides[@]}" != "" ]]; then
    echo -e "[\e[41m\u2717 \e[0m] Des dossiers log vides ont été détectés"
    for l in "${dossiers_vides[@]}"; do
      test_source=`echo $l | grep -o $dossier_log`
      if [[ "$test_source" != "" ]] ; then
        if [[ -d "$l" ]]; then
          echo -e "   ... suppression de : "$l
          rmdir "$l"
        fi
      fi
    done
  else
    echo -e "[\e[42m\u2713 \e[0m] Aucun dossier log vide détecté"
  fi
fi
 
echo "..." > /opt/scripts/.$mon_script_base
 
fin_script=`date`
if [[ -f "$fichier_log_perso" ]]; then
  eval 'echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"' $mon_log_perso
else
  echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"
fi
rm "$pid_script"
 
if [[ "$1" == "--menu" ]]; then
  read -rsp $'Appuyez sur une touche pour fermer la fenêtre...\n' -n1 key
fi
