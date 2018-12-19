#!/bin/bash

echo ""
echo " ========================================================= "
echo " \                 Linux信息搜集脚本                     / "
echo " ========================================================= "
echo " # author：al0ne                    "
echo " # https://github.com/al0ne/LinuxCheck     "
echo -e "\n"
source /etc/os-release
if ag -V > /dev/null 2>&1; then
    echo -n
else
    case ${ID} in
        debian|ubuntu|devuan)
            apt-get install silversearcher-ag > /dev/null 2>&1
                ;;
        centos|fedora|rhel)
            yum install silversearcher-ag > /dev/null 2>&1
                ;;
                        *)
            exit 1
                ;;
    esac

fi
if [ $UID -ne 0 ]; then
    echo "请使用root权限运行！！！"
    exit 1
fi
echo -e "\e[00;31m[+]系统信息\e[00m"
#当前用户
echo -e "USER:\t\t" `whoami` 2>/dev/null
#版本信息
echo -e "OS Version:\t"  ${PRETTY_NAME}
#主机名
echo -e "Hostname: \t" `hostname -s`
#uptime
echo -e "uptime: \t" `uptime | awk -F ',' '{print $1}'`
#cpu信息
echo -e "CPU info:\t" `cat /proc/cpuinfo|ag -o '(?<=model name\t: ).*'|head -n 1`
# ipaddress
ipaddress=`ifconfig|ag -o '(?<=inet addr:)\d+\.\d+\.\d+\.\d+'|ag -v '127.0.0.1'` >/dev/null 2>&1
echo -e "IPADDR:\t\t${ipaddress}"|sed ":a;N;s/\n/ /g;ta"
echo -e "\n"

echo -e "\e[00;31m[+]CPU使用率:  \e[00m"
awk '$0 ~/cpu[0-9]/' /proc/stat 2>/dev/null  | while read line
do
    echo "$line" | awk '{total=$2+$3+$4+$5+$6+$7+$8;free=$5;\
        print$1" Free "free/total*100"%",\
        "Used " (total-free)/total*100"%"}'
done
echo -e "\n"
#CPU占用
cpu=`ps aux|grep -v ^'USER'|sort -rn -k3|head -10` 2>/dev/null
echo -e "\e[00;31m[+]CPU TOP10:  \e[00m\n${cpu}\n"
#内存占用
echo -e "\e[00;31m[+]内存占用\e[00m"
free -mh
echo -e "\n"
#剩余空间
echo -e "\e[00;31m[+]剩余空间\e[00m"
df -mh
echo -e "\n"
echo -e "\e[00;31m[+]硬盘挂载\e[00m"
cat /etc/fstab|ag -v "#"|awk '{print $1,$2,$3}'
echo -e "\n"
#ifconfig
echo -e "\e[00;31m[+]ifconfig\e[00m"
/sbin/ifconfig -a
echo -e "\n"
#网络流量
echo -e "\e[00;31m[+]网络流量 \e[00m"
echo "Interface    ByteRec   PackRec   ByteTran   PackTran"
awk   ' NR>2' /proc/net/dev  | while read line
do
    echo "$line" | awk -F ':' '{print "  "$1"  " $2}' |\
    awk '{print $1"   "$2 "    "$3"   "$10"  "$11}'
done
echo -e "\n"
#端口监听
echo -e "\e[00;31m[+]端口监听\e[00m"
netstat -tulpen|ag 'tcp|udp.*' --nocolor
echo -e "\n"
#网络连接
echo -e "\e[00;31m[+]网络连接\e[00m"
netstat -antop|ag ESTAB --nocolor
echo -e "\n"
#路由表
echo -e "\e[00;31m[+]路由表\e[00m"
/sbin/route -nee
echo -e "\n"
#DNS
echo -e "\e[00;31m[+]DNS Server\e[00m"
cat /etc/resolv.conf|ag -o '\d+\.\d+\.\d+\.\d+' --nocolor
echo -e "\n"
#crontab
echo -e "\e[00;31m[+]Crontab\e[00m"
crontab -u root -l|ag -v '#' --nocolor
ls -al /etc/cron.*/*
echo -e "\n"
#env
echo -e "\e[00;31m[+]env\e[00m"
env
echo -e "\n"
#passwd信息
echo -e "\e[00;31m[+]可登陆用户\e[00m"
cat /etc/passwd|ag -v 'nologin$|false$'
echo -e "passwd文件修改日期:" `stat /etc/passwd|ag -o '(?<=Modify: ).*' --nocolor`
echo -e "\n"
echo -e "\e[00;31m[+]sudoers(请注意NOPASSWD)\e[00m" 
cat /etc/sudoers|ag -v '#'|sed -e '/^$/d'|ag ALL --nocolor
echo -e "\n"
#防火墙
echo -e "\e[00;31m[+]IPTABLES防火墙\e[00m"
iptables -L
echo -e "\n"
#登陆信息
echo -e "\e[00;31m[+]登录信息\e[00m"
w
echo -e "\n"
last
echo -e "\n"
lastlog
echo "登陆ip:" `ag -a accepted /var/log/auth.*|ag -o '\d+\.\d+\.\d+\.\d+'|sort|uniq`
echo -e "\n"
#运行服务
echo -e "\e[00;31m[+]Service \e[00m"
case ${ID} in
    debian|ubuntu|devuan)
        service --status-all |ag -Q '+' --nocolor
            ;;
    centos|fedora|rhel)
        service --status-all |ag -Q 'is running' --nocolor
            ;;
                    *)
     	exit 1
            ;;
   esac
echo -e "\n"
#查看history文件
echo -e "\e[00;31m[+]History\e[00m"
ls -la ~/.*_history; ls -la /root/.*_history
echo -e "\n"
cat ~/.*history|ag '[12](?:[0-9]{1,2})?\.[12](?:[0-9]{1,2})?\.[12](?:[0-9]{1,2})?\.[12](?:[0-9]{1,2})?|http://'
echo -e "\n"
#HOSTS
echo -e "\e[00;31m[+]/etc/hosts \e[00m"
cat /etc/hosts
echo -e "\n"
#/etc/profile
echo -e "\e[00;31m[+]/etc/profile \e[00m"
cat /etc/profile|ag -v '#'
echo -e "\n"
#~/.bash_profile
echo -e "\e[00;31m[+]~/.bash_profile \e[00m"
cat ~/.bash_profile|ag -v '#'
echo -e "\n"
#~/.bashrc
echo -e "\e[00;31m[+]~/.bashrc \e[00m"
cat ~/.bashrc|ag -v '#'
echo -e "\n"
#tmp目录
echo -e "\e[00;31m[+]/tmp \e[00m"
ls /tmp -al
echo -e "\n"
#lsof -L1
echo -e "\e[00;31m[+]lsof -L1 \e[00m"
lsof +L1
echo -e "\n"
#近7天改动
echo -e "\e[00;31m[+]近七天文件改动 \e[00m"
find /etc /bin /sbin /dev /root/ /home /tmp /opt -mtime -7|ag -v 'cache|vim'
echo -e "\n"
#大文件>200mb
echo -e "\e[00;31m[+]大文件>200mb \e[00m"
find / -size +200M -print  2>/dev/null|xargs -i{} ls -alh {}
echo -e "\n"
#lsmod 查看模块
echo -e "\e[00;31m[+]lsmod模块\e[00m"
sudo lsmod
echo -e "\n"
#检查ssh key
echo -e "\e[00;31m[+]SSH key\e[00m"
sshkey=${HOME}/.ssh/authorized_keys
if [ -e "${sshkey}" ]; then 
    cat ${sshkey}
else
    echo -e "SSH key文件不存在\n"
fi 
echo -e "\n"

rkhuntercheck()
{
rkhunter='/tmp/rkhunter-1.4.6/files/rkhunter'
if ${rkhunter} > /dev/null 2>&1; then
    ${rkhunter} --checkall --sk|ag -v 'OK|Not found|None found'
else
    wget 'https://astuteinternet.dl.sourceforge.net/project/rkhunter/rkhunter/1.4.6/rkhunter-1.4.6.tar.gz' -O /tmp/rkhunter.tar.gz > /dev/null 2>&1
    cd /tmp
    tar -zxvf rkhunter.tar.gz > /dev/null 2>&1
    ${rkhunter} --checkall --sk|ag -v 'OK|Not found|None found'

fi  
}
ping -c 1 114.114.114.114 > /dev/null 2>&1
if [ $? -eq 0 ];then
    echo -e "\e[00;31m[+]RKhunter\e[00m"
    rkhuntercheck
else
    echo -e '\n'
fi