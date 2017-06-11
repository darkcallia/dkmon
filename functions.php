<?php
//darkcallia
//2017
//функции и переменные для проекта dkmon
//используемые массивы
$arraycheckip=array();//содержит таблицу "checkip" опрашиваемых сервисов по ip
$arraycheckport=array();//содержит таблицу "checkport" опрашиваемых сервисов по порту
//файл БД
$dbfile="mysqlitedb.db";
/*----------------------------------------------*/
/*проверка есть файл базы*/
function dbexist($db)
{
// echo "step1";
// $dbtemp=new SQLite3($db);
 if(!file_exists($db))
 {
//  $dbtemp=new SQLite3($db);
//  echo "step2";
  createdb($db);
  return false;
 } else { /*echo "step3";*/ return true; }
}
/*----------------------------------------------*/
/*создание пустых таблиц*/
function createdb($db)
{
// $dbtemp=new SQLite3($db);
 if(file_exists($db))
 {
  $dbtemp=new SQLite3($db);
  $dbtemp->exec('DROP TABLE IF EXISTS checkip');
  $dbtemp->exec('DROP TABLE IF EXISTS checkport');
 }
 $dbtemp=new SQLite3($db);
 $dbtemp->exec('CREATE TABLE checkip (id INTEGER PRIMARY KEY AUTOINCREMENT, ip TEXT, name TEXT, tel INTEGER, email INTEGER, alarm INTEGER, active INTEGER)');
 $dbtemp->exec("INSERT INTO checkip (ip, name, tel, email, alarm, active) VALUES ('127.0.0.1', 'Локальный хост', 0, 0, 0, 1)");
 $dbtemp->exec('CREATE TABLE checkport (id INTEGER PRIMARY KEY AUTOINCREMENT, port TEXT, name TEXT, tel INTEGER, email INTEGER, alarm INTEGER, active INTEGER)');
 $dbtemp->exec("INSERT INTO checkport (port, name, tel, email, alarm, active) VALUES ('127.0.0.1:80', 'Локальный хост', 0, 0, 0, 1)");
}
/*----------------------------------------------*/
/*выборка из таблицы*/
function fromtable($db, $table, $columnsearch, $valuesearch)//, $columnanswer)
{
 if (dbexist($db))
  {
//   echo "db exist<br>";
   $dbtemp=new SQLite3($db);
   //$res=$dbtemp->query('SELECT '.$columnanswer.' FROM '.$table.' WHERE '.$columnsearch.'="'.$requestsearch.'"');
   $res=$dbtemp->query('SELECT * FROM '.$table.' WHERE '.$columnsearch.'="'.$valuesearch.'"');
   //echo 'SELECT '.$columnanswer.' FROM '.$table.' WHERE '.$columnsearch.'="'.$requestsearch.'"';
   $array=array();
   while($data=$res->fetchArray())
   { $array[]=$data; }
   //foreach($array as $row)
   //{ echo $row[$columnanswer];}
   //echo $array;
   return $array;
  } else { echo "no db"; }
}
/*----------------------------------------------*/
/*вставка в таблицу*/
function inserttotable($db, $table, $columns, $values)
{
 if (dbexist($db))
 {
  $dbtemp=new SQLite3($db);
  $dbtemp->exec("INSERT INTO ".$table." (".$columns.") VALUES (".$values.")");
//  echo "INSERT INTO ".$table." (".$columns.") VALUES (".$values.")";
 }
}
/*----------------------------------------------*/
/*изменение таблицы*/
function updatetable($db, $table, $columnsearch, $valuesearch, $columnupdate, $valueupdate)
{
 if (dbexist($db))
 {
  $dbtemp=new SQLite3($db);
  $update=$dbtemp->query('UPDATE '.$table.' SET '.$columnupdate.'="'.$valueupdate.'" WHERE '.$columnsearch.'="'.$valuesearch.'"');
//   echo 'UPDATE '.$table.' SET '.$columnupdate.'="'.$valueupdate.'" WHERE '.$columnsearch.'="'.$valuesearch.'"';
 }
}
/*----------------------------------------------*/
/*удаление записи таблицы*/
function deletefromtable($db, $table, $columnsearch, $valuesearch)
{
 if (dbexist($db))
 {
  $dbtemp=new SQLite3($db);
  $delete=$dbtemp->query('DELETE FROM '.$table.' WHERE '.$columnsearch.'="'.$valuesearch.'"');
//   echo 'UPDATE '.$table.' SET '.$columnupdate.'="'.$valueupdate.'" WHERE '.$columnsearch.'="'.$valuesearch.'"';
//  echo 'DELETE FROM '.$table.' WHERE '.$columnsearch.'="'.$valuesearch.'"';
 }
}
/*----------------------------------------------*/
//тестовое наполнение таблицы
function inserttest($db)
{
 echo "INSERT";
 $dbtemp=new SQLite3($db);
 $dbtemp->exec("INSERT INTO checkip (ip, name, tel, email, alarm, active) VALUES ('127.0.0.2', 'Локальный хост 2', 0, 0, 0, 1)");
 $dbtemp->exec("INSERT INTO checkip (ip, name, tel, email, alarm, active) VALUES ('127.0.0.3', 'Локальный хост 3', 0, 0, 0, 1)");
 $dbtemp->exec("INSERT INTO checkip (ip, name, tel, email, alarm, active) VALUES ('127.0.0.4', 'Локальный хост 4', 0, 0, 0, 1)");
}
/*----------------------------------------------*/
function service_temperature($source, $limit, $title, $comment)
{
 /* датчик температуры--*/
 if ( file_exists("$source") )
 {
  $t2=file_get_contents("$source");
//  $t2=substr($temperature2, strpos($temperature2, "<T1>")+4, strpos($temperature2, "</T1>")-(strpos($temperature2, "<T1>")+4));
//  $t2_uptime=substr($temperature2, strpos($temperature2, "<T1-uptime>")+11, strpos($temperature2, "</T1-uptime>")-(strpos($temperature2, "<T1-uptime>")+11));
//  $t2_uptime_day=strtok($t2_uptime, ".");
//  $t2_uptime_hour=strtok(".");
  if ($t2 < $limit)
   {
    echo ("<div class='element'><div class='dat' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));' ");
   } else
   {
    echo ("<div class='element'><div class='dat' style='background:#d64760;' ");
   }
  echo (" data-title='$comment'>$t2&deg;C");
  echo ("</div><div class='text'>$title");
  echo ("</div><div class='note'>Обновлено в " . date("H:i"));
  echo ("</div></div>");
 }
}
/*---------------------*/
function service_motiontime($source, $title)
{
 /* Движение в СП2-------*/
 if ( file_exists("$source") )
 {
  $checkmotion=file_get_contents("$source");
  echo ("<div class='element'><div class='dat' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));'><font color=brown>$checkmotion</font>");
  echo ("</div><div class='text'>$title");
  echo ("</div><div class='note'>Обновлено в " . date("H:i"));
  echo ("</div></div>");
 }
}
/*----------------------*/
function service_motionactive($source, $title, $comment)
{
 /* датчик движения -----------*/
 if ( file_exists("$source") )
 {
  $motion=file_get_contents("$source");
  $M1=substr($motion, strpos($motion, "<M1>")+4, strpos($motion, "</M1>")-(strpos($motion, "<M1>")+4));
  $M1_1=strtok($M1, ".");
  $M1_2=strtok(".");
  $M1_uptime=substr($motion, strpos($motion, "<M1-uptime>")+11, strpos($motion, "</M1-uptime>")-(strpos($motion, "<M1-uptime>")+11));
  $M1_uptime_day=strtok($M1_uptime, ".");
  $M1_uptime_hour=strtok(".");
  if ($M1_1 < 1)
   {
    echo ("<div class='element'><div class='dat' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));' ");
    $M1="нет движения";
   } else
   {
    echo ("<div class='element'><div class='dat' style='background:#d64760;' ");
    $M1="Движение! #$M1_2";
   }
  echo (" data-title='$comment'>$M1");
  echo ("</div><div class='text'>$title");
  echo ("</div><div class='note'>Обновлено в " . date("H:i"));
  echo ("</div></div>");
 }
}
/*---------------------*/
function service_light($source, $title, $comment)
{
 /* датчик света -----------*/
 if ( file_exists("$source") )
 {
  $light=file_get_contents("$source");
  $L1=substr($light, strpos($light, "<L1>")+4, strpos($light, "</L1>")-(strpos($light, "<L1>")+4));
  $L1_uptime=substr($light, strpos($light, "<L1-uptime>")+11, strpos($light, "</L1-uptime>")-(strpos($light, "<L1-uptime>")+11));
  $L1_uptime_day=strtok($L1_uptime, ".");
  $L1_uptime_hour=strtok(".");
  $rbgcalc=intval(($L1/1023*100)*2.55);
  $rbgcalcinverse=255-intval(($L1/1023*100)*2.55);
  echo ("<div class='element'><div class='dat' style='background:rgb($rbgcalc,0,0);background:linear-gradient(to bottom, #FFFFFF, rgb($rbgcalc,0,0));' ");
  echo (" data-title='$comment'><font style='color:rgb($rbgcalcinverse,255,255);'>$L1</font>");
  echo ("</div><div class='text'>$title");
  echo ("</div><div class='note'>Обновлено в " . date("H:i"));
  echo ("</div></div>");
 }
}
/*---------------------*/
function service_foto($source, $title, $comment)
{
 /* фото с камеры -----------*/
 if ( file_exists("$source") )
 {  
  echo ("<div class='element'><div class='dat' style='background:rgb($rbgcalc,0,0);background:linear-gradient(to bottom, #FFFFFF, rgb($rbgcalc,0,0));' ");
  echo (" data-title='$comment'><font style='color:rgb($rbgcalcinverse,255,255);'>$L1</font>");
  echo ("</div><div class='text'>$title");
  echo ("</div><div class='note'>");
  echo ("</div></div>");
 }
}
/*---------------------*/
function service_light_button($device, $cmdon, $cmdoff)
{
 /* Включалка светодиодов на Arduino -----------*/
 $cmd=exec("ls $device");
 if ( $cmd == $device )
 {
  echo ("<div class='element'><div class='dat' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));' ");
  echo (" data-title=''><form action='' method='post'><input type='submit' name='ledon' value='Вкл' /><input type='submit' name='ledoff' value='Выкл' /></form>");
  echo ("</div><div class='text'>Включить свет");
  echo ("</div><div class='note'>");
  echo ("</div></div>");
  if(isset($_POST['ledon']))
   {
    $cmd="stty -F /dev/ttyS1 -echo -onlcr -iexten 9600; echo 'Ledon' > /dev/ttyS1";
    //$exe=escapeshellcmd($cmd);
    //echo $exe;
    exec($cmd);
   }
  if(isset($_POST['ledoff']))
   {
    $cmd="stty -F /dev/ttyS1 -echo -onlcr -iexten 9600; echo 'Ledoff' > /dev/ttyS1";
    //$exe=escapeshellcmd($cmd);
    //echo $exe;
    exec($cmd);
   }
 }
}
/*---------------------*/
function service_hddsize($disk, $limit, $title, $comment)
{
 /* Опрос свободного места на диске --------------*/
 if ( file_exists("$disk") )
  {
   $checkdisk=file_get_contents($disk);
   if ($checkdisk > $limit)
    {
     echo ("<div class='element'><div class='dat' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));'");
    } else
    {
     echo ("<div class='element'><div class='dat' style='background:#d64760;'");
    }
   echo (" data-title='$comment'>$checkdisk GB");
   echo ("</div><div class='text'>$title");
   echo ("</div><div class='note'>Обновлено в " . date("H:i"));
   echo ("</div></div>");
  }
}
/*---------------------*/
function service_trafic($speed, $limit, $title, $comment)
{
 /*Опрос траффика --*/
 if ( file_exists("$speed") )
  {
   $traf=file_get_contents($speed);
   if ($traf > $limit)
    {
     echo ("<div class='element'><div class='dat' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));'");
    } else
    {
     echo ("<div class='element'><div class='dat' style='background:#d64760;'");
    }
   echo (" data-title='$comment'>$traf Мбит/с");
   echo ("</div><div class='text'>$title");
   echo ("</div><div class='note'>Обновлено в " . date("H:i"));
   echo ("</div></div>");
  }
}
/*---------------------*/
/* Квота---------------
$checkquota=file_get_contents("/mnt/shared/result_clear.txt");
echo ("<div class='elementlist'><div class='datlist' style='background:rgb(160,203,169);background:linear-gradient(rgb(160,203,169), rgb(99,169,113));'");
echo (" data-title='Квота на сервере 10.51.0.203. Суммируются сетевые диски, документы, рабочий стол'><pro>$checkquota</pro>");
echo ("</div><div class='text'>Квота пользователей РО");
echo ("</div><div class='note'>Обновлено в " . date("H:i"));
echo ("</div></div>");
/*---------------------*/
