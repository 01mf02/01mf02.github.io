---
title: Xfce in xmonad pt. 3
---

This article shows how to integrate Xfce 4.14 with xmonad 0.15.

For motivation, please see [my previous article on this topic](/blog/xfce-in-xmonad-pt-2).
The new integration keeps the xmonad configuration file at the middle of the article.
What is new is the setup to start xmonad upon starting Xfce:

~~~
xfconf-query --channel xfce4-session --property /sessions/Failsafe/Client0_Command \
  --type string --set "xmonad" \
  --type string --set "--replace"
xfconf-query --channel xfce4-session --property /sessions/Failsafe/Client4_Command \
  --type string --set "xfdesktop.disabled" --force-array
~~~

This changes which commands are executed upon starting Xfce.
In particular, this replaces
`xfwm4 --replace` by `xmonad --replace`, and
`xfdesktop` by `xfdesktop.disabled`.
The latter prevents xfdesktop from starting,
which is unfortunately necessary due to
[a bug in xmonad](https://github.com/xmonad/xmonad/issues/151).

This method replaces the previous, brittle way of
replacing a running xfwm4 with xmonad after a fixed time amount.
Its disadvantage is that this prevents Xfce from providing
custom desktop backgrounds and desktop icons.
But if you are like me, chances are that
you will rarely see your desktop anyway. :)
