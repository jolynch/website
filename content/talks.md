---
title: "Talks"
menu: "main"
weight: 4
meta: false
---

Below are a collection of conference talks or other presentations that I've
given, typically related to distributed systems or other software engineering
topics:

* [Towards Practical Self-Healing Distributed Databases](https://www.youtube.com/watch?v=9wAM7L49agM) (2020):
  A talk at ApacheCon 2020 I gave on the self-healing database architecture and
  how to apply that to Cassandra. If you are trying to maintain a large scale
  database infrastructure this talk might have some useful tips.
* [How Netflix Debugs and Fixes Apache Cassandra When it Breaks](https://www.youtube.com/watch?v=Zf4ge12aOMg&)
  ([slides](https://github.com/ngcc/ngcc2019/blob/master/HowNetflixDebugsAndFixesApacheCassandraWhenItBreaks.pdf)) (2019):
  A talk at ApacheCon 2019 I gave about how to debug and scientifically analyze
  performance bottlenecks in Apache Cassandra. This is a very good "help I'm
  going oncall for Cassandra" introduction to basic tools and techniques.
* [How Netflix manages petabyte scale Apache Cassandra](https://github.com/ngcc/ngcc2019/blob/master/HowNetflixManagesPetabyteScaleApacheCassandraInTheCloud.pdf) (2019):
  A talk at ApacheCon 2019 I gave with Vinay Chella about how we design
  declarative control planes to orchestrate thousands of independently scaling
  Cassandra Clusters. Essentially this talk is "how to make your own
  self-driving database".
* [Iterating on Stateful Services in the Cloud](https://www.youtube.com/watch?v=valsEK5mIQI) (2018):
  A talk at re:Invent 2018 about how Netflix manages stateful services (such
  as datastores or databases) in the AWS cloud. Contains a lot of concrete
  advice for managing state in AWS.
* [Repair Service and Cassandra](https://youtu.be/KSmAdtMJYEo?list=PLBEdfxkxBbYHjAKk4N05vW1UerK-_WDeN&t=1526)
  (2018): Part of Netflix's OSS Meetup about Polyglot Persistence. Vinay Chella
  and I talk about how we built a repair scheduler for OSS Cassandra.
* [Building a Powerful Data Tier from Open Source Databases](https://www.youtube.com/watch?v=wOqxgC8cUWs)
  (2016): A talk I gave at OSCON London 2016 about how to build a polyglot
  datastore data tier using open source datastores.
* [The Human Side of Service-Oriented Architectures](https://www.youtube.com/watch?v=je6VB4RXzzY) (2016): A talk
  that an old mentor, John Billings, and I gave at the first Microservice
  summit about how you have to scale the human side of microservices (as
  opposed to the technical sides).
* [Automating Datastore Fleets with Puppet](https://www.youtube.com/watch?v=g8qDoU2WlVs) (2016):
  A more detailed talk on how we automated datastores at Yelp specifically with
  Puppet and other common industry tools. Given at Puppetconf 2016.
* [Writing a Polyglot Datastore Story](https://www.youtube.com/watch?v=Wb046sEnidQ) (2015):
  A talk I did with Josh Snyder at Velocity 2015 about how Yelp allowed
  developers to use polyglot datastores. Has architectural advice as well as
  practical advice.
* [The Evolution of Elastic(Search) at Yelp](https://www.elastic.co/elasticon/2015/sf/evolution-of-elasticsearch-at-yelp) (2015):
  A talk I did with Chris Tidder at ElasicOn 2015 about how Yelp built self
  service Elasticsearch with sufficient abstractions to allow datastores to
  be maintained and scaled to large engineering organizations.
