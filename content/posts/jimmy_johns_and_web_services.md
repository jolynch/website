---
title: "Jimmy John's is like a High Performance Web Service"
date: 2019-02-25T00:00:00-00:00
---
Today on the "distributed systems as food service analogy" series we visit one
of my favorites: sandwich shops.

Most sandwich places are absolutely terrible at efficiently processing my
sandwich order. They have limited workers that constantly context switch and
are entirely unable to pipeline (looking at you Subway). [Jimmy
Johns](https://www.jimmyjohns.com/), however, is wonderfully efficient and a
model for all other sandwich places.

In this post I will explore how Jimmy Johns operates as a high performance web
(micro)service might. When I worked at Yelp in San Francisco, I spent a great
deal of time eating at Jimmy Johns, and a non trivial reason for that is that
it was so *efficient* at processing orders. I would show up and there would be
a queue of 20-50 people, but I still got my sandwich in record time (a few
minutes). At least the one near Yelp's SF office achieved this by operating as
a finely tuned web service might, and I feel it's worth reflecting on all of
the tricks they do. If you're building a high performance service and you
aren't doing these things, it's food for thought.

So, what does Jimmy John's Do?
==============================

At the end of the day, Jimmy John's is trying to provide sandwiches as a
service. A customer walks up with a sandwich order of varying complexity and
duration, and Jimmy John's tries to make it for them as fast as possible. They
handle dozens of concurrent requests that might range in complexity from simple
"I'll have roast beef and some provolone" to the more complex "J.J. Gargantuan
hold the oregano and extra tomatoes".

In my experience Jimmy John's is able to achieve average processing times in
less than 30 seconds from when I place my order to when I receive it, and the
end to end experience even under heavy load is a few minutes. In queueing
theory terms they achieve an impressive `T_processing` of ~30s and `T_queued`
of two minutes under heavy load leading to a `Slowdown` of ~4 and excellent
end-to-end latency and therefore throughput. They are able to increase their
throughput by accepting multiple concurrent orders (I typically observe about 5
in flight) and fulfilling them all in parallel giving their throughput an even
bigger boost. A quick online search indicates that Jimmy Johns actually
holds a yearly [competition](https://vimeo.com/289769768) called "Sandwich
Masters", so you know they take this seriously.

My favorite part of this all though is that Jimmy Johns achieves these great
speeds using a number of tricks common in high performance web services that I
have worked on.

Trick #1: Avoid Context Switches
--------------------------------

One of the biggest enemies of high performance systems is the ["context
switch"](https://en.wikipedia.org/wiki/Context_switch).  The name comes from
when CPUs have to switch from one running process to the other, which causes a
significant delay in processing, but the concept is actually pretty general. A
context switch in the general sense is simply when a system goes from doing one
thing to doing another. This change in activity usually takes some time that
you could have been using to do real work.

One of the most common ways that sandwich shops context switch is when the same
person takes your order, retrieves your food, and has you pay. For example, at
Subway, a worker might context switch *four or more times* in a single order:

1. Take your order,
2. Make the sandwich
3. Toast your sandwich (uh oh cache miss)
4. *Context Switch* back to take another person's order while your sandwich
  toasts. The ordering takes longer than your sandwich takes to toast so
  you start waiting on the person to come back.
5. *Context Switch* to add toppings to your sandwich
6. Switch to register to ring you up

The biggest delays at Subway happen for me when we get to step 4 above, where
the worker context switches to take another order which can take longer than
my sandwich takes to toast. This kind of pre-emption based on IO bound work
(toasting the sandwich) is called asynchronous processing and is generally
a good thing, but in this case the context switch costs non trivial time and
can result in slowing down the order.

Jimmy John's doesn't do this. Jimmy John's has dedicated accept workers like
high performance proxies use (e.g. [HAProxy](http://www.haproxy.org/) and
[NGINX](https://www.nginx.com/)). These workers just accept orders and dispatch
them to the appropriate downstream worker. They also use async processing by
handing off the compute bound part (making the sandwich) but without the
context switch. This saves time because the workers never have to context
switch, they just process order after order and dispatch that work to highly
efficient sandwich making workers. It looks a little like:

<center>![jj_single_queue](/img/jimmy_johns_single_queue.svg)</center>

Jimmy John's does three more things crucially right here:

1. They have a single queue going into the register (see my post on
   [Supermarkets and Efficient Queueing: Part 1]({{< relref
   supermarkets_and_efficient_queueing_part_1 >}}) to see why that's a good
   idea). This increases throughput and decreases mean slowdown by decreasing
   the likelihood that a worker is idle.
2. They have more than one accept worker in case an order takes a long time to
   accept. This helps ensure we don't run into the slow request problem where a
   single slow item blocks the whole queue
3. Finally, they hand the customer back the ticket and tell them to go to the
   end of the processing pipeline to receive their order _directly from the
   worker making the sandwich_. That's right, Jimmy John's does _direct return_
   to their customers.  The sandwich doesn't waste time being passed back up to
   the register (looking at you McDonald's), it just goes straight to the
   customer.

Direct return is, in particular, really neat because it's what high performance
routing layers like Google's Maglev [[1](#maglev)] do to try to offload heavy
network results off their load balancers (and instead have the servers return
the bytes directly to the requester).

Trick #2: Parallel Pipelines
----------------------------

Jimmy John's doesn't just get its speed from avoiding context switches, it
also cuts significant time by using [*parallel
processing*](https://en.wikipedia.org/wiki/Parallel_computing). In a web
service you might run multiple workers that each run their own compute
pipelines. You do this so that one slow order can't block all the fast ones.
You also do this to allow different workers (services in software land) to
specialize and process their work faster and more efficiently.

Jimmy John's nails parallel processing. Not only does it have multiple lanes
to make multiple sandwiches in parallel, but they even sometimes re-order
or prioritize orders to make sure that large complex orders don't unnecessarily
slow down short orders. This in turn keeps mean processing time and mean
slowdown way down. We can now add the parallel sandwich pipelines to the Jimmy
Johns model:

<center>![jj_system](/img/jimmy_johns_whole_system.svg)</center>

I'm not sure if the pipelines are specialized, as in I'm not sure if certain
orders like roast beef go to one lane and other orders like Italian sandwiches
go to another lane. If they did do this it would be pretty neat because the
workers could probably cut processing time by only having to handle a subset of
the menu in the general case. Of course this would mean that they'd have to
have good sandwich load balancing to make sure no one lane got overloaded, or
dynamically re-assign the workers when there is extra capacity.

Trick #3: Pre-Compute Cache misses
----------------------------------

Another interesting thing I've noticed at Jimmy John's is that they have
background workers who are constantly re-filling the pre-allocated sandwich
materials for the workers that are running low on various meats or cheeses. Not
only does this avoid the sandwich worker context switching, but it's a great
example of pre-compute caches that are becoming really popular these days.

In the past few years, software engineers have realized that you can watch
for pending demand changes and pre-compute the cache entries for that demand.
For example, if you use [change data
capture](https://en.wikipedia.org/wiki/Change_data_capture) (CDC) from your
database to inform offline cache pre-compute systems which goes off, calculates
the value a cache should have and writes it into the cache pre-emptively, you
can significantly improve your cache hit rate and keep systems running fast. A
common example of this in industry are cache invalidation systems like
Facebook's `mcsqueal` [[2](#fb_memcache)] and Yelp's
[casper](https://engineeringblog.yelp.com/2018/03/caching-internal-service-calls-at-yelp.html)
project which uses CDC to [invalidate
caches](https://engineeringblog.yelp.com/2018/03/caching-internal-service-calls-at-yelp.html#invalidating-caches).

Jimmy John's appears to me to do pre-compute demand caches. They notice that a
lane will run out of roast beef and pre-emptively have a background worker go
and re-fill the roast beef, Wicked.


Summary: Jimmy John's is Very Efficient
=======================================

In this post we explored how Jimmy John's exploits the following concepts
in high performance computing:

1. Minimize context switches with dedicated workers accepting sandwich
   requests, processing sandwiches, and direct returning results directly
   to the customer.
2. Maximize throughput with full parallelism across multiple specialized
   workers
3. Increase sandwich output rate by using background workers to pre-fetch
   cache misses.

Many food service shop do some of these techniques, but I am not aware of one
that combines so many best practices in high performance systems engineering
in one, very fast, sandwich making package.

Citations
=========
<a name="maglev"></a>
[1] Daniel E. Eisenbud, Cheng Yi, et al. "Maglev: A Fast and Reliable Software
Network Load Balancer"
([pdf](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/44824.pdf))

<a name="fb_memcache"></a>
[2] Rajesh Nishtala, Hans Fugal, et al. "Scaling Memcache at Facebook" ([pdf](https://www.usenix.org/system/files/conference/nsdi13/nsdi13-final170_update.pdf))

