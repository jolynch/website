---
title: "Yes there has been inflation"
date: 2021-10-30T09:32:19-04:00
tags: ["economics"]
---

I recently read [The Deficit Myth](https://www.google.com/books/edition/_/0r7_ygEACAAJ?hl=en)
and I particularly enjoyed the insight that [inflation](https://en.wikipedia.org/wiki/Inflation)
comes from consumer spending on supply-limited goods, _not printing money_. Put
differently, when a consumer wants a scarce good _and_ has more money to spend
they will accept a higher price for the same good. Inflation only occurs when
the consumer accepts that higher price.

This realization has some interesting consequences for U.S. Federal
[monetary](https://en.wikipedia.org/wiki/Monetary_policy) and
[fiscal](https://en.wikipedia.org/wiki/Fiscal_policy) policy:

1. Printing money does not inherently cause inflation. People spending money
   causes inflation and it matters more _who_ has excess money (or credit) to
   spend.
2. Spending money to create supply only causes inflation on the materials that
   supplier requires. It is less likely consumers would see these price increases
   long term as the increased supply compensates.
3. For the _federal_ government, tax cuts are functionally equivalent to
   printing money and handing it directly to certain people. Taxes remove
   money from the system, spending creates it.

Under this insight the past decade of loose monetary policy but [low
inflation](https://fred.stlouisfed.org/graph/?g=EqRD) in the consumer price
index ([CPI](https://www.bls.gov/cpi/)) makes sense if that money supply did
not primarily flow to most consumers who buy most goods.

I contend there actually has been inflation, but in goods that wealthy
Americans compete for, not for everyday goods. Relatedly, I personally believe
this is a sign we as a society are not efficiently distributing
wealth to most people, but concentrating it in the hands of the few who then
use it to compete for luxury goods.

## There has actually been inflation

Most of the money that has been created in the past twenty years via tax cuts,
stock market gains, defense spending, and government guaranteed loans (in
particular mortgage guarantees and education loans) has flowed to generally
wealthier people and not to most consumers.

Wealthy people don't compete for gallons of milk, they compete for scarce
assets and luxury real world goods. For example, a wealthy person might compete
with other wealthy people for:

* (Fine) Art
* (Desirable) Land
* (Large) Yachts
* (Fancy) Jewelry
* (New) Cars
* (Higher) Education

Average prices on all of these have increased, but just like measuring average
latency doesn't reveal much information, we want to
look at the [statistical tail](https://en.wikipedia.org/wiki/Long_tail) of the
distribution to see where the inflation lives.

Unfortunately, there isn't very much in the way of price distribution data
available for these asset classes (say relative to liquid assets like
stocks or bonds) and I'm not sufficiently invested in this post to try to
get it, so let's just look as some of the tail events that have happened
in the last decade and see what we see. We can calculate inflation rates with a
simple function:

{{< highlight python >}}
def inflation(p, y):
    """
    Given two prices and two years, calculate the annual
    inflation rate as a percentage (0-100)
    """
    p1, p2 = p
    y1, y2 = y
    ratio = p2 / p1
    years = 1 / (y2 - y1)
    return round((ratio ** years - 1) * 100, 2)

# inflation((127.5, 450.3), (2013, 2017)) -> 37.09
{{< /highlight >}}

So if we were to look at [CPI](https://fred.stlouisfed.org/series/CPIAUCNS)
we'd see inflation of around 3% annually since 1980 and even lower around
2.3% since 2000.

{{< highlight text >}}
# From 1980 to 2021
inflation((77.8, 261.582), (1980, 2021)) -> 3.0
# Or just from 2000 to 2021
inflation((168.8, 273), (2000, 2021)) -> 2.32
{{< /highlight >}}

In the same period [median full-time annual wages](https://fred.stlouisfed.org/series/LES1252881500Q)
have increased as well, around 3.4% since 1980 and 2.7% since 2000. Even the
first [decile](https://fred.stlouisfed.org/series/LEU0252911200Q) of wages have
increased similarly (data is only available since 2000 for that series). [Median
household income](https://fred.stlouisfed.org/series/MEHOINUSA646N) has also
increased similarly in [current dollars](https://www.census.gov/topics/income-poverty/income/guidance/current-vs-constant-dollars.html)

{{< highlight text>}}
# Median full-time wages from 1980 to 2021
inflation((254, 990), (1980, 2021)) -> 3.37
# Median full-time wages from 2000 to 2021
inflation((568, 990), (2000, 2021)) -> 2.68
# First decile full-time from 2000 to 2021
inflation((281, 502), (2000, 2021)) -> 2.8

# Median household income from 1984 to 2020
inflation((22_415, 67_521), (1984, 2020)) -> 3.11
# Median household income from 1984 to 2020
inflation((41_990, 67_521), (2000, 2020)) -> 2.4
{{< /highlight >}}

Let's focus in on the last two decades, where CPI has inflated by around 2.3%
and median full-time wages have increased by around 2.68%. How do these average
rates compare to prices at the tail of the distribution?

### Desirable Art

The 2010s have been [good](https://www.artnews.com/art-news/market/art-market-2010s-1202674009/)
for fine art, seeing some [record breaking sales](https://en.wikipedia.org/wiki/List_of_most_expensive_paintings)
such as:

2017: $450.3 million for
[Salvator Mundi](https://en.wikipedia.org/wiki/Salvator_Mundi_(Leonardo)) by
[Leonardo da Vinci](https://en.wikipedia.org/wiki/Leonardo_da_Vinci). Valued at
$127.5 million in 2013 for a 37% annual inflation rate.

{{< highlight text >}}
inflation((127.5, 450.3), (2013, 2017)) -> 37.09
{{< /highlight >}}

2017: $110.5 million for [Untitled](https://en.wikipedia.org/wiki/Untitled_(1982_painting))
by [Jean-Michel Basquiat](https://en.wikipedia.org/wiki/Jean-Michel_Basquiat),
the largest sum ever paid for an American artist at auction. Valued at
$20,900 in 1984 this is a 30% annual inflation rate.

{{< highlight text >}}
inflation((20_900, 110.5e6), (1984, 2017)) -> 29.67
{{< /highlight >}}

2015: $179.4 million for [Les Femmes d'Alger, Version O](https://en.wikipedia.org/wiki/Les_Femmes_d%27Alger#%22Version_O%22) by [Pablo Picasso](https://en.wikipedia.org/wiki/Pablo_Picasso).
Sold for $31.9 million in 1997 this is a 10% annual inflation rate.

{{< highlight text >}}
inflation((31.9, 179.4), (1997, 2015)) -> 10.07
{{< /highlight >}}

As many (most?) sales of art are private it is hard to know exactly how much
inflation has been going on in the fine art community. Above we looked at some
of the tail events happening in public auctions over the past decade and
hopefully as the
[LLCs](https://www.sec.gov/Archives/edgar/data/1738134/000149315218016661/partiiandiii.htm)
created by companies like [masterworks.io](https://www.masterworks.io/) become
more common we can finally get some accurate market data.

That being said, fine art is inflating at a rate far greater than 2.3%, probably
closer to 10%.

### Desirable Land

Ideally we could break down land value separately from homes so we can look
at how the actual scarce good (land) performs relative to the durable good
of the house itself. I can't seem to find good data on per locality land values
without homes on them, but [Zillow Research](https://www.zillow.com/research/data/)
does provide the Zillow Home Value Index (ZHVI) for ["Top Tier"](https://files.zillowstatic.com/research/public_csvs/zhvi/City_zhvi_uc_sfrcondo_tier_0.67_1.0_sm_sa_month.csv?t=1633281985)
markets (65% - 95% for a region) which can give us some insight into how the
most expensive real-estate markets in America have inflated since 2000.

Homes in [Atherton](https://en.wikipedia.org/wiki/Atherton,_California),
California (rich Tech Bay Area, part of "Silicon Valley") have increased from
$4.6 million in 2000 right at the peak of the tech bubble to $12.4 million in
2021, for a 4.85% inflation rate. If you just look from 2012 to 2021 the
rate increases to around 7%.

{{< highlight text >}}
inflation((4_599_043, 12_445_835), (2000, 2021)) -> 4.85
inflation((6_804_630, 12_445_835), (2012, 2021)) -> 6.94
{{< /highlight >}}

Homes in [Aspen](https://en.wikipedia.org/wiki/Aspen,_Colorado), Colorado
have increased from $3.1 million in 2000 to $8.36 million in 2021, for a
4.8% inflation rate.
{{< highlight text>}}
inflation((3_125_662, 8_362_437), (2000, 2021)) -> 4.8
{{< /highlight >}}

Homes in
[Bridgehampton](https://en.wikipedia.org/wiki/Bridgehampton,_New_York), New
York (part of the "Hamptons") have increased from $1.82m in 2000 to $7.8
million in 2021, for a 7.11% inflation rate.
{{< highlight text>}}
inflation((1_842_709, 7_793_749), (2000, 2021)) ->: 7.11
{{< /highlight >}}

Near where I grew up the most desirable homes were in
[Potomac](https://en.wikipedia.org/wiki/Potomac,_Maryland), Maryland (rich
public figures and such from DC). From 2000 to 2006 homes there increased from
$782,806 to around $1.7 million, for a 14% inflation rate, but never really
recovered after the financial crisis and stand at about the same value today
yielding a 3.6% annual inflation rate from 2000 to 2021.
{{< highlight text>}}
inflation((782_806, 1_713_201), (2000, 2006)) -> 13.94
inflation((782_806, 1_652_206), (2000, 2021)) -> 3.62
{{< /highlight >}}

At the top end of the real-estate market we have also seen higher price
increases than 2.3%, although it is very time dependent, probably around 5%
though.

### Desirable Watches

I wasn't sure if I should include watches in this analysis because desirable
luxury watches have had a somewhat large
[rise in prices](https://www.cnbc.com/2021/10/13/luxury-watch-shortage-drives-growth-of-20-billion-secondhand-market.html)
since 2019, but I do think it's a good example of the kind of supply limited
luxury goods that wealthy people are absolutely competing for.

For example, the [Patek Philippe](https://en.wikipedia.org/wiki/Patek_Philippe_SA)
Nautilus 5711 (blue dial 1A-010) has increased from around $24,215 in 2013 to
nearly $145,000 in 2021 according to
[Chrono24](https://www.chrono24.com/patekphilippe/ref-57111a010.htm). Yes there
are _stainless steel_ watches going for over one hundred thousand dollars on the
secondary market! Rare and precious metal watches have increased perhaps even
more such as the [Rolex Rainbow Daytona ref 116595RBOW](https://www.chrono24.com/rolex/rainbow--imod2759.htm)
which in rose gold were originally sold at $96,900 in 2018 and in 2021 can go for
as high as $500,000. Watches that are intentionally kept scarce such as those
produced by
[Richard Mille](https://en.wikipedia.org/wiki/Richard_Mille) routinely
sell for between a quarter and half a million dollars, often far above retail
prices.

{{< highlight text>}}
inflation((24_215, 145_000), (2013, 2021)) -> 25.07
inflation((96_900, 500_000), (2018, 2021)) -> 72.8
{{< /highlight >}}

At the top end of the luxury watch market we have seen price increases similar
to that of fine art, probably because luxury watches are more fine art than
functional. Although data is scarce, it is likely that luxury watches in
general have experienced around 10% inflation over the past two decades.

### Desirable Education

We often hear about how the cost of higher education is increasing in
America for a multitude of reasons. Under the "available money spent on scarce
goods creates inflation" philosophy one might explain it primarily because
more consumers have access to credit (often with rather punishing terms) to
pay for college (demand) while the number of slots at universities (supply)
have remained somewhat constant. But at the tail, how have tuitions changed at
the top three Universities in the world (according to
[US News and World Report](https://www.usnews.com/education/best-global-universities/rankings))?

One year of education at Harvard University has
[increased](https://oir.harvard.edu/fact-book/undergraduate_package) from
$32,164 in 2000 to $63,025 in 2017 for a 4% inflation rate.

{{< highlight text >}}
inflation((32_164, 63_025), (2000, 2017)) -> 4.04
{{< /highlight >}}

One year of education at MIT, which apparently [includes much more expensive
housing than Harvard](https://sfs.mit.edu/undergraduate-students/the-cost-of-attendance/annual-student-budget/),
has increased from $33,225 in [2000](https://news.mit.edu/2000/tuition) to $77,020 in 2021
for a 4.08% inflation rate.

{{< highlight text >}}
inflation((33_225, 77_020), (2000, 2021)) -> 4.08
{{< /highlight >}}

One year of education at Stanford has increased from $32,471 in [2000](https://news.stanford.edu/pr/00/000216tuition.html)
to $73,333 in [2021](https://news.stanford.edu/2021/02/03/stanford-expands-financial-aid-keeps-2021-22-tuition-flat/)
for a 3.96% inflation rate.

{{< highlight text >}}
inflation((32_471, 73_333), (2000, 2021)) -> 3.96
{{< /highlight >}}

Even if we look at a large in-state university like Ohio State, we see one year
of in-state education has increased from $12,483 in [2000](https://www.asc.ohio-state.edu/wilkins.5/osu_and_ohio/statistics/statistics01.htm)
to $25,288 in [2021](http://undergrad.osu.edu/cost-and-aid/basic-costs) for a
3.4% inflation rate.
{{< highlight text >}}
inflation((12_483, 25_288), (2000, 2021)) -> 3.42
{{< /highlight >}}

At the top end of the education market we have again seen higher price increases
than 2.3%, probably around 4%. This was somewhat surprisingly low, in my
opinion, as a 20 year
[US Treasury Bond](https://www.treasury.gov/resource-center/data-chart-center/interest-rates/pages/TextView.aspx?data=yieldYear&year=2000)
yielded around 6% in 2000, and median wage growth was around 2.68% over roughly
the same period.

## Conclusion

From the price increases of goods that wealthier people compete for, we see
about double (in some places more than double) the officially reported rate of
inflation of the broadly applicable CPI. This data matches with the hypothesis
put forward by the Deficit Myth, namely that spending causes inflation, not
money supply.

I by no means think we should sympathize with the inflationary pains of the
elite, but I do fear it signals broader political ramifications. In particular,
as the price of admission to the upper class of society increases, more
potential [elites](https://en.wikipedia.org/wiki/Elite_overproduction) are
shut out of upward mobility. I fear we are already seeing this as college
degrees de-value, owning homes seem unattainable to many, and financial
independence often may seem unreachable.

The next time you hear someone complain about money creation and inflation,
consider instead where the money is going and ask yourself if that seems like
a societally beneficial use of that money.
