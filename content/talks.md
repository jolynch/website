---
title: "Talks"
menu: "main"
weight: 4
meta: false
---

Below are a collection of conference talks or other presentations that I've
given, typically related to distributed systems or other software engineering
topics:

* (2025) [Techniques Netflix Uses to Weather Significant Demand Shifts](https://www.usenix.org/conference/srecon25americas/presentation/lynch)
  ([slides](/pdf/srecon2025-techniques-to-weather-demand-shifts.pdf), [video](https://www.youtube.com/watch?v=RivD2EK5QFk&t=1s))
  A talk I gave at SRECon 2025 about how Netflix ensures reliability of our complex architecture under order of
  magnitude load-spikes by carefully balancing Traffic demand with Compute supply. Similar to the previous re:Invent
  talk but covers more breadth with less depth. Spans techniques to manage traffic at the edge, through how to make
  services resilient, and all the way to making databases resilient.
* (2024) [How Netflix handles sudden load spikes in the cloud](https://www.youtube.com/watch?v=TkFyZyxFRBM)
  ([slides](https://reinvent.awsevents.com/content/dam/reinvent/2024/slides/nfx/NFX301_How-Netflix-handles-sudden-load-spikes-in-the-cloud.pdf))
  A talk Rob Gulewich, Ryan Schroeder and I gave at AWS re:Invent 2024 about
  how we combine advanced traffic management, capacity management, workload
  prioritization, intelligent load shedding, fast autoscaling, and more to
  survive order of magnitude traffic spikes.
* (2023) [**How Netflix Ensures Highly-Reliable Online Stateful Systems**](https://www.infoq.com/presentations/netflix-stateful-cache/):
  A talk I gave at QConSF 2023 on how to structure stateful systems to be
  designed for reliability, handle load spikes, and gracefully handle failure.
  Recording, slides and summary should be available via the link.
* (2023) [Safely migrate databases that serve millions of requests per second](https://www.youtube.com/watch?v=3bjnm1SXLlo):
  A talk Ayushi Singh and I gave at AWS re:Invent 2023 about how to manage
  database migrations in a safe way using cloud capabilities to ensure
  performance and correctness.
* (2023) [How Netflix Delivers Key-Value and Time-Series Storage at Any Scale](https://www.youtube.com/watch?v=sQ-_jFgOBng):
  The first in-depth talk Netflix has given on our Data Abstraction Layers - Vidhya
  Arvind and I present how to build KeyValue and TimeSeries solutions atop
  Cassandra to scale up as far as you need.
* (2022) [**Capacity Plan Optimally in the Cloud**](https://www.youtube.com/watch?v=Lf6B1PxIvAs):
  A talk at AWS re:Invent 2022 about how Netflix uses
  [`service-capacity-modeling`](https://github.com/Netflix-Skunkworks/service-capacity-modeling)
  to optimally buy EC2 instances for a multitude of different workloads.
  The system as presented can capacity plan computers for any cloud or
  on premise setup as well.
* (2022) Improving Cassandra Client Load Balancing ([slides](/pdf/wlllb-apachecon-2022.pdf)):
  A talk Ammar Khaku and I from Netflix gave at ApacheCon 2022 on how we
  cut database latency by 30% or more using a novel weighting technique
  in coordinator selection. The talk is about Cassandra but the algorithm
  is generically useful for clients of stateful systems.
* (2021) [How Netflix Provisions Optimal Cloud Deployments of Cassandra](https://www.youtube.com/watch?v=2aBVKXi8LKk)
  ([slides](/pdf/netflix-provisions-optimal-cassandra.pdf)):
  A talk at ApacheCon 2021 I gave on how Netflix uses our [service-capacity-modeling](https://github.com/Netflix-Skunkworks/service-capacity-modeling)
  system to mathematically model and plan for capacity for petabyte scale
  database systems. The talk is about Cassandra but the approach (and library)
  supports any stateful system.
* (2020) [**Towards Practical Self-Healing Distributed Databases**](https://www.youtube.com/watch?v=9wAM7L49agM):
  A talk at ApacheCon 2020 I gave on the self-healing database architecture and
  how to apply that to Cassandra. If you are trying to maintain a large scale
  database infrastructure this talk might have some useful tips.
* (2019) [How Netflix Debugs and Fixes Apache Cassandra When it Breaks](https://www.youtube.com/watch?v=Zf4ge12aOMg&)
  ([slides](https://github.com/ngcc/ngcc2019/blob/master/HowNetflixDebugsAndFixesApacheCassandraWhenItBreaks.pdf)):
  A talk at ApacheCon 2019 I gave about how to debug and scientifically analyze
  performance bottlenecks in Apache Cassandra. This is a very good "help I'm
  going oncall for Cassandra" introduction to basic tools and techniques.
* (2019) [How Netflix manages petabyte scale Apache Cassandra](https://github.com/ngcc/ngcc2019/blob/master/HowNetflixManagesPetabyteScaleApacheCassandraInTheCloud.pdf):
  A talk at ApacheCon 2019 I gave with Vinay Chella about how we design
  declarative control planes to orchestrate thousands of independently scaling
  Cassandra Clusters. Essentially this talk is "how to make your own
  self-driving database".
* (2018) [Iterating on Stateful Services in the Cloud](https://www.youtube.com/watch?v=valsEK5mIQI):
  A talk at re:Invent 2018 about how Netflix manages stateful services (such
  as datastores or databases) in the AWS cloud. Contains a lot of concrete
  advice for managing state in AWS.
* (2018) [Repair Service and Cassandra](https://youtu.be/KSmAdtMJYEo?list=PLBEdfxkxBbYHjAKk4N05vW1UerK-_WDeN&t=1526):
  Part of Netflix's OSS Meetup about Polyglot Persistence. Vinay Chella
  and I talk about how we built a repair scheduler for OSS Cassandra.
* (2016) [**Building a Powerful Data Tier from Open Source Databases**](https://www.youtube.com/watch?v=wOqxgC8cUWs):
  A talk I gave at OSCON London 2016 about how to build a polyglot
  datastore data tier using open source datastores.
* (2016) [The Human Side of Service-Oriented Architectures](https://www.youtube.com/watch?v=je6VB4RXzzY): A talk
  that an old mentor, John Billings, and I gave at the first Microservice
  summit about how you have to scale the human side of microservices (as
  opposed to the technical sides).
* (2016) [Automating Datastore Fleets with Puppet](https://www.youtube.com/watch?v=g8qDoU2WlVs):
  A more detailed talk on how we automated datastores at Yelp specifically with
  Puppet and other common industry tools. Given at Puppetconf 2016.
* (2015) [Writing a Polyglot Datastore Story](https://www.youtube.com/watch?v=Wb046sEnidQ):
  A talk I did with Josh Snyder at Velocity 2015 about how Yelp allowed
  developers to use polyglot datastores. Has architectural advice as well as
  practical advice.
* (2015) [The Evolution of Elastic(Search) at Yelp](https://www.elastic.co/elasticon/2015/sf/evolution-of-elasticsearch-at-yelp):
  A talk I did with Chris Tidder at ElasicOn 2015 about how Yelp built self
  service Elasticsearch with sufficient abstractions to allow datastores to
  be maintained and scaled to large engineering organizations.
