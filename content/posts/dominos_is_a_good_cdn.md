---
title: "Dominos Is A Pretty Good Content Delivery Network"
date: 2019-08-14T17:30:34-08:00
draft: true
---
Today on the "distributed systems as food service analogy" series we visit low
latency pizza delivery and how they relate to large website's use of Content
Delivery Networks (CDN).

Like with [Jimmy John's]({{< relref jimmy_johns_and_web_services >}}), I often
order Dominos pizza not because it tastes particularly good but because
Domninos is one of the only pizza places I know that offer a latency service
level objective (SLO) of less than thirty minutes. To achieve this promise,
they use a number of techniques common in today's high performance content
delivery networks (CDNs).

In this post we'll see how large online services keep their latencies low to
the user by observing the strategies that Dominos and pizza delivery have been
using for years.

Technique #1: Many Points of Presence
=====================================

The primary way that Dominos ensures low latency to your door is by having
a large number of what the tech industry call's "Points of Presence" aka
`PoP`s. These `PoP`s are physically close to the customer, which in the
case of Dominos means a driver can actually reach you within the thirty
minute SLO. By placing stores near users, Dominos is able to reduce the
average latency that their customers experience. It isn't enough, however,
to just place pizza stores physically proximate to homes, they have to be
near major highways or transport arteries so the delivery drivers can cover
a particular delivery area in under thirty minutes.

As it turns out, this is more or less exactly how large websites like Google,
Facebook, and Netflix guarantee low latency delivery of webpages, images and
very importantly video. All of these services rely heavily on similar `PoP`s
that are physically proximate to (likely in the same building) local internet
service providers (ISPs). These `PoP`s store large, typically static, content
such as client side code (javascript), images (mostly cat pictures), and of
course videos. This global storage network is called a content delivery
network and while web services might run their core business logic from a
relatively small (~10s) number of large datacenters that are likely hundreds of
milliseconds away, customers can often be served entirely from a local `PoP`
which is plugged directly into the local ISPs. This technique shaves orders
of magnitude off the latency that customers experience.

Technique #2: Pre-compute All the Things
========================================

To meet the thirty minute SLO Dominos can't just have close stores, they
also have to be able to make the pizzas extremely quickly. While I have
never personally worked in a Dominos store, when I have on occasion visited
them it appears to me that they are making heavy use of pre-compute, where
you do work ahead of time so you don't have to do it during the actual request.

For example, the dough that they use appears to come in regularly (daily?)
already formed into the right size balls for various size pizzas and ready to
roll and top. The sauce is similarly pre-made and toppings are also all pre-cut
and ready to go. This way when an order comes in, all the worker has to do is
take the pre-prepared dough and roll it, spread pre-made sauce on it, and
sprinkle the pre-prepared toppings on top. Just like we saw in the
[Jimmy John's]({{< relref jimmy_johns_and_web_services >}}) post, pre-making
ingredients can drastically reduce the latency.

The most apt analogy for this is how tech companies pre-compute their
static assets (code, images, video) in various formats and packages before
they upload them to the CDNs. For example Netflix might encode a given
movie in various bitrates ahead of time so that the CDN just has to deliver
the right one. Facebook pre-computes image thumbnails and uploads all the
various sizes and shapes of a given image asset to the CDN so that, again,
all the CDN has to do is return the right asset.


Imperfect Analogy
=================

The CDN and Dominos analogy isn't perfect though. In particular, Dominos
either doesn't have to or cannot do some of the more interesting techniques
that CDNs must do to meet latency SLOs.

One such interesting technique that websites can use but that Dominos can't is
where browsers or applications fetch static content from CDNs before it is
actually needed aka "pre-fetch".  Naturally if Dominos did this it would lead
to many confusing doorbell rings but I have often wondered how hard it would be
for Dominos to use a predictive model to predict ahead of time what toppings
will be most popular in a given town or time of week.

Another hard problem that tech companies have to solve that Dominos can skip
is which assets to store in the CDN and which assets to not store in the CDN.
Certainly there are some CDN use cases which are a total cache (the full
dataset is stored on every `PoP`), but for really huge caches you have to be
selective about what you put where. The only way Dominos would run into this
is if they started offering orders of magnitude more toppings and configurations,
which for the record I would personally be a fan of.

Summary: There is No Way Around Latency
=======================================

In this post we learned how with some relatively simple techniques (and as
before a lot of pre-compute), Dominos is able to deliver Pizzas to your door
fast just like web services serve up pictures of cat pictures fast. Both
systems:

1. Utilize many hundreds of Points of Presence (`PoP`s) to drive latency
   down.
2. Optimally place `PoP`s near major transportation (internet) hubs to
   provide low latency.
3. Pre-compute as much as possible so that the final assembly of the
   pizza (request) can be done as fast as possible.

Indeed, any service that wants to minimize latency to users such as Dominos
pizza delivery, package shipping and distribution, or distributing movies on
the web can benefit from these simple techniques.
