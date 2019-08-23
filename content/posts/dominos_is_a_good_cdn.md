---
title: "Domino's Is A Pretty Good Content Delivery Network For Pizza"
date: 2019-08-14T17:30:34-08:00
draft: true
---
Today on the "distributed systems as food service analogy" series we visit low
latency pizza delivery and how they relate to Content Delivery Networks (CDN).

Like with [Jimmy John's]({{< relref jimmy_johns_and_web_services >}}), I often
order Domino's pizza not because it tastes particularly good but because
Domino's is one of the only pizza places I know that offer a latency service
level objective ([SLO](https://en.wikipedia.org/wiki/Service-level_objective))
of less than thirty minutes. To achieve this promise, they use a number of
common techniques used by Content Delivery Networks (CDNs) to ensure web
content such as photos, code (javascript) and even videos get to your browser
or device quickly.

In this post we'll see how large online services keep their latencies low to
the user by observing the strategies that Domino's in particular, and pizza
delivery in general, have been using for years.

Technique #1: Many Points of Presence
=====================================

The primary way that Domino's ensures low latency to your door is by having
a large number of what the tech industry call's ["Points of
Presence"](https://en.wikipedia.org/wiki/Point_of_presence) aka `PoP`s. These
`PoP`s are physically close to the customer, which in the case of Domino's
means a driver can actually reach you within the thirty minute SLO. By placing
stores near users, Domino's is able to reduce the average latency that their
customers experience. It isn't enough, however, to just place pizza stores
physically proximate to homes, they have to be near major highways or transport
arteries so the delivery drivers can cover a particular delivery area in under
thirty minutes.

You can understand this intuitively by looking at how a "Big Pizza Shop" model
might work where a large store services many customers:

<center>![dominos_big_pizza](/img/dominos_big_pizza.svg)</center>

In this visualization a single grid tick represents one minute of time, so
our first customer spends about 2 minutes ordering his pizza, then the pizza
shop spends about 12 minutes lovingly hand tossing the dough and cooking the
pizza, and then the delivery driver must drive close to 20 minutes to get to
their door. In this example the end to end latency works out to ~35 minutes for
`Alice` and ~30 for `Bob`.

On the other hand, Domino's splits their pizza making endeavors into many
smaller points of presence which are closer to their customers. This model
allows the pizzas to arrive back at the customers in a mere 8-10 minutes,
bringing the delivery ETA to under the 30 minute SLO!

<center>![dominos_small_pizza](/img/dominos_small_pizza.svg)</center>

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

To meet the thirty minute SLO Domino's can't just have nearby stores, they
also have to be able to make the pizzas extremely quickly. While I have
never personally worked in a Domino's store, when I have on occasion visited
them it appears to me that they are making heavy use of pre-compute, where
you do work ahead of time so you don't have to do it during the actual user
request.

For example, the dough that they use appears to come in pre-formed into the
right size balls for various size pizzas and ready to roll and top. The sauce
is similarly pre-made to an order and toppings are also all pre-cut and ready
to go. This way when an order comes in, all the worker has to do is take the
pre-prepared dough and roll it, spread pre-made sauce on it, and sprinkle the
pre-prepared toppings on top. Just like we saw in the [Jimmy John's]({{< relref
jimmy_johns_and_web_services >}}) post, pre-making ingredients before a request
comes in can drastically reduce the latency.

This leads us to the "Domino's Model" where we have extremely fast ordering,
fast pizza making, and happy customers!

<center>![dominos_full](/img/dominos_pizza_full.svg)</center>

Is it lovingly hand tossed and finished with freshly cut vegetables and meats?
No, but it is extremely efficient and honestly, I kinda like the end result!

The most apt analogy for this is how tech companies pre-compute their
static assets (code, images, video) in various formats and packages before
they upload them to the CDNs. For example Netflix might encode a given
movie in various bitrates ahead of time so that the CDN just has to deliver
the right one. Another example is how Facebook pre-computes image thumbnails
and uploads all the various sizes and shapes of a given image asset to their
CDN so that, again, all the CDN has to do is return the right asset. A typical
web architecture that uses CDNs looks somewhat familiar:

<center>![dominos_cdn](/img/dominos_cdn.svg)</center>

Imperfect Analogy
=================

The CDN and Domino's analogy isn't perfect though. In particular, Domino's
either doesn't have to or cannot do some of the more interesting techniques
that CDNs must do to meet latency SLOs.

One such interesting technique that websites can use but that Domino's can't is
where browsers or applications fetch static content from CDNs before it is
actually needed a.k.a "pre-fetch".  Naturally if Domino's did this it would
lead to many confusing doorbell rings but I have often wondered how hard it
would be for Domino's to use a predictive model to forecast what toppings will
be most popular in a given town or time of week and optimize their just in time
network accordingly.

Another hard problem that tech companies have to solve that Domino's can skip
is which assets to store in the CDN and which assets to not store in the CDN.
Certainly there are some CDN use cases which are a total cache (the full
dataset is stored on every `PoP`), but for really huge caches you have to be
selective about what you put where. The only way Domino's would run into this
is if they started offering orders of magnitude more toppings and configurations,
which for the record I would personally be a fan of.

Summary: There is No Way Around Latency
=======================================

In this post we learned how with some relatively simple techniques (and as
before a lot of pre-compute), Domino's is able to deliver pizzas to your door
fast just like web services serve up pictures of cat pictures fast. Both
systems:

1. Utilize many hundreds of Points of Presence (`PoP`s) to drive latency
   down.
2. Optimally place `PoP`s near major transportation (internet) hubs to
   provide low latency.
3. Pre-compute as much as possible so that the final assembly of the
   pizza (request) can be done as fast as possible.

Indeed, any service that wants to minimize latency to users such as Domino's
pizza delivery, package shipping and distribution, or even distributing
videos on the web can benefit from these simple techniques.
