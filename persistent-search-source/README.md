# Persistent Search PingDataSync Source

## TLDR;
https://pingidentity-devops.gitbook.io/devops/getstarted
then
```
git clone https://github.com/arnaudlacour/sync-use-cases.git
docker-compose up -d
docker-compose logs -f
```

## Overview
This docker-compose stack demonstrates how a PingDataSync server may be configured to detect changes on a source LDAP Server by issuing persistent search requests.

### Archictecture

```
                        +----------------------------------------------------------------------------+
                        |                          |     PingDataSync     |                          |
                        |                          +----------------------+                          |
+--------------+        | +-----------+     +-----------------------------------+    +-------------+ |
|              |        | |           |     |                                   |    |             | |
| LDAP Server  +<---------+ Source    +---->+               Pipe                +--->+ Destination | |
|              |        | |           |     |                                   |    |             | |
+--------------+        | +-----------+     +-----------------------------------+    +-------------+ |
                        |   persistent             |   +------------+                       DevNull  |
                        |   search                 +-->+  Class     |                                |
                        |                              +------------+                                |
                        |                              |  +-------------+                            |
                        |                              +->+ DN Map      |                            |
                        |                                 +-------------+                            |
                        |                                 +-------------+                            |
                        |                                 | Attr Map    |                            |
                        |                                 +-------------+                            |
                        |                                  |  +------------+                         |
                        |                                  +->+ mappings...|                         |
                        |                                     +------------+                         |
                        +----------------------------------------------------------------------------+
```
In this setup, the LDAP sync source issues a persistent search request to the LDAP Server.
Once processed, the request will remain open until the server terminate the request or something unexpected interrupts it.
A new request will be issued to the LDAP Server in either case.
Once search entries are sent by the LDAP server to PingDataSync they will flow through the pipe to a mock destination that discards the change.
This allows to demonstrate how this sync source works.

### Rationale
Some LDAP servers may not offer a change log (or similar) facility for PingDataSync to reliably detect changes. In some situations it may not be possible, allowed or otherwise desirable to use a changelog so this approach offers a serviceable alternative.

## Details
### Caveats
Persistent searches do not offer many of the advantages of using a changelog facility. In particular, while not inherently unreliable, the possibility exists to miss changes using this mechanism under certain circumstances. It is always preferable to use a changelog as they allow rewinding and replay past changes.
On some LDAP servers, persistent searches may be very restricted because of potential adverse performance costs and stability risks associated with processing these very long-lived requests.

### Advantages
While they come with some disadvantages compared to other available synchronization and change detection strategies, persistent search requests also have some benefits: they're simple, flexible and provided the source ldap server performs well, they allow for very low latency change detection.

### Pre-requisites
On the source LDAP server, an account should be created for the PingDataSync server to be able to issue persistent search requests.
This may be a feature to explicitly enable on certain products.
Additionally, security access control rule(s) should be associated to the account to be able use the persistent search request control (OID 2.16.840.1.113730.3.4.3)

### What to expect
When this stack runs, it will first run a small PingDirectory instance for demonstration purpose.
Once the PingDirectory instance is in working order, the PingDataSync container will come up and issue a persistent search request to PingDirectory.
At this point, a modrate job will generate one LDAP MODIFY request every second on entries in PingDirectory.
You will be able to see the changes detected by PingDataSync in the container output, it will look like:
```
pingdatasync_1     | [17/Apr/2020:03:54:17.292 +0000] category=SYNC severity=INFORMATION msgID=1893728293 op=2168 changeNumber=2168 pipe="from-persistent-search-source_to_dev-null" msg="Detected MODIFY of cn=user.0\,ou\=People\,dc\=example\,dc\=com at pingdirectory"
```
