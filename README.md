# vaonis
script to download fits on vespera pro

prerequisites

- have a linux computer ;
- or have WSL on windows and install Ubuntu or Debian
- be connected to the vespera wifi during shooting

the script was created on debian 12.7 and working on WSL2 on a win10 computer

install WSL : https://learn.microsoft.com/fr-fr/windows/wsl/install or https://learn.microsoft.com/en-us/windows/wsl/install

download the script, and make it executable (chmod +x ftp_vespera.sh) and execute it when you are connected to the vespera's wifi : ./ftp_vespera.sh

change the following parameters to adapt with your environment :

LOCAL_DIR="here_your_disk_letter_and_folder_name"

CHECK_INTERVAL="time_in_second" (set the time compared with exposure time on expert mode) 

By default the script goes to "/user/" folder and check the most recent folder and check on sub folders where the file fits where, after that, the script will download the fits and deleted them. After 10 failed check (the script can(t find any fits files) the script shuts off

Maybe you can improve if you are planning to shoot more than 1 object by night (because i think the script will end during the time the vespera aim another target, so you should increase the check_interval or the max_failed_checks)
