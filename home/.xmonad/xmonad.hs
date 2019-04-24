import XMonad
import XMonad.Config.Desktop
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Spacing
import XMonad.Util.EZConfig(additionalKeys, additionalKeysP)

import qualified DBus as D
import qualified DBus.Client as D

import Graphics.X11.ExtraTypes.XF86

import qualified Codec.Binary.UTF8.String as UTF8

-- Colors
fg        = "#ebdbb2"
bg        = "#282828"
gray      = "#a89984"
bg1       = "#3c3836"
bg2       = "#505050"
bg3       = "#665c54"
bg4       = "#7c6f64"

green     = "#b8bb26"
darkgreen = "#98971a"
red       = "#fb4934"
darkred   = "#cc241d"
yellow    = "#fabd2f"
blue      = "#83a598"
purple    = "#d3869b"
aqua      = "#8ec07c"
white     = "#eeeeee"

pur2      = "#5b51c9"
blue2     = "#2266d0"


main = do
  dbus <- D.connectSession
  D.requestName dbus (D.busName_ "org.xmonad.Log") 
    [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]

  xmonad $ desktopConfig
    { terminal    = "urxvtc"
    , modMask     = mod4Mask
    , layoutHook  = myLayout
    , startupHook = myStartupHook
    , logHook     = dynamicLogWithPP (myLogHook dbus)
    } `additionalKeysP` specialKeys

myLayout = avoidStruts $ spacingRaw False (Border 5 5 5 5) True (Border 10 10 10 10) True $ layoutHook def

specialKeys = [ ("<XF86MonBrightnessUp>", spawn $ modifyBacklightCmd "-inc 20")
              , ("<XF86MonBrightnessDown>", spawn $ modifyBacklightCmd "-dec 20")

              , ("<XF86AudioRaiseVolume>", spawn $ modifyVolumeCmd "+5")
              , ("<XF86AudioLowerVolume>", spawn $ modifyVolumeCmd "-5%")
              , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")
              ]


-- LogHook to communicate with Polybar
myLogHook :: D.Client -> PP
myLogHook dbus = def
    { ppOutput = dbusOutput dbus
    , ppCurrent = wrap ("%{B" ++ bg2 ++ "} ") " %{B-}"
    , ppVisible = wrap ("%{B" ++ bg1 ++ "} ") " %{B-}"
    , ppUrgent = wrap ("%{F" ++ red ++ "} ") " %{F-}"
    , ppHidden = wrap " " " "
    , ppWsSep = ""
    , ppSep = "  "
    , ppTitle = shorten 40
    , ppOrder = (\(ws:_:rest) -> ws : rest)
    }

-- Emit a DBus signal on log updates
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
            D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"

-- Spawn system daemons
myStartupHook = do
  spawn "setxkbmap -layout de -option caps:escape"
  spawn "compton"
  spawn "~/.config/polybar/polybar.sh && ~/.config/polybar/tray.sh"
  spawn "urxvtd"
  spawn "udiskie -2"
  spawn "dunst"
  spawn "~/.fehbg"

modifyVolumeCmd cmd = "pactl set-sink-volume @DEFAULT_SINK@ " ++ cmd
modifyBacklightCmd cmd = "xbacklight " ++ cmd
