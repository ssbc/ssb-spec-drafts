---
coding: utf-8

# see https://raw.githubusercontent.com/cabo/kramdown-rfc2629/master/examples/draft-ietf-core-block-xx.mkd for more fields

title: SAME-AS - Creating the Illusion of Multi-Feed Identities
abbrev: SAME-AS
docname: draft-ssb-app-same-as-00
category: info
submissionType: independent
ipr: none
wg: Secure Scuttlebutt Working Group

stand_alone: yes
pi: [toc, sortrefs, symrefs, comments]

author:
  -
    ins: M. McKegg
    name: Matt McKegg
    org: New Zealand
    email: ssb(@FbGoHeEcePDG3Evemrc+hm+S77cXKf8BRQgkYinJggg=.ed25519)

--- abstract

This is an unredacted copy of https://github.com/ssbc/ssb-same-as, taken
July 4, 2019. The last commit of said repo is from Dec 13, 2017.

SAME-AS is a scuttlebot plugin that provides a stream of which feeds
are (and are not) the same as other feeds.


--- middle

# ssb-same-as

A [scuttlebot](https://github.com/ssbc/scuttlebot) plugin that provides a stream of which feeds are (and are not) the same as other feeds.

The basis for creating the illusion of multi-feed identities in SSB!

Based on [ssb-friends](https://github.com/ssbc/ssb-friends) and [graphreduce](https://github.com/ssbc/graphreduce)

## TODO

- need to test merge blocking and unmerging
- hook into replication to ensure the correct feeds are replicated
- improve realtime performance (avoid re-traversing entire graph)

## Spec

### Assert that you are the same as another feed

~~~~~~~~~~~
{
  type: 'contact',
  contact: TARGET_FEED_ID,
  following: true, // for backwards compat reasons
  sameAs: true
}
~~~~~~~~~~~

### Block a sameAs

~~~~~~~~~~~
{
  type: 'contact',
  contact: TARGET_FEED_ID,
  following: true, // for backwards compat reasons
  sameAs: false
}
~~~~~~~~~~~


### Agree with another feed's assertion

~~~~~~~~~~~
{
  type: 'contact',
  contact: TARGET_FEED_ID,
  following: true, // for backwards compat reasons
  sameAs: {
    SOURCE_FEED_ID: true // or `false` to remove an agreement
  }
}
~~~~~~~~~~~


### Logic behind sameAs resolution

- If one side explicitly disagrees (with a `sameAs: false`), the identities will **NEVER be merged**.
- If both sides agree, the identity will **ALWAYS be merged**.
- If one side agrees (and the other side has not shared an opinion), and you agree, then the identities will be **merged**.
- In all other cases, the identities **will not be merged**.

This module uses graphreduce to walk the `sameAs` links, so this means that any topology of links will be resolved.

## Exposed API (as sbot plugin)

### sbot.sameAs.stream({live: false, sync: true, old: true}) source

Gets a list of all of the resolved and verified `sameAs` links between feeds.

~~~~~~~~~~~
{from: 'a', to: 'b', value: true}
{from: 'a', to: 'c', value: true}
{from: 'a', to: 'd', value: true}
{from: 'b', to: 'a', value: true}
{from: 'b', to: 'c', value: true}
{from: 'b', to: 'd', value: true}
...
~~~~~~~~~~~


### sbot.sameAs.get({id}, cb) async

Gets a list of all of the verified `sameAs` links for a given feed.

~~~~~~~~~~~
{
  'b': true,
  'c': true,
  'd': true
}
~~~~~~~~~~~


## License

MIT
