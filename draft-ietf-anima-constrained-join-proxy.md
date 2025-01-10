---
v: 3

title: Join Proxy for Bootstrapping of Constrained Network Elements
abbrev: Join Proxy
docname: draft-ietf-anima-constrained-join-proxy-16

# stand_alone: true

ipr: trust200902
area: Internet
wg: anima Working Group
kw: Internet-Draft
cat: std
stream: IETF

author:

- ins: M. Richardson
  name: Michael Richardson
  org: Sandelman Software Works
  email: mcr+ietf@sandelman.ca

- ins: P. van der Stok
  name: Peter van der Stok
  org: vanderstok consultancy
  email: stokcons@kpnmail.nl

- ins: P. Kampanakis
  name: Panos Kampanakis
  org: Cisco Systems
  email: pkampana@cisco.com

- ins: E. Dijk
  name: Esko Dijk
  org: IoTconsultancy.nl
  email: esko.dijk@iotconsultancy.nl

venue:
  group: anima
  mail: anima@ietf.org
  github: anima-wg/constrained-join-proxy

normative:
  RFC768:
  RFC8366bis: I-D.ietf-anima-rfc8366bis
  RFC8949:
  RFC8990:
  RFC8995:
  RFC9032:
  RFC9147:
  RFC9148:
  cBRSKI: I-D.ietf-anima-constrained-voucher
  ieee802-1AR:
    target: "https://standards.ieee.org/standard/802.1AR-2009.html"
    title: "IEEE 802.1AR Secure Device Identifier"
    author:
    rc: "IEEE Standard"
    date: 2009
  
informative:
  RFC3610:
  RFC3927:
  RFC3986:
  RFC4944:
  RFC6550:
  RFC6690:
  RFC6775:
  RFC7030:
  RFC7102:
  RFC7228:
  RFC7252:
  RFC7959:
  RFC8610:
  RFC8974:
  RFC9031:
  I-D.kumar-dice-dtls-relay:
  I-D.richardson-anima-state-for-joinrouter:

--- abstract

This document extends the work of Bootstrapping Remote Secure Key
Infrastructures (BRSKI) by replacing the (stateful) TLS Circuit proxy between
Pledge and Registrar with a stateless or stateful DTLS Circuit proxy 
which is called the constrained Join Proxy. The Join Proxy is a mesh neighbor of the
Pledge and can relay a DTLS session originating from a Pledge with only link-local
addresses to a Registrar that is not a mesh neighbor of the
Pledge.

Like the BRSKI Circuit proxy, this Join Proxy eliminates the need of
Pledges to have routeable IP addresses before enrolment by utilizing link-local
addresses. Use of the Join Proxy also eliminates the need of the Pledge
to authenticate to the network or perform network-wide Registrar discovery before enrolment.

--- middle

# Introduction

The Bootstrapping Remote Secure Key Infrastructure (BRSKI) protocol described in {{RFC8995}}
provides a solution for a secure zero-touch (automated) bootstrap of new (unconfigured) devices.
In the context of BRSKI, new devices, called "Pledges", are equipped with a factory-installed Initial Device Identifier (IDevID) (see {{ieee802-1AR}}), and are enrolled into a network.
BRSKI makes use of Enrollment over Secure Transport (EST) {{RFC7030}}
with {{RFC8366bis}} vouchers to securely enroll devices. A Registrar provides the security anchor of the network to which a Pledge enrolls.

In this document, BRSKI is extended such that a Pledge can connect to a Registrar via a constrained Join Proxy.
In particular, this solution is intended to support 6LoWPAN mesh networks as described in {{RFC4944}}.
However, 6TiSCH networks are not in scope since these use CoJP {{RFC9031}} mechanism already.

The Join Proxy as specified in this document is one of the Join Proxy
options referred to in {{RFC8995}} section 2.5.2 as future work.

A complete specification of the terminology is pointed at in {{Terminology}}.

The specified solutions in {{RFC8995}} and {{RFC7030}} are based on POST or GET requests to the EST resources 
(`/cacerts`, `/simpleenroll`, `/simplereenroll`, `/serverkeygen`, and `/csrattrs`), and the brski resources 
(`/requestvoucher`, `/voucher_status`, and `/enrollstatus`).
These requests use https and may be too large (in terms of code space or bandwidth required for constrained devices).
Constrained devices, which may be part of challenged networks {{RFC7228}}, typically implement the IPv6 over Low-Power Wireless personal Area Networks (6LoWPAN) {{RFC4944}} and Constrained Application Protocol (CoAP) {{RFC7252}}.

CoAP can be run with the Datagram Transport Layer Security (DTLS) {{RFC9147}} as a security protocol for authenticity and confidentiality of the messages.
This is known as the "coaps" scheme.
A constrained version of EST, using CoAP and DTLS, is described in {{RFC9148}}.

{{cBRSKI}} extends {{RFC9148}} with BRSKI artifacts such as voucher, request voucher, and the protocol extensions for constrained Pledges that use CoAP.

However, in networks that require authentication, such as those using {{RFC4944}},
the Pledge will not be IP routable over the mesh network
until it is authenticated to the mesh network. A new Pledge can only
initially use a link-local IPv6 address to communicate with a
mesh neighbor [RFC6775] until it receives the necessary network
configuration parameters. The Pledge receives these configuration
parameters from the Registrar. When the Registrar is not a direct
neighbor of the Registrar but several hops away, the Pledge
discovers a neighbor that is operating the constrained Join Proxy, which
forwards DTLS protected messages between Pledge and Registrar.
The constrained Join Proxy must be enrolled
previously such that the
message from constrained Join Proxy to Registrar can be routed over
one or more hops.

An enrolled Pledge can act as constrained Join Proxy between other Pledges and the enrolling Registrar.

Two modes of the constrained Join Proxy are specified:

1. A stateful Join Proxy that locally stores UDP connection state:
IP addresses (link-local with interface and non-link-local and UDP port-numbers) during the connection.

2. A stateless Join Proxy where the connection state
is replaced by a new proxy header in the UDP messages between constrained Join Proxy and Registrar.

This document is very much inspired by text published earlier in {{I-D.kumar-dice-dtls-relay}}.
{{I-D.richardson-anima-state-for-joinrouter}} outlined the various options for building a constrained Join Proxy.
{{RFC8995}} adopted only the Circuit Proxy method (1), leaving the other methods as future work.

Similar to the difference between storing and non-storing Modes of
Operations (MOP) in RPL {{RFC6550}}, the stateful and stateless modes differ in the way that they store
the state required to forward the return packet to the pledge.
In the stateful method, the
return forward state is stored in the Join Proxy.  In the stateless
method, the return forward state is stored in the network.

# Terminology          {#Terminology}

{::boilerplate bcp14}

The following terms are defined in {{RFC8366bis}} and {{RFC8995}}, and are used identically in this document: 
artifact, Circuit Proxy, Join Proxy, domain, imprint, Registrar, Pledge, and Voucher.

The term "installation" refers to all devices in the network and their interconnections, including Registrar, enrolled nodes with and without constrained Join Proxy functionality and Pledges.

(Installation) IP addresses are assumed to be routable over the whole installation network except for link-local IP addresses.

The term "Join Proxy" as used in this document refers specifically to an {{RFC8995}} Join Proxy that can support 
Pledges execute the cBRSKI protocol {{cBRSKI}} over an end-to-end secured
channel to the cBRSKI Registrar.


# Join Proxy functionality

As depicted in {{fig-net}}, the Pledge (P), in a network such as a Low-Power and Lossy Network (LLN) mesh
 {{RFC7102}} can be more than one hop away from the Registrar (R) and not yet authenticated into the network.

In this situation, the Pledge can only communicate one-hop to its nearest neighbor, the constrained Join Proxy (J), 
using their link-local IPv6 addresses.
However, the Pledge needs to communicate with end-to-end security with a Registrar to authenticate and get the relevant system/network parameters.
If the Pledge, knowing the IP-address of the Registrar, initiates a DTLS connection to the Registrar, then the packets are dropped at the Join Proxy since the Pledge is not yet admitted to the network or there is no IP routability to the Pledge for any returned messages from the Registrar.

~~~~ aasvg
                    multi-hop mesh
         .---.                         IPv6
         | R +---.    +----+    +---+ subnet +--+
         |   |    \   |6LR +----+ J |........|P |
         '---'     `--+    |    |   | clear  |  |
                      +----+    +---+        +--+
       Registrar             Join Proxy     Pledge


~~~~
{: #fig-net title='multi-hop enrollment.' align="left"}

Without a routeable IPv6 address, the Pledge (P) cannot exchange IPv6/UDP/DTLS traffic
with the Registrar (R), over multiple hops in the network.

Furthermore, the Pledge may not be able to discover the IP address of the Registrar over multiple hops to initiate a DTLS connection and perform authentication.

To overcome the problems with non-routability of DTLS packets and/or discovery of the destination address of the Registrar, the Join Proxy is introduced.
This Join Proxy functionality is also (auto) configured into all authenticated devices in the network that may act as a Join Proxy for Pledges.
The Join Proxy allows for routing of the packets from the Pledge using IP routing to the intended Registrar. An authenticated Join Proxy can discover the routable IP address of the Registrar over multiple hops.
The following {{jr-spec}} specifies the two Join Proxy modes. A comparison is presented in {{jr-comp}}.

When a mesh network is set up using cBRSKI, it requires an active Registrar that is reachable by the nodes to be 
onboarded into the mesh network. Typically, the first device to be set up is a 6LoWPAN Border Router (6LBR) which 
enables cBRSKI onboarding of new devices via a 6LoWPAN network interface. 
This 6LBR may host the cBRSKI Registrar.
At the time the Registrar and the 6LBR are enabled, there may be zero Pledges, or there may be already one or more 
Pledges waiting - periodically attempting to discover a Join Proxy for cBRSKI onboarding.

The Registrar hosted on the 6LBR will, per {{cBRSKI}}, make itself discoverable as a Join Proxy so that Pledges can 
use it for onboarding.
Note that only some of these Pledges may be neighbors of the Registrar/6LBR. 
Others would need their traffic to be relayed across one or more enrolled mesh devices (6LR) to reach the Registrar.

The desired state of the installation is a network with a Registrar and all Pledges successfully enrolled in the 
network domain. 
Some of these enrolled devices can act as Join Proxies. 
Pledges can only employ link-local communication until they are enrolled. 
A Pledge will regularly try to discover a Join Proxy with link-local discovery requests. 
The Pledges that are neighbors of the Registrar will discover the Registrar itself (as it is posing as a Join Proxy) 
and will be enrolled first using cBRSKI. 
An enrolled device can then act as Join Proxy itself. 
The Pledges that are not a neighbor of the Registrar will eventually discover a Join Proxy and be enrolled with 
cBRSKI. 
While this continues, more and more Join Proxies with a larger hop distance to the Registrar will emerge. 
The mesh network auto-configured in this way, such that at the end of the enrollment process, all Pledges are enrolled.

The Join Proxy is as a packet-by-packet proxy for UDP packets between Pledge and
Registrar. The constrained BRSKI protocol between Pledge and Registrar described in
{{cBRSKI}} which this Join Proxy supports
uses UDP messages with DTLS payload, but the Join Proxy as described here is unaware
of this payload. It can therefore potentially also work for other UDP based protocols
as long as they are agnostic to (or can be made to work with) the change of IP header
by the Join Proxy.

In both Stateless and Stateful mode, the Join Proxy needs to be configured with
or dynamically discover a Registrar to perform its service. This specification does not
discuss how a Join Proxy selects a Registrar when it discovers 2 or more.

# Join Proxy specification {#jr-spec}

A Join Proxy can operate in two modes:

   1. Stateful mode
   2. Stateless mode

The advantages and disadvantages of the two modes are presented in {{jr-comp}}.

A Join Proxy MUST implement both. A Registrar MUST implement the stateful mode and SHOULD implement the Stateless mode.

For a Join Proxy to be operational, the node on which it is running has to be
able to talk to a Registrar (exchange UDP messages with it). This can happen
fully automatically by the Join Proxy node first enrolling itself as a Pledge,
and then learning the IP address, the UDP port and the mode(s) (Stateful and/or Stateless)
of the Registrar, through a discovery mechanism such as those described in Section 6.
Other methods, such as provisioning the Join Proxy are out of scope for this document
but equally feasible.

Once the Join Proxy is operational, its mode is determined by the mode of the Registrar.
If the Registrar offers both Stateful and Stateless mode, the Join Proxy MUST use
the stateless mode.

Independent of the mode of the Join Proxy, the Pledge first discovers (see Section 6)
and selects the most appropriate Join Proxy. From the discovery, the Pledge learns the
Join Proxies link-local scope IP address and UDP (join) port.  This discovery can also be
based upon {{RFC8995}} section 4.1.  If the discovery method does not support discovery
of the join-port, then the Pledge assumes the default CoAP over DTLS UDP port (5683).

## Stateful Join Proxy {#stateful}

In stateful mode, the Join Proxy acts as a UDP "circuit" proxy that does not
change the UDP payload (data octets according to {{RFC768}}) but only rewrites
the IP and UDP headers of each packet it receives from Pledge and Registrar.

The stateful join proxy operates as a 'pseudo' UDP circuit proxy creating
and utilizing connection mapping state to rewrite the IP address and UDP port number
packet header fields of UDP packets that it forwards between Pledge and Registrar.
{{fig-statefull2}} depiects how this state is used.

~~~~
+------------+------------+-------------+--------------------------+
|   Pledge   | Join Proxy |  Registrar  |          Message         |
|    (P)     |     (J)    |    (R)      | Src_IP:port | Dst_IP:port|
+------------+------------+-------------+-------------+------------+
|      --ClientHello-->                 |   IP_P:p_P  | IP_Jl:p_Jl |
|                    --ClientHello-->   |   IP_Jr:p_Jr| IP_R:5684  |
|                                       |             |            |
|                    <--ServerHello--   |   IP_R:5684 | IP_Jr:p_Jr |
|                            :          |             |            |
|       <--ServerHello--     :          |   IP_Jl:p_Jl| IP_P:p_P   |
|               :            :          |             |            |
|              [DTLS messages]          |       :     |    :       |
|               :            :          |       :     |    :       |
|        --Finished-->       :          |   IP_P:p_P  | IP_Jl:p_Jl |
|                      --Finished-->    |   IP_Jr:p_Jr| IP_R:5684  |
|                                       |             |            |
|                      <--Finished--    |   IP_R:5684 | IP_Jr:p_Jr |
|        <--Finished--                  |   IP_Jl:p_Jl| IP_P:p_P   |
|              :             :          |      :      |     :      |
+---------------------------------------+-------------+------------+
IP_P:p_P = Link-local IP address and port of Pledge (DTLS Client)
IP_R:5684 = Routable IP address and coaps port of Registrar
IP_Jl:p_Jl = Link-local IP address and join-port of Join Proxy
IP_Jr:p_Jr = Routable IP address and client port of Join Proxy
~~~~
{: #fig-statefull2 title='constrained stateful joining message flow with Registrar address known to Join Proxy.' align="left"}

Because UDP does not have the notion of a connection, this document
calls this a 'pseudo' connection, whose establishment is solely
triggered by receipt of a packet from a pledge with an
IP_p%IF:p_P source for which no mapping state exists, and that is
termined by a connection expiry timer E.

If an untrusted Pledge that can only use link-local addressing wants to contact a trusted Registrar, and the Registrar is more than one hop away, it sends its DTLS messages to the Join Proxy.

## Stateless Join Proxy {#jpy-encapsulation-protocol}

Stateless join proxy operation eliminates the need and complexity to
maintain per UDP connection mapping state on the proxy and the state machinery to build, maintain and
remove this mapping state. It also removes the need to protect this mapping state
against DoS attacks and may also reduce memory and CPU requirements on the proxy.

Stateless join proxy operations works by introducing a new JPY message used in communication between Proxy and Registrar, 
which consists of two parts:

  * Header (H) field: contains context information about the Pledge (P) such as the link-local IP address, interface and UDP (source) port.
  * Contents (C) field: the original UDP payload (data octets according to RFC768) received from the Pledge, or destined to the Pledge.

When the join proxy receives a UDP message from a Pledge, it encodes the Pledge's
link-local IP address, interface and UDP (source) port of the UDP packet into the Header field
and the UDP payload into the Content field and sends the packet to the Registrar from
a fixed source UDP port. When the Registrar sends packets for the Pledge,
it MUST return the Header field unchanged, so that the join proxy can decode the
Header to reconstruct the Pledge's link-local IP address, interace and UDP (destination) port
for the return UDP packet. {{fig-stateless}} shows this per-packet mapping on the join proxy.

The Registrar transiently stores the Header field information.
The Registrar uses the Contents field to execute the Registrar functionality.
When the Registrar replies, it wraps its DTLS message in a JPY message and sends it back to the Join Proxy.
The Registrar SHOULD NOT assume that it can decode the Header Field, it should simply repeat it when responding.
The Header contains the original source link-local address and port of the Pledge from the transient state stored 
earlier and the Contents field contains the DTLS payload.

On receiving the JPY message, the Join Proxy retrieves the two parts.
It uses the Header field information to send a UDP message containing the (DTLS) payload retrieved from the Contents field to a 
particular Pledge.

When the Registrar receives such a JPY message, it MUST treat the Header
H as a single additional opaque identifier for all packets of a UDP connection
from a Pledge: Whereas in the stateful proxy case, all packets with the same
(IP_jr:p_Jr, IP_R:p_r) belong to a single Pledge's UDP connection and hence
DTLS/CoAP connection, only the packets with the same (IP_jr:p_Jr, IP_R:p_r, H)
belong to a single Pledge's UDP connection / DTLS/CoAP connection. The
JPY message Content field contains the UDP payload of the packet for that UDP
connection. Packets with different header H belong to different Pledge's UDP connections.

In the stateless join proxy mode, both the Registrar and the Join Proxy use discoverable UDP join-ports. 
For the Join Proxy this may be a default CoAPS port (5684), or another free port.

~~~~
+--------------+------------+---------------+-----------------------+
|    Pledge    | Join Proxy |    Registrar  |        Message        |
|     (P)      |     (J)    |      (R)      |Src_IP:port|Dst_IP:port|
+--------------+------------+---------------+-----------+-----------+
|      --ClientHello-->                     | IP_P:p_P  |IP_Jl:p_Jl |
|                    --JPY[H(IP_P:p_P),-->  | IP_Jr:p_Jr|IP_R:p_Ra  |
|                          C(ClientHello)]  |           |           |
|                    <--JPY[H(IP_P:p_P),--  | IP_R:p_Ra |IP_Jr:p_Jr |
|                         C(ServerHello)]   |           |           |
|      <--ServerHello--                     | IP_Jl:p_Jl|IP_P:p_P   |
|              :                            |           |           |
|          [ DTLS messages ]                |     :     |    :      |
|              :                            |     :     |    :      |
|      --Finished-->                        | IP_P:p_P  |IP_Jr:p_Jr |
|                    --JPY[H(IP_P:p_P),-->  | IP_Jl:p_Jl|IP_R:p_Ra  |
|                          C(Finished)]     |           |           |
|                    <--JPY[H(IP_P:p_P),--  | IP_R:p_Ra |IP_Jr:p_Jr |
|                         C(Finished)]      |           |           |
|      <--Finished--                        | IP_Jl:p_Jl|IP_P:p_P   |
|              :                            |     :     |    :      |
+-------------------------------------------+-----------+-----------+
IP_P:p_P = Link-local IP address and port of the Pledge
IP_R:p_Ra = Routable IP address and join-port of Registrar
IP_Jl:p_Jl = Link-local IP address and join-port of Join Proxy
IP_Jr:p_Jr = Routable IP address and port of Join Proxy

JPY[H(),C()] = Join Proxy message with header H and content C

~~~~
{: #fig-stateless title='constrained stateless joining message flow.' align="left"}

## Stateless Message structure {#stateless-jpy}

The JPY message is carried directly over the UDP layer.
There is no CoAP or DTLS layer used between the JPY messages and the UDP layer.

A JPY messages consists of one CBOR {{RFC8949}} array of 2 elements:

   1. The Join Proxy's context data: This is a CBOR byte string. It SHOULD be between 8 and 32 bytes in size.
   2. The content field: This contains the binary DTLS payload being relayed, wrapped in a CBOR byte string.

Using CDDL {{RFC8610}}, the CBOR array that constitutes the JPY message can be formally defined as:

~~~
    JPY_message =
    [
       jp_context : bstr,
       content    : bstr
    ]
~~~
{: #fig-cddl title='CDDL representation of a JPY message' align="left"}

The content field is DTLS-encrypted. 
Therefore, the Join Proxy cannot decrypt it and has no knowledge of any transported (CoAP) messages, or media types.

The context data is to be reflected (unmodified) by the Registrar when sending return data packets to the Join Proxy.
The context data internal representation is not standardized: it can be constructed by the Join Proxy in whatever way.
It is to be used by the Join Proxy to record the context (state) of the associated content field, for example the 
information which Pledge the data traffic came from.

The Join Proxy SHOULD encrypt the context data prior to wrapping it in a CBOR byte string. It is encrypted with a 
symmetric key known only to the Join Proxy itself.
This key need not persist on a long-term basis, and MAY be changed periodically.
The considerations of  {{Section 5.2 of RFC8974}} apply.

This context data is intended to be identical to the "state object" mechanism described in {{Section 7.1 of RFC9031}}.
However, since the CoAP protocol layer is inside the DTLS layer (end-to-end encrypted between the Pledge and the 
Registrar), it is not possible for the Join Proxy to act as a CoAP proxy.

For the JPY messages relayed to the Registrar, the Join Proxy SHOULD use the same UDP source port for the JPY messages 
of all pledges.
A Join Proxy MAY vary the UDP source port, but doing so creates more local state.
A Join Proxy with multiple CPUs (unlikely in a constrained system, but possible in the future) could, for instance, use 
different source port numbers to demultiplex connections across CPUs.

### Example format for Join Proxy context data

A typical context data format might be constructed using the following CDDL grammar.
This is illustrative only: the format of jp_context is not subject to standardization.

~~~~
    jp_context_plaintext = [
      family:  uint .bits 1,
      ifindex: uint .bits 8,
      srcport: uint .bits 16,
      iid:     bstr .bits 64,
    ]
~~~~

This results in a total of 96 bits, or 12 bytes.
The structure stores the Pledge's UDP source port (srcport), the IID bits of the Pledge's originating IPv6 link-Local 
address (iid), the IPv4/IPv6 family (as a single bit) and an interface index (ifindex) to provide the link-local scope.
This size fits nicely into a single AES128 CBC block for instance, resulting in a 16 byte block of context data,
jp_context_encrypted.
This jp_context_encrypted data block is then wrapped in a CBOR byte string to form the jp_context element.
So for the example jp_context_plaintext of 12 bytes, we get a jp_context_encrypted of 16 bytes, and finally 
a jp_context of 17 bytes which adds a 1-byte overhead of encoding the data as a CBOR byte string.

Note: when IPv6 is used only the lower 64-bits of the origin IP need to be recorded, 
because they are all IPv6 link-Local addresses, so the upper 64-bits are just "fe80::" and can be elided. 
For IPv4, a link-Local IPv4 address {{RFC3927}} would be used, and it would always fit into 64 bits.
On media where the Interface IDentifier (IID) is not 64-bits, a different field size for iid will be necessary.

The Join Proxy MUST maintain the same context data for all communications from the same Pledge.
This implies that the encryption key used either does not change during the onboarding attempt of the Pledge, 
or that when it does, it is acceptable to break any onboarding connections that have not yet completed.

If using a context data format as defined above, it should be easy for the Join Proxy to meet this requirement without maintaining any local state about the pledge.

### Processing by Registrar

On reception of a JPY message by the Registrar, the Registrar MUST verify that the number of CBOR array elements is 2 or more.
The content field must be provided as input to a DTLS library {{RFC9147}}, which along with the 5-tuple of the UDP connection 
provides enough information for the Registrar to pick an appropriate (active) client context.
Note that the same UDP socket will need to be used for multiple DTLS flows, which is atypical for how DTLS usually uses sockets.
The jp_context field can be used to select an appropriate DTLS context, as DTLS headers do not contain any kind of per-session context.
The jp_context field needs to be linked to the DTLS context, and when a DTLS message need to be sent back to the client, 
then the jp_context needs to be included in a JPY message along with the DTLS message in the content field. 

Examples are shown in {{examples}}.

At the CoAP level, using the cBRSKI {{cBRSKI}} and the EST-CoAPS {{RFC9148}} protocols, 
the CoAP blockwise options {{RFC7959}} are often used to split large payloads into multiple data blocks.
The Registrar and the Pledge MUST select a block size that would allow the addition of the JPY\_message header 
(including a jp_context field of up to 34 bytes) without violating MTU sizes.

# Discovery {#jr-disc}


## Discovery operations by Join Proxy

In order to accommodate automatic configuration of the Join Proxy, it must discover the location and a capabilities of the Registar.
This includes discovering whether stateless operation is supported, or not.

### CoAP discovery {#coap-disc}

The stateless Join Proxy requires a different end point that can accept the JPY encapsulation.

The stateless Join Proxy can discover the join-port of the Registrar by sending a GET request to "/.well-known/core" including a resource type (rt) parameter with the value "brski.rjp" {{RFC6690}}.
Upon success, the return payload will contain the join-port of the Registrar.

~~~~
  REQ: GET /.well-known/core?rt=brski.rjp

  RES: 2.05 Content
  <coaps+jpy://[IP_address]:join-port>;rt=brski.rjp
~~~~

In the {{RFC6690}} link format, and {{RFC3986, Section 3.2}}, the authority attribute cannot include a port number unless it also includes the IP address.

The returned join-port is expected to process the encapsulated JPY messages described in section {{stateless-jpy}}.
The scheme remains coaps, as the inside protocol is still CoAP and DTLS.

An EST/Registrar server running at address ```2001:db8:0:abcd::52```, with the JPY process on port 7634, and the stateful Registrar on port 5683 could reply to a multicast query as follows:

~~~~
  REQ: GET /.well-known/core?rt=brski*

  RES: 2.05 Content
  <coaps+jpy://[2001:db8:0:abcd::52]:7634>;rt=brski.rjp,
  <coaps://[2001:db8:0:abcd::52]/.well-known/brski/rv>;rt=brski.rv,
  <coaps://[2001:db8:0:abcd::52]/.well-known/brski/vs>;rt=brski.vs,
  <coaps://[2001:db8:0:abcd::52]/.well-known/brski/es>;rt=brski.es
~~~~

Note: the coaps+jpy scheme is registered in {{jpyscheme}}.

### GRASP discovery

TODO: missing how to use GRASP {{RFC8990}} discovery within the ACP to locate the stateful port of the Registrar.

A Join Proxy that supports a stateless mode of operation using the mechanism described in {{stateless-jpy}} must know where to send the encoded content from the pledge.
The Registrar announces its willingness to use the stateless mechanism by including an additional objective in its M\_FLOOD'ed ```AN_join_registrar``` announcements, but with a different objective value.

The following changes are necessary with respect to Figure 10 of {{RFC8995}}:

* The transport-proto is IPPROTO_UDP
* the objective is AN\_join\_registrar, identical to {{RFC8995}}.
* the objective name is "BRSKI_RJP".

Here is an example M\_FLOOD announcing the Registrar on example port 5685, which is a port number chosen by the Registrar.

~~~
   [M_FLOOD, 51804231, h'fda379a6f6ee00000200000064000001', 180000,
   [["AN_join_registrar", 4, 255, "BRSKI_RJP"],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_UDP, 5685]]]
~~~
{: #fig-grasp-rgj title='Example of Registrar announcement message' align="left"}

Most Registrars will announce both JPY-stateless and stateful ports, and may also announce an HTTPS/TLS service:

~~~
   [M_FLOOD, 51840231, h'fda379a6f6ee00000200000064000001', 180000,
   [["AN_join_registrar", 4, 255, ""],
    [O_IPv6_LOCATOR,
    h'fda379a6f6ee00000200000064000001', IPPROTO_TCP, 8443],
    ["AN_join_registrar", 4, 255, "CMP"],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_TCP, 8448],
    ["AN_join_registrar", 4, 255, "BRSKI_JP"],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_UDP, 5684],
    ["AN_join_registrar", 4, 255, "BRSKI_RJP"],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_UDP, 5685]]]
~~~
{: #fig-grasp-many title='Example of Registrar announcing two services' align="left"}

## Pledge discovers Join Proxy

Regardless of whether the Join Proxy operates in stateful or stateless mode, the Join Proxy is discovered by the Pledge identically.
When doing constrained onboarding with DTLS as security, the Pledge will always see an IPv6 Link-Local destination, with a single UDP port to which DTLS messages are to be sent.

### CoAP discovery {#jp-disc}

In the context of a CoAP network without Autonomic Network support, discovery follows the standard CoAP policy.
The Pledge can discover a Join Proxy by sending a link-local multicast message to ALL CoAP Nodes with address FF02::FD. Multiple or no nodes may respond. The handling of multiple responses and the absence of responses follow section 4 of {{RFC8995}}.

The join-port of the Join Proxy is discovered by
sending a GET request to "/.well-known/core" including a resource type (rt)
parameter with the value "brski.jp" {{RFC6690}}.
Upon success, the return payload will contain the join-port.

The example below shows the discovery of the join-port of the Join Proxy.

~~~~
  REQ: GET coap://[FF02::FD]/.well-known/core?rt=brski.jp

  RES: 2.05 Content
  <coaps://[IP_address]:join-port>; rt="brski.jp"
~~~~

Port numbers are assumed to be the default numbers 5683 and 5684 for coap and coaps respectively (sections 12.6 and 12.7 of {{RFC7252}}) when not shown in the response.
Discoverable port numbers are usually returned for Join Proxy resources in the &lt;URI-Reference&gt; of the payload (see section 5.1 of {{RFC6690}}).

### GRASP discovery

This section is normative for uses with an ANIMA ACP.
In the context of autonomic networks, the Join Proxy uses the DULL GRASP M_FLOOD mechanism to announce itself.
Section 4.1.1 of {{RFC8995}} discusses this in more detail.

The following changes are necessary with respect to figure 10 of {{RFC8995}}:

* The transport-proto is IPPROTO_UDP
* the objective is AN_Proxy
* the objective-value is "DTLS-EST"

The Registrar announces itself using ACP instance of GRASP using M_FLOOD messages.
Autonomic Network Join Proxies MUST support GRASP discovery of Registrar as described in section 4.3 of {{RFC8995}}.

Here is an example M_FLOOD announcing the Join Proxy at fe80::1, on standard coaps port 5684.

~~~
     [M_FLOOD, 12340815, h'fe800000000000000000000000000001', 180000,
     [["AN_Proxy", 4, 1, "DTLS-EST"],
     [O_IPv6_LOCATOR,
     h'fe800000000000000000000000000001', IPPROTO_UDP, 5684]]]
~~~
{: #fig-grasp-rg title='Example of Registrar announcement message' align="left"}

### 6tisch Discovery

The discovery of CoJP {{RFC9031}} compatible Join-Proxy by the Pledge uses the enhanced beacons as discussed in {{RFC9032}}.
6tisch does not use DTLS and so this specification does not apply to it.

The Enhanced Beason discovery mechanism used in 6tisch does not convey a method to the pledge, (equivalent to an objective value, as described above), so only the CoAP/OSCORE mechanism described in {{RFC9031}} is announced.

A 6tisch network that wanted to use DTLS for security would need a new attribute for the enhanced beacon that announced the availability of a DTLS proxy as described in this document.
Future work could provide that capability.

# Comparison of stateless and stateful Join Proxy modes {#jr-comp}

The stateful and stateless mode of operation for the Join Proxy each have their advantages and disadvantages.
This section should enable operators to make a choice between the two modes based on the available device resources and network bandwidth.

| Properties  |         Stateful mode      |     Stateless mode     |
|:----------- |:---------------------------|:-----------------------|
| State Information | The Join Proxy needs additional storage to maintain mappings between the address and port number of the Pledge and those of the Registrar.  | No information is maintained by the Join Proxy. Registrar transiently stores the JPY message header.  |
|-------------
|Packet size  |The size of a relayed message is the same as the original message.   | Size of a relayed message is up to 34 bytes larger than the original: it includes additional context information.  |
|-------------
|Technical complexity |The Join Proxy needs additional functions to maintain state information, and specify the source and destination addresses and ports of relayed messages. | Requires new JPY message structure (CBOR) in Join Proxy. The Registrar requires a function to process JPY messages.|
|------------
| Join Proxy Ports | Join Proxy needs discoverable join-port | Join Proxy needs discoverable join-port  |
|------------
| Registrar Ports  | Registrar can host on a single UDP port. | Registrar must host on two UDP ports: one for DTLS, one for JPY messages. |
|=============
{: #fig-comparison title='Comparison between stateful and stateless mode' align="left"}

# Security Considerations

All the concerns in {{RFC8995}} section 4.1 apply.
The Pledge can be deceived by malicious Join Proxy announcements.
The Pledge will only join a network to which it receives a valid voucher {{cBRSKI}}.
Once the Pledge has joined, the payload between Pledge and Registrar is protected by DTLS.

A malicious Join Proxy has a number of routing possibilities:

   * It sends the message on to a malicious Registrar. This is the same case as the presence of a malicious Registrar discussed in RFC 8995.

   * It does not send on the request or does not return the response from the Registrar. This is the case of the not responding or crashing Registrar discussed in RFC 8995.

   * It uses the returned response of the Registrar to enroll itself in the network. With very low probability it can decrypt the response because successful enrollment is deemed  unlikely.

   * It uses the request from the pledge to appropriate the pledge certificate, but then it still needs to acquire the private key of the pledge. This, too, is assumed to be highly unlikely.

   * A malicious node can construct an invalid Join Proxy message. Suppose, the destination port is the coaps port. In that case, a Join Proxy can accept the message and add the routing addresses without checking the payload. The Join Proxy then routes it to the Registrar. In all cases, the Registrar needs to receive the message at the join-port, checks that the message consists of two parts and uses the DTLS payload to start the BRSKI procedure. It is highly unlikely that this malicious payload will lead to node acceptance.

  * A malicious node can sniff the messages routed by the Join Proxy. It is very unlikely that the malicious node can decrypt the DTLS payload. A malicious node can read the header field of the message sent by the stateless Join Proxy. This ability does not yield much more information than the visible addresses transported in the network packets.

It should be noted here that the contents of the CBOR array used to convey return address information is not DTLS protected. When the communication between Join Proxy and Registrar passes over an unsecure network, an attacker can change the CBOR array, causing the Registrar to deviate traffic from the intended Pledge. These concerns are also expressed in {{RFC8974}}. It is also pointed out that the encryption in the source is a local matter. Similarly to {{RFC8974}}, the use of AES-CCM {{RFC3610}} with a 64-bit tag is recommended, combined with a sequence number and a replay window.

If such scenario needs to be avoided, the Join Proxy MUST encrypt the CBOR array using a locally generated symmetric
key. The Registrar is not able to examine the encrypted result, but
does not need to. The Registrar stores the encrypted header in the return packet without modifications. The Join Proxy can decrypt the contents to route the message to the right destination.

In some installations, layer 2 protection is provided between all member pairs of the mesh. In such an environment encryption of the CBOR array is unnecessary because the layer 2 protection already provides it.

# IANA Considerations

## Extensions to the "BRSKI AN_Proxy Objective Value" Registry

TODO: register the objective value DTLS-EST.

This document makes use of it, and the registry should be extended to reference this document as well.

## Extensions to the "BRSKI AN_join_registrar Objective Value" Registry

This document registers the objective-value: "BRSKI_RJP"

## Resource Type Attributes registry

This specification registers two new Resource Type (rt=) Link Target Attributes in the "Resource Type (rt=) Link Target Attribute Values" subregistry under the "Constrained RESTful Environments (CoRE)
Parameters" registry per the {{RFC6690}} procedure.

    Attribute Value: brski.jp
    Description: This BRSKI resource type is used to query and return
                 the supported BRSKI resources of the constrained
                 Join Proxy.
    Reference: [this document]

    Attribute Value: brski.rjp
    Description: This BRSKI resource type is used for the constrained
                 Join Proxy to query and return Join Proxy specific
                 BRSKI resources of a Registrar.
    Reference: [this document]

## CoAPS+JPY Scheme Registration {#jpyscheme}

    Scheme name: coaps+jpy
    Status: permanent
    Applications/protocols that use this scheme name: cBRSKI
    Contact: ANIMA WG
    Change controller: IESG
    References: [THIS RFC]
    Scheme syntax: identical to the "coaps" scheme
    Scheme semantics: The encapsulation mechanism described in 
       {{stateless-jpy}} is used with coaps.
    Security considerations: The new encapsulation allows traffic to be 
       returned to a calling node behind a proxy.  The form of the 
       encapsulation can include privacy and integrity protection under 
       the control of the proxy system.

## Service name and port number registry {#dns-sd-spec}

This specification registers two service names under the "Service Name and Transport Protocol Port
Number" registry.

    Service Name: brski-jp
    Transport Protocol(s): udp
    Assignee:  IESG <iesg@ietf.org>
    Contact:  IESG <iesg@ietf.org>
    Description: Bootstrapping Remote Secure Key Infrastructure
                 constrained Join Proxy
    Reference: [this document]

    Service Name: brski-rjp
    Transport Protocol(s): udp
    Assignee:  IESG <iesg@ietf.org>
    Contact:  IESG <iesg@ietf.org>
    Description: Bootstrapping Remote Secure Key Infrastructure
                 Registrar join-port used by stateless constrained
                 Join Proxy
    Reference: [this document]


# Acknowledgements

Many thanks for the comments by {{{Carsten Bormann}}}, {{{Brian Carpenter}}}, {{{Spencer Dawkins}}}, {{{Esko Dijk}}}, {{{Toerless Eckert}}}, {{{Russ Housley}}}, {{{Ines Robles}}}, {{{Rich Salz}}}, {{{Jürgen Schönwälder}}}, {{{Mališa Vučinić}}}, and {{{Rob Wilton}}}.

# Contributors

{{{Sandeep Kumar}}}, {{{Sye loong Keoh}}}, and {{{Oscar Garcia-Morchon}}} are the co-authors of the draft-kumar-dice-dtls-relay-02.
Their draft text has served as a basis for this document.

# Changelog
-15 to -16

       * Clarify 'context payload' terminology; issue #49.
       * Use shorter and consistent term for Join Proxy; issue #58.
       * Author added.
       * Update reference RFC8366 to RFC8366bis.
       * Editorial updates.

-13 to -15

       * Various editorial updates and minor changes. 

-12 to -13

       * jpy message encrypted and no longer standardized

-11 to -12

       * many typos fixed and text re-organized
       * core of GRASP and CoAP discovery moved to constrained-voucher
         document, only stateless extensions remain

-10 to -11

       * Join-Proxy and Registrar discovery merged
       * GRASP discovery updated
       * ARTART review
       * TSVART review

-09 to -10

       * OPSDIR review
       * IANA review
       * SECDIR review
       * GENART review

-07 to -09

        * typos

-06 to -07
     
        * AD review changes

-05 to -06

        * RT value change to brski.jp and brski.rjp
        * new registry values for IANA
        * improved handling of jpy header array

-04 to -05

        * Join Proxy and join-port consistent spelling
        * some nits removed
        * restructured discovery
        * section
        * rephrased parts of security section

-03 to -04

       * mail address and reference

-02 to -03

       * Terminology updated
       * Several clarifications on discovery and routability
       * DTLS payload introduced

-01 to -02

      * Discovery of Join Proxy and Registrar ports

-00 to -01

       * Registrar used throughout instead of EST server
       * Emphasized Join Proxy port for Join Proxy and Registrar
       * updated discovery accordingly
       * updated stateless Join Proxy JPY header
       * JPY header described with CDDL
       * Example simplified and corrected

-00 to -00

       * copied from vanderstok-anima-constrained-join-proxy-05

--- back

#Stateless Proxy payload examples {#examples}

The examples show the request "GET coaps://192.168.1.200:5965/est/crts" to a Registrar. The header generated between Join Proxy and Registrar and from Registrar to Join Proxy are shown in detail. The DTLS payload is not shown.




The request from Join Proxy to Registrar looks like:

~~~ cbor-pretty
   85                                   # array(5)
      50                                # bytes(16)
         FE800000000000000000FFFFC0A801C8 #
      19 BDA7                           # unsigned(48551)
      01                                # unsigned(1) IP
      00                                # unsigned(0)
      58 2D                             # bytes(45)
   <cacrts DTLS encrypted request>
~~~

In CBOR Diagnostic:

~~~ cbor-diag
    [h'FE800000000000000000FFFFC0A801C8', 48551, 1, 0,
     h'<cacrts DTLS encrypted request>']
~~~

The response is:

~~~ cbor-pretty
   85                                   # array(5)
      50                                # bytes(16)
         FE800000000000000000FFFFC0A801C8 #
      19 BDA7                           # unsigned(48551)
      01                                # unsigned(1) IP
      00                                # unsigned(0)
   59 026A                              # bytes(618)
      <cacrts DTLS encrypted response>
~~~

In CBOR diagnostic:

~~~ cbor-diag
    [h'FE800000000000000000FFFFC0A801C8', 48551, 1, 0,
    h'<cacrts DTLS encrypted response>']
~~~
