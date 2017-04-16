---
layout: post
title: Xfce in xmonad pt. 2
---

Liebe Leser, willkommen zum zweiten Teil meiner Xmonade! Mittlerweile habe ich ziemlich viel mit xmonad und Xfce herumexperimentiert, wobei ich einiges gelernt habe, was ich mit meiner geschätzten Leserschaft teilen möchte! :)

Zuerst habe ich weiter xmonad an meine Bedürfnisse angepasst, u.a. auch die Tastaturkürzel eingerichtet (siehe weiter unten) und die Schriften eingestellt (via Xfce). Dann hat sich allerdings ein einschneidendes Problem ergeben: Ich stellte nämlich fest, dass eines meiner am häufigsten verwendeten Programme, jEdit (wegen meiner Masterarbeit), überhaupt nicht richtig funktionierte: Es ließ sich zu Beginn das Fenster nicht vergrößern/verkleinern, und auch nach einigem Einstellen in Konfigurationsdateien ignorierte das Programm meine Tastatureingaben; das heißt, ich hatte einen Editor, mit dem ich nichts schreiben konnte. Wie ironisch.

An diesem Punkte las ich, dass die neueste Version von xmonad (0.11) [einige Probleme mit Java-Programmen beseitigt](http://www.haskell.org/haskellwiki/Xmonad/Notable_changes_since_0.10), zu welchen auch jEdit gehört. Das waren natürlich hochinteressante Neuigkeiten, doch stellte ich fest, dass die neueste xmonad-Version nicht in meiner damaligen, dafür aber in neueren Ubuntu-Versionen verfügbar ist. So beschloss ich, einfach gleich die Gelegenheit zu nützen und ein neues Xubuntu bei mir zu installieren, nachdem das alte ja schon ein Jahr lang brav seinen Dienst geleistet hat.

Ein paar Stunden später ist das neue Xubuntu auf der Platte, inkl. aller wichtigen Softwarepakete. Ich starte xmonad, und -- siehe da! -- jEdit läuft wie am Schnürchen, ohne Probleme quelconque. Wunderbar!

So machte ich weiter mit meiner xmonad-Konfiguration, aber auf einmal packte mich der Schalk im Nacken und ich fragte mich, was in der neuen Xubuntu-Version ein "xmonad --replace" in Xfce bewirken würde. Erinnern wir uns: Dieses Experiment hatte in der alten Xubuntu-Version zu katastrophalen Ergebnissen geführt; neue Fenster wurden nicht mehr angezeigt, ich konnte mich nicht mehr abmelden, ... So sah ich diesem Experiment gespannt entgegen und duckte mich vor dem schicksalshaften Drücken der Eingabe-Taste vor dem Computer. Doch oh Wunder, es passiert nichts, außer dass alle meine bisher geöffneten Fenster von xmonad verwaltet werden; genau so, wie es sein soll! Einen kleinen spontanen Freudentanz später und nach ein paar Tests, ob wirklich alles funktioniert, beschließe ich, auch fortan xmonad innerhalb von Xfce laufen zu lassen, da dieses Arrangement einige Probleme löst:

- Die Xfce-Einstellungen waren unter xmonad immer nur als sehr lange und unübersichtliche Liste im "Startmenü" verfügbar; unter Xfce ist an dieser Stelle nur noch ein einziger Knopf, der das Xfce-Einstellungsprogramm öffnet.
- Ich kann wieder mit dem Xfce-Panel meinen Rechner ausschalten, in den Schlafmodus versetzen, mich abmelden etc. Unter xmonad waren an dieser Stelle diese Optionen nicht verfügbar bzw. haben Fehlermeldungen angezeigt.
- Xfce startet automatisch gnome-keyring, weshalb ich mein Passwort nicht mehr jedesmal eingeben muss, wenn ich mit git arbeite.
- Die Schriftarten funktionieren wieder wie gewohnt.
- Xfce verwaltet wieder meinen Desktop, wodurch sich auch das Hintergrundbild bei einem Monitorwechsel dynamisch anpasst. Das hat zuvor zu einigen Problemen geführt, da das Programm "feh", dass ich zwischenzeitlich verwendet habe, z.B. bei einem Wechsel der Bildschirmauflösung nicht auch das Hintergrundbild aktualisiert hat.
- Ich muss keine Programme wie xfce4-panel mehr manuell via xmonad starten.


Meine aktuelle Konfiguration
----------------------------

Xfce startet xmonad automatisch beim Start, was ich durch einen Eintrag in den Sitzungseinstellungen (Autostart) erzielt habe, der mir einfach "xmonad --replace" aufruft. Fertig.

Weiters habe ich (wie schon im letzten Artikel beschrieben) die Xfce-Tastaturkürzel deaktiviert, sodass es zu keinen ungewünschten Wechselwirkungen zwischen Xfce und xmonad kommt.

Meine xmonad-Konfigurationsdatei schaut wie folgt aus:

~~~ haskell
import XMonad
import XMonad.Config.Desktop
import XMonad.Config.Xfce
import XMonad.Hooks.SetWMName
import XMonad.Layout.NoBorders
import XMonad.Util.EZConfig

main = xmonad $ xfceConfig
	{ startupHook = startupHook xfceConfig >>
	    -- make Java programs resize correctly by pretending we are a
	    -- different WM (camouflage)
	    setWMName "LG3D"

	  -- inherit layout from desktopConfig
	, layoutHook = desktopLayoutModifiers $
	    -- do not show window borders in fullscreen mode
	    smartBorders $
	    -- switch only between two tiling algorithms instead of three
	    -- as in the default configuration
	    Tall 1 (3/100) (1/2) ||| Full
	, terminal = "exo-open --launch TerminalEmulator"
	}
	`additionalKeys`
	[ ((0       , xK_Print), spawn "xfce4-screenshooter -f")
	, ((mod1Mask, xK_Print), spawn "xfce4-screenshooter -w")
	, ((mod1Mask .|. shiftMask, xK_End), spawn "xfce4-session-logout --halt")
	, ((mod4Mask, xK_f), spawn "exo-open --launch FileManager")
	, ((mod4Mask, xK_w), spawn "exo-open --launch WebBrowser")
	, ((mod4Mask, xK_m), spawn "exo-open --launch MailReader")
	, ((mod4Mask, xK_b), spawn "transmission-gtk")
	, ((mod4Mask, xK_p), spawn "xfce4-display-settings")
	]
~~~



Dabei wäre das kleine, aber feine Tastenkürzel Alt-Shift-Ende hervorzuheben, das meinen Computer herunterfährt und mir bis zu drei Mausklicks erspart. ;) Zuvor benutzte ich unter xmonad die Befehle von [folgender Seite](https://bbs.archlinux.org/viewtopic.php?id=127962), also z.B.

	dbus-send --system --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop

zum Ausschalten des Rechners. Da dieser Befehl allerdings unter Xfce nicht funktioniert, verwende ich nunmehr den Xfce-eigenen Befehl dafür.

Um z.B. Filme im Vollbildmodus anzusehen, benutze ich meistens mplayer und drücke dann F, um in den Vollbildmodus zu gelangen. Bin ich aber faul und benutze die Standard-Xfce-Videowiedergabe Parole, dann gehe ich auch mit F in den Vollbildmodus, muss dann allerdings noch das Programm mittels Alt-Enter, Alt-Leertaste in den xmonad-Vollbildmodus schalten und das Panel am oberen Bildschirmrand mit einem einfachen Druck von Alt-B verstecken. (Übrigens auch eine sehr gute Methode, um noch ein wenig Platz zu gewinnen und um sich besser konzentrieren zu können.)

Wenn man in xmonad Alt-Leertaste drückt, dann wechselt xmonad die Art, wie es Fenster anzeigt, z.b. "ein Fenster links und alle anderen Fenster rechts davon zeigen" oder "aktuelles Fenster im Vollbildmodus darstellen". Ich verwende hauptsächlich diese zwei Modi, weshalb ich sie in layoutHook eingestellt habe. Das ist recht gut auf [dieser Seite](http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Config-Desktop.html) erklärt.


Résumé
------

Mit der momentanen Lösung bin ich höchst zufrieden -- alles funktioniert bestens, läuft stabil und ich kann die Annehmlichkeiten von Xfce mit der Effizienz von xmonad verbinden. Ich kann auf die exzellente [Tour d'xmonad][Tour] verweisen, die mich ursprünglich von xmonad begeistert hat. Für das frankophone Publikum möchte ich auch auf [diese Seite](http://blog.fedora-fr.org/metal3d/post/Xmonad,-le-bureau-productif-orient%C3%A9-terminal) verweisen, die eine kleine, recht lustige Einführung in xmonad bietet. Andere gute Einführungen befinden sich [hier](http://www.nepherte.be/step-by-step-configuration-of-xmonad/) und [da](http://www.linuxandlife.com/2011/11/how-to-configure-xmonad-arch-linux.html) (übrigens auch von einem Franzosen; mir kommt vor, dass sehr viele diese Arbeitsumgebung nutzen).

Zu guter Letzt noch ein paar Bildschirmfotos:

{% include image.html caption="Einmal aufgeräumt, ..." media="clean.png" %}

{% include image.html caption="... einmal mit Fenstern." media="messy.png" %}

Man beachte auch die Fenstervorschau pro Arbeitsfläche im Xfce-Panel rechts oben; ein sehr nützliches Werkzeug, um schnell herauszufinden, wo sich der Firefox wieder hinverkrochen hat. ;)


[Tour]: http://xmonad.org/tour.html
