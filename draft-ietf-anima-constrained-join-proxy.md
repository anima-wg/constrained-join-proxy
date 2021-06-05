---
title: Constrained Join Proxy for Bootstrapping Protocols
abbrev: Join-Proxy
docname: draft-ietf-anima-constrained-join-proxy-03

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
  org: AWS
  email: kpanos@amazon.com

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

This document defines a protocol to securely assign a Pledge to a domain, represented by a Registrar, using an intermediary node between Pledge and Registrar. This intermediary node is known as a "constrained Join Proxy".

This document extends the work of {{I-D.ietf-anima-bootstrapping-keyinfra}} by replacing the Circuit-proxy between Pledge and Registrar by a stateless/stateful constrained (CoAP) Join Proxy.
It relays join traffic from the Pledge to the Registrar.

--- middle

# Introduction

Enrolment of new nodes into networks with enrolled nodes present is described in
{{I-D.ietf-anima-bootstrapping-keyinfra}} ("BRSKI") and makes use of Enrolment over Secure Transport (EST) {{RFC7030}}
with {{RFC8366}} vouchers to securely enroll devices.
BRSKI connects a new joining device (called Pledge) to "Registrars" via a Join Proxy.

The specified solutions use https and may be too large in terms of code space or bandwidth required for constrained devices.
Constrained devices possibly part of constrained networks {{RFC7228}} typically implement the IPv6 over Low-Power Wireless personal Area Networks (6LoWPAN) {{RFC4944}} and Constrained Application Protocol (CoAP) {{RFC7252}}.

CoAP can be run with the Datagram Transport Layer Security (DTLS) {{RFC6347}} as a security protocol for authenticity and confidentiality of the messages.
This is known as the "coaps" scheme.
A constrained version of EST, using Coap and DTLS, is described in {{I-D.ietf-ace-coap-est}}. The {I-D.ietf-anima-constrained-voucher} extends {{I-D.ietf-ace-coap-est}} with BRSKI artefacts such as voucher, request voucher, and the protocol extensions for constrained Pledges.

DTLS is a client-server protocol relying on the underlying IP layer to perform the routing between the DTLS Client and the DTLS Server.
However, the new Pledge will not be IP routable until it is authenticated to the network.
A new Pledge can only initially use a link-local IPv6 address to communicate with a neighbour on the same link {{RFC6775}} until it receives the necessary network configuration parameters.
However, before the Pledge can receive these configuration parameters, it needs to authenticate itself to the network to which it connects.

During enrollment, a DTLS connection is required between Pledge and Registrar.

This document specifies a new form of Join Proxy and protocol to act as intermediary between Pledge and Registrar to relay DTLS messages between Pledge and Registrar. Two versions of the Join Proxy are specified:

    1 A stateful Join Proxy that locally stores IP addresses
      during the connection.
    2 A stateless Join Proxy that where the connection state
     is stored in the messages.

This document is very much inspired by text published earlier in {{I-D.kumar-dice-dtls-relay}}.
{{I-D.richardson-anima-state-for-joinrouter}} outlined the various options for building a join proxy.
{{I-D.ietf-anima-bootstrapping-keyinfra}} adopted only the Circuit Proxy method (1), leaving the other methods as future work.
This document standardizes the CoAP/DTLS (method 4).

# Terminology          {#Terminology}

The following terms are defined in {{RFC8366}}, and are used
identically as in that document: artifact, imprint, domain, Join
Registrar/Coordinator (JRC), Manufacturer Authorized Signing Authority
(MASA), Pledge, Trust of First Use (TOFU), and Voucher.

The term "installation network" refers to all devices in the installation and the network connections between them. The term "installation IP_address" refers to the set of adresses which are routable over the whole installation network.

# Requirements Language {#reqlang}

{::boilerplate bcp14}

# Join Proxy functionality

As depicted in the {{fig-net}}, the Pledge (P), in an LLN mesh
can be more than one hop away from the Registrar (R) and not yet authenticated into the network.

In this situation, the Pledge can only communicate one-hop to its nearest neighbour, the Join Proxy (J) using their link-local  IPv6 addresses.
However, the Pledge (P) needs to communicate with end-to-end security with a Registrar to authenticate and get the relevant system/network parameters.
If the Pledge (P), knowing the IP-address of the Registrar, initiates a DTLS connection to the Registrar, then the packets are dropped at the Join Proxy (J) since the Pledge (P) is not yet admitted to the network or there is no IP routability to Pledge (P) for any returned messages from the Registrar.

~~~~

          ++++ multi-hop
          |R |---- mesh  +--+        +--+
          |  |    \      |J |........|P |
          ++++     \-----|  |        |  |
                         +--+        +--+
       Registrar       Join Proxy   Pledge
                                   

~~~~
{: #fig-net title='multi-hop enrolment.' align="left"}

Without routing the Pledge (P) cannot establish a secure connection to the Registrar (R) over multiple hops in the network.

Furthermore, the Pledge (P) cannot discover the IP address of the Registrar (R) over multiple hops to initiate a DTLS connection and perform authentication.

To overcome the problems with non-routability of DTLS packets and/or discovery of the destination address of the Registrar, the Join Proxy is introduced.
This Join Proxy functionality is configured into all authenticated devices in the network which may act as a Join Proxy for Pledges.
The Join Proxy allows for routing of the packets from the Pledge using IP routing to the intended Registrar. An authenticated Join Proxy can discover the routable IP address of the Registrar over multiple hops.
The following {{jr-spec}} specifies the two Join Proxy modes. A comparison is presented in {{jr-comp}}.

# Join Proxy specification {#jr-spec}

A Join Proxy can operate in two modes:

  * Statefull mode
  * Stateless mode

A Join Proxy MUST implement one of the two modes. A Join Proxy MAY implement both, with an unspecified mechanism to switch between the two modes.

## Statefull Join Proxy

In stateful mode, the Join Proxy forwards the DTLS messages to the Registrar.

Assume that the Pledge does not know the IP address of the Registrar it needs to contact.
The Join Proxy has has been enrolled via the Registrar and learns the IP address and port of the Registrar, for example by using the discovery mechanism described in {{jr-disc}}. The Pledge first discovers (see {{jr-disc}}) and selects the most appropriate Join Proxy.
(Discovery can also be based upon {{I-D.ietf-anima-bootstrapping-keyinfra}} section 4.1, or via DNS-SD service discovery {{RFC6763}}).
The Pledge initiates its request as if the Join Proxy is the intended Registrar. The Join Proxy receives the message at a discoverable "Join" port.
The Join Proxy constructs an IP packet by copying the DTLS message payload   from the message received from the Pledge, and provides source and destination addresses to forward the message to the intended Registrar.
The Join Proxy maintains a 4-tuple array to translate the DTLS messages received from the Registrar and forward it back to the Pledge.

In {{fig-statefull2}} the various steps of the message flow are shown, with 5684 being the standard coaps port:

~~~~
+------------+------------+-------------+--------------------------+
|   Pledge   | Join Proxy |  Registrar  |          Message         |
|    (P)     |     (J)    |    (R)      | Src_IP:port | Dst_IP:port|
+------------+------------+-------------+-------------+------------+
|      --ClientHello-->                 |   IP_P:p_P  | IP_Ja:p_J  |
|                    --ClientHello-->   |   IP_Jb:p_Jb| IP_R:5684  |
|                                       |             |            |
|                    <--ServerHello--   |   IP_R:5684 | IP_Jb:p_Jb |
|                            :          |             |            |
|       <--ServerHello--     :          |   IP_Ja:p_J | IP_P:p_P   |
|               :            :          |             |            |
|              [DTLS messages]          |       :     |    :       |
|               :            :          |       :     |    :       |
|        --Finished-->       :          |   IP_P:p_P  | IP_Ja:p_J  |
|                      --Finished-->    |   IP_Jb:p_Jb| IP_R:5684  |
|                                       |             |            |
|                      <--Finished--    |   IP_R:5684 | IP_Jb:p_Jb |
|        <--Finished--                  |   IP_Ja:p_J | IP_P:p_P   |
|              :             :          |      :      |     :      |
+---------------------------------------+-------------+------------+
IP_P:p_P = Link-local IP address and port of Pledge (DTLS Client)
IP_R:5684 = Routable IP address and coaps port of Registrar
IP_Ja:P_J = Link-local IP address and join port of Join Proxy
IP_Jb:p_Rb = Routable IP address and client port of Join proxy
~~~~
{: #fig-statefull2 title='constrained statefull joining message flow with Registrar address known to Join Proxy.' align="left"}

## Stateless Join Proxy

The stateless Join Proxy aims to minimize the requirements on the constrained Join Proxy device.
Stateless operation requires no memory in the Join Proxy device, but may also reduce the CPU impact as the device does not need to search through a state table.

If an untrusted Pledge that can only use link-local addressing wants to contact a trusted Registrar, and the Registrar is more than one hop away, it sends the DTLS message to the Join Proxy.

When a Pledge attempts a DTLS connection to the Join Proxy, it uses its link-local IP address as its IP source address.
This message is transmitted one-hop to a neighbouring (Join Proxy) node.
Under normal circumstances, this message would be dropped at the neighbour node since the Pledge is not yet IP routable or is not yet authenticated to send messages through the network.
However, if the neighbour device has the Join Proxy functionality enabled, it routes the DTLS message to its Registrar of choice.

The Join Proxy extends this message into a new type of message called Join ProxY (JPY) message and sends it on to the Registrar.

The JPY message payload consists of two parts:

  * Header (H) field: consisting of the source link-local address and port of the Pledge (P), and
  * Contents (C) field: containing the original DTLS message.

On receiving the JPY message, the Registrar retrieves the two parts.

The Registrar transiently stores the Header field information.
The Registrar uses the Contents field to execute the Registrar functionality.
However, when the Registrar replies, it also extends its DTLS message with the header field in a JPY message and sends it back to the Join Proxy.
The Registrar SHOULD NOT assume that it can decode the Header Field, it should simply repeat it when responding.
The Header contains the original source link-local address and port of the Pledge from the transient state stored earlier and the Contents field contains the DTLS message.

On receiving the JPY message, the Join Proxy retrieves the two parts.
It uses the Header field to route the DTLS message retrieved from the Contents field to the Pledge.

In this scenario, both the Registrar and the Join Proxy use discoverable "Join" ports.

The {{fig-stateless}} depicts the message flow diagram:

~~~~
+--------------+------------+---------------+-----------------------+
|    Pledge    | Join Proxy |    Registrar  |        Message        |
|     (P)      |     (J)    |      (R)      |Src_IP:port|Dst_IP:port|
+--------------+------------+---------------+-----------+-----------+
|      --ClientHello-->                     | IP_P:p_P  |IP_Ja:p_Ja |
|                    --JPY[H(IP_P:p_P),-->  | IP_Jb:p_Jb|IP_R:p_Ra  |
|                          C(ClientHello)]  |           |           |
|                    <--JPY[H(IP_P:p_P),--  | IP_R:p_Ra |IP_Jb:p_Jb |
|                         C(ServerHello)]   |           |           |
|      <--ServerHello--                     | IP_Ja:p_Ja|IP_P:p_P   |
|              :                            |           |           |
|          [ DTLS messages ]                |     :     |    :      |
|              :                            |     :     |    :      |
|      --Finished-->                        | IP_P:p_P  |IP_Ja:p_Ja |
|                    --JPY[H(IP_P:p_P),-->  | IP_Jb:p_Jb|IP_R:p_Ra  |
|                          C(Finished)]     |           |           |
|                    <--JPY[H(IP_P:p_P),--  | IP_R:p_Ra |IP_Jb:p_Jb |
|                         C(Finished)]      |           |           |
|      <--Finished--                        | IP_Ja:p_Ja|IP_P:p_P   |
|              :                            |     :     |    :      |
+-------------------------------------------+-----------+-----------+
IP_P:p_P = Link-local IP address and port of the Pledge
IP_R:p_Ra = Routable IP address and join port of Registrar
IP_Ja:p_Ja = Link-local IP address and join port of Join Proxy
IP_Jb:p_Jb = Routable IP address and port of Join Proxy

JPY[H(),C()] = Join Proxy message with header H and content C

~~~~
{: #fig-stateless title='constrained stateless joining message flow.' align="left"}

## Stateless Message structure

The JPY message is constructed as a payload with media-type aplication/cbor

Header and Contents fields togther are one cbor array of 5 elements:

   1. header field: containing a CBOR array {{RFC7049}} with the Pledge IPv6 Link Local address as a cbor byte string, the Pledge's UDP port number as a CBOR integer, the IP address family (IPv4/IPv6) as a cbor integer, and the proxy's ifindex or other identifier for the physical port as cbor integer. The header field is not DTLS encrypted.

   2. Content field: containing the DTLS encrypted payload as a CBOR byte string.

The join_proxy cannot decrypt the DTLS ecrypted payload and has no knowledge of the transported media type. 

~~~
    JPY_message =
    [
       ip      : bstr,
       port    : int,
       family  : int,
       index   : int
       payload : bstr
    ]

~~~
{: #fig-cddl title='CDDL representation of JPY message' align="left"}

The content fields are DTLS encrypted. In CBOR diagnostic notation the payload JPY[H(IP_P:p_P)], will look like:

~~~
      [h'IP_p', p_P, family, ident, h'DTLS-content']
~~~

Examples are shown in {{examples}}.

# Comparison of stateless and statefull modes {#jr-comp}

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
|             |maintain mapping between    | Proxy. Registrar needs |
|             |the address and port number | to store the packet    |
|             |of the Pledge and those     | header.                |
|             |of the Registrar.           |                        |
+-------------+----------------------------+------------------------+
|Packet size  |The size of the forwarded   |Size of the forwarded   |
|             |message is the same as the  |message is bigger than  |
|             |original message.           |the original,it includes|
|             |                            |additional source and   |
|             |                            |destination addresses.  |
+-------------+----------------------------+------------------------+
|Specification|The Join Proxy needs        |New JPY message to      |
|complexity   |additional functionality    |encapsulate DTLS message|
|             |to maintain state           |The Registrar           |
|             |information, and modify     |and the Join Proxy      |
|             |the source and destination  |have to understand the  |
|             |addresses of the DTLS       |JPY message in order    |
|             |handshake messages          |to process it.          |
+-------------+----------------------------+------------------------+
| Ports       | Join Proxy needs           |Join Proxy and Registrar|
|             | discoverable "Join" port   |need discoverable       |
|             |                            | "Join" ports           |
+-------------+----------------------------+------------------------+

~~~~
{: #fig-comparison title='Comparison between stateful and stateless mode' align="left"}

#Discovery {#jr-disc}

It is assumed that Join Proxy seamlessly provides a coaps connection between Pledge and Registrar. In particular this section replaces section 4.1 of {{I-D.ietf-anima-bootstrapping-keyinfra}}.

The discovery follows two steps:

   1. The Pledge is one hop away from the Registrar. The Pledge discovers the link-local address of the Registrar as described in {I-D.ietf-ace-coap-est}. From then on, it follows the BRSKI process as described in {I-D.ietf-ace-coap-est}, using link-local addresses.
   2. The Pledge is more than one hop away from a relevant Registrar, and discovers the link-local address and join port of a Join Proxy. The Pledge then follows the BRSKI procedure using the link-local address of the Join Proxy.
   3. once enrolled, the Join Proxy discovers the join port of the Registrar.

Once a Pledge is enrolled, it may function as Join Proxy. The Join Proxy functions are advertised as descibed below. In principle, the Join Proxy functions are offered via a "join" port, and not the standard coaps port. Also the Registrar offers a "join" port to which the stateless join proxy sends the JPY message. The Join Proxy and Registrar MUST show the extra join port number when reponding to the .well-known/core request addressed to the standard coap/coaps port.

Three discovery cases are discussed: coap discovery, 6tisch discovery and GRASP discovery.

## Pledge discovery of Registrar

The Pledge and Join Proxy are assumed to communicate via Link-Local addresses.

### CoAP discovery

The discovery of the coaps Registrar, using coap discovery, by the Join Proxy follows section 6 of {{I-D.ietf-ace-coap-est}}. The extension to discover the additional port needed by the stateless proxy is described in {{jp-disc}}.

### Autonomous Network

In the context of autonomous networks, the Join Proxy uses the DULL GRASP M_FLOOD mechanism to announce itself. Section 4.1.1 of {{I-D.ietf-anima-bootstrapping-keyinfra}} discusses this in more detail.
The Registrar announces itself using ACP instance of GRASP using M_FLOOD messages.
Autonomous Network Join Proxies MUST support GRASP discovery of Registrar as decribed in section 4.3 of {{I-D.ietf-anima-bootstrapping-keyinfra}} .

### 6tisch discovery

The discovery of Registrar by the Pledge uses the enhanced beacons as discussed in {{I-D.ietf-6tisch-enrollment-enhanced-beacon}}.

## Pledge discovers Join Proxy

### Autonomous Network

The Pledge MUST listen for GRASP M_FLOOD {{I-D.ietf-anima-grasp}} announcements of the objective: "AN_Proxy".
See section Section 4.1.1 {{I-D.ietf-anima-bootstrapping-keyinfra}} for the details of the objective.

### CoAP discovery {#jp-disc}

In the context of a coap network without Autonomous Network support, discovery follows the standard coap policy.
The Pledge can discover a Join Proxy by sending a link-local multicast message to ALL CoAP Nodes with address FF02::FD. Multiple or no nodes may respond. The handling of multiple responses and the absence of responses follow section 4 of {{I-D.ietf-anima-bootstrapping-keyinfra}}.

The join port of the Join Proxy is discovered by
sending a GET request to "/.well-known/core" including a resource type (rt)
parameter with the value "brski-proxy" {{RFC6690}}.
Upon success, the return payload will contain the join port.

The example below shows the discovery of the join port of the Join Proxy.

~~~~
  REQ: GET coap://[FF02::FD]/.well-known/core?rt=brski-proxy

  RES: 2.05 Content
  <coaps://[IP_address]:join-port>; rt="brski-proxy"
~~~~

Port numbers are assumed to be the default numbers 5683 and 5684 for coap and coaps respectively (sections 12.6 and 12.7 of {{RFC7252}} when not shown in the response.
Discoverable port numbers are usually returned for Join Proxy resources in the &lt;href&gt; of the payload (see section 5.1 of {{I-D.ietf-ace-coap-est}}).

## Join Proxy discovers Registrar join port

### CoAP discovery {#coap-disc}

The stateless Join Proxy can discover the join port of the Registrar by sending a GET request to "/.well-known/core" including a resource type (rt)
parameter with the value "join-proxy" {{RFC6690}}.
Upon success, the return payload will contain the join Port of the Registrar.

~~~~
  REQ: GET coap://[IP_address]/.well-known/core?rt=brski-proxy

  RES: 2.05 Content
  <coaps://[IP_address]:join-port>; rt="join-proxy"
~~~~

The discoverable port numbers are usually returned for Join Proxy resources in the &lt;href&gt; of the payload (see section 5.1 of {{I-D.ietf-ace-coap-est}}).


# Security Considerations

It should be noted here that the contents of the CBOR map used to convey return address information is not protected.
However, the communication is between the Proxy and a known registrar are over the already secured portion of the network, so are not visible to eavesdropping systems.

All of the concerns in {{I-D.ietf-anima-bootstrapping-keyinfra}} section 4.1 apply.
The Pledge can be deceived by malicious AN\_Proxy announcements.
The Pledge will only join a network to which it receives a valid {{RFC8366}} voucher.

If the proxy/Registrar was not over a secure network, then an attacker could change the cbor array, causing the Pledge to send traffic to another node.
If the such scenario needed to be supported, then it would be reasonable for the Proxy to encrypt the CBOR array using a locally generated symmetric key.
The Registrar would not be able to examine the result, but it does not need to do so.
This is a topic for future work.

# IANA Considerations

This document needs to create a registry for key indices in the CBOR map.  It should be given a name, and the amending formula should be IETF Specification.

##Resource Type registry

This specification registers a new Resource Type (rt=) Link Target Attributes in the "Resource Type (rt=) Link Target Attribute Values" subregistry under the "Constrained RESTful Environments (CoRE) Parameters" registry.

      rt="brski-proxy". This BRSKI resource is used to query and return
      the supported BRSKI port of the Join Proxy.

      rt="join-proxy". This BRSKI resource is used to query and return
      the supported BRSKI port of the Registrar.

# Acknowledgements

Many thanks for the comments by Brian Carpenter and Esko Dijk.

# Contributors

Sandeep Kumar, Sye loong Keoh, and Oscar Garcia-Morchon are the co-authors of the draft-kumar-dice-dtls-relay-02. Their draft has served as a basis for this document. Much text from their draft is copied over to this draft.

# Changelog

## 02 to 03

    * Terminology updated
    * Several clarifications on discovery and routability

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

The examples show the get coaps://[192.168.1.200]:5965/est/crts to a Registrar. The header generated between Client and registrar and from registrar to client are shown in detail. The DTLS encrypted code is not shown.




The request from Join Proxy to Registrar looks like:

~~~
   85                                   # array(5)
      50                                # bytes(16)
         00000000000000000000FFFFC0A801C8 # 
      19 BDA7                           # unsigned(48551)
      0A                                # unsigned(10)
      00                                # unsigned(0)
      58 2D                             # bytes(45)
   <cacrts DTLS encrypted request>
~~~

In CBOR Diagnostic:

~~~
    [h'00000000000000000000FFFFC0A801C8', 48551, 10, 0, 
     h'<cacrts DTLS encrypted request>']
~~~

The response is:

~~~
   85                                   # array(5)
      50                                # bytes(16)
         00000000000000000000FFFFC0A801C8 # 
      19 BDA7                           # unsigned(48551)
      0A                                # unsigned(10)
      00                                # unsigned(0)
   59 026A                              # bytes(618)
      <cacrts DTLS encrypted response>
~~~

In CBOR diagnostic:

~~~
    [h'00000000000000000000FFFFC0A801C8', 48551, 10, 0, 
    h'<cacrts DTLS encrypted response>']
~~~



