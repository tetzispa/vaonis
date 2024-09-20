#!/bin/bash

# Variables de connexion FTP / FTP connection variables
FTP_SERVER="10.0.0.1"    # Remplacer par l'IP ou l'adresse de ton serveur FTP / Replace with FTP server IP
FTP_USER="anonymous"     # Utilisateur FTP / FTP username
REMOTE_DIR="/user"       # Repertoire distant de depart / Starting remote directory

# Repertoire local ou telecharger les fichiers / Local directory to download files
LOCAL_DIR="CHANGE-FOR-YOUR-FOLDER"

# Intervalle entre chaque verification (en secondes) / Interval between checks (in seconds)
CHECK_INTERVAL=15

# Compteur de tentatives infructueuses / Counter for unsuccessful checks
FAILED_CHECKS=0

# Nombre maximum de tentatives infructueuses avant l'arret / Max failed checks before stopping
MAX_FAILED_CHECKS=10

# Fonction pour trouver le repertoire le plus recent / Function to find the most recent directory
find_most_recent_dir() {
  local dir=$1

  # Se connecter au FTP et lister le contenu du repertoire / Connect to FTP and list directory contents
  ftp -inv $FTP_SERVER <<EOF > dir_list.txt
user $FTP_USER
cd $dir
ls -t
bye
EOF

  # Trouver le sous-repertoire le plus recent / Find the most recent directory (first directory listed)
  local most_recent_dir=$(grep "^d" dir_list.txt | awk '{print $9}' | head -n 1)

  # Verifier si un repertoire a ete trouve / Check if a directory was found
  if [ -z "$most_recent_dir" ]; then
    echo "Aucun repertoire trouve dans $dir."  # No directory found in $dir
    exit 1
  fi

  echo "$most_recent_dir"
}

# Fonction pour parcourir les repertoires, telecharger et supprimer les fichiers .fits / Function to explore directories, download and delete .fits files
download_and_delete_fits_in_dir() {
  local dir=$1
  local found_files=0

  # Se connecter au FTP et lister le contenu du repertoire / Connect to FTP and list directory contents
  ftp -inv $FTP_SERVER <<EOF > dir_list.txt
user $FTP_USER
cd $dir
ls
bye
EOF

  # Telecharger les fichiers .fits et les supprimer / Download and delete .fits files
  grep "\.fits" dir_list.txt | awk '{print $9}' | while read -r fits_file; do
    echo "Telechargement du fichier : $fits_file depuis $dir"  # Downloading file from $dir
    ftp -inv $FTP_SERVER <<EOF
user $FTP_USER
cd $dir
lcd $LOCAL_DIR
get $fits_file
delete $fits_file
bye
EOF
    found_files=1
  done

  # Parcourir les sous-repertoires / Explore subdirectories
  grep "^d" dir_list.txt | awk '{print $9}' | while read -r subdir; do
    download_and_delete_fits_in_dir "$dir/$subdir"
  done

  return $found_files
}

# Boucle infinie pour surveiller les nouveaux fichiers .fits / Infinite loop to check for new .fits files
while true; do
  # Trouver le repertoire le plus recent / Find the most recent directory
  most_recent=$(find_most_recent_dir $REMOTE_DIR)

  # Lancer le telechargement et la suppression a partir du repertoire le plus recent / Start downloading and deleting from the most recent directory
  echo "Exploration du repertoire le plus recent : $REMOTE_DIR/$most_recent"  # Exploring most recent directory
  download_and_delete_fits_in_dir "$REMOTE_DIR/$most_recent"
  found=$?

  if [ $found -eq 0 ]; then
    # Aucune fichier trouvé, incremente le compteur / No files found, increment failure count
    ((FAILED_CHECKS++))
    echo "Aucun fichier .fits trouve. Tentative ratee : $FAILED_CHECKS"  # No .fits file found, failed attempt count
  else
    # Des fichiers ont ete trouves, reinitialise le compteur / Files found, reset failure count
    FAILED_CHECKS=0
  fi

  # Verifier si le nombre maximum de tentatives infructueuses est atteint / Check if max failed checks reached
  if [ $FAILED_CHECKS -ge $MAX_FAILED_CHECKS ]; then
    echo "Nombre maximum de tentatives infructueuses atteint. Arret du script."  # Max failed attempts reached, stopping script
    break
  fi

  # Attendre avant la prochaine verification / Wait before next check
  echo "Attente de $CHECK_INTERVAL secondes avant la prochaine verification..."  # Waiting before next check
  sleep $CHECK_INTERVAL
done

# Nettoyer les fichiers temporaires / Clean up temporary files
rm dir_list.txt
