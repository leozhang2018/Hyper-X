#!/bin/bash
#iptable-更新(中国区 IP 段)
# 注意: if [ "" ] 前后有空格
# 从shell脚本调用另一个shell脚本 http://stackoverflow.com/questions/8352851/how-to-call-shell-script-from-another-shell-script
# 首先是其他脚本成为可执行文件， 则添加 #!/bin/bash 在文件的路径在顶部， 并且为$PAth环境变量。 然后可以调用其作为一个普通的命令。
# Call其与 source 命令( 别名是 . ) 像这样 source /path/to/script .
# 使用 bash 命令来执行它。 /bin/bash /path/to/script

#载入配置文件
source ./config.conf

#获取 iptable 函数 CurlIptable
CurlIptable(){
	## 指定作用域分隔符为 '|',同时计算子网掩码位数之后进行拼接(http://www.cnblogs.com/ggjucheng/archive/2013/01/13/2858470.html)
	curl $Delegated_apnic_latest_URL | grep 'apnic|CN|ipv4' | awk -F '|' '/CN/&&/ipv4/ {print "iptables -t nat -I SHADOWSOCKS -d " $4 "/" 32-log($5)/log(2)  " -j RETURN" }'|cat > $save_to_file
}

##检查 Crontab 函数 CrontabCheck
CheckCrontab(){
	testing=`crontab -l | grep Update-iptables.sh`  	#检测 crontab 是否存在 Update-iptables.sh
	if [ "$testing" != "" ]; then
					exit
	else
			echo "$testing"
			echo "检测尚未写入 Crontab,是否写入以进行定时自动更新?(yes or no)"
			read input
			file_location=$(pwd)/Update-iptables.sh
				if [ "$input" == "yes" -o "$input" == "Yes" ]; then
				#每个月总有那么一次
				echo '* * 1 * * sh' $file_location >> /var/spool/cron/crontabs/root
				echo -e "写入 Crontab 完毕 时间设置 0,45 5-23 * * * sh"
				else
						exit 0
				fi
	fi
}

#更新 iptable 函数 UpdateList
UpdateList(){
		if test -s $save_to_file ;then
			echo '文件已经存在是否进行更新? (yes or no)'
			read input
			## -o 或运算 -a 与运算
		     	 if [ "$input" == "yes" -o "$input" == "Yes" ]; then
		        	  CurlIptable
		     	 else
		         	  exit 0
		     	 fi
		else
			CurlIptable
			CheckCrontab
		fi
}
#调用 UpdateList 函数
UpdateList
##CheckCrontab
