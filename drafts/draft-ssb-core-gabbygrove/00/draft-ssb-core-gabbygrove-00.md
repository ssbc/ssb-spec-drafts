---
coding: utf-8

# see https://raw.githubusercontent.com/cabo/kramdown-rfc2629/master/examples/draft-ietf-core-block-xx.mkd for more fields

title: GabbyGrove (CBOR based Feed Format)
abbrev: DRAFT GabbyGrove
docname: draft-ssb-core-gabbygrove-00
category: info
submissionType: independent
ipr: none
wg: Secure Scuttlebutt Working Group

stand_alone: yes
pi: [toc, sortrefs, symrefs, comments]

author:
  -
    ins: H. Bubert
    name: Henry Florenz Bubert
    org: SSBC
    email: cryptix@riseup.net

--- abstract

This document defines a new binary format for append-only feeds as used by Secure-Scuttlebutt.
That is, it defines the bytes that are used for computing the cryptographic signatures and hashes that make up a feed in this format.
It strives to do two things: be easier to implement then the current scheme. Hence, it uses [CBOR](https://cbor.io) {{?RFC7049}} to encode the logical values that describe each entry.
Secondly, it only reference content by hash on the feed entry to enable content deletion without breaking verification of the feed.

--- middle

# Gabby Grove

This is the revised version of [the ProtoChain proposal](ssb://%3ATKLKIHdM+beamr1dqoO2Jd6BC7oW5zj0ygLvmDsEc=.sha256).
The main difference to _ProtoChain_ is that _Gabby Grove_ uses CBOR instead of Protocol Buffers.

# Rationale

While this is would introduce radical new ways of doing things, like requiring CBOR for encoding and supporting multiple feed formats, it also makes concessions to how things are currently. In a sense this proposal should be seen as an overhaul of the current scheme, only adding off-chain capabilities. Let me elaborate on two of them which cater to this point specifically:

## Keeping the timestamp

In principle, the timestamp is an application concern. Some types of messages could omit the timestamp and it could be considered _cleaner_ to move them up into the content of the types that want/need them. We recognize however that it would stir up problems for existing applications and this is something we are not interested in.

## Keeping the author field

A similar argument could be made for the author. In the current design the author never changes over the lifetime of a feed, so why have it on each and every entry of a feed? Especially if you replicate one feed at a time it seems wasteful, since the author is already known.

Dominic made a pretty good security argument [here](ssb://%1AsqTRxdVrbfypC69W7uWbMClQteNNnnl3ohzbpu3Xw=.sha256). It should always be known which key-pair created a signature and thus having it reduces ambiguity and possible backdoors.

## Only encoding the content

This format would only encode the metadata as CBOR, leaving the _user_ to encode their content as they see fit.
Since we don't want to cause problems for applications, we suggest keeping the `content` portion in JSON.
This should allow for events to be mapped full JSON objects which look just like regular, legacy messages so that they can be consumed by applications without any change.

For upgrades and more advance uses we added an `encoding enum` that defines known values for arbitrary data (`0`), JSON (`1`) and CBOR (`2`).
CBOR _should_ be good at converting it's values to JSON for integration and backwards compatibility to other parts of the SSB stack.

# Definitions for SSB

## Event

A single entry on an feed with this format is called an event (formerly also known as Message).
It contains a fixed number of fields:

* A cipherlink to the `previous` one, null only on the first entry.
* The ed25519 public key of the `author`, also encoded as a cipherlink.
* The `sequence` number of the entry as an unsigned integer. Increasing by 1 each entry, starting with 1.
* An unsigned integer describing a `timestamp`. UNIX epoch timestamp (number of seconds since 1970-01-01).
* `content`: an array of three fields:
  * `hash` as a cipherlink
  * `size` as a uint16, increasing the maximum content size to 64k.
  * `encoding` enumeration of three possible values.

## Transfer

The next needed structure is `transfer`. It consists of three byte arrays:

* The encoded bytes of an _Event_, here called `eventData`.
* `signature`: 64 bytes, to be verified against the `author`s public key from the event.
* the optional `content`: a maximum of 64k bytes.

To validate an incoming signed event, the receiver just takes the `eventData` and the `signature` and passes them to the cryptographic function that does the validation.
In this case, edwards25519 as defined in {{?RFC8032}}, also known as Ed25519 from the [Networking and Cryptography library (NaCL)](https://nacl.cr.yp.to/).

If present, hashing the `content` needs to compute the same hash as stated by the `content.hash` field on the event.
If it should be omitted, it needs to be set to null (primitive 22 or `0xf6` in CBOR) to keep the array it's contained in of length three.

The Hash of a signed event (and the `previous` field of the next event) is the SHA256 of `eventData` and `signature` bytes concatenated.

## Cipherlinks

The hashes and public key references are not base64 encoded readable ASCII strings but are binary encoded.

In this first version we don't plan to support many formats, which is why I decided against something like IPFS Multihash, which supports every hash function under the sun.

Currently there are these different reference types:

* `0x01`: references to gabby grove formatted feeds (ED25519 Public Key, 32bytes of data)
* `0x02`: gabby grove signed event hashes (such as `previous`), using SHA256 (32bytes of data)
* `0x03`: `content.hash` also using SHA256 (32bytes of data)
* `0x04`: "SSB v1", legacy / old feed reference (ED25519 Public Key, 32bytes of data)
* `0x05`: SHA256 message hashes as used by legacy ssb
* `0x06`: SHA256 binary blob hashes as used by legacy ssb

Only 1 to 3 are used on gabby grove event fields.
4 to 6 are intended to encode cipherlinks in CBOR encoded content when referencing feeds in the legacy format.
I'm relatively certain and hopeful this will be revised and extended but it feels like a good starting point.
They all should be convertible to and from the base64 encoded ASCII references we currently use in JSON.

We add one byte as prefix to those bytes, making all references 33bytes long, for now.

### Cross references

Up until now SSB only had to deal with `.ed25519` and `.sha256` to identify a whole feed and individual messages respectively. Although I'd like to avoid a registry of known suffixes, my [initial thoughts](ssb://%t5mSAGJZEWus/HO+180M9SSsn5irHg/LVQTVqODFS9I=.sha256) on how to do _decent_ subjective name-spaces for identifier and networks are still very vague. For the meantime, I propose the `.ggfeed-v1` suffix as a default feed reference and `.ggmsg-v1` for messages.

I also briefly looked into [IPFS Content Identifiers (CID)s](https://docs.ipfs.io/guides/concepts/cid/) and [Decentralized Identifiers (DIDs)](https://w3c-ccg.github.io/did-spec/) but discarded them since it leaves the scope of this specification. It's only important that we clearly discern and define type and data of these identifiers so that we can convert to and from them down the road.

# CBOR

## Basics

If you never worked with CBOR, I suggest checking out it's [website](https://cbor.io) and the definitions in {{?RFC7049}}). Similar to JSON it is a _self describing_ format. Which means, bytes of it can be translated to logical, typed values without the need for a schema definition.

What helped me a lot as well to understand it better were the [cbor-diag utilities](https://github.com/cabo/cbor-diag) (or the [the playground at cbor.me](https://cbor.me) with the same features).
With it, you can translate between bytes and the diagnostic notation (defined in section 6 of it's RFC).
Roughly speaking you can use JSON like literals as diagnostic input for `diag2pretty.rb` (or the left side of the playground):

~~~~~~~~~~~
{
  "type": "test",
  "count": 123,
  "true": false,
  "link": null
}
~~~~~~~~~~~

which outputs a hexadecimal, indented and commented representation with type annotations:

~~~~~~~~~~~
A4               # map(4)
   64            # text(4)
      74797065   # "type"
   64            # text(4)
      74657374   # "test"
   65            # text(5)
      636F756E74 # "count"
   18 7B         # unsigned(123)
   64            # text(4)
      74727565   # "true"
   F4            # primitive(20)
   64            # text(4)
      6C696E6B   # "link"
   F6            # primitive(22)
~~~~~~~~~~~

The comments tell us the types and values again. The first line says _A4 means the following is a map with 3 entries_.
Maps are key-value pairs, so we get three pairs of first the name (or key) of the pair and then the value.
Next to signed and unsigned number types it also has predefined primitives for `true`, `false` and `null`.
Notice that the keys are also typed (_text of len N_).

Let's compare it to an array of the same values, without the keys:

~~~~~~~~~~~
["test", 123, false, null]
~~~~~~~~~~~

results in

~~~~~~~~~~~
84             # array(4)
   64          # text(4)
      74657374 # "test"
   18 7B       # unsigned(123)
   F4          # primitive(20)
   F6          # primitive(22)
~~~~~~~~~~~

This results in 10 encoded bytes. The map example needs 31, in comparison.

Encoding the same well-defined objects as maps over and over again comes with a lot of overhead and redundant description of the field names.

This was my main concern in comparison to Protocol Buffers. A self-describing format isn't that useful here since the fields don't change.
As shown above, the size overhead of encoding structures as maps can be mitigated by encoding them as arrays instead.

## Canonical encoding

We _could_ define the first field of a `transfer` as an _event_ itself instead of opaque bytes but I want to make canonical encoding on this level of the protocol optional.
Meaning: if you can re-produce the same `eventData` from an de-coded stored `Event`, go ahead.
Butt, diverging one bit from the original `eventData` means that signature verification and hash comparison will fail.
Over all this seems like an potentially instable and divergent way of exchanging feeds, producing incorrect references as heads of a feed if implementations incorrectly consume them.

However, as an experiment, implementers are advised to use the canonical CBOR suggestions defined in [Section 3.9](https://tools.ietf.org/html/rfc7049#section-3.9).
Since we only use bytes, integers and tags for our structures we can ignore the suggestions for map keys and floats.

Potentially, a canonical encoding would allow for skipping certain fields on the transport layer.
`author`, `sequence` and even `previous` could be filled in by the receiver themselves to produce the full `eventData`.

It would also free implementors on the question of how to store events.
It's unclear to the author if this amounts to a worth-while endeavor compared to just storing the bytes of the `transfer`.

## Extensibility

CBOR allows for augmenting the types of it's values with an additional numeric tag. These are hints for the de- and encoders to treat some type of values differently.

This kind of extensibility through type tags seems useful for SSB, especially if we ever change away from JSON as the content encoding.
With it, we can explicitly mark cipherlinks as such, for instance.

Another option would be to explicitly tag the whole `transfer`, which is otherwise _just_ an array with three entries, and state how the signature was computed by the author's key-pair referenced inside the `event`.

See [Section 2.4 of CBORs RFC](https://tools.ietf.org/html/rfc7049#section-2.4) for more.

# Code and roll out

the current work-in-progress repository can be found [here](http://cryptbox.mindeco.de/ssb/gabbygrove).

It experiments with Go and javascript interoperability and shows that signature verification and content hashing works as expected.

Integration into go-ssb or the javascript stack is pending on review comments.

One open question would be how to get this into EBT while also supporting the classical/legacy way of encoding feeds.
For replication of single feeds I'd suggest using the established stream command `createHistoryStream` which can pick the correct transfer encoding based on the passed feed reference.

# Remarks

## Alternative Encodings

Having worked with CBOR and Protocol Buffers, CBOR feels like the better tool for the job.
Especially since it could also be used for encoding of the `content` itself where Protocol Buffers would require shared schemas for all types.

Possible alternatives:

* Cap’n Proto: seemed like a bit bleeding edge.
* MessgePack: my reading of Appendix E, it's quite stable but extension mechanism is in a dead end.
* Protocol Buffers: pretty steep dependency, generated code, schema only interesting for event entries, not higher levels of the stack

[Appendix E. (Comparison of Other Binary Formats to CBOR's Design Objectives)](https://tools.ietf.org/html/rfc7049#appendix-E) also shows how CBOR compares to ASN.1/DER/BER, BSON and UBJSON.

## Deletion requests

I believe we should leave this out of the spec and just give way for clients to drop content as wanted. Tuning replication rules with signed deletions or what ever can be done orthogonal if the chain/feed format allows validation with missing content.

## Size benefits

This cuts down the amount of transmitted bytes considerably. As an example, a _old_ contact message weighs in at roughly 434 bytes (JSON without whitespace, sequence in the hundreds range). Encoding a contact message with this, results in 289 bytes, 119 of which are still JSON. This overhead is small for longer posts but still wanted to mention it. The main driver of this reduction is the binary encoding of the references and being able to omit the field names. Converting content to a binary encoding would reduce it further but as stated above would require strict schemas for every type.

## How long lived this will be?

I _think_ this is a solid format but wouldn't mind to be superseded by something else once it surfaces. As a migration path, I'd suggest we double down on `sameAs`.
The _simplest_  case of it would be terminating one feed and starting a new one, while logically appending one to the other for higher levels of the protocol stack.
The implications for indexing things like the friend graph and how to end feeds in the old format show that this needs to be covered in a separate spec.

# Addressed comments from ProtoChain

Apart from choosing another library for marshalling bytes this proposal changed the name of a couple of things.

## Event

as [@cft](@AiBJDta+4boyh2USNGwIagH/wKjeruTcDX2Aj1r/haM=.ed25519) mentioned in [his first comment](ssb://%pXxsQeOENZ/M9vYAlf1+99tqvTY8WtVwSkOEfQddV2o=.sha256), _Message_ and _Meta_ were not easy to speak and reason about.
"What includes what?" wasn't easy enough to answer. The _Message_ was conceptually redundant as well since it's fields can be in the _Transfer_ structure as well to achieve the same results.
Which is why there is just a single concept for this called _Event_.

## "Content Type"

Was not only wrong because it is already a named concept on the higher level (type:contact, type:post, etc.) but also because it is not specific enough.
This field deals with the _encoding_ of the content and thus should be named as such.


# Comments addressed since the first "off-chain content" proposal

Remarks this proposal addresses over [the first Off-chain content proposal](ssb://%LrMcs9tqgOMLPGv6mN5Z7YYxRQ8qn0JRhVi++OyOvQo=.sha256):

## incrementing on a broken format

The main idea of the first proposal was to add off-chain content without overhauling the verification scheme.
We got numerous comments on this, the gist being that we tried to hard, improving something that should be deprecated altogether.

Therefore we chose a clean slate approach with a new encoding scheme. This comes with the downside of requiring multiple supported _feed formats_ in the stack. Personally I think this is good though as it will pave the way for other formats, like bamboo, as well.

## The use of MUXRPC specific features for transmission/replication

The idea to transmit content and metadata as two [MUXRPC](https://github.com/ssbc/muxrpc) frames was my idea. It seems sensible/practical because it fitted into the existing stack but I see now that it tried to much to fit into the existing way and hid a dependency along the way.

This is why we have the `transfer` message definition which has two fields. One for the message, which should be required and one field for the content, which can be omitted.


--- back

## CDDL

As a suggestion for possible future work, here is the format specification in _Concise data definition language (CDDL)_ {{?RFC8610}} which describes the `event`, `content` and `transfer` objects.

The language allows for more detailed description and definition of valid objects and seems like an interesting tool to define supported types and messages for higher levels of SSB as well.



<!-- It would be handy to have a macro to embed this from a separate file, I think.
Needs to be colwrapped to suppress warnings and overflowing the html format -->

~~~~~~~~~~~
; this document uses the Concise data definition language (CDDL)
; https://tools.ietf.org/html/rfc8610

; it describes the data structures that are used
; by the gabby grove feed format for secure-scuttlebutt (ssb)
; feeds are single author/writer and they don't fork.
; the use of hash functions to address previous entries,
; turns them into an append-only linked-list that can't be altered.

; a single entry on a feed (formerly also known as message)
event = [
  previous: cipherlink,
  author: cipherlink,
  sequence: uint,
  timestamp: uint,
  content,
]

content = [
    hash: cipherlink,
    size: uint16,
    encoding: contentEncoding,
]

; 33 bytes, tagged with major type 6, number 1050
; this is used to indicate the cryptographic references
cipherlink = #6.1050(bytes .size 33)
; See section 2.4 and iana registry for already defined tags
; https://tools.ietf.org/html/rfc7049#section-2.4
; https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml#tags

; possible values for content encoding are 0, 1 and 2
; 0 means _arbitrary bytes_ (like an private message, image or tar)
; 1 means json
; 2 means cbor
contentEncoding = 0..2

; 16-bit unsigned int, equivalent to 0..65536
uint16 = uint .size 2 

; transfer describes a signed event with the actual content
transfer = [
  eventData: bytes,         ; event encoded as bytes
  signature: signature,     ; the signature 
  ? contentData: bytes,     ; the actual bytes of the content
]

; we _could_ define the first field of a transfer as an _event_
; but I want to make canonical encoding on this level
; only optional but not a requirement as output

; v1 only support Ed25519 curves.
; These signatures are always 64 bytes long.
signature = bytes .size 64
~~~~~~~~~~~


