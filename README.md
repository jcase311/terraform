My attempts to create a reproducible best practice security architecture in aws with terraform.

<br>
Features (So Far): <br>
1). 3 Tier VPC (Web,App,DB) with SG/NACL hardening.<br>
2). Use of CIS L1 Linux Images (Host Hardening).<br>
3). Encryption everywhere (in transit, at rest).<br>
4). Implementation of WAF on all ALBs.<br>
5). DNS Hardening (SPF,DKIM).<br>
6). Logging. <br>
7). More on the way...<br>
