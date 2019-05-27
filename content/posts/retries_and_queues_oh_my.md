---
title: "Retries And Deep Queues Oh My"
date: 2019-05-26T22:24:56-07:00
draft: true
---

Working on service meshes and distributed databases has taught me repeatedly
that there are two commonly used "resilience" techniques that can bring a
distributed system to its knees: **retries** and **deep queues**.

In the world of millions of queries per second with latency budgets under ten
milliseconds, I can see the allure of retries and deep queues.

Let's consider for a moment that some developer named Bob is unhappy that their
service saw an error from another service or a database after waiting some
effective eternity like 3 seconds and so they have a reasonable idea "hey what
if I retried against a different server after 200ms instead". The developer
rolls out their change and their service's `P99` latency drops to `201 ms`!
They celebrate the easy win and move on to making the next widget.

Now another developer, Alice, administers a large user messaging service which
takes pending messages from a queue and calls another team's service after
transforming the data. She get's a call from her boss saying "alright we have a
mission critical message to send to our users, please scale up the consumers to
make sure we can process the backlog". She hits the scale up button and replies
"ready".

Unfortunately, both of these developers has set distributed systems traps.

<center>![its_a_trap](/img/its_a_trap.jpg)</center>
<center>Retries and Deep Queues in Distributed Systems</center>

Bob has set a trap by adding a retry after a short timeout. Under normal
operation everything is fine, but it is only a matter of time until this system
succumbs to the **dreaded retry storm** where an upstream service starts
sending many times the normal load to downstream systems and overwhelms them.
Retry storms can and do cascade down the entire call graph and potentially
cause total outage.

Alice has set a trap by allowing higher concurrency during peak traffic on her
downstream without ensuring that they can handle the load, which means that
when those millions of critical messages come in, their service will process
the queue but the downstream may explode.

These kinds of operator error where a small fix to a small problem can
quickly turn into a big problem via a latent failure mode is one of my favorite
examples of rule 14 of Richard Cook's `How Complex Systems Fail` paper: "Change
introduces new forms of failure" \[[1](#how_complex_systems_fail)\].


Why are Retries and Deep Queues Bad?
====================================

First, retries are bad because they allow load to double or triple or worse
(e.g. retrying against every host in the cluster) when a downstream performance
profile shifts very slightly. System load discontinuities like those caused by
retry storms (where a service performance characteristic suddenly shifts) are
extremely hard to plan or recover from, and are one of the number one causes
of massive outages in my experience.

Second, queueing work deeply is bad because it can cause large backlogs to
build up which cannot flush into your downstream services faster than work
comes in.  When your "work grows without bound" you have turned a stable system
into an *unstable* system, and you probably can't recover without turning it
off and on again.

If I had to count the most frequent 90% of total outages in the distributed
systems I work on, they most certainly involve some form of retries or some
deep queues.


What is better than Retrying?
=============================

In latency sensitive services there is a strictly superior option to retrying
against a slow upstream: *concurrency limited request speculation*. This
technique is more complex than "just retry" but if you replace every retry you
have with concurrency limited speculations, it will allow your oncall engineers
to sleep more soundly at night.

Concurrency limited request speculation is the combination of two ideas:

1. Request speculation (aka hedging). A technique where you send an additional
   request after some period of time has passed in an attempt to get a faster
   response. This technique was popularized by Google's Jeff Dean in the Tail
   at Scale paper \[[2](#tail_at_scale)\].
2. Concurrency limiting. Downstream services are often concurrency limited, so
   it is common to restrict how many outstanding requests one can make against
   the downstream service via a concurrency limit. Concurrency limiters can
   be as simple as a counter or a fixed size threadpool, or can be complex
   like a [leaky bucket](https://en.wikipedia.org/wiki/Leaky_bucket) or even
   [adaptive concurrency limiter](https://github.com/Netflix/concurrency-limits).

Speculations are strictly better than retries because if the original request
succeeds, we can still use that result without waiting on the second request.
They also solve the "what should my timeout be" problem because you often
speculate on an adaptive latency percentile that is observed from the
downstream calls, such as the `95th` percentile latency. Speculating on the
`95th` would naturally put an average of `5%` load on the service. The
concurrency limiter steps in when this measurement is inaccurate (e.g. because
the downstream server is pausing for garbage collection) and ensures that your
service does not overload the downstream.

{{< highlight python >}}
class SimpleConcurrencyLimiter(object):
    def __init__(slots: int, period_s: int)
    def wait_for_slot(timeout_ms: int) -> Future

class LatencyMonitor():
    def record(latency_ms: int)
    def percentile(pct: float) -> int

latency = LatencyMonitor()
limiter = SimpleConcurrencyLimiter(slots: 4, period_s: 60)

def send_concurrency_limited_request(req: Request) -> Response:
    current_p95 = LatencyMonitor.percentile(0.95)
    response = grequests.get(req.url, timeout=current_p95)
    second_response = response
    if response.timeout():
        # If we still have a chance to achieve the request budget and
        # can acquire the concurrency limiter we can speculate
        with limiter.wait_for_slot((req.budget - current_p95) / 2.0):
            second_response = grequests.get(req.url, timeout=current_p95)

    result = any(response, second_response)
    # Record the latency that the request took
    latency.record(result.elapsed)


{{< /highlight >}}


In throughput sensitive services, just say no to retries because throughput
is maximized when you optimally tune the concurrency you are placing on the
downstream. You can aggregate all failures and retry the whole batch once you
are done working through the initial queue. This way you always put constant
load on the downstream. If you absolutely must retry, please use bounded,
concurrency limited, exponential backoff retry *with jitter* to try to limit
the amount of retries.

What is better than Queueing?
=============================

For latency sensitive services it is generally better to shed load by
responding quickly with an overloaded exception than to queue, especially if
your service on average responds in just a few milliseconds. By *failing fast*
and throwing an error (shedding load) the service can protect itself and its
downstreams from overload which may otherwise cause serious service
degradation.

In throughput sensitive services, backpressure is often preferable to building
up a large queue in your service. You can do this by intentionally pacing
(aka slowing down) responses to incoming requests. One way to do this for a
network service is to simply stop accepting packets off the userspace socket,
which will eventually cause the Linux TCP stack to stop acking packets and
naturally slow down your callers (as they will start observing "latency" which
will slow them down. This makes the production levels go down which in turn can
allow your service to recover.

When is it OK to retry or Queue?
================================

It is **never ok to retry**. Using retries when you could be using concurrency
limited speculations is like using bubble sort when you have quicksort
available.

Queues are ok only when you know that you are throughput sensitive.

Citations
=========

<a name="how_complex_systems_fail"></a>
[1] Richard I Cook, How Complex Systems Fail ([paper](https://web.mit.edu/2.75/resources/random/How%20Complex%20Systems%20Fail.pdf)

<a name="tail_at_scale"></a>
[2] Jeffrey Dean and Luiz Andre Barroso, The Tail at Scale ([paper](https://ai.google/research/pubs/pub40801]))
