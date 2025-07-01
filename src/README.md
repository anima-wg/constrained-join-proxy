# src files for constrained-join-proxy

This directory contains source material for testing or inclusion into the draft.
It currently contains:

`jpy_header_cbor.cddl` 
* an example of a jpy_header_plaintext that is in the CBOR format, specified formally using CDDL (RFC 8610).
* it can be used as input to the Ruby tool `cddl` (install by `gem install cddl`). This tool can generated examples of valid, compliant CBOR data structures.