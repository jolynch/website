---
title: "Distributed Systems Shibboleths"
date: 2022-04-24T11:28:49-05:00
---

[Shibboleths](https://en.wikipedia.org/wiki/Shibboleth) are historically a
word or phrasing that indicate membership in a particular group or culture. I
was introduced to the term in the [West Wing](https://youtu.be/fqkaBEWPH18?t=24)
where the President needed to verify the veracity of a person's claims of
religious persecution.

I am still a relatively new engineer in the field of distributed systems,
having only studied and worked in the field for around a decade, but in that
time I believe I have learned to recognize some key "distsys shibboleths" that
help me recognize when I can trust what a vendor or other engineer is telling
me.

# Positive Shibboleths
When discussing distributed systems with vendors or other engineers they can
build trust with me that they know what they are talking about when I hear one
of these positive Shibboleths:

> We made the operation **idempotent**

Most useful distributed systems involve mutation of state communicated through
messages. The *only* safe way to mutate state in the presence of unreliable
networks is to do so in a way that you can apply the same operation multiple
times until it explicitly succeeds or fails. Idempotent operations are a
cornerstone of distributed computing powering rather important things like:

* [TCP segment retransmission](https://datatracker.ietf.org/doc/html/rfc793#section-3.3)
  relies on idempotent receivers to ensure an ordered stream of bytes. The
  internet as we know it fundamentally depends on idempotency.
* Stripe and other payment processors ensure they only bill your credit card
  once using [idempotency keys](https://stripe.com/docs/api/idempotent_requests)
  so even when you are paying for boba via your `2g` network connection you
  can be sure you will only pay once.
* [CRDTs](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
  fundamentally rely on idempotence to allow reliably applying mutation
  operations. These power all kinds of distributed systems and I highly
  recommend Martin Kleppmann's
  [series](https://martin.kleppmann.com/2020/07/06/crdt-hard-parts-hydra.html)
  on them if you want to learn more.

I should also note that while [Distributed Transactions](https://en.wikipedia.org/wiki/Distributed_transaction)
might be a useful tool in building idempotency, simply wrapping a non idempotent
operation (e.g. "add 1 to X") in a transaction does not make it idempotent. If
your design relies on never having to deal with a timeout (not knowing if the
transaction applied or not), your design is probably not robust.

> The system makes **incremental progress**

A robust distributed system makes constant incremental progress and does not
have "big bang" operations. For example:

* An incremental backup or data replication system breaks the snapshot down
  into small, easy-to-recover pieces of work and checkpoints progress so the
  system can recover from failure.
* When a distributed database accepts
  [DDL](https://en.wikipedia.org/wiki/Data_definition_language) it accepts the
  request, writes it down in a ledger and returns an async job id the user can
  poll for completion (since DDL may take time to occur). As leader nodes
  that accept mutations incrementally complete the schema change they surface
  that progress.
* An incremental full-scan API is paginated and resumable with a previously
  received page token. This allows readers to resume after an error or
  network failure.
* Rather than only communicating when there is something to do, sending
  a periodic heartbeat allows systems to turn silence into incremental
  progress.

For me, this is a positive indication because it means the person designing the
system has a true understanding that partitions happen for all kinds of
reasons: network delay/failure, lock contention, garbage collection, or your
CPU might just stop running code for a bit while it does a [microcode
update](https://aws.amazon.com/security/security-bulletins/AWS-2018-013/v11/).
The only defense is breaking down your larger problem into smaller incremental
problems that you don't mind having to re-solve in the error case.

> Every component is **crash-only**

I like to think of this one as the programming paradigm which collectively
encourages you to "make operations idempotent *and* make incremental progress"
because handling errors by crashing forces you to decompose your programs into
small idempotent processors that make incremental progress. In my experience,
[crash-only](https://www.usenix.org/legacy/events/hotos03/tech/full_papers/candea/candea_html/index.html)
software is by far the most reliable way to build distributed systems because
it gives you no choice but to design for failure.

> We **shard it** on \<some reasonably high cardinality value\>

Distributed systems typically handle large scale datasets (otherwise you would be
running a single instance of PostgreSQL right?). A fundamental aspect of
building a distributed system is figuring out how you are going to distribute
the data and processing. This technique of limiting responsibility for subsets
of data to different sets of computers is the well-known process of
[sharding](https://en.wikipedia.org/wiki/Shard_(database_architecture)). A
carefully-thought-out shard key can easily be the difference between a reliable
system and a constantly overloaded one.

# Negative Shibboleths

On the opposing side to positive Shibboleths, negative ones are phrases or
statements that immediately signal to me that the person I'm talking to is
either misinformed or worse intentionally trying to deceive me. I personally
experience more ignorance than deception, except perhaps for when vendors are
involved (in my experience database vendors will say all kinds of nonsensical
things to get people to buy their database).

> Our system is **Consistent and Available**.

If any vendor ever claims they have a `CA` anything, I immediately distrust
everything they are about to tell me since this is like claiming they have
found Unicorns and Rainbows and along the way found a polynomial-time
algorithm for factoring large prime numbers using a classical computer and a
way to decrease the entropy of the universe.

Coda Hale presented a compelling argument for this back in
[2010](https://codahale.com/you-cant-sacrifice-partition-tolerance/) and yet I
still hear this somewhat routinely in vendor pitches. What *does exist* are
datastores that take advantage of
[`PACELC`](https://en.wikipedia.org/wiki/PACELC_theorem) tradeoffs to either
provide higher availability to `CP` systems such as building fast failover into
a leader-follower system (attempting to cap the latency of the failure), or
provide stronger consistency guarantees to `AP` systems such as paying latency
in the local datacenter operations to operate with
[linearizability](https://youtu.be/noUNH3jDLC0?list=PLeKd45zvjcDFUEv_ohr_HdUFe97RItdiB&t=723)
while remote datacenters permit stale or
[phantom](https://en.wikipedia.org/wiki/Isolation_(database_systems)#Phantom_reads)
reads.

> at-least-once and at-most-once are nice, but **our system implements
> exactly-once**

No it does not. Your system might implement at-least-once delivery with
idempotent processing, but it does not implement exactly-once which
is demonstrated to be impossible in the
[Two Generals](https://en.wikipedia.org/wiki/Two_Generals%27_Problem) problem.
These words matter because building idempotency has to be something you thread
through your whole distributed system, all the way down to the system that is
mutating the source of truth state and all the way up to your clients. It takes
effort to build in idempotency, and can be difficult to add as an afterthought.

I've heard this a lot from Kafka fans recently where they implemented at-least-once
delivery with idempotent processing and have been claiming various places "we
implemented exactly-once". If you actually [read what they
built](https://www.confluent.io/blog/exactly-once-semantics-are-possible-heres-how-apache-kafka-does-it/)
it is *just idempotent processing of at-least-once delivery*. This is not new
or innovative, it is how every robust system has worked since the dawn of
computer networks. Indeed as I pointed out earlier, the TCP protocol the
internet is built on works this way.

> **I just need Transactions** to solve my distributed systems problems

This statement _can_ be true but it is true far less often than I hear
engineers saying it. Transactions can still timeout and fail in a distributed
system, in which case you must read from the distributed system to figure out
what happened. The main advantage of distributed transactions is that they make
distributed systems look less distributed by choosing `CP`, but that inherently
trades off availability! Distributed transactions do not instantly solve your
distributed systems problems, they just make a `PACELC` choice that sacrifices
availability under partitions but tries to make the window of unavailability as
small as possible.

An example of how transactions do not help, even with a `CP` system, is if you
implement a distributed counter by transactionally adding one to a register
(e.g. `x = x + 1`), you have _not solved your distributed systems problem_. You
just implemented an at-least-once counter that overcounts (a.k.a. corrupts your
counters) during partitions. To actually solve the problem you have to model
your counting events in a way that makes them idempotent. For example, you
could place a unique identifier on every count event and then roll up those
deltas in the background and transactionally advance a summary, either
preventing ingestion after some time delay or handling recounting.

> I will take a **distributed lock**

There is no such thing as a distributed lock because a true distributed lock
would require a `CA` system and we should remember those are not possible. This
impossibility is because a partitioned node that held a lock, by its nature of
being partitioned, *cannot know* it has lost the lock.  There are absolutely
[`distributed leases`](https://en.wikipedia.org/wiki/Lease_(computer_science))
as most well known "distributed locks" are actually just leases, and indeed
leader election is just taking a lease on a binary piece of state. The popular
Zookeeper `lock` recipe is actually just a ~30 second (session timeout) lease
with heartbeats built in.

*Distributed leases are possible* because the participating nodes agree ahead
of time how much time they are allowed to assume they hold a lease without
coordinating. This introduces unavailability under partitions (preserving `CP`
by choosing to fail under a partition).

Even better than *just* using a lease
would be to attach idempotency/fencing tokens and use them as a [`fencing
token`](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
in your system's mutation path so you can reject tokens that are too old since
they may convey conflicting writes.

# Conclusions

Of course these are not an exhaustive list of positive and negative Shibboleths,
but I hope they might be helpful. Perhaps new engineers just getting
started in the field can skip making some of the mistakes I have. If I'm lucky,
database vendors might try just a little harder to tell the truth in their
sales-pitch meetings knowing their audiences are informed.
