---
title: "How to Speed up the DMV"
date: 2020-01-02T12:00:00-08:00
tags: ["real-life-queueing"]
---

I've been asked to apply some of the lessons learned from the ["distributed
systems as food service analogies"]({{< ref "/tags/distsys-as-food" >}}) to
something unrelated to food but that does devour Americans' souls: the
Department of Motor Vehicles (DMV).

The DMV is where happy Americans go to wait, sometimes for many moons, just to
be told that they have the wrong identifying documents for a driver's license
renewal. It is an unfortunately dreadful introduction to government
bureaucracy, and is a uniform topic of derision for newly driving teenagers
(and indeed adults) across the US. It is so dreadful that it is even mocked in
[children's movies](https://www.youtube.com/watch?v=ONFj7AYgbko).

In this post I will attempt to apply basic queueing theory and performance
analysis to the DMV, the same way I would to a distributed system. Some State's
DMVs are already doing some of the proposals I make, for example California
generally does a better job than Maryland (in my experience), but they can all
improve by scientifically analyzing their bottlenecks and continuously
optimizing using data driven decisions.

Step 1: Gather Data
===================

The first step of scientific performance analysis is to rigorously measure the
system under test. Measuring key metrics allows system engineers to propose and
test improvements scientifically. We incrementally develop theories, devise
experiments, run the experiments, measure the results and finally update our
mental models which allows us to develop new theories. All performance analysis
and optimization works in this continuous fashion whether you are optimizing
distributed systems, pizza delivery, or issuing form MC-706-M.

<center><h3>Performance Analysis</h3></center>
<center>![performance analysis](/img/performance_analysis.svg)</center>

In most distributed systems we might care about the system throughput we can do
at different levels of concurrent load, or the distribution of service times.
We may want to optimize
[mean latency]({{< relref supermarkets_and_efficient_queueing_part_1 >}}),
or [mean slowdown]({{< relref supermarkets_and_efficient_queueing_part_2 >}}),
or sacrifice a little time on average to keep our high percentile service time
lower. For the DMV to improve, we must first collect actionable data. I propose
collecting the following timing information for every single person that walks
in the door of a DMV:

* When the customer arrives at the queue (`T_q`)
* When the customer leaves the queue to go to a worker (`T_qf`)
* When the customer is finished (`T_f`).

This data is straightforward to collect and allows us to calculate both the
system's mean slowdown (how much do fast tasks queue behind slow ones) and
mean latency (how fast do tasks complete):

<center>![dmv_metrics](/img/dmv_metrics.svg)</center>

This time series data along with what kind of task the customer sought
(license renewal, new license, etc ...) allows the DMV to measure changes to
their systems and is the first step to satisfying the well established
performance engineering paradigm of "measure first, optimize second". For
instance, if after rolling out a new system mean slowdown and mean latency
decrease we have improved the world. If mean slowdown decreases but mean
latency increases (meaning we need more workers) we have made people happier
but may need to hire more workers to get the mean latency back down.

Data isn't just vital for running experiments, it is also a pre-requisite for
many advanced task assignment algorithms we want to be able to use later. It
is also convenient for creating incentives for DMV workers to perform well,
such as issuing bonuses to effective DMV workers who complete tasks to full
satisfaction in less than expected amounts of time.

Step 2: Reduce and Balance the Load
===================================
```
The best way to make something fast is not to do it.

- Software engineering proverb
```

To reduce load on DMV offices, the very first step should be to identify high
load activities that take up a large quantity of processing time but do not
have to be done in person.

Eliminating work is typically done with education and by providing online or
over the phone services (accessible via phones, computers, or libraries) which
allow high traffic activities such as renewing drivers licenses or
registrations to be done without setting foot in a DMV office. One need only
look at the massive delays being caused in California due to REAL-ID renewals,
where people have to physically attend the DMV, to see just how many renewals
were being sped up by not having people physically attend. This may sound
obvious but figuring out how to keep people out of the DMV is one of the best
ways to improve it.

When we can't eliminate work, a wealth of literature tells us that we should
try to balance the load. We can attack load balancing to DMVs in a few ways.

Balance the Load across Time
----------------------------

The DMV struggles, like many public services (roads, etc ...), with time of day
load unbalancing, where more customers tend to show up at certain times of the
day. One of the best ways to spread out this load is using appointments, and
indeed many states such as California implement appointments to help distribute
load out over the whole day. Note that selecting how many appointments to have
is somewhat of a tricky problem, but tuning that can be done using the
throughput and slowdown statistics gathered in real time.

<center>![dmv time of day load](/img/dmv_load_over_time.svg)</center>

This graph is made up (with data from part 1 we could make a real one!), but it
demonstrates how appointments allow the DMV to more evenly spread load across
all hours of the day and give users who can incentives to go during "off-peak"
hours.

An economist would go a step further and apply demand based pricing where a
subset of reservations is held for auction every day, and we can use the money
captured from the reservation auction to hire more workers. This in turn
reduces load for everyone while allowing those with high cost per unit time to
expedite their visits.

Balance the Load across Space
-----------------------------

Once the data collection of timing data is automated, we can record the
distribution of wait times and use this to help those considering walk-ins to
select the office with the shortest queueing time for their particular task.
This helps users balance load to the least busy DMV office.

<center>![dmv time of day load](/img/dmv_time_distribution.svg)</center>

In this case a customer may choose to attend the green (long-dashed) DMV
because it will be faster for them. This is similar to the "Join Shorted Queue"
[load balancing algorithm we saw earlier]({{< relref supermarkets_and_efficient_queueing_part_1 >}}#lesson-2-balance-your-load) and while it isn't as advanced as some
alternative load balancing algorithms, it is something humans intuitively
understand: to go where the line is shortest.

Step 3: Optimize Queueing for Long Tailed Distributions
=======================================================

Balancing load evenly is generally useful, but to deal with the long tailed
nature of DMV tasks where some tasks take significantly longer then others, we
will have to unbalance the load and try to use the data we have to make good
choices and help minimize slowdown, which is probably a better proxy for
happiness than throughput. It may be useful to experiment with two
size based strategies:

* Size-Interval Task Assignment with Equal Load (SITA-E \[[1](#sita)\]): Divide
  tasks to workers based on the task size such that load on each worker is
  roughly even on average.
* Task Assignment based on Guessing Size (TAGS \[[2](#tags)\]): When you don't
  know how big a piece of work is, guess and reschedule when exceeding the
  guess deadline.

Specifically we can use the data collected to group tasks together with similar
durations, and then keep those tasks queued together. Think of this like
creating different "express lanes" based on estimated task duration. A license
renewal, which is a fast task, should be separated from a new license with
vision test, which is typically a slower task.

The cutoff points are calculated per `SITA-E` such that the percentage of load
that arrives at each pool of workers is roughly even. We can improve this even
further by allowing large task workers to take from the short task pool (this
is similar to thread
[work-stealing](https://en.wikipedia.org/wiki/Work_stealing)) when they are
idle so that we do not suffer an idle worker. Even with this modification, it
is important to note that for this to work the cutoffs and worker assignments
must be constantly adjusting to what the data is telling us, otherwise the
[system's throughput can actually suffer significantly]({{< relref supermarkets_and_efficient_queueing_part_2 >}}#lesson-4-separate-out-different-kinds-of-work) when a
worker could be busy but is instead idle.

<center>![dmv_task_queueing](/img/dmv_task_queueing.svg)</center>

TAGs comes in when a task exceeds the duration we thought it would take. When
this happens, we can turn that worker into a "slow task" worker and re-queue
all future tasks exceeding the deadline to that single slow task worker. This
is illustrated above as "Slow Task Requeue" and further corrals slow tasks
together and prevents them from slowing down fast tasks.

For example, imagine that a customer was supposed to be in the `10-30m` lane,
but it turns out they need to get their vision checked, which will put them
over the 30 minute deadline. TAGs says that instead of tying up the `10-30m`
worker with the unexpectedly long task we should instead re-queue the work to a
dedicated "slow" queue. For practical reasons we would probably let the first
such slow task consume the worker but any future slow tasks would get escalated
to the slow queue.

For either of these systems to work well, however, we _must_ have good data
on task sizing. We can compensate slightly with TAGs and by allowing idle
workers to dynamically re-assign themselves to pending customers in the faster
groups, but depending on the distribution of task durations our strategy has to
change.  Indeed it may be better to just open up all workers to all tasks if
the task duration distribution is less heavy tailed and more uniform.


Conclusion
==========

In this post we saw how the first step to fixing the DMV is to start with data
so that we can continuously experiment and measure our theories. Then we saw a
few potential strategies to improve involving both load balancing and
unbalancing to try to help reduce mean latency and mean slowdown in the face
of variable task duration.

It is important to note that most of the above strategies are operating under
the assumption of a stable system state, namely that the average number of
employed workers is greater than the average arrival rate of customers
multiplied by the average service time (aka [Little's
Law](https://en.wikipedia.org/wiki/Little%27s_law)). Many DMV offices are
simply understaffed to handle the load placed on them, and absent techniques
like auctioning off high demand appointment slots or getting fewer people to
come in by doing things over the phone, by mail, or online; no amount of
fancy load balancing can fix an overloaded system.

Citations
=========

<a name="sita"></a>
[1] Harchol-Balter, M., Crovella, M. E., & Murta, C. D. (1999). On choosing a
task assignment policy for a distributed server system. ([paper](https://www.cs.cmu.edu/~harchol/Papers/tools.pdf))

<a name="tags"></a>
[2] Harchol-Balter, M. (2000, April). Task assignment with unknown duration.
([paper](https://www.cs.cmu.edu/~harchol/Papers/tags.pdf))
