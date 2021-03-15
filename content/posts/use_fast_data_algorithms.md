---
title: "Use Fast Data Algorithms"
date: 2021-03-14T20:48:05-04:00
draft: true
---

As an engineer working with data I spend a lot of time moving data around,
hashing it, compressing it, encrypting it and generally trying to shovel it in
and out of blob stores. I am constantly surprised by how many systems only
support slow, inefficient, and expensive ways of doing these operations.

In my experience these poor algorithm choices are *orders of magnitude* slower
than modern alternatives, and in the interest of using more of our CPU time
to do useful work we will explore modern alternatives in this post.

<center><h3>Benchmarking Disclaimer</h3></center>
{{< highlight text >}}
As always, there are lies, damn lies, and benchmarks. If you are considering
taking some of the advice in this post please remember to test your specific
workloads, which might be different or have different bottlenecks.
{{< /highlight >}}

## Hashing
In data movement a common tasks is "I want to check these two pieces of data
match" and unfortunately slow algorithms are the most common choice. When I am
doing benchmarking I constantly see these poor algorithm choices (often from
the 90s) show up all over my performance profiles and it makes me sad because
we have significantly better choices now.

### Non-Cryptographic Hashes

**Common Poor Choices**
* `MD5`: This hash is both weak _and_ slow at about 100 MiBps. When I am doing
  performance analysis this poor choice pops up in profiles everywhere like
  Cassandra [Quorum
  Reads](https://issues.apache.org/jira/browse/CASSANDRA-14611) and S3
  upload/download.
* `CRC32`: I often hear "well CRC32" is fast, but to be honest I haven't come
  across a fast implementation. Theoretically there is hardware support
  for this, but at least in most Java or Python programs I profile they
  are using very slow software implementations.

**Better Choice**
Use [`XXHASH`](https://github.com/Cyan4973/xxHash) as it is blazing (10GiBps)
fast, high quality, and the `XXH64` variant is usually sufficient for most data
integrity checks. It even performs well on small data inputs, where `XXH3` is
particularly impressive.

**Quick-and-dirty Benchmark**
Expect 10x improvement from `MD5` to `XXH64`.


### Better Cryptographic Alternative

Use [`Blake3`](https://github.com/BLAKE3-team/BLAKE3). I very rarely find y


## Compression

### Best Choice for Performance

Use [`LZ4`](https://github.com/lz4/lz4). 

### Best Choice for 

## Pipeline
Now that we have fast algorithms, it matters how we wire them togehter. One of
the number one performance mistakes I see is doing a single step of a data
movement at a time, for example decrypting a file to disk and then
decompressing it. As the intermediate products must hit disk this neccesarily
slows down your data transfer.

When data transfer is slow there are usually either slow disks or slow Java
heap allocations in the way.

I've found that if I can structure my pipelines as unix pipelines with the
output from one stage always flowing to the input of the other I can much
more efficiently upload and download data.

For example the following will outperform almost any Java S3 upload:

```
HASH=
zstd --adapt 




## Encryption



