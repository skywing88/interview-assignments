#切换到目录"F:\PowerShell"
cd F:\powershell


#定义一个变量用于显示基于小时的时间窗口
$i=0

 #定义月份英语缩写至数字的HashTable
 $months=@{Jan=1;Feb=2;Mar=3;Apr=4;May=5;Jun=6;Jul=7;Aug=8;Sept=9;ct=10;Nov=11;Dec=12}


#定义基于小时的时间窗口变量,ex"第0时至1时"
$timeWindow="第"+$i+"时"+"至"+($i+1)+"时"

#定义日志处理的起始时间
$starttime=get-date -Month 5 -Day 13 00:00:00

#在起始时间的基础上加上1个小时，即当天的1点整
$endtime=$starttime.AddHours(1)

#定义匹配每条日志记录开头的UTC格式的时间信息的正则表达式,ex"May 13 00:01:58"
$pattern1="[a-zA-Z]{3}.[0-9]{2}.([0-9]{2}:){2}[0-9]{2}"

<#
定义匹配日志条目中包含在"()"中的进程名称的正则表达式,
ex"(com.apple.mdworker.bundles[12513])"中的"com.apple.mdworker.bundles"
#>
$pattern2="([a-zA-Z]{3,}\.){2,}[a-zA-Z]{3,}"

<#定义匹配日志条目中包含在"()"中的由5位数字组成的进程ID,
ex"(com.apple.mdworker.bundles[12513])"中的"12513"
#>
$pattern3="[0-9]{5}"

<#
将原始日志文件"interview_data_set"中的包含有关键字"error"日志条目检索出来,
将结果保存在变量"errlog"中
#>
$errlog=gc .\interview_data_set | Select-String "error" 

#将"|"定义为一个定界符号，存入变量"delimiter"中
$delimiter="|"

#这个foreach循环的功能是将每一条日志记录最开头的UTC时间信息替换为小时级别的时间窗口
foreach($line in $errlog)
{
 #先去匹配正则表达式
 #$line -match $pattern1
  
 #将匹配到的UTC时间信息赋值给变量"utc_date", ex:"May 13 00:01:58"
  $utc_date=([regex]"$pattern1").matches($line) | % { $_.value }



 <#
 以空格为分隔符去分割变量"utc_date"所含的字符串，获取月份英文缩写，并转换
 为数值，存入变量"month"中
 #>
 $month=$months[$utc_date.Split(" ")[0]]

 #获取day信息，并存入变量"day"中
 $day=$utc_date.Split(" ")[1]

 #获取时/分/秒信息，并存入变量"time"中
 $time=$utc_date.Split(" ")[2]

 $current_time=get-date -Month $month -day $day $time

 <#
   将当前时间与整点时间做比较，如果超过整点时间时，则"timeWindow"变量需要重新赋值
   而整点时间变量"endtime"需要往后调整一个小时
 #>
 
 if((New-TimeSpan -Start $current_time -End $endtime).totalseconds -lt 0)
 { 
   $i+=1
   $timeWindow="第"+$i+"时"+"至"+($i+1)+"时"
   $endtime=$endtime.AddHours(1)
  }

<#
将原始日志中的含有error关键字的日志条目过滤出来，将日志最开头的UTC时间信息替换为小时级别的时间窗口，
然后在一条一条记录存入变量 errorlog2中，每存一条记录时在该条记录的末尾处需要加上分割符合"#",便于之后
将整个字符串"errorlog2"分割拆分成数组
#>
  $errorlog2+=($line -replace ($utc_date,$timeWindow))+"#"
}


 

<#去掉errorlog2变量所存储的字符串内容的末尾和首部的"#",
再将变量"errorlog2"中存放的字符串以"#"号分割为数组，并存入数组变量"errorlog2_charry"中
#>
$errorlog2_charry=($errorlog2.trim("#")).Split("#")



foreach($each_raw_line in $errorlog2_charry)
{
  if($each_raw_line -eq "")
  {
     break
   }
  $chararray=$each_raw_line -split  {$_ -eq "(" -or $_ -eq ")"}
  
  if(($chararray.Count -le 2 -and $chararray.Count -gt 0) -or $chararray[1] -eq "")
   
  {
   #Write-Host $chararray.Count$each_raw_line
   $chararray=$each_raw_line -split  {$_ -eq "[" -or $_ -eq "]"}, 3
   $subChararray=$chararray[0] -split " ",3
   #$timeWindow=($chararray[0] -split " ")[0]
   $timeWindow=$subChararray[0]
   #$deviceName=($chararray[0] -split " ")[1]
   $deviceName=$subChararray[1]
   $processName=$subChararray[2]
  <#
     for($i=2;$i -lt ($chararray[0] -split " ").Length;$i++)
       {
          if($i -eq (($chararray[0] -split " ").Length-1))
            {
              $processName+=($chararray[0] -split " ")[$i]
             }
          else
           {
              $processName+=($chararray[0] -split " ")[$i]+" "
            }
          }
    #>
    $processID=$chararray[1]
    $description=$chararray[2] -replace “^: ”
    $description=$description -replace "`n|`r"
    Add-Content -Path F:\powershell\result_1.txt -Value $timeWindow"|"$deviceName"|"$processName"|"$processID"|"$description
    }
    else
     {  
        #$chararray[1]
        $timeWindow=($chararray[0] -split " ")[0]
        $deviceName=($chararray[0] -split " ")[1]
        $processName=([regex]"([a-zA-Z]{3,}\.){2,}[a-zA-Z]{3,}").matches($chararray[1]) | % { $_.value }
        $processID=([regex]"[0-9]{5}").matches($chararray[1]) | % { $_.value }
        #$chararray[1] -match $pattern1
        #$processName=$Matches[0]
        #$chararray[1] -match $pattern2
        #$processID=$Matches[0]
        $description=$chararray[2] -replace “^: ”
        $description=$description -replace "`n|`r"
       Add-Content -Path F:\powershell\result_1.txt -Value $timeWindow"|"$deviceName"|"$processName"|"$processID"|"$description
       }
 }

$counts=@{}

gc .\result_1.txt | Foreach-Object {$_ -replace "\|[0-9]{3,}",""} | sort | foreach { $counts[$_]++ }

gc .\result_1.txt | Foreach-Object {$_ -replace "\|[0-9]{3,}",""} | sort | Get-Unique > .\result_tmp_1.txt

<#创建一个StreamReader对象,该对象操作的原始文本文件为"F:\powershell\result_tmp_1.txt"文件，
进行逐行读取操作
#>
$newstreamreader = New-Object System.IO.StreamReader("F:\powershell\result_tmp_1.txt")
while (($readeachline =$newstreamreader.ReadLine()) -ne $null)
{
    $numberOfOccurrence= $counts[$readeachline]
    $timeWindow=$readeachline.Split("|")[0]
    $deviceName=$readeachline.Split("|")[1]
    $processName=$readeachline.Split("|")[2]
    $description=$readeachline.Split("|")[3]
    $eachline_json=@{}
    $eachline_json.numberOfOccurrence="$numberOfOccurrence"
    $eachline_json.timeWindow="$timeWindow"
	$eachline_json.deviceName="$deviceName"
    $eachline_json.processName="$processName"
    $eachline_json.description="$description"
    $json_of_eachline=$eachline_json | ConvertTo-Json
    $json_of_eachline >> .\result_final.txt
}
$newstreamreader.Dispose()
#$rr=gc .\result_1.txt | Foreach-Object {$_ -replace "\|[0-9]{3,}",""}| Group-Object | Sort-Object -Property Count -Descending | Select-Object Count,group

del variable:errlog
del variable:errorlog2
del .\result_tmp_1.txt
del .\result_1.txt










