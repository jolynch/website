---
title: "Publications"
menu: "main"
weight: 5
meta: false
---

I've mostly written blog posts and whitepapers, mostly for employers. I've
included links here in case they might be interesting.

* (2024) [Data Gateway - A Platform For Growing and Protecting the Data Tier](https://netflixtechblog.medium.com/data-gateway-a-platform-for-growing-and-protecting-the-data-tier-f1ed8db8f5c6):
  A post I co-authored with Shahar Zimmerman, Vidhya Arvind, and Vinay Chella
  for Netflix that shared the architecture of our Data Gateway Platform.
  The Data Gateway Platform at Netflix hosts Data Abstraction Layers (DALs)
  that shield Developers from complex and backwards-incompatible database API
  changes.
* (2020) [Towards Practical Self-Healing Distributed Databases](/pdf/practical-self-healing-databases.pdf):
  A paper published in proceedings of the [2020 IEEE Infrastructure Conference](https://ieeexplore.ieee.org/document/9377621/references#references) about how one can build self-healing
  databases out of existing software and hardware without replacing the entire
  database engine.
* (2019) [Garbage Collecting Unhealthy JVMs, a proactive approach](https://medium.com/@NetflixTechBlog/introducing-jvmquake-ec944c60ba70):
  A post I authored with Josh Snyder for Netflix that introduced and explained
  how we use the [`jvmquake`](https://github.com/jolynch/jvmquake) agent to
  rescue our distributed databases written in Java from JVM death spirals.
* (2018) [Cassandra Availability with Virtual Nodes](/pdf/cassandra-availability-virtual.pdf):
  A whitepaper I authored with Josh Snyder that attempted to formally
  model Cassandra's availability under different numbers of tokens per node.
  TLDR: use no more than 4 tokens if you want high availability in a Dynamo
  style database. The paper is based on [this
  notebook](https://github.com/jolynch/python_performance_toolkit/blob/master/notebooks/cassandra_availability/cassandra_availability.ipynb)
* (2017) [Taking Zero Downtime Load Balancing even Further](https://engineeringblog.yelp.com/2017/05/taking-zero-downtime-load-balancing-even-further.html):
  In this post I showed how Yelp had evolved their highly available and scalable
  service mesh based on SmartStack to use NGINX and HAProxy and get the best of
  all worlds.
* (2016) [Monitoring Cassandra at Scale](https://engineeringblog.yelp.com/2016/06/monitoring-cassandra-at-scale.html):
  A post I wrote for Yelp about how they monitored their distributed
  Cassandra deployments taking into account full ring health. Also includes
  some helpful examples for how to interact with Cassandra's JMX interface from
  Python.
* (2015) [True Zero Downtime HAProxy
  Reloads](https://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html):
  A post I wrote for Yelp about how they reloaded HAProxy without any
  downtime to requests using Linux queueing disciplines. A super hacky way to
  achieve the end that has since been superseded by better techniques. It was
  pretty novel at the time though.
* (2014) [Scaling Elasticsearch to Hundreds of Developers](https://engineeringblog.yelp.com/2014/11/scaling-elasticsearch-to-hundreds-of-developers.html):
  A blog post I wrote for Yelp about the Apollo data gateway which
  acted as a proxy tier to NoSQL databases such as Elasticsearch (And later
  Cassandra). Basically this was an API-gateway for datastores, which was
  ridiculously useful and helped Yelp's distsys-data team scale datastores and
  upgrade them all the time.
