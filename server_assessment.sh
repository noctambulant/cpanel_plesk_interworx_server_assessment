#4/19/24
#Alex Silkin
#Server Assessment script for web-servers using cPanel, Plesk, InterWorx control panels
#Version 0.1
#!/bin/bash


#Setting base variable values

CONTROL_PANEL="none"
PANEL_VERSION=0
CPU_CORES=$(nproc)
RAM_BYTES=$(free -t | grep "Mem" | awk '{print $2}')
RAM_HUMAN_READABLE=$(free -th | grep "Mem" | awk '{print $2}')


detect_panel_version
check_sites_hitting_fpm_limits #Work in progress
check_apache_scoreboard_errors #To do
check_recent_out_of_memory_terminations #To do
check_mysql_performance #To do




detect_panel_version() {
#Identifying cPanel panel type and version
if [ -f /usr/sbin/whmapi1 ] || [ -f /usr/sbin/whmapi0 ]
    then
        CONTROL_PANEL="cpanel"
        PANEL_VERSION=$(/usr/sbin/whmapi1 version | head -3 | grep version | awk '{print $2}')
        echo "This server uses cPanel version" $PANEL_VERSION
fi

#Identifying Plesk panel type and version

if [ -f /usr/sbin/plesk ]
    then
        CONTROL_PANEL="cpanel"
        PANEL_VERSION=$(plesk -v | head -1 | awk '{print $3, $4, $5}')
        echo "This server uses Plesk version" $PANEL_VERSION
fi
#Identifying InterWorx panel type and version

}

check_sites_hitting_fpm_limits() { 

echo "RECENT PHP-FPM LIMIT HITS:"

case $CONTROL_PANEL in
    cpanel)
        grep -isaE 'max_requests|max_children' /opt/cpanel/ea-php*/root/usr/var/log/php-fpm/error.log* | awk '{print $1, $2, $3, $5, $10}' | tail
        ;;
    plesk)
    #To do
       grep -isaE 'max_requests|max_children' /var/log/plesk-php*-fpm/error.log | awk '{print $1, $2, $3, $5, $10}' | tail
        ;;
    interworx)
    #To do
        #grep -isaE 'max_requests|max_children' /opt/cpanel/ea-php*/root/usr/var/log/php-fpm/error.log* | awk '{print $1, $2, $3, $5, $10}' | tail
        ;;
esac
}


check_apache_scoreboard_errors() {

echo "RECENT APACHE ERRORS:"

case $CONTROL_PANEL in
    cpanel)
    echo "MaxRequestWorker errors:"
    grep -isa "MaxRequestWorkers" /etc/apache2/logs/error_log

    echo "ScoreBoard filled up:"
    grep -isa "scoreboard" /etc/apache2/logs/error_log
    ;;
    interworx)
    echo "MaxRequestWorker errors:"
    ;;
    plesk)
    echo "MaxRequestWorker errors:"
    grep -isa "MaxRequestWorkers" /var/log/httpd/error_log
    echo "ScoreBoard filled up:"
    grep -isa "scoreboard" /var/log/httpd/error_log
    echo "ServerLimit errors:"
    grep -isa "serverlimit" /var/log/httpd/error_log
    ;;

esac

}
check_mysql_performance() {

echo "Assessing InnoDB and MyISAM MySQL performance:"

#Pull relevant MySQL data
INNODB_BUFFER_POOL_READ_REQUESTS=$(mysql -e "show global status;" | grep "Innodb_buffer_pool_read_requests" | awk '{print $2}')
INNODB_BUFFER_POOL_READS=$(mysql -e "show global status;" | grep "Innodb_buffer_pool_reads" | awk '{print $2}')

#Divide the values with 3 precision points

INNODB_READS_TO_READ_REQUESTS=$(awk "BEGIN {print $INNODB_BUFFER_POOL_READ_REQUESTS / $INNODB_BUFFER_POOL_READS}")

#Output the result
echo "The ratio of InnoDB reads to read requests is 1 to" $INNODB_READS_TO_READ_REQUESTS

MYISAM_KEY_BUFFER_READS=$(mysql -e "show global status;" | grep "Key_reads" | awk '{print $2}')
MYISAM_KEY_BUFFER_READ_REQUESTS=$(mysql -e "show global status;" | grep "Key_read_requests" | awk '{print $2}')

MYISAM_READS_TO_READ_REQUESTS=$(printf "%.3f\n" $((10**3 * $MYISAM_KEY_BUFFER_READ_REQUESTS / $MYISAM_KEY_BUFFER_READS))e-3)

#Output the result
echo "The ratio of MyISAM reads to read requests is 1 to" $MYISAM_READS_TO_READ_REQUESTS



}
