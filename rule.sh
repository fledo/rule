#!/bin/bash
# 
#	rule.sh
#		Configure firewall via iptables
#	Usage
#		rule help
#	

# Look for iptables
check() {
	if ! iptables -V &>/dev/null ; then
		echo "Iptables binary not found. Check permissions/package/path."
		exit 1
	fi
}
#  Apply default rules.
default() {
	echo "Applying default rules!"
	rule out tcp 80,443 # HTTP/HTTPS
	rule out udp 53		# DNS
	rule out udp 67		# DHCP
	rule out udp 123	# NTP
	rule out tcp 22		# SSH out
	rule in tcp 22		# SSH in
}

#	rule()
#		Toggle a basic firewall rule. Input will allow related or established output and vice versa.
#	param
#		1	Direction "in" or "out"
#		2	Protocol
#		3	Destination port(s). Single, comma separated, or range xxxx:yyyy"
#		4	Rule target. Default "ACCEPT"
#		5	Input sorce(s) or output destination(s). Single IP, comma separated or CIDR range.
rule() {
	target=${4:-ACCEPT} # Default value
	target=${target^^}	# iptables likes capital letters.
	if [ $1 = in ]; then
		toggle INPUT -p $2 -m multiport --dports $3 ${5+-s $5} -j $target
		toggle OUTPUT -p $2 -m multiport --sports $3 ${5+-d $5} -m state --state RELATED,ESTABLISHED -j $target
	elif [ $1 = out ]; then
		toggle OUTPUT -p $2 -m multiport --dports $3 ${5+-d $5} -j $target
		toggle INPUT -p $2 -m multiport --sports $3 ${5+-s $5} -m state --state RELATED,ESTABLISHED -j $target
	fi
}

#	flush()
#		Flush all rules/tables. Default policy drop. Allow ping and loopback.
#	param
#		1	If "all" then don't apply default rules. This will lock the system down.
flush() {
	# tables
	iptables -F
	iptables -X
	iptables -Z
	while read table ;do
		iptables -t $table -F
		iptables -t $table -X
		iptables -t $table -Z
	done < /proc/net/ip_tables_names

	# Default policy
	iptables -P INPUT DROP
	iptables -P FORWARD DROP
	iptables -P OUTPUT DROP

	# Loopback
	iptables -A INPUT -i lo -j ACCEPT -m comment --comment Loopback
	iptables -A OUTPUT -o lo -j ACCEPT -m comment --comment Loopback

	# ICMP
	iptables -A INPUT -p icmp -j ACCEPT
	iptables -A FORWARD -p icmp -j ACCEPT
	iptables -A OUTPUT -p icmp -j ACCEPT
	
	echo "Flushed rules!"
	
	# Apply default rules unless: rule flush all
	if [ "$1" != all ] ; then
		default
	fi
}

#	log()
#		Toggle log rules of dropped input/output/forward packets.
#	param
#		1	Limit per minute. Default: 15
#		2	Level to log. Default: 7 (ebug)
log() {
	limit="${1:-15}"
	level="${2:-7}" 
	toggle INPUT -m limit --limit $limit/minute -j LOG --log-level $level --log-prefix "iptables input: "
	toggle OUTPUT -m limit --limit $limit/minute -j LOG --log-level $level --log-prefix "iptables output dropped: "
	toggle FORWARD -m limit --limit $limit/minute -j LOG --log-level $level --log-prefix "iptables forward dropped: "
}

#	toggle()
#		Enable or disable supplied rule
#	params
#		All params will be passed to iptables as they are.
toggle() {
	if iptables -C "$@" &>/dev/null; then
		iptables -D "$@"
		echo -e "Removed:\t$@"
	else
		iptables -A "$@"
		echo -e "Applied:\t$@"
	fi
}

#	save()
#		Save current rules to file.
#	params
#		1	File where to save rules. Default: /etc/iptables/rules.v4
save() {
	saveTo=${1:-"/etc/iptables/rules.v4"}
	if iptables-save > $saveTo ; then
		echo "Rules saved to $saveTo"
	else
		echo "Error while saving rules to $saveTo"
	fi
	exit $?
}

#	usage()
#		Echo script help
#	params
#		1	Specific section.
usage() {
	case $1 in
	in) 
		echo "Create a rule for incoming traffic. Outgoing related/established traffic will be allowed. Already applied rule will be removed.

	Usage: rule in <protocol> <port> [chain] [source]

		<protocol>

			The protocol of the rule. can be 'tcp', 'udp', 'icmp' or 'all'.

		<port>

			The port to open for incoming traffic. Single '22', multiple '80,443', range '5000:5010'.

		[chain]

			Optional chain target. Default: 'accept'. Can also be 'drop', 'reject' or user defined.

		[source]

			Optional source address. Default 'none/all'. Can be  Single, comma separated or CIDR annotation."
	;;

	out)
		echo "Create a rule for outgoing traffic. Incoming related/established traffic will be allowed. Alreay applied rule will be removed.

	Usage: rule out <protocol> <port> [chain] [destination]

		<protocol>

			The protocol of the rule. can be 'tcp', 'udp', 'icmp' or 'all'.

		<port>

			The port to open for incoming traffic. Single '22', multiple '80,443', range '5000:5010'.

		[chain]

			Optional chain target. Default: 'accept'. Can also be 'drop', 'reject' or user defined.

		[source]

			Optional source address. Default 'none/all'. Can be  Single, comma separated or CIDR annotation."
	;;

	flush)
		echo "Flush all rules and apply default rules.

	Usage rule flush [action]

		[action]

			If 'all' then rules will be flushed and no default rules will be applied. This will lock you out from the system."
	;;

	policy)
		echo "Set default policy for a chain.

	Usage: rule pocily <chain> <target> 

		<chain>

			Name of chain where to apply policy: 'input', 'output', 'forward' or user defined.

		<policy>

			Name of policy to apply to chain: 'accept', 'reject' or 'drop'."
	;;

	save) 
		echo "Save current rules to file.

	Usage: rule save [file]

		[file]

			Target file to save rules. Default: '/etc/iptables/rules.v4'"
	;;

	log)
		echo "Create rule for traffic logging. Already applied rule will be removed.

	Usage: rule log [limit] [level]

		[limit]

			Number of logged packets per minute. Default: '15'.

		[level]

			Log level: '0' emergency, '1' alert, '2' critical, '3' error, '4' warning, '5' notice, '6' info, '7' debug. Default: '7'."
	;;

	show)
		echo "Show current rules.

	Usage: rule show [chain]

		[chain]

			Name of chain to show."
	;;

	help)
		echo "Show help

	Usage: rule show [section]

		[section]

			Show specific section. in/out/policy/save/log/show/help/examples/default"
	;;

	examples)
		echo "Examples

	Allow incoming tcp on port 22

		rule in tcp 22

	Allow incoming tcp on port 80 and 443

		rule in tcp 80,443

	Allow incoming tcp on port 1521 from specific IPs

		rule in tcp 1521 accept 10.0.0.2,10.0.0.3

	Allow outgoing tcp to port 80, 443 and 5000 to 5050 to specific subnet 

		rule out tcp 80,443,5000:5050 accept 192.168.0.1/24"
	;;

	default)
		echo "Toggle default rules. Already applied rules will be removed.

	Usage: rule default

		rule out tcp 80,443 # HTTP/HTTPS
		rule out udp 53		# DNS
		rule out udp 67		# DHCP
		rule out udp 123	# NTP
		rule out tcp 22		# SSH out
		rule in tcp 22		# SSH in"
	;;
	*)
		echo "Configure firewall with iptables.

	in <protocol> <port> [chain] [destination]

		Create inbound rule.

	out <protocol> <port> [chain] [source]

		Create outbound rule.

	pocily <chain> <target>

		Set policy for built-in chain.

	save [file]

		Save current rules to file.

	show

		Show current rules.

	help [section]

		Show command help.

	examples

		Show command examples.

	default

		Apply default rules."
	esac
}

# permissions and iptables ok?
check

case $1 in
	in|out)
		rule "$@"
	;;
	flush)
		flush $2
	;;
	policy)
		iptables --policy ${2^^} ${3^^}
	;;
	save)
		save $2
	;;
	log)
		log $2 $3
	;;
	show)
		iptables --numeric --list ${2^^}
	;;
	help)
		usage $2 
	;;
	examples)
		usage examples
	;;
	default)
		default
	;;
	*)
		echo -e "Unknown command: $1\nUsage: rule [ in | out | flush | policy | save | log | show | help | examples | default ]"
esac
