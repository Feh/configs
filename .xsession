export GTK_IM_MODULE=xim
export QT_IM_MODULE=xim
xset b off
xset s off
xset r rate 200 40
xhost local:root
xset fp+ /usr/share/fonts/local/
xrdb -load ~/.Xdefaults
exec i3
