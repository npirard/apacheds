Apache DS in a container
========================

In case an LDAP directory is needed, see
[https://directory.apache.org/apacheds/](https://directory.apache.org/apacheds/)


## Build
```
cd docker
docker build -t apacheds .
```


## Run

### If no modification is needed

`docker run --rm -d --name ldap -p 389:10389 -p 636:10636 npirard/apacheds:latest`

### If some bootstrap modification are needed
Bootstrap modification LDIF data is to be specified on the `bootstrap` volume

* Schema modification
the LDIF with the modification must be present under bootstrap/schema_modification.ldif

* Partitions adding
the LDIF with the partition information must be present under /bootstrap/add_partition.ldif

Example:  
`docker run -it --rm --name ldap -p 389:10389 -v $PWD/sample:/bootstrap npirard/apacheds:latest`

### If some bootstrap data is needed
The LDIF file must be specified with the BOOTSTRAP_FILE environment variable

Example:  
`docker run -it --rm --name ldap -p 389:10389 -v $PWD/sample:/bootstrap -e BOOTSTRAP_FILE=/bootstrap/ADB01.ldif npirard/apacheds:latest`

*NB* use `docker run -d` if no interest in logs

