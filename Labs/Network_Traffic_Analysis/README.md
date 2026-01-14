# Network Traffic Analysis – Wireshark Lab

## Objective
To analyze captured network traffic in order to identify normal activity and potential security issues using Wireshark.

## Tools Used
- Wireshark
- Linux (Kali / Ubuntu)

## Lab Environment
- One client machine
- One server or simulated traffic source
- Network interface in promiscuous mode

## Filters Used
- tcp
- http
- tcp.port == 80
- ip.addr == 192.168.1.1

## Analysis Performed
- Identified TCP handshakes (SYN, SYN-ACK, ACK)
- Observed HTTP GET and POST requests
- Detected unencrypted credentials in plaintext traffic
- Reviewed packet headers and payloads

## Findings
- HTTP traffic is transmitted in plaintext
- Sensitive data can be exposed without encryption
- TCP retransmissions may indicate network issues or attacks

## Security Takeaways
- Always enforce HTTPS
- Monitor network traffic for anomalies
- Use packet analysis during incident investigations

