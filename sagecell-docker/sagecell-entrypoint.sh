#!/bin/bash

function configure_ssh() {
	local key_file=/home/sage/.ssh/id_rsa
	if [ $(ssh-add -l &> /dev/null; echo $?) -gt 0 ]; then
		# Generate ssh keys for the user.
		if [ ! -f $key_file ]; then
			[ ! -d /home/sage/.ssh ] && mkdir /home/sage/.ssh
			ssh-keygen -t rsa -f $key_file -P "" -q
		fi

		# Start and configure the ssh-agent.
		eval `ssh-agent` > /dev/null
		local ssh_fingerprint=$(ssh-keygen -l -f $key_file | awk '{print $2}')
		if [ ! -z  "$ssh_fingerprint" ] && [ -z "$(ssh-add -l | grep "$ssh_fingerprint")" ]; then
			ssh-add $key_file 2> /dev/null
		fi

		# Add localhost to known_hosts.
		[ ! -f /home/sage/.ssh/known_hosts ] && touch /home/sage/.ssh/known_hosts
		if [ -z "$(ssh-keygen -F localhost)" ]; then
			ssh-keyscan -H localhost > /home/sage/.ssh/known_hosts 2> /dev/null
		fi

		cat ${key_file}.pub > /home/sage/.ssh/authorized_keys
	fi
}

function check_ssh() {
	ssh -v -o PreferredAuthentications=publickey -o BatchMode=yes -o ConnectTimeout=10 \
		-o StrictHostKeyChecking=no localhost /bin/true &> /dev/null
	return $?
}

# Configure and start rsyslog.
sed -i '/imklog/s/^/#/' /etc/rsyslog.conf
rsyslogd

# Start and configure the ssh server for internal use.
service ssh start > /dev/null

export -f configure_ssh
export -f check_ssh

su sage bash -c "configure_ssh"
su sage bash -c "check_ssh"

if [ $? -eq 0 ]; then
    echo "Executing: $(eval "echo $@")"
    exec $(eval "echo $@")
else
    echo "ERROR: SageCell server not started. Failed to configure internal ssh server."
fi
