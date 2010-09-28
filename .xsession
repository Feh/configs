export GTK_IM_MODULE=xim
export QT_IM_MODULE=xim
xset b off
xset s off
xset r 500 75
xhost local:root
xmodmap ~/.Xmodmap
xrdb -load ~/.Xdefaults
# set up two screen system if connected
if xrandr -q | grep -q "VGA connected"; then
  xrandr --output LVDS --auto --output VGA --left-of LVDS --mode 1360x768
else
  xrandr --output VGA --off --output LVDS --auto
fi
# feh --bg-scale ~/wallpaper/zz_big.jpg
urxvtd -q -f -o
synergys
awesome
