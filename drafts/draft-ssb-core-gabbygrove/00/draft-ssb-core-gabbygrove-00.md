---
coding: utf-8

# see https://raw.githubusercontent.com/cabo/kramdown-rfc2629/master/examples/draft-ietf-core-block-xx.mkd for more fields

title: GabbyGrove (CBOR based Feed Format)
abbrev: DRAFT GabbyGrove
docname: draft-ssb-core-gabbygrove-00
category: info
submissionType: independent
ipr: trust200902
wg: Secure Scuttlebutt Working Group

stand_alone: yes
pi: [toc, sortrefs, symrefs, comments]

author:
  -
    ins: H. Bubert
    name: Henry Florenz Bubert
    org: SSBC
    email: ssb(my pubkey)

--- abstract

This document defines a new binary format for SSBs append-only feeds.
It strives to 

It uses CBOR to encode the logical values that describe each entry

--- middle

# Gabby Grove

This is the revised version of ssb(%3ATKLKIHdM+beamr1dqoO2Jd6BC7oW5zj0ygLvmDsEc=.sha256). The main difference to _ProtoChain_ is that _Gabby Grove_ uses CBOR instead of ProtoBuf.

It's extensability through type tags seems usefull, especially down the line _if_ we ever change away from JSON as the content encoding. With it, we can explicitly mark cipherlinks as such.

My first concern 
The overhead of it's self-describing encoding of _structs as maps_ can be overcome by encoding them as arrays.

# old proposal

alternative approaches, essentially coming up with a new verification scheme based on a binary protocol.


1. Easy to implement (hence the use of [CBOR](https://cbor.io) {{?RFC7049}})
2. Content is only referenced by hash on the immutable data structure (hence enabling omitting and dropping of content locally) 

I propose the `.ggfeed-v1` suffix as a default feed reference.

Further comments this proposal addresses:

## incrementing on a broken format

The main idea of the first proposal was to add offchain-content without overhauling the verification scheme.
We got numerous comments on this, the gist being that we tried to hard, improving something that should be deprecated altogether.

Therefore we chose a clean slate approach with a new encoding scheme. This comes with the downside of requiring multiple supported _feed formats_ in the stack. Personally I think this is good though as it will pave the way for other formats, like bamboo, as well.

## The use of muxprc specific features for transmission/replication

The idea to transmit content and metadata as two muxrpc frames was my idea. It seems sensible/practical because it fitted into the existing stack but I see now that it tried to much to fit into the existing way and hid a dependency along the way.

This is why we have the `transfer` message definition which has two fields. One for the message, which should be required and one field for the content, which can be omitted.

# Rational

While this is would introduce radical new ways of doing things, like requiring CBOR for encoding and supporting multiple feed formats, it also makes concessions to how things are currently. In a sense this proposal should be seen as an overhaul of the current scheme, only adding offchain capabilities. Let me elaborate on two of them which cater to this point specifically:

## Keeping the timestamp on the message

In principle, the timestamp is an application concern. Some message types could omit it and it could ne considered _cleaner_ to move them up into the content of the types that want/need them. We recognize however that it would stir up problems for existing applications and this is something we are not interested in.

## Having the author on the message

A similar argument could be made for the author of a message. In the current design the author never changes over the lifetime of a feed, so why have it on each and every message? Especially if you replicate one feed at a time it seems wasteful, since the author is already known.

@dominic made a pretty good security argument [here](%1AsqTRxdVrbfypC69W7uWbMClQteNNnnl3ohzbpu3Xw=.sha256). It should always be known which key-pair created a signature and thus having it reduces ambiguity and possible backdoors.

## Only encoding the content

This format would only encode the metadata as CBOR, leaving the _user_ to encode their content as they see fit.
Since we don't want to cause problems for applications, we suggest keeping the `content` portion in JSON.
This should allow for messages to be mapped full JSON objects which look just like regular messages so that they can be consumed by applications without any change.

For upgrades and more advance uses we added a `encoding enum` that only defines JSON up until now.

# Definitions


## CBOR basics

If you never worked with CBOR, I suggest checking out it's [website](https://cbor.io) and the definitions in {{?RFC7049}}). Similar to JSON it is a _self describing_ format. Which means, bytes of it can be translated to logical, typed values without the need for a schema definition.

What helped me a lot as well to understand it better was [the playground at cbor.me](https://cbor.me). Here you can translate between the bytes in hexadecimal notation and the diagnostic noation (defined in section 6 of it's RFC). Entering a key-value object on the left like this:

~~~~~~~~~~~
{
  "type": "test",
  "count": 123,
  "true": false
}
~~~~~~~~~~~

And it outputs an indented and commented version with type annotations, like this:

~~~~~~~~~~~
A3               # map(3)
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
~~~~~~~~~~~

The comments tell us _this is a map with 3 entries_. Maps are key-value pairs, so we get three tuples of first the name (or key) of the pair and then the value. Notice that the keys are also typed (_text of len N_).

Let's compare it to an array of the same values, without the keys:

~~~~~~~~~~~
["test", 123, false]
~~~~~~~~~~~

results in

~~~~~~~~~~~
83             # array(3)
   64          # text(4)
      74657374 # "test"
   18 7B       # unsigned(123)
   F4          # primitive(20)
~~~~~~~~~~~

This results in 9 encoded bytes. The map example needs 25, in comparison. Encoding well defined objects as maps comes with quite the overhead.


# TODO

## Events

One writes `message` definitions which describe the type and ordering of each field.



For the metadata of a message it looks like this:

~~~~~~~~~~~
message Meta {
  bytes previous   = 1;
  bytes author     = 2;
  uint64 sequence  = 3;
  Content content  = 4;
  uint64 timestamp = 5;
}

message Content {
    ContentType type = 1;
    uint64 size = 2;
    bytes hash = 3;
}

enum ContentType {
    Missing = 0;
    JSON = 1;
    // CBOR = 2; ???
}
~~~~~~~~~~~

Field one and two are arbitrary byte arrays, named `previous` and `author`.
Field number three is the sequence number of the message. (Protobuf uses variable size integers which grow in bytes as needed.)
Field number four embeds another structure inside of `Meta`, the `content` which in turn is defined as the three fields `type`, `size` and `hash`.
The `ContentType` is an enumeration of possible values for a field, making sure the protocol agrees on a set of known values.

With such a definition file at hand, protobuf toolchains can generate code that does the marshalling to and from bytes for you.
That is also where it's job ends, though. What constitutes a valid hash or public key is up to the implementor of this new feed type. 

The next needed message structure would be `message` which is the meta with the corresponding signature:

~~~~~~~~~~~
message Message {
    Meta meta = 1;
    bytes signature = 2;
}
~~~~~~~~~~~

To validate a message, the receiver re-encodes just the `meta` fields to bytes and passes it and the signature to the cryptographic function that does the validation.

Lastly, there is a `transfer` message structure that has a `Message` and a byte array for the actual `content`:

~~~~~~~~~~~
message Transfer {
    Message Message = 1;
    bytes content = 2;
}
~~~~~~~~~~~

# Hash/PubKey References

The hashes and public key references are not base64 encoded readable strings but binary encoded.

We don't plan to support many formats, which is why I decided against something like IPFS Multihash, which supports every hash under the sun. Again, this is not important because we don't encode the `content` with this, just the metadata.

Currently there are only three different reference types:

* `0x01`: ED25519 Public Key, 32bytes of data
* `0x02`: `Previous` message hash, using SHA256 (32bytes of data)
* `0x03`: `Content.Hash` also using SHA256 (32bytes of data)

We add one byte as prefix to those bytes, making all references 33bytes long.


# Code

the current work-in-progress repository can be found [here](http://cryptbox.mindeco.de/ssb/gabbygrove).

It experiments with Go and javascript interoperability and shows that signature verification and content hashing works as expected.

Integration into go-ssb or the javascript stack is pending on review comments.

One open question would be how to get this into EBT while also supporting the classical/legacy way of encoding messages.
For classical replication I'd suggest a new rpc stream command, similar to `createHistoryStream` which sends `transfer` encoded messages one by one.

# Further comments

First, I'm not heartpressed on the name at all. And if this isn't already obvious, this would become the feed format that verse uses.

## alternative encodings

I'm undecided on protocol buffers, it just seemed to be the most stable (or boring if you like).

Possible interesting alternatives:

* captnproto (seemed like a bit bleeding edge)
* msgpack (could work, seems niche)
* protobuf (pretty steap dependency, generated code)

## Deletion requests

I believe we should leave this out of the spec and just give way for clients to drop content as wanted. Tuning replication rules with signed deletions or what ever can be done orthogonal if the chain/feed format allows validation with missing content.

## Size benefits

This cuts down the amount of transmitted bytes considerably. As an example, a _old_ contact message clocks in at roughly 434 bytes (JSON without whitespace, sequence in the hundreds range). Encoding a contact message with this, results in 289 bytes, 119 of which are still JSON. This overhead is small for longer posts but still wanted to mention it. The main driver of this reduction is the binary encoding of the references and being able to omit the field names. Converting content to a binary encoding would reduce it further but as stated above would require strict schemas for every type.

## I'm not sure how long lived this will be

I _think_ this is a solid format but wouldn't mind to be superseded by something else once it surfaces. As a migration path, I'd suggest we double down on `SameAs`.


# Adressed comments

## Event

_Message_ and _Meta_ were not easy to speak and reason about. _What includes what?_, etc. 

Also `Message` was redundant to begin with. The Hash of a signed event is the SHA256 of `event` and `signature` bytes concataneted.

TODO: cfts msg

## Content Type

was totally the wrong name. Should be encoding.
Type is already ambigous because of application content.type like about and contact

## Deterministic encoding

TODO: how sending the signed bytes instead of remarshaling makes it extensible.

## cbor

but using arrays, maps are exsessive for the well defined structure



--- back

# Historical Note

This MAY {{?RFC2119}} be useful. (you must be online the first time you
run the document rendering - afterwards, this reference is cached)


--- fluff

what?
