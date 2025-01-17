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
  RFC9147:
  RFC9148:
  cBRSKI: I-D.ietf-anima-constrained-voucher
  ieee802-1AR:
    target: "https://standards.ieee.org/ieee/802.1AR/6995/"
    title: "IEEE 802.1AR Secure Device Identity"
    author:
    rc: "IEEE Standards Association"
    date: 2018
  
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
  RFC7595:
  RFC7959:
  RFC8610:
  RFC8974:
  RFC9031:
  I-D.ietf-anima-brski-discovery:
  I-D.kumar-dice-dtls-relay:
  I-D.richardson-anima-state-for-joinrouter:

--- abstract

This document extends the constrained Bootstrapping Remote Secure Key Infrastructures (cBRSKI) onboarding protocol by 
adding a new network function, the constrained Join Proxy.
This function can be implemented by a constrained node {{RFC7228}}. 
The goal of the Join Proxy is to help new constrained nodes ("Pledges") securely onboard into a new IP network using the 
cBRSKI protocol.
It acts as a circuit proxy for User Datagram Protocol (UDP) packets that carry the onboarding messages.
The solution is extendible to support other UDP-based onboarding protocols as well.
The Join Proxy functionality is designed for use in constrained networks {{RFC7228}}, including IPv6 over Low-Power Wireless Personal Area Networks (6LoWPAN) 
{{RFC4944}} based mesh networks in which the onboarding authority server ("Registrar") may be multiple IP hops away from a Pledge.
Despite this distance, the Pledge only needs to use link-local UDP communication to complete cBRSKI onboarding.
Two modes of Join Proxy operation are defined, stateless and stateful, to allow implementers to make different trade-offs 
regarding resource usage, implementation complexity and security.

--- middle

# Introduction

The Bootstrapping Remote Secure Key Infrastructure (BRSKI) protocol described in {{RFC8995}}
provides a solution for a secure zero-touch (automated) bootstrap of new, unconfigured devices.
In the context of BRSKI, new devices, called "Pledges", are equipped with a factory-installed 
Initial Device Identifier (IDevID) {{ieee802-1AR}}, and are enrolled into a network.
BRSKI makes use of Enrollment over Secure Transport (EST) {{RFC7030}}
with {{RFC8366bis}} signed vouchers to securely enroll devices.
A Registrar provides the trust anchor of the network domain to which a Pledge enrolls.

{{cBRSKI}} defines a version of BRSKI that is suitable for constrained nodes ({{RFC7228}}) and for operation 
on constrained networks ({{RFC7228}}) including Low-Power and Lossy Networks (LLN) {{RFC7102}}.
It uses Constrained Application Protocol (CoAP) {{RFC7252}} messages secured by  Datagram Transport Layer Security 
(DTLS) {{RFC9147}} to implement the BRSKI functions defined by {{RFC8995}}.

In this document, cBRSKI is extended such that a cBRSKI Pledge can connect to a Registrar via a constrained Join Proxy.
In particular, this solution is intended to support 
IPv6 over Low-Power Wireless Personal Area Networks (6LoWPAN) {{RFC4944}} mesh networks.
6TiSCH networks are not in scope of this document since these use the CoJP {{RFC9031}} proxy mechanism.

The Join Proxy as specified in this document is one of the Join Proxy
options referred to in {{Section 2.5.2 of RFC8995}} as future work.

However, in IP networks that require node authentication, such as those using 6LoWPAN {{RFC4944}},
data to and from the Pledge will not be routable over the IP network 
before it is properly authenticated to the network.
A new Pledge can initially only use a link-local IPv6 address to communicate with a
mesh neighbor {{RFC6775}} until it receives the necessary network configuration parameters.

Before it can receive these parameters, the Pledge needs to be authenticated and authorized to onboard the  
network. This is done in cBRSKI through an end-to-end encrypted DTLS session with a domain Registrar. 

When this Registrar is not a direct (link-local) neighbor of the Pledge but several hops away, the Pledge 
needs to discover a link-local neighbor that is operating as a constrained Join Proxy, which helps  
forward the DTLS messages of the session between Pledge and Registrar.

Because the Join Proxy is a regular network node that has already been onboarded onto the network, it can send 
IP packets to the Registrar which are then routed over one or more hops over the mesh network -- and potentially 
over other IP networks too, before reaching the Registrar.
Likewise, the Registrar sends its response IP packets which are routed back to the Join Proxy over the mesh network.

Once a Pledge has enrolled onto the network in this manner, it can optionally be configured itself as a new constrained 
Join Proxy. In this role it can help other Pledges perform the cBRSKI onboarding process.

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

The term "Join Proxy" is used in this document with the same definition as in {{RFC8995}}. 
However, in this document it refers specifically to a Join Proxy that can support Pledges to onboard using a 
UDP-based protocol, such as the cBRSKI protocol {{cBRSKI}}. 
This protocol operates over an end-to-end secured DTLS session between a Pledge and a cBRSKI Registrar.

The acronym "JPY" is used to refer to a new protocol and JPY message format defined by this document. 
The message can be seen as a "Join Proxy Yoke": connecting two data items and letting these travel together over a network.

Because UDP does not have the notion of a connection, the term "UDP connection" in this document 
refers to a pseudo-connection, whose establishment on the Join Proxy is triggered by receipt of a first UDP packet from a new 
Pledge source. 

The term "endpoint" is used as defined in {{RFC7252}}.

The terms "6LoWPAN Router" (6LR), "6LoWPAN Border Router" (6LBR) and "6LoWPAN link" are used as defined in {{RFC6775}}.

Details of the IP address and port notation used in the Join Proxy specification are provided in {{ip-port-notation}}.


# Join Proxy Problem Statement and Solution

## Problem Statement

As depicted in {{fig-net}}, the Pledge (P), in a network such as a 6LoWPAN {{RFC4944}} mesh network  
 can be more than one hop away from the Registrar (R) and it is not yet authenticated to the network.
Also, the Pledge does not possess any key material to encrypt or decrypt link-layer data transmissions.

In this situation, the Pledge can only communicate one-hop to its neighbors, such as the constrained Join Proxy (J), 
using link-local IPv6 addresses and using no link-layer encryption.
However, the Pledge needs to communicate with end-to-end security with a Registrar to authenticate and obtain its 
domain identity/credentials.
In the case of cBRSKI, the domain identity is an X.509 certificate. Domain credentials may include key material for 
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
{: #fig-net title='Multi-hop cBRSKI onboarding scenario in a 6LoWPAN mesh network' align="left"}

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
performed by the Join Proxy.

In summary, the following steps are typically taken for the onboarding process of a Pledge:

1. Join Proxies in the network learn the IP address and UDP port of the Registrar.
2. A new Pledge arrives: it discovers one or more Join Proxies and selects one.
3. The Pledge sends a link-local UDP message to the selected Join Proxy.
4. The Join Proxy relays the message to the Registrar (and port) discovered in step 1.
5. The Registrar sends a response UDP message back to the Join Proxy.
6. The Join Proxy relays the message back to the Pledge.
7. Step 3 to 6 repeat as needed, for multiple messages, to complete the onboarding protocol.
8. The Pledge uses its obtained domain identity/credentials to join the domain network.

To reach the Registrar in step 4, the Join Proxy needs to be either configured with a Registrar address or 
needs to dynamically discover a Registrar as detailed in {{discovery-by-jp}}. 
This configuration/discovery is specified here as step 1. 
Alternatively, in case of automated discovery it can also happen on-demand in step 4, at the moment that the Join Proxy has 
data to send to the Registrar.
For step 1, it is out of scope how a Join Proxy selects a Registrar when it discovers two or more.
That is the subject of future work.

## Forming 6LoWPAN Mesh Networks with cBRSKI

The Join Proxy has been specifically designed to set up an entire 6LoWPAN mesh network using cBRSKI onboarding.
This section outlines how this process works and highlights the role that the Join Proxy plays in forming the mesh
network.

Typically, the first node to be set up is a 6LoWPAN Border Router (6LBR) which will form the new mesh network and 
decide on the network's configuration. The 6LBR may be configured using for example one of the below methods.
Note that multiple methods may be used within the scope of a single installation.

1. Manual administrative configuration
2. Use non-constrained BRSKI {{RFC8995}} to automatically onboard over its high-speed network interface when it gets powered on.
3. Use cBRSKI {{cBRSKI}} to automatically onboard over its high-speed network interface when it gets powered on.

Once the 6LBR is enabled, it requires an active Registrar reachable via IP communication to onboard any Pledges.
Once cBRSKI onboarding is enabled (either administratively, or automatically) on the 6BLR, it can support      
the onboarding of 6LoWPAN-enabled Pledges, via its 6LoWPAN network interface.
This 6LBR may host the cBRSKI Registrar itself, but the Registrar may also be hosted 
elsewhere on the installation network.

At the time the Registrar and the 6LBR are enabled, there may be zero Pledges, or there may be already one or more 
installed and powered Pledges waiting - periodically attempting to discover a Join Proxy over 
their 6LoWPAN network interface.

A Registrar hosted on the 6LBR will, per {{cBRSKI}}, make itself discoverable as a Join Proxy so that Pledges can 
use it for cBRSKI onboarding over a 6LoWPAN link (one hop).
Note that only some of Pledges waiting to onboard may be direct neighbors of the Registrar/6LBR. 
Other Pledges would need their traffic to be relayed by Join Proxies across one or more enrolled mesh 
devices (6LR, see {{fig-net}}) in order to reach the Registrar/6LBR.
For this purpose, all or a subset of the enrolled Pledges start to act as Join Proxies themselves.
Which subset is selected, and when the Join Proxy function is enabled by a node, is out of scope of this document.

The desired end state of the installation includes a network with a Registrar and all Pledges successfully enrolled in the 
network domain and connected to one of the 6LoWPAN mesh networks that are part of the installation. 
New Pledges may also be added by future network maintenance work on the installation.

Pledges employ link-local communication until they are enrolled, at which point they stop being a "Pledge". 
A Pledge will periodically try to discover a Join Proxy using for example link-local discovery requests, as defined in {{cBRSKI}}. 
Pledges that are neighbors of the Registrar will discover the Registrar itself (which is posing as a Join Proxy) 
and will be enrolled first, using cBRSKI. 
The Pledges that are not a neighbor of the Registrar will at first fail to find a Join Proxy.
Later on, they will eventually discover a Join Proxy so that they can be enrolled with cBRSKI too. 
While this continues, more and more Join Proxies with a larger hop distance to the Registrar will emerge. 
The mesh network auto-configures in this way, such that at the end of the onboarding process, all Pledges are enrolled 
into the network domain and connected to the mesh network.


# Join Proxy Specification {#jp-spec}

A Join Proxy can operate in two modes:

1. Stateful mode
2. Stateless mode

The advantages and disadvantages of the two modes are presented in {{jp-comparison}}.

## Mode Implementation and Configuration Requirements

For a Join Proxy implementation on a node, there are three possible scenarios:

1. Both stateful and stateless modes are implemented. The Join Proxy can switch between these modes, depending on 
   configuration.
2. Only stateful mode is implemented. 
3. Only stateless mode is implemented.

An application profile or ecosystem standard that integrates the Join Proxy functionality as defined in this 
document MAY define any of these three options. 
In particular, option 2 or 3 has the advantage of reducing code size and testing efforts, when all devices under 
the application profile/standard adhere to the same choice.

A generic Join Proxy that is not adhering to such an application profile/standard MUST implement both modes. 

A cBRSKI Registrar by design necessarily implements the stateful mode, and it SHOULD implement support for 
Join Proxies operating in the stateless mode. The exception case here is a cBRSKI Registrar that is implemented for a 
particular dedicated application profile/standard which specifies only the stateful mode.

If a Join Proxy implements both modes, then it MUST use only the mode that is currently configured for the network 
(by a method or profile outside the scope of this document) or the mode individually configured for the device.
If the mode is not configured, the device MUST NOT operate as a Join Proxy.

For a Join Proxy to be operational, the node on which it is running has to be
able to talk to a Registrar (exchange UDP messages with it). Establishing this connectivity can happen
fully automatically if the Join Proxy node first enrolls itself as a Pledge,
and then discovers the Registrar IP address/port and if applicable its desired mode of operation (stateful or stateless), 
through a discovery mechanism (see {{discovery}}).
Other methods, such as provisioning the Join Proxy are out of scope for this document
but equally feasible.

Independent of the mode of the Join Proxy, the Pledge first discovers (see {{discovery-by-pledge}})
and selects the most appropriate Join Proxy.
From the discovery result, the Pledge learns a Join Proxy's link-local IP address and UDP join-port.
Details of this discovery are defined by the onboarding protocol and are not in scope of this document.
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
* `p_R` denotes the server port of the Registrar on which it serves the onboarding protocol, such as cBRSKI.
* `p_Rj` denotes the server port of the Registrar on which it serves the JPY protocol.
* `JPY[H( ),C( )]` denotes a JPY message, as defined by the JPY protocol, with header H and content C indicated in 
   between the parentheses.

## Stateful Join Proxy {#stateful-jp}

In stateful mode, the Join Proxy acts as a UDP circuit proxy that does not
change the UDP payload (called "data octets" in {{RFC768}}) but only rewrites
the IP and UDP headers of each UDP packet it forwards between a Pledge and a Registrar.

The UDP flow mapping state maintained by the Join Proxy can be represented as a list of tuples, one for each 
active Pledge, as follows:

~~~~aasvg
  Local UDP state              Routable UDP state     Time state
 (IP_P:p_P, IP_Jl:p_Jl) <===> (IP_Jr:p_Jr, IP_R:p_R)  (Exp-timer)
~~~~

In case a Join Proxy has multiple network interfaces that accept Pledges, an interface identifier needs to be added 
on the leftmost tuple component. If a Join Proxy has multiple network interfaces to connect to (one or more) Registrars, an 
interface identifier needs to be added to the rightmost tuple component.
Both of these are not shown further in this section, for better readability.

The establishment of the UDP connection state on the Join Proxy is solely triggered by receipt of a UDP packet from 
a Pledge with an `IP_P:p_P` link-local source and `IP_Jl:p_Jl` link-local 
destination for which no mapping state exists, and that is terminated by a connection expiry timer.

{{fig-statefull2}} depicts an example DTLS session via the Join Proxy, to show how this state is used in practice.
In this case the Join Proxy knows the IP address of the Registrar (`IP_R`) and the default CoAPS port (`P_R` = `5684`) 
on the Registrar is used to access cBRSKI resources.

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
Also, it enables the Registrar to correctly distinguish multiple DTLS clients by means of IP address/port tuples.

The default timeout for clearing the state for a Pledge MUST be 30 seconds after the last relayed packet was sent on 
a UDP connection associated to that Pledge, in either direction.
The default timeout MAY be overridden by another value that is either configured, or discovered in some way out of 
scope of this document.

When a Join Proxy receives an ICMP {{RFC792}} / ICMPv6 {{RFC4443}} error from the Registrar, this may signal a 
permanent change of the Registrar's IP address and/or port, or it may signal a temporary disruption of the network. 
In such case, the Join Proxy SHOULD send an equivalent ICMP error message (with same Type and Code) to the Pledge.
The specific Pledge can be determined from the IP/UDP header information that is contained in the ICMP error message 
body, if included.
In case the ICMP message body is empty, or insufficient information is included there, the Join Proxy does not send 
the ICMP error message to the Pledge because the intended recipient cannot be determined.

To protect itself and the Registrar against malfunctioning Pledges and/or denial of service (DoS) attacks, 
the Join Proxy SHOULD limit the number of simultaneous state tuples for a given `IP_p` to at most 2, 
and it SHOULD limit the number of simultaneous state tuples per network interface to at most 10. 

When a new Pledge connection is received and the Join Proxy is unable to build new mapping state for it, for example due to 
the above limits, the Join Proxy SHOULD return an ICMP Type 1 "Destination Unreachable" error message 
with Code 1, "Communication with destination administratively prohibited".

## Stateless Join Proxy {#stateless-jp}

Stateless Join Proxy operation eliminates the need and complexity to
maintain per-Pledge UDP connection mapping state on the proxy and the machinery to build, maintain and
remove this mapping state.
It also removes the need to protect this mapping state against DoS attacks and may also reduce memory and 
CPU requirements on the proxy.

Stateless Join Proxy operations work by introducing a new JPY message used in communication between Proxy and Registrar.
This message will store the state "in the network".
It consists of two parts:

  * Header (H) field: contains state information about the Pledge (P) such as the link-local IP address and UDP port.
  * Contents (C) field: the original UDP payload (data octets according to {{RFC768}}) received from the Pledge, 
    or destined to the Pledge.

When the join proxy receives a UDP message from a Pledge, it encodes the Pledge's
link-local IP address, interface ID and UDP (source) port of the UDP packet into the Header field
and the UDP payload into the Contents field and sends the packet to the Registrar from
a fixed source UDP port. When the Registrar sends packets for the Pledge,
it MUST return the Header field unchanged, so that the join proxy can decode the
Header to reconstruct the Pledge's link-local IP address, interace and UDP (destination) port
for the return UDP packet. 
{{fig-stateless}} shows this per-packet mapping on the join proxy for a DTLS session.

The Registrar transiently stores the Header field information.
The Registrar uses the Contents field to execute the Registrar functionality.
When the Registrar replies, it wraps its DTLS message in a JPY message and sends it back to the Join Proxy.
The Registrar SHOULD NOT assume that it can decode the Header Field of a received JPY message, it MUST simply replicate it when responding.
The Header of a reply JPY message contains the original source link-local address and port of the Pledge from the transient state stored 
earlier and the Contents field contains the DTLS payload created by the Registrar.

On receiving the JPY message, the Join Proxy retrieves the two parts.
It uses the Header field information to send a link-local UDP message containing the (DTLS) payload retrieved from the 
Contents field to a particular Pledge.

When the Registrar receives such a JPY message, it MUST treat the Header H as a single additional opaque identifier 
of all packets associated to a UDP connection with a Pledge.
Whereas in the stateful proxy case, all packets with the same 4-tuple `(IP_Jr:p_Jr, IP_R:p_R)` belong to a single 
Pledge's UDP connection,
in the stateless proxy case only the packets with the same 5-tuple `(IP_Jr:p_Jr, IP_R:p_Rj, H)` belong to a single 
Pledge's UDP connection.
The JPY message Contents field contains the UDP payload of the packet for that Pledge's UDP connection. 
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
Therefore, it cannot inform the Pledge of the specific error that occurred.

## JPY Protocol and Messages {#stateless-jpy}

JPY messages are used by a stateless Join Proxy to carry required state information in the relayed UDP messages, 
such that it does not need to store this state in memory.
JPY messages are carried directly over the UDP layer.
So, there is no CoAP or DTLS layer used between the JPY messages and the UDP layer.

A Registrar that supports the JPY protocol also uses JPY message to return relayed UDP messages to the stateless Join Proxy, 
including the state information that it needs.

### JPY Message Structure

Each JPY message consists of one CBOR {{RFC8949}} array with 2 elements:

   1. The Header (H) with the Join Proxy's per-message state data: wrapped in a CBOR byte string. 
      The state data SHOULD be at most 32 bytes.
   2. The Content (C) field: the binary (DTLS) payload being relayed, wrapped in a CBOR byte string. 
      The payload is encrypted. 
      The Join Proxy cannot decrypt it and therefore has no knowledge of any transported (CoAP) messages, or the URI
      paths or media types within the CoAP messages.

Using CDDL {{RFC8610}}, the CBOR array that constitutes the JPY message can be formally defined as:

~~~
    jpy_message =
    [
       jpy_header  : bstr,
       jpy_content : bstr,
    ]
~~~
{: #fig-cddl title='CDDL representation of a JPY message' align="left"}

The `jpy_header` state data is to be reflected (unmodified) by the Registrar when sending return JPY messages to the Join Proxy.
The header's internal representation is not standardized: it can be constructed by the Join Proxy in whatever way.
It is to be used by the Join Proxy to record state for the included `jpy_content` field, which includes the 
information which Pledge the data in `jpy_content` came from.

This state data stored in the JPY message is similar to the "state object" mechanism described in {{Section 7.1 of RFC9031}}.
However, since the CoAP protocol layer (if any) is inside the DTLS layer, so end-to-end encrypted between the Pledge and the 
Registrar, it is not possible for the Join Proxy to act as a CoAP proxy per {{Section 5.7 of RFC7252}}.

### JPY Message Port Usage

For the JPY messages sent to the Registrar, the Join Proxy SHOULD use the same UDP source port and IP source address 
for the JPY messages sent on behalf of all Pledges.

Although a Join Proxy MAY vary the UDP source port, doing so creates more local state.
A Join Proxy with multiple CPUs (unlikely in a constrained system, but possible) could, for instance, use 
different UDP source port numbers to demultiplex connections across CPUs.

### JPY Message Overhead and MTU Size

The use of the JPY message CBOR encoding adds a 3-6 byte overhead on top of the data carried within the Header and Contents fields.
The Header state data itself (up to 32 bytes) also adds an overhead on each UDP message exchanged between Join Proxy and Registrar.
Therefore, a protocol using the stateless Join Proxy MUST use (UDP) payloads that are bounded in size, such that 
the maximum payload length used minus the maximum overhead size (38 bytes) stays below the MTU size of the network. 
cBRSKI is designed to work even for the minimum IPv6 MTU of 1280 bytes, by configuring the DTLS maximum fragment length 
and using CoAP blockwise transfer for large resource transfers {{cBRSKI}}.

At the CoAP level, using the cBRSKI {{cBRSKI}} and the EST-CoAPS {{RFC9148}} protocols, 
the CoAP blockwise options {{RFC7959}} are often used to split large payloads into multiple data blocks.
The Registrar and the Pledge MUST select a block size that would allow the addition of the JPY message structure   
without violating MTU sizes.

### JPY Message Security

The Join Proxy SHOULD encrypt the state data prior to wrapping it in a CBOR byte string in jpy_header. 
It SHOULD be encrypted with a symmetric key known only to the Join Proxy itself.
This key need not persist on a long-term basis, and MAY be changed periodically.

The Join Proxy MUST maintain identical `jpy_header` data for all communications from the same Pledge and same UDP source port.
This implies that the encryption key used either does not change during the onboarding attempt of the Pledge, 
or that when it does, it is acceptable to break any onboarding connections that have not yet completed.

### Example Format for JPY Header Data

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
a `jpy_header` CBOR element of 17 bytes which includes a 1-byte overhead to encode the data as a CBOR byte string of 
length 16.

Note: when IPv6 is used only the lower 64-bits of the source IPv6 address need to be recorded,  
because they must be by design all IPv6 link-Local addresses, so the upper 64-bits are just "fe80::" and can be elided. 
For IPv4, a link-Local IPv4 address {{RFC3927}} would be used, and it would always fit into the 64 bits of the `iid` 
field.
On media where the Interface IDentifier (IID) is not 64-bits, a different field size for `iid` will be necessary.

A detailed example using this format is shown in {{examples-detailed}}. 
(TBD: update Appendix A example.)

### Processing by Registrar

On reception of a JPY message by the Registrar, the Registrar MUST verify that the number of CBOR array elements is 2 or more.
To implement this specification, only the first two elements are used.

The data in the `jpy_content` field must be provided as input to a DTLS library {{RFC9147}}, which along with the 
5-tuple defined in {{stateless-jp}} provides enough information for the Registrar to pick an appropriate (active) 
client context.
Note that the same UDP socket will need to be used for multiple DTLS flows, which is atypical for how DTLS usually uses sockets.
The `jpy_context` field can be used to select an appropriate DTLS context, as DTLS headers do not contain any kind of per-session context.
The `jpy_context` field needs to be linked to the DTLS context, and when a DTLS message need to be sent back to the 
client, the `jpy_context` needs to be included in a JPY message along with the DTLS message in the `jpy_content` field. 


# Discovery {#discovery}

## Join Proxy Discovers Registrar  {#discovery-by-jp}

In order to accommodate automatic configuration of the Join Proxy, it MUST discover the location and capabilities 
of the Registrar, in case this information is not configured already.

In BRSKI {{RFC8995}} the GeneRic Autonomic Signaling Protocol (GRASP) {{RFC8990}} protocol is supported for discovery 
of a BRSKI Registrar in an Autonomic Control Plane (ACP).
However, this document does not target the ACP context of use. 
Therefore, the definition of how to use GRASP for discovering a cBRSKI Registrar is left to future work such as 
{{I-D.ietf-anima-brski-discovery}}.

Although multiple discovery methods can be supported in principle by a single Join Proxy, this document only defines 
one default method for a Join Proxy to discover a Registrar: using CoAP resource discovery queries {{RFC6690}} {{RFC7252}}.

The CoAP discovery query to use depends on the intended mode of operation of the Join Proxy, stateless or stateful.
A stateless Join Proxy needs to discover a UDP endpoint (address and port) that can accept JPY messages.
On the other hand, a stateful Join Proxy needs to discover a single CoAPS endpoint that offers the full set of 
cBRSKI Registrar resources.

### Stateless Case

The stateless Join Proxy can discover the JPY protocol endpoint of the Registrar by sending a multicast CoAP GET 
discovery query to the "/.well-known/core" resource including a resource type (rt) query parameter "brski.rjp".
The latter CoAP resource type is defined in {{iana-rt}}.

Upon success, the return payload will contain the port of the Registrar on which the JPY protocol handler is hosted.
This exchange is shown below:

~~~~
  REQ: GET coap://[ff05::fd]/.well-known/core?rt=brski.rjp

  RES: 2.05 Content
    Content-Format: 40
    Payload:
      <coaps+jpy://[ipv6_address]:port>;rt=brski.rjp
~~~~

In this case, the multicast CoAP request is sent to the site-local "All CoAP Nodes" multicast IPv6 address 
`ff05::fd`.
In some deployments, a smaller scope than site-local is more appropriate to reduce the network load due to this 
CoAP discovery traffic.
For example, in a 6LoWPAN mesh network where a JPY protocol endpoint is always hosted on a 6LoWPAN Border Router (6LBR), 
the realm-local scope "All CoAP Nodes" address `ff03::fd` can be used.

The reason that the IPv6 address (field `ipv6_address`) is always included in the link-format result is that 
in the {{RFC6690}} link format, and per {{Section 3.2 of RFC3986}}, the authority component cannot include only a port 
number but has to include also the IP address.

The returned port is expected to process the encapsulated JPY messages described in {{stateless-jpy}}.
The scheme is `coaps+jpy`, described in {{jpyscheme}}, and not regular `coaps` because the JPY messages effectively 
form a new protocol that encapsulates CoAPS. 

### Stateful Case

The stateful Join Proxy can discover the Registrar's cBRSKI resource set by sending a multicast CoAP GET   
discovery query to the "/.well-known/core" resource including a resource type (rt) query parameter "brski".
The latter CoAP resource type is defined in {{cBRSKI}}.

Upon success, the return payload will contain the URI path and port of the Registrar on which the cBRSKI resources are hosted.
This exchange is shown below:

~~~~
  REQ: GET coap://[ff05::fd]/.well-known/core?rt=brski

  RES: 2.05 Content
    Content-Format: 40
    Payload:
      <coaps://[ipv6_address]:port/uri_path>;rt=brski
~~~~

The `port` field and its preceding colon are optionally included: if elided, the default CoAPS port 5684 is implied.
The `uri_path` field may be a single CoAP URI path resource label, or it may be a hierarchy of resources.
For efficiency, it is RECOMMENDED for the Registrar to configure the URI path as short as possible, for example `b`.

Note that the Join Proxy does not use the returned `uri_path` information, while it uses the `ipv6_address` and `port` 
information for its relaying operations.

### Examples

A Registrar with address ```2001:db8:0:abcd::52```, with the JPY protocol hosted on port 7634, 
and the CoAPS resources hosted on default port 5684 could for example reply to a multicast CoAP query of a stateful 
Join Proxy as follows:

~~~~
  REQ: GET coap://[ff05::fd]/.well-known/core?rt=brski

  RES: 2.05 Content
    Content-Format: 40
    Payload:
        <coaps://[2001:db8:0:abcd::52]/b>;rt=brski
~~~~

The same Registrar could for example reply to a multicast CoAP query of a stateless Join Proxy as follows:

~~~~
  REQ: GET coap://[ff05::fd]/.well-known/core?rt=brski.rjp

  RES: 2.05 Content
    Content-Format: 40
    Payload:
        <coaps+jpy://[2001:db8:0:abcd::52]:7634>;rt=brski.rjp
~~~~

In these examples, the Join Proxy in a specific mode of operation (stateful or stateless) only queries for those 
cBRSKI services that it minimally needs to perform the Join Proxy function in that mode.
For this reason, wildcard queries (such as `rt=brski*`) are not sent.

## Pledge Discovers Join Proxy {#discovery-by-pledge}

Regardless of whether the Join Proxy operates in stateful or stateless mode, it is discovered by the Pledge identically.
{{Section 10 of cBRSKI}} defines the details of the CoAP discovery request sent by the Pledge.

A Join Proxy implementation by default MUST support this discovery method.
If there is another method configured, by some means outside of the scope of this document, the default method MAY 
be deactivated.

The join-port of the Join Proxy is discovered by
sending a multicast GET request to "/.well-known/core" including a resource type (rt) parameter with the value "brski.jp". 
This value is defined in {{iana-rt}}.
Upon success, the return payload will contain the join-port.

The example below shows the discovery of the join-port (field `join_port`) of the Join Proxy:

~~~~
  REQ: GET coap://[ff02::fd]/.well-known/core?rt=brski.jp

  RES: 2.05 Content
    Content-Format: 40
    Payload:
      <coaps://[IP_address]:join_port>;rt=brski.jp
~~~~

Note that the `join_port` field and preceding colon MAY be absent in the discovery response: this indicates that 
the join-port is the default CoAPS port 5684.

In the returned CoRE link format document, discoverable port numbers are usually returned for the Join Proxy resource 
in the &lt;URI-Reference&gt; of the link (see {{Section 5.1 of RFC6690}} for details).


# Comparison of Stateless and Stateful Modes {#jp-comparison}

The stateful and stateless mode of operation for the Join Proxy each have their advantages and disadvantages.
This section helps operators and/or profile-specifiers to make a choice between the two modes based on 
the available device resources and network bandwidth.

| Properties  |         Stateful mode      |     Stateless mode     |
|:----------- |:---------------------------|:-----------------------|
| State Information | The Join Proxy needs additional storage to maintain mappings between the address and port number of the Pledge and those of the Registrar.  | No information is maintained by the Join Proxy. Registrar transiently stores the JPY message header.  |
|-------------
|Packet size  |The size of a relayed message is the same as the original message.   | Size of a relayed message is up to 38 bytes larger than the original: due to additional context data.  |
|-------------
|Technical complexity |The Join Proxy needs additional functions to maintain state information, and specify the source and destination addresses and ports of relayed messages. | Requires new JPY message structure (CBOR) in Join Proxy. The Registrar requires a function to process JPY messages.|
|------------
| Join Proxy Ports | Join Proxy needs discoverable join-port | Join Proxy needs discoverable join-port  |
|------------
| Registrar Ports  | Registrar can host on a single UDP port. | Registrar must host on two UDP ports: one for DTLS, one for JPY messages. |
|=============
{: #fig-comparison title='Comparison between stateful and stateless Join Proxy mode' align="left"}


# Security Considerations

For a Pledge using a Join Proxy, all the security considerations and requirements in {{Section 4.1 of RFC8995}} apply.
While doing discovery of Join Proxies, the Pledge can be deceived by malicious Join Proxy announcements.

The subsequent communication of a Pledge with a Registrar that flows via the Join Proxy is end-to-end protected by DTLS.

A malicious Join Proxy has a number of relay/routing options for messages sent by a Pledge:

   * It relays messages to a malicious Registrar. This is the same case as the presence of a "malicious Registrar" discussed in {{RFC8995}}.

   * It does not relay messages, or does not return the responses from the Registrar to the Pledge.
     This is equivalent to the case of a non-responding Registrar discussed in {{RFC8995}}.

   * It uses the returned responses of the Registrar for itself. This is very unlikely due to the DTLS security.

   * It uses the request from the Pledge to take the Pledge certificate and impersonate the Pledge. This is very 
     unlikely because that requires it to acquire the private key of the Pledge. 

A malicious Pledge may also craft and send messages to a Join Proxy:

   * It can construct an invalid DTLS or UDP message and send it to the open join-port of the Join Proxy. 
    A Join Proxy will accept the message and relay to the Registrar without checking the payload. 
    The Registrar will now parse the invalid message as DTLS protocol payload. 
    Due to the security properties of DTLS, it is highly unlikely that this malicious payload will lead to node 
    acceptance or to Registrar malfunctioning.
    The Registrar of course MUST be prepared to receive invalid and/or non-DTLS payloads in this way.
    If the Pledge uses large UDP payloads, the attacker is able to misuse network resources.
    This way, a DoS attack could be performed by using multiple malicious Pledges, or using a single device posing as 
    multiple Pledges.

For a malicious node that is a neighbor of a Join Proxy, or is a router on the path to the Registrar:

   * It may sniff the messages routed by the Join Proxy. It is very unlikely that the malicious node can decrypt the DTLS payload. 
    The malicious node may be able to read the inner data structure in the Header field, if that is not encrypted.
    This does expose some information about the Pledge attempting to join, but this can be mitigated by the Pledge 
    using a new (random) link-local address for each onboarding attempt.

A malicious node has a number of options to craft a JPY message and send it to a stateless Join Proxy:

   * It can construct an invalid JPY message. In that case, a Join Proxy might accept the message and send the Content 
     field data to a Pledge as a UDP message. Such a message could disrupt an ongoing DTLS session.
     It could also allow the attacker to access an unsecured UDP port that a Pledge may have exposed.
     For this reason, a Pledge MUST NOT accept messages on other UDP ports than its port used for onboarding while 
     an onboarding attempt is ongoing.

It should be noted here that the JPY message CBOR array and the Header field are not DTLS protected. 
When the communication between stateless Join Proxy and Registrar passes over an unsecure network, an attacker can change the 
CBOR array, and change the Header field if no encryption is used there. 
These concerns are also expressed in {{RFC8974}}. 
It is also pointed out that the encryption by the source is a local matter. 
Similar to {{RFC8974}}, the use of AES-CCM {{RFC3610}} with a 64-bit tag is recommended, combined with a sequence number and a replay window.

In some installations, layer 2 (link layer) security is provided between all node pairs of a mesh network. 
In such an environment, in case all mesh nodes are trusted, and the Registrar is also located on the mesh network, 
and on-mesh attackers are not considered, then 
encryption of the Header field as specified in this document is not necessary because the layer 2 security already protects it.


# IANA Considerations {#iana}

## Resource Type Attributes Registry {#iana-rt}

This specification registers two new Resource Type (rt=) Link Target Attributes in the 
"Resource Type (rt=) Link Target Attribute Values" registry under the "Constrained RESTful Environments (CoRE)
Parameters" registry group, per the {{RFC6690}} procedure.

    Attribute Value: brski.jp
    Description: Constrained Join Proxy for cBRSKI onboarding protocol.
    Reference:   [This RFC]

    Attribute Value: brski.rjp
    Description: cBRSKI Registrar Join Proxy endpoint that supports the 
                 JPY protocol.
    Reference:   [This RFC]

## coaps+jpy Scheme Registration {#jpyscheme}

This specification registers a new URI scheme per {{RFC7595}} under the IANA "Uniform Resource Identifier (URI) Schemes"
registry.

    Scheme name: coaps+jpy
    Status:      permanent
    Applications/protocols that use this scheme name: 
                 cBRSKI, constrained Join Proxy
    Contact:     ANIMA WG
    Change controller: IESG
    References:  [This RFC]

The scheme specification is provided below.

* Scheme syntax: identical to the "coaps" scheme defined in {{RFC7252}}.
* Scheme semantics: identical to the "coaps" scheme, except that the JPY message encapsulation mechanism described in 
  {{stateless-jpy}} of \[This RFC\] is used to transport each CoAPS UDP datagram.
* Encoding considerations: identical to the "coaps" scheme.
* Interoperability considerations: identical to the "coaps" scheme.
* Security considerations: all of the security considerations of the "coaps" scheme apply.
  Users of this scheme should be aware that as part of the intended use, a UDP message that was formed using the 
  "coaps" scheme is modified by a Join Proxy as defined by \[This RFC\] into a UDP message conforming to the 
  "coaps+jpy" scheme without the Join Proxy being able to parse/decode which CoAPS URI was originally used by the 
  sender.
  Depending on the CoAP Options used in the original CoAPS message, this operation may modify elements of the original 
  CoAPS URI (as will be reconstructed by the receiving coaps+jpy server) in a way that is unknown to the Join Proxy.

## Service Name and Transport Protocol Port Number Registry {#dns-sd-spec}

This specification registers two service names under the IANA "Service Name and Transport Protocol Port
Number" registry.

    Service Name: brski-jp
    Transport Protocol(s): udp
    Assignee:  IESG <iesg@ietf.org>
    Contact:  IESG <iesg@ietf.org>
    Description: Bootstrapping Remote Secure Key Infrastructure
                 constrained Join Proxy
    Reference:   [This RFC]

    Service Name: brski-rjp
    Transport Protocol(s): udp
    Assignee:  IESG <iesg@ietf.org>
    Contact:  IESG <iesg@ietf.org>
    Description: Bootstrapping Remote Secure Key Infrastructure
                 Registrar join-port used by stateless constrained
                 Join Proxy
    Reference:   [This RFC]


# Acknowledgements
{{I-D.richardson-anima-state-for-joinrouter}} outlined the various options for building a constrained Join Proxy.

Many thanks for the comments by {{{Bill Atwood}}}, {{{Carsten Bormann}}}, {{{Brian Carpenter}}}, {{{Spencer Dawkins}}}, {{{Esko Dijk}}}, {{{Toerless Eckert}}}, {{{Russ Housley}}}, {{{Ines Robles}}}, {{{Rich Salz}}}, {{{Jürgen Schönwälder}}}, {{{Mališa Vučinić}}}, and {{{Rob Wilton}}}.


# Contributors
This document is very much inspired by text published earlier in {{I-D.kumar-dice-dtls-relay}}.
{{{Sandeep Kumar}}}, {{{Sye loong Keoh}}}, and {{{Oscar Garcia-Morchon}}} are the co-authors of this document.
Their draft text has served as a basis for this document.


# Changelog
-15 to -16

       * Security considerations text reviewed and expanded with more
         attack types.
       * Define CoAP discovery as default, remove GRASP/6TiSCH (#68).
       * Abstract updated to describe higher-level concepts (#47).
       * Applied Spencer's TSVART review comment 2022-05-16 in an 
         improved manner.
       * Applied Russ' review comments from IOTDIR review 2023-08-09.
       * Rewrite Section 4.1 based on Russ' review (#48).
       * Applied Toerless' review comments from WGLC (#63).
       * Applied review comments of Bill Atwood of 2024-05-21.
       * Clarify 'context payload' terminology (#49).
       * Use shorter and consistent term for Join Proxy (#58).
       * Author added.
       * Update reference RFC8366 to RFC8366bis.
       * Many editorial updates.

-13 to -15

       * Various editorial updates and minor changes. 

-12 to -13

       * jpy message encrypted and no longer standardized

-11 to -12

       * many typos fixed and text re-organized
       * core of GRASP and CoAP discovery moved to constrained-voucher
         document, only stateless extensions remain

-10 to -11

       * Join Proxy and Registrar discovery merged
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

#Stateless Proxy payload examples {#examples-detailed}

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
