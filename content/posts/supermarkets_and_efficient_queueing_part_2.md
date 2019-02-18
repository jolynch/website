---
title: "Supermarkets And Efficient Queueing: Part 2"
date: 2019-01-10T14:42:15-08:00
draft: true
---

Today we're going to talk about **queuing theory**, and how we can understand
it with the help of your every day supermarket or grocery store.

Lesson #3: When you have the wrong queue, cheat
-----------------------------------------------

Unfortunately for you and me, supermarkets frequently choose the wrong way to
queue their customers with individual queues per register. Computer programs
also often don't know how large the queues are at various computers or on
various cores. The bright news is that there is a great technique we can borrow
from high performance distributed systems: tied requests (aka request
speculation).

With speculative/tied requests we as the customer try to get the fastest
service time by dispatching to two or more workers, and you take whichever gets
there first. Crucially to be efficient we have to drop the redundant request
when the first starts being processed, however, we can still get a nice latency
improvement even without this cancellation as shown in \[[2](#tail_at_scale)\].

This is just like in a supermarket where a couple will split up and have one
person wait at one register and the second person waits at a different
register. Whoever gets to the cashier first tries to frantically signal to the
other person "hey come over here we can check out together" and they succeed
at reducing their latency with no real decrease to throughput, although your
fellow customers may be peeved at the surprise arrival of a potentially larger
order.

Lesson #4: Separate out different kinds of work
-----------------------------------------------
The final way that supermarkets relate to high performance computing is work
separation. We are all familiar with the "15 items or less" lines at
supermarkets, but did you know that this is actually a really effective way
to minimize average slowdown? Queueing theorists did! \<TODO: link TAGS followup
paper\>.

When you create dedicated queues for the "fast" customers, you guarantee that
quick checkouts cannot queue behind slow grandmas, and while you sacrifice a
little bit of throughput to get this, your average slowdown goes way down
because the slow tasks can never penalize the fast ones. The throughput
decreases because when there are few 15 item customers, you are effectively
losing cashiers that could be servicing the slower masses. I love that
supermarkets mostly get this right, but I do wish that they would do more of
this based on metrics other than number of items, such as payment method.
Indeed a queuing theorist would say if you pay with cash or a check you should
get directed to the "super slow" lanes.

It turns out that computer systems can benefit from the same type of isolation
of work we think will be fast (aka "latency sensitive" or "interactive"
requests) from work that we know will take a long time (aka "batch" or
"offline" requests). This is why you may see dedicated web workers or database
replicas just for handling offline traffic, and also why CPU pinning will
always beat CPU shares for mixed latency+batch workloads \<TODO: link Herecles\>

It's important to recognize, however, that there are real tradeoffs here,
especially if you size the worker pools incorrectly (for example, if you
had a dozen "15 items or less" cashiers but only a single normal cashier, then
your customers with more than 15 items will be very unhappy.

Lesson #5: When queues form, autoscale and re-assign workers
------------------------------------------------------------

I mentioned earlier that supermarket employees can take on many roles, very
similar to how CPUs can run different programs. Interestingly, this ability
to change what someone is doing with a task switch can be very valuable and
can help mitigate some of the issues with the previous strategy of separating
out work.

One of the most efficient grocery stores I know, the Military PX, does this
really cool thing where baggers automatically turn into cashiers when enough of
a customer queue starts forming. The supermarket actually *autoscales* their
cashiers. They also only do this when the queue get's large enough to justify
the context switching costs of moving a worker from one task to another. This
technique of worker re-assignment allows us to re-capture some of the lost
throughput we got from separating out 15 item customers from the rest because
when there are not enough 15 item customers to justify the cashiers we can
re-allocate those cashiers to the normal pool.

This kind of work re-prioritization is common in computers, for example servers
run processes with different priorities (the "bagging" process has lower
priority than the "customer checkout" process). It's also similar to work
shedding, where when computer systems get overloaded they might decide to stop
doing less critical functions (bagging) to prioritize high priority work
(checking out). Indeed now that everyone is moving their web services to
the cloud, software engineers can do this for their web services as well by
re-allocating cores/machines from running background or less important tasks to
running latency sensitive tasks when we need to. The whole AWS spot market is
built on the notion of "while there are free baggers lying around we'll do your
relatively unimportant work, but when customers show up we're stopping with the
complimentary bagging and re-assign these baggers to work the cashier".


Conclusion
==========

We've seen how supermarkets and high performance software services actually
have a lot in common. We have learned how both can take advantage of basic
performance practices:

1. Use a smaller number of queues when you are worker bound that dispatch to
   free workers rather than having a queue per worker. This will increase
   throughput and decrease mean slowdowns.
2. When you have multiple queues of unknown duration and latency is crucial,
   dispatch to multiple queues and race them against each other to get minimal
   latency.
3. When you can, separate out work into groups that are roughly similar in
   duration to minimize mean slowdown.
4. If you are separating out workers, make sure to dynamically re-assign them
   to different pools so you don't decrease throughput by too much.

We have also learned how supermarkets could improve if more worked like the
Military PX with single lines that dispatch to free workers instead of multiple
checkout lines. Maybe more supermarkets will someday see the light of better
queueing theory and I'll have less time to think about how I'm wasting time
in line waiting to checkout.


Citations
=========
<a name="ref1"></a>
[1] M. Harchol-Balter, Performance Modeling and Design of Computer Systems:
Queueing Theory in Action.

<a name="tail_at_scale"></a>
[2] Jeffery Dean and Luiz Andre Barroso, The Tail at Scale (https://ai.google/research/pubs/pub40801)


