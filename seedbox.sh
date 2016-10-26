#!/bin/bash
#Website: http://www.dwhd.org
#IMPORTANT!!!Please Setting the following Values!
#================================================================
if [ $(id -u) != "0" ]; then
    echo "警告: 你现在不是root权限登录服务器, 请使用root帐号登录服务器，然后执行SEEDBOX军团的一键安装脚本~！"
    exit 1
fi

#================================================================
ONEKEY_DOWNLOAD_LINK="http://www.dwhd.org/download"
ONEKEY_WEB_LINK="www.dwhd.org"
ONEKEY_ADMIN_EMAIL="admin@dwhd.org"
ONEKEY_TIME="$(date)"
ONEKEY_NEWUSER_DIRECTORY="/home/box123"
ONEKEY_FLEXGET_DIRECTORY="/root/.flexget"
ONEKEY_ONLINE_INSTALL="apt-get install"
ONEKEY_SCCREN_DELUGE="screen -fa -d -m -S deluge-web deluge-web"
ONEKEY_CRONTAB_ROOT="/var/spool/cron/crontabs/root"
ONEKEY_OPENDIR=`cat /etc/security/limits.conf | grep '65535'`
ONEKEY_RC_LOCAL="/etc/rc.local"
ONEKEY_ADD_SOURCES="/etc/apt/sources.list"
ONEKEY_TR_CONFIG="/etc/transmission-daemon/settings.json"
ONEKET_TR_START="/etc/init.d/transmission-daemon"
ONEKEY_VNSTAT="/var/www/vnstat"
ONEKEY_OS="/root/os.txt"
ONEKEY_USERPASS="/root/chpass.txt"
ONEKEY_RTDIR="/var/rutorrent/rutorrent"
ONEKEY_RTDOWN="/root/rut"
#================================================================
ONEKEY_MAIN_MEN="
  	o---------------------------------------------------------------o
		|                          主菜单                               |
		|           请选择你需要的功能来执行一键脚本                    |
		|---------------------------------------------------------------|
		|            1/a/A. 安装 Deluge+Flexget                         |
		|            2/b/B. 安装 rtorrent + ruTorrent                   |
		|            3/c/C. 安装 Transmission+Flexget  (建议使用)       |
		|            4/d/D. 安装 FTP                                    |
		|            5/e/E. 安装 VPN                                    |
		|            6/f/F. 安装 VNC                                    |
		|            7/g/G. 开启 SSH Proxy                              |
		|            8/h/H. 修改时区为中国大陆时区                      |
		|            9/i/I. 一键配置Flexget (可以一键配置 中国5大站RSS) |
		|           10/j/J. 安装 Rapidleech                             |
		|---------------------------------------------------------------|
		|            0/q/Q. 退出脚本                                    |
		|---------------------------------------------------------------|
		|如果脚本有BUG请联系邮箱 $ONEKEY_ADMIN_EMAIL                         |
		o---------------------------------------------------------------o"

ONEKEY_RSS_MEN="
		o---------------------------------------------------------------o
		|                          RSS菜单                              |
		|           请选择你需要的功能来执行一键脚本                    |
		|---------------------------------------------------------------|
		|            1/a/A. 一键配置 Deluge RSS (支持国内五大站)        |
		|            2/b/B. 一键配置 Transmission RSS (支持国内五大站)  |
		|---------------------------------------------------------------|
		|---------------------------------------------------------------|
		|如果脚本有BUG请联系邮箱 $ONEKEY_ADMIN_EMAIL                         |
		o---------------------------------------------------------------o"
		
ONEKEY_DELUGE_MEN="
		o---------------------------------------------------------------o
		|                     Deluge安装菜单                            |
		|           请选择你需要的功能来执行一键脚本                    |
		|---------------------------------------------------------------|
		|            1/a/A. 一键安装Deluge1.3.5版                       |
		|            2/b/B. 一键安装Deluge最新版本                      |
		|---------------------------------------------------------------|
		|---------------------------------------------------------------|
		|如果脚本有BUG请联系邮箱 $ONEKEY_ADMIN_EMAIL                         |
		o---------------------------------------------------------------o"


ONEKEY_VERSION="
				_____           _  _____
				|   __|___ ___ _| || __  |___ _ _
				|__   | -_| -_| . || __ -| . |_'_|
				|_____|___|___|___||_____|___|_,_|
					V 4.1.8"

#================================================================
# Sets os and os_long to the OS type and OS name respectively
detectOs() {
		local DISTRIB_ID=
		local DISTRIB_DESCRIPTION=
		if [ -f /etc/lsb-release ]; then
			. /etc/lsb-release
		fi

		if [ "$DISTRIB_ID" = "Ubuntu" ]; then
			os=debian
			os_long="$DISTRIB_DESCRIPTION"
		elif [ -f /etc/debian_version ]; then
			os=debian
			local prefix=
			if ! uname -s | grep -q GNU; then
				prefix="GNU/"
			fi
			os_long="Debian $prefix$(uname -s) $(cat /etc/debian_version)"
		fi

		os_long="${os_long:-$(uname -s)}"
}

rm -rf $ONEKEY_OS
touch $ONEKEY_OS
detectOs
cat > $ONEKEY_OS << EOF
$os_long
EOF

ONEKEY_DEBIAN_VERSION=`cat $ONEKEY_OS | grep 'Debian'`
ONEKEY_UBUNTU_VERSION=`cat $ONEKEY_OS | grep 'Ubuntu'`
ONEKEY_UBUNTU_1004=`cat $ONEKEY_OS | grep 'Ubuntu 10.04'`
ONEKEY_UBUNTU_1110=`cat $ONEKEY_OS | grep 'Ubuntu 11.10'`
ONEKEY_UBUNTU_1204=`cat $ONEKEY_OS | grep 'Ubuntu 12.04'`

#================================================================
isValidIpAddress() {
		# It's not 100% accurate ... ;)
		echo $1 | grep -qE '^[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?\.[0-9][0-9]?[0-9]?$'
}

getIpAddress() {
		isValidIpAddress "$OUR_IP_ADDRESS" && return
		echo "${CMSG}Detecting your IP address...$CEND"
		isValidIpAddress "$OUR_IP_ADDRESS" || OUR_IP_ADDRESS=$(curl ifconfig.me)
		isValidIpAddress "$OUR_IP_ADDRESS" || OUR_IP_ADDRESS=$(ifconfig | awk -F'[ ]+|:' '/inet addr/{if($4!~/^192.168|^172.16|^10|^127|^0/) print $4}')
		isValidIpAddress "$OUR_IP_ADDRESS" || OUR_IP_ADDRESS=$(wget -q --no-check-certificate http://www.whatismyip.com/automation/n09230945.asp -O - -o /dev/null)
		isValidIpAddress "$OUR_IP_ADDRESS" || OUR_IP_ADDRESS="1.2.3.4"
}

mainmenu() {
		clear
		cat << EOF
${CGREEN}$ONEKEY_VERSION$CEND$CWARNING$ONEKEY_MAIN_MEN$CEND
EOF
}

rssmenu() {
		clear
		cat << EOF
${CGREEN}$ONEKEY_VERSION$CEND$CWARNING$ONEKEY_RSS_MEN$CEND
EOF
}

delugemenu() {
		clear
		cat << EOF
${CGREEN}$ONEKEY_VERSION$CEND$CWARNING$ONEKEY_DELUGE_MEN$CEND
EOF
}

#================================================================
ONEKEY_LOGO="
        @@                    @         @@@                   @@@
        @@                   @@@        @@@@@@@@@@@@@@@@@@@@@@@@@@
       @@@@@@@@@@@@@@@@@@@@@@@@@@       @@@          @@@      @@@@
       @@@      @@@         @@@@@       @@@          @@@@     @@@@
      @@@@      @@@@        @@@         @@@          @@@@     @@@@
     @@@@@     @@@@@       @@@          @@@          @@@@     @@@@
      @@       @@@@                     @@@          @@@@     @@@@
              @@@@        @@@           @@@          @@@@  @@ @@@@
        @@@@@@@@@@@@@@@@@@@@@@          @@@          @@@@ @@@@@@@@
         @@@@@@@@                       @@@ @@@@@@@@@@@@@@@@@@@@@@
             @@@@ @@@                   @@@         @@@@@     @@@@
            @@@@  @@@@@                 @@@         @@@@@     @@@@
           @@@@   @@@@                  @@@        @@@@@@     @@@@
           @@@@   @@@@                  @@@       @@@@@@@     @@@@
          @@@@    @@@@    @@@           @@@       @@@@@@@     @@@@
         @@@@@@@@@@@@@@@@@@@@@          @@@      @@@@@@@@     @@@@
         @@@@@@@@@@@@@@@@@@@@@          @@@     @@@@ @@@@     @@@@
          @@      @@@@                  @@@    @@@@  @@@@     @@@@
                  @@@@                  @@@   @@@@   @@@@     @@@@
                  @@@@        @@        @@@  @@@@    @@@@     @@@@
                  @@@@       @@@@       @@@ @@@@     @@@@     @@@@
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@       @@@@     @@@@
                  @@@@                  @@@     @@@@@@@@@     @@@@
                  @@@@                  @@@       @@@@@@      @@@@
                  @@@@                  @@@         @@@       @@@@
                  @@@@                  @@@         @@        @@@@
                  @@@@                  @@@@@@@@@@@@@@@@@@@@@@@@@@
                  @@@@                  @@@                   @@@@
                  @@@@                  @@@                   @@@
                  @@                                                  "

#================================================================
echo=echo
for cmd in echo /bin/echo; do
		$cmd >/dev/null 2>&1 || continue
		if ! $cmd -e "" | grep -qE '^-e'; then
			echo=$cmd
			break
		fi
done

CSI=$($echo -e "\033[")
CEND="${CSI}0m"
CDGREEN="${CSI}32m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"
CQUESTION="$CMAGENTA"
CWARNING="$CRED"
CMSG="$CCYAN"

#================================================================
	clear
	blockHDWing="y"
	echo ""
	echo "${CWARNING}是否屏蔽HDWing网站?我们建议您屏蔽HDWing网站,具体原因不多说~$CEND"
	echo "${CGREEN}默认是屏蔽HDWing网站，如果不想屏蔽请输入n然后按回车键:$CEND"
	read blockHDWing

	case "$blockHDWing" in
	y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
	echo "${CYELLOW}你同意屏蔽HDWing网站$CEND"
	blockHDWing="y"
	;;
	n|N|No|NO|no|nO)
	echo "${CYELLOW}不屏蔽HDWing网站$CEND"
	blockHDWing="n"
	;;
	*)
	echo "${CYELLOW}输入错误,按照默认选择屏蔽HDWing网站$CEND"
	blockHDWing="y"
	esac
	if [ $blockHDWing = "n" ]
	then
		iptables -F;iptables -X;iptables -Z
	else
		$ONEKEY_ONLINE_INSTALL -y iptables
		iptables -I INPUT -s 198.143.146.237 -j DROP
	fi
	clear

exit_scrip() {
		exit_scrip="y"
		echo ""
		echo "${CWARNING} 是否继续执行脚本?$CEND"
		echo "${CGREEN}默认按任意键退出执行,如果需要继续执行脚本请按输入n 然后回车:$CEND"
		read exit_scrip

		case "$exit_scrip" in
		y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
		echo "${CYELLOW}退出SEEDBOX军团一键脚本 !感谢您的使用!$CEND"
		exit_scrip="y"
		;;
		n|N|No|NO|no|nO)
		echo "${CYELLOW}继续执行脚本!$CEND"
		exit_scrip="n"
		;;
		*)
		echo "${CYELLOW}输入错误,退出SEEDBOX军团一键脚本!感谢您的使用!$CEND"
		exit_scrip="y"
		esac
		if [ $exit_scrip = "n" ]
		then
			clear
			men
		fi
}

men() {
		while :
		do
		mainmenu
		cat << EOF
$CMSG 请输入你需要的选项(0-10/a-j/A-J):$CEND
EOF
		read input
		if [ "$input" = "1" ] || [ "$input" = "a" ] || [ "$input" = "A" ]
		then
			#echo "${CWARNING}由于CHD和HDS不再支持Deluge客户端SEEDBOX军团不建议你安装Deluge客户端.......$CEND"
			#echo "${CWARNING}由于时间紧急 SEEDBOX军团暂时将Deluge安装暂停.......$CEND"
			#echo "${CWARNING}我们会在后期开放Deluge的安装.......$CEND"
			#echo "${CWARNING}以此带来的不便请谅解.......$CEND"&&sleep 3
			clear
			delugemenu
			cat << EOF
$CMSG 请输入你需要的选项:$CEND
EOF
			read deluge
			if [ "$deluge" = "1" ] || [ "$deluge" = "A" ] || [ "$deluge" = "a" ]
			then
				install_deluge135
				exit_scrip
			elif [ "$deluge" = "2" ] || [ "$deluge" = "B" ] || [ "$deluge" = "b" ]
			then
				install_deluge
				exit_scrip
			else
				clear&&echo ""
				echo "${CQUESTION}              不配置任何RSS返回菜单 $CEND"
				sleep 1&&men
			fi
			break
		elif [ "$input" = "2" ] || [ "$input" = "b" ] || [ "$input" = "B" ]
		then
			clear
			install_rtorrent
			exit_scrip
			break
		elif [ "$input" = "3" ] || [ "$input" = "c" ] || [ "$input" = "C" ]
		then
			clear
			install_transmission
			exit_scrip
			break
		elif [ "$input" = "4" ] || [ "$input" = "d" ] || [ "$input" = "D" ]
		then
			clear
			install_ftp
			exit_scrip
			break
		elif [ "$input" = "5" ] || [ "$input" = "e" ] || [ "$input" = "E" ]
		then
			clear
			install_vpn
			exit_scrip
			break
		elif [ "$input" = "6" ] || [ "$input" = "f" ] || [ "$input" = "F" ]
		then
			clear
			install_vnc
			exit_scrip
			break
		elif [ "$input" = "7" ] || [ "$input" = "g" ] || [ "$input" = "G" ]
		then
			clear
			install_ssh_proxy
			exit_scrip
			break
		elif [ "$input" = "8" ] || [ "$input" = "h" ] || [ "$input" = "H" ]
		then
			clear
			change_time
			exit_scrip
			break
		elif [ "$input" = "9" ] || [ "$input" = "i" ] || [ "$input" = "I" ]
		then
			clear
			rssmenu
			cat << EOF
$CMSG 请输入你需要的选项:$CEND
EOF
			read rss
			if [ "$rss" = "1" ] || [ "$rss" = "A" ] || [ "$rss" = "a" ]
			then
				deflexget_config
				exit_scrip
			elif [ "$rss" = "2" ] || [ "$rss" = "B" ] || [ "$rss" = "b" ]
			then
				trflexget_config
				exit_scrip
			else
				clear&&echo ""
				echo "${CQUESTION}              不配置任何RSS返回菜单 $CEND"
				sleep 1&&men
			fi
			break
		elif [ "$input" = "10" ] || [ "$input" = "j" ] || [ "$input" = "J" ]
		then
			clear
			install_rapidleech
			exit_scrip
			break
		elif [ "$input" = "11" ] || [ "$input" = "k" ] || [ "$input" = "K" ]
		then
			clear
			install_vg
			exit_scrip
			break
		elif [ "$input" = "0" ] || [ "$input" = "q" ] || [ "$input" = "Q" ]
		then
			clear
			echo "${CQUESTION}对不起!!!!! 脚本开始退出.........................$CEND"
			sleep 2;echo "Bye Bye";clear
			echo "${CQUESTION}Shell 脚本运行结束时间: $CGREEN$ONEKEY_TIME$CEND"
			exit
		else
			clear&&echo ""&&echo ""&&echo ""
			echo "$CMSG                     请输入一个正确的选项!$CEND"&&sleep 2
		fi
		done
}
#================================================================
install_deluge135() {
		clear&&echo "${CYELLOW}开始安装Deluge1.3.5及相关软件...............................$CEND"
		sleep 2
		#start install deluge
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/downloads/
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/rss/
		mkdir -p $ONEKEY_FLEXGET_DIRECTORY
		apt-get autoremove --purge mysql* -y
		$ONEKEY_ONLINE_INSTALL -y python-twisted python-twisted-web2 python-openssl python-simplejson python-setuptools python-xdg python-chardet python-geoip python-libtorrent python-notify python-pygame python-gtk2 python-gtk2-dev python-mako gettext intltool  librsvg2-dev xdg-utils
		$ONEKEY_ONLINE_INSTALL -y mktorrent unrar* screen bizp2
		$ONEKEY_ONLINE_INSTALL vnstat
		wget -q -O /root/deluge-1.3.5.tar $ONEKEY_DOWNLOAD_LINK/102/
		tar -xf deluge-1.3.5.tar
		cd deluge-1.3.5&&python setup.py clean -a
		python setup.py install&&cd
		rm -rf $ONEKEY_OS deluge-*
		deluged
		$ONEKEY_SCCREN_DELUGE
		sed -i '/exit 0/d' $ONEKEY_RC_LOCAL
		sed -i '/deluge/d' $ONEKEY_RC_LOCAL
		echo "deluged" >> $ONEKEY_RC_LOCAL
		echo "$ONEKEY_SCCREN_DELUGE" >> $ONEKEY_RC_LOCAL
		echo "exit 0" >> $ONEKEY_RC_LOCAL
		killall deluged
		wget -q -O /root/.config/deluge/core.conf $ONEKEY_DOWNLOAD_LINK/35/
		deluged
		vnstat -u -i eth0

		clear&&echo "${CQUESTION}你是否希望安装Flexget，若安装请输入Y，不安装请输入任意键。$CEND"
		read flexget
		if [ "$flexget" = "y" ] || [ "$flexget" = "yes" ] || [ "$flexget" = "Y" ] || [ "$flexget" = "YES" ] || [ "$flexet" = "Yes" ]
		then
			#start install flexget
			#http://download.flexget.com/unstable/FlexGet-1.0r3182.tar.gz
			clear&&$ONEKEY_ONLINE_INSTALL -y python-setuptools
			easy_install flexget
			#run deluge and config auto start on system start
			#config flexget crontab
			touch $ONEKEY_CRONTAB_ROOT
			ONEKEY_FLEXGET1=`cat /var/spool/cron/crontabs/root | grep '/usr/local/bin/flexget > /root/flexget.log 2>&1'`
			ONEKEY_FLEXGET2=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /root/.flexget/.config-lock'`
			ONEKEY_FLEXGET3=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /home/box123/rss/*'`
			if [ -n "$ONEKEY_FLEXGET1" ]
			then
				echo "${CYELLOW}Flexget定时运行已经设置  跳过$CEND"
			else
				echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
			fi
			if [ -n "$ONEKEY_FLEXGET2" ]
			then
				echo "${CYELLOW}Flexget防止自动锁设置已经配置   跳过$CEND"
			else
				echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
			fi
			if [ -n "$ONEKEY_FLEXGET3" ]
			then
				echo "${CYELLOW}定时清空Flexget RSS种子缓存已经设置   跳过$CEND"
			else
			echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
			fi
			crontab $ONEKEY_CRONTAB_ROOT
			crontab -l

			#start install apache
			#apt-get install -y apache2
			#ln -s /home/box123/downloads/ /var/www/
			#/etc/init.d/apache2 stop/start/restart

			#start http downloads
			#cd /home/box123/downloads
			#screen -fa -d -m -S http python -m SimpleHTTPServer 8888;cd

			#download config.yml and config it
			cd $ONEKEY_FLEXGET_DIRECTORY/
			wget -q -O $ONEKEY_FLEXGET_DIRECTORY/config.yml $ONEKEY_DOWNLOAD_LINK/11/

			clear
			echo "${CYELLOW}                        请输入你的RSS地址, 如果不想配置RSS请直接按 \"ENTER\" ，脚本会自行跳过$CEND"
			echo "${CQUESTION}请输入你的CHD RSS地址 :$CEND"
			read chdrss1
			echo "${CQUESTION}请输入你的CHD下载框地址 :$CEND"
			read chdrss2
			echo "${CQUESTION}请输入你的TTG RSS地址 :$CEND"
			read ttgrss1
			echo "${CQUESTION}请输入你的TTG小货车地址 :$CEND"
			read ttgrss2
			if [ $blockHDWing = "n" ]
			then
				echo "${CQUESTION}请输入你的HDWing RSS地址 :$CEND"
				read HDWingrss1
				echo "${CQUESTION}请输入你的HDWing下载框地址 :$CEND"
				read HDWingrss2
			else
				echo "${CWARNING}#############由于你选择了屏蔽HDWing网站，所以不做HDWing RSS配置#############$CEND"
			fi
				echo "${CQUESTION}请输入你的HDR RSS地址 :$CEND"
				read hdrrss1
				echo "${CQUESTION}请输入你的HDS RSS地址 :$CEND"
				read hdsrss1
				echo "${CQUESTION}请输入你的HDS下载框地址 :$CEND"
				read hdsrss2
			echo ""
			#modiry rss url and del no define variables
			if [ "$chdrss1" != "" ]
			then
				chdrss1=`echo "$chdrss1" | sed 's@\&@\\\&@g'`
				#modify CHD RSS url1 3 line
				sed -i 3,3s@rss:.*@"rss: $chdrss1\r"@ config.yml
			else
				#del 2-20 line
				sed -i '2,21s/.*//' config.yml
			fi

			if [ "$chdrss2" != "" ]
			then
				chdrss2=`echo "$chdrss2" | sed 's@\&@\\\&@g'`
				#modify CHD RSS url2 22 line
				sed -i 23,23s@rss:.*@"rss: $chdrss2\r"@ config.yml
			else
				#del 21-32 line
				sed -i '22,33s/.*//' config.yml
			fi

			if [ "$ttgrss1" != "" ]
			then
				ttgrss1=`echo "$ttgrss1" | sed 's@\&@\\\&@g'`
				#modify TTG url1 34 line
				sed -i 35,35s@rss:.*@"rss: $ttgrss1\r"@ config.yml
			else
				#del 33-53 line
				sed -i '34,53s/.*//' config.yml
			fi

			if [ "$ttgrss2" != "" ]
			then
				ttgrss2=`echo "$ttgrss2" | sed 's@\&@\\\&@g'`
				#modify TTG url2 55 line
				sed -i 55,55s@rss:.*@"rss: $ttgrss2\r"@ config.yml
			else
				#del 54-65 line
				sed -i '54,65s/.*//' config.yml
				fi

			if [ $blockHDWing = "n" ]
			then
				if [ "$HDWingrss1" != "" ]
				then
					HDWingrss1=`echo "$HDWingrss1" | sed 's@\&@\\\&@g'`
					#modify HDWing url1 67 line
					sed -i 67,67s@rss:.*@"rss: $HDWingrss1\r"@ config.yml
				else
					#del 66-85 line
					sed -i '66,85s/.*//' config.yml
				fi

				if [ "$HDWingrss2" != "" ]
				then
					HDWingrss2=`echo "$HDWingrss2" | sed 's@\&@\\\&@g'`
					#modify HDWing url2 87 line
					sed -i 87,87s@rss:.*@"rss: $HDWingrss2\r"@ config.yml
				else
					#del 86-97 line
					sed -i '86,97s/.*//' config.yml
				fi
			else
				#del 66-97 line
				sed -i '66,97s/.*//' config.yml
			fi
##########################################################################################
			if [ "$hdrrss1" != "" ]
			then
				hdrrss1=`echo "$hdrrss1" | sed 's@\&@\\\&@g'`
				#modify HDR url1 99 line
				sed -i 99,99s@rss:.*@"rss: $hdrrss1\r"@ config.yml
			else
				#del 98-117 line
				sed -i '98,118s/.*//' config.yml
			fi

			if [ "$hdsrss1" != "" ]
			then
				hdsrss1=`echo "$hdsrss1" | sed 's@\&@\\\&@g'`
				#modify HDS url1 119 line
				sed -i 120,120s@rss:.*@"rss: $hdsrss1\r"@ config.yml
			else
				#del 118-137 line
				sed -i '119,138s/.*//' config.yml
			fi

			if [ "$hdsrss2" != "" ]
			then
				hdsrss2=`echo "$hdsrss2" | sed 's@\&@\\\&@g'`
				#modify HDS url2 139 line
				sed -i 140,140s@rss:.*@"rss: $hdsrss2\r"@ config.yml
			else
				#del 138-149 line
				sed -i '139,150s/.*//' config.yml
			fi
			clear

			#del space line
			sed -i '/^$/d' config.yml

			#dos2unix
			dos2unix $ONEKEY_FLEXGET_DIRECTORY/config.yml
			sed -i 's/\\r//' config.yml&&clear

			echo "${CYELLOW}请等待，程序运行中...";sleep 55;clear;echo "${CYELLOW}请等待5秒 ,脚本运行中...$CEND";echo "${CYELLOW}5 .........$CEND";sleep 1;echo "${CYELLOW}4 ........$CEND";sleep 1;echo "${CYELLOW}3 ......$CEND";sleep 1;echo "${CYELLOW}2 ....$CEND";sleep 1;echo "${CYELLOW}1 ...GO$CEND";sleep 1;clear
			ONEKEY_DELUGE_PASS=`awk -F ':' '{print $2}' /root/.config/deluge/auth`
			ONEKEY_DELUGE_USERNAME=`awk -F ':' '{print $1}' /root/.config/deluge/auth`
			sed -i s/"pass:"/"pass: $ONEKEY_DELUGE_PASS"/g config.yml
		else
			clear&&echo "${CYELLOW}请等待，程序运行中...";sleep 55;clear;echo "${CYELLOW}请等待5秒 ,脚本运行中...$CEND";echo "${CYELLOW}5 .........$CEND";sleep 1;echo "${CYELLOW}4 ........$CEND";sleep 1;echo "${CYELLOW}3 ......$CEND";sleep 1;echo "${CYELLOW}2 ....$CEND";sleep 1;echo "${CYELLOW}1 ...GO$CEND";sleep 1;clear
			ONEKEY_DELUGE_PASS=`awk -F ':' '{print $2}' /root/.config/deluge/auth`
			ONEKEY_DELUGE_USERNAME=`awk -F ':' '{print $1}' /root/.config/deluge/auth`
		fi
		getIpAddress
		clear
		cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   Deluge安装结束，下面是Deluge的相关信息$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 你的Deluge 登录地址        :$CGREEN http://$OUR_IP_ADDRESS:8112 $CEND
		${CQUESTION}= 你的Deluge 登录密码        :$CGREEN deluge$CEND
		${CQUESTION}= 你的Deluge 下载路径        :$CGREEN $ONEKEY_NEWUSER_DIRECTORY/downloads$CEND
		${CQUESTION}= Deluge pass                :$CGREEN $ONEKEY_DELUGE_PASS$CEND
		${CQUESTION}= Deluge Username            :$CGREEN $ONEKEY_DELUGE_USERNAME$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_deluge() {
		clear&&echo "${CYELLOW}开始安装Deluge及相关软件...............................$CEND"
		sleep 2
		#start install deluge
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/downloads/
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/rss/
		mkdir -p $ONEKEY_FLEXGET_DIRECTORY
		if [ -n "$ONEKEY_UBUNTU_VERSION" ]
		then
			clear
			apt-get autoremove --purge mysql* -y
			if [ -n "$ONEKEY_UBUNTU_1110" ]
			then
				cp $ONEKEY_ADD_SOURCES $ONEKEY_ADD_SOURCES.backup
				cat >> $ONEKEY_ADD_SOURCES << EOF
deb http://archive.ubuntu.com/ubuntu/ oneiric main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ oneiric-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ oneiric-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ oneiric-proposed main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ oneiric-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ oneiric main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ oneiric-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ oneiric-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ oneiric-proposed main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ oneiric-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ oneiric partner
deb http://extras.ubuntu.com/ubuntu oneiric main
EOF
			fi
			if [ -n "$ONEKEY_UBUNTU_1004" ]
			then
				cp $ONEKEY_ADD_SOURCES $ONEKEY_ADD_SOURCES.backup
				cat >> $ONEKEY_ADD_SOURCES << EOF
deb http://archive.ubuntu.com/ubuntu/ lucid main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ lucid-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ lucid-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ lucid-proposed main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ lucid-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ lucid main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ lucid-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ lucid-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ lucid-proposed main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ lucid-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ lucid partner
EOF
			fi
			if [ -n "$ONEKEY_UBUNTU_1204" ]
			then
				cp $ONEKEY_ADD_SOURCES $ONEKEY_ADD_SOURCES.backup
				cat >> $ONEKEY_ADD_SOURCES << EOF
deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ precise-proposed main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse
deb http://archive.canonical.com/ubuntu/ precise partner
deb http://extras.ubuntu.com/ubuntu/ precise main
EOF
			fi
			apt-get update
			echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu jaunty main" >> $ONEKEY_ADD_SOURCES
			echo "deb-src http://ppa.launchpad.net/deluge-team/ppa/ubuntu jaunty main" >> $ONEKEY_ADD_SOURCES
			$ONEKEY_ONLINE_INSTALL vnstat
			clear
			echo "${CQUESTION}你希望安装Web 版的Vnstat吗？,请输入 [\"Y\"/\"N\"] 来选择~!$CEND"
			read vnstat
			if [ "$vnstat" = "y" ] || [ "$vnstat" = "yes" ] || [ "$vnstat" = "Y" ] || [ "$vnstat" = "YES" ] || [ "$vnstat" = "Yes" ]
			then
				$ONEKEY_ONLINE_INSTALL -y apache2
				$ONEKEY_ONLINE_INSTALL -y php5
				$ONEKEY_ONLINE_INSTALL -y php5-gd
				$ONEKEY_ONLINE_INSTALL -y php5-cli
				wget -q -O vnstat.tar $ONEKEY_DOWNLOAD_LINK/45/
				tar xvf vnstat.tar
				mv vnstat $ONEKEY_VNSTAT
				rm -rf vnstat.tar
				sed -i s@/var/www@$ONEKEY_VNSTAT@ /etc/apache2/sites-available/default
				/etc/init.d/apache2 restart && clear
			else
				echo "${CQUESTION}不安装Web版Vnstat~~~~~~~~~~~~~~~~~~~~~$CEND"
				clear && sleep 2
			fi
			sed -i s/"MaxBandwidth 100"/"MaxBandwidth 1000"/g /etc/vnstat.conf
			if [ -n "$ONEKEY_UBUNTU_1004" ]
			then
				chmod 777 /var/run/screen
			else
				echo "${CQUESTION}Vnstat 安装完成~~~~~~~~~~~~~~~~~~~~~$CEND"
				clear
			fi
			$ONEKEY_ONLINE_INSTALL mktorrent
			$ONEKEY_ONLINE_INSTALL -y unrar*
			$ONEKEY_ONLINE_INSTALL python-software-properties --force-yes -y&&clear
			add-apt-repository -y ppa:deluge-team/ppa
			apt-get update -y
			$ONEKEY_ONLINE_INSTALL screen deluged deluge-web --force-yes -y

		elif [ -n "$ONEKEY_DEBIAN_VERSION" ]
		then
			echo "nameserver 8.8.8.8" > /etc/resolv.conf
			echo "nameserver 8.8.4.4" >> /etc/resolv.conf
			# Start
			echo "${CYELLOW}开始安装Deluge...............................$CEND"
			#start install deluge
			rm -rf $ONEKEY_FLEXGET_DIRECTORY/config.yml
			echo "deb http://ftp.fr.debian.org/debian unstable main" >> $ONEKEY_ADD_SOURCES
			echo "deb-src http://ftp.fr.debian.org/debian unstable main" >> $ONEKEY_ADD_SOURCES
			wget -q -O /etc/apt/preferences $ONEKEY_DOWNLOAD_LINK/24/
			aptitude update -y
			aptitude -t unstable install deluge -y
			echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu lucid main" >> $ONEKEY_ADD_SOURCES
			echo "deb-src http://ppa.launchpad.net/deluge-team/ppa/ubuntu lucid main" >> $ONEKEY_ADD_SOURCES
			apt-key adv --recv-keys --keyserver pgp.surfnet.nl 249AD24C
			apt-get update -y
			apt-get install -t lucid deluge-common deluged deluge-web -y
		else
			echo "${CQUESTION}Version is not Ubuntu OR Debian !!!$CEND"
			echo "${CQUESTION}Sorry!!!!! Now Quit.........................$CEND"
			echo "${CQUESTION}Shell Script Over Time: $CGREEN$ONEKEY_TIME$CEND"
		fi
		rm -rf $ONEKEY_OS
		deluged && $ONEKEY_SCCREN_DELUGE
		sed -i '/exit 0/d' $ONEKEY_RC_LOCAL
		sed -i '/deluge/d' $ONEKEY_RC_LOCAL
		echo "deluged" >> $ONEKEY_RC_LOCAL
		echo "$ONEKEY_SCCREN_DELUGE" >> $ONEKEY_RC_LOCAL
		echo "exit 0" >> $ONEKEY_RC_LOCAL
		killall deluged
		wget -q -O /root/.config/deluge/core.conf $ONEKEY_DOWNLOAD_LINK/35/
		deluged
		vnstat -u -i eth0

		clear&&echo "${CQUESTION}你是否希望安装Flexget，若安装请输入Y，不安装请输入任意键。$CEND"
		read flexget
		if [ "$flexget" = "y" ] || [ "$flexget" = "yes" ] || [ "$flexget" = "Y" ] || [ "$flexget" = "YES" ] || [ "$flexet" = "Yes" ]
		then
			#start install flexget
			#http://download.flexget.com/unstable/FlexGet-1.0r3182.tar.gz
			$ONEKEY_ONLINE_INSTALL -y python-setuptools
			easy_install flexget
			#run deluge and config auto start on system start
			#config flexget crontab
			touch $ONEKEY_CRONTAB_ROOT
			ONEKEY_FLEXGET1=`cat /var/spool/cron/crontabs/root | grep '/usr/local/bin/flexget > /root/flexget.log 2>&1'`
			ONEKEY_FLEXGET2=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /root/.flexget/.config-lock'`
			ONEKEY_FLEXGET3=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /home/box123/rss/*'`
			if [ -n "$ONEKEY_FLEXGET1" ]
			then
				echo "${CYELLOW}Flexget定时运行已经设置  跳过$CEND"
			else
				echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
			fi
			if [ -n "$ONEKEY_FLEXGET2" ]
			then
				echo "${CYELLOW}Flexget防止自动锁设置已经配置   跳过$CEND"
				else
			echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
			fi
			if [ -n "$ONEKEY_FLEXGET3" ]
			then
				echo "${CYELLOW}定时清空Flexget RSS种子缓存已经设置   跳过$CEND"
			else
				echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
			fi

			crontab $ONEKEY_CRONTAB_ROOT && crontab -l
			#start install apache
			#apt-get install -y apache2
			#ln -s /home/box123/downloads/ /var/www/
			#/etc/init.d/apache2 stop/start/restart

			#start http downloads
			#cd /home/box123/downloads
			#screen -fa -d -m -S http python -m SimpleHTTPServer 8888;cd

			#download config.yml and config it
			cd $ONEKEY_FLEXGET_DIRECTORY/
			wget -q -O $ONEKEY_FLEXGET_DIRECTORY/config.yml $ONEKEY_DOWNLOAD_LINK/11/

			clear
			echo "${CYELLOW}                        请输入你的RSS地址, 如果不想配置RSS请直接按 \"ENTER\" ，脚本会自行跳过$CEND"
			echo "${CQUESTION}请输入你的CHD RSS地址 :$CEND"
			read chdrss1
			echo "${CQUESTION}请输入你的CHD下载框地址 :$CEND"
			read chdrss2
			echo "${CQUESTION}请输入你的TTG RSS地址 :$CEND"
			read ttgrss1
			echo "${CQUESTION}请输入你的TTG小货车地址 :$CEND"
			read ttgrss2
			if [ $blockHDWing = "n" ]
			then
				echo "${CQUESTION}请输入你的HDWing RSS地址 :$CEND"
				read HDWingrss1
				echo "${CQUESTION}请输入你的HDWing下载框地址 :$CEND"
				read HDWingrss2
			else
				echo "${CWARNING}#############由于你选择了屏蔽HDWing网站，所以不做HDWing RSS配置#############$CEND"
			fi
			echo "${CQUESTION}请输入你的HDR RSS地址 :$CEND"
			read hdrrss1
			echo "${CQUESTION}请输入你的HDS RSS地址 :$CEND"
			read hdsrss1
			echo "${CQUESTION}请输入你的HDS下载框地址 :$CEND"
			read hdsrss2
			echo ""
			#modiry rss url and del no define variables
			if [ "$chdrss1" != "" ]
			then
				chdrss1=`echo "$chdrss1" | sed 's@\&@\\\&@g'`
				#modify CHD RSS url1 3 line
				sed -i 3,3s@rss:.*@"rss: $chdrss1\r"@ config.yml
			else
				#del 2-20 line
				sed -i '2,21s/.*//' config.yml
			fi

			if [ "$chdrss2" != "" ]
			then
				chdrss2=`echo "$chdrss2" | sed 's@\&@\\\&@g'`
				#modify CHD RSS url2 22 line
				sed -i 23,23s@rss:.*@"rss: $chdrss2\r"@ config.yml
			else
				#del 21-32 line
				sed -i '22,33s/.*//' config.yml
			fi

			if [ "$ttgrss1" != "" ]
			then
				ttgrss1=`echo "$ttgrss1" | sed 's@\&@\\\&@g'`
				#modify TTG url1 34 line
				sed -i 35,35s@rss:.*@"rss: $ttgrss1\r"@ config.yml
			else
				#del 33-53 line
				sed -i '34,53s/.*//' config.yml
			fi

			if [ "$ttgrss2" != "" ]
			then
				ttgrss2=`echo "$ttgrss2" | sed 's@\&@\\\&@g'`
				#modify TTG url2 55 line
				sed -i 55,55s@rss:.*@"rss: $ttgrss2\r"@ config.yml
			else
				#del 54-65 line
				sed -i '54,65s/.*//' config.yml
			fi

			if [ $blockHDWing = "n" ]
			then
				if [ "$HDWingrss1" != "" ]
				then
					HDWingrss1=`echo "$HDWingrss1" | sed 's@\&@\\\&@g'`
					#modify HDWing url1 67 line
					sed -i 67,67s@rss:.*@"rss: $HDWingrss1\r"@ config.yml
				else
					#del 66-85 line
					sed -i '66,85s/.*//' config.yml
				fi

				if [ "$HDWingrss2" != "" ]
				then
					HDWingrss2=`echo "$HDWingrss2" | sed 's@\&@\\\&@g'`
					#modify HDWing url2 87 line
					sed -i 87,87s@rss:.*@"rss: $HDWingrss2\r"@ config.yml
				else
					#del 86-97 line
					sed -i '86,97s/.*//' config.yml
				fi
			else
				#del 66-97 line
				sed -i '66,97s/.*//' config.yml
			fi
##########################################################################################
			if [ "$hdrrss1" != "" ]
			then
				hdrrss1=`echo "$hdrrss1" | sed 's@\&@\\\&@g'`
				#modify HDR url1 99 line
				sed -i 99,99s@rss:.*@"rss: $hdrrss1\r"@ config.yml
			else
				#del 98-117 line
				sed -i '98,118s/.*//' config.yml
			fi

			if [ "$hdsrss1" != "" ]
			then
				hdsrss1=`echo "$hdsrss1" | sed 's@\&@\\\&@g'`
				#modify HDS url1 119 line
				sed -i 120,120s@rss:.*@"rss: $hdsrss1\r"@ config.yml
			else
				#del 118-137 line
				sed -i '119,138s/.*//' config.yml
			fi

			if [ "$hdsrss2" != "" ]
			then
				hdsrss2=`echo "$hdsrss2" | sed 's@\&@\\\&@g'`
				#modify HDS url2 139 line
				sed -i 140,140s@rss:.*@"rss: $hdsrss2\r"@ config.yml
			else
				#del 138-149 line
				sed -i '139,150s/.*//' config.yml
			fi
			clear
			#del space line
			sed -i '/^$/d' config.yml

			#dos2unix
			dos2unix $ONEKEY_FLEXGET_DIRECTORY/config.yml
			sed -i 's/\\r//' config.yml&&clear

			echo "${CYELLOW}请等待，程序运行中...";sleep 55;clear;echo "${CYELLOW}请等待5秒 ,脚本运行中...$CEND";echo "${CYELLOW}5 .........$CEND";sleep 1;echo "${CYELLOW}4 ........$CEND";sleep 1;echo "${CYELLOW}3 ......$CEND";sleep 1;echo "${CYELLOW}2 ....$CEND";sleep 1;echo "${CYELLOW}1 ...GO$CEND";sleep 1;clear
			ONEKEY_DELUGE_PASS=`awk -F ':' '{print $2}' /root/.config/deluge/auth`
			ONEKEY_DELUGE_USERNAME=`awk -F ':' '{print $1}' /root/.config/deluge/auth`
			sed -i s/"pass:"/"pass: $ONEKEY_DELUGE_PASS"/g config.yml
		else
			clear&&echo "${CYELLOW}请等待，程序运行中...";sleep 55;clear;echo "${CYELLOW}请等待5秒 ,脚本运行中...$CEND";echo "${CYELLOW}5 .........$CEND";sleep 1;echo "${CYELLOW}4 ........$CEND";sleep 1;echo "${CYELLOW}3 ......$CEND";sleep 1;echo "${CYELLOW}2 ....$CEND";sleep 1;echo "${CYELLOW}1 ...GO$CEND";sleep 1;clear
			ONEKEY_DELUGE_PASS=`awk -F ':' '{print $2}' /root/.config/deluge/auth`
			ONEKEY_DELUGE_USERNAME=`awk -F ':' '{print $1}' /root/.config/deluge/auth`
		fi
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   Deluge安装结束，下面是Deluge的相关信息$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 你的Deluge 登录地址        :$CGREEN http://$OUR_IP_ADDRESS:8112 $CEND
		${CQUESTION}= 你的Deluge 登录密码        :$CGREEN deluge$CEND
		${CQUESTION}= 你的Deluge 下载路径        :$CGREEN $ONEKEY_NEWUSER_DIRECTORY/downloads$CEND
		${CQUESTION}= Deluge pass                :$CGREEN $ONEKEY_DELUGE_PASS$CEND
		${CQUESTION}= Deluge Username            :$CGREEN $ONEKEY_DELUGE_USERNAME$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_rtorrent() {
		clear
		echo "${CYELLOW}开始安装 ruTorrent...............................$CEND"
		sleep 2
		#self shell run
		#wget -q -O /root/ubunturt.sh $ONEKEY_DOWNLOAD_LINK/12/
		#sh /root/ubunturt.sh
		apt-get autoremove --purge apache* -y
		apt-get autoremove --purge mysql* -y
		apt-get update -y
		$ONEKEY_ONLINE_INSTALL nano screen -y
		$ONEKEY_ONLINE_INSTALL zip -y
		wget -q -O /root/rarlinux-4.2.0.tar.gz $ONEKEY_DOWNLOAD_LINK/103/
		tar -xzpf rarlinux-4.2.0.tar.gz&&rm -rf rarlinux-4.2.0.tar.gz
		cd rar%%sudo make&&cd
		$ONEKEY_ONLINE_INSTALL -y irssi 
		#$ONEKEY_ONLINE_INSTALL apache2-utils mini-httpd
		wget -q -O /root/autodl-setup $ONEKEY_DOWNLOAD_LINK/40/
		sh /root/autodl-setup
}

install_transmission() {
		clear && echo "${CYELLOW}开始安装Transmission并配置~~$CEND" && sleep 2 && clear
		#echo "${CQUESTION}请输入一个用户名作为Transmission的登录帐号:$CEND"
		#read trname
		#echo "${CQUESTION}请输入一个密码作为Transmission的登录密码:$CEND"
		#read trpasswd
		#clear
		trname=box123
		trpasswd=`openssl rand 6 -base64`
		if [ "$1" != "" ]
			then trpasswd=$1
		fi
		sudo useradd $trname
		touch $ONEKEY_USERPASS
		echo $trname:$trpasswd >> $ONEKEY_USERPASS
		chpasswd < $ONEKEY_USERPASS
		rm -rf $ONEKEY_USERPASS
		#touch $ONEKEY_CRONTAB_ROOT
		#echo "*/10 * * * * /etc/init.d/transmission-daemon start" >> $ONEKEY_CRONTAB_ROOT
		#echo "*/20 * * * * rm -rf /home/box123/trrss/*" >> $ONEKEY_CRONTAB_ROOT
		#crontab $ONEKEY_CRONTAB_ROOT
		#crontab -l&&clear
		apt-get install python-software-properties vnstat mktorrent -y&&clear
		add-apt-repository -y ppa:transmissionbt/ppa
		apt-get update
		apt-get -y install transmission-cli transmission-daemon transmission-common python-setuptools
		easy_install transmissionrpc
		clear&&echo "${CQUESTION}你是否希望安装Flexget，若安装请输入Y，不安装请输入任意键。$CEND"
		read flexget
		clear&&mkdir -p $ONEKEY_FLEXGET_DIRECTORY
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/downloads
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/incomplete
		mkdir -p $ONEKEY_NEWUSER_DIRECTORY/trrss
		chmod 777 -R $ONEKEY_NEWUSER_DIRECTORY/*
		#chown debian-transmission:debian-transmission -R $ONEKEY_NEWUSER_DIRECTORY/*
		$ONEKET_TR_START stop
		touch $ONEKEY_TR_CONFIG
		echo "" > $ONEKEY_TR_CONFIG
		cat > $ONEKEY_TR_CONFIG << EOF
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://www.example.com/blocklist",
    "cache-size-mb": 400,
    "dht-enabled": false,
    "download-dir": "/home/box123/downloads",
    "download-limit": 10000,
    "download-limit-enabled": 0,
    "download-queue-enabled": false,
    "download-queue-size": 50,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "/home/box123/incomplete",
    "incomplete-dir-enabled": false,
    "lazy-bitfield-enabled": false,
    "lpd-enabled": false,
    "max-peers-global": 20000,
    "message-level": 2,
    "open-file-limit": 65535,
    "peer-congestion-algorithm": "",
    "peer-limit-global": 880,
    "peer-limit-per-torrent": 800000,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": false,
    "preallocation": 1,
    "prefetch-enabled": 1,
    "proxy": "",
    "proxy-auth-enabled": false,
    "proxy-auth-password": "",
    "proxy-auth-username": "",
    "proxy-enabled": false,
    "proxy-port": 80,
    "proxy-type": 0,
    "queue-stalled-enabled": false,
    "queue-stalled-minutes": 30,
    "ratio-limit": 20,
    "ratio-limit-enabled": false,
    "rename-partial-files": false,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-password": "$trpasswd",
    "rpc-port": 9888,
    "rpc-url": "/transmission/",
    "rpc-username": "$trname",
    "rpc-whitelist": "127.0.0.1",
    "rpc-whitelist-enabled": false,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false, 
    "seed-queue-size": 10, 
    "speed-limit-down": 100,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": true,
    "umask": 0,
    "upload-limit": 10000,
    "upload-limit-enabled": 0,
    "upload-slots-per-torrent": 100,
    "utp-enabled": true,
    "watch-dir": "/home/box123/trrss",
    "watch-dir-enabled": true
}
EOF
		chmod -R 777 /etc/transmission-daemon/settings.json
		if [ -n "$ONEKEY_UBUNTU_VERSION" ]
		then
			trdir="/usr/share/transmission"
			trgzname="transmission-control-full.tar.gz"
			downtrweb="http://transmission-control.googlecode.com/svn/resouces/$trgzname" && clear
			echo "${CQUESTION}你是否希望安装Transmission的中文WEBui？ 若希望安装请输入 Y ，若不安装请输入任意键$CEND"
			read transmissionzh
			if [ "$transmissionzh" = "y" ] || [ "$transmissionzh" = "yes" ] || [ "$transmissionzh" = "Y" ] || [ "$transmissionzh" = "YES" ] || [ "$transmissionzh" = "Yes" ]
			then
				cd $trdir && mv $trdir/web/index.html $trdir/web/index.original.html
				wget -q $downtrweb -O $trdir/$trgzname
				cd $trdir/ && tar -zxf $trgzname && cd
			fi
			update-rc.d transmission-daemon defaults
		elif [ -n "$ONEKEY_DEBIAN_VERSION" ]
		then
			insserv transmission-daemon
		else
		#exit shell
			sleep 2;clear
			echo "${CQUESTION}对不起您的系统不是$CEND ${CGREEN}Ubuntu或者Debian.........................$CEND"
			echo "Bye Bye"
			echo "${CQUESTION}Shell 脚本运行结束时间: $CGREEN$ONEKEY_TIME$CEND"
			exit
		fi
		$ONEKET_TR_START start
		TRREBOOT=`cat ~/.bashrc | grep 'transmission-daemon'`
		if [ -z "$TRREBOOT" ]
		then
			echo 'alias trreboot="/etc/init.d/transmission-daemon restart"' >> ~/.bashrc
			source ~/.bashrc
		fi
		clear
		if [ "$flexget" = "y" ] || [ "$flexget" = "yes" ] || [ "$flexget" = "Y" ] || [ "$flexget" = "YES" ] || [ "$flexet" = "Yes" ]
		then
			#start install flexget
			#http://download.flexget.com/unstable/FlexGet-1.0r3182.tar.gz
			$ONEKEY_ONLINE_INSTALL -y python-setuptools
			easy_install flexget
			mkdir .flexget

			#run deluge and config auto start on system start
			#config flexget crontab
			touch $ONEKEY_CRONTAB_ROOT
			ONEKEY_FLEXGET1=`cat /var/spool/cron/crontabs/root | grep '/usr/local/bin/flexget > /root/flexget.log 2>&1'`
			ONEKEY_FLEXGET2=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /root/.flexget/.config-lock'`
			ONEKEY_FLEXGET3=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /home/box123/rss/*'`
			if [ -n "$ONEKEY_FLEXGET1" ]
			then
				echo "${CYELLOW}Flexget定时运行已经设置  跳过$CEND"
			else
				echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
			fi
			if [ -n "$ONEKEY_FLEXGET2" ]
			then
				echo "${CYELLOW}Flexget防止自动锁设置已经配置   跳过$CEND"
			else
				echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
			fi
			if [ -n "$ONEKEY_FLEXGET3" ]
			then
				echo "${CYELLOW}定时清空Flexget RSS种子缓存已经设置   跳过$CEND"
			else
				echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
			fi
			#echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
			#echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
			#echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
			crontab $ONEKEY_CRONTAB_ROOT
			crontab -l

			cd $ONEKEY_FLEXGET_DIRECTORY/
			wget -q -O $ONEKEY_FLEXGET_DIRECTORY/config.yml $ONEKEY_DOWNLOAD_LINK/92/
			clear && echo "${CYELLOW}                        请输入你的RSS地址, 如果不想配置RSS请直接按 \"ENTER\" ，脚本会自行跳过$CEND"
			echo "${CQUESTION}请输入你的CHD RSS地址 :$CEND"
			read chdrss1
			echo "${CQUESTION}请输入你的CHD下载框地址 :$CEND"
			read chdrss2
			echo "${CQUESTION}请输入你的TTG RSS地址 :$CEND"
			read ttgrss1
			echo "${CQUESTION}请输入你的TTG小货车地址 :$CEND"
			read ttgrss2
			if [ $blockHDWing = "n" ]
			then
				echo "${CQUESTION}请输入你的HDWing RSS地址 :$CEND"
				read HDWingrss1
				echo "${CQUESTION}请输入你的HDWing下载框地址 :$CEND"
				read HDWingrss2
			else
				echo "${CWARNING}#############由于你选择了屏蔽HDWing网站，所以不做HDWing RSS配置#############$CEND"
			fi
			echo "${CQUESTION}请输入你的HDR RSS地址 :$CEND"
			read hdrrss1
			echo "${CQUESTION}请输入你的HDS RSS地址 :$CEND"
			read hdsrss1
			echo "${CQUESTION}请输入你的HDS下载框地址 :$CEND"
			read hdsrss2
			echo ""
			#modiry rss url and del no define variables
			if [ "$chdrss1" != "" ]
			then
				chdrss1=`echo "$chdrss1" | sed 's@\&@\\\&@g'`
				#modify CHD RSS url1 3 line
				sed -i 3,3s@rss:.*@"rss: $chdrss1\r"@ config.yml
				sed -i 21,21s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 2-20 line
				sed -i '2,21s/.*//' config.yml
			fi
			if [ "$chdrss2" != "" ]
			then
				chdrss2=`echo "$chdrss2" | sed 's@\&@\\\&@g'`
				#modify CHD RSS url2 22 line
				sed -i 23,23s@rss:.*@"rss: $chdrss2\r"@ config.yml
				sed -i 23,33s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 21-32 line
				sed -i '22,33s/.*//' config.yml
			fi
			if [ "$ttgrss1" != "" ]
			then
				ttgrss1=`echo "$ttgrss1" | sed 's@\&@\\\&@g'`
				#modify TTG url1 34 line
				sed -i 35,35s@rss:.*@"rss: $ttgrss1\r"@ config.yml
				sed -i 53,53s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 33-53 line
				sed -i '34,53s/.*//' config.yml
			fi
			if [ "$ttgrss2" != "" ]
			then
				ttgrss2=`echo "$ttgrss2" | sed 's@\&@\\\&@g'`
				#modify TTG url2 55 line
				sed -i 55,55s@rss:.*@"rss: $ttgrss2\r"@ config.yml
				sed -i 65,65s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 54-65 line
				sed -i '54,65s/.*//' config.yml
			fi
			if [ $blockHDWing = "n" ]
			then
				if [ "$HDWingrss1" != "" ]
				then
					HDWingrss1=`echo "$HDWingrss1" | sed 's@\&@\\\&@g'`
					#modify HDWing url1 67 line
					sed -i 67,67s@rss:.*@"rss: $HDWingrss1\r"@ config.yml
					sed -i 85,85s@trpasswd@"$trpasswd\r"@ config.yml
				else
					#del 66-85 line
					sed -i '66,85s/.*//' config.yml
				fi
				if [ "$HDWingrss2" != "" ]
				then
					HDWingrss2=`echo "$HDWingrss2" | sed 's@\&@\\\&@g'`
					#modify HDWing url2 87 line
					sed -i 87,87s@rss:.*@"rss: $HDWingrss2\r"@ config.yml
					sed -i 97,97s@trpasswd@"$trpasswd\r"@ config.yml
				else
					#del 86-97 line
					sed -i '86,97s/.*//' config.yml
				fi
			else
				#del 66-97 line
				sed -i '66,97s/.*//' config.yml
			fi
##########################################################################################
			if [ "$hdrrss1" != "" ]
			then
				hdrrss1=`echo "$hdrrss1" | sed 's@\&@\\\&@g'`
				#modify HDR url1 99 line
				sed -i 99,99s@rss:.*@"rss: $hdrrss1\r"@ config.yml
				sed -i 119,119s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 98-117 line
				sed -i '98,119s/.*//' config.yml
			fi
			if [ "$hdsrss1" != "" ]
			then
				hdsrss1=`echo "$hdsrss1" | sed 's@\&@\\\&@g'`
				#modify HDS url1 119 line
				sed -i 121,121s@rss:.*@"rss: $hdsrss1\r"@ config.yml
				sed -i 139,139s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 118-137 line
				sed -i '120,139s/.*//' config.yml
			fi
			if [ "$hdsrss2" != "" ]
			then
				hdsrss2=`echo "$hdsrss2" | sed 's@\&@\\\&@g'`
				#modify HDS url2 139 line
				sed -i 141,141s@rss:.*@"rss: $hdsrss2\r"@ config.yml
				sed -i 151,151s@trpasswd@"$trpasswd\r"@ config.yml
			else
				#del 138-149 line
				sed -i '140,151s/.*//' config.yml
			fi
			clear
			#del space line
			sed -i '/^$/d' config.yml
			#dos2unix
			dos2unix $ONEKEY_FLEXGET_DIRECTORY/config.yml
			sed -i 's/^M//g' config.yml
			sed -i 's/\\r//' config.yml&&clear
		fi
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                     Transmission安装结束$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= Transmission 登陆地址        :$CGREEN http://$OUR_IP_ADDRESS:9888 $CEND
		${CQUESTION}= Transmission 用户名          :$CGREEN $trname$CEND
		${CQUESTION}= Transmission 密码            :$CGREEN $trpasswd$CEND
		${CQUESTION}= Transmission 文件下载路径    :$CGREEN /home/box123/downloads$CEND
		${CQUESTION}= Transmission 种子监控目录    :$CGREEN /home/box123/trrss$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_ftp() {
		clear
		echo "${CYELLOW}开始按转发FTP...............................$CEND"
		sleep 2
		$ONEKEY_ONLINE_INSTALL -y proftpd
		sed -i s/"#DefaultRoot"/"DefaultRoot"/g /etc/proftpd/proftpd.conf
		/etc/init.d/proftpd restart
		clear
		echo "${CQUESTION}请输入一个用户名作为等FTP的用户名:$CEND"
		read ftpusername
		echo "${CQUESTION}请输入一个密码作为等FTP的密码:$CEND"
		read ftppassword
		clear && useradd $ftpusername
		touch $ONEKEY_USERPASS
		echo $ftpusername:$ftppassword >> $ONEKEY_USERPASS
		chpasswd < $ONEKEY_USERPASS
		rm -rf $ONEKEY_USERPASS
		if [ "$ftpusername" = "box123" ]
		then
			mkdir -p /home/$ftpusername
			chmod 777 /home/$ftpusername
		else
			mkdir -p /home/$ftpusername
			chmod 777 /home/$ftpusername
			ln -s $ONEKEY_NEWUSER_DIRECTORY/downloads/ /home/$ftpusername/
		fi
		sed -i "65 s/30/200/" /etc/proftpd/proftpd.conf
		/etc/init.d/proftpd restart&&clear
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   FTP安装结束$CEND
		${CQUESTION}==================================================================
		${CQUESTION}= FTP IP地址       :$CGREEN $OUR_IP_ADDRESS$CEND
		${CQUESTION}= FTP 端口         :$CGREEN 21$CEND
		${CQUESTION}= FTP 用户名       :$CGREEN $ftpusername$CEND
		${CQUESTION}= FTP 密码         :$CGREEN $ftppassword$CEND
		${CQUESTION}=$CGREEN ftp://$ftpusername:$ftppassword@$OUR_IP_ADDRESS/downloads$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_vpn() {
		clear
		echo "${CYELLOW}开始安装VPN...............................$CEND"
		sleep 2
		#Install PPTP VPN
		dpkg --purge remove pptpd
		apt-get --purge remove pptpd
		apt-get update
		clear
		echo "${CQUESTION}请输入一个用户名作为VPN的用户名:$CEND"
		read username
		echo "${CQUESTION}请输入一个密码作为VPN的密码:$CEND"
		read password
		clear
		$ONEKEY_ONLINE_INSTALL -y pptpd
		echo 1 > /proc/sys/net/ipv4/ip_forward
		echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
		iptables -A FORWARD -s 192.168.1.0/24 -j ACCEPT
		iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
		iptables-save > /etc/iptables-rules
		touch /etc/network/if-up.d/iptables
		cat > /etc/network/if-up.d/iptables << EOF
#!/bin/sh

iptables-restore < /etc/iptables-rules
chmod +x /etc/network/if-up.d/iptables
EOF
		PPTPD="/etc/pptpd.conf"
		CHAP="/etc/ppp/chap-secrets"
		PPTPD_OPTIONS="/etc/ppp/pptpd-options"
		rm -rf $PPTPD && touch $PPTPD
		cat > "$PPTPD" << EOF
option    /etc/ppp/pptpd-options
logwtmp
localip    192.168.1.1
remoteip    192.168.1.100-245
EOF
		rm -rf $CHAP && touch $CHAP
		echo "$username pptpd $password  \"*\"" >> $CHAP
		rm -rf $PPTPD_OPTIONS && touch $PPTPD_OPTIONS
		chmod 777 $PPTPD_OPTIONS
		cat > $PPTPD_OPTIONS << EOF
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
name pptpd
EOF
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   PPTPD VPN 安装结束$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= Your VPN IP 地址  :$CGREEN $OUR_IP_ADDRESS$CEND
		${CQUESTION}= PPTP VPN 帐户     :$CGREEN $username$CEND
		${CQUESTION}= PPTP VPN 密码     :$CGREEN $password$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_vg() {
		clear
		# Install VNC
		echo "${CYELLOW}开始安装VNC.................................$CEND"
		sleep 2
		#apt-get -q -y --force-yes install vnc4server xterm jwm mercurial libasound2-dev libcurl4-openssl-dev libnotify-dev libxt-dev libiw-dev mesa-common-dev autoconf2.13 yasm bzip2 libidl-dev zip
		$ONEKEY_ONLINE_INSTALL xinit gdm ubuntu-desktop -y
		$ONEKEY_ONLINE_INSTALL vnc4server -y
		wget ftp://ftp.uwsg.indiana.edu/linux/slackware/slackware-13.0/patches/source/mozilla-firefox/firefox-3.6.28.source.tar.bz2
		bzip2 -d firefox-3.6.28.source.tar.bz2 && tar -xvf firefox-3.6.28.source.tar
		cd mozilla-*
		./configure --enable-application=browser && make && make install && cd
		wget ftp://ftp.psu.ac.th/pub/adobe/flash/install_flash_player_10_linux.tar.gz
		tar xvzf install_flash_player_10_linux.tar.gz
		mkdir -p ~/.mozilla/plugins/
		cp libflashplayer.so ~/.mozilla/plugins/
		vncpasswd && vncserver && vncserver -kill :1
		XSTARTUP="/root/.vnc/xstartup"
		rm -rf $XSTARTUP && echo "" > $XSTARTUP
		cat > $XSTARTUP << EOF
#!/bin/sh

# Uncomment the following two lines for normal desktop:
# unset SESSION_MANAGER
# exec /etc/X11/xinit/xinitrc

#[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
#[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
xterm -geometry -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#x-window-manager &
gnome-session &
startjwm &
firefox --display=:1
EOF
		chmod +x $XSTARTUP
		VNCKJ="/etc/init.d/vncserver"
		vncserver && touch $VNCKJ && wget -q -O $VNCKJ $ONEKEY_DOWNLOAD_LINK/106/
		chmod +x $VNCKJ && update-rc.d vncserver defaults
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   VNC安装配置结束$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= Your VNC 地址    :$CGREEN http://$OUR_IP_ADDRESS:1$CEND
		${CQUESTION}= Your VNC 密码    :$CGREEN 你之前设置的密码$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_vnc() {
		clear
		# Install VNC
		echo "${CYELLOW}开始安装VNC.................................$CEND" && sleep 2
		$ONEKEY_ONLINE_INSTALL xinit gdm ubuntu-desktop vnc4server -y
		vncpasswd && vncserver && vncserver -kill :1
		XSTARTUP="/root/.vnc/xstartup"
		rm -rf $XSTARTUP && echo "" > $XSTARTUP
		cat > $XSTARTUP << EOF
#!/bin/sh

# Uncomment the following two lines for normal desktop:
# unset SESSION_MANAGER
# exec /etc/X11/xinit/xinitrc

#[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
#[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
xterm -geometry -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#x-window-manager &
gnome-session &
EOF
		chmod 755 $XSTARTUP
		vncserver
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   VNC安装配置结束$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= Your VNC 地址    :$CGREEN http://$OUR_IP_ADDRESS:1$CEND
		${CQUESTION}= Your VNC 密码    :$CGREEN 你之前设置的密码$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_ssh_proxy() {
		groupadd fanqiang
		clear
		echo "${CQUESTION}请输入一个用户名作为 SSH 代理的用户名:$CEND"
		read proxyusername
		echo "${CQUESTION}P请输入一个密码作为 SSH 代理的密码:$CEND"
		read proxypassword
		useradd -d /home/$proxyusername -m -g fanqiang -s /bin/false $proxyusername
		touch $ONEKEY_USERPASS
		echo $proxyusername:$proxypassword >> $ONEKEY_USERPASS
		chpasswd < $ONEKEY_USERPASS
		rm -rf $ONEKEY_USERPASS
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   SSH代理安装配置结束$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= SSH 代理 IP 地址  :$CGREEN $OUR_IP_ADDRESS$CEND
		${CQUESTION}= SSH 代理 帐户     :$CGREEN $proxyusername$CEND
		${CQUESTION}= SSH 代理 密码     :$CGREEN $proxypassword$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

change_time() {
		clear && echo "" && echo "" && echo ""
		echo "${CQUESTION}                              请等待，脚本运行中...............$CEND"
		rm -rf /etc/localtime
		cp /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime
		ntpdate time.windows.com
		hwclock -w
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND


		${CQUESTION}=                   时区修改结束 本服务器/VPS现在时区为中国大陆时区$CEND
		${CGREEN}$ONEKEY_TIME$CEND


		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

install_rapidleech() {
		$ONEKEY_ONLINE_INSTALL -y apache2
		$ONEKEY_ONLINE_INSTALL -y php5 php5-gd php5-cli
		sed -i 's@var/www@home/Rapidleech@' /etc/apache2/sites-available/default
		sed -i 's@var/www@home/Rapidleech@' /etc/apache2/sites-available/default-ssl
		/etc/init.d/apache2 restart
		wget -q -O /home/Rapidleech.tar.gz $ONEKEY_DOWNLOAD_LINK/42/
		cd /home
		tar xvf Rapidleech.tar.gz
		rm -rf Rapidleech.tar.gz
		chmod 777 Rapidleech/configs
		chmod 777 Rapidleech/files
		chmod 777 Rapidleech/configs/files.lst && cd
		getIpAddress
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND
		${CQUESTION}=                   Rapidleech 安装配置结束$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= Rapidleech 地址  :$CGREEN http://$OUR_IP_ADDRESS$CEND
		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

trflexget_config() {
		clear
		echo "${CYELLOW}开始一键配置Tranmission的Flexget RSS............................$CEND"
		ONEKEY_FLEXGET_FIND="/var/tmp/flexget.txt"
		ONEKEY_FLEXGET5=`find / -name FlexGet* | grep -s "FlexGet" > $ONEKEY_FLEXGET_FIND`&&sleep 2
		ONEKEY_FLEXGET6=`cat /var/tmp/flexget.txt | grep 'FlexGet'`
		sleep 2 && touch $ONEKEY_FLEXGET_FIND
		echo "" > $ONEKEY_FLEXGET_FIND
		if [ -n "$ONEKEY_FLEXGET6" ]
		then
			clear&&echo "${CYELLOW}系统已安装Flexget  直接配置Flexget$CEND"&&sleep 3
		else
			clear&&echo "${CYELLOW}系统未安装Flexget  先进行安装Flexget$CEND"&&sleep 3
			$ONEKEY_ONLINE_INSTALL -y python-setuptools
			easy_install flexget
		fi
		#download config.yml and config it
		cd $ONEKEY_FLEXGET_DIRECTORY/
		wget -q -O $ONEKEY_FLEXGET_DIRECTORY/config.yml $ONEKEY_DOWNLOAD_LINK/11/ && clear
		#start install flexget
		#http://download.flexget.com/unstable/FlexGet-1.0r3182.tar.gz
		#$ONEKEY_ONLINE_INSTALL -y python-setuptools
		#easy_install flexget
		mkdir .flexget
		#run deluge and config auto start on system start
		#config flexget crontab
		touch $ONEKEY_CRONTAB_ROOT
		ONEKEY_FLEXGET1=`cat /var/spool/cron/crontabs/root | grep '/usr/local/bin/flexget > /root/flexget.log 2>&1'`
		ONEKEY_FLEXGET2=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /root/.flexget/.config-lock'`
		ONEKEY_FLEXGET3=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /home/box123/rss/*'`
		if [ -n "$ONEKEY_FLEXGET1" ]
		then
			echo "${CYELLOW}Flexget定时运行已经设置  跳过$CEND"
		else
			echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
		fi
		if [ -n "$ONEKEY_FLEXGET2" ]
		then
			echo "${CYELLOW}Flexget防止自动锁设置已经配置   跳过$CEND"
		else
			echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
		fi
		if [ -n "$ONEKEY_FLEXGET3" ]
		then
			echo "${CYELLOW}定时清空Flexget RSS种子缓存已经设置   跳过$CEND"
		else
			echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
		fi
		#echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
		#echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
		#echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
		crontab $ONEKEY_CRONTAB_ROOT
		crontab -l&&clear
		cd $ONEKEY_FLEXGET_DIRECTORY/
		wget -q -O $ONEKEY_FLEXGET_DIRECTORY/config.yml $ONEKEY_DOWNLOAD_LINK/92/ && clear
		echo "${CQUESTION}请输入你的Transmission登陆帐号:$CEND"
		read trname
		echo "${CQUESTION}请输入你的Transmission登陆密码:$CEND"
		read trpasswd2
		clear
		echo "${CYELLOW}                        请输入你的RSS地址, 如果不想配置RSS请直接按 \"ENTER\" ，脚本会自行跳过$CEND"
		echo "${CQUESTION}请输入你的CHD RSS地址 :$CEND"
		read chdrss1
		echo "${CQUESTION}请输入你的CHD下载框地址 :$CEND"
		read chdrss2
		echo "${CQUESTION}请输入你的TTG RSS地址 :$CEND"
		read ttgrss1
		echo "${CQUESTION}请输入你的TTG小货车地址 :$CEND"
		read ttgrss2
		if [ $blockHDWing = "n" ]
		then
			echo "${CQUESTION}请输入你的HDWing RSS地址 :$CEND"
			read HDWingrss1
			echo "${CQUESTION}请输入你的HDWing下载框地址 :$CEND"
			read HDWingrss2
		else
			echo "${CWARNING}#############由于你选择了屏蔽HDWing网站，所以不做HDWing RSS配置#############$CEND"
		fi
		echo "${CQUESTION}请输入你的HDR RSS地址 :$CEND"
		read hdrrss1
		echo "${CQUESTION}请输入你的HDS RSS地址 :$CEND"
		read hdsrss1
		echo "${CQUESTION}请输入你的HDS下载框地址 :$CEND"
		read hdsrss2
		echo ""
		#modiry rss url and del no define variables
		if [ "$chdrss1" != "" ]
		then
			chdrss1=`echo "$chdrss1" | sed 's@\&@\\\&@g'`
			#modify CHD RSS url1 3 line
			sed -i 3,3s@rss:.*@"rss: $chdrss1\r"@ config.yml
			sed -i 20,20s@box123@"$trname\r"@ config.yml
			sed -i 21,21s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 2-20 line
			sed -i '2,21s/.*//' config.yml
		fi
		if [ "$chdrss2" != "" ]
		then
			chdrss2=`echo "$chdrss2" | sed 's@\&@\\\&@g'`
			#modify CHD RSS url2 22 line
			sed -i 23,23s@rss:.*@"rss: $chdrss2\r"@ config.yml
			sed -i 32,32s@box123@"$trname\r"@ config.yml
			sed -i 33,33s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 21-32 line
			sed -i '22,33s/.*//' config.yml
		fi
		if [ "$ttgrss1" != "" ]
		then
			ttgrss1=`echo "$ttgrss1" | sed 's@\&@\\\&@g'`
			#modify TTG url1 34 line
			sed -i 35,35s@rss:.*@"rss: $ttgrss1\r"@ config.yml
			sed -i 54,54s@box123@"$trname\r"@ config.yml
			sed -i 53,53s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 33-53 line
			sed -i '34,53s/.*//' config.yml
		fi
		if [ "$ttgrss2" != "" ]
		then
			ttgrss2=`echo "$ttgrss2" | sed 's@\&@\\\&@g'`
			#modify TTG url2 55 line
			sed -i 55,55s@rss:.*@"rss: $ttgrss2\r"@ config.yml
			sed -i 64,64s@box123@"$trname\r"@ config.yml
			sed -i 65,65s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 54-65 line
			sed -i '54,65s/.*//' config.yml
		fi
		if [ $blockHDWing = "n" ]
		then
			if [ "$HDWingrss1" != "" ]
			then
				HDWingrss1=`echo "$HDWingrss1" | sed 's@\&@\\\&@g'`
				#modify HDWing url1 67 line
				sed -i 67,67s@rss:.*@"rss: $HDWingrss1\r"@ config.yml
				sed -i 84,84s@box123@"$trname\r"@ config.yml
				sed -i 85,85s@trpasswd@"$trpasswd2\r"@ config.yml
			else
				#del 66-85 line
				sed -i '66,85s/.*//' config.yml
			fi

			if [ "$HDWingrss2" != "" ]
			then
				HDWingrss2=`echo "$HDWingrss2" | sed 's@\&@\\\&@g'`
				#modify HDWing url2 87 line
				sed -i 87,87s@rss:.*@"rss: $HDWingrss2\r"@ config.yml
				sed -i 96,96s@box123@"$trname\r"@ config.yml
				sed -i 97,97s@trpasswd@"$trpasswd2\r"@ config.yml
			else
				#del 86-97 line
				sed -i '86,97s/.*//' config.yml
			fi
		else
			#del 66-97 line
			sed -i '66,97s/.*//' config.yml
		fi
##########################################################################################
		if [ "$hdrrss1" != "" ]
		then
			hdrrss1=`echo "$hdrrss1" | sed 's@\&@\\\&@g'`
			#modify HDR url1 99 line
			sed -i 99,99s@rss:.*@"rss: $hdrrss1\r"@ config.yml
			sed -i 118,118s@box123@"$trname\r"@ config.yml
			sed -i 119,119s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 98-117 line
			sed -i '98,119s/.*//' config.yml
		fi
		if [ "$hdsrss1" != "" ]
		then
			hdsrss1=`echo "$hdsrss1" | sed 's@\&@\\\&@g'`
			#modify HDS url1 119 line
			sed -i 121,121s@rss:.*@"rss: $hdsrss1\r"@ config.yml
			sed -i 138,138s@box123@"$trname\r"@ config.yml
			sed -i 139,139s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 118-137 line
			sed -i '120,139s/.*//' config.yml
		fi
		if [ "$hdsrss2" != "" ]
		then
			hdsrss2=`echo "$hdsrss2" | sed 's@\&@\\\&@g'`
			#modify HDS url2 139 line
			sed -i 141,141s@rss:.*@"rss: $hdsrss2\r"@ config.yml
			sed -i 150,150s@box123@"$trname\r"@ config.yml
			sed -i 151,151s@trpasswd@"$trpasswd2\r"@ config.yml
		else
			#del 138-149 line
			sed -i '140,151s/.*//' config.yml
		fi
		clear
		#del space line
		sed -i '/^$/d' config.yml
		#dos2unix
		dos2unix $ONEKEY_FLEXGET_DIRECTORY/config.yml
		sed -i 's/^M//g' config.yml
		sed -i 's/\\r//' config.yml&&clear
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND

		${CQUESTION}=                   Tranmission RSS 一键配置结束 $CEND

		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

deflexget_config() {
		#download config.yml and config it
		ONEKEY_FLEXGET_FIND="/var/tmp/flexget.txt"
		touch $ONEKEY_FLEXGET_FIND
		echo "" > $ONEKEY_FLEXGET_FIND
		ONEKEY_FLEXGET5=`find / -name FlexGet* | grep -s "FlexGet" > $ONEKEY_FLEXGET_FIND`&&sleep 2
		ONEKEY_FLEXGET6=`cat /var/tmp/flexget.txt | grep 'FlexGet'`
		if [ -n "$ONEKEY_FLEXGET6" ]
		then
			clear&&echo "${CYELLOW}系统已安装Flexget  直接配置Flexget$CEND"&&sleep 3
		else
			clear&&echo "${CYELLOW}系统未安装Flexget  先进行安装Flexget$CEND"&&sleep 3
			$ONEKEY_ONLINE_INSTALL -y python-setuptools
			easy_install flexget
		fi
		clear&&echo "${CYELLOW}开始配置Deluge的Flexget 0_0$CEND"&&sleep 2
		#run deluge and config auto start on system start
		#config flexget crontab
		touch $ONEKEY_CRONTAB_ROOT
		ONEKEY_FLEXGET1=`cat /var/spool/cron/crontabs/root | grep '/usr/local/bin/flexget > /root/flexget.log 2>&1'`
		ONEKEY_FLEXGET2=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /root/.flexget/.config-lock'`
		ONEKEY_FLEXGET3=`cat /var/spool/cron/crontabs/root | grep 'rm -rf /home/box123/rss/*'`
		if [ -n "$ONEKEY_FLEXGET1" ]
		then
			echo "${CYELLOW}Flexget定时运行已经设置  跳过$CEND"
		else
			echo "*/3 * * * * /usr/local/bin/flexget > /root/flexget.log 2>&1" >> $ONEKEY_CRONTAB_ROOT
		fi
		if [ -n "$ONEKEY_FLEXGET2" ]
		then
			echo "${CYELLOW}Flexget防止自动锁设置已经配置   跳过$CEND"
		else
			echo "*/1 * * * * rm -rf /root/.flexget/.config-lock" >> $ONEKEY_CRONTAB_ROOT
		fi
		if [ -n "$ONEKEY_FLEXGET3" ]
		then
			echo "${CYELLOW}定时清空Flexget RSS种子缓存已经设置   跳过$CEND"
		else
			echo "*/20 * * * * rm -rf /home/box123/rss/*" >> $ONEKEY_CRONTAB_ROOT
		fi
		crontab $ONEKEY_CRONTAB_ROOT
		crontab -l&&clear
		mkdir -p /root/.flexget && cd $ONEKEY_FLEXGET_DIRECTORY/
		wget -q -O $ONEKEY_FLEXGET_DIRECTORY/config.yml $ONEKEY_DOWNLOAD_LINK/11/
		clear
		echo "${CYELLOW}		请输入你的RSS地址, 如果不想配置RSS请直接按 \"ENTER\" ，脚本会自行跳过$CEND"
		echo "${CQUESTION}请输入你的CHD RSS地址 :$CEND"
		read chdrss1
		echo "${CQUESTION}请输入你的CHD下载框地址 :$CEND"
		read chdrss2
		echo "${CQUESTION}请输入你的TTG RSS地址 :$CEND"
		read ttgrss1
		echo "${CQUESTION}请输入你的TTG小货车地址 :$CEND"
		read ttgrss2
		if [ $blockHDWing = "n" ]
		then
			echo "${CQUESTION}请输入你的HDWing RSS地址 :$CEND"
			read HDWingrss1
			echo "${CQUESTION}请输入你的HDWing下载框地址 :$CEND"
			read HDWingrss2
		else
			echo "${CWARNING}#############由于你选择了屏蔽HDWing网站，所以不做HDWing RSS配置#############$CEND"
		fi
		echo "${CQUESTION}请输入你的HDR RSS地址 :$CEND"
		read hdrrss1
		echo "${CQUESTION}请输入你的HDS RSS地址 :$CEND"
		read hdsrss1
		echo "${CQUESTION}请输入你的HDS下载框地址 :$CEND"
		read hdsrss2
		echo ""
		#modiry rss url and del no define variables
		if [ "$chdrss1" != "" ]
		then
			chdrss1=`echo "$chdrss1" | sed 's@\&@\\\&@g'`
			#modify CHD RSS url1 3 line
			sed -i 3,3s@rss:.*@"rss: $chdrss1\r"@ config.yml
		else
			#del 2-20 line
			sed -i '2,21s/.*//' config.yml
		fi
		if [ "$chdrss2" != "" ]
		then
			chdrss2=`echo "$chdrss2" | sed 's@\&@\\\&@g'`
			#modify CHD RSS url2 22 line
			sed -i 23,23s@rss:.*@"rss: $chdrss2\r"@ config.yml
		else
			#del 21-32 line
			sed -i '22,33s/.*//' config.yml
		fi
		if [ "$ttgrss1" != "" ]
		then
			ttgrss1=`echo "$ttgrss1" | sed 's@\&@\\\&@g'`
			#modify TTG url1 34 line
			sed -i 35,35s@rss:.*@"rss: $ttgrss1\r"@ config.yml
		else
			#del 33-53 line
			sed -i '34,53s/.*//' config.yml
		fi
		if [ "$ttgrss2" != "" ]
		then
			ttgrss2=`echo "$ttgrss2" | sed 's@\&@\\\&@g'`
			#modify TTG url2 55 line
			sed -i 55,55s@rss:.*@"rss: $ttgrss2\r"@ config.yml
		else
			#del 54-65 line
			sed -i '54,65s/.*//' config.yml
		fi
		if [ $blockHDWing = "n" ]
		then
			if [ "$HDWingrss1" != "" ]
			then
				HDWingrss1=`echo "$HDWingrss1" | sed 's@\&@\\\&@g'`
				#modify HDWing url1 67 line
				sed -i 67,67s@rss:.*@"rss: $HDWingrss1\r"@ config.yml
			else
				#del 66-85 line
				sed -i '66,85s/.*//' config.yml
			fi
			if [ "$HDWingrss2" != "" ]
			then
				HDWingrss2=`echo "$HDWingrss2" | sed 's@\&@\\\&@g'`
				#modify HDWing url2 87 line
				sed -i 87,87s@rss:.*@"rss: $HDWingrss2\r"@ config.yml
			else
				#del 86-97 line
				sed -i '86,97s/.*//' config.yml
			fi
			else
				#del 66-97 line
				sed -i '66,97s/.*//' config.yml
			fi
##########################################################################################
		if [ "$hdrrss1" != "" ]
		then
			hdrrss1=`echo "$hdrrss1" | sed 's@\&@\\\&@g'`
			#modify HDR url1 99 line
			sed -i 99,99s@rss:.*@"rss: $hdrrss1\r"@ config.yml
		else
			#del 98-117 line
			sed -i '98,118s/.*//' config.yml
		fi
		if [ "$hdsrss1" != "" ]
		then
			hdsrss1=`echo "$hdsrss1" | sed 's@\&@\\\&@g'`
			#modify HDS url1 119 line
			sed -i 120,120s@rss:.*@"rss: $hdsrss1\r"@ config.yml
		else
			#del 118-137 line
			sed -i '119,138s/.*//' config.yml
		fi
		if [ "$hdsrss2" != "" ]
		then
			hdsrss2=`echo "$hdsrss2" | sed 's@\&@\\\&@g'`
			#modify HDS url2 139 line
			sed -i 140,140s@rss:.*@"rss: $hdsrss2\r"@ config.yml
		else
			#del 138-149 line
			sed -i '139,150s/.*//' config.yml
		fi
		clear
		#del space line
		sed -i '/^$/d' config.yml
		#dos2unix
		dos2unix $ONEKEY_FLEXGET_DIRECTORY/config.yml
		sed -i 's/\\r//' config.yml
		echo "${CYELLOW}请稍等,脚本运行中...";sleep 3;clear;echo "${CYELLOW}请等待5秒 ,脚本运行中...$CEND";echo "${CYELLOW}5 .........$CEND";sleep 1;echo "${CYELLOW}4 ........$CEND";sleep 1;echo "${CYELLOW}3 ......$CEND";sleep 1;echo "${CYELLOW}2 ....$CEND";sleep 1;echo "${CYELLOW}1 ...GO$CEND";sleep 1;clear
		ONEKEY_DELUGE_PASS=`awk -F ':' '{print $2}' /root/.config/deluge/auth`
		ONEKEY_DELUGE_USERNAME=`awk -F ':' '{print $1}' /root/.config/deluge/auth`
		sed -i s/"pass: *"/"pass: $ONEKEY_DELUGE_PASS"/g config.yml
		clear && cat << EOF
		${CQUESTION}==================================================================$CEND

		${CQUESTION}=                   Deluge RSS 一键配置结束 $CEND

		${CQUESTION}==================================================================$CEND
		${CQUESTION}= 感谢使用 SEEDBOX-军团 一键安装脚本$CEND
		${CQUESTION}= SEEDBOX-军团 网址 $CGREEN$ONEKEY_WEB_LINK$CEND
		${CQUESTION}==================================================================$CEND
EOF
}

#===================================
if [ -n "$ONEKEY_UBUNTU_VERSION" ] || [ -n "$ONEKEY_DEBIAN_VERSION" ]
then
	if [ -n "$ONEKEY_OPENDIR" ]
	then
		echo "${CQUESTION}文件打开数已经破解,若没有生效请重启系统一次$CEND"&&sleep 1&&clear
	else
		sed -i '/# End of file/d' /etc/security/limits.conf
		cat >> /etc/security/limits.conf << EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
		echo "# End of file" >> /etc/security/limits.conf
		cat >> /etc/sysctl.conf << EOF
fs.file-max=65535
EOF
		echo "session required pam_limits.so" >> /etc/pam.d/common-session
		echo "ulimit -SHn 65535" >> /etc/profile
		/sbin/sysctl -p&&clear
	fi
#================================================================
	rm -rf /root/.vimrc&&wget -q -O vim.tar $ONEKEY_DOWNLOAD_LINK/86/
	cd /root/&&tar -xf vim.tar&&rm -rf vim.tar
	$ONEKEY_ONLINE_INSTALL curl dos2unix vim -y
	clear && cat << EOF
${CBLUE}$ONEKEY_LOGO$CEND
EOF
	sleep 3
	men
else
	#exit shell
	sleep 2;clear
	echo "${CQUESTION}对不起!!!!! 你的服务器不是$CEND ${CGREEN}Ubuntu 或者 Debian.........................$CEND"
	echo "Bye Bye"
	echo "${CQUESTION}Shell 脚本运行结束时间: $CGREEN$ONEKEY_TIME$CEND"
	exit
fi
