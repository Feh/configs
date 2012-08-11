export GTK_IM_MODULE=xim
export QT_IM_MODULE=xim
xset b off
xset s off
xset r 500 75
xhost local:root
xmodmap ~/.Xmodmap
xrdb -load ~/.Xdefaults
exec i3
