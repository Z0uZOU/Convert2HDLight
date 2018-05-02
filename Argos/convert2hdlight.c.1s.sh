#!/usr/bin/env bash

version="0.0.0.21"

#### Nettoyage
if [[ -f "~/convert2hdlight-update.sh" ]]; then
  rm $HOME/convert2hdlight-update.sh
fi

#### Vérification des dépendances
if [[ ! -f "/bin/yad" ]] && [[ ! -f "/usr/bin/yad" ]]; then yad_missing="1"; fi
if [[ ! -f "/bin/curl" ]] && [[ ! -f "/usr/bin/curl" ]]; then curl_missing="1"; fi
if [[ ! -f "/bin/gawk" ]] && [[ ! -f "/usr/bin/gawk" ]]; then gawk_missing="1"; fi
if [[ ! -f "/bin/wget" ]] && [[ ! -f "/usr/bin/wget" ]]; then wget_missing="1"; fi
if [[ ! -f "/bin/grep" ]] && [[ ! -f "/usr/bin/grep" ]]; then grep_missing="1"; fi
if [[ ! -f "/bin/sed" ]] && [[ ! -f "/usr/bin/sed" ]]; then sed_missing="1"; fi
if [[ "$yad_missing" == "1" ]] || [[ "$curl_missing" == "1" ]] || [[ "$gawk_missing" == "1" ]] || [[ "$wget_missing" == "1" ]] || [[ "$grep_missing" == "1" ]] || [[ "$sed_missing" == "1" ]]; then
  CONVERT2HDLIGHT_BAD_ICON=$(curl -s "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/.cache-icons/hdlightencode-bad-argos.png" | base64 -w 0)
  echo " Erreur(s) | image='$CONVERT2HDLIGHT_BAD_ICON' imageWidth=25"
  echo "---"
  if [[ "$yad_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install yad | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$curl_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install curl | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$gawk_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install gawk | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$wget_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install wget | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$grep_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install grep | ansi=true font='Ubuntu Mono'"; fi
  if [[ "$sed_missing" == "1" ]]; then echo -e "\e[1mDépendance manquante      :\e[0m sudo apt-get install sed | ansi=true font='Ubuntu Mono'"; fi
  echo "---"
  echo "Rafraichir | refresh=true"
  exit 1
fi

#### Création du dossier de notre extension (si il n'existe pas)
if [[ ! -d "$HOME/.config/argos/convert2hdlight/log" ]]; then
  mkdir -p $HOME/.config/argos/convert2hdlight/log
fi

#### Récupération des versions (locale et distante)
script_pastebin="https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/Argos/convert2hdlight.c.1s.sh"
local_version=$version
pastebin_version=`wget -O- -q "$script_pastebin" | grep "^version=" | sed '/grep/d' | sed 's/.*version="//' | sed 's/".*//'`

#### Comparaison des version et mise à jour si nécessaire
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
compare=`testvercomp $local_version $pastebin_version '<' | grep Pass`
if [[ "$compare" != "" ]] ; then
  update_required="Mise à jour disponible"
  (
  echo "0"
  echo "# Creation de l'updater." ; sleep 2
  touch ~/convert2hdlight-update.sh
  echo "25"
  echo "# Chmod de l'updater." ; sleep 2
  chmod +x ~/convert2hdlight-update.sh
  echo "50"
  echo "# Edition de l'updater." ; sleep 2
  echo "#!/bin/bash" > ~/convert2hdlight-update.sh
  echo "(" >> ~/convert2hdlight-update.sh
  echo "echo \"75\"" >> ~/convert2hdlight-update.sh
  echo "echo \"# Mise à jour en cours.\" ; sleep 2" >> ~/convert2hdlight-update.sh
  echo "curl -o ~/.config/argos/convert2hdlight.c.1s.sh $script_pastebin" >> ~/convert2hdlight-update.sh
  echo "sed -i -e 's/\r//g' ~/.config/argos/convert2hdlight.c.1s.sh" >> ~/convert2hdlight-update.sh
  echo "echo \"100\"" >> ~/convert2hdlight-update.sh
  echo ") |" >> ~/convert2hdlight-update.sh
  echo "yad --undecorated --width=500 --progress --center --no-buttons --no-escape --skip-taskbar --image=\"$HOME/.config/argos/.cache-icons/updater.png\" --text-align=\"center\" --text=\"\rUne mise à jour de <b>convert2hdlight.c.1m.sh</b> a été detectée.\r\rVersion locale: <b>$local_version</b>\rVersion distante: <b>$pastebin_version</b>\r\r<b>Installation de la mise à jour...</b>\r\" --auto-kill --auto-close" >> ~/convert2hdlight-update.sh  echo "75"
  echo "# Lancement de l'updater." ; sleep 2
  bash ~/convert2hdlight-update.sh
  exit 1
) |
yad --undecorated --width=500 --progress --center --no-buttons --no-escape --skip-taskbar --image="$HOME/.config/argos/.cache-icons/updater.png" --text-align="center" --text="\rUne mise à jour de <b>convert2hdlight.c.1m.sh</b> a été detectée.\r\rVersion locale: <b>$local_version</b>\rVersion distante: <b>$pastebin_version</b>\r\r<b>Installation de la mise à jour...</b>\r" --auto-kill --auto-close
fi

#### Vérification du cache des icones (ou création)
icons_cache=`echo $HOME/.config/argos/.cache-icons`
if [[ ! -f "$icons_cache" ]]; then
  mkdir -p $icons_cache
fi
if [[ ! -f "$icons_cache/updater.png" ]] ; then curl -o "$icons_cache/updater.png" "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/.cache-icons/updater.png" ; fi
if [[ ! -f "$icons_cache/convert2hdlight-argos.png" ]] ; then curl -o "$icons_cache/convert2hdlight-argos.png" "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/.cache-icons/hdlightencode-argos.png" ; fi
if [[ ! -f "$icons_cache/convert2hdlight-bad-argos.png" ]] ; then curl -o "$icons_cache/convert2hdlight-bad-argos.png" "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/.cache-icons/hdlightencode-bad-argos.png" ; fi
if [[ ! -f "$icons_cache/movie_folder.png" ]] ; then curl -o "$icons_cache/movie_folder.png" "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/.cache-icons/movie_folder.png" ; fi
if [[ ! -f "$icons_cache/movie_file.png" ]] ; then curl -o "$icons_cache/movie_file.png" "https://raw.githubusercontent.com/Z0uZOU/Convert2HDLight/master/.cache-icons/movie_file.png" ; fi

#### Mise en variable des icones
CONVERT2HDLIGHT_ICON=$(curl -s "file://$icons_cache/convert2hdlight-argos.png" | base64 -w 0)
CONVERT2HDLIGHT_BAD_ICON=$(curl -s "file://$icons_cache/convert2hdlight-bad-argos.png" | base64 -w 0)
FOLDER_ICON=$(curl -s "file://$icons_cache/movie_folder.png" | base64 -w 0)
FiLE_ICON=$(curl -s "file://$icons_cache/movie_file.png" | base64 -w 0)

#### Fonction: dehumanize
dehumanise() {
  for v in "$@"
  do  
    echo $v | awk \
      'BEGIN{IGNORECASE = 1}
       function printpower(n,b,p) {printf "%u\n", n*b^p; next}
       /[0-9]$/{print $1;next};
       /K(iB)?$/{printpower($1,  2, 10)};
       /M(iB)?$/{printpower($1,  2, 20)};
       /G(iB)?$/{printpower($1,  2, 30)};
       /T(iB)?$/{printpower($1,  2, 40)};
       /KB$/{    printpower($1, 10,  3)};
       /MB$/{    printpower($1, 10,  6)};
       /GB$/{    printpower($1, 10,  9)};
       /TB$/{    printpower($1, 10, 12)}'
  done
}

#### Fonction: humanize
humanise() {
  b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}o)
  while ((b > 1024)); do
    d="$(printf ".%02d" $((b % 1000 * 100 / 1000)))"
    b=$((b / 1000))
    let s++
  done
  echo "$b$d ${S[$s]}"
}

### Récupération des info en cours
in_progress=`echo "/opt/scripts/.convert2hdlight"`
title=`cat $in_progress | sed -n '1p'`
file=""
folder_in=""
folder_out=""
if [[ $title != "Encodage terminé" ]] && [[ $title != "..." ]] && [[ $title != "" ]]; then
  file=`cat $in_progress | sed -n '3p'`
  #folder_in=`cat $in_progress | sed -n '2p' | sed -e 's/\/'$file'//g'`
  folder_in=$(dirname "$(cat $in_progress | sed -n '2p')")
  folder_out=`cat $in_progress | sed -n '4p'`
  size_file=`ls -l "$folder_in/$fichier" | awk '{print $5}'`
  size_file=`humanise $size_file`
  size_folder_in=`df -Hl "$folder_in" | grep '/dev/' | awk '{print $4}' | sed 's/M/ Mo/' | sed 's/T/ To/' | sed 's/G/ Go/'`
  #size_folder_in=`df $folder_in | grep '/dev/' | awk '{print $4}'`
  #size_folder_in=`humanise $size_folder_in`
  size_folder_out=`df -Hl "$folder_out" | grep '/dev/' | awk '{print $4}' | sed 's/M/ Mo/' | sed 's/T/ To/' | sed 's/G/ Go/'`
  #size_folder_out=`df $folder_out | grep '/dev/' | awk '{print $4}'`
  #size_folder_out=`humanise $size_folder_out`
else
  echo " ... | image='$CONVERT2HDLIGHT_ICON' imageWidth=25"
  chmod -x $HOME/.config/argos/convert2hdlight.c.1s.sh
  exit 1
fi

### Catégorie du média
test_categorie=`echo $file | tr [:upper:] [:lower:] | grep -E "s[0-9][0-9]e[0-9][0-9]|s[0-9]e[0-9][0-9]|- [0-9]x[0-9][0-9] -|- [0-9][0-9]x[0-9][0-9] -|- [0-9]x[0-9][0-9]-[0-9][0-9] -|- [0-9][0-9]x[0-9][0-9]-[0-9][0-9] -"`
if [[ "$test_categorie" != "" ]] ; then
  categorie="Série"
else
  categorie="Film"
fi

### Déclaration de la variable de log
log_file="$HOME/.config/argos/convert2hdlight/temp"

### Récupération des infos du média
mediainfo_resolution=`cat $log_file/mediainfo_resolution.txt`
mediainfo_duree=`cat $log_file/mediainfo_duree.txt`
mediainfo_langue=`cat $log_file/mediainfo_langue.txt`

### Récupération des infos de l'épisode
if [[ "$categorie" == "Série" ]]; then
  serie_nom_en=`cat $log_file/serie_nom_en.txt`
  serie_nom_fr=`cat $log_file/serie_nom_fr.txt`
  serie_annee=`cat $log_file/serie_annee.txt`
  serie_tvdb_id=`cat $log_file/serie_tvdb_id.txt`
  serie_diffusion_episode=`cat $log_file/serie_diffusion_episode.txt`
  serie_genres=`cat $log_file/serie_genres.txt`
  serie_note=`cat $log_file/serie_note.txt`
  serie_saison=`cat $log_file/serie_saison.txt`
  serie_episode=`cat $log_file/serie_episode.txt`
  serie_titre_fr=`cat $log_file/serie_titre_fr.txt`
  serie_titre_en=`cat $log_file/serie_titre_en.txt`
  attention_vide="0"
  if [[ "$serie_nom_en" == "" ]] && [[ "$serie_nom_fr" == "" ]]; then
    attention_vide="1"
  fi
else
### Récupération des infos du film
  film_titre_en=`cat $log_file/serie_nom_en.txt`
  film_titre_fr=`cat $log_file/film_titre_fr.txt`
  film_annee=`cat $log_file/film_annee.txt`
  film_tmdb_id=`cat $log_file/film_tmdb_id.txt`
  film_imdb_id=`cat $log_file/film_imdb_id.txt`
  film_genres=`cat $log_file/film_genres.txt`
  film_note=`cat $log_file/film_note.txt`
  film_origine=`cat $log_file/film_origine.txt`
  film_synopsis=`cat $log_file/film_synopsis.txt`
  attention_vide="0"
  if [[ "$film_titre_en" == "" ]] && [[ "$film_titre_fr" == "" ]]; then
    attention_vide="1"
  fi
fi

#### Récupération de la jaquette
if [[ "$categorie" == "Série" ]]; then
  COVER=$(curl -s "file://$HOME/.config/argos/convert2hdlight/Covers/Séries/$serie_tvdb_id.jpg" | base64 -w 0)
else
  COVER=$(curl -s "file://$HOME/.config/argos/convert2hdlight/Covers/Films/$film_tmdb_id.jpg" | base64 -w 0)
fi

#### On affice le résultat
echo " $title | image='$CONVERT2HDLIGHT_ICON' imageWidth=25"
if [[ "$file" != "" ]]; then
  echo "---"
  if [[ "$categorie" == "Série" ]]; then
    printf "%19s | ansi=true font='Ubuntu Mono' trim=false size=20 terminal=false image=$COVER imageWidth=80 \n" "$serie_nom_fr"
  else
    printf "%19s | ansi=true font='Ubuntu Mono' trim=false size=20 terminal=false image=$COVER imageWidth=80 \n" "$film_titre_fr"
  fi
  printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Fichier" "$file"
  printf "%-2s \u251c\u2500 \e[1m%-13s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "" "Resolution" "$mediainfo_resolution"
  printf "%-2s \u251c\u2500 \e[1m%-13s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "" "Duree" "$mediainfo_duree min"
  printf "%-2s \u251c\u2500 \e[1m%-13s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "" "Langue" "$mediainfo_langue"
  printf "%-2s \u251c\u2500 \e[1m%-13s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "" "Source" "$folder_in ($size_folder_in)"
  printf "%-2s \u2514\u2500 \e[1m%-13s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "" "Destination" "$folder_out ($size_folder_out)"
  if [[ "$attention_vide" == "0" ]]; then
    if [[ "$categorie" == "Série" ]]; then
      if [[ "$serie_nom_fr" != "" ]]; then
        printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Nom" "$serie_nom_fr"
      else
        if [[ "$serie_nom_en" != "" ]]; then
          printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Nom" "$serie_nom_en"
        else
          printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Nom" "Aucune correspondance TvDB"
        fi
      fi
      if [[ "$serie_titre_fr" != "" ]]; then
        printf "\e[1m%-10s\e[0m : %sx%s - %s | ansi=true font='Ubuntu Mono' trim=false \n" "Episode" "$serie_saison" "$serie_episode" "$serie_titre_fr"
      else
        if [[ "$serie_titre_en" != "" ]]; then
          printf "\e[1m%-10s\e[0m : %sx%s - %s | ansi=true font='Ubuntu Mono' trim=false \n" "Episode" "$serie_saison" "$serie_episode" "$serie_titre_en"
        else
          printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Episode" "Aucune correspondance TvDB"
        fi
      fi
    else
      if [[ "$film_titre_fr" != "" ]]; then
        printf "\e[1m%-10s\e[0m : %s (%s) | ansi=true font='Ubuntu Mono' trim=false \n" "Nom" "$film_titre_fr" "$film_annee"
        #printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Synopsis" "$film_synopsis"
      else
        printf "\e[1m%-10s\e[0m : %s (%s) | ansi=true font='Ubuntu Mono' trim=false \n" "Nom" "$film_titre_en" "$film_annee"
        #printf "\e[1m%-10s\e[0m : %s | ansi=true font='Ubuntu Mono' trim=false \n" "Synopsis" "$film_synopsis"
      fi
    fi
  else
    echo "Aucune correspondance"
  fi
fi
echo "---"
printf "%s | ansi=true font='Ubuntu Mono' trim=false size=8 \n" "version: $version"
