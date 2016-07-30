# rule
Pass commands to iptables and create firewall rules with a simple syntax.

## Help

For further information, run `rule help [command]`.

### In

Create or remove inbound rule for specifiec protocol and port. Related and established outbound traffic will be allowed.

    in <protocol> <port> [chain] [destination]

### Out

Create or remove outbound rule for specifiec protocol and port. Related or established inbound traffic will be allowed.

    out <protocol> <port> [chain] [source]

### Policy

Set policy for built-in chain.

    pocily <chain> <target>

### Save

Save current rules to file. Defaults to /etc/iptables/rules.v4

    save [file]

### Flush

Remove current rules, sets policy for default chains to DROP, allows loopback and ICMP. Several more [default](#default) rules will be added unless `[action]` is `all`.

    flush [action]

### Show

Show all rules or rules for specific chain..

    show [chain]

### Help

Show command help.

    help [section]

### Examples

Show command examples.

    examples

### Default

Apply default rules.

    default

Triggers the following commands:

    rule out tcp 80,443 # HTTP/HTTPS
    rule out udp 53     # DNS
    rule out udp 67     # DHCP
    rule out udp 123    # NTP
    rule out tcp 22     # SSH out
    rule in tcp 22      # SSH in


## Examples

Add a rule to allow inbound tcp port 22.

    rule in tcp 22

Allow outbound tcp 80 and tcp 443:

    rule out tcp 80,443

Allow incoming tcp port 1521 from specific sources:

    rule in tcp 1521 accept 10.0.0.2,10.0.0.4

Allow outgoing tcp to port 80, 443 and 5000 to 5050 to a specific subnet:

    rule out tcp 80,443,5000:5050 accept 192.168.0.0/24

Enable/Disable logging:

    rule log

Remove all rules and apply default set:

    rule flush
    
Set output policy to drop:

    rule policy output drop

## License

```
The MIT License (MIT)

Copyright (c) 2016 Fred Uggla

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
