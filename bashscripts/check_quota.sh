#!/bin/bash
#darkcallia
#v2017.05.28
#Чтение и сохранение в текстовые файлы мониторинговой информации для дальнейшего использования в других скриптах
#удаляет лишнюю информацию
#-------------------------------------
#файл result.txt полученный с сервера 10.51.0.203
if [ -f "/home/shared/result.txt" ]
then
 #переходим в каталог
 cd /home/shared/
 #обрабатываем лог
 #переносим только строчки где указывается нужная строка
 sed -n '/RO51/p' result.txt > file1.txt
 #удаляем лишнее и сразу сортируем с ключем -u для удаления дублей
 cat /home/shared/file1.txt | cut -d '\' -f2,2 | cut -d ' ' -f1,1 | sort -u | tr '\n' ',' > result_clear.txt
fi
#-------------------------------------
#Свободное место на 0.209
#собираем информацию
fssbackupdisk_b=$(smbclient "//10.51.0.209/fssbackupdisk" -U "stat%stat51qwerty" -W ro51-00-209 -c "du" | sed -n '/available/p' | awk '{print $6}')
fssbackupdisk_oldarch_b=$(smbclient "//10.51.0.209/fssbackupdisk-oldarch" -U "stat%stat51qwerty" -W ro51-00-209 -c "du" | sed -n '/available/p' | awk '{print $6}')
#преобразовываем байты в гигабайты
let "fssbackupdisk_Gb=(fssbackupdisk_b * 33553920) / (1024 * 1024 * 1024)"
let "fssbackupdisk_oldarch_Gb=(fssbackupdisk_oldarch_b * 33553920) / (1024 * 1024 * 1024)"
echo $fssbackupdisk_Gb > /home/shared/ro-0.209-disk1.txt
echo $fssbackupdisk_oldarch_Gb > /home/shared/ro-0.209-disk2.txt
#-------------------------------------
#Свободное место на 1.205
#собираем информацию
fssbackupdisk_b=$(smbclient "//10.51.1.205/d$" -U "fssadmin%rf;#j[j#;tk#pyf" -W ro51-01 -c "du" | sed -n '/available/p' | awk '{print $6}')
#преобразовываем байты в гигабайты
let "fssbackupdisk_Gb=(fssbackupdisk_b * 4194304) / (1024 * 1024 * 1024)"
echo $fssbackupdisk_Gb > /home/shared/f1-1.205-disk1.txt
#-------------------------------------
#Свободное место на 0.203
#собираем информацию
disk_c=$(smbclient "//10.51.0.203/c$" -U "fssadmin%rf;#j[j#;tk#pyf" -W ro51 -c "du" | sed -n '/available/p' | awk '{print $6}')
disk_f=$(smbclient "//10.51.0.203/f$" -U "fssadmin%rf;#j[j#;tk#pyf" -W ro51 -c "du" | sed -n '/available/p' | awk '{print $6}')
#преобразовываем байты в гигабайты
let "disk_c_Gb=(disk_c * 4194304) / (1024 * 1024 * 1024)"
let "disk_f_Gb=(disk_f * 4194304) / (1024 * 1024 * 1024)"
echo $disk_c_Gb > /home/shared/ro-0.203-disk1.txt
echo $disk_f_Gb > /home/shared/ro-0.203-disk2.txt
#-------------------------------------
#-------------------------------------
#Траффик с ф1
#путь до логов
logpath=/var/www/html/motionlog
traf=$(iperf3 -c 10.51.1.203 -d -t 10 | sed -n '/ sender\| receiver/p' | awk '{print $7}')
#ro_to_f1_traf=$(echo $traf | sed -n '/ sender/p' | awk '{print $7}')
#f1_to_ro_traf=$(echo $traf | sed -n '/ receiver/p' | awk '{print $7}')
ro_to_f1_traf=$(echo $traf | awk '{print $1}')
f1_to_ro_traf=$(echo $traf | awk '{print $2}')
#traf=$(iperf3 -c 10.51.1.203 -d -t 10 | sed -n '/ sender/p' | awk '{print $7}')
echo $ro_to_f1_traf > /home/shared/ro-to-f1-traf.txt
echo $f1_to_ro_traf > /home/shared/f1-to-ro-traf.txt
#сохраняем в файл лог
echo $ro_to_f1_traf";"$f1_to_ro_traf";"`date '+%d-%m-%Y'`";"`date '+%H:%M'` >> $logpath/traf-`date '+%d-%m-%Y'`.log
#-------------------------------------
