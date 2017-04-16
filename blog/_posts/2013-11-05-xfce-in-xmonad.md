---
layout: post
title: Xfce in xmonad
---

*Aktualisierung*: Mittlerweile habe ich [den zweiten Teil des Artikels](/blog/xfce-in-xmonad-pt-2) geschrieben.

Kürzlich habe ich den Fenstermanager [xmonad] ausprobiert, und ich war ziemlich begeistert: Nach kurzer Zeit war ich beim Verwalten meiner Fenster um einiges schneller als zuvor, und ich musste die Maus nur noch sehr sporadisch einsetzen -- eine exzellente Sache, auch im Hinblick auf ergonomisches Arbeiten.

Es zeigte sich allerdings nach und nach, dass ich einige Dinge vermisste: So hätte ich mir Lösungen für folgende Probleme suchen müssen:

- GTK-Programme schauen sehr "schiach" aus.
- Drahtlose Netzwerke werden nicht automatisch gesucht.
- USB-Laufwerke werden nicht automatisch eingebunden.
- Es existiert kein Feld zum Ändern der Lautstärke.
- Ich kann meine Bildschirmauflösung nicht einstellen. (xrandr, ich hasse dich!)
- ...

Die Liste ließe sich noch sehr lange fortsetzen. Ich hätte mir jetzt natürlich an dieser Stelle für jede dieser Sachen eine eigene Lösung suchen können, aber ich halte Faulheit, wenn sie intelligent eingesetzt wird, für eine Tugend. Und der einfachste (sprich "faulste") Weg wäre natürlich, meine bisherigen Programme für die oben genannten Probleme einzusetzen, also einfach meine mir ans Herz gewachsenen Xfce-Programme weiterzuverwenden, während ich xmonad zur Fensterverwaltung benütze. Voilà.

Und so habe ich einfach einmal unter xmonad versucht, das Panel von Xfce zu starten. Alt-P (nach der Installation von dmenu), xfce4-panel eingegeben und los geht's. Mon dieu ! Das Panel schaut grauenhaft aus, zeigt keine Ikonen an und spielt nicht wirklich mit xmonad zusammen. An diesem Punkt schaue ich einfach einmal ins Internet, was andere Leute zu dem Thema "xfce4 xmonad" geschrieben haben. Ein wenig später bin ich schlauer, dass viele Leute ganz herkömmlich Xfce starten und dann xmonad in Xfce laufen lassen, durch ein simples "xmonad --replace". Gleichzeitig lese ich allerdings ein paar Warnungen dazu, was mich aber nicht abhält, einfach einmal "xmonad --replace" einzugeben. Whoa! Es scheint zwar so, dass xmonad läuft, aber ich kann keine Programme mehr öffnen, meine Schnellstartleiste erscheint nicht mehr, und irgendwie kommt mir das alles spanisch vor.

Welche Möglichkeiten habe ich jetzt also? Ich könnte mich einige Zeit darin vertiefen, xmonad unter Xfce zum Laufen zu bringen, oder ich könnte versuchen, die von mir benötigten Teile von Xfce unter xmonad einzusetzen.
Ich entscheide mich für letztere Lösung -- Gründe:

- Wenn ich Xfce so konfiguriere, dass es mit xmonad zusammenspielt und nicht umgekehrt, so kann es sein, dass ich beim nächsten Mal, wenn ich alle meine Xfce-Einstellungen lösche (kommt durchschnittlich alle sechs Monate vor), wieder das delikate Zusammenspiel xmonad/Xfce neu einstellen muss. Die xmonad-Konfiguration ist hingegen viel simpler aufgebaut, sodass ich diese gar nicht erst löschen werde.
- Ich kann einiges über den Aufbau und den Startvorgang von Xfce lernen.
- Der Start des Desktops könnte etwas schneller sein. :)

Ich werde also jetzt meinen Migrationsprozess dokumentieren. Zu dem Zeitpunkt, wo ich diese Zeilen schreibe, sitze ich noch in meinem angestammten Xfce-Desktop und beginne mit der Forschungsarbeit, was denn jetzt zu tun ist. :)


Sondierung
----------

Wenn wir in Xubuntu Xfce starten, dann wird zuerst /usr/share/xsessions/xfce.desktop ausgeführt: Diese Datei enthält einfach den Befehl "startxfce4". Schauen wir uns diese Datei an: Diese Datei (liegt in /usr/bin/startxfce4, was ein einfaches "which startxfce4" zu Tage bringt) setzt hauptsächlich sehr allgemeine Umgebungsvariablen, die nicht direkt im Zusammenhang mit Xfce stehen, wie z.B. XDG_DATA_DIRS. Dann startet sie den X-Server, und zwar mit einer Konfigurationsdatei xinitrc, die sich ein meinem Falle in /etc/xdg/xfce4/xinitrc verbirgt. Schauen wir dort einmal hinein:

Im ersten Teil setzt das Skript xinitrc hauptsächlich wieder Umgebungsvariablen, darunter einige Pfade.
Dann wird es interessant: Falls xfce4-session installiert ist, startet das Skript dieses Programm und beendet sich an dieser Stelle; andernfalls setzt das Skript seine Ausführung fort.
Was macht also xfce4-session? Ich habe auf meinem System festgestellt, dass xfce4-session installiert ist, also wird es bei mir auch ausgeführt. xfce4-session übernimmt den Start der Programme, die die meisten Benutzer als Xfce-typisch ansehen würden: Das Panel, den Dateimanager, den Desktop, ... -- darunter allerdings auch den Fenstermanager xfwm4, den ich ja gerne durch xmonad ersetzen würde.
Aus letzterem Grunde entschließe ich mich also gegen xfce4-session, da es mir vermutlich einiges an Flexibilität nehmen würde, und entscheide mich dafür, in der xinitrc weiterzulesen, welche Programme dieses Skript in der Absenz von xfce4-session denn starten würde. Und, siehe da, da sind die wichtigen Programme aufgelistet: Zuerst noch das langweilige dbus, dann aber xfsettingsd (ein Dämon zum Verwalten von Xfce-Einstellungen), dann xfwm4 (Fenstermanager), weiters xfdesktop (Xfce-Desktop), Orage (Terminverwaltung mit schönem französischen Namen) und schlussendlich noch xfce4-panel, das u.a. für die Schnellstartleiste und das Startmenü zuständig ist. Puh.

War das alles, was Xfce startet? Nun, Xfce startet noch einige andere Programme, die ich hier noch nicht aufgelistet habe, aber für mich dennoch wichtig sind, z.B. die Netzwerkverwaltung (network-manager) oder den Bildschirmschoner (xscreensaver). Wenn man sehen möchte, welche Programme Xfce startet, gebe man xfce4-session-settings ein und erhält eine hübsche Liste.

Was ist jetzt also zu tun, wenn ich eine abgespeckte Version von Xfce mit den für mich notwendigen Programmen unter xmonad starten möchte?

1. Wichtige Umgebungsvariablen aus startxfce4 extrahieren.
2. Weitere Umgebungsvariablen aus xinitrc extrahieren.
3. Programme aus xinitrc extrahieren, mit Ausnahme von xfwm4, da ja xmonad dessen Arbeit übernimmt.
4. Automatisch gestartete Programme aus xfce4-session-settings extrahieren.

Diese Arbeit habe ich erledigt und zwei kleine Skripte namens xfce-base.sh und xfce-extras.sh gebastelt, die mir all diese Programme starten:

~~~
#!/bin/bash
# xfce-base.sh
xdg-user-dirs-update
dbus-launch
xfsettingsd
xfce4-panel &
~~~

Und die nächste:

~~~
#!/bin/bash
# xfce-extras.sh
system-config-printer-applet &
xfce4-volumed
xfce4-power-manager
xscreensaver -no-splash &
update-notifier &
nm-applet &
/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
~~~

Umgebungsvariablen setze ich keine, da ich bisher ohne auskomme.



Ab zu xmonad
------------

So, jetzt melde ich mich aus Xfce ab und in xmonad an. Wie ich mittlerweile schon weiß, startet man ein Terminal mit Alt-Shift-Enter und beendet xmonad mit Alt-Shift-Q. (Am Anfang dachte ich, dass die Installation nicht funktioniert hätte, weil Mausklicks auf die Arbeitsfläche keine Wirkung hatten und auch sonst kein Fenster zu sehen war. ^^) Nachdem ich also ein Terminal gestartet habe, führe ich meine beiden Skripten aus -- oh Wunder, meine Xfce-Programme öffnen sich, und meine Bildschirmauflösung passt sich automatisch an meine Xfce-Einstellungen an (dank xfsettingsd)! Allerdings kann ich neugestartete Programme nicht sehen. Nach ein wenig Experimentierens merke ich, dass xfdesktop die Fehlerquelle darstellt, und schmeiße xfdesktop aus meiner xfce-base.sh. So, neuer Versuch ohne xfdesktop. Ja, diesmal schaut es besser aus! Ich sehe neugeöffnete Programme! :)

An diesem Punkt bemerke ich allerdings, dass Xfce und xmonad noch nicht so richtig miteinander wollen; das Panel verdeckt meine Fenster, das Wechseln zwischen Fenstern wählt manchmal auch das Panel aus (sehr lästig!), sodass es Zeit für eine Überarbeitung ist und Zeit, eine xmonad-Konfiguration zu erstellen! Im Internet lese ich eine [Version der Konfigurationsdatei mit Xfce](http://www.haskell.org/haskellwiki/Xmonad/Using_xmonad_in_XFCE#Using_XMonad.Config.Xfce), was ich direkt probiere:

~~~ haskell
import XMonad
import XMonad.Config.Xfce
main = xmonad xfceConfig
~~~

Das war's, diese Zeilen kommen in die Datei ~/.xmonad/xmonad.hs. Ich prüfe mit

~~~
xmonad --recompile
~~~

nach, ob ich keine Fehler gemacht habe, und verleite xmonad mittels Alt-Q zum Neuladen der Konfiguration. Da ich noch keine Änderung feststellen kann, starte ich auch noch das Panel neu mittels:

~~~
pkill xfce4-panel
xfce4-panel &
~~~

Tada! Mein Panel überlappt meine anderen Fenster nicht mehr und zeigt mir überdies auch noch äußerst geräumig meine Arbeitsflächen an. Als zusätzlichen Bonus kann ich das Panel auch ein-/ausblenden mit Alt-B.

An diesem Punkt bemerke ich allerdings, dass xfceConfig eher dafür gedacht ist, xmonad *innerhalb* von Xfce zu betreiben und nicht andersherum, da ich xmonad z.B. nicht mehr mit Alt-Shift-Q beenden kann, da dies eine Xfce-Funktion aufruft, die ich aber gar nicht gestartet habe. Aus diesem Grunde stelle ich meine xmonad.hs ein wenig um:

~~~ haskell
import XMonad
import XMonad.Config.Desktop
main = xmonad desktopConfig
~~~

Weiters lösche ich alle Tastaturkürzel von Xfce (via Xfce-Einstellungen), da mir im Laufe meiner Tests ein paar der Kürzel in die Quere gekommen sind und ich die Kürzel ohnehin nie verwende.


Résumé
------


Mittlerweile habe ich ein ganz anständiges System, mit dem ich produktiv arbeiten kann. Es benötigt aber noch ein wenig Arbeit:

- Ich möchte mir noch Tastaturkürzel für einige Sachen, wie z.B. "Bildschirmfoto von aktuellem Fenster machen", definieren.
- An ein paar Stellen kollidieren Tastaturkürzel von Programmen mit den xmonad-Tastaturkürzeln, vornehmlich jenen, die mit dem Drücken der Alt-Taste beginnen. Ich habe Alt einmal auf die Windows-Taste umdefiniert (modMask), fand das allerdings so fürchterlich, dass ich wieder davon abgekommen bin, da das Drücken der Windows-Taste eine ziemliche Fingerakrobatik erfordert, wenn man mit der ganzen Hand auf der Tastatur "liegt". Zur Lösung dieses Problems habe ich noch überhaupt keine Idee.
- Manche Programme funktionieren noch nicht richtig im Vollbildmodus; z.B. VLC oder Parole. mplayer geht allerdings.
- Meine Xfce-Programme sollten beim Start von xmonad auch automatisch mitstarten. Bis jetzt führe ich meine Skripte noch manuell aus.
- Dadurch, dass ich xfdesktop nicht ausführe, kann ich meinen Bildschirmhintergrund nicht mehr einstellen.
- Die Schriften schauen auch an manchen Stellen noch komisch aus.

Ich hoffe, diese Punkte in einem anderen Artikel behandeln zu können, und hoffe, es war bis hierhin lehrreich! :)


[xmonad]: http://xmonad.org/
