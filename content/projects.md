---
title: "Projects"
menu: "main"
weight: 3
meta: false
---

Below are some of my projects roughly categorized by area.

Distributed Systems
-------------------

* [`synapse`](https://github.com/airbnb/synapse) and
  [`nerve`](https://github.com/airbnb/nerve) service mesh aka SmartStack. I help
  maintain and have contributed significant features to Airbnb's service mesh,
  including improving the scalability of the system by multiple orders of
  magnitude (Yelp ran tens of thousands of containers across a global network
  with full global service discovery), and extending Synapse to be fully
  pluggable and support any proxy.
* [`Paasta`](https://github.com/Yelp/paasta) distributed platform as a service. I
  was a somewhat minor contributor to Paasta, mostly working on SmartStack
  integrations, but I did help port the whole codebase to Python 3 so that was
  interesting...
* [`jvmquake`](https://github.com/jolynch/jvmquake) agent for rescuing
  distributed databases written in Java from themselves by killing them (while
  grabbing a core dump) when they enter JVM death spirals. This is basically an
  extension of [`jvmkill`](https://github.com/airlift/jvmkill) that also
  detects GC spirals of death.
* [`Priam`](https://github.com/Netflix/Priam) distributed sidecar for Apache
  Cassandra. I work on this at Netflix, improving operability of Cassandra.
* [`pinch`](https://github.com/jolynch/pinch) toolkit for compressing, hashing
  and moving data around as fast as you can around a network. This is just
  a docker container with all of my favorite data compression and validation
  tools built in (e.g. `zstd`, `lz4`, `xxhash` etc ...) and a local `go` server
  that can do it all via HTTP for you (assuming the commands are installed)
* [`service-capacity-modeling`](https://github.com/Netflix-Skunkworks/service-capacity-modeling)
  library for capacity planning (determining which kind and how much of a
  computer to buy) for a particular workload such as Apache Cassandra or
  Elasticsearch. Essentially a multi-variate monte carlo simulation with a
  least regret optimizer over per workload models.


Debugging / Performance Analysis
--------------------------------

* [`performance-analysis`](https://github.com/jolynch/performance-analysis)
  collection of [`jupyter`](https://github.com/jupyter) notebooks and various
  python scripts I've used to analyze the performance of various service or
  database setups. Perhaps one of the more interesting ones is my notebook for
  modeling Cassandra availability with different numbers of
  [vnodes](https://github.com/jolynch/performance-analysis/tree/master/notebooks/cassandra_availability)
* [`cqltrace`](https://github.com/jolynch/cqltrace) dynamic tracer for observing
  live CQL traffic in real time. I mostly use this for debugging Cassandra
  clients and their performance.

Educational
-----------

* [`python_service_performance`](https://github.com/jolynch/python_service_performance)
  A step by step guide on how to make a `python3` web service based on
  [`uwsgi`](https://github.com/unbit/uwsgi),
  [`pyramid`](https://github.com/Pylons/pyramid),
  [`gevent`](https://github.com/gevent/gevent) and
  [`nginx`](https://github.com/nginx/nginx) production ready. This means high
  scalability and low latency with a typical microservice setup.

Economics
---------

* [`splitit`](https://github.com/jolynch/splitit) algorithm and Python web
  service for fairly dividing items that are hard to value (e.g. rents in a 5
  bedroom apartment). I used this with my roommates to divide rent fairly in
  San Francisco.

Debate
------

* [`MIT-TAB`](https://github.com/MIT-Tab/mit-tab) APDA parliamentary debate
  tabulation software. Basically this is a very complicated constraint
  optimization problem that debaters used to do by hand, and now a good
  fraction of the American Parliamentary Debate Association's tournaments run
  with this software. I was the original author but have since handed
  development off to [Ben Muschol](https://github.com/BenMusch) who has really
  improved the project!

Machine Learning / AI
---------------------

* [`python_hqsom`](https://github.com/jolynch/python-hqsom) implementation of
  the HQSOM deep learning algorithm. This was a project I worked on for a few
  graduate classes at MIT (6.867 and 6.868) that used genetic algorithms and
  deep learning and other such buzzwords. Surprisingly it actually worked
  pretty well.
* [`food.op`](https://github.com/jolynch/food.op) recipe recommender based on
  gradient boosting classifiers. It was a hackathon project but sorta neat to
  have recipes recommended based on previous cooking experiences.
* [`organon`](https://github.com/jolynch/organon) symbolic constraint framework
  and solver for modeling complex constrained systems that may not have
  solutions. The
  [paper](https://github.com/jolynch/organon/blob/master/papers/final.pdf) is a
  decent read if you're interested in what this project can do.
* [`service-capacity-modeling`](https://github.com/Netflix-Skunkworks/service-capacity-modeling)
  library for capacity planning (determining which kind and how much of a
  computer to buy) for a particular workload such as Apache Cassandra or
  Elasticsearch. Essentially a multi-variate monte carlo simulation with a
  least regret optimizer over per workload models.
