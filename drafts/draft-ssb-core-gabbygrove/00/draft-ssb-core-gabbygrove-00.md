---
coding: utf-8

# see https://raw.githubusercontent.com/cabo/kramdown-rfc2629/master/examples/draft-ietf-core-block-xx.mkd for more fields

title: GabbyGrove (CBOR-based Feed Format)
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
    ins: cryptix
    name: Henry Florenz Bubert
    org: SSBC
    email: cryptix@riseup.net

--- abstract

This document defines a new binary format for append-only feeds as used by Secure-Scuttlebutt.
That is, it defines the bytes that are used for computing the cryptographic signatures and hashes that make up a feed in this format.
It strives to do two things: Be easier to implement compared to the current scheme. Hence, it uses [CBOR](https://cbor.io) {{?RFC7049}} to encode the logical values that describe each entry.
Secondly, the feed entry only references content by hash to enable content deletion without breaking verification of the feed.

--- middle

# Gabby Grove

This is the revised version of [the ProtoChain proposal](ssb://%3ATKLKIHdM+beamr1dqoO2Jd6BC7oW5zj0ygLvmDsEc=.sha256).
The main difference to _ProtoChain_ is that _Gabby Grove_ uses CBOR instead of Protocol Buffers.

# Rationale

While this is would introduce new ways of doing things, like requiring CBOR for encoding and supporting multiple feed formats, it also makes concessions to how things are currently. In a sense this proposal should be seen as an overhaul of the current scheme, only adding off-chain capabilities. Let me elaborate on two of them which cater to this point specifically:

## Keeping the timestamp

In principle, the timestamp is an application concern. Some types of messages could omit the timestamp and it could be considered _cleaner_ to move them up into the content of messages which want to supply them. We recognize however that it would stir up problems for existing applications and this is something we are not interested in.

## Keeping the author field

A similar argument could be made for the author. In the current design the author never changes over the lifetime of a feed, so why have it on each and every entry of a feed? Especially if you replicate one feed at a time it seems wasteful, since the author is already known.

[Dominic Tarr](ssb://@EMovhfIrFk4NihAKnRNhrfRaqIhBv1Wj8pTxJNgvCCY=.ed25519) made a security argument [here](ssb://%1AsqTRxdVrbfypC69W7uWbMClQteNNnnl3ohzbpu3Xw=.sha256). It should always be known which key-pair created a signature and thus having it reduces ambiguity and possible backdoors.

## Only encoding the content

At first, this format would only encode the header fields of a message (subsequently called `event`) as CBOR, leaving the author of a feed to encode their content as they see fit.
An encoding enumeration field on the `event` sets one of a set of known values for arbitrary data (`0`), JSON (`1`) and CBOR (`2`).

Since we don't want to cause problems for applications, we suggest keeping the `content` portion in JSON {{?RFC8259}} for now.
This should allow for events to be mapped to full JSON objects which look just like regular, legacy messages so that they can be consumed by applications with minimal changes.
CBOR _should_ be good at converting it's values to JSON for integration and backwards compatibility to other parts of the SSB stack.

# Definitions for SSB

## Event

A single entry on an feed with this format is called an event (formerly also known as Message).
It contains a fixed number of fields:

* A cipherlink to the `previous` one, null only on the first entry.
* The ed25519 public key of the `author`, also encoded as a cipherlink.
* The `sequence` number of the entry as an unsigned integer. Increasing by 1 each entry, starting with 1.
* An signed integer describing a `timestamp`. UNIX epoch timestamp (number of seconds since 1970-01-01). Using signed integers to allow use for historic data.
* `content`: an array of three fields:
  * `hash` as a cipherlink
  * `size` as a uint16, increasing the maximum content size to 64k.
  * `encoding` enumeration of three possible values.

## Transfer

The next needed structure is `transfer`. It consists of three byte arrays:

* The encoded bytes of an `event`, here called `eventData`.
* `signature`: 64 bytes, to be verified against the `author`s public key from the event.
* the optional `content`: a maximum of 64k bytes.

To validate the `transfer`, the receiver takes the byte strings `eventData` and `signature` and passes them to the cryptographic function that does the validation.
The only supported functions of this format is, edwards25519 as defined in {{?RFC8032}}, also known as Ed25519 from the [Networking and Cryptography library (NaCL)](https://nacl.cr.yp.to/).

If `content` is present, hashing it needs to compute the same hash as stated by the `content.hash` field on the event.
To omit the `content`, it needs to be set to `null` (primitive 22 or `0xf6` in CBOR), so that the array the field is contained in has the same size in both cases.

The hash of a signed event (and the `previous` field of the next event) is the SHA256 of `eventData` and `signature` bytes concatenated.

## Cipherlinks

The hashes and public key references are not base64 encoded readable ASCII text strings but are binary encoded.

In this first version we don't plan to support many formats, which is why we don't use something like [IPFS Multihash](https://github.com/multiformats/multihash), which supports every hash function under the sun.

Currently there are these different reference types:

* `0x01`: references to gabby grove formatted feeds (ED25519 Public Key, 32bytes of data)
* `0x02`: gabby grove signed event hashes (such as `previous`), using SHA256 (32bytes of data)
* `0x03`: `content.hash` also using SHA256 (32bytes of data)
* `0x04`: "SSB v1", legacy / old feed reference (ED25519 Public Key, 32bytes of data)
* `0x05`: SHA256 message hashes as used by legacy ssb
* `0x06`: SHA256 binary blob hashes as used by legacy ssb

Only 1, 2 and 3 are used on gabby grove event fields.
4 to 6 are intended to encode cipherlinks in CBOR encoded content when referencing feeds in the legacy format.
I'm relatively certain and hopeful this will be revised and extended but it feels like a good starting point.
They all should be convertible to and from the base64 encoded ASCII references we currently use in JSON.
We add one byte as prefix to those bytes, making all references 33bytes long, for now.

### Cross references

Up until now SSB only had to deal with `.ed25519` and `.sha256` to identify a whole feed and individual entries respectively. Although I'd like to avoid a registry of known suffixes, my [initial thoughts](ssb://%t5mSAGJZEWus/HO+180M9SSsn5irHg/LVQTVqODFS9I=.sha256) on how to do _decent_ subjective name-spaces for identifier and networks are still very vague. For the meantime, this document proposes the `.ggfeed-v1` suffix as a default feed reference and `.ggmsg-v1` for messages.

The author also briefly looked into [IPFS Content Identifiers (CID)s](https://docs.ipfs.io/guides/concepts/cid/) and [Decentralized Identifiers (DIDs)](https://w3c-ccg.github.io/did-spec/) but discarded them since it leaves the scope of this specification. It's only important that we clearly discern and define type and data of these identifiers so that we can convert to and from them down the road.

## Signing capability

The existing legacy format has an [optional HMAC signing capability](https://github.com/ssbc/ssb-keys#signobjkeys-hmac_key-obj). When enabled, a hashed message authentication code ([HMAC](https://en.wikipedia.org/wiki/HMAC)) is signed instead of the the message (the `event` bytes inside a `transfer` in our case). For this a (usually secret among the users of the network) key is needed. Without this key for the HMAC function, the receiver can't validate the signature. Because messages are still communicated as clear text, this mode doesn't add any confidentiality, which the needed key might imply. Therefore this mode is primarily usefull for splitting networks of feeds, like for testing purposes.

 Currently this format uses exactly the same scheme as the legacy format for portability reasons. The used HMAC function is NaCLs `crypto_auth`, defined [here](https://nacl.cr.yp.to/auth.html).

# CBOR

## Basics

If you never worked with CBOR, I suggest checking out it's [website](https://cbor.io) and the definitions in {{?RFC7049}}). Similar to JSON it is a _self describing_ format. Which means, bytes of it can be translated to logical, typed values without the need for a schema definition.

The [cbor-diag utilities](https://github.com/cabo/cbor-diag) (or the [the playground at cbor.me](https://cbor.me) with the same features) can help a lot to see how it works. With it, we can translate between encoded bytes and the diagnostic notation (defined in section 6 of CBORs RFC).
Roughly speaking we can use JSON-like literals as diagnostic input for `diag2pretty.rb` (or the left side of the playground):

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

The comments (everything right of the `#` character) tell us the types and values again. The first line says "0xA4 means the following is a map with 4 entries".
Maps are key-value pairs, so we get three pairs of first the name (or key) of the pair and then the value.
Next to signed and unsigned number types it also has predefined primitives for `true`, `false` and `null`.
Notice that the keys are also typed (_text of len N_).

Let's compare the previous example to an array of the same values, without the keys:

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

This is also why the previous attempt to define a new feed format used Protocol Buffers. A self-describing format isn't inherently useful since the fields of an `event` don't change.
As shown above, the size overhead of encoding structures as maps can be mitigated by encoding them as arrays instead.

## Canonical encoding

We _could_ define the first field of a `transfer` as an `event` itself instead of opaque byte strings but canonical encoding on this level of the protocol is seen as optional.
Meaning: if the implementation can re-produce the same `eventData` from an stored `Event`, go ahead.
Butt be wary, diverging one bit from the original `eventData` means that signature verification and hash comparison will fail.
Over all this seems like an potentially instable and divergent way of exchanging feeds, producing incorrect references as heads of a feed if implementations incorrectly consume them.

However, as an experiment, implementers are advised to use the canonical CBOR suggestions defined in [Section 3.9 of CBORs RFC](https://tools.ietf.org/html/rfc7049#section-3.9).
Since we only use bytes, integers and tags for our structures we can ignore the suggestions for map keys and floats.

Potentially, a canonical encoding would allow for skipping certain fields on the transport layer.
`author`, `sequence` and even `previous` could be filled in by the receiver themselves to produce the full `eventData`.

It would also free implementors on the question of how to store events.
It's unclear to the author if this amounts to a worth-while endeavor compared to just storing the bytes of the `transfer`.

## Extensibility

CBOR allows for augmenting the types of it's values with an additional numeric tag. These are hints for the de- and encoders to treat some type of values differently. See [Section 2.4 of CBORs RFC](https://tools.ietf.org/html/rfc7049#section-2.4) for more. [A list of defined CBOR Tags](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml#tags) is maintained by the IANA.

This kind of extensibility through type tags seems useful for SSB, especially if we ever change away from JSON as the content encoding.
With it, we can explicitly mark cipherlinks as such, for instance. I took the liberty to take one of the _first come first served_ numbers for the cipherlinks above, it's 1050.

[Section 2.4.4.1 of the CBOR RFC](https://tools.ietf.org/html/rfc7049#section-2.4.4.1) also defines tag number 24 to delay decoding of embedded cbor values (like the `event` in the `transfer`). Depending on how flexible the used CBOR libarary is, this might help input validation but since each field of an `event` has to be checked in context of the feed for append validation, this feature was not applied to this version of the format.

Another option would be to explicitly tag the whole `transfer`, which is otherwise _just_ an array with three opaque byte string entries, and state how the signature was computed by the author's key-pair referenced inside the `event`. And also define the role of the actual `content` bytes in relation to the `content` field in the `event`.

## Examples

As a concrete example of all the above combined, here are some actual structures of this format encoded as CBOR.

### Key Pair

of the ED25519 key-pair that was seeded with `dead` repeated 8 times, which is a poor choice for an actual key-pair but gives us deterministic test data. I tested sodium-native on javascript and ed25519 for Go by agl and x/crypto and they all gave me these public key bytes as a hexdump:

~~~~~~~~~~~
00000000  AED3DAB65CE9E0D6C50D46FCEFFB5522  |....\.....F...U"|
00000010  96ED21B6E0B537A6A0184575CE8F5CBD  |..!...7...Eu..\.|
~~~~~~~~~~~

### Event

These are the first two messages of a feed authored by the keypair above. 

~~~~~~~~~~~
 1:85                                      # array(5)
 2:   F6                                   # primitive(22)
 3:   D9 041A                              # tag(1050)
 4:      58 21                             # bytes(33)
 5:         01
 6:         AED3DAB65CE9E0D6C50D46FCEFFB5522
 7:         96ED21B6E0B537A6A0184575CE8F5CBD
 8:   01                                   # unsigned(1)
 9:   24                                   # negative(4)
10:   83                                   # array(3)
11:      D9 041A                           # tag(1050)
12:         58 21                          # bytes(33)
13:            03
14:            A7AC59B52AFF894BA89508B35F445AE9
15:            0628F6D5F358157E4F45F39B5B3BE96B
16:      09                                # unsigned(9)
17:      00                                # unsigned(0)
~~~~~~~~~~~

Let's discuss line by line what this means:

1. The first line, `85 # array(5)`, tells us `0x85` is the first byte and means "this is an array with five elements". What follows are the five fields that were defined in Section 3.1 of this document: `previous`, `author`, `sequence`, `timestamp` and `content`.
2. `0xF6` is the first value of this array. The `primitive(22)` is a special CBOR value, signaling `null`. So the `previous` hash is `null`, which is fine for the first message.
3. The three bytes (`0xD904A1`) mean `tag(1050)`. This is CBORs optional tagging feature, introduced in Section 4.3 of this document. It tell's the decoder "the following values is tagged with the number 1050". This value describes cipherlinks, defined in Section 3.3 of this document.
4. The following line with the two bytes `0x5821` just tells the decoder "the following are 33 bytes" and can be taking literally in value without any modification.
5. These are the 33 bytes of a cipherlink. Since this cipherlink starts with a `0x01`, it is the public key of an author.
6. This is the first half of the authors public key, broken in two lines of 16bytes each. (This is only to conform with the 72 character limit of text only output of this document.)
7. This is the 2nd half of the authors public key.
8. The next line is the third element of the array: the `sequence` number encoded as an unsigned integer, as the comment tells us.
9. The fourth element is the `timestamp` encoded as an signed integer. As a starting timestamp I picked 1969-12-31 23:59:55, which translates to -5 seconds as a UNIX epoch timestamp.
10. The fifth element is the `content` object, which itself is encoded as an array of 3 items (`hash`, `size` and `encoding`)
11. First, we have a cipherlink for the `hash`.
13. It starts with 03 which means, it's a content hash. (See Section 3.3)
14. The following two lines are the hash function output. How to compute these will be shown in the next section.
16. This is the content's `size`, in bytes also as an unsigned integer. Meaning, this content is 9 bytes long.
17. The number 0 means the content was encoded as `binary` (See Section 2.3).

Here is the next message:

~~~~~~~~~~~
85                                      # array(5)
   D9 041A                              # tag(1050)
      58 21                             # bytes(33)
         02
         CCD8FD8392C1B9D1E3026DEA42BEC93E
         04B6F8ECEB9AF2D591489EB8B831C5E1
   D9 041A                              # tag(1050)
      58 21                             # bytes(33)
         01
         AED3DAB65CE9E0D6C50D46FCEFFB5522
         96ED21B6E0B537A6A0184575CE8F5CBD
   02                                   # unsigned(2)
   23                                   # negative(3)
   83                                   # array(3)
      D9 041A                           # tag(1050)
         58 21                          # bytes(33)
            03
            95CCA4FA7B24ABC6049683E716292B00
            C49509BE147AA024C06286BD9B7DBDA8
      16                                # unsigned(22)
      01                                # unsigned(1)

~~~~~~~~~~~

If you compare this to the above you should see some similarities. Instead of `0xf6` as the first element as the array we now have `0xD9041A5821`. We have seen this sequence of bytes twice above already: It's a cipherlink with 33 bytes of data. Instead of starting with byte `0x01` or `0x03`, this starts with `0x02` which means, it's a hash of a signed event.

The content type is `0x01` instead and the timestamp is advanced by 1 as well as the `sequence`.

### Transfer

Here is the transfer object for the first event:

~~~~~~~~~~~
83                                      # array(3)
   58 53                                # bytes(83)
      85F6D9041A582101AED3DAB65CE9E0D6C50D46FCEFFB552296ED21B6E
      0B537A6A0184575CE8F5CBD012483D9041A582103A7AC59B52AFF894B
      A89508B35F445AE90628F6D5F358157E4F45F39B5B3BE96B0900
   58 40                                # bytes(64)
      8A3739FDB99D91E28552E9A2E22650C14A8CDBFE607CDCA5767569DB2
      B1E24CAA3C31D65964143DC752E568B05C99E0E97C198885BFB8F3549
      B9C6CCBC991205
   49                                   # bytes(9)
      FF7330316D4279747A                # "\xFFs01mBytz"
~~~~~~~~~~~

Similar to the above, we have an array with 3 elements, each in turn being a byte string of varying size.
The first one is the `eventData`, the second one is the `signature` and the last one is the `content` data.
(The long data chunks were broken into multiple lines for readability, consult the code repositories for actual test vectors.)


Here is the transfer object for the second event:

~~~~~~~~~~~
83                                      # array(3)
   58 78                                # bytes(120)
      85D9041A582102CCD8FD8392C1B9D1E3026DEA42BEC93E04B6F8ECEB9
      AF2D591489EB8B831C5E1D9041A582101AED3DAB65CE9E0D6C50D46FC
      EFFB552296ED21B6E0B537A6A0184575CE8F5CBD022383D9041A58210
      395CCA4FA7B24ABC6049683E716292B00C49509BE147AA024C06286BD
      9B7DBDA81601
   58 40                                # bytes(64)
      3A7F29F7395CC454C3904DE2236EEF2C0147496B77C556ADE1A08BF57
      D3E70D2A43A4C723AEB5366D4F073CEEB8B2677E03EC62E49D1647C67
      0D95CC77F9DB07
   56                                   # bytes(22)
      7B2269223A312C2274797065223A2274657374227D0A
~~~~~~~~~~~

# Code and roll out

The current work-in-progress code, licensed under MIT is available for [Go](http://git.mindeco.de/ssb/gabbygrove) and [javascript](https://github.com/cryptix/js-gabbygrove) to show interoperability and that signature verification and content hashing works as expected. [go-ssb](https://github.com/cryptoscope/ssb) also has integrated in it's native sbot, testing against [a demo plugin](https://github.com/cryptoscope/ssb/blob/f6960c92e333b219709755a04b03c61500685adb/tests/ggdemo/index.js) for [ssb-server](https://github.com/ssbc/ssb-server). 

One open question would be how to get this into EBT while also supporting the classical/legacy way of encoding feeds.
For replication of single feeds we can use the established stream command `createHistoryStream` which can pick the correct transfer encoding based on the passed feed reference.

# Remarks

## Alternative Encodings

Having worked with CBOR and Protocol Buffers, CBOR feels like the better tool for the job.
Especially since it could also be used for encoding of the `content` itself where Protocol Buffers would require shared schemas for all types.

Possible alternatives:

* Cap’n Proto: seemed like a bit bleeding edge.
* MessgePack: my reading of Appendix E, it's quite stable but extension mechanism is in a dead end.
* Protocol Buffers: pretty steep dependency, generated code, schema only interesting for event entries, not higher levels of the stack

[Appendix E of CBORs RFC](https://tools.ietf.org/html/rfc7049#appendix-E) also shows how CBOR compares to ASN.1/DER/BER, BSON and UBJSON.

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

as [@cft](ssb://@AiBJDta+4boyh2USNGwIagH/wKjeruTcDX2Aj1r/haM=.ed25519) mentioned in [his first comment](ssb://%pXxsQeOENZ/M9vYAlf1+99tqvTY8WtVwSkOEfQddV2o=.sha256), _Message_ and _Meta_ were not easy to speak and reason about. "What includes what?" wasn't easy enough to answer. The _Message_ was conceptually redundant as well since it's fields can be in the `transfer` structure as well to achieve the same results. Which is why there is just a single concept for this called `event`.

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

This is why the `transfer` structure definition has a dedicated field for `content` which can be set to `null` to indicate unavailability.

--- back



