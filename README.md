My attempts to create a reproducible best practice low cost security architecture in aws with terraform. Theres obviously more that can be done with further paid subscription models (such as AWS Shield Advanced) but generally people do not have that much to spend per month (3k/mo) so we will do our best with keeping it as free as possible.  

<br>
Features (So Far): <br>
1). 3 Tier VPC (Web,App,DB) with SG/NACL hardening.<br>
2). Use of CIS L1 Linux Images (Host Hardening).<br>
3). Encryption everywhere (in transit, at rest).<br>
4). Implementation of WAF on all ALBs.<br>
5). DNS Hardening (SPF,DMARC).<br>
6). Logging. <br>
7). More on the way...<br>
