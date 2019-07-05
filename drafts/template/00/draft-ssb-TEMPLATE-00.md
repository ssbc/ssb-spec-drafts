---
coding: utf-8

# see https://raw.githubusercontent.com/cabo/kramdown-rfc2629/master/examples/draft-ietf-core-block-xx.mkd for more fields

title: TEMPLATE for SSB drafts
abbrev: DRAFT TEMPLATE
docname: draft-ssb-TEMPLATE-00
category: info
submissionType: independent
ipr: none
wg: Secure Scuttlebutt Working Group

stand_alone: yes
pi: [toc, sortrefs, symrefs, comments]

author:
  -
    ins: Ch. Tschudin
    name: Christian Tschudin
    org: University of Basel
    email: ssb(@AiBJDta+4boyh2USNGwIagH/wKjeruTcDX2Aj1r/haM=.ed25519)

--- abstract

This is a placeholder. There is a little bit of useful text in the
introductory section.

--- middle

# Introduction

When copying this template you should modify the following items:

- in the config section of the markdown file:
  - title
  - abbreviation (running header)
  - docname (shown under the title)

- in the author section of the markdown file:
  - author names and addresses

- the middle section of the markdown file:
  - add your content, of course.

- in the Makefile:
  - define the draft's file name

## This is a demo subsection

This section has a ASCII art figure which has an internal reference
name as well as a title. Note the empty line between the text and the figure:

~~~~~~~~~~~
                        +-not--------------+
                        |    much          |
                        |        to        |
                        |          see     |
                        |             here |
                        `------------------'
~~~~~~~~~~~
{: #ssb-layers title="SSB Layers"}


--- back

# Historical Note

This MAY {{?RFC2119}} be useful. (you must be online the first time you
run the document rendering - afterwards, this reference is cached)


--- fluff

what?
