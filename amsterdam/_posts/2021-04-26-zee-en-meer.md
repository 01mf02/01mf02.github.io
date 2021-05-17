---
title: Zee en Meer
stylesheets: https://unpkg.com/leaflet@1.7.1/dist/leaflet.css
scripts: https://unpkg.com/leaflet@1.7.1/dist/leaflet.js
---

In der Woche vom 12. April begann gefühlt der Sommer in Amsterdam.
Die Menschen rauchten ein gemütliches Jointerl oder tranken ein Glaserl Wein
vor ihren Häuser, und die Parks füllten sich erneut mit Leben.
Eine ganz neue Atmosphäre machte sich breit.

{% include image.html caption="Zomer in Amsterdam." media="IMG_20210413_180942.jpg" %}

Ich nutzte das schöne Wetter, um einen zweiten Anlauf Richtung Meer zu wagen.
Diesmal sollte es mir gelingen, die psychologische Haarlemer Schranke zu überwinden.
Ursprünglich wollte ich bei [Zandvoort aan Zee] das Meer erreichen.
Doch schon einige Kilometer nach Haarlem hörte ich von einer Aussichtsplattform aus
laute Motorengeräusche (die bei weiterer Annäherung immer stärker wurden) aus Richtung Zandvoort,
und auch die Hochhauskulisse Zandvoorts verzauberte mich enden wollend.
So entschloss ich mich dazu, Zandvoort zu umfahren und erst bei Bloemendaal das Meer zu erreichen.
Bei dem Weg dorthin kam ich direkt an der Lärmquelle vorbei, nämlich dem [Circuit Park Zandvoort],
wo übrigens Niki Lauda das bisher letzte Rennen gewonnen hatte.
Nach der Rennstrecke ging es durch eine sehr
kurvige, windige und etwas eintönige Dünenlandschaft nach Bloemendaal.
Dort angekommen allerdings weder eine Spur vom Meer noch von Blumen,
jedoch eine mäßig einladende Betonwüste.
So fuhr ich noch ein Stück weiter zu einem Ort namens Parnassia aan Zee,
wo ich endlich das Meer erblickte (und mir einen Kaffee gönnte).

{% include image.html caption="Heimlicher Star: die Möwe." media="IMG_20210416_162025.jpg" %}

{% include image.html caption="Kitesurfer und Hochhäuser." media="IMG_20210416_164344.jpg" %}

Das Wasser machte leider keinen sehr einladenden Eindruck, und ein paar Damen,
die nach wenigen Sekunden Wasserkontakt schnell wieder umdrehten, bestätigten dies.
Die zahlreichen Kitesurfer ließen sich davon jedoch nicht abschrecken.

An dieser Stelle ein wenig Linguistik:
Der Niederländer nennt das Meer "Zee", und den See (wie auch das deutsche "mehr") "Meer".
Der Titel dieses Artikels ist somit mehrdeutig:
Entweder "Meer und mehr", oder "Meer und See". :)

Zurück Richtung Haarlem ging es durch eine pittoreske, wenn auch etwas triste Dünenlandschaft.

{% include image.html media="IMG_20210416_165716.jpg" %}

{% include image.html caption="Man beachte die windbedingte Neigung der Bäume." media="IMG_20210416_171050.jpg" %}

<figure class="image">
<div id="map" style="height: 600px;"></div>
<figcaption>Amsterdam -- Haarlem -- Zandvoort -- Santpoort -- Spaarndam -- Amsterdam.</figcaption>
</figure>
<script>
var newMap = L.map('map');
L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(newMap);
fetch('{% include media %}/zee.geojson')
  .then(response => response.json())
  .then(data => newMap.fitBounds(L.geoJson(data).addTo(newMap).getBounds()));
</script>

Am Dienstag, den 20. April, fuhr ich wie geplant mit dem Zug nach Österreich.
Dabei kam ich auch durch Utrecht, welches ich im letzten Artikel als potenzielle
Wohnort-Alternative zu Amsterdam ins Spiel gebracht hatte.
Doch fand ich die Hochhauskulisse um den Bahnhof herum so hässlich,
dass ich diesen Plan eilends wieder verwarf.
In Richtung der deutschen Grenze wies mich dann ein Schaffner darauf hin,
dass ich für die Durchreise durch Deutschland einen PCR-Test benötige,
sofern ich nicht ohne Umstieg mit dem Zug weiter zu seinem Endbahnhof Basel führe.
Mein Hinweis auf die geltenden Richtlinien, die nichts von Umstiegen erwähnen,
quittierte er mit dem Hinweis, dass ich dann eben 500€ in Deutschland zahlen müsse,
sollte ich kontrolliert werden, und legte mir nahe, in Arnhem auszusteigen und einen Test nachzuholen.
Nachdem ich mich jedoch im Recht wähnte, blieb ich im Zug sitzen,
nicht ohne aber an der Grenze etwas ins Schwitzen zu geraten.
Doch an der Grenze und auch danach fand keine Kontrolle statt,
sodass ich glücklicherweise nicht mit deutschen Polizisten streiten musste.
Nach diesem Zwischenfall ging alles wie am Schnürchen,
und ohne eine einzige Minute Verspätung erreichte ich planmäßig die Karwendelbahn in München.
In Scharnitz war ebenfalls keine Kontrolle,
jedoch überraschte mich mein Cousin im Zug, sodass wir zu zweit
die wunderbare Abfahrt zwischen Seefeld und Innsbruck bei Sonnenuntergang genießen konnten.

Am Mittwoch ließ ich mich beim Olympiastadion testen.
Ich war von der Geschwindigkeit und dem reibungslosen Ablauf sehr beeindruckt.
Danach ging ich wie vorgesehen in Quarantäne, die ich
für meine Arbeit glücklicherweise produktiv nutzen konnte.
Am Sonntag ließ ich mich dann zum zweiten Mal testen,
und machte dann nach Erhalt meines negativen Ergebnisses (per SMS)
eine Rodeltour in [Praxmar], um doch noch ein bisschen Wintergefühl genießen zu können.

[Zandvoort aan Zee]: https://de.wikipedia.org/wiki/Zandvoort
[Circuit Park Zandvoort]: https://de.wikipedia.org/wiki/Circuit_Park_Zandvoort
[Praxmar]: http://www.winterrodeln.org/wiki/Praxmar
