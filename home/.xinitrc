xrdb -merge ~/.Xresources

setxkbmap -layout de,us
setxkbmap -option caps:escape
xinput set-prop 12 276 1

urxvtd &
devmon &

session=${1:-bspwm}

case $session in
	i3|i3wm		 ) exec i3;;
	kde			   ) exec startkde;;
	xfce|xfce4 ) exec startxfce4;;
  bspwm      ) exec bspwm;;
	*			     ) ;;
esac
