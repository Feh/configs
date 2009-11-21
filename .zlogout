sudo -k
clear
if [[ -n $SSH_CONNECTION ]]; then
    echo -n "Connection closed: "
    date
fi
