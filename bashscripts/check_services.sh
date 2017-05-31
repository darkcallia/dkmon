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

run_monitoring(){
  # Для каждого хоста из списка, содержащегося в файле данных
  # последовательно выполняем функцию check_host
  #парсим файл со списком
#  phpscript=`php -r '$f=file_get_contents("'$phppath'/checkarray1.txt"); $massiv=unserialize($f); foreach ($massiv as $key=>$j) { echo "$j;$key "; }'`
  phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "active", "1"); foreach ($arraycheckip as $row) { echo "$row[id];$row[ip] "; }'`
#  phpscript=`php -r 'include "'$path'/functions.php"; $arraycheckip=fromtable("'$path'/$dbfile", "checkip", "active", "1");'`
#  phpscript=`php -r 'echo "'$path'/functions.php";'`
#  echo $phpscript
#  exit
  keylist=$(echo $phpscript)
  #идем по списку
  for i in $keylist ; do
    j=$(echo $i | awk -F ";" '{print $1}')
    p=$(echo $i | awk -F ";" '{print $2}')
    k="ip"
    #check_host $j $p $k
    echo $j $p $k
  done
  exit
}

run_monitoring_port(){
  # Для каждого хоста из списка, содержащегося в файле данных
  # последовательно выполняем функцию check_port
  #парсим файл со списком
  phpscript=`php -r '$f=file_get_contents("'$phppath'/checkarray1port.txt"); $massiv=unserialize($f); foreach ($massiv as $key=>$j) { echo "$j:$key "; }'`
  keylist=$(echo $phpscript)
  #идем по списку
  for i in $keylist ; do
    j=$(echo $i | awk -F ":" '{print $1}')
    p=$(echo $i | awk -F ":" '{print $2}')
    q=$(echo $i | awk -F ":" '{print $3}')
    k="port"
    check_host $j $p $q $k
  done
}

check_host(){
  repeat="0"
  if [ $3 == "ip" ]
  #проверяем по IP
  then
   RESULT=`ping -s 0 -c 2 $1 | grep ttl`
   #перепроверяем пинг при недоступности :)
   if [ "$RESULT" == "" ]
   then
    RESULT=`ping -s 0 -c 20 $1 | grep ttl`
   fi

   #если попадается ранее недоступный хост ставший доступен то удаляем из списка
   if [ "$RESULT" != "" ]
   then
    #проверяем сначала был ли в списке недоступных этот ip
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); \
if (in_array('$2',$array3)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    repeat=$(echo $phpscript)
    #удаляем из списка недоступных IP
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); \
if (in_array('$2',$array3)) { foreach ($array3 as $keya3=>$a3) { if ($array3[$keya3] == '$2') \
{ unset($array3[$keya3]); $s=serialize($array3); $f=fopen("'$phppath'/checkarray3.txt", "w"); fwrite($f, $s); fclose($f); } } } }'`
    list=$(echo $phpscript)
   fi
  #проверяем по портам
  else
   if nc -z $1 $2
   then
    RESULT="isup"
    #проверяем сначала был ли в списке недоступных этот порт
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); \
if (in_array('$3',$array3port)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    repeat=$(echo $phpscript)
    #если попадается ранее недоступный порт ставший доступен то удаляем из списка
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); \
if (in_array('$3',$array3port)) { foreach ($array3port as $keya3=>$a3) { if ($array3port[$keya3] == '$3') \
{ unset($array3port[$keya3]); $s=serialize($array3port); $f=fopen("'$phppath'/checkarray3port.txt", "w"); fwrite($f, $s); fclose($f); } } } }'`
    list=$(echo $phpscript)
   else
    RESULT=""
   fi
  fi
  #Проверяем если сервис в списке был в недоступных и стал доступен, то высылаем оповещение что сервис стал доступен
  if [ $repeat == "1" ]
  then
   #проверяем стоит ли галочка, что нужно оповещать
   warningEmailOn="0"
   warningPhoneOn="0"
   if [ $3 == "ip" ]
   then
    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemail.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayemail.txt"); $arrayemail=unserialize($f); \
if (in_array('$2',$arrayemail)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    warningEmailOn=$(echo $phpscript)
    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphone.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayphone.txt"); $arrayphone=unserialize($f); \
if (in_array('$2',$arrayphone)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    warningPhoneOn=$(echo $phpscript)
   else
    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemailport.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayemailport.txt"); $arrayemailport=unserialize($f); \
if (in_array('$3',$arrayemailport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    warningEmailOn=$(echo $phpscript)
    phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphoneport.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayphoneport.txt"); $arrayphoneport=unserialize($f); \
if (in_array('$3',$arrayphoneport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    warningPhoneOn=$(echo $phpscript)
   fi
   if [ $warningEmailOn == "1" ]
   then
    #А здесь будут выполнены действия по извещению о доступности хоста
    MESSAGE="$1 $2"
    echo "$MESSAGE"
    echo "To: $mailto" > file1
    echo "Subject: Внимание! Сервис вновь доступен." >> file1
    echo "From: $mailfrom" >> file1
    echo "Content-Type: text/plain; charset=\"utf-8\"" >> file1
    echo "-" >> file1
    echo "Сервис $MESSAGE доступен." >> file1
    /usr/sbin/ssmtp $mailto < file1
    rm file1
   fi
   if [ $warningPhoneOn == "1" ]
   then
    #А здесь будут выполнены действия по извещению о доступности хоста
    MESSAGE="$1 $2"
    /usr/bin/python /scripts/sendsms/sendsms.py $phoneto "$MESSAGE start" > /dev/null
#    echo START
   fi
  fi

  #если попадается недоступный хост
  if [ "$RESULT" == "" ]
  then
   repeat="0"
   if [ $3 == "ip" ]
   then
    #проверяем сначала был ли в списке недоступных этот ip
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); \
if (in_array('$2',$array3)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    repeat=$(echo $phpscript)
   else
    #проверяем сначала был ли в списке недоступных этот порт
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); \
if (in_array('$3',$array3port)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
    repeat=$(echo $phpscript)
   fi
   #Проверяем если сервис в списке был в недоступных, то НЕ высылаем оповещение что сервис недоступен
   if [ $repeat == "0" ]
   then
    #проверяем стоит ли галочка, что нужно оповещать
    warningEmailOn="0"
    warningPhoneOn="0"
    if [ $3 == "ip" ]
    then
     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemail.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayemail.txt"); $arrayemail=unserialize($f); \
if (in_array('$2',$arrayemail)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
     warningEmailOn=$(echo $phpscript)
     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphone.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayphone.txt"); $arrayphone=unserialize($f); \
if (in_array('$2',$arrayphone)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
     warningPhoneOn=$(echo $phpscript)
    else
     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayemailport.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayemailport.txt"); $arrayemailport=unserialize($f); \
if (in_array('$3',$arrayemailport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
     warningEmailOn=$(echo $phpscript)
     phpscript=`php -r 'if (filesize("'$phppath'/checkarrayphoneport.txt") > 6) { \
$f=file_get_contents("'$phppath'/checkarrayphoneport.txt"); $arrayphoneport=unserialize($f); \
if (in_array('$3',$arrayphoneport)) { echo("1"); } else { echo("0"); } } else { echo("0"); }'`
     warningPhoneOn=$(echo $phpscript)
    fi
    if [ $warningEmailOn == "1" ]
    then
     # А здесь будут выполнены действия по извещению о недоступности хоста
     MESSAGE="$1 $2"
     echo "$MESSAGE"
     echo "To: $mailto" > file1
     echo "Subject: Внимание! Нет доступности!" >> file1
     echo "From: $mailfrom" >> file1
     echo "Content-Type: text/plain; charset=\"utf-8\"" >> file1
     echo "-" >> file1
     echo "Сервис $MESSAGE недоступен!" >> file1
     /usr/sbin/ssmtp $mailto < file1
     rm file1
    fi
    if [ $warningPhoneOn == "1" ]
    then
     #А здесь будут выполнены действия по извещению о недоступности хоста
     MESSAGE="$1 $2"
     /usr/bin/python /scripts/sendsms/sendsms.py $phoneto "$MESSAGE STOP" > /dev/null
 #    echo STOP
    fi
   fi
   #меняем массив с описанием добавляя ставших недоступными
   if [ $3 == "ip" ]
   then
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3.txt") < 7) { $array3=array('$2'); } else { \
$f=file_get_contents("'$phppath'/checkarray3.txt"); $array3=unserialize($f); if (!in_array('$2',$array3)) \
{ array_push($array3, '$2'); } } $s=serialize($array3); $f=fopen("'$phppath'/checkarray3.txt", "w"); fwrite($f, $s); fclose($f);'`
    list=$(echo $phpscript)
   else
    phpscript=`php -r 'if (filesize("'$phppath'/checkarray3port.txt") < 7) { $array3port=array('$3'); } else { \
$f=file_get_contents("'$phppath'/checkarray3port.txt"); $array3port=unserialize($f); if (!in_array('$3',$array3port)) \
{ array_push($array3port, '$3'); } } $s=serialize($array3port); $f=fopen("'$phppath'/checkarray3port.txt", "w"); fwrite($f, $s); fclose($f);'`
    list=$(echo $phpscript)
   fi
  fi
}

run_monitoring
exit
#не выполняем скрипт мониторинга портов в определенные часы
hour_now=$(date +%H)
if [[ ($hour_now == "00") || ($hour_now == "01") || ($hour_now == "02") || ($hour_now == "03") || ($hour_now == "04") || ($hour_now == "05") || ($hour_now == "06") || ($hour_now == "06") || ($hour_now == "07") || ($hour_now == "08") ]]
 then
  exit
 fi
run_monitoring_port