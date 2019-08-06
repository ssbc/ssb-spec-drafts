# GabbyGrove (CBOR based feed format)

# Proposal

Here is the PR on the ssb-specs-draft repo. Here is the proposal as a [type:blog]().


# Food for thought

During reasearch and discussions with friends there were a few things that didn't get integrated into this proposal:

## Replication scope

Among other things, @keks and I discussed the _signing capabilities_. We both disliked that it is _optional_ in the old format.

Keks proposed to always use this mode but use a key just made up of zero bytes by default. He also gave the feature a different name: _replication scope_, which reflects much more of what it actually enables. It seperates feeds by this setting (and the used key) since they are invalid in other settings.

He also proposed to just store the used key as a field on the event (maybe called `scope`). Since the value doesn't have to be secret, you wouldn't even need to hash any of the event bytess to achive the same effect. If it should be secret, for whatever reason, the `scope` field could store `hmac(content.hash, scopeKey)`.

I liked this more explicit way of defining it but disliked the additonal bytes this would take up (both from a minimalist and a processing size perspective) and wondered if this doesn't achive the same effect: Change `previous` and `content.hash` to an HMAC function instead of a plain hash and use `scopeKey` as their key. The only remaining problem is that the first message would process `hmac(null, scopeKey)` which would be ambigous. To fix this, we could store `hash(scopeKey)` on the first `previous` value instead of `null`.

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