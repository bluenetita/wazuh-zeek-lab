event zeek_init(){
    system("bash /opt/zeek/share/zeek/site/custom_scripts/wazuh-zeek.sh");
}root@zeekvm:/opt/zeek/share/zeek/site/custom_scripts# cat start.zeek
event zeek_init(){
    system("bash /opt/zeek/share/zeek/site/custom_scripts/wazuh-zeek.sh");
}