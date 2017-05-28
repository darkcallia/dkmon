#!/bin/bash
#darkcallia
#v2017.05.28
#Чтение и сохранение в текстовые файлы мониторинговой информации для дальнейшего использования в других скриптах
#удаляет лишнюю информацию
#запускать в Crontab с необходимой периодичностью
#ящики получателей через запятую. Ящики отдела ОИТ
mailto=xcallia@gmail.com
#ящик отправителя
mailfrom=robot@ro51.fss.ru
#телефон для оповещение
phoneto="+79095603879"
#путь до каталога со скриптом
path=/var/www/dkmon/data

#-------------------------------------
get_ro51_result()
{
 #файл result.txt полученный с сервера 10.51.0.203
 if [ -f "/home/shared/result.txt" ]
 then
  #переходим в каталог
  cd /home/shared/
  #обрабатываем лог
  #переносим только строчки где указывается нужная строка
  sed -n '/RO51/p' result.txt > file1.txt
  #удаляем лишнее и сразу сортируем с ключем -u для удаления дублей
  cat /home/shared/file1.txt | cut -d '\' -f2,2 | cut -d ' ' -f1,1 | sort -u | tr '\n' ',' > $path/data/result_clear.txt
 fi
}
#-------------------------------------
get_sambafree_space()
{
 disk=$(smbclient "$1" -U "$2" -W $3 -c "du" | sed -n '/available/p' | awk '{print $6}')
 #преобразовываем байты в гигабайты
 let "disk_Gb=($disk * $4) / (1024 * 1024 * 1024)"
 echo $disk_Gb > $path/data/$5
}
#-------------------------------------
get_traf()
{
 #Траффик с ф1
 traf=$(iperf3 -c 10.51.1.203 -d -t 10 | sed -n '/ sender\| receiver/p' | awk '{print $7}')
 ro_to_f1_traf=$(echo $traf | awk '{print $1}')
 f1_to_ro_traf=$(echo $traf | awk '{print $2}')
 echo $ro_to_f1_traf > $path/data/ro-to-f1-traf.txt
 echo $f1_to_ro_traf > $path/data/f1-to-ro-traf.txt
 #сохраняем в файл лог
 echo $ro_to_f1_traf";"$f1_to_ro_traf";"`date '+%d-%m-%Y'`";"`date '+%H:%M'` >> $path/data/traf-`date '+%d-%m-%Y'`.log
}
#-------------------------------------
#запускаем нужные функции
#get_ro51_result
#get_sambafree_space "//10.51.0.209/fssbackupdisk" "stat%stat51qwertya" "ro51-00-209" 33553920 "ro-0.209-disk1.txt"
#get_sambafree_space "//10.51.0.209/fssbackupdisk-oldarch" "stat%stat51qwertya" "ro51-00-209" 33553920 "ro-0.209-disk2.txt"
#get_sambafree_space "//10.51.1.205/d$" "fssadmin%rf;#j[j#;tk#pyf" "ro51-01" 4194304 "f1-1.205-disk1.txt"
#get_sambafree_space "//10.51.0.203/c$" "fssadmin%rf;#j[j#;tk#pyf" "ro51" 4194304 "ro-0.203-disk1.txt"
#get_sambafree_space "//10.51.0.203/f$" "fssadmin%rf;#j[j#;tk#pyf" "ro51" 4194304 "ro-0.203-disk2.txt"
#get_traf
