import XMonad
import XMonad.Config.Desktop
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Spacing
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig(additionalKeys, additionalKeysP)
import XMonad.Util.Scratchpad

import qualified DBus as D
import qualified DBus.Client as D

import Graphics.X11.ExtraTypes.XF86

import qualified Codec.Binary.UTF8.String as UTF8

-- Colors
fg         = "#ebdbb2"
bg         = "#282828"
gray       = "#ced4da"
darkgrey   = "#495057"
bg1        = "#3c3836"
bg2        = "#505050"
bg3        = "#665c54"
bg4        = "#7c6f64"

green      = "#51cf66"
darkgreen  = "#40c057"
red        = "#ff8787"
darkred    = "#fa5353"
yellow     = "#ffd43b"
darkyellow = "#fab005"
blue       = "#4dadf7"
darkblue   = "#228ae6"
purple     = "#d3869b"
aqua       = "#8ec07c"
white      = "#e9ecef"

pur2       = "#5b51c9"
blue2      = "#2266d0"

-- Main configuration
main = do
  dbus <- D.connectSession
  D.requestName dbus (D.busName_ "org.xmonad.Log")
    [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]

  xmonad $ docks $ ewmh desktopConfig
    { terminal    = myTerminal
    , modMask     = mod4Mask
    , layoutHook  = myLayout
    , manageHook  = myManageHook
    , startupHook = myStartupHook
    , logHook     = dynamicLogWithPP (myLogHook dbus)
    } `additionalKeysP` specialKeys

myLayout = avoidStruts $ spacingRaw False (Border 5 5 5 5) True (Border 10 10 10 10) True $ layoutHook def
myTerminal = "urxvtc"
myFilemanager = "ranger"
myBrowser = "firefox"
myEditor = "emacs"

specialKeys = [ ("<XF86MonBrightnessUp>", spawn $ modifyBacklightCmd "-inc 20")
              , ("<XF86MonBrightnessDown>", spawn $ modifyBacklightCmd "-dec 20")

              , ("<XF86AudioRaiseVolume>", spawn $ modifyVolumeCmd "+5%")
              , ("<XF86AudioLowerVolume>", spawn $ modifyVolumeCmd "-5%")
              , ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle")

              , ("<XF86AudioMicMute>", spawn "pactl set-source-mute 1 toggle")

              , ("M-s", scratchpadSpawnActionTerminal myTerminal)
              , ("M-p", spawn "rofi -show drun")
              , ("M-a f", spawn $ myTerminal ++ " -e " ++  myFilemanager)
              , ("M-a b", spawn myBrowser)
              , ("M-a e", spawn myEditor)
              ]

-- LogHook to communicate with Polybar
myLogHook :: D.Client -> PP
myLogHook dbus = def
    { ppOutput = dbusOutput dbus
    , ppCurrent = wrap ("%{B" ++ bg2 ++ "} ") " %{B-}"
    , ppVisible = wrap ("%{B" ++ bg1 ++ "} ") " %{B-}"
    , ppUrgent = wrap ("%{F" ++ red ++ "} ") " %{F-}"
    , ppHidden = wrap " " " " . noScratchpad
    , ppWsSep = ""
    , ppSep = "  "
    , ppTitle = shorten 40
    , ppOrder = (\(ws:_:rest) -> ws : rest)
    }
  where noScratchpad ws = if ws == "NSP" then "" else ws

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

-- Manage hook
myManageHook = manageDocks <+> manageScratchpad <+> manageHook desktopConfig

manageScratchpad :: ManageHook
manageScratchpad = scratchpadManageHook (W.RationalRect 0.20 0.20 0.6 0.6)

-- Spawn system daemons
myStartupHook = do
  spawn "light-locker"
  spawn "setxkbmap -layout de -option caps:escape"
  spawn "compton"
  spawn "~/.config/polybar/polybar.sh && ~/.config/polybar/tray.sh"
  spawn "urxvtd"
  spawn "udiskie -2"
  spawn "dunst"
  spawn "~/.fehbg"

modifyVolumeCmd cmd = "pactl set-sink-volume @DEFAULT_SINK@ " ++ cmd
modifyBacklightCmd cmd = "xbacklight " ++ cmd
