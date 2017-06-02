#!/bin/bash
#версия 7
#darkcallia 2017.02.10
#в скрипте используется php скрипт для заполнения списка узлов через web.
#Скрипт отправляет предупреждения о недоступности серверов или портов раз в день по смс и до устранения проблемы по почте
#Для работы скрипта нужно:
#1. поставить пакет python-xmmp
#2. сделать скрипт для выполнения отсылки сообщения send_jabber_server.sh
#       #!/usr/bin/env python
#       #-*- coding: utf-8 -*-
#       import xmpp,sys
#       xmpp_jid = 'admin@jbr2.ro51.fss.ru'
#       xmpp_pwd = 'z,,th'
#       to = sys.argv[1]
#       msg = sys.argv[2]
#       jid = xmpp.protocol.JID(xmpp_jid)
#       client = xmpp.Client(jid.getDomain(),debug=[])
#       client.connect()
#       client.auth(jid.getNode(),str(xmpp_pwd),resource='xmpppy')
#       client.send(xmpp.protocol.Message(to,msg))
#       client.disconnect()
#3. настроить ssmtp для отправки по почте

#ящики получателей через запятую. Ящики отдела ОИТ
mailto=xcallia@gmail.com
#ящик отправителя
mailfrom=robot@ro51.fss.ru
#телефон для оповещение
phoneto="+79095603879"
#путь до скрита php и файлов txt
phppath=/var/www/html
#путь до каталога со скриптом
path=/var/www/dkmon
#вывод лога в консоль
console_log="1"

run_monitoring(){
  #Для каждого хоста из списка, содержащегося в БД
  #последовательно выполняем функцию check_host
#  phpscript=`php -r '$f=file_get_contents("'$phppath'/checkarray1.txt"); $massiv=unserialize($f); foreach ($massiv as $key=>$j) { echo "$j;$key "; }'`
  phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "active", "1"); foreach ($arraycheckip as $row) { echo "$row[id];$row[ip] "; }'`
#  phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "active", "1");'`
#  phpscript=`php -r 'echo "'$path'/functions.php";'`
#  echo $phpscript
#  exit
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
  exit
}

run_monitoring_port(){
  #Для каждого хоста из списка, содержащегося в файле данных
  #последовательно выполняем функцию check_port
#  phpscript=`php -r '$f=file_get_contents("'$phppath'/checkarray1port.txt"); $massiv=unserialize($f); foreach ($massiv as $key=>$j) { echo "$j:$key "; }'`
  phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "active", "1"); foreach ($arraycheckport as $row) { echo "$row[id]:$row[port] "; }'`
#  keylist=$(echo $phpscript)
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

   #если попадается ранее недоступный хост ставший доступен то удаляем из списка
   if [ "$RESULT" != "" ]
   then

    #проверяем сначала был ли в списке недоступных этот ip
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); \
#if (in_array('$2',$array3)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[alarm]"; }'`
	alarm=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - IP $2 доступен и в БД колонка ALARM = $alarm"; fi
#    #удаляем из списка недоступных IP
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); \
#if (in_array('$2',$array3)) { foreach ($array3 as $keya3=>$a3) { if ($array3[$keya3] == '$2') \
#{ unset($array3[$keya3]); $s=serialize($array3); $f=fopen("'$phppath'/checkarray3.txt", "w"); fwrite($f, $s); fclose($f); } } } }'`
#    list=$(echo $phpscript)

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
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); \
#if (in_array('$3',$array3port)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[alarm]"; }'`
	alarm=$(echo $phpscript)
    #если попадается ранее недоступный порт ставший доступен то удаляем из списка
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); \
#if (in_array('$3',$array3port)) { foreach ($array3port as $keya3=>$a3) { if ($array3port[$keya3] == '$3') \
#{ unset($array3port[$keya3]); $s=serialize($array3port); $f=fopen("'$phppath'/checkarray3port.txt", "w"); fwrite($f, $s); fclose($f); } } } }'`
    
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
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemail.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayemail.txt"); $arrayemail=unserialize($f); \
#if (in_array('$2',$arrayemail)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[email]"; }'`
	warningEmailOn=$(echo $phpscript)
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphone.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayphone.txt"); $arrayphone=unserialize($f); \
#if (in_array('$2',$arrayphone)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[tel]"; }'`
#	temp_id=$(echo $phpscript | awk -F ";" '{print $1}')
#	temp_tel=$(echo $phpscript | awk -F ";" '{print $2}')
#	echo "ID="$temp_id
# 	echo "TEL="$temp_tel
    warningPhoneOn=$(echo $phpscript)
   #проверка по портам	
   else
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemailport.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayemailport.txt"); $arrayemailport=unserialize($f); \
#if (in_array('$3',$arrayemailport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[email]"; }'`
	warningEmailOn=$(echo $phpscript)
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphoneport.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayphoneport.txt"); $arrayphoneport=unserialize($f); \
#if (in_array('$3',$arrayphoneport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[tel]"; }'`
	warningPhoneOn=$(echo $phpscript)
   fi
   #стоит галочка что нужно оповещать по email
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
    #/usr/sbin/ssmtp $mailto < file1
	if [ $console_log == "1" ]; then cat file1; fi
    rm file1
   fi
   #стоит галочка что нужно оповещать по СМС
   if [ $warningPhoneOn == "1" ]
   then
    #А здесь будут выполнены действия по извещению о доступности хоста
	#$1 - id в таблице, $2 - ip адрес
    MESSAGE="$1 $2"
    #/usr/bin/python /scripts/sendsms/sendsms.py $phoneto "$MESSAGE start" > /dev/null
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
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); \
#if (in_array('$2',$array3)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[alarm]"; }'`
	alarm=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Сервис IP $2 недоступен и у него был ALARM = $alarm"; fi
   else
    #проверяем сначала был ли в списке недоступных этот порт
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); \
#if (in_array('$3',$array3port)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
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
#     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemail.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayemail.txt"); $arrayemail=unserialize($f); \
#if (in_array('$2',$arrayemail)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
	 phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[email]"; }'`
     warningEmailOn=$(echo $phpscript)
	 if [ $console_log == "1" ]; then echo "test step - Предупреждение по EMAIL - $warningEmailOn"; fi
#     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphone.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayphone.txt"); $arrayphone=unserialize($f); \
#if (in_array('$2',$arrayphone)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
     phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "id", "'$1'"); foreach ($arraycheckip as $row) { echo "$row[tel]"; }'`
	 warningPhoneOn=$(echo $phpscript)
	 if [ $console_log == "1" ]; then echo "test step - Предупреждение по TEL - $warningPhoneOn"; fi
    else
#     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemailport.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayemailport.txt"); $arrayemailport=unserialize($f); \
#if (in_array('$3',$arrayemailport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
	 phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckport=fromtable("'$path'/$dbfile", "checkport", "id", "'$1'"); foreach ($arraycheckport as $row) { echo "$row[email]"; }'`
     warningEmailOn=$(echo $phpscript)
	 if [ $console_log == "1" ]; then echo "test step - Предупреждение по EMAIL - $warningEmailOn"; fi
#     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphoneport.txt") > 6) { \
#$f=file_get_contents("'$phppath'/checkarrayphoneport.txt"); $arrayphoneport=unserialize($f); \
#if (in_array('$3',$arrayphoneport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
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
     #/usr/sbin/ssmtp $mailto < file1
	 if [ $console_log == "1" ]; then cat file1; fi
     rm file1
    fi
    if [ $warningPhoneOn == "1" ]
    then
     #А здесь будут выполнены действия по извещению о недоступности хоста
     MESSAGE="$1 $2"
     #/usr/bin/python /scripts/sendsms/sendsms.py $phoneto "$MESSAGE STOP" > /dev/null
     if [ $console_log == "1" ]; then echo "$phoneto $MESSAGE STOP"; fi
    fi
   fi
   #меняем таблицу, добавляя ставших недоступными
   if [ $3 == "ip" ]
   then
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") < 7) { $array3=array('$2'); } else { \
#$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); if (!in_array('$2',$array3)) \
#{ array_push($array3, '$2'); } } $s=serialize($array3); $f=fopen("'$phppath'/checkarray3.txt", "w"); fwrite($f, $s); fclose($f);'`
#    list=$(echo $phpscript)
    phpscript=`php -r 'include "'$path'/functions.php"; updatetable("'$path'/$dbfile", "checkip", "id", "'$1'", "alarm", "1");'`
	run_phpscript=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Сервис IP $2 недоступен и меняем в БД значение ALARM"; fi
   else
#    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") < 7) { $array3port=array('$3'); } else { \
#$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); if (!in_array('$3',$array3port)) \
#{ array_push($array3port, '$3'); } } $s=serialize($array3port); $f=fopen("'$phppath'/checkarray3port.txt", "w"); fwrite($f, $s); fclose($f);'`
	phpscript=`php -r 'include "'$path'/functions.php"; updatetable("'$path'/$dbfile", "checkport", "id", "'$1'", "alarm", "1");'`
    run_phpscript=$(echo $phpscript)
	if [ $console_log == "1" ]; then echo "test step - Сервис PORT $2 $3 недоступен и меняем в БД значение ALARM"; fi
   fi
  fi
}

#run_monitoring
#не выполняем скрипт мониторинга портов в определенные часы
hour_now=$(date +%H)
if [[ ($hour_now == "00") || ($hour_now == "01") || ($hour_now == "02") || ($hour_now == "03") || ($hour_now == "04") || ($hour_now == "05") || ($hour_now == "06") || ($hour_now == "06") || ($hour_now == "07") || ($hour_now == "08") ]]
 then
  exit
 fi
run_monitoring_port
