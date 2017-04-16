---
layout: page
title: Erasmus
permalink: /erasmus/
---

Praha
-----

<img src="/media/michaelfaerber2014.jpg" style="float: right; margin: 10px;" />

2016 habe ich mich für ca. vier Monate in Prag aufgehalten.
Hier befinden sich die Artikel aus jener Zeit.

<ul class="post-list">
{% for post in site.posts %}
  {% if post.categories contains 'erasmus' and post.categories contains 'praha' %}
    {% include post.html %}
  {% endif %}
{% endfor %}
</ul>


Praha
-----

<img src="/media/michaelfaerber2012.jpg" style="float: right; margin: 10px;" />

Hier finden sich die Artikel, die ich
während meines Erasmus-Aufenthalts 2012/13 in Bordeaux
auf der Seite [You can make IT](https://youcanmakeit.at/blog/) geschrieben habe.
Bonne lecture ! :)

<ul class="post-list">
{% for post in site.posts %}
  {% if post.categories contains 'erasmus' and post.categories contains 'bordeaux' %}
    {% include post.html %}
  {% endif %}
{% endfor %}
</ul>
