xrdb -merge ~/.Xresources

# setxkbmap -layout de
# setxkbmap -option caps:escape
# xinput set-prop 12 276 1

# urxvtd &
# udiskie -t2 &
# dunst &

session=${1:-xmonad}

case $session in
	i3|i3wm		) exec i3;;
	kde		) exec startkde;;
	xfce|xfce4	) exec startxfce4;;
  	bspwm		) exec bspwm;;
	xmonad		) exec xmonad;;
	*		) ;;
esac
