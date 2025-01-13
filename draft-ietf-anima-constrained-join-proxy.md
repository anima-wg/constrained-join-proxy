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
  RFC792:
  RFC4443:
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

This document extends the constrained Bootstrapping Remote Secure Key Infrastructures (cBRSKI) onboarding protocol by 
adding a new network element, called the constrained Join Proxy.
This element acts as a circuit proxy for User Datagram Protocol (UDP) packets.
The goal of the Join Proxy is to help new devices ("Pledges") securely onboard into a new IP network using the 
cBRSKI protocol.
It is easily extendible to support other UDP-based onboarding protocols.
The Join Proxy functionality is designed for use in constrained networks, including IPv6 over Low-Power Wireless Personal Area Networks (6LoWPAN) 
based mesh networks in which the onboarding authority ("Registrar") may be multiple IP hops away from a Pledge.
Despite this, the Pledge only needs to use link-local UDP communication to complete cBRSKI onboarding.
Two modes of operation are defined, stateless and stateful, to allow implementers to make different trade-offs 
between resource usage, implementation complexity and security.

--- middle

# Introduction

The Bootstrapping Remote Secure Key Infrastructure (BRSKI) protocol described in {{RFC8995}}
provides a solution for a secure zero-touch (automated) bootstrap of new (unconfigured) devices.
In the context of BRSKI, new devices, called "Pledges", are equipped with a factory-installed Initial Device Identifier (IDevID) {{ieee802-1AR}}, and are enrolled into a network.
BRSKI makes use of Enrollment over Secure Transport (EST) {{RFC7030}}
with {{RFC8366bis}} signed vouchers to securely enroll devices.
A Registrar provides the trust anchor of the network domain to which a Pledge enrolls.

{{cBRSKI}} defines a version of BRSKI that is suitable for constrained nodes ({{RFC7228}}) and for operation 
on constrained networks ({{RFC7228}}) including Low-Power and Lossy Networks (LLN) {{RFC7102}}.
It uses Constrained Application Protocol (CoAP) {{RFC7252}} messages secured by  Datagram Transport Layer Security 
(DTLS) {{RFC9147}} to implement the BRSKI functions defined by {{RFC8995}}.

In this document, cBRSKI is extended such that a cBRSKI Pledge can connect to a Registrar via a constrained Join Proxy.
In particular, this solution is intended to support 6LoWPAN mesh networks as described in {{RFC4944}}.
6TiSCH networks are not in scope since these use CoJP {{RFC9031}} mechanism already.

The Join Proxy as specified in this document is one of the Join Proxy
options referred to in {{Section 2.5.2 of RFC8995}} as future work.

However, in IP networks that require node authentication, such as those using {{RFC4944}},
data to and from the Pledge will not be IP routable over the mesh network
until it is authenticated to the network.
A new Pledge can initially only use a link-local IPv6 address to communicate with a
mesh neighbor {{RFC6775}} until it receives the necessary network configuration parameters.

Before it can receive these parameters, the Pledge needs to be authenticated and authorized for onboarding onto the 
network. This is done in cBRSKI through an end-to-end encrypted DTLS session with a domain Registrar. 

When this Registrar is not a direct (link-local) neighbor of the Pledge but several hops away, the Pledge 
needs to discover a link-local neighbor that is operating as a constrained Join Proxy, which will help to 
forward the DTLS messages of the session between Pledge and Registrar.

Because the Join Proxy is a regular network node that has already been onboarded onto the network, it can send 
IP datagrams to the Registrar which are then routed over one or more hops over the mesh network -- and potentially 
over other IP networks too, before reaching the Registrar.

Once a Pledge has enrolled onto the network in this manner, it can be itself configured as a constrained Join Proxy 
and in this role it can help other Pledges perform the cBRSKI onboarding process.

Two modes of operation for a constrained Join Proxy are specified:

1. A stateful Join Proxy that locally stores UDP connection state per Pledge.
2. A stateless Join Proxy that does not locally store UDP connection state, but stores it in the header of a 
   message that is exchanged between the Join Proxy and the Registrar.

Similar to the difference between storing and non-storing Modes of
Operations (MOP) in RPL {{RFC6550}}, the stateful and stateless modes differ in the way that they store
the state required to forward return UDP packets from the Registrar back to the Pledge.

# Terminology          {#Terminology}

{::boilerplate bcp14}

The following terms are defined in {{RFC8366bis}} and {{RFC8995}}, and are used identically in this document: 
artifact, Circuit Proxy, Join Proxy, domain, imprint, Registrar, Pledge, and Voucher.

The term "installation" refers to all devices in the network and their interconnections, including Registrar, 
enrolled nodes (with and without constrained Join Proxy functionality) and Pledges (not yet enrolled).

(Installation) IP addresses are assumed to be routable over the whole installation network, except for link-local IP addresses.

The term "Join Proxy" as used in this document refers specifically to an {{RFC8995}} Join Proxy that can support 
Pledges to onboard using a UDP-based protocol, such as the cBRSKI protocol {{cBRSKI}} which operates over an 
end-to-end secured DTLS session with a cBRSKI Registrar.

Details of the IP address and port notation used in the Join Proxy specification are provided in {{ip-port-notation}}.


# Join Proxy Problem Statement and Solution

## Problem Statement

As depicted in {{fig-net}}, the Pledge (P), in a network such as a 6LoWPAN {{RFC4944}} mesh network  
 can be more than one hop away from the Registrar (R) and it is not yet authenticated into the network.

In this situation, the Pledge can only communicate one-hop to its nearest neighbor, the constrained Join Proxy (J), 
using link-local IPv6 addresseses.
However, the Pledge needs to communicate with end-to-end security with a Registrar to authenticate and obtains its 
domain identity/credentials, which is a domain certificate in case of cBRSKI, but may also include key material for 
network access.

~~~~ aasvg
                    multi-hop mesh
         .---.                            IPv6 
         | R +---.    +-----+    +---+  link-local  +---+
         |   |    \   | 6LR +----+ J |..............| P |
         '---'     `--+     |    |   |              |   |
                      +-----+    +---+              +---+
       Registrar                Join Proxy          Pledge


~~~~
{: #fig-net title='Multi-hop cBRSKI onboarding scenario' align="left"}

So one problem is that there is no IP routability between the Pledge and the Registrar, via intermediate nodes 
such as 6LoWPAN Routers (6LRs), despite the need for an end-to-end secured session between both.

Furthermore, the Pledge is not be able to discover the IP address of the Registrar because it is not yet allowed onto 
the network.

## Solution

To overcome these problems, the constrained Join Proxy is introduced.
This is specific functionality that all, or a specific subset of, authenticated nodes in an IP network can implement.
When the Join Proxy functionality is enabled in a node, it can help a neighboring Pledge securely onboard the network.

The Join Proxy performs relaying of UDP packets from the Pledge to the intended Registrar, and 
relaying of the subsequent return packets.
An authenticated Join Proxy can discover the routable IP address of the Registrar, as specified in this document.
Future methods of Registrar discovery can also be easily added.

The Join Proxy acts as a packet-by-packet proxy for UDP packets between Pledge and Registrar.
The cBRSKI protocol between Pledge and Registrar {{cBRSKI}} which this Join Proxy supports
uses UDP messages with DTLS-encrypted CoAP payloads, but the Join Proxy as described here is unaware
of these payloads.
The Join Proxy solution can therefore be easily extended to work for other UDP-based protocols, 
as long as these protocols are agnostic to (or can be made to work with) the change of the IP and UDP headers 
that is performed by the Join Proxy.

In summary, the following steps are typically taken for the onboarding process of a Pledge:

1. Join Proxies in the network learn the IP address and UDP port of the Registrar.
2. A new Pledge arrives: it discovers one or more Join Proxies and selects one.
3. The Pledge sends a link-local UDP message to the selected Join Proxy.
4. The Join Proxy relays the message to the Registrar (and port) discovered in step 1.
5. The Registrar sends a response UDP message back to the Join Proxy.
6. The Join Proxy relays the message back to the Pledge.
7. Step 3 to 6 repeat as needed, for multiple messages, to complete the onboarding protocol.

To reach the Registrar in step 4, the Join Proxy needs to be either configured with a Registrar address or 
needs to dynamically discover a Registrar as detailed in {{discovery-by-jp}}. 
This configuration/discovery is specified here as step 1. 
Alternatively, in case of automated discovery it can also happen in step 4 -- at the moment that the Join Proxy has 
data to send to the Registrar.
For step 1, this specification does not specify how a Join Proxy selects a Registrar when it discovers two or more.
That is the subject of future work.

## Solution for Mesh Networks Formed using cBRSKI

The Join Proxy has been specifically designed to set up entire 6LoWPAN mesh networks using cBRSKI onboarding.
This section outlines how this process can work and highlights the role that the Join Proxy plays in forming the mesh
network.

Typically, the first node to be set up is a 6LoWPAN Border Router (6LBR) which will form the new mesh network and 
decide on the network's configuration. The 6LBR may be configured for this using for example one of the below methods.
Multiple methods may be used within the scope of a single installation.

1. Manual administratvie configuration
2. Use non-constrained BRSKI {{RFC8995}} to automatically onboard over its high-speed network interface when it gets powered on.
3. Use cBRSKI {{cBRSKI}} to automatically onboard over its high-speed network interface when it gets powered on.

When a new mesh network is created by the 6LBR, it requires an active Registrar that is reachable via IP by 6LBR before 
more Pledges can be onboarded. 
Once cBRSKI onboarding is enabled (either administratively, or automatically) on the 6BLR, it helps     
onboard 6LoWPAN-enabled Pledges via its 6LoWPAN network interface.
This 6LBR may host the cBRSKI Registrar itself, but the Registrar may also be hosted 
elsewhere on the (non-mesh) installation network.

At the time the Registrar and the 6LBR are enabled, there may be zero Pledges, or there may be already one or more 
installed and powered Pledges waiting - periodically attempting to discover a Join Proxy for cBRSKI onboarding over 
their 6LoWPAN network interface.

A Registrar hosted on the 6LBR will, per {{cBRSKI}}, make itself discoverable as a Join Proxy so that Pledges can 
use it for cBRSKI onboarding.
Note that only some of Pledges waiting to onboard may be direct neighbors of the Registrar/6LBR. 
Other Pledges would need their traffic to be relayed by constrained Join Proxies across one or more enrolled mesh 
devices (6LR) in order to reach the Registrar/6LBR.
For this purpose, all or some of the enrolled Pledges should start to act as Join Proxies themselves.

The desired end state of the installation includes a network with a Registrar and all Pledges successfully enrolled in the 
network domain and connected to one of the 6LoWPAN mesh networks that are part of the domain. 
New Pledges may also be added by future 
network maintenance work on the installation.

Pledges can only employ link-local communication until they are enrolled, at which point they stop being a "Pledge". 
A Pledge will regularly try to discover a Join Proxy with link-local discovery requests, as defined in {{cBRSKI}}. 
The Pledges that are neighbors of the Registrar will discover the Registrar itself (as it is posing as a Join Proxy) 
and will be enrolled first using cBRSKI. 
The Pledges that are not a neighbor of the Registrar will first wait and will eventually discover a Join Proxy so 
that they can be enrolled also with cBRSKI. 
While this continues, more and more Join Proxies with a larger hop distance to the Registrar will emerge. 
The mesh network auto-configured in this way, such that at the end of the enrollment process, all Pledges are enrolled.


# Join Proxy specification {#jp-spec}

A Join Proxy can operate in two modes:

   1. Stateful mode
   2. Stateless mode

The advantages and disadvantages of the two modes are presented in {{jp-comparison}}.

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

Independent of the mode of the Join Proxy, the Pledge first discovers (see {{discovery-by-pledge}})
and selects the most appropriate Join Proxy.
From the discovery, the Pledge learns the Join Proxy's link-local IP address and UDP join-port.
Details of this discovery are defined by the onboarding protocol.
For cBRSKI, this is defined in {{Section 10 of cBRSKI}}.

## Notation {#ip-port-notation}

The following notation is used in this section in both text and figures:

* The colon (`:`) separates IP address and port number (`<IP>:<port>`).
* `IP_P` denotes the link-local IP address of the Pledge. For simplicity, it is assumed here that the Pledge only has 
   one network interface.
* `IP_R` denotes the routable IP address of the Registrar.
* `IP_Jl` denotes the link-local IP address of the Join Proxy on the interface that connects it to the Pledge.
* `IP_Jr` denotes the routable IP address of the Join Proxy.
* `p_P` denotes the UDP port used by the Pledge for its onboarding/joining protocol, which may be cBRSKI. The Pledge 
   acts in a UDP client role, specifically as a DTLS client for the case of cBRSKI.
* `p_Jl` denotes the join-port of the Join Proxy.
* `p_Jr` denotes the client port of the Join Proxy that it uses to forward packets to the Registrar.
* `p_Ra` denotes the server port of the Registrar on which it serves the onboarding protocol, such as cBRSKI.
* `p_Rj` denotes the server port of the Registrar on which it serves the JPY protocol.
* `JPY[H( ),C( )]` denotes a JPY message, as defined by the JPY protocol, with header H and content C indicated in 
   between the parentheses.

## Stateful Join Proxy {#stateful}

In stateful mode, the Join Proxy acts as a UDP circuit proxy that does not
change the UDP payload (called "data octets" in {{RFC768}}) but only rewrites
the IP and UDP headers of each UDP packet it forwards between a Pledge and a Registrar.

The UDP flow mapping state maintained by the Join Proxy can be represented as a list of tuples, one for each 
active Pledge, as follows:

~~~~aasvg
    Local connection UDP state      Routable connection UDP state
      (IP_P:p_P, IP_Jl:p_Jl)  <===>   (IP_Jr:p_Jr, IP_R:p_r)
~~~~

In case a Join Proxy has multiple network interfaces that accept Pledges, an interface identifier needs to be added 
on the left state item. If a Join Proxy has multiple network interfaces to connect to (one or more) Registrars, an 
interface identifier needs to be added to the right state item. Both of these are not shown further in this section, 
for better readability.

Because UDP does not have the notion of a connection, the use of "UDP connection" in this document
refers to a pseudo-connection, whose establishment on the Join Proxy is solely
triggered by receipt of a UDP packet from a Pledge with an `IP_P:p_P` link-local source and `IP_Jl:p_Jl` link-local 
destination for which no mapping state exists, and that is terminated by a connection expiry timer.

{{fig-statefull2}} depicts an example DTLS session via the Join Proxy, to show how this state is used in practice.
In this case the Join Proxy knows the IP address of the Registrar (`IP_R`) and the default CoAPS port (5684) on the 
Registrar is used to access cBRSKI resources.

~~~~aasvg
+------------+------------+-------------+--------------------------+
|   Pledge   | Join Proxy |  Registrar  |        UDP Message       |
|    (P)     |     (J)    |    (R)      | Src_IP:port | Dst_IP:port|
+------------+------------+-------------+-------------+------------+
|     ---ClientHello-->                 |   IP_P:p_P  | IP_Jl:p_Jl |
|                   ---ClientHello-->   |   IP_Jr:p_Jr| IP_R:5684  |
|                                       |             |            |
|                    <--ServerHello---  |   IP_R:5684 | IP_Jr:p_Jr |
|                            :          |             |            |
|       <--ServerHello---    :          |   IP_Jl:p_Jl| IP_P:p_P   |
|               :            :          |       :     |    :       |
|              [DTLS messages]          |       :     |    :       |
|               :            :          |       :     |    :       |
|       ---Finished-->       :          |   IP_P:p_P  | IP_Jl:p_Jl |
|                     ---Finished-->    |   IP_Jr:p_Jr| IP_R:5684  |
|                                       |             |            |
|                      <--Finished---   |   IP_R:5684 | IP_Jr:p_Jr |
|        <--Finished---                 |   IP_Jl:p_Jl| IP_P:p_P   |
|              :             :          |      :      |     :      |
+---------------------------------------+-------------+------------+
~~~~
{: #fig-statefull2 title='Example of the message flow of a DTLS session via a stateful Join Proxy.' align="left"}

The Join Proxy MUST allocate a unique `IP_Jr:p_Jr` for every unique Pledge that it serves. This is typically done 
by selecting a unique available port `P_Jr` for each Pledge. 
Doing so enables the Join Proxy to correctly map the 
UDP packets received from the Registrar back to the corresponding Pledges. 
Also, it enables the Registrar to correctly distinguish multiple DTLS clients by means of IP-address/port tuples.

The default timeout for clearing the state for a Pledge MUST be 30 seconds after the last relayed packet was sent on 
a UDP connection associated to that Pledge, in either direction.
The default timeout MAY be overridden by another value that is either configured, or discovered in some way.

When a Join Proxy receives an ICMP {{RFC792}} / ICMPv6 {{RFC4443}} error from the Registrar, this may signal a 
permanent change of the Registrar's IP address and/or port, or it may signal a temporary disruption of the network. 
In such case, the Join Proxy SHOULD send an equivalent ICMP error message (with same Type and Code) to the Pledge.
The specific Pledge can be determined from the IP/UDP header information that is contained in the ICMP error message 
body, if included.
In case the ICMP message body is empty, or insufficient information is included there, the Join Proxy does not send 
the ICMP error message to the Pledge because the intended recipient cannot be determined.

To protect itself and the Registrar against malfunctioning Pledges and/or denial of service (DoS) attacks, 
the Join Proxy SHOULD limit the number of simultaneous state tuples for a given `IP_p` to 2, 
and it SHOULD the number of simultaneous state tuples per network interface to 10. 

When a new Pledge connection is received and the Join Proxy is unable to build new mapping state for it, for example due to 
the above limits, the Join Proxy SHOULD return an ICMP Type 1 "Destination Unreachable" error message 
with Code 1, "Communication with destination administratively prohibited".

## Stateless Join Proxy {#jpy-encapsulation-protocol}

Stateless Join Proxy operation eliminates the need and complexity to
maintain per Pledge UDP connection mapping state on the proxy and the machinery to build, maintain and
remove this mapping state.
It also removes the need to protect this mapping state against DoS attacks and may also reduce memory and 
CPU requirements on the proxy.

Stateless Join Proxy operations work by introducing a new JPY message used in communication between Proxy and Registrar.
This message will store the state. It consists of two parts:

  * Header (H) field: contains state information about the Pledge (P) such as the link-local IP address and UDP port.
  * Contents (C) field: the original UDP payload (data octets according to {{RFC768}}) received from the Pledge, 
    or destined to the Pledge.

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

When the Registrar receives such a JPY message, it MUST treat the Header H as a single additional opaque identifier 
of all packets associated to a UDP connection with a Pledge.
Whereas in the stateful proxy case, all packets with the same tuple `(IP_Jr:p_Jr, IP_R:p_Ra)` belong to a single 
Pledge's UDP connection,
in the stateless proxy case only the packets with the same tuple `(IP_Jr:p_Jr, IP_R:p_Rj, H)` belong to a single 
Pledge's UDP connection.
The JPY message Content field contains the UDP payload of the packet for that Pledge's UDP connection. 
Packets with different header H belong to different Pledge's UDP connections.

In the stateless mode, the Registrar MUST offer the JPY protocol on a discoverable UDP port (`p_Rj`). 
There is no default port number available for the JPY protocol, unlike in the stateful mode where the Registrar 
can host all its services on the CoAPS default port.

~~~~aasvg
+--------------+------------+---------------+-----------------------+
|    Pledge    | Join Proxy |    Registrar  |      UDP Message      |
|     (P)      |     (J)    |      (R)      |Src_IP:port|Dst_IP:port|
+--------------+------------+---------------+-----------+-----------+
|   ---ClientHello--->                      | IP_P:p_P  |IP_Jl:p_Jl |
|                   ---JPY[H(IP_P:p_P), --> | IP_Jr:p_Jr|IP_R:p_Rj  |
|                          C(ClientHello)]  |           |           |
|                   <--JPY[H(IP_P:p_P), --- | IP_R:p_Rj |IP_Jr:p_Jr |
|                          C(ServerHello)]  |           |           |
|   <---ServerHello---                      | IP_Jl:p_Jl|IP_P:p_P   |
|              :                            |     :     |    :      |
|          [ DTLS messages ]                |     :     |    :      |
|              :                            |     :     |    :      |
|   ---Finished--->                         | IP_P:p_P  |IP_Jr:p_Jr |
|                   ---JPY[H(IP_P:p_P), --> | IP_Jl:p_Jl|IP_R:p_Rj  |
|                          C(Finished)]     |           |           |
|                   <--JPY[H(IP_P:p_P), --- | IP_R:p_Rj |IP_Jr:p_Jr |
|                          C(Finished)]     |           |           |
|   <---Finished--                          | IP_Jl:p_Jl|IP_P:p_P   |
|              :                            |     :     |    :      |
+-------------------------------------------+-----------+-----------+
~~~~
{: #fig-stateless title='Example of the message flow of a DTLS session via a stateless Join Proxy.' align="left"}

When a Join Proxy receives an ICMP {{RFC792}} / ICMPv6 {{RFC4443}} error from the Registrar, this may signal a 
permanent change of the Registrar's IP address and/or port, or it may signal a temporary disruption of the network. 

Unlike a stateful Join Proxy, the stateless Join Proxy cannot determine the Pledge to which this ICMP error should 
be mapped, because the JPY header containing this information is not included in the ICMP error message.
Therefore, it cannot inform the Pledge of the error that occurred.

## JPY Message Structure {#stateless-jpy}

The JPY message is used by a stateless Join Proxy to carry required state information in the relayed UDP messages, 
such that it does not need to store this state in memory.
JPY messages are carried directly over the UDP layer.
So, there is no CoAP or DTLS layer used between the JPY messages and the UDP layer.

Each JPY message consists of one CBOR {{RFC8949}} array with 2 elements:

   1. The Header (H) with the Join Proxy's per-message state data: wrapped in a CBOR byte string. 
      The byte string including its related CBOR encoding SHOULD be at most 34 bytes.
   2. The Content (C) field: the binary (DTLS) payload being relayed, wrapped in a CBOR byte string. 
      The payload is encrypted. 
      The Join Proxy cannot decrypt it and therefore has no knowledge of any transported (CoAP) messages, or the URI
      paths or media types within the CoAP messages.

Using CDDL {{RFC8610}}, the CBOR array that constitutes the JPY message can be formally defined as:

~~~
    jpy_message =
    [
       jpy_header  : bstr,
       jpy_content : bstr
    ]
~~~
{: #fig-cddl title='CDDL representation of a JPY message' align="left"}

The jpy_header state data is to be reflected (unmodified) by the Registrar when sending return JPY messages to the Join Proxy.
The header's internal representation is not standardized: it can be constructed by the Join Proxy in whatever way.
It is to be used by the Join Proxy to record state for the included jpy_content field, which includes the 
information which Pledge the data in jpy_content came from.

The Join Proxy SHOULD encrypt the state data prior to wrapping it in a CBOR byte string in jpy_header. 
It SHOULD be encrypted with a symmetric key known only to the Join Proxy itself.
This key need not persist on a long-term basis, and MAY be changed periodically.

This state data stored in the JPY message is similar to the "state object" mechanism described in {{Section 7.1 of RFC9031}}.
However, since the CoAP protocol layer (if any) is inside the DTLS layer, so end-to-end encrypted between the Pledge and the 
Registrar, it is not possible for the Join Proxy to act as a CoAP proxy per {{Section 5.7 of RFC7252}}.

For the JPY messages sent to the Registrar, the Join Proxy SHOULD use the same UDP source port and IP source address 
for the JPY messages sent on behalf of all Pledges.
Although a Join Proxy MAY vary the UDP source port, doing so creates more local state.
A Join Proxy with multiple CPUs (unlikely in a constrained system, but possible) could, for instance, use 
different UDP source port numbers to demultiplex connections across CPUs.

### Example Format for the Join Proxy's Header Data

A typical JPY message header format, prior to encryption, could be constructed using the following CDDL grammar.
This is illustrative only: the format of the data inside `jpy_header` is not subject to standardization and may vary 
across Pledges.

~~~~
    jpy_header_plaintext = [
      family:  uint .bits 1,
      ifindex: uint .bits 8,
      srcport: uint .bits 16,
      iid:     bstr .bits 64,
    ]
~~~~

This results in a total plaintext size of 96 bits, or 12 bytes.
The data structure stores the Pledge's UDP source port (srcport), the IID bits of the Pledge's originating IPv6 link-Local 
address (iid), the IPv4/IPv6 family (as a single bit) and an interface index (ifindex) to provide the link-local scope 
for the case that the Join Proxy has multiple network interfaces.
This size fits nicely into a single AES128 CBC block for instance, resulting in a 16 byte block of encrypted state data,
`jpy_header_ciphertext`.
This `jpy_header_ciphertext` data is then wrapped in a CBOR byte string to form the `jpy_header` element.
So for the example `jpy_header_plaintext` of 12 bytes, we get a `jpy_header_ciphertext` of 16 bytes, and finally 
a jpy_header of 17 bytes which adds a 1-byte overhead to encode the data as a CBOR byte string.

Note: when IPv6 is used only the lower 64-bits of the source IPv6 address need to be recorded,  
because they must be by design all IPv6 link-Local addresses, so the upper 64-bits are just "fe80::" and can be elided. 
For IPv4, a link-Local IPv4 address {{RFC3927}} would be used, and it would always fit into the 64 bits of the `iid`  
field.
On media where the Interface IDentifier (IID) is not 64-bits, a different field size for `iid` will be necessary.

The Join Proxy MUST maintain the same context data for all communications from the same Pledge UDP source port.
This implies that the encryption key used either does not change during the onboarding attempt of the Pledge, 
or that when it does, it is acceptable to break any onboarding connections that have not yet completed.

If using a header data format as defined above, it should be easy for the Join Proxy to meet this requirement 
without maintaining any local state about the Pledge.

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


# Discovery {#discovery}

## Join Proxy Discovers Registrar  {#discovery-by-jp}

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

## Pledge discovers Join Proxy {#discovery-by-pledge}

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


# Comparison of Stateless and Stateful Modes {#jp-comparison}

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
{{I-D.richardson-anima-state-for-joinrouter}} outlined the various options for building a constrained Join Proxy.

Many thanks for the comments by {{{Bill Atwood}}}, {{{Carsten Bormann}}}, {{{Brian Carpenter}}}, {{{Spencer Dawkins}}}, {{{Esko Dijk}}}, {{{Toerless Eckert}}}, {{{Russ Housley}}}, {{{Ines Robles}}}, {{{Rich Salz}}}, {{{Jürgen Schönwälder}}}, {{{Mališa Vučinić}}}, and {{{Rob Wilton}}}.


# Contributors
This document is very much inspired by text published earlier in {{I-D.kumar-dice-dtls-relay}}.
{{{Sandeep Kumar}}}, {{{Sye loong Keoh}}}, and {{{Oscar Garcia-Morchon}}} are the co-authors of this document.
Their draft text has served as a basis for this document.


# Changelog
-15 to -16

       * Applied review comments of Bill Atwood of 2024-05-21.
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
