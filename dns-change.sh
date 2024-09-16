#!/bin/bash

# Author : 1Stream
# Website : https://1stream.icu

if [ $1 != 'restore' ];then
    DNS1=$1
    DNS2=$2
fi

function get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
function Welcome(){
    echo -e '正在检测您的操作系统...'
    echo -e '您确定要使用下面的DNS地址吗？'
    echo -e '主DNS: '$DNS1''
    if [ "$DNS2" != '' ]; then
        echo -e '备DNS: '$DNS2''
    fi
    echo
    read -p "是否使用TCP DNS (y/N):" tcp
    if [[ -n "${tcp}" ]]; then
        if [[ "$tcp" == 'y' ]] || [[ "$tcp" == 'Y' ]]; then
            echo -e '使用TCP DNS'
        fi
    fi
    echo -e '请按任意键继续，如有配置错误请使用 Ctrl+C 退出。'
    char=`get_char`
}
function ChangeDNS(){
    echo -e '尝试关闭NetworkManager的DNS功能'
    echo -e "[main]\ndns=none" > /etc/NetworkManager/conf.d/no-dns.conf
    systemctl restart NetworkManager.service
    echo -e '尝试关闭netconfig的DNS功能'
    sed -i 's/^.*NETCONFIG_DNS_POLICY.*/NETCONFIG_DNS_POLICY=\"\"/g' /etc/sysconfig/network/config
    echo -e '尝试关闭resolvconf和rdnssd'
    systemctl disable --now resolvconf.service
    systemctl disable --now rdnssd.service
    echo -e '尝试关闭systemd-resolved'
    systemctl disable --now systemd-resolved.service
    echo -e '尝试删除resolv.conf'
    rm /etc/resolv.conf
    echo -e '重新写入resolv.conf'
    echo -e "nameserver $DNS1\n" > /etc/resolv.conf
    if [ "$DNS2" != '' ]; then
        echo -e "nameserver $DNS2" >> /etc/resolv.conf
    fi
    echo
    echo -e '感谢您的使用, 由于脚本执行了破坏性操作，执行脚本文件时使用参数 restore将恢复dns为8.8.8.8/1.1.1.1'
}
function RestoreDNS(){
    echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
    echo
    echo -e 'DNS配置文件恢复完成。'
}
function addDNS(){
    Welcome
    ChangeDNS
}
if [ $1 != 'restore' ];then
    addDNS
elif [ $1 == 'restore' ];then
    RestoreDNS
else
    echo '用法错误！'
fi
