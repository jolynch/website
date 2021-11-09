---
title: "Distribute Systems Shibboleths"
date: 2021-11-07T11:28:49-05:00
draft: true
---

[Shibboleths](https://en.wikipedia.org/wiki/Shibboleth) are historically a
word or phrasing that indicate membership in a particular group or culture. I
was introduced to the term in the [West Wing](https://youtu.be/fqkaBEWPH18?t=24)
where the President needed to verify the veracity of a person claiming religious persecution.

I'm still a reasonably new engineer in distributed systems, having only studied
and worked in the field for around ten years, but in that time I believe I have
learned to recognize some key "distsys shibboleths" that help me recognize when
I can trust what database vendor is telling me. They may also help in


# Positive Shibboleths
When discussing distributed systems with vendors or other engineers I
immediately have a good feeling inside that they know what they are talking
about when I hear one of these phrases.

> Operations are **idempotent**

Any useful distributed system involves mutation of state communicated through
messages. The *only safe way to mutate state* in the presence of unreliable
networks is to do so in a way that you can apply the same operation multiple
times until it succeeds. Idempotent operations are a cornerstone of distributed
computing powering rather important things like:

* [TCP segment retransmission](https://datatracker.ietf.org/doc/html/rfc793#section-3.3)
  relies on idempotent receivers to ensure an ordered stream of bytes. The
  internet as we know it fundamentally depends on idempotency.
* Stripe and other payment processors ensure they only bill your credit card
  once using [idempotency keys](https://stripe.com/docs/api/idempotent_requests)
  so even when you are paying for boba via your `2g` network connection you
  can be sure you will only pay once
* [CRDTs](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
  fundamentally rely on idempotence to allow reliably applying mutation
  operations. These power all kinds of distributed systems and I highly
  recommend Martin Kleppmann's
  [series](https://martin.kleppmann.com/2020/07/06/crdt-hard-parts-hydra.html)
  on them if you want to learn more.

I should also note that while [Distributed Transactions](https://en.wikipedia.org/wiki/Distributed_transaction)
might be a useful tool in building idempotency, simply wrapping a non idempotent
operation in a transaction does not make it idempotent. If your design relies
on never having to deal with a timeout, your design is wrong.

> The system makes **incremental progress**

A robust distributed system makes constant incremental progress and does not
have "big bang" operations. For example:

* An incremental backup system (which is creating a replica of the dataset)
  breaks the snapshot down into smaller completable pieces and checkpoints
  progress as data is uploaded.
* When a distributed database is accepting distributed
  [DDL](https://en.wikipedia.org/wiki/Data_definition_language) it accepts
  the request, writes it down in a ledger and returns an async job id the user
  can poll for completion (since DDL may take time to occur). As leader nodes
  that accept mutations incrementally complete the schema change that progress
  can be surfaced.
* An incremental full scan API is paginated and resumable with a previously
  received page token. This allows readers to resume after a network failure.

For me this is such a positive indication because it means the person
designing the system has a true understanding that partitions happen for all
kinds of reasons (network failure, lock contention, garbage collection —
your CPU might just stop running code for a bit while it does a microcode update)
and the only defense is breaking down your hard problem into smaller easier
ones.

> Every component is **crash-only**

I like to think of this one as the programming paradigm which encourages you to
"make operations idempotent and make incremental progress" because handling
errors by crashing forces you to decompose your programs into small idempotent
processors that make incremental progress. In my experience
[crash-only](https://www.usenix.org/legacy/events/hotos03/tech/full_papers/candea/candea_html/index.html)
software is by far the most reliable way to build distributed systems because
it forces you to actually build robust crash-recovery.

> We **shard it** on <user|country|...>

Distributed systems typically handle large scale datasets (otherwise you would be
running a single instance of PostgreSQL right?). A fundamental aspect of
making a system distributed is figuring out how you are going to distribute
the work. This process of limiting responsibility to different sets of nodes
is just the process of [Sharding](https://en.wikipedia.org/wiki/Shard_(database_architecture))

# Negative Shibboleths
On the other hand to positive Shibboleths, negative ones are phrases or
statements that immediately signal to me that the person I'm talking to is
either misinformed or worse intentionally trying to deceive me. I personally
experience more ignorance than deception, except for when vendors are involved
(at least in my case database vendors will say all kinds of nonsensical things
to get people to buy their database).

> **Our system is Consistent and Available**.

If any vendor ever claims they have a `CA` anything, I immediately distrust
everything they are about to tell me since this is like claiming they have
found Unicorns and Rainbows and along the way found a polynomial-time
algorithm for factoring large prime numbers using a classical computer and a
way to decrease the entropy of the universe.
Coda Hale presented a wonderful argument for this back in
[2010](https://codahale.com/you-cant-sacrifice-partition-tolerance/) and yet I
still hear this somewhat routinely in vendor pitches.

What does exist are datastores that take advantage of
[`PACELC`](https://en.wikipedia.org/wiki/PACELC_theorem) tradeoffs to either
provide higher availability to `CP` systems such as building fast failover
into a leader-follower system (attempting to cap the latency of the failure),
or provide stronger consistency guarantees to `AP` systems such as paying
latency in the local datacenter operations to operate with
[linearizability](https://youtu.be/noUNH3jDLC0?list=PLeKd45zvjcDFUEv_ohr_HdUFe97RItdiB&t=723)
while remote datacenters permit stale or
[phantom](https://en.wikipedia.org/wiki/Isolation_(database_systems)#Phantom_reads)
reads.

> at-least-once and at-most-once are nice, but **our system implements
> exactly-once**

No it does not. Your system might implement at-least-once delivery with
idempotent processing, but it does not implement exactly-once (which
is impossible per the
[Two Generals](https://en.wikipedia.org/wiki/Two_Generals%27_Problem) problem).
These words matter because building idempotency has to be something you thread
through your whole distributed system, all the way down to the system that is
mutating the source of truth state and all the way up to your clients.

I've heard this a lot from Kafka fans recently where they implemented at-least-once
delivery with idempotent processing and have been claiming literally
everywhere "we implemented exactly-once". If you actually [read what they
built](https://www.confluent.io/blog/exactly-once-semantics-are-possible-heres-how-apache-kafka-does-it/)
it is *just idempotent processing of at-least-once delivery*. This is not new
or innovative, it is how every robust system works (as I pointed out the TCP
protocol the internet is built on literally works this way).

> **Transactions solve my distributed systems problems**

This statement _can_ be true but it is true far less often then I hear
engineers saying it. Transactions can still timeout in a distributed system, in
which case you must read from the distributed system to figure out what
happened. The main advantage of distributed transactions is that they make
distributed systems look less distributed by typically choosing `CP`, but that
inherently trades off availability! Distributed transactions do not solve your
distributed systems problems, they just make a `CAP` choice that sacrifices
`A`.

For example, even with a `CP` system, if you implement a distributed counter by
transactionally adding one to a register (e.g. `x = x + 1`), you have _not
solved your distributed systems problem_. You just implemented an at-least-once
counter that overcounts. To actually solve the problem you have to model your
counting events in a way that makes them idempotent.

> I will take a **distributed lock**

There is no such thing as a distributed lock because a true distributed lock
would require a `CA` system. This is because a partitioned node that held
a lock, by its nature of being partitioned, *cannot know* it has lost the lock.
There are absolutely [`distributed
leases`](https://en.wikipedia.org/wiki/Lease_(computer_science))
as most well known "distributed locks" are actually just leases, and indeed
leader election is just taking a lease on a binary piece of state. Indeed
the Zookeeper `lock` recipe is actually just a 30 second (session timeout)
lease tat

Distributed leases are possible because the participating nodes agree ahead of
time how much time they are allowed to assume they hold a lease without
coordinating which introduces unavailability under partitions (preserving `CP`
by choosing to fail under a partition). Even better than just using a lease
would be to run a [`fencing
token`](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
through your system similar to how `idempotency tokens` need to be threaded
through for idempotency.


