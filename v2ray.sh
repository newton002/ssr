#!/bin/bash
# 一键安装 v2ray （ws+nginx+tls）和简单的可视化流量统计页面
end() {
    err="启动失败或安装失败，请检查或重新安装！"
    systemctl enable nginx php7.2-fpm
    systemctl restart nginx php7.2-fpm 
    service v2ray start
    ps -fe | grep nginx |grep -v grep
    nginx_status=$?
    ps -fe | grep php-fpm |grep -v grep
    php_status=$?
    ps -fe | grep v2ray |grep -v grep
    v2ray_status=$?
    if [ $nginx_status -eq 0 ] && [ $php_status -eq 0 ] && [ $v2ray_status -eq 0 ];then
        whiptail --backtitle "九四の記" --msgbox "安装完成！\n\n地址：$domain\n端口：443\nUUID：$UUID\nAlterId：8\n加密方式：none\n传输协议：ws\n路径：/\n底层安全传输：TLS\n\n可用 v2rayN 导出 config.json\n\n流量统计、网速可访问 https://$domain 查看（流量统计在重启 v2ray 后清零）。\n\n相关命令、路径\nv2ray 命令：service v2ray start|stop|status|reload|restart|force-reload\nv2ray 配置路径：/etc/v2ray\nnginx 命令：systemctl start|stop|enable|disable nginx\nnginx 安装路径：/etc/nginx\nphp 命令：systemctl start|stop|enable|disable php7.2-fpm\nphp 安装路径：/etc/php" 30 80
        clear
        exit 0
    else
        if [ $nginx_status -ne 0 ];then
            whiptail --backtitle "九四の記" --msgbox "nginx $err" 15 60
            clear && exit 1
        elif [ $php_status -ne 0 ];then
            whiptail --backtitle "九四の記" --msgbox "php $err" 15 60
            clear && exit 1
        elif [ $v2ray_status -ne 0 ];then
            whiptail --backtitle "九四の記" --msgbox "v2ray $err" 15 60
            clear && exit 1
        fi
    fi
    exit 0
}
set_web() {
    echo "<?php
    error_reporting(0);
    for(\$i=0; \$i<=1; \$i++) {
        \$down[\$i] = shell_exec(\"/usr/bin/v2ray/v2ctl api --server=127.0.0.1:10085 StatsService.GetStats 'name:\\\"user>>>i@$domain>>>traffic>>>downlink\\\" reset: false'  | grep value | awk -F:' ' '{print \$2}'\");
        \$up[\$i] = shell_exec(\"/usr/bin/v2ray/v2ctl api --server=127.0.0.1:10085 StatsService.GetStats 'name:\\\"user>>>i@$domain>>>traffic>>>uplink\\\" reset: false'  | grep value | awk -F:' ' '{print \$2}'\");
        sleep(1);
    }
    function formatsize(\$size) {
        if(\$size >= 1073741824) {
            \$size = round(\$size / 1073741824 * 100) / 100 . ' GB';
        } elseif(\$size >= 1048576) {
            \$size = round(\$size / 1048576 * 100) / 100 . ' MB';
        } elseif(\$size >= 1024) {
            \$size = round(\$size / 1024 * 100) / 100 . ' KB';
        } else {
            \$size = \$size . ' B';
        }
        return \$size;
    }
    \$downspeed = formatsize(\$down[1] - \$down[0]);
    \$upspeed = formatsize(\$up[1] - \$up[0]);
    \$downtotal = formatsize(\$down[1]);
    \$uptotal = formatsize(\$up[1]);
    if (isset(\$_GET['act'])) {
        if (\$_GET['act'] == 'rt')
        echo \"<div class=\\\"total\\\"><div class=\\\"left\\\">Download total<hr></div><div class=\\\"right\\\">\".\$downtotal.\"</div></div>\";
        echo \"<div class=\\\"total\\\"><div class=\\\"left\\\">Upload total<hr></div><div class=\\\"right\\\">\".\$uptotal.\"</div></div>\";
        echo \"<div class=\\\"speed\\\"><div class=\\\"left\\\">Download speed<hr></div><div class=\\\"right\\\">\".\$downspeed.\"/s</div></div>\";
        echo \"<div class=\\\"speed\\\"><div class=\\\"left\\\">Upload speed<hr></div><div class=\\\"right\\\">\".\$upspeed.\"/s</div></div>\";
        exit;
    } ?>
    <html lang=\"en\">
        <head>
            <meta charset=\"utf-8\" />
            <meta http-equiv=\"X-UA-Compatible\" content=\"IE=Edge,chrome=1\">
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1, user-scalable=no\" />
            <title>Network Monitoring</title>
            <style type=\"text/css\">
                body {
                    -webkit-touch-callout: none;
                    -webkit-user-select: none;
                    -khtml-user-select: none;
                    -moz-user-select: none;
                    -ms-user-select: none;
                    user-select: none;
                    font-size: 28px;
                    background-image: url(\"data:image/png;base64,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\"); background-repeat: repeat;
                }
                dot {
                    display: inline-block;
                    height: 1em;
                    line-height: 1;
                    text-align: left;
                    vertical-align: -.25em;
                    overflow: hidden;
                }

                dot::before {
                    display: inline-block;
                    content: '...\A..\A.';
                    white-space: pre;
                    animation: dot 3s infinite step-start both;
                }

                @keyframes dot {
                    33% {
                        transform: translateY(-2em);
                    }
                    66% {
                        transform: translateY(-1em);
                    }
                }        
                h1,#all {
                    text-align: center;
                }
                #all {
                    padding: 1.2%;
                    margin: 0 auto;
                    max-width: 650px;
                }
                .total, .speed {
                    background: #ffffff;
                    margin: 30px;
                    padding: 20px;
                    border-radius: 5px;
                    box-shadow: 0 2px 6px 0px #0000004f;
                }
                .total:hover, .speed:hover{
                    transform: scale(1.3);  
                    transition: all 1s ease 0s;  
                    -webkit-transform: scale(1.3);  
                    -webkit-transform: all 1s ease 0s;  
                }
                a { 
                    color: #000; 
                }
            </style>
        </head>
        <body> 
            <h1>Network Monitoring</h1>
                <div id=\"all\">LOADING<dot>...</dot></div>
                <div style=\"text-align: center;font-size: 10px;\">by <a href=\"https://feaui.com\">九四</a></div>
                <script type=\"text/javascript\">
                    var xmlHttp;
                    function createXMLHttpRequest(){
                        if(window.ActiveXObject){
                            xmlHttp = new ActiveXObject(\"Microsoft.XMLHTTP\");
                        }
                        else if(window.XMLHttpRequest){
                            xmlHttp = new XMLHttpRequest();
                        }  
                    } 
                    function start(){
                        createXMLHttpRequest();
                        var url=\"?act=rt\";
                        xmlHttp.open(\"GET\",url,true);
                        xmlHttp.onreadystatechange = callback;
                        xmlHttp.send(null);
                    }
                    function callback(){
                        if(xmlHttp.readyState == 4){
                            if(xmlHttp.status == 200){
                                document.getElementById(\"all\").innerHTML = xmlHttp.responseText;
                                setTimeout(\"start()\",2000);
                            }
                        }
                    }
                start()
            </script>
        </body> 
    </html>" > /var/www/html/index.php
}
set_v2ray() {
    echo "{
        \"stats\": { }, 
        \"api\": {
            \"services\": [
                \"StatsService\"
            ], 
            \"tag\": \"api\"
        }, 
        \"policy\": {
            \"levels\": {
                \"0\": {
                    \"connIdle\": 300, 
                    \"downlinkOnly\": 30, 
                    \"handshake\": 4, 
                    \"uplinkOnly\": 5, 
                    \"statsUserDownlink\": true, 
                    \"statsUserUplink\": true
                }
            }
        }, 
        \"log\": {
            \"access\": \"\", 
            \"error\": \"\", 
            \"loglevel\": \"warning\"
        }, 
        \"inbound\": {
            \"port\": $PORT, 
            \"protocol\": \"vmess\", 
            \"settings\": {
                \"udp\": true, 
                \"clients\": [
                    {
                        \"id\": \"$UUID\", 
                        \"level\": 0, 
                        \"alterId\": 8, 
                        \"email\": \"i@$domain\"
                    }
                ]
            },
            \"streamSettings\": {
                \"network\": \"ws\", 
                \"wsSettings\": {
                    \"path\": \"/\"
                }
            }
        }, 
        \"inboundDetour\": [
            {
                \"listen\": \"127.0.0.1\", 
                \"port\": 10085, 
                \"protocol\": \"dokodemo-door\", 
                \"settings\": {
                    \"address\": \"127.0.0.1\"
                }, 
                \"tag\": \"api\"
            }
        ], 
        \"outbound\": {
            \"protocol\": \"freedom\", 
            \"settings\": { }
        }, 
        \"outboundDetour\": [
            {
                \"protocol\": \"blackhole\", 
                \"settings\": { }, 
                \"tag\": \"blocked\"
            }
        ], 
        \"routing\": {
            \"strategy\": \"rules\", 
            \"settings\": {
                \"rules\": [
                    {
                        \"inboundTag\": [
                            \"api\"
                        ], 
                        \"outboundTag\": \"api\", 
                        \"type\": \"field\"
                    }, 
                    {
                        \"type\": \"field\", 
                        \"ip\": [
                            \"0.0.0.0/8\", 
                            \"10.0.0.0/8\", 
                            \"100.64.0.0/10\", 
                            \"127.0.0.0/8\", 
                            \"169.254.0.0/16\", 
                            \"172.16.0.0/12\", 
                            \"192.0.0.0/24\", 
                            \"192.0.2.0/24\", 
                            \"192.168.0.0/16\", 
                            \"198.18.0.0/15\", 
                            \"198.51.100.0/24\", 
                            \"203.0.113.0/24\", 
                            \"::1/128\", 
                            \"fc00::/7\", 
                            \"fe80::/10\"
                        ], 
                        \"outboundTag\": \"blocked\"
                    }
                ]
            }
        }
    }" > /etc/v2ray/config.json
}
set_nginx() {
    echo "    user www-data;
    pid /run/nginx.pid;
    worker_processes auto;
    worker_rlimit_nofile 51200;
    events {
        use epoll;
        worker_connections 51200;
        multi_accept on;
    }

    http {
        include       mime.types;
        default_type  application/octet-stream;
        server_names_hash_bucket_size 128;
        client_header_buffer_size 32k;
        large_client_header_buffers 4 32k;
        client_max_body_size 50m;
        sendfile   on;
        tcp_nopush on;
        keepalive_timeout 60;
        tcp_nodelay on;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 64k;
        fastcgi_buffers 4 64k;
        fastcgi_busy_buffers_size 128k;
        fastcgi_temp_file_write_size 256k;
        gzip on;
        gzip_min_length  1k;
        gzip_buffers     4 16k;
        gzip_http_version 1.1;
        gzip_comp_level 2;
         gzip_types     text/plain application/javascript application/x-javascript text/javascript text/css application/xml application/xml+rss;
        gzip_vary on;
        gzip_proxied   expired no-cache no-store private auth;
        gzip_disable   MSIE [1-6].;
        server_tokens off;
        access_log off;

        server {
            listen 80 default_server;
            listen 443 ssl http2;
            server_name $domain;

            if (\$scheme = http) {
               return 301 https://\$server_name\$request_uri; 
            }

            index index.php;
            root /var/www/html;

            ssl_certificate /root/.acme.sh/$domain/fullchain.cer;
            ssl_certificate_key /root/.acme.sh/$domain/$domain.key;

            ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers \"EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH\";
            
            location ~* \.php$ {
                fastcgi_pass unix:/run/php/php7.2-fpm.sock;
                include         fastcgi_params;
                fastcgi_param   SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
                fastcgi_param   SCRIPT_NAME        \$fastcgi_script_name;
            }
            location / {
                proxy_redirect off;
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection \"upgrade\";
                proxy_set_header Host \$http_host;
                if (\$http_upgrade = \"websocket\") {
                    proxy_pass http://127.0.0.1:$PORT;
                }
            }
        }
    }" > /etc/nginx/nginx.conf
}
set_php() {
    echo "[www]user = www-data
    group = www-data
    listen = /run/php/php7.2-fpm.sock
    listen.owner = www-data
    listen.group = www-data 
    pm = dynamic
    pm.max_children = 5
    pm.start_servers = 2
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3" > /etc/php/7.2/fpm/pool.d/www.conf
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.2/fpm/php.ini
}
install_all() {
    apt-get -y install apt-transport-https lsb-release ca-certificates
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    wget -O /etc/apt/trusted.gpg.d/nginx.gpg https://packages.sury.org/nginx/apt.gpg
    sh -c 'echo "deb https://packages.sury.org/nginx/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/nginx.list'
    sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    apt-get -y update
    apt-get -y install nginx php7.2-fpm
    bash <(curl -L -s https://install.direct/go.sh)
}
check() {
    TMPSTR=`ping $domain -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    ip_info=`curl ip.cn/\?ip=$domain`
    ssl_file="/root/.acme.sh/$domain/fullchain.cer"
    [ ! -f "$ssl_file" ] && whiptail --backtitle "九四の記" --msgbox "SSL 证书申请失败！ 请重试或手动申请。\n\n参见：https://github.com/Neilpang/acme.sh/wiki/%E8%AF%B4%E6%98%8E" 10 60 && rm -rf /root/.acme.sh && exit 1
    if [ -z $TMPSTR ];then
        whiptail --backtitle "九四の記" --msgbox "未能正确解析域名 IP，请检查！" 10 60
        exit 1
    else  
        if [ $CDN == "true" ];then
            if [[ $ip_info =~ "CloudFlare" ]];then
                install_all
                set_nginx
                set_php
                set_v2ray
                set_web
                end
            else
                whiptail --backtitle "九四の記" --msgbox "域名 ip 解析有误，请检查！" 10 60
                clear
                exit 1
            fi
        elif [ $CDN == "false" ];then
            if [ $TMPSTR == "$(get_ip)" ];then
                install_all
                set_nginx
                set_php
                set_v2ray
                set_web
                end
            else
                whiptail --backtitle "九四の記" --msgbox "域名 ip 解析有误，请检查！" 10 60
                clear
                exit 1
            fi
        fi
    fi
}
ssl() {
    first_setup=`~/.acme.sh/acme.sh --issue --dns -d $domain --yes-I-know-dns-manual-mode-enough-go-ahead-please`
    Value=`echo ${first_setup#*value}|cut -d" " -f2|sed s#\'##g`
    Domain=`echo ${first_setup#*Domain}|cut -d" " -f2|sed s#\'##g`
    whiptail --title "请添加 TXT 记录" --msgbox "\n域名：$Domain\n\n值：$Value\n\n请添加好以后再继续下一步！\n\n参见：https://www.google.com/search?q=txt%E8%AE%B0%E5%BD%95" 20 60
    (
        c=0
        while [ $c -ne 100 ];do
            echo $c
            echo "###"
            echo "$c %"
            echo "###"
            ((c+=5))
            sleep 1
        done
    ) | whiptail --title "请等待" --gauge "" 5 60 0
    second_setup=`~/.acme.sh/acme.sh --renew -d $domain --yes-I-know-dns-manual-mode-enough-go-ahead-please`
}
random_parameter() {
    UUID=`cat /proc/sys/kernel/random/uuid`
    PORT=`shuf -i 9000-19999 -n 1`
    v2ray_path=`date | md5sum | cut -b -5`
    httphost=`date | md5sum | cut -b -3`
}
get_ip(){  # 这一部分抄自秋水的 shadowsocks 一键安装脚本
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    echo ${IP}
}
start() {
    whiptail --backtitle "九四の記" --yesno "脚本使用前说明\n\n1. 本脚本仅在 Debian 8 以及 Debian 9 测试通过。\n\n2. 不保证此脚本能完美运行。\n\n3. 建议在全新的系统下运行安装，注意备份重要资料。\n\n4. 安装前请准备好域名，以及把域名解析至本机 IP ：$(get_ip)\n\n5. 如有问题请联系 https://t.me/FEAUI" 20 60
    response=$?
    case $response in
        1) echo "取消安装" && exit 0;;
        255) echo "取消安装" && exit 0;;
    esac
    domain=$(whiptail --inputbox "请输入域名：" 10 60 3>&1 1>&2 2>&3 3>&- )
    clear
    whiptail --yesno "是否上 CDN\n\n" 10 60
    response=$?
    case $response in
        0) CDN=true;;
        1) CDN=false;;
        255) echo "取消安装" && exit 0;;
    esac
    clear
    if [ $CDN == "true" ];then
        whiptail --backtitle "九四の記" --yesno "我已正确地将域名 ns 服务器修改为 Cloudflare 的，并且正确地设置了 CDN 相关选项？\n\n参见 https://feaui.com/compile-and-install-nginx.html" 10 60
        response=$?
        case $response in
            0) CDN=true;;
            1) echo "取消安装" && exit 0;;
            255) echo "取消安装" && exit 0;;
        esac
        clear
    fi
    ssl
    random_parameter
    check
}
apt-get -y update
apt-get -y install whiptail curl wget
curl https://get.acme.sh | sh
start