#!/bin/bash
#Постоянный мониторинг с датчиков
#запускать добавив в crontab:
#без кавычек "@reboot sudo /scripts/always_run.sh &"
#darkcallia
#v2017.05.28
#Сообщает на почту и на страницу php о срабатывании датчиков
#Для оповещение по почте используется ssmtp

#ящики получателей через запятую
mailto=xcallia@gmail.com
#ящик отправителя
mailfrom=xcallia@gmail.com
#путь до логов
logpath=/var/www/dkmon/data
#промежуток между сбором данные в сек
timer=10
#предыдущее значение переменной Есть движение
m1_1_prev=0

#функция сбора данных
run_collector(){
  #получаем информацию с arduino используя php
  phpscript=`php -r '$motion=file_get_contents("http://10.51.0.251/"); $M1=substr($motion, strpos($motion, "<M1>")+4, strpos($motion, "</M1>")-(strpos($motion, "<M1>")+4)); echo $M1;'`
  m1_1=$(echo $phpscript | awk -F"." '{print $1}')
  m1_2=$(echo $phpscript | awk -F"." '{print $2}')
  #сохраняем в файл лог
  echo $m1_2";"`date '+%d-%m-%Y'`";"`date '+%H:%M'` >> $logpath/motion-`date '+%d-%m-%Y'`.log
  #сбрасываем значение переменной Есть движение
  if [ $m1_1 == "0" ]
  then
    m1_1_prev=0
  fi
  #сообщаем если пришла 1. Есть движение!
  if [ $m1_1 == "1" ]
  then
    if [ $m1_1_prev == "0" ]
    then
      #меняем дату в файле для check.php
      d=$(echo "`date '+%d.%m.%y'` в `date '+%H:%M'`")
      echo $d > $logpath/checkmotion_clear.txt
      #сохраняем в лог когда произошло событие
      echo $m1_2";"`date '+%d-%m-%Y'`";"`date '+%H:%M'` >> $logpath/motion-warnings.log
      send_warning
    fi
    m1_1_prev=1
  fi
}

send_warning(){
  #действия по извещению о событии
  echo "To: $mailto" > file1
  echo "Subject: Внимание! Движуха в серверной!" >> file1
  echo "From: $mailfrom" >> file1
  echo "Content-Type: text/plain; charset=\"utf-8\"" >> file1
  echo "-" >> file1
  echo "Обнаружено движение в серверной!" >> file1
  /usr/sbin/ssmtp $mailto < file1
  rm file1
}

while true
do
  run_collector
  sleep $timer
done
