<?php
//darkcallia
//2017

//используемые массивы ОПРЕДЕЛЕНЫ В functions.php
//$arraycheckip=array();//содержит таблицу "checkip" опрашиваемых сервисов по ip
//$arraycheckport=array();//содержит таблицу "checkport" опрашиваемых сервисов по порту
//файл БД ОПРЕДЕЛЕН В functions.php
//подключаем фунции
include "functions.php";
//чтение массивов
if(!file_exists($dbfile))
{ createdb($dbfile); }
//функция для сортировки многомерного массива по полю ip
function sortarrayip($a, $b)
{
 if ($a['ip']==$b['ip']) return 0;
 return $a['ip']>$b['ip'] ? 1 : -1;
}
//функция для сортировки многомерного массива по полю port
function sortarrayport($a, $b)
{
 if ($a['port']==$b['port']) return 0;
 return $a['port']>$b['port'] ? 1 : -1;
}
//функция чтения массивов
function readarrays()
{
 $GLOBALS["arraycheckip"]=fromtable($GLOBALS["dbfile"], "checkip", "active", "1");
 usort($GLOBALS["arraycheckip"], 'sortarrayip');
 $GLOBALS["arraycheckport"]=fromtable($GLOBALS["dbfile"], "checkport", "active", "1");
 usort($GLOBALS["arraycheckport"], 'sortarrayport');
}
readarrays();
//добавление элемента проверки по ip
if(isset($_POST['insert-ip']))
{
 //добавляем в таблицу БД
 inserttotable($dbfile, "checkip", "ip, name, tel, email, alarm, active", "'".trim($_POST['iptext'])."', '".trim($_POST['notetext'])."', 0, 0, 0, 1");
 readarrays();//обновляем массивы
 //вывод введенного
 echo "<b>Добавлено " . trim($_POST['iptext']) . "</b><br>";
}
//добавление элемента проверки по порту
if(isset($_POST['insert-port']))
{
 //добавляем в таблицу БД
 inserttotable($dbfile, "checkport", "port, name, tel, email, alarm, active", "'".trim($_POST['porttext'])."', '".trim($_POST['portnotetext'])."', 0, 0, 0, 1");
 readarrays();//обновляем массивы
 //вывод введенного
 echo "<b>Добавлено " . trim($_POST['porttext']) . "</b><br>";
}
//добавление или удаление опроса по email для IP
if(isset($_POST['edit-ip-email']))
{
 $a=$_POST['checks'];
 if(empty($a))
 { echo("Вы ничего не выбрали."); } else
 {
  echo("Вы изменили состояние email у следующих элементов: ");
  foreach ($a as $email)
  {
   echo($email . " ");
   //ищем текущее значение и меняем его
   $arraytemp=fromtable($dbfile, "checkip", "id", "$email");
   updatetable($dbfile, "checkip", "id", "$email", "email", !$arraytemp[0][email]);
  }
  readarrays();//обновляем массивы
 }
}
//добавление или удаление опроса по email для портов
if(isset($_POST['edit-port-email']))
{
 $a=$_POST['portchecks'];
 if(empty($a))
 { echo("Вы ничего не выбрали."); } else
 {
  echo("Вы изменили состояние email у следующих элементов: ");
  foreach ($a as $emailport)
  {
   echo($emailport . " ");
   //ищем текущее значение и меняем его
   $arraytemp=fromtable($dbfile, "checkport", "id", "$emailport");
   updatetable($dbfile, "checkport", "id", "$emailport", "email", !$arraytemp[0][emailport]);
  }
  readarrays();//обновляем массивы
 }
}
//добавление или удаление опроса по tel для IP
if(isset($_POST['edit-ip-tel']))
{
 $a=$_POST['checks'];
 if(empty($a))
 { echo("Вы ничего не выбрали."); } else
 {
  echo("Вы изменили состояние tel у следующих элементов: ");
  foreach ($a as $tel)
  {
   echo($tel . " ");
   //ищем текущее значение и меняем его
   $arraytemp=fromtable($dbfile, "checkip", "id", "$tel");
   updatetable($dbfile, "checkip", "id", "$tel", "tel", !$arraytemp[0][tel]);
  }
  readarrays();//обновляем массивы
 }
}
//добавление или удаление опроса по tel для портов
if(isset($_POST['edit-port-tel']))
{
 $a=$_POST['portchecks'];
 if(empty($a))
 { echo("Вы ничего не выбрали."); } else
 {
  echo("Вы изменили состояние tel у следующих элементов: ");
  foreach ($a as $telport)
  {
   echo($telport . " ");
   //ищем текущее значение и меняем его
   $arraytemp=fromtable($dbfile, "checkport", "id", "$telport");
   updatetable($dbfile, "checkport", "id", "$telport", "telport", !$arraytemp[0][telport]);
  }
  readarrays();//обновляем массивы
 }
}
//удаление элементов проверки по ip
if(isset($_POST['del-ip']))
{
 $a=$_POST['checks'];
 if(empty($a))
 { echo("Вы ничего не выбрали."); } else
 {
  echo("Вы удалили элементы: ");
  foreach ($a as $valdel)
  {
   echo($valdel . " ");
   deletefromtable($dbfile, "checkip", "id", $valdel);
  }
  readarrays();//обновляем массивы
 }
}
//удаление элементов проверки по портам
if(isset($_POST['del-port']))
{
 $a=$_POST['portchecks'];
 if(empty($a))
 { echo("Вы ничего не выбрали."); } else
 {
  echo("Вы удалили элементы: ");
  foreach ($a as $valdel)
  {
   echo($valdel . " ");
   deletefromtable($dbfile, "checkport", "id", $valdel);
  }
  readarrays();//обновляем массивы
 }
}
?>

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="shortcut icon" type="image/vnd.microsoft.icon" href="favicon.ico">
<link rel="icon" type="image/vnd.microsoft.icon" href="favicon.ico">
<meta HTTP-EQUIV="refresh" content="300" />
<link rel="stylesheet" href="check.css" />
</head>
<body style="background:#CFE8D8">

<table border=0 width=800 height=* align=center>
 <tr>
    <td align=center colspan="2">
<!--  <img src="fss.gif"><br /><br /> -->
<?php
/* заголовок ----------*/
echo ("<div class='block'>");
/*----------------------------------------------*/
/* перечисляем функции опроса датчиков, сервисов*/
service_temperature("data/temperaturet2.txt", 21, "Температура СП РО", "Датчик температуры в СП РО.");
service_motiontime("data/checkmotion_clear.txt", "Посещение СП РО");
service_motionactive("http://10.51.0.251/", "Движение СП РО", "Датчик Движения. Цифра от #1 до #600 означает длительность нахождения. Работает уже $M1_uptime_day дн. и $M1_uptime_hour час.");
service_light("http://10.51.0.251/", "Освещение СП РО", "Датчик освещенности. Диапазон от 0 до 1023. Свет включен в районе 800, выключен около 200. работает уже $L1_uptime_day дн. и $L1_uptime_hour час.");
service_hddsize("data/ro-0.35-disk1.txt", 30, "Диск H БД РО", "База данных РО. Место на диске H (папка с базой)");
service_hddsize("data/ro-0.35-disk2.txt", 30, "Диск M БД РО", "База данных РО. Место на диске M (архивы баз)");
service_hddsize("data/f1-1.35-disk1.txt", 30, "Диск C БД Ф1", "База данных Филиала 1. Место на диске C (папка с базой и архивы)");
service_hddsize("data/audio-0.140-disk.txt", 10, "Записи с АТС РО", "Сервер с записями телефонных разговоров и горячей линии. Место на диске E.");
service_hddsize("data/f1-1.205-disk1.txt", 2, "Записи с АТС Ф1", "Сервер с записями телефонных разговоров и горячей линии. Место на диске D.");
service_hddsize("data/ro-0.209-disk1.txt", 200, "Основной диск", "Дисковый массив Iomega 10.51.0.209. Хранятся все архивы РО и БД Филиалов. Основной диск.");
service_hddsize("data/ro-0.209-disk2.txt", 100, "Диск старых архивов", "Дисковый массив Iomega 10.51.0.209. Хранятся все архивы РО и БД Филиалов. Диск старых архивов.");
service_hddsize("data/ro-0.203-disk1.txt", 7, "Файловый РО. Первый диск", "Файловый сервер РО 10.51.0.203. Сетевые диски ЛВС РО. Первый диск.");
service_hddsize("data/ro-0.203-disk2.txt", 7, "Файловый РО. Второй диск", "Файловый сервер РО 10.51.0.203. Сетевые диски ЛВС РО. Второй диск.");
service_trafic("data/ro-to-f1-traf.txt", 20, "Траффик РО -> Ф1", "Траффик от РО до Ф1.");
service_trafic("data/f1-to-ro-traf.txt", 20, "Траффик Ф1 -> РО", "Траффик от Ф1 до РО.");
service_light_button("/dev/ttyS1", "Ledon", "Ledoff");
service_foto("http://192.168.1.111/picture.jpg", "Фото с камеры", "<img src='192.168.1.111/picture.jpg'></img>");
/*----------------------------------------------*/
/* конец блоков--------*/
echo ("</div>");
/*---------------------*/

?>
 <tr>
  <td align=center colspan="2"><br>
 <tr>
  <td align=center style="vertical-align:top;">
   <form action="" method="post">
   <input type="text" name="iptext" />
   <input type="text" name="notetext" />
   <input type="submit" name="insert-ip" value="Добавить" />
   </form>

  <td align=center style="vertical-align:top;">
   <form action="" method="post">
   <input type="text" name="porttext" />
   <input type="text" name="portnotetext" />
   <input type="submit" name="insert-port" value="Добавить" />
   </form>

 <tr>
  <td align=center style="vertical-align:top;">Проверка серверов по IP
<?php
 $tagsred="<td onmouseover=\"this.style.background='#ABCDEF'; this.style.cursor='hand'; this.style.color='#626068'\" onmouseout=\"this.style.background='#FF0000'; this.style.color='#000000'\" align=left style=\"border-top-style:dashed; border-top-width:1; border-top-color:gray; font-family:Tahoma; font-weight:normal; font-size:12; background:red;\">";
 $tags="<td onmouseover=\"this.style.background='#ABCDEF'; this.style.cursor='hand'; this.style.color='#626068'\" onmouseout=\"this.style.background='#CFE8D8'; this.style.color='#000000'\" align=left style=\"vertical-align:middle;border-top-style:dashed; border-top-width:1; border-top-color:gray; font-family:Tahoma; font-weight:normal; font-size:12;\">";
?>

<?php
echo "<table width=* height=* style=\"border-style:dashed; border-width:1; border-color:blue; vertical-align:middle;\">";
echo "<form action='' method='post'>";
foreach ($arraycheckip as $row)//массив таблицы с сервисами для проверки доступа по ip
{
 if($row[email]) {//значек email
  $email="$tags<img src=\"img/email.png\" width=\"12\" height=\"8\">"; } else {
  $email="$tags<img src=\"img/noemail.png\" width=\"12\" height=\"8\">"; }
 if($row[tel]) {//значек tel
  $phone="$tags<img src=\"img/phone.png\" width=\"8\" height=\"12\">"; } else {
  $phone="$tags<img src=\"img/nophone.png\" width=\"8\" height=\"12\">"; }
 if($row[alarm]) {//предупреждение о недоступности
  echo "<tr>$tagsred<input type='checkbox' name='checks[]' value='$row[id]' /><b>$row[ip] $row[name] $email $phone НЕДОСТУПЕН</b>"; } else {
  echo "<tr>$tags<input type='checkbox' name='checks[]' value='$row[id]' />$row[ip] $row[name] $email $phone"; } 
}
echo "<tr><td align=center style=\"border-top-style:dashed; border-top-width:1; border-top-color:gray; font-family:Tahoma; font-weight:normal; font-size:12\"><input type='submit' name='edit-ip-email' value='Email' /><input type='submit' name='edit-ip-tel' value='SMS' /><input type='submit' name='del-ip' value='Удалить' /></form>";
?>
</table>

  <td align=center style="vertical-align:top;">Проверка сервисов по портам
<?php
echo "<table width=* height=* style=\"border-style:dashed; border-width:1; border-color:blue;\">";
echo "<form action='' method='post'>";
foreach ($arraycheckport as $row)//массив таблицы с сервисами для проверки доступа по портам
{
 if($row[email]) {//значек email
  $email="$tags<img src=\"img/email.png\" width=\"12\" height=\"8\">"; } else {
  $email="$tags<img src=\"img/noemail.png\" width=\"12\" height=\"8\">"; }
 if($row[tel]) {//значек tel
  $phone="$tags<img src=\"img/phone.png\" width=\"8\" height=\"12\">"; } else {
  $phone="$tags<img src=\"img/nophone.png\" width=\"8\" height=\"12\">"; } 
 if($row[alarm]) {//предупреждение о недоступности
  echo "<tr>$tagsred<input type='checkbox' name='portchecks[]' value='$row[id]' /><b>$row[port] $row[name] $email $phone НЕДОСТУПЕН</b>"; } else {
  echo "<tr>$tags<input type='checkbox' name='portchecks[]' value='$row[id]' />$row[port] $row[name] $email $phone $row[alarm]"; }
}
echo "<tr><td align=center style=\"border-top-style:dashed; border-top-width:1; border-top-color:gray; font-family:Tahoma; font-weight:normal; font-size:12\"><input type='submit' name='edit-port-email' value='Email' /><input type='submit' name='edit-port-tel' value='SMS' /><input type='submit' name='del-port' value='Удалить' /></form>";
?>
</table>

</table>

</body>
</html>
