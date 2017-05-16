<?php
//darkcallia
//2017

//используемые массивы
$arraycheckip=array();//содержит таблицу "checkip" опрашиваемых сервисов по ip
//подключаем фунции
include "functions.php";
//файл БД
$dbfile="mysqlitedb.db";

//inserttotable($dbfile, "checkip", "ip, name, tel, email, alarm, active", "'127.0.0.5', 'Локальный хост 5', 0, 0, 0, 1");

//чтение массивов
//функция для сортировки многомерного массива по полю sort
function sortarray($a, $b)
{
 if ($a['ip']==$b['ip']) return 0;
 return $a['ip']>$b['ip'] ? 1 : -1;
}
//$f=file_get_contents("checkarray1.txt");
//функция чтения массивов
function readarrays()
{
 $GLOBALS["arraycheckip"]=fromtable($GLOBALS["dbfile"], "checkip", "active", "1");
// asort($GLOBALS["arraycheckip"]);
// array_multisort($GLOBALS["arraycheckip[ip]"], SORT_ASC, SORT_STRING);
// array_multisort($GLOBALS["arraycheckip"][][ip], SORT_ASC, SORT_STRING);
 usort($GLOBALS["arraycheckip"], 'sortarray');
// echo "TEST" . $GLOBALS["arraycheckip"][7][ip] . "<br>";
/*
 foreach($GLOBALS["arraycheckip"] as $key => $value)
 {
  echo "$key = $value[ip] <br />";
 }
*/
}
readarrays();
//$array1=unserialize($f);
//asort($array1);

$f=file_get_contents("checkarray2.txt");
$array2=unserialize($f);
$f=file_get_contents("checkarray3.txt");
$array3=unserialize($f);
$f=file_get_contents("checkarrayemail.txt");
$arrayemail=unserialize($f);
$f=file_get_contents("checkarrayphone.txt");
$arrayphone=unserialize($f);
$f=file_get_contents("checkarray1port.txt");
$array1port=unserialize($f);
asort($array1port);
$f=file_get_contents("checkarray2port.txt");
$array2port=unserialize($f);
$f=file_get_contents("checkarray3port.txt");
$array3port=unserialize($f);
$f=file_get_contents("checkarrayemailport.txt");
$arrayemailport=unserialize($f);
$f=file_get_contents("checkarrayphoneport.txt");
$arrayphoneport=unserialize($f);

//если пустой файл, то записываем в массив локалхост
/*if(filesize("checkarray1.txt") < 7)
 {
  $array1=array("127.0.0.1");
  $array2=array("без описания");
 }*/
if(filesize("checkarray1port.txt") < 7)
 {
  $array1port=array("127.0.0.1 80");
  $array2port=array("без описания");
 }

//добавление элемента
if(isset($_POST['insert-ip']))
 {
  //добавляем в таблицу БД
  inserttotable($dbfile, "checkip", "ip, name, tel, email, alarm, active", "'".trim($_POST['iptext'])."', '".trim($_POST['notetext'])."', 0, 0, 0, 1");
  readarrays();//обновляем массивы
/*
  //добавляем в массив
  array_push($array1, trim($_POST['iptext']));
  array_push($array2, trim($_POST['notetext']));
  //сохраняем в файл массив
  $string_to_file = serialize($array1);
  $f = fopen("checkarray1.txt", 'w');
  fwrite($f, $string_to_file);
  fclose($f);
  $string_to_file = serialize($array2);
  $f = fopen("checkarray2.txt", 'w');
  fwrite($f, $string_to_file);
  fclose($f);
*/
  //вывод введенного
  echo "<b>Добавлено " . trim($_POST['iptext']) . "</b><br>";
 }
if(isset($_POST['port']))
 {
  //добавляем в массив
  array_push($array1port, trim($_POST['porttext']));
  array_push($array2port, trim($_POST['portnotetext']));
  //сохраняем в файл массив
  $string_to_file = serialize($array1port);
  $f = fopen("checkarray1port.txt", 'w');
  fwrite($f, $string_to_file);
  fclose($f);
  $string_to_file = serialize($array2port);
  $f = fopen("checkarray2port.txt", 'w');
  fwrite($f, $string_to_file);
  fclose($f);
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
//   echo "Q" . !$arraytemp[0][email] . "Q";
   updatetable($dbfile, "checkip", "id", "$email", "email", !$arraytemp[0][email]);
  }
  readarrays();//обновляем массивы
 }
}
/*
if(isset($_POST['email']))
 {
  $a = $_POST['checks'];
  if(empty($a))
  {
    echo("Вы ничего не выбрали.");
  } else
  {
   echo("Вы изменили состояние email у следующих элементов: ");
   foreach ($a as $email)
    {
     echo($email . " ");
     if (filesize("checkarrayemail.txt") < 7)//если элемент первый
      {
       $arrayemail=array($email);
      } else//если не первый
      {
       if (!in_array($email,$arrayemail))//если не было элемента то добавляем
        {
         array_push($arrayemail, $email);
        } else//если был, то удаляем
        {
         foreach ($arrayemail as $key=>$k)//перебираем в массиве arrayemail ключи от array1 и находим удаляемый и его соотв.ключ в массиве arrayemail
          {
           if ($arrayemail[$key] == $email)
            {
             unset($arrayemail[$key]);
            }
          }
        }
      }
     //сохраняем в файл изменения
     $string_to_file = serialize($arrayemail);
     $f = fopen("checkarrayemail.txt", 'w');
     fwrite($f, $string_to_file);
     fclose($f);
    }
  }
 }
*/
//добавление или удаление опроса по email для Port
if(isset($_POST['emailport']))
 {
  $a = $_POST['portchecks'];
  if(empty($a))
  {
    echo("Вы ничего не выбрали.");
  } else
  {
   echo("Вы изменили состояние email у следующих элементов: ");
   foreach ($a as $emailport)
    {
     echo($emailport . " ");
     if (filesize("checkarrayemailport.txt") < 7)//если элемент первый
      {
       $arrayemailport=array($emailport);
      } else//если не первый
      {
       if (!in_array($emailport,$arrayemailport))//если не было элемента то добавляем
        {
         array_push($arrayemailport, $emailport);
        } else//если был, то удаляем
        {
         foreach ($arrayemailport as $key=>$k)//перебираем в массиве arrayemailport ключи от array1port и находим удаляемый и его соотв.ключ в массиве arrayemailport
          {
           if ($arrayemailport[$key] == $emailport)
            {
             unset($arrayemailport[$key]);
            }
          }
        }
      }
     //сохраняем в файл изменения
     $string_to_file = serialize($arrayemailport);
     $f = fopen("checkarrayemailport.txt", 'w');
     fwrite($f, $string_to_file);
     fclose($f);
    }
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
/*
//добавление или удаление опроса по phone для IP
if(isset($_POST['phone']))
 {
  $a = $_POST['checks'];
  if(empty($a))
  {
    echo("Вы ничего не выбрали.");
  } else
  {
   echo("Вы изменили состояние phone у следующих элементов: ");
   foreach ($a as $phone)
    {
     echo($phone . " ");
     if (filesize("checkarrayphone.txt") < 7)//если элемент первый
      {
       $arrayphone=array($phone);
      } else//если не первый
      {
       if (!in_array($phone,$arrayphone))//если не было элемента то добавляем
        {
         array_push($arrayphone, $phone);
        } else//если был, то удаляем
        {
         foreach ($arrayphone as $key=>$k)//перебираем в массиве arrayphone ключи от array1 и находим удаляемый и его соотв.ключ в массиве arr$
          {
           if ($arrayphone[$key] == $phone)
            {
             unset($arrayphone[$key]);
            }
          }
        }
      }
     //сохраняем в файл изменения
     $string_to_file = serialize($arrayphone);
     $f = fopen("checkarrayphone.txt", 'w');
     fwrite($f, $string_to_file);
     fclose($f);
    }
  }
 }
*/
//добавление или удаление опроса по phone для Port
if(isset($_POST['phoneport']))
 {
  $a = $_POST['portchecks'];
  if(empty($a))
  {
    echo("Вы ничего не выбрали.");
  } else
  {
   echo("Вы изменили состояние phone у следующих элементов: ");
   foreach ($a as $phoneport)
    {
     echo($phoneport . " ");
     if (filesize("checkarrayphoneport.txt") < 7)//если элемент первый
      {
       $arrayphoneport=array($phoneport);
      } else//если не первый
      {
       if (!in_array($phoneport,$arrayphoneport))//если не было элемента то добавляем
        {
         array_push($arrayphoneport, $phoneport);
        } else//если был, то удаляем
        {
         foreach ($arrayphoneport as $key=>$k)//перебираем в массиве arrayphoneport ключи от array1port и находим удаляемый и его соотв.ключ в$
          {
           if ($arrayphoneport[$key] == $phoneport)
            {
             unset($arrayphoneport[$key]);
            }
          }
        }
      }
     //сохраняем в файл изменения
     $string_to_file = serialize($arrayphoneport);
     $f = fopen("checkarrayphoneport.txt", 'w');
     fwrite($f, $string_to_file);
     fclose($f);
    }
  }
 }

//удаление элементов
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
//удаление элементов
if(isset($_POST['del']))
 {
  $a = $_POST['checks'];
  if(empty($a))
  {
    echo("Вы ничего не выбрали.");
  }
  else
  {
    echo("Вы удалили элементы: ");
    foreach ($a as $valdel)
     {
      echo($valdel . " ");
      //удаление элемента массива
      unset($array1[$valdel]);
      unset($array2[$valdel]);
      //массив для хранения недоступных узлов тоже чистим от удаляемого элемента
      foreach ($array3 as $keya3=>$a3)
       {
        if ($array3[$keya3] == $valdel)
         {
          unset($array3[$keya3]);
          $string_to_file = serialize($array3);
          $f = fopen("checkarray3.txt", 'w');
          fwrite($f, $string_to_file);
          fclose($f);
         }
       }
      //массив для хранения email узлов тоже чистим от удаляемого элемента
      foreach ($arrayemail as $keya3=>$a3)
       {
        if ($arrayemail[$keya3] == $valdel)
         {
          unset($arrayemail[$keya3]);
          $string_to_file = serialize($arrayemail);
          $f = fopen("checkarrayemail.txt", 'w');
          fwrite($f, $string_to_file);
          fclose($f);
         }
       }
      //массив для хранения phone узлов тоже чистим от удаляемого элемента
      foreach ($arrayphone as $keya3=>$a3)
       {
        if ($arrayphone[$keya3] == $valdel)
         {
          unset($arrayphone[$keya3]);
          $string_to_file = serialize($arrayphone);
          $f = fopen("checkarrayphone.txt", 'w');
          fwrite($f, $string_to_file);
          fclose($f);
         }
       }
      //сохраняем в файл массив
      $string_to_file = serialize($array1);
      $f = fopen("checkarray1.txt", 'w');
      fwrite($f, $string_to_file);
      fclose($f);
      $string_to_file = serialize($array2);
      $f = fopen("checkarray2.txt", 'w');
      fwrite($f, $string_to_file);
      fclose($f);
     }
  }
 }
if(isset($_POST['portdel']))
 {
  $a = $_POST['portchecks'];
  if(empty($a))
  {
    echo("Вы ничего не выбрали.");
  }
  else
  {
    echo("Вы удалили элементы: ");
    foreach ($a as $valdel)
     {
      echo($valdel . " ");
      //удаление элемента массива
      unset($array1port[$valdel]);
      unset($array2port[$valdel]);
      //массив для хранения недоступных узлов тоже чистим от удаляемого элемента
      foreach ($array3port as $keya3=>$a3)
       {
        if ($array3port[$keya3] == $valdel)
         {
          unset($array3port[$keya3]);
          $string_to_file = serialize($array3port);
          $f = fopen("checkarray3port.txt", 'w');
          fwrite($f, $string_to_file);
          fclose($f);
         }
       }
      //массив для хранения email опрашиваемых узлов тоже чистим от удаляемого элемента
      foreach ($arrayemailport as $keya3=>$a3)
       {
        if ($arrayemailport[$keya3] == $valdel)
         {
          unset($arrayemailport[$keya3]);
          $string_to_file = serialize($arrayemailport);
          $f = fopen("checkarrayemailport.txt", 'w');
          fwrite($f, $string_to_file);
          fclose($f);
         }
       }
      //массив для хранения phone опрашиваемых узлов тоже чистим от удаляемого элемента
      foreach ($arrayphoneport as $keya3=>$a3)
       {
        if ($arrayphoneport[$keya3] == $valdel)
         {
          unset($arrayphoneport[$keya3]);
          $string_to_file = serialize($arrayphoneport);
          $f = fopen("checkarrayphoneport.txt", 'w');
          fwrite($f, $string_to_file);
          fclose($f);
         }
       }
      //сохраняем в файл массив
      $string_to_file = serialize($array1port);
      $f = fopen("checkarray1port.txt", 'w');
      fwrite($f, $string_to_file);
      fclose($f);
      $string_to_file = serialize($array2port);
      $f = fopen("checkarray2port.txt", 'w');
      fwrite($f, $string_to_file);
      fclose($f);
     }
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
service_temperature();
service_motiontime();
service_motionactive();
service_light();
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
   <input type="submit" name="port" value="Добавить" />
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
 echo "<tr>$tags<input type='checkbox' name='checks[]' value='$row[id]' />$row[ip] $row[name] $email $phone";
}
/*
foreach ($array1 as $key=>$val) {
 if (in_array($key,$arrayemail))
  {
   $email="$tags<img src=\"img/email.png\" width=\"12\" height=\"8\">";
  } else
  {
   $email="$tags<img src=\"img/noemail.png\" width=\"12\" height=\"8\">";
  }
 if (in_array($key,$arrayphone))
  {
   $phone="$tags<img src=\"img/phone.png\" width=\"8\" height=\"12\">";
  } else
  {
   $phone="$tags<img src=\"img/nophone.png\" width=\"8\" height=\"12\">";
  }
 if (in_array($key,$array3))
  {
   echo "<tr>$tagsred<input type='checkbox' name='checks[]' value='$key' /><b>$val $array2[$key] НЕДОСТУПЕН</b><br /> $email $phone";
  } else
  {
   echo "<tr>$tags<input type='checkbox' name='checks[]' value='$key' />$val $array2[$key] $email $phone";
  }
}
*/
echo "<tr><td align=center style=\"border-top-style:dashed; border-top-width:1; border-top-color:gray; font-family:Tahoma; font-weight:normal; font-size:12\"><input type='submit' name='edit-ip-email' value='Email' /><input type='submit' name='edit-ip-tel' value='SMS' /><input type='submit' name='del-ip' value='Удалить' /></form>";
?>
</table>

  <td align=center style="vertical-align:top;">Проверка сервисов по портам
<?php
echo "<table width=* height=* style=\"border-style:dashed; border-width:1; border-color:blue;\">";
echo "<form action='' method='post'>";
foreach ($array1port as $key=>$val) {
 if (in_array($key,$arrayemailport))
  {
   $email="$tags<img src=\"img/email.png\" width=\"12\" height=\"8\">";
  } else
  {
   $email="$tags<img src=\"img/noemail.png\" width=\"12\" height=\"8\">";
  }
 if (in_array($key,$arrayphoneport))
  {
   $phone="$tags<img src=\"img/phone.png\" width=\"8\" height=\"12\">";
  } else
  {
   $phone="$tags<img src=\"img/nophone.png\" width=\"8\" height=\"12\">";
  }
 if (in_array($key,$array3port))
  {
   echo "<tr>$tagsred<input type='checkbox' name='portchecks[]' value='$key' /><b>$val $array2port[$key] НЕДОСТУПЕН</b><br /> $email $phone";
  } else
  {
   echo "<tr>$tags<input type='checkbox' name='portchecks[]' value='$key' />$val $array2port[$key] $email $phone";
  }
}
echo "<tr><td align=center style=\"border-top-style:dashed; border-top-width:1; border-top-color:gray; font-family:Tahoma; font-weight:normal; font-size:12\"><input type='submit' name='emailport' value='Email' /><input type='submit' name='phoneport' value='Sms' /><input type='submit' name='portdel' value='Удалить' /></form>";
//inserttest("mysqlitedb.db");
//fromtable("mysqlitedb.db", "checkip", "ip", "127.0.0.3", "ip");
//fromtable("mysqlitedb.db", "checkip", "active", "1", "ip");
?>
</table>

</table>

</body>
</html>
