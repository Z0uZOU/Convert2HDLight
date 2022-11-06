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
## Installation sh: wget -q https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/convert2hdlight.sh -O convert2hdlight.sh && sed -i -e 's/\r//g' convert2hdlight.sh && chmod +x convert2hdlight.sh
## Micro-config
version="Version: 0.0.2.0" #base du système de mise à jour
description="Convertisseur en HDLight" #description pour le menu
script_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/convert2hdlight.sh" #emplacement du script original
changelog_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/Changelog/convert2hdlight" #emplacement du changelog de ce script
icone_github="https://github.com/Z0uZOU/Convert2HDLight/raw/master/.cache-icons/convert2hdlight.png" #emplacement de l'icône du script
required_repos="" #ajout de repository
required_tools="handbrake-cli trash-cli curl mlocate lm-sensors mediainfo" #dépendances du script
required_tools_pip="" #dépendances du script (PIP)
script_cron="0 * * * *" #ne définir que la planification
verification_process="HandBrakeCLI" #si ces process sont détectés on ne notifie pas (ou ne lance pas en doublon)
mon_fichier_json_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/hdlight-encode.json" #lien vers le fichier json, fichier nécessaire pour la conversion
mon_script_argos_github="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/Argos/convert2hdlight.c.1s.sh" #lien vers le script Argos
lien_filebot="https://github.com/Z0uZOU/Convert2HDLight/tree/master/FileBot" #lien vers l'installer de filebot 
########################


#### Vérification de la présence du Net
net_connection=`ping thetvdb.com -c 1 2>/dev/null | grep "1 received"`
if [[ "$net_connection" == "" ]]; then
  mon_script_fichier=`basename "$0"`
  mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
  mon_dossier_config=`echo "/root/.config/"$mon_script_base`
  affichage_langue=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
  mon_script_langue=`echo $mon_dossier_config"/MUI/"$affichage_langue".lang"`

  end_of_script=`date`
  if [[ ! -f "$mon_script_langue" ]]; then
    mui_no_connection=" -- No Internet connection -- "
    mui_end_of_script=" -- END OF SCRIPT: $end_of_script -- "
  else
    source $mon_script_langue
  fi
  
  my_title_count=`echo -n "$mui_no_connection" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_no_connection" "$after"' $mon_log_perso

  my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"' $mon_log_perso

  if [[ "$1" == "--menu" ]]; then
    read -rsp $'Press a key to close the window...\n' -n1 key
  fi
  exit 1
fi
md5_404_not_found=`curl -s "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/404" | md5sum  | cut -f1 -d" "`

#### Vérification de la langue du system
if [[ "$@" =~ "--langue=" ]]; then
  affichage_langue=`echo "$@" | sed 's/.*--langue=//' | sed 's/ .*//' | tr '[:upper:]' '[:lower:]'`
else
  affichage_langue=$(locale | grep LANG | sed -n '1p' | cut -d= -f2 | cut -d_ -f1)
fi
verif_langue=`curl -s "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/MUI/$affichage_langue.lang" | md5sum  | cut -f1 -d" "`
if [[ "$verif_langue" == "$md5_404_not_found" ]]; then
  affichage_langue="en"
fi

#### Déduction des noms des fichiers (pour un portage facile)
mon_script_fichier=`basename "$0"`
mon_script_base=`echo ''$mon_script_fichier | cut -f1 -d'.'''`
mon_script_base_maj=`echo ${mon_script_base^^}`
mon_dossier_config=`echo "/root/.config/"$mon_script_base`
mon_script_config=`echo $mon_dossier_config"/"$mon_script_base".conf"`
mon_script_langue=`echo $mon_dossier_config"/MUI/"$affichage_langue".lang"`
mon_script_desktop=`echo $mon_script_base".desktop"`
mon_script_updater=`echo $mon_script_base"-update.sh"`
mon_script_pid=`echo $mon_dossier_config"/lock-"$mon_script_base`
mon_path_log=`echo $mon_dossier_config"/log"`
date_log=`date +%Y%m%d`
heure_log=`date +%H%M`
mon_fichier_log=`echo $mon_path_log"/"$date_log"/"$heure_log".log"`

#### Vérification que le script possède les droits root
## NE PAS TOUCHER
if [ "$(whoami)" != "root" ]; then
  if [[ "$CRON_SCRIPT" == "oui" ]]; then
    exit 1
  else
    source <(curl -s https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/MUI/$affichage_langue.lang)
    echo "$mui_root_check"
    exit 1
  fi
fi

#### Chargement du fichier pour la langue (ou installation)
if [[ -f "$mon_script_langue" ]]; then
  distant_md5=`curl -s "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/MUI/$affichage_langue.lang" | md5sum | cut -f1 -d" "`
  local_md5=`md5sum "$mon_script_langue" 2>/dev/null | cut -f1 -d" "`
  if [[ $distant_md5 != $local_md5 ]]; then
    wget --quiet "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/MUI/$affichage_langue.lang" -O "$mon_script_langue"
    chmod +x "$mon_script_langue"
  fi
else
  mkdir $mon_dossier_config"/MUI"
  wget --quiet "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/MUI/$affichage_langue.lang" -O "$mon_script_langue"
  chmod +x "$mon_script_langue"
fi
source $mon_script_langue

#### Fonction pour envoyer des push
push-message() {
  push_title=$1
  push_content=$2
  push_priority=$3
  for user in {1..10}; do
    destinataire=`eval echo "\\$destinataire_"$user`
    if [ -n "$destinataire" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$destinataire" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=$push_priority" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}

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
      echo "$process_travail $mui_prevent_dupe_task"
      end_of_script=`date`
      source $mon_script_langue
      my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"
    fi
    exit 1
  fi
done

#### Initialisation des variables
no_update="non"
ignore_range="non"
force_encodage="non"
parametre_source=""
rennomage_filebot="non"

#### Tests des arguments
for parametre in $@; do
  if [[ "$parametre" == "--debug" ]]; then
    debug="yes"
  fi
  if [[ "$parametre" == "--edit-config" ]]; then
    nano $mon_script_config
    exit 1
  fi
  if [[ "$parametre" == "--efface-lock" ]]; then
    mon_lock=`echo $mon_dossier_config"/lock-"$mon_script_base`
    rm -f "$mon_lock"
    echo -e "$mui_lock_removed"
    exit 1
  fi
  if [[ "$parametre" == "--statut-lock" ]]; then
    statut_lock=`cat $mon_script_config | grep "maj_force=\"oui\""`
    if [[ "$statut_lock" == "" ]]; then
      echo -e "$mui_lock_status_on"
    else
      echo -e "$mui_lock_status_off"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--active-lock" ]]; then
    sed -i 's/maj_force="oui"/maj_force="non"/g' $mon_script_config
    echo -e "$mui_lock_status_on"
    exit 1
  fi
  if [[ "$parametre" == "--desactive-lock" ]]; then
    sed -i 's/maj_force="non"/maj_force="oui"/g' $mon_script_config
    echo -e "$mui_lock_status_off"
    exit 1
  fi
  if [[ "$parametre" == "--extra-log" ]]; then
    mon_log_perso="| tee -a $mon_fichier_log"
  fi
  if [[ "$parametre" == "--purge-process" ]]; then
    pgrep -x "$mon_script_fichier" | xargs kill -9
    echo -e "$mui_purge_process"
    exit 1
  fi
  if [[ "$parametre" == "--purge-log" ]]; then
    cd $mon_path_log
    mon_chemin=`echo $PWD`
    if [[ "$mon_chemin" == "$mon_path_log" ]]; then
      printf "$mui_purge_log_question : "
      read question_effacement
      reponse_effacement=`echo $question_effacement | tr '[:upper:]' '[:lower:]'`
      if [[ "$reponse_effacement" == "$mui_purge_log_answer_yes" ]]; then
        rm -rf *
        echo -e "$mui_purge_log_done"
      fi
    else
      echo -e "$mui_purge_log_ko"
    fi
    exit 1
  fi
  if [[ "$parametre" == "--help" ]]; then
    i=""
    for i in _ {a..z} {A..Z}; do eval "echo \${!$i@}" ; done | xargs printf "%s\n" | grep mui_menu_help > variables
    help_lignes=`wc -l variables | awk '{print $1}'`
    rm -f variables
    j=""
    mui_menu_help="mui_menu_help_"
    for j in $(seq 1 $help_lignes); do
      source $mon_script_langue
      mui_menu_help_display=`echo -e "$mui_menu_help$j"`
      echo -e "${!mui_menu_help_display}"
    done
    exit 1
  fi
  if [[ "$parametre" == "--no-update" ]]; then
    no_update="oui"
  fi
  if [[ "$parametre" == "--ignore-range" ]]; then
    ignore_range="oui"
  fi
  if [[ "$parametre" == "--filebot" ]]; then
    rennomage_filebot="oui"
  fi
  if [[ "$parametre" == "--force-encodage" ]]; then
    force_encodage="oui"
  fi
  if [[ "$parametre" =~ "--source:" ]]; then
    parametre_source=`echo $parametre | sed 's/--source://g'`
  fi
done

#### Chargement du fichier conf si présent
if [[ -f "$mon_script_config" ]] ; then
  source $mon_script_config
fi

#### Vérification qu'au reboot les lock soient bien supprimés
test_crontab=`crontab -l | grep "clean-lock"`
if [[ "$test_crontab" == "" ]]; then
  crontab -l > $dossier_config/mon_cron.txt
  sed -i '5i@reboot\t\t\tsleep 10 && /opt/scripts/clean-lock.sh' $dossier_config/mon_cron.txt
  crontab $dossier_config/mon_cron.txt
  rm -f $dossier_config/mon_cron.txt
fi
if [[ ! -f "/opt/scripts/clean-lock.sh" ]]; then
  wget -q https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/extras/clean-lock.sh -O /opt/scripts/clean-lock.sh && sed -i -e 's/\r//g' /opt/scripts/clean-lock.sh && chmod +x /opt/scripts/clean-lock.sh
fi

#### Vérification qu'une autre instance de ce script ne s'exécute pas
if [[ "$maj_force" == "non" ]] ; then
  if [[ -f "$mon_script_pid" ]] ; then
    computer_name=`hostname`
    source $mon_script_langue
    echo "$mui_pid_check"
    push-message "$mui_pid_check_title" "$mui_pid_check" "1"
    exit 1
  fi
fi
touch $mon_script_pid

#### Chemin du script
## necessaire pour le mettre dans le cron
cd /opt/scripts

#### Indispensable aux messages de chargement
mon_printf="\r                                                                                                                                "

#### Nettoyage obligatoire et push pour annoncer la maj
if [[ -f "$mon_script_updater" ]] ; then
  rm "$mon_script_updater"
  push-message "$mui_pushover_updated_title" "$mui_pushover_updated_msg" "1"
fi

#### Vérification de version pour éventuelle mise à jour
distant_md5=`curl -s "$script_github" | md5sum | cut -f1 -d" "`
local_md5=`md5sum "$0" 2>/dev/null | cut -f1 -d" "`
if [[ "$md5_404_not_found" != "$distant_md5" ]];then
  if [[ "$distant_md5" != "$local_md5" ]]; then
    eval 'echo -e "$mui_update_available"' $mon_log_perso
    if [[ "$no_update" == "non" ]]; then
      eval 'echo -e "$mui_update_download"' $mon_log_perso
      touch $mon_script_updater
      chmod +x $mon_script_updater
      echo "#!/bin/bash" >> $mon_script_updater
      mon_script_fichier_temp=`echo $mon_script_fichier"-temp"`
      echo "wget -q $script_github -O $mon_script_fichier_temp" >> $mon_script_updater
      echo "sed -i -e 's/\r//g' $mon_script_fichier_temp" >> $mon_script_updater
      echo "mv $mon_script_fichier_temp $mon_script_fichier" >> $mon_script_updater
      echo "chmod +x $mon_script_fichier" >> $mon_script_updater
      echo "chmod 777 $mon_script_fichier" >> $mon_script_updater
      echo "$mui_update_done" >> $mon_script_updater
      echo "bash $mon_script_fichier $@" >> $mon_script_updater
      echo "exit 1" >> $mon_script_updater
      rm "$mon_script_pid"
      bash $mon_script_updater
      exit 1
    else
      eval 'echo -e "$mui_update_not_downloaded"' $mon_log_perso
    fi
  fi
else
  my_title_count=`echo -n "$mui_no_connection" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_no_connection" "$after"' $mon_log_perso
fi
source $mon_script_langue
my_title_count=`echo -n "$mui_title" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
line_lengh="78"
before_count=$((($line_lengh-$my_title_count)/2))
after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
before=`eval printf "%0.s-" {1..$before_count}`
after=`eval printf "%0.s-" {1..$after_count}`
eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_title" "$after"' $mon_log_perso

#### Nécessaire pour l'argument --update
if [[ "$@" == "--update" ]]; then
  rm "$mon_script_pid"
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
  eval 'echo -e "$mui_cron_path_updated"' $mon_log_perso
else
  rm -f $dossier_config/mon_cron.txt
fi

#### Mise en place éventuelle d'un cron
if [[ "$script_cron" != "" ]]; then
  mon_cron=`crontab -l`
  verif_cron=`echo "$mon_cron" | grep "$mon_script_fichier"`
  if [[ "$verif_cron" == "" ]]; then
    my_title_count=`echo -n "$mui_no_cron_entry" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
    line_lengh="78"
    before_count=$((($line_lengh-$my_title_count)/2))
    after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
    before=`eval printf "%0.s-" {1..$before_count}`
    after=`eval printf "%0.s-" {1..$after_count}`
    eval 'printf "\e[41m%s%s%s\e[0m\n" "$before" "$mui_no_cron_entry" "$after"' $mon_log_perso
    eval 'echo "$mui_no_cron_creating"' $mon_log_perso
    ajout_cron=`echo -e "$script_cron\t\t/opt/scripts/$mon_script_fichier > /var/log/$mon_script_log 2>&1"`
    eval 'echo "$mui_no_cron_adding"' $mon_log_perso
    crontab -l > $dossier_config/mon_cron.txt
    echo -e "$ajout_cron" >> $dossier_config/mon_cron.txt
    crontab $dossier_config/mon_cron.txt
    rm -f $dossier_config/mon_cron.txt
    eval 'echo "$mui_no_cron_updated"' $mon_log_perso
  else
    if [[ "${verif_cron:0:1}" == "#" ]]; then	
      my_title_count=`echo -n "$mui_script_in_cron_disable" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_script_in_cron_disable" "$after"' $mon_log_perso
	else
      my_title_count=`echo -n "$mui_script_in_cron" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
      line_lengh="78"
      before_count=$((($line_lengh-$my_title_count)/2))
      after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
      before=`eval printf "%0.s-" {1..$before_count}`
      after=`eval printf "%0.s-" {1..$after_count}`
      eval 'printf "\e[101m%s%s%s\e[0m\n" "$before" "$mui_script_in_cron" "$after"' $mon_log_perso
    fi
  fi
fi

#### Vérification/création du fichier conf
if [[ -f $mon_script_config ]] ; then
  my_title_count=`echo -n "$mui_conf_ok" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[42m%s%s%s\e[0m\n" "$before" "$mui_conf_ok" "$after"' $mon_log_perso
else
  my_title_count=`echo -n "$mui_conf_missing" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | wc -c`
  line_lengh="78"
  before_count=$((($line_lengh-$my_title_count)/2))
  after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
  before=`eval printf "%0.s-" {1..$before_count}`
  after=`eval printf "%0.s-" {1..$after_count}`
  eval 'printf "\e[41m%s%s%s\e[0m\n" "$before" "$mui_conf_missing" "$after"' $mon_log_perso
  eval 'echo "$mui_conf_creating"' $mon_log_perso
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
## Activation du script argos
activer_argos="oui"
## Sources
dossier_source="/mnt/sdc1/Handbrake/A_Convertir"
## Cibles
dossier_cible="/mnt/sdc1/Handbrake/Converti"
dossier_cible_traite="/mnt/sdc1/Handbrake/Traité"
dossier_cible_erreur="/mnt/sdc1/Handbrake/Erreur"
dossier_cible_media_3D="/mnt/sdc1/Handbrake/Media_3D"
dossier_filebot_films="/mnt/sdc1/Downloads/Films_Hdlight"
dossier_filebot_series="/mnt/sdc1/Downloads/Séries_HQ"
## Température maximum avant coupure du script
temperature_max="85"
 
#### Paramètre du push
debug_dev="non"
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
  eval 'echo "$mui_no_conf_created"'
  eval 'echo "$mui_no_conf_edit"'
  eval 'echo "mui_no_conf_help"'
  rm $pid_script
  exit 1
fi
echo "------------------------------------------------------------------------------"

#### VERIFICATION DES DEPENDANCES
##########################
eval 'printf  "\e[44m\u2263\u2263  \e[0m \e[44m \e[1m %-62s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n" "$mui_section_dependencies"' $mon_log_perso


#### Vérification et installation des repositories (apt)
for repo in $required_repos ; do
  ppa_court=`echo $repo | sed 's/.*ppa://' | sed 's/\/ppa//'`
  check_repo=`grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep "$ppa_court"`
    if [[ "$check_repo" == "" ]]; then
      add-apt-repository $repo -y
      update_a_faire="1"
    else
      source $mon_script_langue
      eval 'echo -e "$mui_required_repository"' $mon_log_perso
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
      source $mon_script_langue
      eval 'echo -e "$mui_required_apt"' $mon_log_perso
    fi
done

#### Vérification et installation des outils requis si besoin (pip)
for tools_pip in $required_tools_pip ; do
  check_tool=`pip freeze | grep "$tools_pip"`
    if [[ "$check_tool" == "" ]]; then
      pip install $tools_pip
    else
      source $mon_script_langue
      eval 'echo -e "$mui_required_pip"' $mon_log_perso
    fi
done

#### Ajout de ce script dans le menu
if [[ -f "/etc/xdg/menus/applications-merged/scripts-scoony.menu" ]] ; then
  useless=1
else
  eval 'echo "$mui_creating_menu_entry"' $mon_log_perso
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
  eval 'echo "$mui_created_menu_entry"' $mon_log_perso
fi

if [[ -f "/usr/share/desktop-directories/scripts-scoony.directory" ]] ; then
  useless=1
else
## je met l'icone en place
  wget -q http://i.imgur.com/XRCxvJK.png -O /usr/share/icons/scripts.png
  eval 'echo "$mui_creating_menu_folder"' $mon_log_perso
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
cd /opt/scripts




end_of_script=`date`
source $mon_script_langue
my_title_count=`echo -n "$mui_end_of_script" | sed "s/\\\e\[[0-9]\{1,2\}m//g" | sed 's/é/e/g' | wc -c`
line_lengh="78"
before_count=$((($line_lengh-$my_title_count)/2))
after_count=$(((($line_lengh-$my_title_count)%2)+$before_count))
before=`eval printf "%0.s-" {1..$before_count}`
after=`eval printf "%0.s-" {1..$after_count}`
eval 'printf "\e[43m%s%s%s\e[0m\n" "$before" "$mui_end_of_script" "$after"' $mon_log_perso
if [[ "$maj_necessaire" == "1" ]] && [[ -f "$fichier_log_perso" ]]; then
  cp $fichier_log_perso /var/log/$mon_script_base-last.log
fi
#rm "$mon_script_pid"

if [[ "$1" == "--menu" ]]; then
  read -rsp $'Press a key to close the window...\n' -n1 key
fi
exit 1


### OLD


#### Vérification de FileBot
filebot_present=`filebot -version 2>/dev/null`
if [[ "$filebot_present" =~ "FileBot" ]] || [[ "$filebot_present" =~ "Unrecognized option" ]]; then
  filebot_local=`filebot -version | awk '{print $2}' 2>/dev/null`
  if [[ "$filebot_present" =~ "Unrecognized option" ]]; then
    filebot_local="Inconnue"
  fi
  echo -e "[\e[42m\u2713 \e[0m] La dépendance: filebot est installée ("$filebot_local")"
else
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
    wget -q "$mon_script_argos_github" -O "$chemin_argos/convert2hdlight.c.1s.sh" && sed -i -e 's/\r//g' "$chemin_argos/convert2hdlight.c.1s.sh" && chmod 777 "$chemin_argos/convert2hdlight.c.1s.sh" && chmod -x "$chemin_argos/convert2hdlight.c.1s.sh"
  else
    if [[ -x "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
      chmod -x "$chemin_argos/convert2hdlight.c.1s.sh"
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
if [[ ! -d "$dossier_source" ]]; then mkdir -p "$dossier_source"; fi
libre_dossier_source=`df --total -hl "$dossier_source" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier source: "$libre_dossier_source"\n[..... "$dossier_source' $mon_log_perso
if [[ ! -d "$dossier_cible" ]]; then mkdir -p "$dossier_cible"; fi
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
    if [[ "$destination_films_hd" != "" ]]; then
      if [[ ! -d "$destination_films_hd" ]]; then mkdir -p "$destination_films_hd"; fi
      libre_films_hd=`df --total -hl "$destination_films_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
      eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier filebot films HD: "$libre_filebot_films_hd"\n[..... "$filebot_films_hd' $mon_log_perso
    fi
    if [[ "$filebot_films_hd" != "" ]]; then
      if [[ ! -d "$filebot_films_hd" ]]; then mkdir -p "$filebot_films_hd"; fi
      libre_filebot_films_hd=`df --total -hl "$filebot_films_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
      eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier destination films HD: "$libre_films_hd"\n[..... "$destination_films_hd' $mon_log_perso
    fi
    # eval $(source $range_path; echo destination_series_hdtv=$cible_auto_series_hdtv)
    # eval $(source $range_path; echo filebot_series_hdtv=$download_auto_series_hdtv)
    # libre_series_hdtv=`df --total -hl "$destination_series_hdtv" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    # libre_filebot_series_hdtv=`df --total -hl "$filebot_series_hdtv" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
    # eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier filebot séries HDTV: "$libre_filebot_series_hdtv"\n[..... "$filebot_series_hdtv' $mon_log_perso
    # eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier destination séries HDTV: "$libre_series_hdtv"\n[..... "$destination_series_hdtv' $mon_log_perso
    eval $(source $range_path; echo destination_series_hd=$cible_auto_series_hd)
    eval $(source $range_path; echo filebot_series_hd=$download_auto_series_hd)
    if [[ "$destination_series_hd" != "" ]]; then
      if [[ ! -d "$destination_series_hd" ]]; then mkdir -p "$destination_series_hd"; fi
      libre_series_hd=`df --total -hl "$destination_series_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
      eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier filebot séries HD: "$libre_filebot_series_hd"\n[..... "$filebot_series_hd' $mon_log_perso
    fi
    if [[ "$filebot_series_hd" != "" ]]; then
      if [[ ! -d "$filebot_series_hd" ]]; then mkdir -p "$filebot_series_hd"; fi
      libre_filebot_series_hd=`df --total -hl "$filebot_series_hd" | grep "total" | awk '{print $4}' | sed 's/T/To/' | sed 's/G/Go/'`
      eval 'echo -e "[\e[42m\u2713 \e[0m] Dossier destination séries HD: "$libre_series_hd"\n[..... "$destination_series_hd' $mon_log_perso
    fi
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
find "$dossier_source" -type f -iname '*[avi|mp4|mkv]' -print0 | sort -z >$dossier_config/tmpfile
while IFS= read -r -d $'\0'; do
  mes_medias+=("$REPLY")
done <$dossier_config/tmpfile
rm -f $dossier_config/tmpfile
 
## Traitement des médias
if [[ "$mes_medias" != "" ]] ; then
  #### Activation du script argos
  if [[ -f "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
    echo "..." > /opt/scripts/.$mon_script_base
    if [[ "$activer_argos" == "oui" ]]; then chmod +x "$chemin_argos/convert2hdlight.c.1s.sh"; fi 
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
      filebot -mediainfo "$mon_media" --format "#0¢{gigabytes}#1¢{minutes}#2¢{vf}#3¢{vc}#4¢{audio.Language}#5¢{audio.Format}#6¢{kbps}#7¢{s3d}#8¢{audio.Channels}#9¢" 2>/dev/null > $dossier_config/mediainfo.txt &
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
      mediainfo_channels=`cat $dossier_config/mediainfo.txt | sed 's/.*#8¢//' | sed 's/#9¢.*//'`
      mediainfo_langue_clean=`echo $mediainfo_langue | sed 's/\[//g' | sed 's/\]//g'`
      mediainfo_langue_codec_clean=`echo $mediainfo_langue_codec | sed 's/\[//g' | sed 's/\]//g'`
      mediainfo_channels_clean=`echo $mediainfo_channels | sed 's/\[//g' | sed 's/\]//g'`
      rm -f $dossier_config/mediainfo.txt
      
#### Sauvegarde des caractéristiques du média
      if [[ -d "$chemin_argos" ]] && [[ "$activer_argos" == "oui" ]]; then
        if [[ ! -d "$chemin_argos/convert2hdlight/temp" ]]; then
          mkdir -p $chemin_argos/convert2hdlight/temp
        else
          rm -f $chemin_argos/convert2hdlight/temp/*
        fi
        echo "$mediainfo_duree" > $chemin_argos/convert2hdlight/temp/mediainfo_duree.txt
        echo "$mediainfo_resolution" > $chemin_argos/convert2hdlight/temp/mediainfo_resolution.txt
        echo "$mediainfo_langue_clean" > $chemin_argos/convert2hdlight/temp/mediainfo_langue.txt
      fi
      output_folder=`dirname "$mon_media"`
      if [[ "$categorie" == "Film" ]]; then
        filebot --action test -script fn:amc -non-strict --conflict override --lang fr --encoding UTF-8 -rename "$mon_media" --def minFileSize=0 --def "movieFormat=#0¢{localize.English.n}#1¢{localize.French.n}#2¢{y}#3¢{id}#4¢{imdbid}#5¢{localize.French.genres}#6¢{rating}#7¢{info.ProductionCountries}#8¢" --output "$output_folder" 2>/dev/null > $dossier_config/mediainfo.txt &
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
          url_tmdb="https://www.themoviedb.org/movie/$film_tmdb_id/fr"
          if [[ -d "$chemin_argos" ]] && [[ "$activer_argos" == "oui" ]]; then
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
        fi
      else
        filebot --action test -script fn:amc -non-strict --conflict override --lang fr --encoding UTF-8 -rename "$mon_media" --def minFileSize=0 --def "seriesFormat=#0¢{localize.English.n}#1¢{localize.French.n}#2¢{y}#3¢{id}#4¢{airdate}#5¢{genres}#6¢{rating}#7¢{s}#8¢{e.pad(2)}#9¢{localize.French.t}#10¢{localize.English.t}#11¢" --output "$output_folder" 2>/dev/null > $dossier_config/mediainfo.txt &
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
          if [[ -d "$chemin_argos" ]] && [[ "$activer_argos" == "oui" ]]; then
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
        fi
      fi
      if [[ -d "$chemin_argos" ]]; then chmod 777 -R $chemin_argos/convert2hdlight; fi
      rm -f $dossier_config/mediainfo.txt
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| taille : $mediainfo_taille"' $mon_log_perso
      mediainfo_duree_clean=`printf '%dh %02dmin' $(($mediainfo_duree/60)) $(($mediainfo_duree%60))`
	  eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| durée : $mediainfo_duree_clean"' $mon_log_perso
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| résolution : $mediainfo_resolution ($mediainfo_codec - $mediainfo_bitrate)"' $mon_log_perso
      eval 'echo -e "[..... |\e[7m ORIGINAL \e[0m| langue(s) : $mediainfo_langue_clean ($mediainfo_langue_codec_clean) ($mediainfo_channels_clean)"' $mon_log_perso
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
            #temperature=`cat $dossier_config/tempcpu.txt | grep -oP 'Tdie.*?\+\K[0-9]+' | sed -n '1p'`
            rm -f $dossier_config/tempcpu.txt
            if [[ "$temperature_max" == "" ]]; then temperature_max="95"; fi
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
              echo "$categorie" >> /opt/scripts/.$mon_script_base
              if [[ "$categorie" == "Film" ]]; then
                echo "$film_titre_fr ($film_annee)" >> /opt/scripts/.$mon_script_base
              else
                echo "$serie_nom_fr ("$serie_saison"x$serie_episode)" >> /opt/scripts/.$mon_script_base
              fi
              tail -1 /root/.config/convert2hdlight/ma_conversion.txt | awk '{print $NF}' | sed "s/)//" >> /opt/scripts/.$mon_script_base
            else
              printf "\rEncodage en cours... ${spin:$e:1}"
              echo "Encodage en cours" > /opt/scripts/.$mon_script_base
              echo "$mon_media" >> /opt/scripts/.$mon_script_base
              echo "$fichier" >> /opt/scripts/.$mon_script_base
              echo "$dossier_cible" >> /opt/scripts/.$mon_script_base
              echo "$categorie" >> /opt/scripts/.$mon_script_base
              if [[ "$categorie" == "Film" ]]; then
                echo "$film_titre_fr ($film_annee)" >> /opt/scripts/.$mon_script_base
              else
                echo "$serie_nom_fr ("$serie_saison"x$serie_episode)" >> /opt/scripts/.$mon_script_base
              fi
              tail -1 /root/.config/convert2hdlight/ma_conversion.txt | awk '{print $NF}' | sed "s/)//" >> /opt/scripts/.$mon_script_base
            fi
            sleep .1
          done
          printf "$mon_printf" && printf "\r"
          echo "Encodage terminé" > /opt/scripts/.$mon_script_base
          rm -f /root/.config/convert2hdlight/ma_conversion.txt
          heure_fin=`date +%H:%M:%S`
          eval 'echo -e "[..... |\e[7m ENCODAGE \e[0m| fin de conversion à $heure_fin"' $mon_log_perso
          mv "$dossier_cible/$fichier-part" "$dossier_cible/$fichier"
          main_user=`getent passwd "1000" | cut -d: -f1`
          chown $main_user:$main_user "$dossier_cible/$fichier"
          chmod 777 "$dossier_cible/$fichier"
          filebot -mediainfo "$dossier_cible/$fichier" --format "#0¢{gigabytes}#1¢{minutes}#2¢{vf}#3¢{vc}#4¢{audio.Language}#5¢{audio.Format}#6¢{kbps}#7¢{s3d}#8¢{audio.Channels}#9¢" > $dossier_config/mediainfo.txt &
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
          mediainfo_channels=`cat $dossier_config/mediainfo.txt | sed 's/.*#8¢//' | sed 's/#9¢.*//'`
          mediainfo_langue_enc_clean=`echo $mediainfo_langue_enc | sed 's/\[//g' | sed 's/\]//g'`
          mediainfo_langue_codec_enc_clean=`echo $mediainfo_langue_codec_enc | sed 's/\[//g' | sed 's/\]//g'`
          mediainfo_channels_clean=`echo $mediainfo_channels | sed 's/\[//g' | sed 's/\]//g'`
          rm -f $dossier_config/mediainfo.txt
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| taille : $mediainfo_taille_enc"' $mon_log_perso
          mediainfo_duree_enc_clean=`printf '%dh %02dmin' $(($mediainfo_duree_enc/60)) $(($mediainfo_duree_enc%60))`
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| durée : $mediainfo_duree_enc_clean"' $mon_log_perso
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| résolution : $mediainfo_resolution_enc ($mediainfo_codec_enc - $mediainfo_bitrate_enc)"' $mon_log_perso
          eval 'echo -e "[..... |\e[7m CONVERTI \e[0m| langue(s) : $mediainfo_langue_enc_clean ($mediainfo_langue_codec_enc_clean) ($mediainfo_channels_clean)"' $mon_log_perso
          mv "$dossier_cible/$fichier" "$dossier_cible/$fichier-part"
          echec_conversion="0"
          if [[ "$mediainfo_duree" == "$mediainfo_duree_enc" ]]; then
            eval 'echo -e "[..... |\e[42m CONVERSION REUSSIE, REMPLACEMENT ET MISE EN PLACE \e[0m|"' $mon_log_perso
            if [[ "$rennomage_filebot" == "oui" ]]; then
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
              filebot -script fn:amc -non-strict --conflict override --lang fr --encoding UTF-8 -rename "$dossier_cible/$fichier" --def "$format=$output" --output "$dossier_cible" > $dossier_config/traitement.txt 2>/dev/null &
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
              fichier_filebot=`cat $dossier_config/traitement.txt | grep "MOVE" | cut -d'[' -f3 | sed 's/].*//g'`
              if [[ "$fichier_filebot" == "" ]]; then
                eval 'echo -e "[..... |\e[42m FILEBOT  \e[0m| Nommage du fichier conforme : $fichier"' $mon_log_perso			  
			           else
  		       	    nombre_crochet=`cat $dossier_config/traitement.txt | grep -o "\[" | wc -m`
                if [[ "$nombre_crochet" == "6" ]]; then
                  fichier_filebot=`cat $dossier_config/traitement.txt | grep "MOVE" | cut -d'[' -f4 | sed 's/].*//g'`
                fi
                if [[ "$nombre_crochet" == "8" ]]; then
                  fichier_filebot=`cat $dossier_config/traitement.txt | grep "MOVE" | cut -d'[' -f5 | sed 's/].*//g'`
                fi
                if [[ "$nombre_crochet" == "10" ]]; then
                  fichier_filebot=`cat $dossier_config/traitement.txt | grep "MOVE" | cut -d'[' -f6 | sed 's/].*//g'`
                fi
                fichier=`basename "$fichier_filebot"`
                eval 'echo -e "[..... |\e[42m FILEBOT  \e[0m| Renommage du fichier en : $fichier"' $mon_log_perso
			           fi
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
            ##trash-put "$mon_media"
            ##if [[ ! -d "$dossier_cible_traite" ]]; then mkdir -p "$dossier_cible_traite"; fi
            ##mv "$mon_media" "$dossier_cible_traite"
            ##chmod 777 "$dossier_cible_traite"
            main_user=`getent passwd "1000" | cut -d: -f1`
            trash_path=`df -h "$mon_media" | tail -1 | awk -F% '{print $NF}' | tr -d ' '`
            if [[ "$trash_path" == "/" ]]; then
              trash_path="/home/$main_user/.local/share/Trash/files"
            else
              trash_path=`echo "$trash_path/.Trash-1000/files"`
            fi
            chown $main_user:$main_user "$mon_media"
            if [[ ! -d "$trash_path" ]]; then
	      mkdir -p "$trash_path"
	      chown $main_user:$main_user -R "$trash_path"
	    fi
	    mv "$mon_media" "$trash_path"
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
    if [[ -x "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
      chmod -x "$chemin_argos/convert2hdlight.c.1s.sh"
    fi
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
  if [[ -f "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
    if [[ -x "$chemin_argos/convert2hdlight.c.1s.sh" ]]; then
      chmod -x "$chemin_argos/convert2hdlight.c.1s.sh"
    fi
  fi
  eval 'echo -e "[\e[41m\u2717 \e[0m] Aucun média trouvé"' $mon_log_perso
fi
 
if [[ -f "/root/.config/convert2hdlight/.stop-convert" ]]; then
  rm "/root/.config/convert2hdlight/.stop-convert"
fi
if [[ "$mes_medias" == "" ]]; then
  rm -f "$fichier_log_perso"
  echo -e "\e[44m\u2263\u2263  \e[0m \e[44m \e[1mRECHERCHE DE DOSSIERS LOG VIDES  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m"
  dossier_log=`echo $dossier_config"/log"`
  if [[ ! -d "$dossier_log" ]]; then mkdir -p "$dossier_source"; fi
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
  cp $fichier_log_perso /var/log/$mon_script_base-last.log
else
  echo -e "\e[43m-- FIN DE SCRIPT: $fin_script --\e[0m"
fi
rm "$pid_script"
 
if [[ "$1" == "--menu" ]]; then
  read -rsp $'Appuyez sur une touche pour fermer la fenêtre...\n' -n1 key
fi
