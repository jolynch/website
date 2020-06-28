---
title: "SemVer Considered Harmful"
date: 2020-06-21T12:57:26-07:00
tags: ["software-opinions"]
---

In the past ten years or so, [Semantic Versioning](https://semver.org) a.k.a
"SemVer" has become extremely popular in the software development world. The
idea is that libraries and services can convey information to users about how
the application programming interface
([API](https://en.wikipedia.org/wiki/Application_programming_interface)) of
that library/package/service is evolving just using the version number. This
information is conveyed through three dotted numbers that form a logical clock
for totally ordering changes to the software API:

<center><h3>Semantic Version Numbers</h3></center>
{{< highlight text >}}
====================== Specification ========================

Version = <Major>.<Minor>.<Patch>

Major: this number goes up when the public API breaks
Minor: this number goes up when the public API changes
Patch: this number goes up when the public API doesn't change

====================== Examples =============================

# A Minor API change happened, safe to upgrade
1.4.5 -> 1.5.0

# API breakage, probably unsafe to upgrade
1.7.0 -> 2.0.0

# Who knows what will happen
0.182.13 -> 0.182.14
=============================================================
{{< /highlight >}}


Armed with this information, software developers can theoretically upgrade
without fear of the new version breaking their code.

How SemVer Breaks
=================

I believe that this versioning scheme, in practice, is problematic and creates
a large amount of pain in our industry. Three concrete failure modes I witness
frequently are:

1. Most packaging systems (deb, rpm, python, ruby, java, etc ...) cannot
   simultaneously install multiple major versions of the same package name.
   This often leaves users unable to upgrade to the latest major version due to
   (reasonable) fear of breakages.
2. Frequent major version bumps frequently break functional code, leading
   to [dependency hell](https://en.wikipedia.org/wiki/Dependency_hell) where
   library/service authors mix and match min, max, and exact version pins on
   major versions to try to work around various incompatibilities. These pins
   inevitably conflict.
3. There is still no standard way to derive the source code which produced the
   artifact or seeing the difference between two versions. This makes it hard
   to verify how the API is breaking or whether it will break specific usage
   patterns.

There is also the somewhat annoying issue of the plethora of `0.X` artifacts,
which happen because developers, somewhat reasonably, don't want to release
a public API they will have to stand behind until they can be certain they
can.

Ultimately these factors lead to software developers, myself included, viewing
dependency upgrades with great trepidation. Quite reasonably developers defend
themselves from breakage by either not upgrading their dependencies (unless
they are forced to), vendoring dependent code, or skipping dependencies all
together and just writing it themselves.

Reduce the Fear: Breaking Versions Must Cohabitate
--------------------------------------------------

The use of the major version number in SemVer to indicate API breakage is by
far the most problematic aspect of the design. In an ideal world, packaging
systems and programming languages would automatically namespace different major
versions, and code that depends on a particular major version would have all
references specifically reference the major version namespace. Unfortunately,
we do not live in an ideal world and most packaging systems simply don't
support this.  Three examples that I personally struggle with frequently:

**Debian packages (`apt`/`aptitude` in particular)**: You only get one version
and the higher one is almost always chosen even if that may break less-than
pins. A common practice with debian packages to work around these limitations
is to release new packages with a different name.

**Java libraries (`mvn`/`gradle` in particular)**: In a given class path you
can only have one implementation of a given package. Even if you manage to
convince gradle or maven to pull down multiple versions of a `.jar`, good luck
getting the JVM to not pick one implementation arbitrarily. As a result, Java
developers often resort to hacks like
[package path rewriting](https://imperceptiblethoughts.com/shadow/).

**Python libraries (`pip` in particular)**: While the Python community has
moved towards isolated virtual environments which does make this issue slightly
less of an issue (and with tools like `docker` or
[`dhvirtualenv`](https://github.com/spotify/dh-virtualenv) it gets even
better), you still can't install multiple versions of the same package in the
same virtualenv. Most Python projects I am aware of either don't work around
this and break all the things, or release multiple package names.

These problems are even worse for client libraries, where the library is wrapping a
remote (often backwards incompatible) API change. For me this has been one of the
hardest parts of upgrading distributed datastores that I work on because we
often can't use the vanilla client libraries during migration (e.g.
[Curator](https://curator.apache.org/) 2 vs Curator 4, Elasticsearch 2 vs 5,
etc ...). In my experience with most client library upgrades you have to create
an internal company fork that renames and relocates the package so we can run
both datastore APIs at the same time and have the client gracefully migrate
from the old version to the new one.

In an ideal world, remote APIs would remain backwards compatible for at least a
single major version to give users an upgrade path, but I find that many
developers argue that they don't need to remain backwards compatible across a
major version (this is what SemVer says after all ...). I wish this argument
was soundly rejected.

How can we fix this problem given the current constraints we operate under?
Well, we are left with a reasonably simple option: **put the API version
semantics in the name of the package.** Some example API migrations where I
have been able to take advantage of this technique are:

* `boto` to `boto3` (Python,
  [docs](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)):
  An extremely prevalent library for accessing AWS services
* `elasticsearch` to `elasticsearch2` (Python, [motivation](https://github.com/elastic/elasticsearch-py/issues/515)): A Python client library for the
   Elasticsearch search engine.
* Every Linux kernel package ever (the Linux kernel has this figured out!). The
  Kernel not only prohibits breaking user-space, but they give their users a
  great way to install multiple kernels at the same time.
* Cassandra's Thrift API
  ([Netflix Astyanax](https://github.com/Netflix/Astyanax))
  to Cassandra's CQL API
  ([Datastax Java Driver](https://github.com/datastax/java-driver)): The client
  drivers for the Cassandra database.


Reduce the Fear: Binary Versions Can be Traced to Source
--------------------------------------------------------

In my experience, software engineers spend a non trivial amount of time trying
to figure out "what actually changed between these two released versions". One
of the explicit goals of `SemVer` was to help developers reason about change.
As a developer myself I accidentally break things in minor versions all the
time, so I understand that this can happen. I don't mind the breakage as much
as being unable to debug what broke, since projects use many different ways of
relating released versions to code.

Some projects do use [git
tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging) to achieve this
auditability, but this isn't mandatory so some (many?) projects don't do it.
The commit id may, in some cases, be a better identifier since the commit id
must exist and `git` has a really easy way to view [changes between two
commits](https://git-scm.com/docs/git-diff). In fact, as far as I know, the
commit id is always easily comparable in practically every source control
system.

[Changelogs](https://en.wikipedia.org/wiki/Changelog) are also _nice_, but
while I can typically assume projects use source control since it is strictly
easier than not using source control, I don't think it is reasonable to expect
developers, often working for free, to take the time to summarize their
software changes into English changelogs. Writing clear and actionable English
is difficult, potentially more difficult than the code itself. Certainly, I
appreciate every project maintainer who takes the time to summarize changes in
a release, but I don't think it's fair to _expect_ it in the same way most
consumers of software expect producers to use source control.

Proposal: Semantic Package Names
================================

Both of these problems can be remedied with a straightforward evolution to
`SemVer` in which we make some small changes to include a great deal more
semantic information in the package name and version number. I call it
semantic package names and it consists of two changes:

1. Use package (=module) names to indicate an API has broken, not versions.
2. Attempt to include a source identifier in the version.

For example, `elasicsearch5` is the python library that functions with the
Elasticsearch server version 5.  Applications such as Elasticsearch or
Cassandra release named packages that unambiguously communicate the major
version API that is supported by that package. One possible example for Apache
Cassandra might be `cassandra-21x`, `cassandra-30x`, `cassandra-311x`, and
`cassandra-40x` for the `2.1`, `3.0`, `3.11`, `4.0` branches respectively.

I know this is not new, many software projects already follow this kind of scheme
such as the Linux kernel (a.k.a "Never break userspace") or the Go
[programming language](https://golang.org/cmd/go/#hdr-Module_compatibility_and_semantic_versioning).
I just believe that if every software project and language I interacted with
followed this pattern the whole industry would become more efficient and spend
less time fearing dependency updates. I have also found myself using this
technique internally to every company I've worked at to manage software change.

In addition to using semantic package names, I prefer when packages include a
fourth piece of metadata in their version number indicating the source version
that produced the artifact. Depending on the packaging system this is usually
either another dotted version (making it a four-tuple) or a `-` suffix.

<center><h3> Better Semantic Versioning </h3></center>

{{< highlight text >}}

====================== Specification ========================
<Package Version> = <Package Name>:<Version Number>
<Version Number>  = <Major>.<Minor>.<Patch><Identifier>

Package Name: This name changes when the public API breaks
Major: this number goes up with "major" public API additions
Minor: this number goes up with "minor" public API additions
Patch: this number goes up on every release, wrapping to
       zero on a Minor release.
Identifier: For packaging systems that support it, this
            string relates directly to a specific source
            code that produced the artifact.

An example of an identifier in git would be the first 8
characters of the commit SHA or if the project uses tags
this could be a tag

====================== Examples =============================

# Minor API change, SHAs indicate code versions
foo1:1.12.34.9bd9aeee -> foo1:1.13.0.625cd1dc

# Patch bump, lack of SHA indicates versions are tagged
foo1:1.13.12 -> foo1:1.13.13

# API breakage for an alpha
foo1:1.13.0 -> foo2:0.1.0

# Transition from unstable to stable API
foo3:0.123.1 -> foo3:1.0.0

=============================================================
{{< /highlight >}}

This solution is, as far as I am aware, backwards compatible with all existing
packaging and versioning schemes and solves all major issues identified with
the status quo. I have personally used such techniques in my jobs to do
dozens of previously impossible upgrades, and I believe all software developers
could fear upgrades significantly less if all software was released this way.

I wish that all packaging systems supported source identifiers in the version
number, which could permanently solve the traceability problem, but they don't.
For example, the Python version specifications generally don't allow arbitrary
text in the version tuple
(especially [PEP 440](https://www.python.org/dev/peps/pep-0440/) compliant version numbers).
Fortunately, I am usually deploying Python code as Docker containers or Debian
packages, both of which do support arbitrary text in their versions that can
include version numbers.

FAQ
---

**I don't like my public API anymore, how do I break it?**

That is great, please change the name of the package or module. Every packaging
system I am aware of namespaces packages by name and allows you to install both
at the same time.  This means that users of your package can safely migrate by
first including the new version, then porting all old code to the new version,
and finally removing the old version. The only cost to the user is the extra
disk space to host multiple versions.

**How do I ensure other people don't take my package name and like add a suffix?**

Yes, this is an issue. It is an issue right now in the status quo as well
without semantic names.  I don't have a backwards-compatible solution, but it
is probably reasonably straightforward for packaging systems (or package hosts)
to add support for claiming a namespace and associating it with a particular
publisher (similar to how you can do that for a single package name).


**How do I do unstable releases?**

The zero dot is still there, but now it is there to explicitly indicate stability.
Now that names are semantic you could *also* name your package something which
indicates its alpha/beta/unstable status. For example `library-beta` or
`library-unstable`. These words are much more descriptive than "it's a zero dot
release", and during the alpha/beta/unstable phases of a project you hopefully
have a somewhat early-adopting audience who is willing to change import names.

**How do I see the changes between two versions?**

You can use the third part of the tuple to relate the artifact to code.

{{< highlight text >}}
# SHA based identifiers
# 1.12.34.9bd9aeee -> 1.13.0.625cd1dc

# Command line
git diff 9bd9aeee 625cd1dc

# Github
https://github.com/org/project/compare/9bd9aeee..625cd1dc

# When shas are not absent in the released versions, version tags
# should exist
# 2.12.34 -> 2.13.0

# Command line
git diff v2.12.34 v2.13.0
{{< /highlight >}}


**As a software author, isn't maintaining multiple branches annoying?**

Most projects I am aware of already use multiple branches to support
multiple major versions. Otherwise applying patches that must apply to multiple
versions, such as security patches, is rather difficult.

I haven't really seen a good way of doing multiple majors with a single branch
absent sophisticated build infrastructure most people don't have.


**The merge conflicts between majors is gnarly**

Yes this is annoying, although I should point out again not unique to this
proposal. The easiest solution is not to break your API in the first place, but
thinking realistically sometimes this has to happen.  Usually though there are
ways around this either via clever symlinks or packaging tooling the merge
issue can be resolved. For example in Python libraries you can use [relative
imports](https://docs.python.org/3/reference/import.html#package-relative-imports)
and then all that is different between branches is the name of the package in
`setup.py`. Sometimes it is harder, like in Java the best tool I've found for
this is package re-writing while generating the jar via the [shadow
plugin](https://imperceptiblethoughts.com/shadow/).
