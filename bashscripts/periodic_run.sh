#!/bin/bash
#darkcallia
#v2017.05.28
#Чтение и сохранение в текстовые файлы мониторинговой информации для дальнейшего использования в других скриптах. Удаляет лишнюю информацию из полученных данных
#Мониторинг сервисов по портам и ip для вебстраницы
#запускать в Crontab с необходимой периодичностью

#ящики получателей через запятую. Ящики отдела ОИТ
mailto=xcallia@gmail.com
#ящик отправителя
mailfrom=robot@ro51.fss.ru
#телефон для оповещение
phoneto="+79095603879"
#путь до каталога со скриптом
path=/var/www/dkmon
#вывод лога в консоль
console_log="1"

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
get_temperature()
{
 #Получаем температуру с подключенной Arduino
 PORT="/dev/ttyS1";
 stty -F $PORT 9600;
 read -rn 100 data < $PORT;
 echo $data | awk -F"<t2>" '{ print $2 }' | awk -F"</t2>" '{ print $1 }' > /var/www/dkmon/data/temperaturet2.txt
}
#-------------------------------------
get_foto()
{
 #Получаем фото с камеры
 cd $path/data;
 wget http://192.168.1.111/picture.jpg 
}
#-------------------------------------
run_monitoring(){
 #Для каждого хоста из списка, содержащегося в БД
 #последовательно выполняем функцию check_host
 phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "active", "1"); foreach ($arraycheckip as $row) { echo "$row[id];$row[ip] "; }'`
 request_result=$(echo $phpscript)
 #идем по списку
 for i in $request_result ; do
  j=$(echo $i | awk -F ";" '{print $1}')
  p=$(echo $i | awk -F ";" '{print $2}')
  k="ip"
  if [ $console_log == "1" ]; then echo "test step - Проверяем $j $p $k"; fi
  check_host $j $p $k
  if [ $console_log == "1" ]; then echo "--------------------------"; fi
 done 
}
#-------------------------------------
run_monitoring_port(){
 #Для каждого хоста из списка, содержащегося в БД
 #последовательно выполняем функцию check_port
 phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "active", "1"); foreach ($arraycheckport as $row) { echo "$row[id]:$row[port] "; }'`
 request_result=$(echo $phpscript)
 #идем по списку
 for i in $request_result ; do
  j=$(echo $i | awk -F ":" '{print $1}')
  p=$(echo $i | awk -F ":" '{print $2}')
  q=$(echo $i | awk -F ":" '{print $3}')
  k="port"
  if [ $console_log == "1" ]; then echo "test step - Проверяем $j $p $q $k"; fi
  check_host $j $p $q $k
  if [ $console_log == "1" ]; then echo "--------------------------"; fi	
 done
}
#-------------------------------------
check_host(){
 alarm="0"
 if [ $3 == "ip" ]
 #проверяем по IP
 then
  if [ $console_log == "1" ]; then echo "test step - Пингуем $2"; fi
  RESULT=`ping -s 0 -c 2 $2 | grep ttl`
  #перепроверяем пинг при недоступности :)
  if [ "$RESULT" == "" ]
  then
   if [ $console_log == "1" ]; then echo "test step - Первый проход показал недоступность. Пингуем повторно $2"; fi
   RESULT=`ping -s 0 -c 20 $2 | grep ttl`
  fi
  #если попадается ранее недоступный хост ставший доступен то сбрасываем значение тревоги-недоступности сервиса по IP
  if [ "$RESULT" != "" ]
  then
   #проверяем сначала был ли в списке недоступных этот ip
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[alarm]"; }'`
   alarm=$(echo $phpscript)
   if [ $console_log == "1" ]; then echo "test step - IP $2 доступен и в БД колонка ALARM = $alarm"; fi
   #Сбрасываем значение тревоги-недоступности сервиса по IP
   phpscript=`php -r 'include "'$path'/functions.php"; updatetable("'$path'/$dbfile", "checkip", "id", "'$1'", "alarm", "0");'`
   run_phpscript=$(echo $phpscript)
  fi
 #проверяем по портам
 else
  if nc -z $2 $3
  then
   RESULT="isup"
   #проверяем сначала был ли в списке недоступных этот порт
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[alarm]"; }'`
   alarm=$(echo $phpscript)
   if [ $console_log == "1" ]; then echo "test step - PORT $2 $3 доступен и в БД колонка ALARM = $alarm"; fi   
   #Сбрасываем значение тревоги-недоступности сервиса по IP
   phpscript=`php -r 'include "'$path'/functions.php"; updatetable("'$path'/$dbfile", "checkport", "id", "'$1'", "alarm", "0");'`
   run_phpscript=$(echo $phpscript)
  else
   RESULT=""
  fi
 fi
 #Теперь проверяем если сервис был ранее в недоступных и стал доступен, то высылаем оповещение что сервис стал доступен
 if [ $alarm == "1" ]
 then
  #проверяем стоит ли галочка, что нужно оповещать
  warningEmailOn="0"
  warningPhoneOn="0"
  #проверка по ip
  if [ $3 == "ip" ]
  then
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[email]"; }'`
   warningEmailOn=$(echo $phpscript)
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[tel]"; }'`
   warningPhoneOn=$(echo $phpscript)
  #проверка по портам	
  else
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[email]"; }'`
   warningEmailOn=$(echo $phpscript)
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[tel]"; }'`
   warningPhoneOn=$(echo $phpscript)
  fi
  #Если стоит галочка что нужно оповещать по email
  if [ $warningEmailOn == "1" ]
  then
   #А здесь будут выполнены действия по извещению о доступности хоста
   #$1 - id в таблице, $2 - ip адрес
   MESSAGE="$1 $2"
   echo "$MESSAGE"
   echo "To: $mailto" > file1
   echo "Subject: Внимание! Сервис вновь доступен." >> file1
   echo "From: $mailfrom" >> file1
   echo "Content-Type: text/plain; charset=\"utf-8\"" >> file1
   echo "-" >> file1
   echo "Сервис $MESSAGE доступен." >> file1
#   /usr/sbin/ssmtp $mailto < file1
   if [ $console_log == "1" ]; then cat file1; fi
   rm file1
  fi
  #стоит галочка что нужно оповещать по СМС
  if [ $warningPhoneOn == "1" ]
  then
   #А здесь будут выполнены действия по извещению о доступности хоста
   #$1 - id в таблице, $2 - ip адрес
   MESSAGE="$1 $2"
#   /usr/bin/python /scripts/sendsms/sendsms.py $phoneto "$MESSAGE start" > /dev/null
   if [ $console_log == "1" ]; then echo "$phoneto $MESSAGE start"; fi
  fi
 fi
 #если попадается недоступный хост
 if [ "$RESULT" == "" ]
 then
  alarm="0"
  if [ $3 == "ip" ]
  then
   #проверяем сначала был ли в списке недоступных этот ip
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[alarm]"; }'`
   alarm=$(echo $phpscript)
   if [ $console_log == "1" ]; then echo "test step - Сервис IP $2 недоступен и у него был ALARM = $alarm"; fi
  else
   #проверяем сначала был ли в списке недоступных этот порт
   phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[alarm]"; }'`
   alarm=$(echo $phpscript)
   if [ $console_log == "1" ]; then echo "test step - Сервис PORT $2 $3 недоступен и у него был ALARM = $alarm"; fi
  fi
  #Проверяем если сервис в списке был в недоступных, то НЕ высылаем оповещение что сервис недоступен
  #0 - был ранее доступен
  if [ $alarm == "0" ]
  then
   #проверяем стоит ли галочка, что нужно оповещать
   warningEmailOn="0"
   warningPhoneOn="0"
   if [ $3 == "ip" ]
   then
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[email]"; }'`
    warningEmailOn=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Предупреждение по EMAIL - $warningEmailOn"; fi
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[tel]"; }'`
    warningPhoneOn=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Предупреждение по TEL - $warningPhoneOn"; fi
   else
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[email]"; }'`
    warningEmailOn=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Предупреждение по EMAIL - $warningEmailOn"; fi
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[tel]"; }'`
    warningPhoneOn=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Предупреждение по TEL - $warningPhoneOn"; fi
   fi
   if [ $warningEmailOn == "1" ]
   then
    # А здесь будут выполнены действия по извещению о недоступности хоста
	#$1 - id в таблице, $2 - ip адрес
    MESSAGE="$1 $2"
    echo "$MESSAGE"
    echo "To: $mailto" > file1
    echo "Subject: Внимание! Нет доступности!" >> file1
    echo "From: $mailfrom" >> file1
    echo "Content-Type: text/plain; charset=\"utf-8\"" >> file1
    echo "-" >> file1
    echo "Сервис $MESSAGE недоступен!" >> file1
#    /usr/sbin/ssmtp $mailto < file1
	if [ $console_log == "1" ]; then cat file1; fi
    rm file1
   fi
   if [ $warningPhoneOn == "1" ]
   then
    #А здесь будут выполнены действия по извещению о недоступности хоста
    MESSAGE="$1 $2"
#    /usr/bin/python /scripts/sendsms/sendsms.py $phoneto "$MESSAGE STOP" > /dev/null
    if [ $console_log == "1" ]; then echo "$phoneto $MESSAGE STOP"; fi
   fi
  fi
  #меняем таблицу, добавляя ставших недоступными
  if [ $3 == "ip" ]
  then
   phpscript=`php -r 'include "'$path'/functions.php"; updatetable("'$path'/$dbfile", "checkip", "id", "'$1'", "alarm", "1");'`
   run_phpscript=$(echo $phpscript)
   if [ $console_log == "1" ]; then echo "test step - Сервис IP $2 недоступен и меняем в БД значение ALARM"; fi
  else
   phpscript=`php -r 'include "'$path'/functions.php"; updatetable("'$path'/$dbfile", "checkport", "id", "'$1'", "alarm", "1");'`
   run_phpscript=$(echo $phpscript)
   if [ $console_log == "1" ]; then echo "test step - Сервис PORT $2 $3 недоступен и меняем в БД значение ALARM"; fi
  fi
 fi
}
#-------------------------------------
#-------------------------------------
#-------------------------------------
#-------------------------------------
#-------------------------------------
#запускаем нужные функции
#get_ro51_result
#get_sambafree_space "//10.51.0.209/fssbackupdisk" "stat%stat51qwertya" "ro51-00-209" 33553920 "ro-0.209-disk1.txt"
#get_sambafree_space "//10.51.0.209/fssbackupdisk-oldarch" "stat%stat51qwertya" "ro51-00-209" 33553920 "ro-0.209-disk2.txt"
#get_sambafree_space "//10.51.1.205/d$" "fssadmin%rf;#j[j#;tk#pyf" "ro51-01" 4194304 "f1-1.205-disk1.txt"
#get_sambafree_space "//10.51.0.203/c$" "fssadmin%rf;#j[j#;tk#pyf" "ro51" 4194304 "ro-0.203-disk1.txt"
#get_sambafree_space "//10.51.0.203/f$" "fssadmin%rf;#j[j#;tk#pyf" "ro51" 4194304 "ro-0.203-disk2.txt"
#get_traf
#get_temperature
#get_foto
#run_monitoring
#не выполняем скрипт мониторинга портов в определенные часы
hour_now=$(date +%H)
if [[ ($hour_now == "00") || ($hour_now == "01") || ($hour_now == "02") || ($hour_now == "03") || ($hour_now == "04") || ($hour_now == "05") || ($hour_now == "06") || ($hour_now == "06") || ($hour_now == "07") || ($hour_now == "08") ]]
 then
  exit
 fi
#run_monitoring_port