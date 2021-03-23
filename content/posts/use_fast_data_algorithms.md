---
title: "Use Fast Data Algorithms"
date: 2021-03-22T20:48:05-04:00
tags: ["software-opinions"]
---

As an engineer who primarily works with data and databases I spend a lot of
time moving data around, hashing it, compressing it, decompressing it and
generally trying to shovel it between VMs and blob stores over TLS. I am
constantly surprised by how many systems only support slow, inefficient, and
expensive ways of doing these operations.

In my experience, these poor algorithm choices are *orders of magnitude* slower
than modern alternatives. Indeed, using a fast algorithm can often be the
difference between actually doing compression/hashing/encryption and "Eh, I'll
skip it".  In the interest of using more of our CPU time to do useful work
instead of melting ice-caps and giving programmers excessively long coffee
breaks, we will explore some faster alternatives in this post.

**TLDR**

| Application        | Common Bad Performance Choices  | Better Performance Choices | Expected Performance Gain |
| -----------------  | ------------------------------  | -------------------------- | ------------------ |
| Trusted data hashing | [`md5`](https://en.wikipedia.org/wiki/MD5), [`sha2`](https://en.wikipedia.org/wiki/SHA-2), [`crc32`](https://en.wikipedia.org/wiki/Cyclic_redundancy_check#CRC-32_algorithm) | [`xxhash`](http://cyan4973.github.io/xxHash/) | ~10x |
| Untrusted data hashing | `md5`, `sha2`, [`sha1`](https://en.wikipedia.org/wiki/SHA-1) | [`blake3`](https://github.com/BLAKE3-team/BLAKE3) | ~10x |
| Fast compression   | [`snappy`](https://en.wikipedia.org/wiki/Snappy_(compression)), [`gzip`](https://www.gnu.org/software/gzip/manual/gzip.html) (zlib) | [`lz4`](https://github.com/lz4/lz4) | 10x over `gzip`, ~2x over `snappy` |
| Good compression   | `gzip` (zlib)              | [`zstd`](https://facebook.github.io/zstd/) | ~2-10x |
| Best compression   | [`xz`](https://en.wikipedia.org/wiki/XZ_Utils) (lzma)               | [`zstd -10+`](https://facebook.github.io/zstd/) | ~2-10x |
| Java crypto (`md5`, `aes-gcm`, etc ...) | Built-in JVM crypto       | [`Amazon Corretto Crypto Provider (ACCP)`](https://github.com/corretto/amazon-corretto-crypto-provider) | ~4-10x |

> **Disclaimer**: There are lies, damn lies, and benchmarks from some random person
> on the internet.
>
> If you are considering taking some of the advice in this
> post please remember to test your specific workloads, which might have
> different bottlenecks. Also the implementation quality in your particular
> software stack for your particular hardware matters *a lot*.

For this post I'll be playing with a ~5 GiB real-world [JSON
dataset](https://www.yelp.com/dataset/download) on my laptop's
`Intel Core i7-8565U` pinned to
[4GHz](https://gist.github.com/jolynch/55185e455351d6b7febb266499207afa#file-benchmarkon-sh).
Since I want to benchmark the algorithms instead of disks I'll be pre-touching
the file into RAM with [`vmtouch`](https://hoytech.com/vmtouch/). Remember that
on most modern cloud servers with fast `NVMe` storage (multiple Gi**B**ps) and
good page-caching algorithms your disks are likely not your bottleneck.

```bash
$ du -shc yelp_academic_dataset_review.json
6.5G    yelp_academic_dataset_review.json
$ vmtouch -t yelp_academic_dataset_review.json
# ...
$ vmtouch yelp_academic_dataset_review.json
           Files: 1
     Directories: 0
  Resident Pages: 1693525/1693525  6G/6G  100%
         Elapsed: 0.1256 seconds
```

## Hashing

> I would like to check that this blob of data over here is the same as that
> data over there.

### Trusted Data Hashes
These hash or checksum functions are used to ensure data integrity and usually
are defending against bugs/bitrot/cosmic rays instead of malicious attackers.
I typically see the following poor choices:

* `md5`: This hash is both weak _and_ slow. It does have the advantage of
  being one of the fastest slow choices in standard libraries and therefore it
  is somewhat common. Two of my favorite examples are slow Cassandra [Quorum
  Reads](https://issues.apache.org/jira/browse/CASSANDRA-14611) and slow S3
  upload/download (seriously, just try disabling `md5` on parts and see how
  much faster S3 is).
* `crc32` or `adler32`: I often hear "well crc32 is fast", but to be honest I
  haven't in practice come across particularly fast implementations in
  real-world deployments. Sure theoretically there are hardware
  implementations, but at least in most Java or Python programs I profile
  running on most servers I encounter these checksums are not particularly fast
  and only generate 32 bits of output where I absolutely have to care about
  collisions.
* `sha2`: An oddly common choice for trusted data hashes. Odd because it is
  slow and you don't need a cryptographic hash for syncing a file
  between two hosts within an internal network with an authorized transfer
  protocol (e.g. `rsync` or via backups to `S3` with proper AWS
  [IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
  policies). If attackers have access to your backups or artifact store you
  have a bigger problem than them forging a hash.

**Faster Choice**

Try [`xxHash`](https://github.com/Cyan4973/xxHash). It is blazing fast, high
quality, and the `XXH64` variant is usually sufficient for most data integrity
checks. It even performs well on small data inputs, where `XXH3` is
particularly impressive. If you find yourself needing 128 bits of entropy (e.g.
if you're hashing data for a
[`DHT`](https://en.wikipedia.org/wiki/Distributed_hash_table)) you can either
use the 128 bit variant or `xxh3`. If you only have an old version available
that doesn't support the new 128 bit variant _two_ `XXH64` runs with
different seeds is usually still faster than any other choice.

### Untrusted Data Hashes

While most of the time the threat model for data transfer is "bugs / cosmic
rays", some of the time people want to defend against bad actors. That's
where cryptographic hashes come in, most commonly:

* `md5`: It's slow and not resistant to collisions ... everything I love in a hash
  function.
* [`sha1`](https://en.wikipedia.org/wiki/SHA-1): This hash is at least somewhat
  performant and isn't as completely broken as `md5`. We should probably still
  consider [it on shaky
  ground](https://en.wikipedia.org/wiki/SHA-1#SHAttered_%E2%80%93_first_public_collision)
  though.
* [`sha2`](https://en.wikipedia.org/wiki/SHA-2) (specifically `sha256`): An
  ubiquitous hash and unlike `md5` and `sha1` it is still considered secure, so
  that is nice. Unfortunately this hash is noticeably slow when used in
  performance critical applications.
* [`sha3`](https://en.wikipedia.org/wiki/SHA-3): The latest hash that NIST
  standardized (because they had concerns about `SHA-2` that appear at this
  time somewhat unfounded). I was not able to find it packaged outside of
  `openssl` and it doesn't appear to have great `cli` or language support at
  this time.  It's also still pretty slow.

**Faster Choice**

Try [`BLAKE3`](https://github.com/BLAKE3-team/BLAKE3). Yes it is a new (2020)
algorithm and there are concerns about security margin but I'm just so tired of
waiting for `sha256`. In practice, this is probably a much better choice than
the known-to-be-completely-broken `md5` so if you're reaching for `md5` over
`xxHash` because you need a cryptographic alternative, consider `blake3`
instead. Also `blake3` uses hash trees ([merkle
trees](https://en.wikipedia.org/wiki/Merkle_tree)) which are wonderful when
implemented correctly and I wish more systems used them.

The one major downside of `blake3` in my opinion is that at this time (2021) I
only know of really good `cli`, `Rust`, `Go`, `C`, and `Python` implementations
and I can't personally vouch for the `Java` JNI bindings. I've only needed to
use it so far from streaming pipeline verifications or artifact verification so
the `cli` and `python` implementations are good enough for me.

A quick reminder that there are lots of security-sensitive hashing situations
where you don't want a fast hash. For example, one situation where you want an
intentionally slow algorithm is when dealing with passwords. In such cases you
want a very slow hash like
[`argon2`](https://en.wikipedia.org/wiki/Argon2),
[`bcrypt`](https://en.wikipedia.org/wiki/Bcrypt),
[`PBKFD2`](https://en.wikipedia.org/wiki/PBKDF2) or even just a high number of
rounds of `SHA-512`.

### Show me the Data

Expect `xxHash` to net about a `~10x` improvement on `MD5` and ~5-10x improvement
on `CRC32` depending on your `CRC32` implementation (e.g. Java's is truly terrible).
Expect `BLAKE3` to be slightly slower than `xxHash` with a single thread so
only use it if you actually care about cryptographic hashes. A simple
[performance test](https://gist.github.com/jolynch/55185e455351d6b7febb266499207afa#file-hashing-sh)
on hashing a `6616 MiB` file confirms that indeed we have 10x performance on the table (
note I'm reporting `user` CPU time since the system time is not really up to the hash)

| Algo     | Hash Time (seconds) | Hash Speed (MiBps) | Cryptographic? | Bits of Entropy |
| -------- | ------------------: | -----------------: | -------------: | --------------: |
| `MD5`        | `9.1s`          | `727`              | Not really     | `128`          |
| `CRC32`      | `4.8s`          | `1378`             | No             | `32`           |
| **`XXH64`**  | `0.5s`          | `13232`            | No             | `64`           |
| | | | | |
| `SHA256`     | `27.5s`         | `240`              | Yes            | `256`          |
| `SHA3-256`   | `16.8s`         | `393`              | Yes            | `256`          |
| `SHA1  `     | `10.7s`         | `618`              | Yes\*          | `160`          |
| **`BLAKE3`** | `1.8s`          | `3675`             | Yes            | `256`          |

**Yes that's right, ~0.5 seconds user CPU time for `xxh64` versus ~27 for `sha256`** and `~9s` for `md5`.
If all you need to do is verify a file transfer you could be doing that 10x faster with xxHash.

The language versions often do make a big deal, e.g. `JNI` versions that link
to fast native code in Java will often significantly out-perform pure Java
versions. "But Joey", you say, "I have to use XYZ algorithm from the early '00s
because of the specification!".  That is unfortunate, but at least make sure
you're using fast implementations, for example
[ACCP](https://github.com/corretto/amazon-corretto-crypto-provider) will speed
up `MD5` on most Java VMs by a factor of ~4 as well as `AES-GCM` by ~10x while
it is at it. ACCP achieves this by ... linking in fast native implementations
of crypto.

## Compression
> I like my data transfers fast and don't like paying for lots of disk or
> network I don't need. I heard [data compression](https://en.wikipedia.org/wiki/Data_compression) is a thing.

Most data compresses, especially text (e.g. `JSON`). The three cases where data
probably does not compress are if your data is random, the data was already
compressed, or the data was encrypted. Often in databases the metadata around
the data (e.g. write times, schemas, etc ...) probably compresses even if the
data doesn't. There are three primary measures of a compression algorithm:

1. **Compression ratio**: How much smaller is the result than the input?
2. **Compression speed**: How quickly can I compress data?
3. **Decompression speed**: How quickly can I decompress data?

Depending on the use case, developers usually make some tradeoff between these
three metrics.  For example, databases doing page compression care most about
decompression speed, file transfers care most about compression speed, archival
storage cares most ratio, etc ...

Fast compression that gives great ratio can significantly improve most
workloads but slow compression with bad ratio is painful and makes me sad.

## Common Poor Choices
* [`gzip`](https://www.gnu.org/software/gzip/manual/gzip.html) (`zlib`): A
  trusty workhorse but also a very slow algorithm. In many cases where your
  network is fast (`1 Gbps+`), compressing with gzip can actually hurt your system's
  performance (I have seen this numerous times).
* [`xz`](https://en.wikipedia.org/wiki/XZ_Utils) (`lzma`): An
  algorithm that has pretty good ratios, but is so slow to compress that in
  practice the only potential use cases are single-write
  many-read use cases.
* [`snappy`](https://en.wikipedia.org/wiki/Snappy_(compression)): One of the
  first "I'll trade off ratio for speed" algorithms, snappy was good for its
  time. These days it is almost always outperformed by other choices.


### Better Choice - I care about ratio

Try [`zstd`](https://facebook.github.io/zstd/). To spend more compression
CPU time for better compression ratio increase the compression level or increase the block
size. I find that in most database workloads the default level (`3`) or even
level `1` is a good choice for write heavy datasets (getting closer to `lz4`)
and level `10` is good for read heavy datasets (surpassing `gzip` in every
dimension). Note that `zstd` strictly dominates `gzip` as it is faster and gets
better ratio.

Even better: `zstd` supports [training dictionaries](https://facebook.github.io/zstd/#small-data)
which can really come in handy if you have lots of individually small but
collectively large `JSON` data (looking at you tracing systems).

### Better Choice - I only care about speed

Try [`lz4`](https://github.com/lz4/lz4). With near memory speeds and decent
ratio this algorithm is almost always a safe choice over not compressing at
all. It has excellent language support and is exceptionally good for real-time
compression/decompression as it is so cheap.

### Better Choice - I want to shovel data from here to there

Try [`zstd --adapt`](https://facebook.github.io/zstd/). This feature
automatically adapts the compression ratio as the IO conditions change to make
the current optimal tradeoff between CPU and "keeping the pipe fed".

For example, if you are have very little free CPU on your system but a fast
network (looking at you `i3en` instances) `zstd --adapt` will automatically
compress with a lower level to minimize total transfer time. If you have a slow
network and extra CPU it will automatically compress at a higher level.

### Show me the Data

Compression is a bit trickier to measure because the read to write ratio
matters a lot and if you can get better ratio that might be worth it to pay
a more expensive compression step for cheaper decompression.

Historically we had to make tradeoffs between ratio, compression speed and
decompression speed, but as we see with [this quick
benchmark](https://gist.github.com/jolynch/55185e455351d6b7febb266499207afa#file-compression-sh)
we no longer need to make tradeoffs. These days (2021), I just reach for `zstd`
with an appropriate level or `lz4` if I really need to minimize CPU cost.

First let's look at the results for the `6.5GiB` review dataset.

| Algo | Ratio  | Compression Speed (MiBps) | Decompression Speed (MiBps) | Transfer Time |
| -----  | -----  | ------------------------: | ------------------------: | ------------: |
| `gzip` | `0.41` | `21`                      | `168`                     | `295s`  |
| `lz4`  | `0.65` | `361`                     | `1760`                    | `36s`   |
| `zstd` | `0.38` | `134`                     | `730`                     | `47s`   |
| `xz`   | `??`   | `??`                      | `???`                     | `??`    |

As `xz` was estimating 1.5 hours to compress and I didn't have that kind of time I ran
that on a smaller `380MiB` dataset:

| Algo       | Ratio  | Compression Speed (MiBps) | Decompression Speed (MiBps) | Transfer Time|
| ---------- | -----  | ------------------------: | --------------------------: | -----------------------: |
| `xz`       | `0.18` | `1.34`                    | `92 `                       | `299s` |
| `zstd -10` | `0.26` | `15.4`                    | `713`                       | `24s` |
| `zstd -19` | `0.21` | `1.18`                    | `404`                       | `24s` |


As expected `lz4` is the fastest choice by a lot while still cutting the
dataset in half, followed by `zstd`. One of the really useful things about
`zstd` is that I am no longer reaching for specialty compressors depending on
the job, I just change the level/block sizes and I can get the trade-off I
want.

## Pipeline
Now that we have fast algorithms, it matters how we wire them together. One of
the number one performance mistakes I see is doing a single step of a data
movement at a time, for example decrypting a file to disk and then
decompressing it and then checksumming it. As the intermediate products must hit disk and
are done sequentially this necessarily slows down your data transfer.

When data transfer is slow there are usually either slow disks or slow Java
heap allocations in the way. I've found that if I can structure my pipelines as
unix pipelines of fast `C` programs (or Python with native extensions) with the
output from one stage always flowing to the input of the other I can much more
efficiently upload and download data by doing everything (IO, decrypt, decompress, checksum)
in parallel.

For example, something like the following will outperform almost any Java S3
upload at putting 100 files in S3 along with whole object checksums
```bash
# Assumption: You have xargs, xxh64sum, zstd and awscli installed

# Simple version
$ DIR=.

$ find $DIR -maxdepth 1 -type f | xargs -IX -P 8 xxh64sum X | sort -k 2 > aws s3 cp - s3://bucket/prefix/checksums
$ find $DIR -maxdepth 1 -type f | xargs -IX -P 8 | bash -c 'zstd --adapt X --stdout | aws s3 cp - s3://bucket/prefix/data/X.zst'

# Or the full pipeline option (full object hash and compress at the same time)
$ find $DIR -maxdepth 1 -type f \
| xargs -IX -P 8 \
bash -c 'export URL=s3://bucket/prefix; cat X | tee >(xxh64sum - | aws s3 cp - ${URL}/X.zst.xxh) | zstd --adapt - --stdout | aws s3 cp - ${URL}/X.zstd'
```

## Why do fast data algorithms matter ?

It matters because most systems choose the slow option and make routine
development activities take longer in modern cloud infrastructure (fast
networks). For example:

* Backing up data. Backing up 1 TiB of data to a fast blob store (can sink
  multiple `GiBps`) using `gzip` and `sha256` would take around `15` hours. Doing
  it with `zstd` and `xxhash` takes `2.2` hours. Timely backups are one of the
  most important properties of a data system.
* Software packages. By default debian packages are either not compressed or
  compressed with `xz`. Installing 500 MiB of uncompressed debian packages over
  a one gig network takes `~5s`, with `xz` compression it actually
  slows down and takes `~1s + ~6s = ~7s`, and with `zstd -19` compression it
  takes `~1s + ~1s = ~2s`. If the `sha256` is checked that would add another
  `~20s` for a total of `~30s` versus if we check with `blake3` that adds
  `~0.1s` for a total of `~3s`.  I'd take the `3s` over `30s` any day. This
  matters every time you build container images, bake cloud VM images or
  bootstrap servers with configuration management (puppet/chef).
* Container Images. By default `docker` uses `gzip` compression with `sha256`
  checksums, which means to decompress and checksum 4GiB of containers I'd need
  about `60s` of CPU time instead of ~`6s` with `zstd` and `xxhash` (or `6.5`s
  with `blake3`). This matters when your docker pull is in the startup path of
  your application.

### A note about implementation availability

A major disadvantage of using good algorithms is that they may not always show
up in your language or OS by default. I've had good experiences with the
following implementations:

* `xxHash`: `cli`, [`python`](https://pypi.org/project/xxhash/), and [`java`](https://github.com/lz4/lz4-java#xxhash-java)
* `lz4`: `cli`, [`python`](https://pypi.org/project/lz4/), and [`java`](https://github.com/lz4/lz4-java#lz4-java).
* `zstd`: `cli`, [`python`](https://pypi.org/project/zstandard/), and [`java`](https://github.com/luben/zstd-jni).
* `blake3`: [`cli`](https://github.com/BLAKE3-team/BLAKE3/releases/tag/0.3.7), and [`python`](https://pypi.org/project/blake3/)
* [`Pinch`](https://github.com/jolynch/pinch) is a [docker image](https://hub.docker.com/r/jolynch/pinch)
  I built so I can bring my swiss-army-knife of hashing/compression techniques
  to any server that can run docker. I use this a lot on CI/CD systems.
