# SSB Content Warning spec

*v00.  2019-08-08*

## Why

People often want to avoid some topics in a conversation.

When speaking in real life you may ask listeners if they want to hear about a particular topic.  This is a way for speakers to show care for their audience.

This practice makes communication more consentful, upholding the "free listening" / "freedom of attention" aspect of the Scuttlebutt principles.

## What

A "content warning" is an optional author-provided field on a SSB message which describes, in human language, any content in the post which a reader may wish to avoid.

This enables readers to decide if they want to skip a post or read it, before they're exposed to the content itself.

Messages with no CW are unchanged by this specification.

## Social expectations

We assume the author is acting with care and goodwill towards others.  It is the author's responsibility to know their audience and be aware of topics that they are sensitive to.  This is a social norm which will emerge from an ongoing conversation between peers.  These norms will vary from community to community.

### Example use-cases

A short survey of Mastodon posts showed these content warnings (paraphrased).  This is not a normative list, just an example of use in the wild in one community.

* sexual content described in various ways, like “photo of butts”, “discussion of kink”
* discussion of racism
* discussion of transphobia
* discussion of various other difficult or triggering topics
* discussion of politics
* discussion of disturbing news of the day
* food
* eye contact
* flashing animation
* health problems
* asking for money
* death
* spoiler alert for a TV show or movie
* content that only some readers care about, like local events in a city
* identify this spider for me

## Author experience

When authoring a supported message type (see below), clients SHOULD provide a "content warning" field for the author to enter an arbitrary string.  This field SHOULD be a single line, disallowing newlines, with a maximum length of 512 bytes (when encoded in UTF-8).

The client SHOULD place this field after the main body field, next to the Post button.  This reminds the author to consider the field before posting.

The content warning field is assumed to contain a subset of Markdown (see below).  Clients MAY autocomplete channel names/hashtags, emoji shortcodes, and @username mentions in this field.

## Reader experience

At a bare minimum, clients MUST show content warnings above messages, even if they are not interactive.

When the reader first encounters a post with a CW (content warning), it SHOULD be collapsed by default unless the user has changed the client settings.

A collapsed message shows the text of the content warning instead of the main body of the message.  It still shows the author, time, number of likes, etc.  It MUST NOT show any images.

Clicking the CW toggles the display of the main body, below the CW.  The CW MUST remain visible.  It MUST be possible to re-collapse the message after expanding it, because the user may change their mind after seeing the content.

The CW MUST be rendered in a way that is distinct from regular body text so the user knows what it is.  This could be an icon next to the text such as a disclosure triangle, a different color or font weight, or some other typographical convention such as putting it in brackets.

Since the CW can contain links, there MUST be a place to click outside of the CW text which will expand/collapse the post, such as the border space around the CW text, without hitting the links.

Clients MAY take readers to a new page to read an expanded post instead of expanding it inline, but this is discouraged as it disrupts the reading flow.

### Parsing and rendering of the CW text itself

If the CW text is longer than usual (approximately 512 bytes), it SHOULD be truncated and the user SHOULD be able to expand the CW itself to see the entire CW text, before expanding the body of the message.

The client MAY treat the CW as either plain text or a subset of Markdown.  The intent of this specification is to render the CW as a single line of rich text.

Allowed Markdown features:
* links
* literal emoji characters
* emoji shortcodes
* @mentions
* #hashtags / channels
* bold, italic

Images MUST NOT be shown in the CW message itself.

Markdown features related to layout and font size MUST instead be rendered as part of the single line of text:
* newlines -- omit them
* headers -- show as bold, regular size text
* tables
* horizontal rules

The client MAY automatically linkify links in the CW text such as @mentions, #hashtags, ssb message links, blob links, and URLs.

The [ssb-markdown](https://github.com/ssbc/ssb-markdown) library has a function `md.inline(source, opts)` which renders markdown to a single line of output.  TODO: is this suitable?  Does it render images?

### User preferences

Clients SHOULD default messages to a collapsed state unless the user has changed settings.

Clients SHOULD allow users to automatically expand all CW'd posts.

Clients SHOULD NOT allow users to ever hide the CW text itself, as this provides important social context and meaning for the message.

Clients MAY remember the expanded/collapsed state of each individual message.

Clients could have a variety of settings about the behavior of CW'd messages, such as:
* Automatically start CW'd messages as: expanded / collapsed
* Auto-expand or collapse messages with the following words in their CW: _____
* Auto-expand or collapse CW messages from the following people: _____

Clients MAY offer these settings in a menu embedded within each CW, such as "always expand posts from this author".

Unless the user clearly indicates otherwise, these settings MUST NOT be stored as public messages in the user's feed -- all of these settings, and the user's expand/collapse actions, MUST be private and will likely stored locally outside of the user's feed.

Clients MAY allow users to share their CW viewing settings, blocklists, and allowlists.  This could happen by publishing public messages, subscribing to other users' settings, or allowing the user to import and export settings manually (for example, as JSON).  The user MUST be clearly informed before public sharing occurs so it does not happen by accident.  Details of this sharing out out of scope for this document.

### Images within CW posts

Users may wish to only download images from inside CW'd posts on demand, when they choose to expand the post.  This could be for legal, moral, or contextual reasons (e.g. the user is on a work computer).

Users may also wish to pre-fetch images in bulk so that they can go offline.  This conflicts with the previous wish.  Clients MAY offer settings to configure this behavior in detail.

Clients SHOULD default to the "safer" behavior of only downloading images when the post is expanded.

Recommended client settings:

> Downloading images in content-warning'd posts:
> * download when each post is expanded
> * download in advance (good for offline situations)
> 
> Viewing images in content-warning'd posts:
> * show immediately
> * blur until clicked
> * don't download at all until clicked

### Accessibility

CWs add work to the process of reading because readers have to manually expand posts.  This amount of work may be an accessibility barrier.

Clients SHOULD accomodate keyboard-only users and screen-reader users.  Failing that, they SHOULD allow all posts to be expanded by default so that reading requires less interaction.

## Technical Specification

The content warning is a string in an optional JSON field, `contentWarning`.

```json
  {
    "key": "%xxxx.sha256",
    "value": {
      "previous": "%yyyy.sha256",
      "sequence": 123,
      "author": "@abcdefg.ed25519",
      "timestamp": 1565285000000,
      "hash": "sha256",
      "content": {
        "type": "post",

        "contentWarning": "horrible spiders",
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

        "text": "Can anyone help me identify these spiders? ![spider-party.jpg](&ssss.sha256)",
        "mentions": []
      },
      "signature": "zzzz.sig.ed25519"
    },
    "timestamp": 1565285000000
  },
```

When authoring a message, clients MUST omit the field if they intend there to be no content warning.

When reading a message, clients MUST interpret these cases to mean there is NO content warning: the field is omitted, `null`, an empty string, or something other than a string.

Clients MUST support content warnings on these message types:
* `post`
* `gathering`
* `blog`

Clients SHOULD show content warnings even if they do not yet provide a way to author them.

Future message types which contain substantial content SHOULD also support content warnings.

Both public and private messages MUST support content warnings.

## Future directions

We could use [Blurhash](https://blurha.sh) which converts images to very low resolution thumbnails stored as short text strings.  This would allow showing blurry images before downloading the actual image.  Mastodon does this; see [their blog post](https://blog.joinmastodon.org/2019/05/improving-support-for-adult-content-on-mastodon/).  It's not immediately obvious where to put these strings in a message's JSON object; or do they belong in a lower level of the stack, where blobs are handled?

We could let people place content warnings on other people's posts, but that's outside the scope of this document.  Care is required to avoid creating new vectors for abuse.

## FAQ

**- What if I don't want any client-side Javascript in my client?**

You can use the [details](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/details) HTML element which allows expanding and collapsing a section of the DOM.

**- When a CW'd post has comments, should the entire thread be collapsed or only the first post?**

We don't know yet.  Let's see how people use this.

**- Why not use standardized or structured tags?**

The motivation for standardized tags is to help clients automatically show or hide certain classes of content.

The rich diversity of use-cases for content warnings, and the way they vary from community to community, makes it difficult to converge on a globally standard set of tags.  Therefore this document does not specify a standard set.

Showing the user something they don't want to see can be serious (emotionally painful, illegal, etc).  Without global standards, an automated show-or-hide feature will frequently fail and show users things they don't want to see, so it can't be relied on.  For that reason we default to hiding all posts and let the user decide about each one.

Locally standardized tags will probably emerge in various communities.  Clients MAY autocomplete the content warning field with common words and hashtags observed in other content warning fields, to facilitate this convergence.  But clients MUST also allow free text entry so authors can describe the subtlety of their content.

**- Why a new JSON field instead of embedding the warning inside the post text?**

For example, Livejournal used a special HTML tag `<lj-cut>spiders</lj-cut>`.  Reddit has its own syntax for spoilers, `>!spiders!<`.

Pros of that approach:
* Users can hide only certain parts of a post
* Probably visible in legacy clients which don't interpret the new markup

Cons:
* Adds more complexity to our already-customized Markdown parser, making it harder to implement SSB in new languages
* Users have to learn more markup instead of just typing into an additional field
* Users have to think more about which parts of their post to hide

Instead, the proposed approach is simpler to implement and simpler to use, though not quite as expressive.

**- How do I know what kind of content to tag?**

This is a social convention that emerges in conversations within a community.  Notice what topics other people are CW'ing.  Listen to your peers and act with care towards their experiences. 

You are not required to put content warnings on your posts.  Neither is anyone required to follow you.  The act of communication requires two consenting people.  Content warnings add more context and richness to this process of consent.
