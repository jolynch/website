---
title: "SemVer Needs to Evolve"
date: 2020-06-21T12:57:26-07:00
tags: ["software-opinions"]
---

In the past ten years or so [Semantic Versioning](https://semver.org) a.k.a
"SemVer" has become extremely popular in the software development world. The
idea is that libraries and services can convey information to users about how
the application programming interface
([API](https://en.wikipedia.org/wiki/Application_programming_interface)) of
that library/package/service is evolving just using the version number. This
information is conveyed through three dotted numbers that form a logical clock
for totally ordering changes to the software API:

<center><h3>Semantic Version Numbers</h3></center>
{{< highlight text >}}
Version = <Major>.<Minor>.<Patch>

Major: this number goes up when the public API breaks
Minor: this number goes up when the public API changes
Patch: this number goes up when the public API doesn't change

# === Examples ===

# A Minor API change happened, safe to upgrade
1.4.5 -> 1.5.0

# API breakage, probably unsafe to upgrade
1.7.0 -> 2.0.0

# Who knows what will happen
0.182.13 -> 0.182.14
{{< /highlight >}}


Armed with this information, software developers can theoretically upgrade
without fear of the new version breaking their code.

How SemVer Breaks
=================

I believe that this versioning scheme, in practice, is problematic and creates
a large amount of pain in our industry. Three concrete failure modes I witness
frequently are:

1. Most packaging systems (deb, rpm, python, ruby, java, etc ...) cannot
   simultaneously host multiple major versions of a given package. This often
   leaves users unable to upgrade to the latest major version due to
   (reasonable) fear of breakages.
2. Frequent major (and even minor version bumps) do break code, leading to
   [dependency hell](https://en.wikipedia.org/wiki/Dependency_hell) where
   library/service authors mix and match min, max, and exact version pins to
   try to work around various incompatibilities.
3. There is still no standard way to derive the source code which produced the
   artifact or seeing the diff between two versions. This makes it hard to
   verify how the API is breaking or whether it will break specific
   usage patterns.

There is also the somewhat annoying issue of the plethora of `0.X` artifacts,
which happen because developers, somewhat reasonably, don't want to release
a public API they will have to stand behind until they can be certain they
can.

Ultimately all of these factors lead to Fear, Uncertainty and Doubt
([FUD](https://en.wikipedia.org/wiki/Fear,_uncertainty,_and_doubt)) and
quite reasonably developers defend themselves by either not upgrading
their dependencies unless they have to, vendoring dependent code, or skipping
dependencies all together and just writing it themselves.

Reduce the FUD: Breaking Versions Can Cohabitate
------------------------------------------------

The existence of the major version number in SemVer is by far the most
problematic aspect of the design. In an ideal world, packaging systems and
programming languages would automatically namespace different major versions,
and code that depends on a particular major version would have all references
specifically reference the major version namespace. Unfortunately, we do not
live in an ideal world and most packaging systems simply don't support this.
Three examples that I personally struggle with constantly are:

**Debian packages (`apt`/`aptitude` in particular)**: You only get one version
and the higher one is almost always chosen even if that may break less than
pins. A common practice with debian packages to work around these limitations
is to release new packages with a different name.

**Java libraries (`mvn`/`gradle` in particular)**: In a given class path you
can only have one implementation of a given package, even if you manage to
convince gradle or maven to pull down multiple versions of a `.jar` good luck
getting the JVM to not just arbitrarily pick one implementation. As a result
Java developers often resort to hacks like
[package path rewriting](https://imperceptiblethoughts.com/shadow/).

**Python libraries (`pip`)**: While the Python community has moved towards
isolated virtual environments which does make this issue slightly less of an
issue (and with tools like `docker` or
[`dhvirtualenv`](https://github.com/spotify/dh-virtualenv) it gets even
better), you still can't install multiple versions of the same package in the
same virtualenv. Most python projects I am aware of either don't work around
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
major version (this is what SemVer says after all ...).

How do we fix this problem given the current constraints we operate under?
Well, we are left with a reasonably simple option: **put the major version in
the name of the package.** For example, when you want to release `foo=2.0.0`
release `foo2` instead. Some example API migrations I have been able to take
advantage of this technique are:

* `boto` to `boto3` (Python,
  [docs](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)):
  An extremely prevalent library for accessing AWS services
* `elasticsearch` to `elasticsearch2` (Python, [motivation](https://github.com/elastic/elasticsearch-py/issues/515)): A Python client library for the
   Elasticsearch search engine.
* Every Linux kernel package ever (the Linux kernel has this figured out!). The
  Kernel not only prohibits breaking user-space, but they give their users a
  great way to install multiple kernels at the same time.


Reduce the FUD: Binary Versions Can be Traced to Source
-------------------------------------------------------

In my experience, software engineers spend a non trivial amount of time trying
to figure out "what actually changed between these two released versions". One
of the explicit goals of `SemVer` was to help developers reason about change.
As a developer myself I accidentally break things in minor versions all the
time, so I understand that this can happen. I don't so much mind the breakage
as being unable to debug what broke since projects use many different ways of
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
software changes into English changelogs.


Proposal: Ditch "Major" Version Numbers
=======================================

Both of these problems can be remedied with a simple evolution to `SemVer` in
which we only use the major version to signal stability rather than A. Package names are sufficient to
indicate an API has changed.  For example, `elasicsearch5` is the python
library that functions with the Elasticsearch server version 5. Applications
such as Elasticsearch or Cassandra release named packages that unambiguously
communicate the major version API that is supported by that package. One
possible example for Cassandra might be `cassandra-21x`, `cassandra-30x`,
`cassandra-311x`, and `cassandra-40x` for the `2.1`, `3.0`, `3.11`, `4.0`
branches respectively. With the removal of major version, we shift all other
numbers up by one and use the newly available third slot as a code identifier.

<center><h3> Better Semantic Version Numbers </h3></center>

{{< highlight text >}}
Version = <Minor>.<Patch>.<Identifier>

Minor: this number goes up when the public API changes
Patch: this number goes up on every release, wrapping to
zero on a Minor release.
Identifier: this string relates directly to a specific
source that produced this artifact.

An example of an identifier in git would be the first 8
characters of the commit SHA or if the project uses tags
this could be a tag

# === Examples ===

# Minor API change, SHAs indicate code versions
12.34.9bd9aeee -> 13.0.625cd1dc

# Patch bump, versions are tagged
13.12.tags -> 13.13.tags

# API breakage
# Not allowed - rename your package
{{< /highlight >}}

This solution is, as far as I am aware, backwards compatible with all existing
packaging and versioning schemes and solves all major issues identified with
the status quo. I have personally used such techniques in my jobs to do
dozens of previously impossible upgrades, and I think we as a field could fear
upgrades significantly less if all software was released this way.

FAQ
---

**I don't like my public API anymore, how do I break it?**

Change the name of the package. Every packaging system I am aware of namespaces
packages by name and allows you to install both at the same time.  This means
that users of your package can safely migrate by first including the new
version, then porting all old code to the new version, and finally removing the
old version. The only cost to the user is the extra disk space to host multiple
versions.

**How do I do unstable releases like I used to do with major version zero?**

Name your package something which indicates its alpha/beta/unstable status. For
example `library-beta` or `library-unstable`. These words are much more
descriptive than "it's a zero dot release".

**How do I see the changes between two versions?**

You can use the third part of the tuple to relate the artifact to code.

{{< highlight text >}}
# SHA based identifiers
# 12.34.9bd9aeee -> 13.0.625cd1dc

# Command line
git diff 9bd9aeee 625cd1dc

# Github
https://github.com/org/project/compare/9bd9aeee..625cd1dc

# Rather than a commit id the phrase "tags" implies the existance
# of version tags:
# 12.34.tags -> 13.0.tags

# Command line
git diff v12.34 v13.0
{{< /highlight >}}


**As a softwre author, isn't maintaining multiple branches annoying?**

Most projects I am aware of already use multiple branches to support
multiple major versions. Otherwise applying patches that must apply to multiple
versions, such as security patches, is rather difficult.

I haven't really seen a good way of doing multiple majors with a single branch
absent sophisticated build infrastructure most people don't have.


**The merge conflicts between majors is knarly**

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
