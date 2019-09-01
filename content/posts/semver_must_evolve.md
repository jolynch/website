---
title: "Semver Must Evolve"
date: 2019-09-01T12:57:26-07:00
draft: true
---

In the past ten years or so [Semantic Versioning](https://semver.org) a.k.a
"semver" has become extremely popular in the software development world. The
idea is that packages and libraries can convey information to users about how
the application programming interface (API) of that library/package/service is
evolving just using the version number. This information is conveyed through
three dotted numbers that form a logical clock for totally ordering changes:

<center><h3>Semantic Version Numbers</h3></center>
{{< highlight text >}}
<major>.<minor>.<patch>

Major: this number goes up when the public API breaks
Minor: this number goes up when the public API changes
Patch: this number goes up when the public API doesn't change

# Examples

# A Minor API change happened, safe to upgrade
1.4.5 -> 1.5.0

# API breakage, probably unsafe to upgrade
1.7.0 -> 2.0.0

# YOLO, who knows what will happen
0.182.13 -> 0.182.14
{{< /highlight >}}


Armed with this information, software developers can theoretically upgrade
without fear of the new version breaking their code.

**In practice, this versioning scheme is a _very bad idea_**

It is bad because:

1. Most packaging systems (deb, rpm, python, ruby, java, etc ...) cannot
   simultaneously host multiple major versions of a given package.
2. Frequent major (and even minor version bumps) do break code, leading to fun
   triangle dependency issues where library authors mix and match min, max, and
   exact version pins to try to work around various incompatibilities.
3. There is still no standard way to derive the source code which produced the
   artifact or seeing the diff between two versions.

There is also the somewhat annoying issue of the plethora of `0.X` artifacts,
which happen because developers, somewhat reasonably, don't want to release
a public API they will have to stand behind until they can be certain they
can.

Proposal 1: Breaking Versions Should Co-Habitate
================================================

The existence of the major version number in semver is by far the most
problematic in practice. In an ideal world packaging systems and programming
languages automatically namespace different major versions, and code that depends
on a particular major dep would have all references automatically re-written
to depend on the re-written major. Unfortunately, we do not live in an ideal
world and most packaging systems simply don't support this.  Three examples
that I personally struggle with constantly are:

**Debian packages (`apt`/`aptitude` in particular)**: You only get one version
and the higher one is almost always chosen even if that may break less than
pins. A common practice with debian packages to work around these limitations
is to release new packages with a different name.

**Java libraries (`mvn`/`gradle` in particular)**: In a given class path you
can only have one implementation of a given package, even if you manage to
convince gradle or maven to pull down multiple versions of a `.jar` good luck
getting the JVM to not just arbitrarily pick one implementation. As a result
Java developers often resort to hacks like package path rewriting.

**Python libraries (`pip`)**: While the Python community moved towards isolated
virtual environments which does make this issue slightly less of an issue (and
with e.g.  dhvirtualenv [todo link] it gets even better), you still can't
install multiple versions of the same package in the same virtualenv. Most
projects I am aware of either don't work around this and break all the things,
or release multiple package names.

This problem is even worse for client libraries, where the library is wrapping a
remote (often backwards incompatible) API change. For me this has been one of the
hardest parts of upgrading distributed datastores that I work on because we
often can't use the vanilla client libraries to during migration (e.g.  Curator
2 vs Curator 4, Elasticsearch 2 vs 5, etc ...). Instead we usually end up
creating a temporary fork and renaming the package internally so we can run
both datastore APIs at the same time and have the client gracefully migrate
from the old version to the new one.

In an ideal world remote APIs would remain backwards compatible for at least a
single major version to give users an upgrade path, but for some reason I find
that many developers argue that they don't need to remain backwards compatible
across a major version (this is what semver says after all ...). So we are
left with a reasonably simple option: **put the major version in the name of
the package.**

For example, when you want to release `foo=2.0.0` release `foo2` instead. Some
example migrations I have used this technique to successfully migrate are:

* `boto` to `boto3` (Python,
  [docs](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)):
  An extremely prevalent library for accessing AWS services
* `elasticsearch` to `elasticsearch2` (Python, [motivation](https://github.com/elastic/elasticsearch-py/issues/515)): A Python client library for the
   Elasticsearch search engine.
* Every linux kernel ever.


Proposal 2: Versions Should be Traceable to Code
================================================

I think software engineers spend a non trivial amount of time trying to figure out
"what actually changed between these two versions". One of the explicit goals of
`semver` was to help developers reason about change. As a developer myself I
accidentally break things in minor versions all the time, so I understand that
this can happen. I don't so much mind the breakage as being unable to debug what
broke since everybody has different ways of relating versions to code.

Some projects do use [git
tags](https://git-scm.com/book/en/v2/Git-Basics-Tagging) to achieve this, but
this isn't mandatory so some projects don't do it. The commit `SHA` may in some
cases be better identifier since it must exist and git has a really easy way to
view changes between two commits, as far as I know the commit id is always
easily comparable in practically every source control system.


Proposal: Semver Evolved
========================

I propose a simple evolution to `semver` in which we eliminate the major
version entirely. Package names are sufficient to indicate an API has changed.
For example, `elasicsearch5` is the python library that functions with the
Elasticsearch server version 5. We then shift all numbers up by one and add
a code identifier.


<center><h3> Better Semantic Version Numbers </h3></center>

{{< highlight text >}}
<minor>.<patch>.<identifier>

Minor: this number goes up when the public API changes
Patch: this number goes up on every release (and to zero on a minor release)
Identifier: An identifier which identifies a particular commit in code which
was used to build this artifact. For example in git this would be the first 8
of the SHA or if the project uses tags this could be a tag

# Examples

# Minor API change, SHAs
12.34.9bd9aeee -> 13.0.625cd1dc

# API breakage
# Nope not allowed, rename the package

# No need for YOLO mode since the package will be renamed when it is stable
{{< /highlight >}}


FAQ
---

**My public API is bad, how do I break it!**

Change the name of the package. Every packaging system I am aware of namespaces
packages by name and allows you to install both at the same time.  This means
that users of your library and package can safely migrate by first including
the new version, then porting all old code to the new version, and finally
removing the old version. The only cost to the user is the extra disk space to
host multiple versions.

**How do I do unstable releases like I used to do with major version zero?**

Name your package something which indicates its alpha/beta/unstable status. For
example `library-beta` or `library-unstable`. These words are much more
descriptive than "it's a zero dot release".

**How do I see the changes between two versions?**

```
# SHA based identifiers
# 12.34.9bd9aeee -> 13.0.625cd1dc

# Command line
git diff 9bd9aeee 625cd1dc 

# Github

# No SHA implies version tags
# 12.34 -> 13.0
# Command line
git diff v12.34 v13.0
```

**Isn't maintaining multiple branches annoying?**

To do multiple major versions you already _have to do multiple branches_ in
order to be able to do e.g. security patches. I haven't really seen a good way
of doing multiple majors with a single branch.


**The merge conflicts between majors is knarly**

Yes this can be annoying, the easiest solution is not to break your API in the
first place, but thinking realistically sometimes this has to happen.
Usually though there are ways around this either via clever symlinks or
packaging tooling the merge issue can be resolved. For example in Python
libraries you can use relative imports and then all that is different between
branches is the name of the package in `setup.py`. Sometimes it is harder, like
in Java the best tool I've found for this is package re-writing while
generating the jar via the shadow plugin [TODO link].
