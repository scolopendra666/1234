#!/bin/bash

if [[ $1 == "-debug" ]]; then
    set -ex
fi

# Parse the Synchrony home folder from the script location
SYNCHRONY_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVICE="synchrony"

if [ -z "$SYNCHRONY_USER" ]; then
    SERVICE_USER="synchrony"
else
    SERVICE_USER=$SYNCHRONY_USER
fi

if [ -x "/sbin/runuser" ]; then
    sucmd="/sbin/runuser"
else
    sucmd="su"
fi

if [[ $1 == "-u" ]]; then
    echo "Uninstalling Synchrony as a service"
    rm -f /etc/init.d/"${SERVICE}"
    if [[ -x $(which update-rc.d) ]]; then
        update-rc.d -f "${SERVICE}" remove
    else
        for (( i=0; i<=6; i++ )); do
            rm -f /etc/rc$i.d/{S,K}95"${SERVICE}"
        done
    fi
else
    if [[ -d /etc/init.d ]]; then
        echo "Installing Synchrony as a service"
        cat >/etc/init.d/"${SERVICE}" <<EOF
#!/bin/bash

### BEGIN INIT INFO
# Provides:      synchrony
# Required-Start:    \$remote_fs \$syslog \$time \$named
# Required-Stop:    \$remote_fs \$syslog \$time \$named
# Default-Start:     2 3 4 5
# Default-Stop:     0 1 6
# Short-Description: Atlassian Synchrony
# Description: Atlassian Synchrony Server
### END INIT INFO

# Synchrony Linux service controller script
cd "${SYNCHRONY_HOME}"

case "\$1" in
    start)
        "${sucmd}" -m "${SERVICE_USER}" -c "./start-synchrony.sh"
        ;;
    stop)
        "${sucmd}" -m "${SERVICE_USER}" -c "./stop-synchrony.sh"
        ;;
    restart)
        "${sucmd}" -m "${SERVICE_USER}" -c "./stop-synchrony.sh"
        "${sucmd}" -m "${SERVICE_USER}" -c "./start-synchrony.sh"
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart}"
        exit 1
        ;;
esac
EOF
        chmod +x /etc/init.d/"${SERVICE}"
        if [[ -x $(which update-rc.d) ]]; then
            update-rc.d -f $SERVICE defaults
        else
            ln -s /etc/init.d/"${SERVICE}" /etc/rc0.d/K95"${SERVICE}"
            ln -s /etc/init.d/"${SERVICE}" /etc/rc1.d/K95"${SERVICE}"
            ln -s /etc/init.d/"${SERVICE}" /etc/rc2.d/S95"${SERVICE}"
            ln -s /etc/init.d/"${SERVICE}" /etc/rc3.d/S95"${SERVICE}"
            ln -s /etc/init.d/"${SERVICE}" /etc/rc4.d/S95"${SERVICE}"
            ln -s /etc/init.d/"${SERVICE}" /etc/rc5.d/S95"${SERVICE}"
            ln -s /etc/init.d/"${SERVICE}" /etc/rc6.d/K95"${SERVICE}"
        fi
    fi
fi
