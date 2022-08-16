---
v: 3

title: Constrained Join Proxy for Bootstrapping Protocols
abbrev: Join Proxy
docname: draft-ietf-anima-constrained-join-proxy-12

# stand_alone: true

area: Internet
wg: anima Working Group
kw: Internet-Draft
cat: std

author:

- ins: M. Richardson
  name: Michael Richardson
  org: Sandelman Software Works
  email: mcr+ietf@sandelman.ca

- ins: P. van der Stok
  name: Peter van der Stok
  org: vanderstok consultancy
  email: stokcons@bbhmail.nl

- ins: P. Kampanakis
  name: Panos Kampanakis
  org: Cisco Systems
  email: pkampana@cisco.com

venue:
  group: anima
  mail: anima@ietf.org
  github: anima-wg/constrained-join-proxy

normative:
  RFC6347:
  RFC8366:
  RFC8995:
  RFC9032:
  RFC9147:
  RFC9148:
  I-D.ietf-anima-constrained-voucher:
  RFC8949:
  RFC8990:
  ieee802-1AR:
    target: "https://standards.ieee.org/standard/802.1AR-2009.html"
    title: "IEEE 802.1AR Secure Device Identifier"
    author:
    rc: "IEEE Standard"
    date: 2009
  family: # this really should be IANA.address-family-numbers
    target: "https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml"
    title: "Address Family Numbers"
    author:
    rc: "IANA"
    date: 2021-10-19

informative:
  I-D.richardson-anima-state-for-joinrouter:
  RFC3986:
  RFC6690:
  RFC7030:
  RFC7102:
  RFC7228:
  RFC9031:
  I-D.kumar-dice-dtls-relay:
  RFC4944:
  RFC3610:
  RFC7252:
  RFC6775:
  RFC7959:
  RFC8974:
  RFC6550:
  RFC8610:

--- abstract
This document extends the work of Bootstrapping Remote Secure Key
Infrastructures (BRSKI) by replacing the Circuit-proxy between
Pledge and Registrar by a stateless/stateful constrained Join
Proxy. The constrained Join Proxy is a mesh neighbor of the
Pledge and can relay a DTLS session originating from a Pledge with only link-local
addresses to a Registrar which is not a mesh neighbor of the
Pledge.

This document defines a protocol to securely assign a Pledge to a domain, represented by a Registrar, using an intermediary node between Pledge and Registrar. This intermediary node is known as a "constrained Join Proxy". An enrolled Pledge can act as a constrained Join Proxy.
--- middle

# Introduction

The Bootstrapping Remote Secure Key Infrastructure (BRSKI) protocol described in {{RFC8995}}
provides a solution for a secure zero-touch (automated) bootstrap of new (unconfigured) devices.
In the context of BRSKI, new devices, called "Pledges", are equipped with a factory-installed Initial Device Identifier (IDevID) (see {{ieee802-1AR}}), and are enrolled into a network.
BRSKI makes use of Enrollment over Secure Transport (EST) {{RFC7030}}
with {{RFC8366}} vouchers to securely enroll devices. A Registrar provides the security anchor of the network to which a Pledge enrolls. In this document, BRSKI is extended such that a Pledge connects to "Registrars" via a constrained Join Proxy. In particular, the underlying IP network is assumed to be a mesh network as described in {{RFC4944}}, although other IP-over-foo networks are not excluded. An example network is shown in {{fig-net}}.

A complete specification of the terminology is pointed at in {{Terminology}}.

The specified solutions in {{RFC8995}} and {{RFC7030}} are based on POST or GET requests to the EST resources (/cacerts, /simpleenroll, /simplereenroll, /serverkeygen, and /csrattrs), and the brski resources (/requestvoucher, /voucher_status, and /enrollstatus). These requests use https and may be too large in terms of code space or bandwidth required for constrained devices.
Constrained devices which may be part of constrained networks {{RFC7228}}, typically implement the IPv6 over Low-Power Wireless personal Area Networks (6LoWPAN) {{RFC4944}} and Constrained Application Protocol (CoAP) {{RFC7252}}.

CoAP can be run with the Datagram Transport Layer Security (DTLS) {{RFC6347}} as a security protocol for authenticity and confidentiality of the messages.
This is known as the "coaps" scheme.
A constrained version of EST, using Coap and DTLS, is described in {{RFC9148}}.

The {{I-D.ietf-anima-constrained-voucher}} extends {{RFC9148}} with BRSKI artifacts such as voucher, request voucher, and the protocol extensions for constrained Pledges.

DTLS is a client-server protocol relying on the underlying IP layer to perform the routing between the DTLS Client and the DTLS Server.
However, the Pledge will not be IP routable over the mesh network
until it is authenticated to the mesh network. A new Pledge can only
initially use a link-local IPv6 address to communicate with a
mesh neighbor [RFC6775] until it receives the necessary network
configuration parameters. The Pledge receives these configuration
parameters from the Registrar. When the Registrar is not a direct
neighbor of the Registrar but several hops away, the Pledge
discovers a neighbor constrained Join Proxy, which transmits the DTLS
protected request coming from the Pledge
to the Registrar. The constrained Join Proxy must be enrolled
previously such that the
message from constrained Join Proxy to Registrar can be routed over
one or more hops.

During enrollment, a DTLS connection is required between Pledge and Registrar.

An enrolled Pledge can act as constrained Join Proxy between other Pledges and the enrolling Registrar.

This document specifies a new form of constrained Join Proxy and protocol to act as intermediary between Pledge and Registrar to relay DTLS messages between Pledge and Registrar. Two modes of the constrained Join Proxy are specified:

    1 A stateful Join Proxy that locally stores IP addresses
      during the connection.
    2 A stateless Join Proxy where the connection state
     is stored in the messages.

This document is very much inspired by text published earlier in {{I-D.kumar-dice-dtls-relay}}.
{{I-D.richardson-anima-state-for-joinrouter}} outlined the various options for building a constrained Join Proxy.
{{RFC8995}} adopted only the Circuit Proxy method (1), leaving the other methods as future work.

Similar to the difference between storing and non_storing Modes of
Operations (MOP) in RPL {{RFC6550}}, the stateful and stateless modes differ in the way that they store
the state required to forward the return packet to the pledge.
In the stateful method, the
return forward state is stored in the join proxy.  In the stateless
method, the return forward state is stored in the network.

# Terminology          {#Terminology}

{::boilerplate bcp14}

The following terms are defined in {{RFC8366}}, and are used
identically as in that document: artifact, imprint, domain, Join
Registrar/Coordinator (JRC), Pledge, and Voucher.

In this document, the term "Registrar" is used throughout instead of "Join
Registrar/Coordinator (JRC)".

The term "installation network" refers to all devices in the installation and the network connections between them. The term "installation IP_address" refers to an address out of the set of addresses which are routable over the whole installation network.

The "Constrained Join Proxy" enables a pledge that is multiple hops away from the Registrar, to securely execute the BRSKI protocol {{RFC8995}} over a secure channel.

The term "join Proxy" is used interchangeably with the term "constrained Join Proxy" throughout this document.

The {{RFC8995}} Circuit Proxy is referred to as a TCP circuit Join Proxy.

# constrained Join Proxy functionality

As depicted in the {{fig-net}}, the Pledge (P), in a Low-Power and Lossy Network (LLN) mesh
 {{RFC7102}} can be more than one hop away from the Registrar (R) and not yet authenticated into the network.

In this situation, the Pledge can only communicate one-hop to its nearest neighbor, the constrained Join Proxy (J) using their link-local IPv6 addresses.
However, the Pledge needs to communicate with end-to-end security with a Registrar to authenticate and get the relevant system/network parameters.
If the Pledge, knowing the IP-address of the Registrar, initiates a DTLS connection to the Registrar, then the packets are dropped at the constrained Join Proxy since the Pledge is not yet admitted to the network or there is no IP routability to Pledge for any returned messages from the Registrar.

~~~~ aasvg
                    multi-hop mesh
         .---.
         | R +---.    +----+    +---+        +--+
         |   |    \   |6LR +----+ J |........|P |
         '---'     `--+    |    |   |  clear |  |
                      +----+    +---+        +--+
       Registrar             Join Proxy     Pledge


~~~~
{: #fig-net title='multi-hop enrollment.' align="left"}

Without routing the Pledge cannot establish a secure connection to the Registrar over multiple hops in the network.

Furthermore, the Pledge cannot discover the IP address of the Registrar over multiple hops to initiate a DTLS connection and perform authentication.

To overcome the problems with non-routability of DTLS packets and/or discovery of the destination address of the Registrar, the constrained Join Proxy is introduced.
This constrained Join Proxy functionality is configured into all authenticated devices in the network which may act as a constrained Join Proxy for Pledges.
The constrained Join Proxy allows for routing of the packets from the Pledge using IP routing to the intended Registrar. An authenticated constrained Join Proxy can discover the routable IP address of the Registrar over multiple hops.
The following {{jr-spec}} specifies the two constrained Join Proxy modes. A comparison is presented in {{jr-comp}}.

When a mesh network is set up, it consists of a Registrar and a set of connected pledges. No constrained Join Proxies are present. The wanted end-state is a network with a Registrar and a set of enrolled devices. Some of these enrolled devices can act as constrained Join Proxies. Pledges can only employ link-local communication until they are enrolled. A Pledge will regularly try to discover a constrained Join Proxy or a Registrar with link-local discovery requests. The Pledges which are neighbors of the Registrar will discover the Registrar and be enrolled following the BRSKI protocol. An enrolled device can act as constrained Join Proxy. The Pledges which are not a neighbor of the Registrar will eventually discover a constrained Join Proxy and follow the BRSKI protocol to be enrolled. While this goes on, more and more constrained Join Proxies with a larger hop distance to the Registrar will emerge. The network should be configured such that at the end of the enrollment process, all pledges have discovered a neighboring constrained Join Proxy or the Registrar, and all Pledges are enrolled.

# constrained Join Proxy specification {#jr-spec}

A Join Proxy can operate in two modes:

  * Stateful mode
  * Stateless mode

A Join Proxy MUST implement both. A Registrar MUST implement the stateful mode and SHOULD implement the Stateless mode.

A mechanism to switch between modes is out of scope of this document. It is recommended that a Join Proxy uses only one of these modes at any given moment during an installation lifetime.

The advantages and disadvantages of the two modes are presented in {{jr-comp}}.

## Stateful Join Proxy

In stateful mode, the Join Proxy forwards the DTLS messages to the Registrar.

Assume that the Pledge does not know the IP address of the Registrar it needs to contact.
The Join Proxy has been enrolled via the Registrar and learns the IP address and port of the Registrar, by using a discovery mechanism such as described in {{jr-disc}}. The Pledge first discovers (see {{jr-disc}}) and selects the most appropriate Join Proxy.
(Discovery can also be based upon {{RFC8995}} section 4.1).
The Pledge initiates its request as if the Join Proxy is the intended Registrar. The Join Proxy receives the message at a discoverable join-port.
The Join Proxy constructs an IP packet by copying the DTLS payload from the message received from the Pledge, and provides source and destination addresses to forward the message to the intended Registrar.
The Join Proxy stores the 4-tuple array of the messages received from the Registrar and copies it back to the header of the message returned to the Pledge.

In {{fig-statefull2}} the various steps of the message flow are shown, with 5684 being the standard coaps port. The columns "SRc_IP:port" and "Dst_IP:port" show the IP address and port values for the source and destination of the message.

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

## Stateless Join Proxy {#jpy-encapsulation-protocol}

The JPY Encapsulation Protocol allows the stateless Join Proxy to minimize memory requirements on a constrained Join Proxy device.
The use of a stateless operation requires no memory in the Join Proxy device because it stores the state in a special encapsulation in the packet.  This may also reduce the CPU impact as the device does not need to search through a state table.

If an untrusted Pledge that can only use link-local addressing wants to contact a trusted Registrar, and the Registrar is more than one hop away, it sends its DTLS messages to the Join Proxy.

When a Pledge attempts a DTLS connection to the Join Proxy, it uses its link-local IP address as its IP source address.
This message is transmitted one-hop to a neighboring (Join Proxy) node.
Under normal circumstances, this message would be dropped at the neighbor node since the Pledge is not yet IP routable or is not yet authenticated to send messages through the network.
However, if the neighbor device has the Join Proxy functionality enabled; it routes the DTLS message to its Registrar of choice.

The Join Proxy transforms the DTLS message to a JPY message which includes the DTLS data as payload, and sends the JPY message to the join-port of the Registrar.

The JPY message payload consists of two parts:

  * Header (H) field: consisting of the source link-local address and port of the Pledge (P), and
  * Contents (C) field: containing the original DTLS payload.

On receiving the JPY message, the Registrar (or proxy) retrieves the two parts.

The Registrar transiently stores the Header field information.
The Registrar uses the Contents field to execute the Registrar functionality.
However, when the Registrar replies, it also extends its DTLS message with the header field in a JPY message and sends it back to the Join Proxy.
The Registrar SHOULD NOT assume that it can decode the Header Field, it should simply repeat it when responding.
The Header contains the original source link-local address and port of the Pledge from the transient state stored earlier and the Contents field contains the DTLS payload.

On receiving the JPY message, the Join Proxy retrieves the two parts.
It uses the Header field to route the DTLS message containing the DTLS payload retrieved from the Contents field to the Pledge.

In this scenario, both the Registrar and the Join Proxy use discoverable join-ports, for the Join Proxy this may be a default CoAP port.

The {{fig-stateless}} depicts the message flow diagram:

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

The JPY message is constructed as a payload directly above UDP.
There is no CoAP or DTLS layer as both are within the relayed payload.

Header and Contents fields together are consist of one CBOR {{RFC8949}} array of 2 elements, explained in CDDL {{RFC8610}}:

   1. The context payload.  This is a CBOR byte string. It SHOULD be between 8 and 32 bytes in size.
   2. Content field: containing the DTLS payload as a CBOR byte string.

~~~
    JPY_message =
    [
       pledge_context_message : bstr,
       content   : bstr
    ]

~~~
{: #fig-cddl title='CDDL representation of JPY message' align="left"}

The Join Proxy cannot decrypt the DTLS payload and has no knowledge of the transported media type.
The contents are DTLS encrypted.

The context payload is to be reflected by the Registrar when sending reply packets to the Join Proxy.
The context payload is not standardized.
It is to be used by the Join Proxy to record which pledge the traffic came from.

The Join Proxy SHOULD encrypt this context with a symmetric key known only to the Join Proxy.
This key need not persist on a long term basis, and MAY be changed periodically.
The considerations of  {{Section 5.2 of RFC8974}} apply.

This is intended to be identical to the mechanism described in {{Section 7.1 of RFC9031}}.
However, since the CoAP layer is inside of the DTLS layer (which is between the Pledge and the Registrar), it is not possible for the Join Proxy to act as a CoAP proxy.

A typical context parameter might be constructed with the following CDDL grammar:
(This is illustrative only: the contents are not subject to standardization)

~~~~
    pledge_context_message = [
      family:  uint .bits 1,
      ifindex: uint .bits 8,
      srcport: uint .bits 16,
      iid:     bstr .bits 64,
    ]
~~~~

This results in a total of 96 bits, or 12 bytes.
The structure stores the srcport, the originating IPv6 Link-Local address, the IPv4/IPv6 family (as a single bit) and an ifindex to provide the link-local scope.
This fits nicely into a single AES128 CBC block for instance, resulting in a 16 byte context message.
The Join Proxy MUST maintain the same context block for all communications from the same pledge.
This implies that any encryption key either does not change during the communication, or that when it does, it is acceptable to break any onboarding connections which have not yet completed.
If using a context parameter like defined above, it should be easy for the Join Proxy to meet this requirement without maintaining any local state about the pledge.

Note: when IPv6 is used only the lower 64-bits of the origin IP need to be recorded, because they are all IPv6 Link-Local addresses, so the upper 64-bits are just "fe80::". For IPv4, a Link-Local IPv4 address {{?RFC3927}} would be used, and it would fit into 64-bits.
On media where the IID is not 64-bits, a different arrangement will be necessary.

For the JPY messages relayed to the Registrar, the Join Proxy SHOULD use the same UDP source port for the JPY messages related to all pledges.
A Join Proxy MAY change the UDP source port, but doing so creates more local state.
A Join Proxy with multiple CPUs (unlikely in a constrained system, but possible in the future) could, for instance, use different source port numbers to demultiplex connections across CPUs.

### Processing by Registrar

On reception of a JPY message by the Registrar, the Registrar MUST verify that the number of array elements is 2 or more.
The pledge_content field must be provided as input to a DTLS library {{RFC9147}}, which along with the 5-tuple of the UDP connection provides enough context for the Registrar to pick an appropriate context.
Note that the socket will need to be used for multiple DTLS flows, which is atypical for how DTLS usually uses sockets.
The pledge\_context\_message can be used to select an appropriate DTLS context, as DTLS headers do not contain any kind of of per session context.
The pledge\_context\_message needs to be linked to the DTLS context, and when DTLS records need to be sent, then the pledge\_context\_message needs to be prepended to the data that is sent.

Examples are shown in {{examples}}.

At the CoAP level, within the Constrained BRSKI and the EST-COAP {{RFC9148}} level, the block option {{RFC7959}} is often used.
The Registrar and the Pledge MUST select a block size that would allow the addition of the JPY\_message header without violating MTU sizes.

# Discovery {#jr-disc}


## Discovery operations by Join-Proxy

In order to accomodate automatic configuration of the Join-Proxy, it must discover the location and a capabilities of the Registar.
{{Section 10.2 of I-D.ietf-anima-constrained-voucher}} explains the basic mechanism, and this section explains the extensions required to discover if stateless operation is supported.

### CoAP discovery {#coap-disc}

{{Section 10.2.2 of I-D.ietf-anima-constrained-voucher}} describes how to use CoAP Discovery.
The stateless Join Proxy requires a different end point that can accept the JPY encapsulation.

The stateless Join Proxy can discover the join-port of the Registrar by sending a GET request to "/.well-known/core" including a resource type (rt) parameter with the value "brski.rjp" {{RFC6690}}.
Upon success, the return payload will contain the join-port of the Registrar.

~~~~
  REQ: GET /.well-known/core?rt=brski.rjp

  RES: 2.05 Content
  <coaps+jpy://[IP_address]:join-port>;rt=brski.rjp
~~~~

In the {{RFC6690}} link format, and {{?RFC3986, Section 3.2}}, the authority attribute can not include a port number unless it also includes the IP address.

The returned join-port is expected to process the encapsulated JPY messages described in section {{stateless-jpy}}.
The scheme remains coaps, as the inside protocol is still CoAP and DTLS.

An EST/Registrar server running at address ```2001:db8:0:abcd::52```, with the JPY process on port 7634, and the stateful Registrar on port 5683 could reply to a multicast query as follows:

~~~~
  REQ: GET /.well-known/core?rt=brski*

  RES: 2.05 Content
  <coaps+jpy://[2001:db8:0:abcd::52]:7634>;rt=brski.rjp,
  <coaps://[2001:db8:0:abcd::52]/.well-known/brski/rv>;rt=brski.rv;ct=836,
  <coaps://[2001:db8:0:abcd::52]/.well-known/brski/vs>;rt=brski.vs;ct="50 60",
  <coaps://[2001:db8:0:abcd::52]/.well-known/brski/es>;rt=brski.es;ct="50 60",
~~~~



The coaps+jpy scheme is registered is defined in {{jpyscheme}}, as per {{RFC7252, Section 6.2}}

### GRASP discovery

{{Section 10.2.1 of I-D.ietf-anima-constrained-voucher}} describes how to use GRASP {{RFC8990}} discovery within the ACP to locate the stateful port of the Registrar.

A join proxy which supports a stateless mode of operation using the mechanism described in {{stateless-jpy}} must know where to send the encoded content from the pledge.
The Registrar announces its willingness to use the stateless mechanism by including an additional objective in it's M\_FLOOD'ed ```AN_join_registrar``` announcements, but with a different objective value.

The following changes are necessary with respect to figure 10 of {{RFC8995}}:

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

Most Registrars will announce both a JPY-stateless and stateful ports, and may also announce an HTTPS/TLS service:

~~~
   [M_FLOOD, 51840231, h'fda379a6f6ee00000200000064000001', 180000,
   [["AN_join_registrar", 4, 255, ""],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_TCP, 8443],
    ["AN_join_registrar", 4, 255, "BRSKI_JP"],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_UDP, 5684],
    ["AN_join_registrar", 4, 255, "BRSKI_RJP"],
    [O_IPv6_LOCATOR,
     h'fda379a6f6ee00000200000064000001', IPPROTO_UDP, 5685]]]
~~~
{: #fig-grasp-many title='Example of Registrar announcing two services' align="left"}

## Pledge discovers Join-Proxy

Regardless of whether the Join Proxy operates in stateful or stateless mode, the Join Proxy is discovered by the Pledge identically.
When doing constrained onboarding with DTLS as security, the Pledge will always see an IPv6 Link-Local destination, with a single UDP port to which DTLS messages are to be sent.

### CoAP discovery {#jp-disc}

In the context of a coap network without Autonomic Network support, discovery follows the standard coap policy.
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
Discoverable port numbers are usually returned for Join Proxy resources in the &lt;URI-Reference&gt; of the payload (see section 5.1 of {{RFC9148}}).

### GRASP discovery

This section is normative for uses with an ANIMA ACP.
In the context of autonomic networks, the Join-Proxy uses the DULL GRASP M_FLOOD mechanism to announce itself.
Section 4.1.1 of {{RFC8995}} discusses this in more detail.

The following changes are necessary with respect to figure 10 of {{RFC8995}}:

* The transport-proto is IPPROTO_UDP
* the objective is AN_Proxy

The Registrar announces itself using ACP instance of GRASP using M_FLOOD messages.
Autonomic Network Join Proxies MUST support GRASP discovery of Registrar as described in section 4.3 of {{RFC8995}} .

Here is an example M_FLOOD announcing the Join-Proxy at fe80::1, on standard coaps port 5684.

~~~
     [M_FLOOD, 12340815, h'fe800000000000000000000000000001', 180000,
     [["AN_Proxy", 4, 1, ""],
     [O_IPv6_LOCATOR,
     h'fe800000000000000000000000000001', IPPROTO_UDP, 5684]]]
~~~
{: #fig-grasp-rg title='Example of Registrar announcement message' align="left"}

### 6tisch discovery

The discovery of Join-Proxy by the Pledge uses the enhanced beacons as discussed in {{RFC9032}}.
6tisch does not use DTLS and so this specification does not apply to it.

# Comparison of stateless and stateful modes {#jr-comp}

The stateful and stateless mode of operation for the Join Proxy have
their advantages and disadvantages.
This section should enable operators to make a choice between the two modes based  on the available device resources and network bandwidth.

~~~~
+-------------+----------------------------+------------------------+
| Properties  |         Stateful mode      |     Stateless mode     |
+-------------+----------------------------+------------------------+
| State       |The Join Proxy needs        | No information is      |
| Information |additional storage to       | maintained by the Join |
|             |maintain mapping between    | Proxy. Registrar needs |
|             |the address and port number | to store the packet    |
|             |of the Pledge and those     | header.                |
|             |of the Registrar.           |                        |
+-------------+----------------------------+------------------------+
|Packet size  |The size of the forwarded   |Size of the forwarded   |
|             |message is the same as the  |message is bigger than  |
|             |original message.           |the original,it includes|
|             |                            |additional information  |
+-------------+----------------------------+------------------------+
|Specification|The Join Proxy needs        |New JPY message to      |
|complexity   |additional functionality    |encapsulate DTLS payload|
|             |to maintain state           |The Registrar           |
|             |information, and specify    |and the Join Proxy      |
|             |the source and destination  |have to understand the  |
|             |addresses of the DTLS       |JPY message in order    |
|             |handshake messages          |to process it.          |
+-------------+----------------------------+------------------------+
| Ports       | Join Proxy needs           |Join Proxy and Registrar|
|             | discoverable join-port     |need discoverable       |
|             |                            | join-ports             |
+-------------+----------------------------+------------------------+

~~~~
{: #fig-comparison title='Comparison between stateful and stateless mode' align="left"}

# Security Considerations

All the concerns in {{RFC8995}} section 4.1 apply.
The Pledge can be deceived by malicious Join Proxy announcements.
The Pledge will only join a network to which it receives a valid {{RFC8366}} voucher {{I-D.ietf-anima-constrained-voucher}}. Once the Pledge joined, the payload between Pledge and Registrar is protected by DTLS.

A malicious constrained Join Proxy has a number of routing possibilities:

   * It sends the message on to a malicious Registrar. This is the same case as the presence of a malicious Registrar discussed in RFC 8995.

   * It does not send on the request or does not return the response from the Registrar. This is the case of the not responding or crashing Registrar discussed in RFC 8995.

   * It uses the returned response of the Registrar to enroll itself in the network. With very low probability it can decrypt the response because successful enrollment is deemed  unlikely.

   * It uses the request from the pledge to appropriate the pledge certificate, but then it still needs to acquire the private key of the pledge. This, too, is assumed to be highly unlikely.

   * A malicious node can construct an invalid Join Proxy message. Suppose, the destination port is the coaps port. In that case, a Join Proxy can accept the message and add the routing addresses without checking the payload. The Join Proxy then routes it to the Registrar. In all cases, the Registrar needs to receive the message at the join-port, checks that the message consists of two parts and uses the DTLS payload to start the BRSKI procedure. It is highly unlikely that this malicious payload will lead to node acceptance.

  * A malicious node can sniff the messages routed by the constrained Join Proxy. It is very unlikely that the malicious node can decrypt the DTLS payload. A malicious node can read the header field of the message sent by the stateless Join Proxy. This ability does not yield much more information than the visible addresses transported in the network packets.

It should be noted here that the contents of the CBOR array used to convey return address information is not DTLS protected. When the communication between JOIN Proxy and Registrar passes over an unsecure network, an attacker can change the CBOR array, causing the Registrar to deviate traffic from the intended Pledge. These concerns are also expressed in {{RFC8974}}. It is also pointed out that the encryption in the source is a local matter. Similarly to {{RFC8974}}, the use of AES-CCM {{RFC3610}} with a 64-bit tag is recommended, combined with a sequence number and a replay window.

If such scenario needs to be avoided, the constrained Join
Proxy MUST encrypt the CBOR array using a locally generated symmetric
key. The Registrar is not able to examine the encrypted result, but
does not need to. The Registrar stores the encrypted header in the return packet without modifications. The constrained Join Proxy can decrypt the contents to route the message to the right destination.

In some installations, layer 2 protection is provided between all member pairs of the mesh. In such an environment encryption of the CBOR array is unnecessary because the layer 2 protection already provide it.

# IANA Considerations

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
    Applications/protocols that use this scheme name: Constrained BRSKI Join Proxy
    Contact: ANIMA WG
    Change controller: IESG
    References: [THIS RFC]
    Scheme syntax: identical to coaps
    Scheme semantics: The encapsulation mechanism described in {{stateless-jpy}} is used with coaps.
    Security considerations: The new encapsulation allows traffic to be returned to a calling node
       behind a proxy.  The form of the encapsulation can include privacy and integrity protection
       under the control of the proxy system.

## service name and port number registry {#dns-sd-spec}

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

{{{Sandeep Kumar}}}, {{{Sye loong Keoh}}}, and {{{Oscar Garcia-Morchon}}} are the co-authors of the draft-kumar-dice-dtls-relay-02. Their draft has served as a basis for this document. Much text from their draft is copied over to this draft.

# Changelog

## 13 to 12
    * jpy message encrypted and no longer standardized

## 12 to 11
    * many typos fixes and text re-organized
    * core of GRASP and CoAP discovery moved to contrained-voucher document, only stateless extensions remain

## 11 to 10
    * Join-Proxy and Registrar discovery merged
    * GRASP discovery updated
    * ARTART review
    * TSVART review

## 10 to 09
    * OPSDIR review
    * IANA review
    * SECDIR review
    * GENART review

## 09 to 07
     * typos

## 06 to 07
     * AD review changes

## 05 to 06
     * RT value change to brski.jp and brski.rjp
     * new registry values for IANA
     * improved handling of jpy header array

## 04 to 05
     * Join Proxy and join-port consistent spelling
     * some nits removed
     * restructured discovery
     * section
     * rephrased parts of security section

## 03 to 04

    * mail address and reference

## 02 to 03

    * Terminology updated
    * Several clarifications on discovery and routability
    * DTLS payload introduced

## 01 to 02

   * Discovery of Join Proxy and Registrar ports

## 00 to 01

   * Registrar used throughout instead of EST server
   * Emphasized additional Join Proxy port for Join Proxy and Registrar
   * updated discovery accordingly
   * updated stateless Join Proxy JPY header
   * JPY header described with CDDL
   * Example simplified and corrected

## 00 to 00

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



