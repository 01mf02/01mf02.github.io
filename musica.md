---
layout: page
title: Musica
permalink: /musica/
---

Hier finden sich Eigenkompositionen, Liedübersetzungen und Arrangements.

<ul class="post-list">
{% for post in site.posts %}
  {% if post.categories contains 'musica' %}
    {% include post.html %}
  {% endif %}
{% endfor %}
</ul>
