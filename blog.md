---
layout: page
title: Blog
permalink: /blog/
---

I am including this blog as a place to discuss some of the technical aspects of my research and coding.  I've found that publishing papers about scientific models is a tricky business... the papers themselves must focus on the scientific application of the model, while all but the highest-level technical details are typically relegated to supplementary material.  But for models to be truly influential, I believe users should have a thorough understanding of their inner workings.  No black boxes!  Here, I hope to be able to delve into some of these technical details that perhaps aren't quite science-y enough for the primary literature, but that can be informative to others working with my code or on similar topics.

In addition, I'll be using this space to discuss the mostly-Matlab code that I have made available through my GitHub repository.  Consider those repositories a data dump of anything I wrote that may be useful to other scientists and engineers, while this is more of a selected portfolio discussing the thought process behind some of those entries.

<ul class="listing">
{% for post in site.posts %}
  {% capture y %}{{post.date | date:"%Y"}}{% endcapture %}
  {% if year != y %}
    {% assign year = y %}
    <li class="listing-seperator">{{ y }}</li>
  {% endif %}
  <li class="listing-item">
    <time datetime="{{ post.date | date:"%Y-%m-%d" }}">{{ post.date | date:"%Y-%m-%d" }}</time>
    <a href="{{ post.url }}" title="{{ post.title }}">{{ post.title }}</a>
  </li>
{% endfor %}
</ul>
