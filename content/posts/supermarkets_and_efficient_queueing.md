---
title: "Supermarkets And Efficient Queueing"
date: 2019-01-10T14:42:15-08:00
draft: true
---

Today we're going to talk about **queuing theory**, and how we can understand
it with the help of your every day supermarket or grocery store.

Why do we care about Queueing Theory?
=====================================
Software engineers spend a lot of time optimizing queues of work. Everything
we do in a computer boils down to having some work to do, keeping that work
in a queue, and then having processors that can do the work. Our systems
generally work well when the queues do not grow without bound. Some examples
are CPU scheduling processes, python web worker load balancing, processing
work items from something like Kafka and even background processing tasks such
as sending emails or resizing images.  Many software bugs boil down to "the
thing started taking twice as long and we couldn't keep up so the queue grew
without bound and everything died". With a little understanding of how queueing
theory works, we can make our code a lot faster and more efficient.

As queues are so fundamental, there is a whole discipline that surrounds them,
called _queueing theory_. There is a lot of math behind it, but to get a bit
of intuition one need only look at a suburban classic: the Supermarket.

How does Queueing Theory have to do with Supermarkets?
======================================================

I spend a lot of time waiting in line at Supermarkets, and I spend an
enbarassing quantity of that time thinking about how they are making queueing
theory tradeoffs. Supermarkets usually have multiple employees that can
run cash registers, or bag groceries, or help customers. Customers arrive with
varying durations of work, some of them are buying just a few items and some
are buying massive quantities of food such as delicious Mac and Cheese.

This is just like a web service that a software engineer that works on the
backend of a website might write, except that the food to check out
are web requests and the employees are CPUs running a web worker (be it a
thread or a process, it's still a worker). Often different requests are more
expensive than others, they might require more computation, and our goal is
to service them as quickly and fairly as possible.

It turns out that people who design supermarkets (food distribution engineers
shall we say) and software engineers have similar goals: process the maximum
number of customers (requests) with most efficient use of employees (workers).

Lesson #1: Use the right kind of queue
--------------------------------------

Supermarkets generally queue their customers in two ways:

1. Have a separate queue for each register, customers self select based on
   superstition or gut feeling.
2. Have a single queue where customers wait until they are dispatched to the
   first free register, typically through a signaling mechanism such as a
   flashing light.

Which is better? It turns out that *by far* the second technique leads to higher
throughput in terms of customers processed per minute and a much lower
average slowdown in terms of how long customers wait to be checked out.
This is because \<TODO:insert math\>

Intuitively we know that the second way is faster because the probability of
you choosing a lane that has a "slow grandma" (less ageist might say a "large
quantity of Mac and Cheese to check out) is significantly higher in the first
method. With the first technique you are going to be stuck behind a slow
grandma if *any* of the people in front of you turn out to be a slow task,
vs in the second technique all of the registers have to be busy with slow
grandma's before you will block behind one.

This equally applies to computer programs: if you have more work to do then you
have workers to do it, try to keep the work in a single queue as long as
possible. When you do dispatch your work try to dispatch it to a worker that
is free. For example if you're running a website try to give a request to a
machine that has a free web worker _right now_.

Lesson #2: When you have the wrong queue, cheat
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
improvement even without this cancellation \<TODO: link tail at scale\>.

This is just like in a supermarket where a couple will split up and have one
person wait at one register and the second person waits at a different
register. Whoever gets to the cashier first tries to frantically signal to the
other person "hey come over here we can check out together" and they succeed
at reducing their latency with no real decrease to throughput, although your
fellow customers may be peeved at the surprise arrival of a potentially larger
order.

Lesson #3: Separate out different kinds of work
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

Lesson #4: When queues form, autoscale and re-assign workers
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
