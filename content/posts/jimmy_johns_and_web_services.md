---
title: "Jimmy John's is like a High Performance Web Service"
date: 2019-01-15T14:12:04-08:00
draft: true
---

Most sandwich places are absolutely terrible at efficiently processing my
sandwich order. They have limited workers that constantly context switch and
are entirely unable to pipeline (looking at you Subway). Jimmy Johns, however,
is wonderfully efficient and a model for all other sandwich places.

In this post I will explore how Jimmy Johns operates as a high performance web
(micro)service might. When I worked at Yelp I spent a great deal of time eating
at Jimmy Johns, and a non trivial reason for that is that it was so *efficient*
at processing orders. I would show up and there would be a queue of 20-50
people, but I still got my sandwich in record time (a few minutes). At least
the one near Yelp's SF office achieved this by operating as a finely tuned
web service might, and I feel it's worth reflecting on all of the tricks they
do.

So, what does Jimmy John's Do?
==============================

At the end of the day, Jimmy John's is trying to provide sandwiches as a
service. A customer walks up with a sandwich order of varying complexity and
duration, and Jimmy John's tries to make it for them as fast as possible.

In my experience Jimmy John's is able to achieve average processing times in
less than 30 seconds from when I place my order to when I receive it, and the
end to end experience even under heavy load is a few minutes. This is
astoundingly good, and to do this they have to use a number of tricks common
in high performance web services.


Trick #1: Avoid Context Switches
--------------------------------

One of the biggest enemies of high performance systems is the "context switch".
The name comes from when CPUs have to switch from one running process to the
other, which causes a significant delay in processing, but the concept is
actually pretty general. A context switch is simply when a system goes from
doing one thing to doing another. This change in activity usually takes some
time that you could have been using to do real work.

One of the most common ways that sandwich shops context switch is when the same
person takes your order, retrieves your food, and has you pay. For example, at
Subway, a worker might context switch four or more times:

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
(toasting the sandwich) is called asyncronous processing and is generally
a good thing, but in this case the context switch costs non trivial time and
can result in slowing down the order.

Jimmy John's doesn't do this. Jimmy John's has dedicated accept workers like
high performance proxies use (e.g. NGINX). These workers just accept orders
and dispatch them to the appropriate downstream worker. They also use async
processing by handing off the compute bound part (making the sandwich) but
without the context switch. This saves time because the workers never have to
context switch, they just process order after order and dispatch that work to
highly efficient sandwich making workers.

Jimmy John's does three more things crucially right here. First they have a
single queue going into the register (see my post on supermarkets to see why
that's a good idea). This increases throughput and decreases mean slowdown.
Second they have more than one accept worker in case an order takes a long time
to accept. This helps ensure we don't run into the slow grandma problem where a
single slow item blocks the whole queue. Finally, they hand the customer back
the ticket and tell them to go to the end of the processing pipeline to receive
their order _directly from the worker making the sandwich_. That's right, Jimmy
John's does _direct return_ to their customers.  The sandwich doesn't waste
time being passed back up to the register (looking at you McDonald's), it just
goes straight to the customer.

Almost nowhere in this system is there a context switch, just highly tuned
order accept workers handing off to sandwich making workers, directly
returning the sandwich back to the customer.

Trick #2: Parallel Pipelines
----------------------------

Jimmy John's doesn't just get its speed from avoiding context switches, it
also cuts significant time by using *parallel processing*. In a web service you
might run multiple workers that each run their own compute pipelines. You
do this so that one slow order can't block all the fast ones. You also do this
to allow different workers (services in software land) to specialize and
process their work faster and more efficiently.

Jimmy John's nails parallel processing. Not only does it have multiple lanes
to make multiple sandwiches in parallel, but they even sometimes re-order
or prioritize orders to make sure that large complex orders don't unncessarily
slow down short orders. This in turn keeps mean processing time and mean
slowdown way down.

I'm not sure if the pipelines are specialized, as in it appears to me that
certain orders like roast beef go to one lane and other orders like Italian
sandwiches go to another lane. If they did do this it would be pretty neat
because the workers could probably cut processing time by only having to
handle a subset of the menu in the general case. Of course this would mean
that they'd have to have good sandwich load balancing to make sure no one
lane got overloaded, or dynamically re-assign the workers when there is
extra capacity.

Trick #3: Pre-Compute Cache misses
----------------------------------

Another interesting thing I've noticed at Jimmy John's is that they have
background workers who are constantly re-filling the pre-allocated sandwich
materials for the workers that are running low on various meats or cheeses. Not
only does this avoid the sandwich worker context switching, but it's a great
example of pre-compute caches that are becoming really popular these days.

In the past few years, software engineers have realized that you can watch
for pending demand changes and pre-compute the cache entries for that demand.
For example, if you use change data capture from your database to inform
offline cache pre-compute systems which goes off, calculates the value a cache
should have and writes it into the cache pre-emptively, you can significantly
improve your cache hit rate and keep systems running fast.

Jimmy John's does pre-compute demand caches. They notice that a lane will run
out of roast beef and pre-emptively have a background worker go and re-fill
the roast beef, Wicked.


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
in one, very fast, package.
