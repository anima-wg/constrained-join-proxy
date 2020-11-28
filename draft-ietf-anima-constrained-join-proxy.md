---
title: Constrained Join Proxy for Bootstrapping Protocols
abbrev: Join-Proxy
docname: draft-ietf-anima-constrained-join-proxy-00

# stand_alone: true

ipr: trust200902
area: Internet
wg: anima Working Group
kw: Internet-Draft
cat: std

pi:    # can use array (if all yes) or hash here
  toc: yes
  sortrefs:   # defaults to yes
  symrefs: yes

author:


- ins: M. Richardson
  name: Michael Richardson
  org: Sandelman Software Works
  email: mcr+ietf@sandelman.ca

- ins: P. van der Stok
  name: Peter van der Stok
  org: vanderstok consultancy
  email: consultancy@vanderstok.org

- ins: P. Kampanakis
  name: Panos Kampanakis
  org: Cisco Systems
  email: pkampana@cisco.com

normative:
  RFC6347:
  RFC7049:
  RFC8366:
  I-D.ietf-anima-bootstrapping-keyinfra:
  I-D.ietf-ace-coap-est:
  I-D.ietf-core-multipart-ct:
  I-D.ietf-6tisch-enrollment-enhanced-beacon:
  I-D.ietf-anima-constrained-voucher:
  I-D.ietf-anima-grasp:
informative:
  RFC6763:
  I-D.richardson-anima-state-for-joinrouter:
  RFC6690:
  RFC7030:
  RFC7228:
  I-D.kumar-dice-dtls-relay:
  RFC4944:
  RFC7252:
  RFC6775:

--- abstract

This document defines a protocol to securely assign a pledge to a domain, represented by an EST server, using an intermediary node between pledge and EST server. This intermediary node is known as a "constrained Join Proxy".

This document extends the work of {{I-D.ietf-anima-bootstrapping-keyinfra}} by replacing the Circuit-proxy by a stateless/stateful constrained (CoAP) Join Proxy.
It transports join traffic from the pledge to the Registrar without requiring per-client state.

--- middle

# Introduction

Enrolment of new nodes into networks with enrolled nodes present is described in
{{I-D.ietf-anima-bootstrapping-keyinfra}} ("BRSKI") and makes use of Enrolment over Secure Transport (EST) {{RFC7030}}
with {{RFC8366}} vouchers to securely enroll devices.
BRSKI connects new devices ("pledges") to extended EST servers ("Registrars") via a Join Proxy.

The specified solutions use https and may be too large in terms of code space or bandwidth required for constrained devices.
Constrained devices possibly part of constrained networks {{RFC7228}} typically implement the IPv6 over Low-Power Wireless personal Area Networks (6LoWPAN) {{RFC4944}} and Constrained Application Protocol (CoAP) {{RFC7252}}.

CoAP can be run with the Datagram Transport Layer Security (DTLS) {{RFC6347}} as a security protocol for authenticity and confidentiality of the messages.
This is known as the "coaps" scheme.
A constrained version of EST, using Coap and DTLS, is described in {{I-D.ietf-ace-coap-est}}. The {I-D.ietf-anima-constrained-voucher} describes the BRSKI extensions to the EST server.

DTLS is a client-server protocol relying on the underlying IP layer to perform the routing between the DTLS Client and the DTLS Server.
However, the new "joining" device will not be IP routable until it is authenticated to the network.
A new "joining" device can only initially use a link-local IPv6 address to communicate with a neighbour node using  neighbour discovery {{RFC6775}} until it receives the necessary network configuration parameters.
However, before the device can receive these configuration parameters, it needs to authenticate itself to the network to which it connects.
IPv6 routing is necessary to establish a connection between joining device and the extended EST server.

A DTLS connection is required between Pledge and EST server.

This document specifies a new form of Join Proxy and protocol to act as intermediary between joining device and EST server to establish a connection between joining device and EST server.

This document is very much inspired by text published earlier in {{I-D.kumar-dice-dtls-relay}}.
{{I-D.richardson-anima-state-for-joinrouter}} outlined the various options for building a join proxy.
{{I-D.ietf-anima-bootstrapping-keyinfra}} adopted only the Circuit Proxy method (1), leaving the other methods as future work.
This document standardizes the CoAP/DTLS (method 4).

# Terminology          {#Terminology}

The following terms are defined in {{RFC8366}}, and are used
identically as in that document: artifact, imprint, domain, Join
Registrar/Coordinator (JRC), Manufacturer Authorized Signing Authority
(MASA), pledge, Trust of First Use (TOFU), and Voucher.

# Requirements Language {#reqlang}

{::boilerplate bcp14}

# Join Proxy functionality

As depicted in the {{fig-net}}, the joining Device, or pledge (P), in an LLN mesh
can be more than one hop away from the EST server (E) and not yet authenticated into the network.

In this situation, it can only communicate one-hop to its nearest neighbour, the Join Proxy (J) using their link-local  IPv6 addresses.
However, the Pledge (P) needs to communicate with end-to-end security with a Registrar hosting the EST server (E) to authenticate and get the relevant system/network parameters.
If the Pledge (P) initiates a DTLS connection to the EST server whose IP address has been pre-configured, then the packets are dropped at the Join Proxy (J) since the Pledge (P) is not yet admitted to the network or there is no IP routability to Pledge (P) for any returned messages.

~~~~

          ++++ multi-hop
          |E |---- mesh  +--+        +--+
          |  |    \      |J |........|P |
          ++++     \-----|  |        |  |
       EST server        +--+        +--+
       Registrar       Join Proxy   Pledge
                                    "Joining" Device

~~~~
{: #fig-net title='multi-hop enrolment.' align="left"}

Without routing the Pledge (P) cannot establish a secure connection to the EST server (E) in the network assuming   appropriate credentials are exchanged out-of-band, e.g. a hash of the Pledge (P)'s raw public key could be provided to the EST server (E).

Furthermore, the Pledge (P) may be unaware of the IP address of the EST server (E) to initiate a DTLS connection and perform authentication.

To overcome the problems with non-routability of DTLS packets and/or discovery of the destination address of the EST  Server to contact, the Join Proxy is introduced.
This Join Proxy functionality is configured into all authenticated devices in the network which may act as the Join Proxy for newly joining nodes.
The Join Proxy allows for routing of the packets from the Pledge using IP routing to the intended EST Server.

# Join Proxy specification

A Join Proxy can operate in two modes:

  * Statefull mode
  * Stateless mode


## Statefull Join Proxy

In stateful mode, the joining node forwards the DTLS messages to the EST server.

Assume that the Pledge does not know the IP address of the EST Server it needs to contact.
In that situation, the Join Proxy must know the (configured or discovered) IP address of a EST server.
(Discovery can be based upon {{I-D.ietf-anima-bootstrapping-keyinfra}} section 4.3, or via DNS-SD service discovery {{RFC6763}})
The Pledge initiates its request as if the Join Proxy is the intended EST server.
The Join Proxy changes the IP packet (without modifying the DTLS message) by modifying both  the source and destination addresses to forward the message to the intended EST Server.
The Join Proxy maintains a 4-tuple array to translate the DTLS messages received from the EST Server and forward it to the EST Client.
This is a form of Network Address translation, where the Join Proxy acts as a forward proxy.
In {{fig-statefull2}} the various steps of the message flow are shown, with 5684 being the standard coaps port:

~~~~
+------------+------------+-------------+--------------------------+
| EST Client | Join Proxy | EST Server  |          Message         |
|    (P)     |     (J)    |    (E)      | Src_IP:port | Dst_IP:port|
+------------+------------+-------------+-------------+------------+
|      --ClientHello-->                 |   IP_P:p_P  | IP_Ja:5684 |
|                    --ClientHello-->   |   IP_Jb:p_Jb| IP_E:5684  |
|                                       |             |            |
|                    <--ServerHello--   |   IP_E:5684 | IP_Jb:p_Jb |
|                            :          |             |            |
|       <--ServerHello--     :          |   IP_Ja:5684| IP_P:p_P   |
|               :            :          |             |            |
|               :            :          |       :     |    :       |
|               :            :          |       :     |    :       |
|        --Finished-->       :          |   IP_P:p_P  | IP_Ja:5684 |
|                      --Finished-->    |   IP_Jb:p_Jb| IP_E:5684  |
|                                       |             |            |
|                      <--Finished--    |   IP_E:5684 | IP_Jb:p_Jb |
|        <--Finished--                  |   IP_Ja:5684| IP_P:p_P   |
|              :             :          |      :      |     :      |
+---------------------------------------+-------------+------------+
IP_P:p_P = Link-local IP address and port of Pledge (DTLS Client)
IP_E:5684 = Global IP address and coaps port of EST Server
IP_Ja:5684 = Link-local IP address and coaps port of Join Proxy
IP_Jb:p_Rb = Global IP address and port of Join proxy
~~~~
{: #fig-statefull2 title='constrained statefull joining message flow with EST server address known to Join Proxy.' align="left"}

## Stateless Join Proxy

The Join Proxy is stateless to minimize the requirements on the constrained Join Proxy device.
Stateless operation requires no memory in the Join Proxy device, but may also reduce the CPU impact as the device does not need to search through a state table.

When a client joining device attempts a DTLS connection to the EST server, it uses its link-local IP address as its IP source address.
This message is transmitted one-hop to a neighbouring (join proxy) node.
Under normal circumstances, this message would be dropped at the neighbour node since the joining device is not yet IP routable or it is not yet authenticated to send messages through the network.
However, if the neighbour device has the Join Proxy functionality enabled, it routes the DTLS message to a specific EST server.
Additional security mechanisms need to exist to prevent this routing functionality being used by rogue nodes to bypass any network authentication procedures.

If an untrusted DTLS Client that can only use link-local addressing wants to contact a trusted end-point EST server, it sends the DTLS message to the Join Proxy.

The Join Proxy extends this message into a new type of message called Join ProxY (JPY) message and sends it on to the EST server.

The JPY message payload consists of two parts:

  * Header (H) field: consisting of the source link-local address and port of the Pledge (P), and
  * Contents (C) field: containing the original DTLS message.

On receiving the JPY message, the EST server retrieves the two parts.

The EST server transiently stores the Header field information.
The EST server uses the Contents field to execute the EST server functionality.
However, when the EST server replies, it also extends its DTLS message with the header field in a JPY message and sends it back to the Join Proxy.
The EST server SHOULD NOT assume that it can decode the Header Field, it should simply repeat it when responding.
The Header contains the original source link-local address and port of the DTLS Client from the transient state stored earlier (which can now be discarded) and the Contents field contains the DTLS message.

On receiving the JPY message, the Join Proxy retrieves the two parts.
It uses the Header field to route the DTLS message retrieved from the Contents field to the Pledge.

The {{fig-stateless}} depicts the message flow diagram:

~~~~
+--------------+------------+---------------+-----------------------+
| EST  Client  | Join Proxy |    EST server |        Message        |
|     (P)      |     (J)    |      (E)      |Src_IP:port|Dst_IP:port|
+--------------+------------+---------------+-----------+-----------+
|      --ClientHello-->                     | IP_P:p_P  |IP_Ja:p_Ja |
|                    --JPY[H(IP_P:p_P),-->  | IP_Jb:p_Jb|IP_E:p_Ea  |
|                          C(ClientHello)]  |           |           |
|                    <--JPY[H(IP_P:p_P),--  | IP_E:p_Ea |IP_Jb:p_Jb |
|                         C(ServerHello)]   |           |           |
|      <--ServerHello--                     | IP_Ja:p_Ja|IP_P:p_P   |
|              :                            |           |           |
|              :                            |     :     |    :      |
|                                           |     :     |    :      |
|      --Finished-->                        | IP_P:p_P  |IP_Ja:p_Ja |
|                    --JPY[H(IP_P:p_P),-->  | IP_Jb:p_Jb|IP_E:p_Ea  |
|                          C(Finished)]     |           |           |
|                    <--JPY[H(IP_P:p_P),--  | IP_E:p_Ea |IP_Jb:p_Jb |
|                         C(Finished)]      |           |           |
|      <--Finished--                        | IP_Ja:p_Ja|IP_P:p_P   |
|              :                            |     :     |    :      |
+-------------------------------------------+-----------+-----------+
IP_P:p_P = Link-local IP address and port of the Pledge
IP_E:p_Ea = Global IP address and join port of EST Server
IP_Ja:p_Ja = Link-local IP address and join port of Join Proxy
IP_Jb:p_Jb = Global IP address and port of Join Proxy

JPY[H(),C()] = Join Proxy message with header H and content C

~~~~
{: #fig-stateless title='constrained stateless joining message flow.' align="left"}

## Stateless Message structure

The JPY message is constructed as a payload with media-type application/multipart-core specified in {{I-D.ietf-core-multipart-ct}}.

Header and Contents fields use different media formats:

   1. header field: application/cbor containing a CBOR array {{RFC7049}} with the pledge IPv6 Link Local address as a 16-byte binary value, the pledge's UDP port number, if different from 5684, as a CBOR integer, and the proxy's ifindex or other identifier for the physical port on which the pledge is connected. Header is not DTLS encrypted.

   2. Content field: Any of the media types specified in {{I-D.ietf-ace-coap-est}} and {{I-D.ietf-anima-constrained-voucher}} dependent on the function that is requested:

     * application/pkcs7-mime; smime-type=server-generated-key
     * application/pkcs7-mime; smime-type=certs-only
     * application/voucher-cms+cbor
     * application/voucher-cose+cbor
     * application/pkcs8
     * application/csrattrs
     * application/pkcs10
     * application/pkix-cert

(XXX- add CDDL for CBOR array above)

The content fields are DTLS encrypted. In CBOR diagnostic notation the payload JPY[H(IP_P:p_P), with cf is content-format of DTLS-content, will look like:

~~~
      [ 60, [IP_p, p_P, ident]
        cf, h'DTLS-content']
~~~

Examples are shown in {{examples}}.

# Comparison of stateless and statefull modes

The stateful and stateless mode of operation for the Join Proxy have
their advantages and disadvantages.  This section should enable to
make a choice between the two modes based on the available device
resources and network bandwidth.

~~~~
+-------------+----------------------------+------------------------+
| Properties  |         Stateful mode      |     Stateless mode     |
+-------------+----------------------------+------------------------+
| State       |The Join Proxy needs        | No information is      |
| Information |additional storage to       | maintained by the Join |
|             |maintain mapping between    | Proxy                  |
|             |the address and port number |                        |
|             |of the pledge and those     |                        |
|             |of the EST server.          |                        |
+-------------+----------------------------+------------------------+
|Packet size  |The size of the forwarded   |Size of the forwarded   |
|             |message is the same as the  |message is bigger than  |
|             |original message.           |the original,it includes|
|             |                            |additional source and   |
|             |                            |destination addresses.  |
+-------------+----------------------------+------------------------+
|Specification|The Join Proxy needs        |New JPY message to      |
|complexity   |additional functionality    |encapsulate DTLS message|
|             |to maintain state           |The EST server          |
|             |information, and modify     |and the Join Proxy      |
|             |the source and destination  |have to understand the  |
|             |addresses of the DTLS       |JPY message in order    |
|             |handshake messages          |to process it.          |
+-------------+----------------------------+------------------------+
~~~~
{: #fig-comparison title='Comparison between stateful and stateless mode' align="left"}

#Discovery

It is assumed that Join Proxy seamlessly provides a coaps connection between Pledge and coaps EST server. In particular this section replaces section 4.2 of {{I-D.ietf-anima-bootstrapping-keyinfra}}.

The discovery follows two steps:

   1. The pledge is one hop away from the EST server. The pledge discovers the link-local address of the EST_server as described in {I-D.ietf-ace-coap-est}. From then on, it follows the BRSKI process as described in {I-D.ietf-ace-coap-est}, using link-local addresses.
   2. The pledge is more than one hop away from a relevant EST server, and discovers the link-local address of a Join Proxy. The pledge then follows the BRSKI procedure using the link-local address of the Join Proxy.

Once a pledge is enrolled, it may function as Join Proxy. The Join Proxy functions are advertised as descibed below. Usually, the Join Proxy functions are offered via a "join" port, and not the standard coaps port. The Join Proxy MUST show the join port number when reponding to the .well-known/core request addressed to the standard coap/coaps port.

Three discovery cases are discussed: coap discovery, 6tisch discovery and GRASP discovery.

## Pledge discovery of Join Proxy

The pledge and Join Proxy are assumed to communicate via Link-Local addresses.

### CoAP discovery

The discovery of the coaps EST server, using coap discovery, by the Join Proxy follows section 6 of {{I-D.ietf-ace-coap-est}}.

### Autonomous Network

In the context of autonomous networks, the Join Proxy uses the DULL GRASP M_FLOOD mechanism to announce itself. Section 4.1.1 of {{I-D.ietf-anima-bootstrapping-keyinfra}} discusses this in more detail.
The Registrar announces itself using ACP instance of GRASP using M_FLOOD messages.
Autonomous Network Join Proxies MUST support GRASP discovery of EST server as decribed in section 4.3 of {{I-D.ietf-anima-bootstrapping-keyinfra}} .

### 6tisch discovery

The discovery of EST server by the pledge uses the enhanced beacons as discussed in {{I-D.ietf-6tisch-enrollment-enhanced-beacon}}.

## Join Proxy discovers EST server

### Autonomous Network

The pledge MUST listen for GRASP M_FLOOD {{I-D.ietf-anima-grasp}} announcements of the objective: "AN_Proxy".
See section Section 4.1.1 {{I-D.ietf-anima-bootstrapping-keyinfra}} for the details of the objective.

### CoAP discovery

In the context of a coap network without Autonomous Network support, discovery follows the standard coap policy.
The Pledge can discover a Join Proxy by sending a link-local multicast message to ALL CoAP Nodes with address FF02::FD. Multiple or no nodes may respond. The handling of multiple responses and the absence of responses follow section 4 of {{I-D.ietf-anima-bootstrapping-keyinfra}}.

The presence and location of (path to) the Join Proxy resource are discovered by
sending a GET request to "/.well-known/core" including a resource type (rt)
parameter with the value "brski-proxy" {{RFC6690}}.
Upon success, the return payload will contain the root resource of the Join Proxy resources.
It is up to the implementation to choose its root resource; throughout this document the
example root resource /jp is used.
The example below shows the discovery of the presence and location of Join Proxy resources.

~~~~
  REQ: GET coap://[FF02::FD]/.well-known/core?rt=brski-proxy

  RES: 2.05 Content
  <coaps://[IP_address]:jp-port/jp>; rt="brski-proxy";ct=62
~~~~

Port numbers are assumed to be the default numbers 5683 and 5684 for coap and coaps respectively (sections 12.6 and 12.7 of {{RFC7252}} when not shown in the response.
Discoverable port numbers are usually returned for Join Proxy resources in the &lt;href&gt; of the payload (see section 5.1 of {{I-D.ietf-ace-coap-est}}).

# Security Considerations

It should be noted here that the contents of the CBOR map used to convey return address information is not protected.
However, the communication is between the Proxy and a known registrar are over the already secured portion of the network, so are not visible to eavesdropping systems.

All of the concerns in {{I-D.ietf-anima-bootstrapping-keyinfra}} section 4.1 apply.
The pledge can be deceived by malicious AN\_Proxy announcements.
The pledge will only join a network to which it receives a valid {{RFC8366}} voucher.

If the proxy/Registrar was not over a secure network, then an attacker could change the cbor array, causing the pledge to send traffic to another node.
If the such scenario needed to be supported, then it would be reasonable for the Proxy to encrypt the CBOR array using a locally generated symmetric key.
The Registrar would not be able to examine the result, but it does not need to do so.
This is a topic for future work.

# IANA Considerations

This document needs to create a registry for key indices in the CBOR map.  It should be given a name, and the amending formula should be IETF Specification.

##Resource Type registry

This specification registers a new Resource Type (rt=) Link Target Attributes in the "Resource Type (rt=) Link Target Attribute Values" subregistry under the "Constrained RESTful Environments (CoRE) Parameters" registry.

      rt="brski-proxy". This EST resource is used to query and return
      the supported EST resource of a Join Proxy placed between Pledge
      and EST server.


# Acknowledgements

Many thanks for the comments by Brian Carpenter.

# Contributors

Sandeep Kumar, Sye loong Keoh, and Oscar Garcia-Morchon are the co-authors of the draft-kumar-dice-dtls-relay-02. Their draft has served as a basis for this document. Much text from their draft is copied over to this draft.

# Changelog

## 00 to 00

   * copied from vanderstok-anima-constrained-join-proxy-05


--- back

#Stateless Proxy payload examples {#examples}

~~~
Examples need to be redone
~~~

Examples are extensions of two examples shown in {{I-D.ietf-ace-coap-est}}.
The following content formats are used:

  * 60:  application/cbor
  * 62:  application/multipart
  * 281: application/pkcs7-mime; smime-type=certs-only
  * 284: application/pkcs8
  * 286: application/pkcs10


For presentation purposes the payloads are abbreviated as follows:

cacrts request payload:

~~~
   <cacrts request payload> = <empty>
~~~

cacrts response payload:

~~~
   <cacrts response payload> =
   DTLS_encrypt(
   3082027b06092a864886f70d010702a082026c308202680201013100300b
   06092a864886f70d010701a082024e3082024a308201f0a0030201020209
   009189bcdf9c99244b300a06082a8648ce3d0403023067310b3009060355
   040613025553310b300906035504080c024341310b300906035504070c02
   4c4131143012060355040a0c0b4578616d706c6520496e63311630140603
   55040b0c0d63657274696669636174696f6e3110300e06035504030c0752
   6f6f74204341301e170d3139303130373130343034315a170d3339303130
   323130343034315a3067310b3009060355040613025553310b3009060355
   04080c024341310b300906035504070c024c4131143012060355040a0c0b
   4578616d706c6520496e6331163014060355040b0c0d6365727469666963
   6174696f6e3110300e06035504030c07526f6f742043413059301306072a
   8648ce3d020106082a8648ce3d03010703420004814994082b6e8185f3df
   53f5e0bee698973335200023ddf78cd17a443ffd8ddd40908769c55652ac
   2ccb75c4a50a7c7ddb7c22dae6c85cca538209fdbbf104c9a38184308181
   301d0603551d0e041604142495e816ef6ffcaaf356ce4adffe33cf492abb
   a8301f0603551d230418301680142495e816ef6ffcaaf356ce4adffe33cf
   492abba8300f0603551d130101ff040530030101ff300e0603551d0f0101
   ff040403020106301e0603551d1104173015811363657274696679406578
   616d706c652e636f6d300a06082a8648ce3d0403020348003045022100da
   e37c96f154c32ec0b4af52d46f3b7ecc9687ddf267bcec368f7b7f135327
   2f022047a28ae5c7306163b3c3834bab3c103f743070594c089aaa0ac870
   cd13b902caa1003100
   )
~~~

serverkeygen request payload:

~~~
   <serverkeygen request payload> =
   DTLS_encrypt(
   3081cf3078020100301631143012060355040a0c0b736b67206578616d70
   6c653059301306072a8648ce3d020106082a8648ce3d030107034200041b
   b8c1117896f98e4506c03d70efbe820d8e38ea97e9d65d52c8460c5852c5
   1dd89a61370a2843760fc859799d78cd33f3c1846e304f1717f8123f1a28
   4cc99fa000300a06082a8648ce3d04030203470030440220387cd4e9cf62
   8d4af77f92ebed4890d9d141dca86cd2757dd14cbd59cdf6961802202f24
   5e828c77754378b66660a4977f113cacdaa0cc7bad7d1474a7fd155d090d
   )
~~~

serverkeygen response payload:

~~~
   <serverkeygen response payload> =
   DTLS_encrypt(
   84                                   # array(4)
   19 011C                              # unsigned(284)
   58 8A                                # bytes(138)
   308187020100301306072a8648ce3d020106082a8648ce3d030107046d30
   6b02010104200b9a67785b65e07360b6d28cfc1d3f3925c0755799deeca7
   45372b01697bd8a6a144034200041bb8c1117896f98e4506c03d70efbe82
   0d8e38ea97e9d65d52c8460c5852c51dd89a61370a2843760fc859799d78
   cd33f3c1846e304f1717f8123f1a284cc99f
   19 0119                              # unsigned(281)
   59 01D3                              # bytes(467)
   308201cf06092a864886f70d010702a08201c0308201bc0201013100300b
   06092a864886f70d010701a08201a23082019e30820143a0030201020208
   126de8571518524b300a06082a8648ce3d04030230163114301206035504
   0a0c0b736b67206578616d706c65301e170d313930313039303835373038
   5a170d3339303130343038353730385a301631143012060355040a0c0b73
   6b67206578616d706c653059301306072a8648ce3d020106082a8648ce3d
   030107034200041bb8c1117896f98e4506c03d70efbe820d8e38ea97e9d6
   5d52c8460c5852c51dd89a61370a2843760fc859799d78cd33f3c1846e30
   4f1717f8123f1a284cc99fa37b307930090603551d1304023000302c0609
   6086480186f842010d041f161d4f70656e53534c2047656e657261746564
   204365727469666963617465301d0603551d0e04160414494be598dc8dbc
   0dbc071c486b777460e5cce621301f0603551d23041830168014494be598
   dc8dbc0dbc071c486b777460e5cce621300a06082a8648ce3d0403020349
   003046022100a4b167d0f9add9202810e6bf6a290b8cfdfc9b9c9fea2cc1
   c8fc3a464f79f2c202210081d31ba142751a7b4a34fd1a01fcfb08716b9e
   b53bdaadc9ae60b08f52429c0fa1003100
   )
~~~

##cacerts

The request from Join Proxy to EST server looks like:

~~~
    Get coaps://192.0.2.1/est/crts
    (Accept: 62)
    (Content-format: 62)
    payload =
    82                    # array(2)
    18 3C                 # unsigned(60)
    83                    # array(3)
    69                    # text(9)
         464538303A3A414238 # "FE80::AB8"
    19 237D               # unsigned(9085)
    65                    # text(5)
         6964656E74       # "ident"
~~~

In CBOR Diagnostic:

~~~
    payload = [60, ["FE80::AB8", 9085, "ident"]]
~~~

The response will then be:

~~~
     2.05 Content
     (Content-format: 62)
       Payload =
     84                                # array(4)
     18 3C                             # unsigned(60)
     83                                # array(3)
     69                                # text(9)
         464538303A3A414238            # "FE80::AB8"
     19 237D                           # unsigned(9085)
     65                                # text(5)
         6964656E74                    # "ident"
     19 0119                           # unsigned(281)
     59 027F                           # bytes(639)
     <cacrts response payload>
     ]
~~~

In CBOR diagnostic:

~~~
    payload = [60, ["FE80::AB8", 9085, "ident"],
               62, h'<cacrts response payload>']
~~~

##serverkeygen

The request from Join Proxy to EST server looks like:

~~~
    Get coaps://192.0.2.1/est/skg
    (Accept: 62)
    (Content-Format: 62)
      Payload =
    83                                # array(4)
    18 3C                             # unsigned(60)
    83                                # array(3)
    69                                # text(9)
         464538303A3A414238           # "FE80::AB8"
    19 237D                           # unsigned(9085)
    65                                # text(5)
         6964656E74                   # "ident"
    19 011E                           # unsigned(286)
    58 D2                             # bytes(210)
    <serverkeygen request payload>
~~~

In CBOR diagnostic:

~~~
    payload = [60, ["FE80::AB8", 9085, "ident"],
               286, h'<serverkeygen request payload>']
~~~

The response will then be:

~~~
     2.05 Content
     (Content-format: 62)
       Payload =
     83                                # array(4)
     18 3C                             # unsigned(60)
     83                                # array(3)
     69                                # text(9)
         464538303A3A414238            # "FE80::AB8"
     19 237D                           # unsigned(9085)
     65                                # text(5)
         6964656E74                    # "ident"
     19 011E                           # unsigned(286)
     59 0269                           # bytes(617)
     <serverkeygen response payload>
~~~

In CBOR diagnostic:

~~~
    payload = [60, ["FE80::AB8", 9085, "ident"],
               286, h'<serverkeygen response payload>']
~~~


