#!/bin/bash
#

function set_X509_certificate()
{
# To find or create your X.509 certificate and security credentials, go to
# https://portal.aws.amazon.com/gp/aws/securityCredentials
read -r -d '' X509_CERTIFICATE <<'EOFEOF'
-----BEGIN CERTIFICATE-----
ADD HERE
-----END CERTIFICATE-----
EOFEOF
}

function set_X509_pk()
{
# To find or create your X.509 certificate and security credentials, go to
# https://portal.aws.amazon.com/gp/aws/securityCredentials
read -r -d '' X509_PRIVATEKEY <<'EOFEOF'
-----BEGIN PRIVATE KEY-----
ADD HERE
-----END PRIVATE KEY-----
EOFEOF
}

function getpublickey()
{
	 x=$(curl -fs http://169.254.169.254/latest/meta-data/public-keys/)
	 if [ $? -eq 0 ]; then
			 for i in $x; do
					 index=$(echo $i|cut -d = -f 1)
					 format=$(curl -s http://169.254.169.254/latest/meta-data/public-keys/$index/)
					 echo $(curl -s http://169.254.169.254/latest/meta-data/public-keys/$index/$format)
			 done
	 else
			 echo "SSH Key not available"
	 fi
}

function log()
{
	echo "$1" >> /tmp/cloudinit.pid
	echo "$1"
}


#--------------------------
#- ADJUST THESE VARIABLES
#--------------------------
#

# HOSTNAME & DOMAIN
CHANGE_HOSTNAME_ENABLED=YES
HOSTNAME=servername
DOMAIN=domain.com

# PACKAGES - update & upgrade
UPDATE_OS_ENABLED=YES
INSTALL_CUSTOM_PKGS=YES

# ENVIRONMENT - adjust enviornment variables, profile, disable motd. See code for details
CHANGE_ENVIRONMENT_ENABLED=YES

# USERS - change the default username from 'ubuntu' to what you specify here (and give sudo rights)
CHANGE_USERS_ENABLED=YES
NEW_USERNAME=davidvincent

# DDNS - Automatically updates dyndns.com servers with your dynamic ip address
DDNS_ENABLED=YES                        # set to NO if you don't want to use Dynamic DNS update
DDNS_USERNAME=david
DDNS_PASSWORD='secret'
DDNS_SUFFIX=dyndns.info

# EBS Volumes
#
# Allow you to select a specific EBS volume to be mounted automatically.
# This requires AWS_API_ENABLED=YES, oterhwise it'll be ignored.
# The EBS volume will NOT be created, so make sure it exists, or it won't work.
EBS_VOL_MOUNT_ENABLED=YES
EBS_VOL_NAME=volume_name                # this MUST be set. Use the name tag when creating the EBS volume
EBS_VOL_SIZE=1                          # default vol size, in GB (only used if the volume doesn't exist)
EBS_DEVICE=/dev/xvdm                    # select where to attach the EBS volume. On newer kernels it's /dev/xvdX..
EBS_MOUNTPOINT=/mydata                  # must be a new directory. It'll be created below
EBS_INIT_FS=no                          # ATTENTION ATTENTION ATTENTION! BE EXTRA CAREFUL. This will initilize (i.e., ERASE!) your EBS volume. If in doubt, say NO
EBS_FILESYSTEM=ext4                     # used on mkfs -t XXXX (ext2, ext3, ext4, ntfs, etc). Only used if EBS_INIT_FS=YES


# AWS API TOOLS - Install AWS EC2 API tools (useful for managing EBS volumes, instances, etc).
# This is mandatory if you're using EBS_DATA_ENABLED=YES. This will also implicitly do a apt-get update/upgrade
AWS_API_ENABLED=YES
AWS_ZONE=us-east-1b
AWS_URL=https://ec2.us-east-1.amazonaws.com
AWS_ACCESS_KEY=myaccesskey
AWS_SECRET_KEY=mysecretkey

# SSH public keys - If you didn't add your public key to AWS Key Pair when creating the EC2 instance, you'll HAVE to
# the SSH_KEYS manually below, otherwise you'll be locked out of your newly created instances.
SSHD_CHANGE_PORT_ENABLED=YES
SSHD_PORT=2222
SSH_KEYS=$(getpublickey)
# SSH_KEYS="ssh-rsa Iw8tVmqnawCGkFlvSyZB........Jnp== youremail@domain.com Comment: \"youemail@domain.com\""



#-------------------------------------------------------
#-- NO NEED TO EDIT ANYTHING BELOW THIS LINE,
#-- unless you want to do specific customizations
#--
log "cloud-init.sh started at:  `date`"

#------- PACKAGES
#-
#- standard update & upgrade
#
if  [ "$AWS_API_ENABLED" = "YES" ];
then
	# enable multiverse packaging, in order to allow EC2 API tools to be installed
	# (see http://alestic.com/2012/05/aws-command-line-packages for instructions)
	sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list

	# install AWS API tools from the multiverse repository
	# note: this will add java, openjdk, ruby 1.8, libxml and a bunch of other depencies (~140MB)
	apt-add-repository -y ppa:awstools-dev/awstools > /dev/null
	apt-get -y update  > /dev/null
	apt-get -y upgrade > /dev/null
	apt-get -y install ec2-api-tools ec2-ami-tools iamcli rdscli > /dev/null

	# if you want to use AWS CloudFormation, uncomment next line:
	#apt-get install aws-cloudformation-cli elbcli

else  # not AWS_API_ENABLED, but maybe we still have to update/upgrade if UPDATE_OS_ENABLED=YES

	if  [ "$UPDATE_OS_ENABLED" = "YES" ];
	then
		apt-get -y update  > /dev/null
		apt-get -y upgrade > /dev/null
	fi
fi


if  [ "$INSTALL_CUSTOM_PKGS" = "YES" ];
then
	# install a basic set of useful packages
	apt-get -y install unzip > /dev/null
	#apt-get -y install alpine > /dev/null
fi



#------- USERS
#-
#- user customizations:
#     . add your customized user
#     . delete default 'ubuntu' user
#     . add SSH Key, with proper permissions
#     . add new user to sudoers
#
if  [ "$CHANGE_USERS_ENABLED" = "YES" ];
then
	# add new user
	useradd -p '*' -m -s '/bin/bash' $NEW_USERNAME
	adduser --quiet $NEW_USERNAME sudo
	adduser --quiet $NEW_USERNAME adm
	adduser --quiet $NEW_USERNAME admin

	# add ssh keys
	mkdir /home/$NEW_USERNAME/.ssh
	echo "$SSH_KEYS" > /home/$NEW_USERNAME/.ssh/authorized_keys
	chmod 0700 /home/$NEW_USERNAME/.ssh
	chmod 0600 /home/$NEW_USERNAME/.ssh/authorized_keys
	chown $NEW_USERNAME.$NEW_USERNAME /home/$NEW_USERNAME/.ssh
	chown $NEW_USERNAME.$NEW_USERNAME /home/$NEW_USERNAME/.ssh/authorized_keys

	# adjust sudoers
	sed -i "s/^ubuntu/$NEW_USERNAME/g" /etc/sudoers.d/*

	# delete old 'ubuntu' default user
	deluser --quiet ubuntu
fi



#------- SSH DAEMON
#-
#- sshd daemon: move sshd to a non-standard port number. This reduces dramatically
#   the number of spam bots hitting your server
#
if  [ "$SSHD_CHANGE_PORT_ENABLED" = "YES" ];
then
	sed -i "s/^Port 22/Port $SSHD_PORT/" /etc/ssh/sshd_config
	service ssh restart > /dev/null 2>&1    # restart sshd to enable the new port
fi


#------- NETWORKING
#-
#- hostname & FQDN: adjust server hostname and add FQDN to /etc/hosts
#
if  [ "$CHANGE_HOSTNAME_ENABLED" = "YES" ];
then

	cat <<EOF > /etc/network/if-up.d/updhosts
#!/bin/bash
MY_DOMAIN=$DOMAIN
MY_HOSTNAME=$HOSTNAME
PUBLIC_IPV4=\`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-ipv4\`

#-- add HOSTNAME
echo "\$MY_HOSTNAME" >/etc/hostname

#-- add FQDN to hosts file (or replace the line, if it already exists)
if grep -qs "\$MY_HOSTNAME.\$MY_DOMAIN" /etc/hosts
then
		sed -i "s/.*\$MY_HOSTNAME.\$MY_DOMAIN.*/\$PUBLIC_IPV4 \$MY_HOSTNAME.\$MY_DOMAIN \$MY_HOSTNAME/g" /etc/hosts
else
		echo "\$PUBLIC_IPV4 \$MY_HOSTNAME.\$MY_DOMAIN \$MY_HOSTNAME" >> /etc/hosts
fi
service hostname restart > /dev/null 2>&1
echo "updhosts last updated: \`date\`" > /tmp/updhosts.pid
EOF

	# adjust ownership & permissions
	chown root.root /etc/network/if-up.d/updhosts
	chmod 0755 /etc/network/if-up.d/updhosts
	/etc/network/if-up.d/updhosts           # set hostname

fi


#------- DDNS
#-
#-  Add this EC2 instance to your DynamicDNS service
#-
#-  Please note that the host MUST ALREADY EXIST on DynDns.com before you update.
#-  That's pitty, but DynDNS does not support automatic host creation via API
#-  (unless you pay $30/month for Enterprise plan)
#-
#-  I'm using the following convention: ROOTDOMAIN-HOSTNAME.$DDNS_SUFFIX. For example:
#-		domain-host1.dyndns.info		(hostname = host1)
#-		domain-host2.dyndns.info		(hostname = host2)
#-		...
#
if  [ "$DDNS_ENABLED" = "YES" ];
then
	apt-get -y install ddclient     # install ddnsclient daemon

	ROOT_DOMAIN=`echo $DOMAIN | cut -f1 -d'.'`

	cat <<EOF > /etc/ddclient.conf
#
# /etc/ddclient.conf

#-- daemon config
#
daemon=300
syslog=yes
ssl=yes
mail-failure=root
pid=/var/run/ddclient.pid
cache=/tmp/ddclient.cache

#-- service being used - DynDNS2
#
protocol=dyndns2
server=members.dyndns.org
use=web, web=checkip.dyndns.com, web-skip='IP Address'
## this will determine IP via DynDNS' CheckIP server (will get ext IP from EC2)

#-- DynDNS credentials
#
login=$DDNS_USERNAME
password='$DDNS_PASSWORD'

#-- add wildcard CNAME?
wildcard=YES

#-- Dynamic DNS hostname(s) go here
#
$ROOT_DOMAIN-$HOSTNAME.$DDNS_SUFFIX
EOF

	cat <<EOF > /etc/default/ddclient
# /etc/default/ddclient
#
# Configuration for ddclient scripts
# generated by AWS Cloud initialization script cloud-init.sh
#
# Set to true if ddclient should be run every time a new ppp connection is established (for dial-up conns)
run_ipup="false"

# Set to true if ddclient should run in daemon mode
run_daemon="true"

# Set the time interval between the updates of the dynamic DNS name in seconds. Only used in daemon mode.
daemon_interval="300"
EOF

	# adjust permissions
	chmod 600 /etc/ddclient.conf
	chmod 644 /etc/default/ddclient

	# start ddclient as daemon, and configure to run at every boot (runlevel 2)
	ln -s /etc/init.d/ddclient /etc/rc2.d/S50ddclient
	service ddclient start > /dev/null 2>&1
fi



#------- ENVIRONMENT
#-
#-  These are the enviornment customizations: .profile, /etc/profile, motd, .bashrc
#-
#-  This is highly personal. Change as you see fit. I like to auto-start a GNU Screen (if
#-  one isn't already running). I'm also picky with aliases, usage of UP/DOWN arrow keys
#-  to backtrack previous shell history and hate any motd messages during login.
#-
if  [ "$CHANGE_ENVIRONMENT_ENABLED" = "YES" ];
then

	# .profile
	#
	cat <<EOF >> /home/$NEW_USERNAME/.profile

# automatically starts GNU/Screen:
#
if [ -z "\$STY" ]; then
		# we're not running yet (on this shell). Let's re-attach (or create)...
		screen -xR mySession

else
		# we're within screen already, so just adjust the prompt (so the hardstatusline can
		# show the running command properly)
		export PS1=\'\[\033k\033\\\]\u@\h:\w\$ \' # set command prompt for screen

fi
EOF

	# /etc/profile
	#
	cat <<EOF >> /etc/profile

# Personal customizations
umask 022
alias dir='ls -la'
alias so='source ~/.profile'
alias pine='alpine'
alias bin='cd /usr/local/bin'
alias www='cd /www'
alias log='cd /var/log'

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

export EDITOR=pico
export PATH="\$PATH:.:"
export PYTHONPATH="~/dev/lib:PYTHONPATH"
EOF

	# motd: disable all motd messages, for a perfectly silent login
	#
	touch /home/$NEW_USERNAME/.hushlogin
	chown $NEW_USERNAME.$NEW_USERNAME /home/$NEW_USERNAME/.hushlogin
fi


#------- AWS API tools
#-
#- install AWS API tools. Useful for AWS script automation later on
#
if  [ "$AWS_API_ENABLED" = "YES" ];
then
	log "Installing & configuring AWS API tools..."
	set_X509_certificate
	set_X509_pk
	EC2_INSTANCE_ID=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
	log "EC2_INSTANCE_ID = [$EC2_INSTANCE_ID]"

	# create AWS X.509 certificate & private key in the root home dir
	mkdir -m 0700 $HOME/.aws/
	
	UUID=`date "+%s"`
	echo "$X509_CERTIFICATE" > $HOME/.aws/cert-$UUID.pem
	echo "$X509_PRIVATEKEY"  > $HOME/.aws/pk-$UUID.pem
	cat <<EOF > $HOME/.aws/aws-credential-file.txt
AWSAccessKeyId=$AWS_ACCESS_KEY
AWSSecretKey=$AWS_SECRET_KEY
EOF

	# adjust environment variables, so credentials are automatically recognized
	cat <<EOF >> $HOME/.bashrc

# AWS credentials
export EC2_PRIVATE_KEY=$HOME/.aws/pk-$UUID.pem
export EC2_CERT=$HOME/.aws/cert-$UUID.pem
export AWS_CREDENTIAL_FILE=$HOME/.aws/aws-credential-file.txt
EOF

	source $HOME/.bashrc

	# force EC2 vars. Normally it would not be needed, but it helps debugging (if you're running the shell interactivelly
	EC2_PRIVATE_KEY=$HOME/.aws/pk-$UUID.pem
	EC2_CERT=$HOME/.aws/cert-$UUID.pem
	AWS_CREDENTIAL_FILE=$HOME/.aws/aws-credential-file.txt
fi


#------- EBS VOLUMES
#-
#- Mount EBS volumes
#-
if  [ "$EBS_VOL_MOUNT_ENABLED" = "YES" ];
then

	if  [ "$AWS_API_ENABLED" != "YES" ];  # sanity checking. We need AWS API TOOLS in order to mount EBS volumes
	then
		log "ERROR. In order to mount EBS Volumes, you *must* set AWS_API_ENABLED=YES."
		log "Skipping EBS configuration..."
	else

		EBS_VOL_ID=`ec2-describe-volumes | grep -w $EBS_VOL_NAME | awk '{ print \$3 }'`
		EBS_JUST_CREATED=NO

		if  [ "$EBS_VOL_ID" = "" ];
		then
			# volume does not exist, so we'll create one
			log "Volume [$EBS_VOL_NAME] not found. Creating volume..."
			OUTPUT=`ec2-create-volume -s $EBS_VOL_SIZE -z $AWS_ZONE`
			log "ec2-create-volume output: [$OUTPUT]"

			log "Changing metadata [Name] to [$EBS_VOL_NAME]..."
			EBS_VOL_ID=`echo $OUTPUT | awk '{ print \$2 }'`
			OUTPUT=`ec2-create-tags $EBS_VOL_ID --tag Name=$EBS_VOL_NAME > /dev/null`
			log "ec2-create-tags output: [$OUTPUT] (empty is OK)"

			EBS_JUST_CREATED=YES
		fi

		# the ec2-attach-volume has the bad habit of requiring /dev/sdX format, but it'll still mount to
		# /dev/xdvX device under Ubuntu. Notice there's no error checking; if the attach command fails (it shouldn't,
		# but you never know) you'll have to deal with it manually after server instantiation
		log "Attaching EBS volume to this instance..."
		OUTPUT=`ec2-attach-volume $EBS_VOL_ID -i $EC2_INSTANCE_ID -d /dev/sd\`echo $EBS_DEVICE | cut -c 9-\``
		log "ec2-attach-volume output: [$OUTPUT]"

		# initialize filesystem, if specified. WARNING: IF VOLUME ALREADY EXISTS, THIS WILL DESTROY YOUR DATA.
		if  [ "$EBS_INIT_FS" = "YES" ] || [ "$EBS_JUST_CREATED" = "YES" ];
		then			
			log "Initializing EBS volume filesystem [$EBS_FILESYSTEM] on device [$EBS_DEVICE]..."
			sleep 5  # wait for kernel to recognize the new drive before mkfs
			OUTPUT=`mkfs -t $EBS_FILESYSTEM $EBS_DEVICE`    # be extra careful with this!
			log "mkfs output: [$OUTPUT]"
		fi

		mkdir $EBS_MOUNTPOINT

		cat <<EOF >> /etc/fstab

# Mount External EBS Volumes
$EBS_DEVICE     $EBS_MOUNTPOINT     $EBS_FILESYSTEM     defaults  0 0
EOF
		OUTPUT=`mount -a`
		log $OUTPUT
	fi
fi


# All done!
log "cloud-init.sh finished at: `date`"
