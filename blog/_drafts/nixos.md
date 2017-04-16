VirtualBox
----------

VirtualBox complains about VT-x being disabled in BIOS.
With the help of <http://amiduos.com/support/knowledge-base/article/enabling-virtualization-in-lenovo-systems>,
I set the flag in BIOS for my Lenovo ThinkPad.

Once I had booted into NixOS, I fell into a command-line login.
Don't know how that happened. Anyway, one `reboot` later, I was in KDE.
There, not many packages seemed to be available, and especially no printer GUI,
which I would have been interested in because I remember that I had problems
configuring printer autodetection last time I tried NixOS.
Disabling keyboard capturing via "Right Ctrl" did not work in VirtualBox,
perhaps because I set "Right Ctrl" as Compose key in X. Ah well,
so I just move out my mouse from the window every time.
Oh, and I cannot copy things in VirtualBox and paste them in my host system.
That sucks.

Let us have a look at the configuration.

~~~
[demo@nixos:~]$ cat /etc/nixos/configuration.nix
{
  imports = [ <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix> ];
}
~~~

Okay, so the *real* configuration is in `virtualbox-image.nix`.
Where is that now exactly?

~~~
[demo@nixos:~]$ locate virtualbox-image
locate: `/var/cache/locatedb': No such file or directory
~~~

Oh, `locate` does not seem to be set up. I remember that this took me
quite some time so set up last time, and I'm not sure whether it really worked
in the end.

Well, let's try it out. Download the graphical ISO image and load it into
VirtualBox.
I followed the manual, and everything went fine, until the boot loader
installation.
I had made with `cfdisk` a GPT partition table (because it was the first
option offered and I didn't want to choose DOS ^^) and created a single
partition on it. However, I got a warning like this:

    grub-install: warning: this GPT partition label contains no BIOS Boot Partition; embedding won’t be possible.

Apparently GRUB needs a partition with the `bios_grub` flag set,
so I made my first partition a bit smaller, created a new 4MB partition,
enabled the `bios_grub` flag on it and reran `nixos-install`.
This time everything went fine.
Source: <https://blog.hostonnet.com/grub-install-warning-this-gpt-partition-label-contains-no-bios-boot-partition-embedding-wont-be-possible>

I reboot and get into the lightdm display manager that I set before in the
configuration. But then I remember that I did not set up a password for my
user. To do that, I logged in as root (in the graphical user interface because
I could not switch to another terminal while in the virtual machine)
and set my personal user password via

    passwd michi

Then, I can finally login as myself.
There, next surprise. I do not even have an internet browser installed.
So I want to edit the NixOS configuration file.
However, for that, I need `sudo`. And `sudo` tells me that I am not in the
`sudoers` file. So I log back in as root, modify my users entry to something
more like

~~~
  users.extraUsers.michi = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" ];
  };
~~~

(fortunately, I had this old configuration file floating around!)
and log back in as myself. This time, I am able to add the `firefox`
package and install it just fine.

XMonad

Fonts
-----

<https://nixos.org/wiki/Fonts>
Add noto-fonts to packages.
Works well.


Icons, Themes
-------------

Do not work
<https://github.com/NixOS/nixpkgs/issues/13537>
Wanted to install Greybird and elementary-icon-theme, but
Greybird was not available for NixOS 16.03, and
elementary-icon-theme did install, but has no effect


Videos
------

I tried Parole, but it immediately told me that
it could not open Xv output. That might have to do with the VM.
However, worse is that no thumbnails for videos are created.
That depends on the Xfce program `tumbler`, and unfortunately,
it is currently built without support for video thumbnails:
<https://github.com/NixOS/nixpkgs/blob/master/pkgs/desktops/xfce/core/tumbler.nix>


Xfce + XMonad
-------------

There exists an option in `lightdm` to start an environment with the tasty name
"xfce + xmonad", but unfortunately, this launches Xfce and XMonad, then
immediately hides the panel. I also have this problem under Xubuntu, but there
I mitigate it by launching `xmonad` about 10 seconds delayed.


Gnome + XMonad
--------------

I tried Gnome 3, but apparently XMonad is not supported for Gnome > 3.8.
Also, video thumbnails did not work in Gnome 3.


KDE
---

I wanted to try KDE, but as I installed it, I ran out of disk space (8GB).
At this place, I decided to stop the NixOS experiment.
