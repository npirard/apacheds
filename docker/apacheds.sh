#!/bin/bash
APACHEDS_VERSION="apacheds-2.0.0.AM26"
APACHEDS_INSTANCE=/var/lib/${APACHEDS_VERSION}/default

function wait_for_ldap {
	echo "Waiting for LDAP to be available "
	c=0

    ldapsearch -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret ou=system;
    
    while [ $? -ne 0 ]; do
        echo "LDAP not up yet... retrying... ($c/20)"
        sleep 4
 		
 		if [ $c -eq 20 ]; then
 			echo "TROUBLE!!! After [${c}] retries LDAP is still dead :("
 			exit 2
 		fi
 		c=$((c+1))
    	
    	ldapsearch -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret ou=system;
    done 
}

# Replacement of the config has not been tested in this project
# see https://github.com/greggigon/apacheds for more
if [ -f /bootstrap/config.ldif ] && [ ! -f ${APACHEDS_INSTANCE}/conf/config.ldif_migrated ]; then
	echo "Using config file from /bootstrap/config.ldif"
	rm -rf ${APACHEDS_INSTANCE}/conf/config.ldif

	cp /bootstrap/config.ldif ${APACHEDS_INSTANCE}/conf/
	chown apacheds.apacheds ${APACHEDS_INSTANCE}/conf/config.ldif
fi

if [ -d /bootstrap/schema ]; then
	echo "Using schema from /bootstrap/schema directory"
	rm -rf ${APACHEDS_INSTANCE}/partitions/schema 

	cp -R /bootstrap/schema/ ${APACHEDS_INSTANCE}/partitions/
	chown -R apacheds.apacheds ${APACHEDS_INSTANCE}/partitions/
fi

# There should be no correct scenario in which the pid file is present at container start
rm -f ${APACHEDS_INSTANCE}/run/apacheds-default.pid 

/opt/${APACHEDS_VERSION}/bin/apacheds start default

wait_for_ldap

# import new schema if any
if [ -f /bootstrap/schema_modification.ldif ]; then
	SCHEMA_OR_PARTITION="true"
	echo "Importing /bootstrap/schema_modification.ldif"
  ldapmodify -h localhost -p 10389 -D "uid=admin,ou=system" -f /bootstrap/schema_modification.ldif -x -w secret
  echo "Imported /bootstrap/schema_modification.ldif"
fi

if [ -f /bootstrap/add_partition.ldif ]; then
	SCHEMA_OR_PARTITION="true"
	echo "Adding partition(s) from /bootstrap/add_partition.ldif"
  ldapmodify -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret -f /bootstrap/add_partition.ldif -a
	echo "Added partition(s)"
fi

if [ -n "${SCHEMA_OR_PARTITION}" ]; then
	echo "Restarting server"
	/opt/${APACHEDS_VERSION}/bin/apacheds restart default
  wait_for_ldap
  echo "Restarted server"
fi

if [ -n "${BOOTSTRAP_FILE}" ]; then
	echo "Bootstraping Apache DS with Data from ${BOOTSTRAP_FILE}"
	
	ldapmodify -h localhost -p 10389 -D 'uid=admin,ou=system' -w secret -f $BOOTSTRAP_FILE -a
fi

echo "Container up und running"

trap "echo 'Stopping Apache DS';/opt/${APACHEDS_VERSION}/bin/apacheds stop default;exit 0" SIGTERM SIGKILL

while true
do
  tail -f /dev/null & wait ${!}
done

# Inspiration for this file : 
# see https://github.com/greggigon/apacheds
# with Copyright (c) 2015 Greg and MIT License