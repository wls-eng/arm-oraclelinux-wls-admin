echo "#adminPasswordOrKey#" | sudo -S [ -d "/u01/app/wls/install/oracle/middleware/oracle_home/wlserver/modules" ] && exit 0
exit 1
