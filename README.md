# LDAP with Docker
> Lightweight Docker image to run OpenLDAP 


## TL,DR;
```shell
docker run -p=389:389 --name=ldap widespot/ldap 
```

## Features
* [x] unopiniated. You won't be annoyed by default configuration, like in the [bitnami LDAP Docker images](https://hub.docker.com/r/bitnami/openldap/).
* [x] highly customizable using [environment variables](#environment-variables)
* [x] Mountable `/seed` directory for custom initialization using `.ldif` files (see `SEED_LDIF_DIR_PATH` [environment variable](#environment-variables))
* [x] pre-built modules and schemas

### Built in modules
* `accesslog`
* `auditlog`
* `autoca`
* `collect`
* `constraint`
* `dds`
* `deref`
* `dyngroup`
* `dynlist`
* `homedir`
* `memberof`
* `otp`
* `pcache`
* `ppolicy`
* `refint`
* `remoteauth`
* `retcode`
* `rwm`
* `seqmod`
* `sssvlv`
* `sycprov`
* `translucent`
* `unique`
* `valsort`

### Built in schemas
TODO

## Environment variables
| ENV                       | configuration | default                               | description                                                                                                                        |
|---------------------------|---------------|---------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| CONFIG_LDIF_FILE_PATH     |               | `${ETC_PATH}/openldap/slapd.ldif`     | path to the LDAP configuration file using LDIF format. See bellow for config file considerations                                   |
| CONFIG_KV_FILE_PATH       |               | `${ETC_PATH}/openldap/slapd.conf`     | path to the LDAP configuration file using key/value format. See bellow for config file considerations                              |
| SEED_LDIF_DIR_PATH        |               | `/seed`                               | path to the directory where the init `.ldif` files are placed. **those files are only executed once, at container creation**       |
| CONFIGURE_BASIC_ACL       | yes           | `1`                                   | Anonymous user will have read access if no ACL configured. This setting to `1` will restrict anonymous users to `auth`             |
| BUILTIN_MODULES           | yes           | `""`                                  | comma separated list of modules. See list bellow                                                                                   
| BUILTIN_SCHEMAS           | yes           | `""`                                  | comma separated list of built in schemas to enable. See list bellow                                                                
| OLC_DB_MAX_SIZE           | yes           | `1073741824`                          |
| OLC_SUFFIX                | yes           | `dc=example,dc=com`                   |
| OLC_ROOT_DN               | yes           | `cn=admin,${OLC_SUFFIX}`              |
| OLC_ROOT_PASSWORD         | yes           | `password`                            |
| OLC_DB_DIRECTORY          | yes           | `${VAR_PATH}/openldap-data`           |
| OLC_ARGS_FILE             | yes           | `${VAR_PATH}/run/slapd.args`          |
| OLC_PID_FILE              | yes           | `${VAR_PATH}/run/slapd.pid`           |
| OLS_MONITORING            | yes           | `FALSE`                               |
| TLS_CA_CERT_FILE_PATH     | yes           | `${ETC_PATH}/openldap/ca.crt.pem`     | 
| TLS_CA_CERT_KEY_FILE_PATH | yes           | `${ETC_PATH}/openldap/ca.key.pem`     | 
| TLS_CERT_FILE_PATH        | yes           | `${ETC_PATH}/openldap/server.crt.pem` | 
| TLS_CERT_KEY_FILE_PATH    | yes           | `${ETC_PATH}/openldap/server.key.pem` | 
| TLS_CERT_CSR_FILE_PATH    | yes           | `${ETC_PATH}/openldap/server.csr.pem` | 
TLS_CERT_COUNTRY="BE"
TLS_CERT_STATE="Brussels"
TLS_CERT_CITY="Brussels"
TLS_CERT_COMPANY="Example"
TLS_CERT_ORGANIZATION_UNIT="IT"
TLS_CERT_COMMON_NAME="example.com"

### Configuration files and environment variables
OpenLDAP supports two configuration file formats
* `.conf` using key/value formatting
* `.ldif` using LDAP LDIF formatting
> slapd.conf is straightforward and simpler but has limited flexibility, while slapd.ldif is more flexible and dynamic, 
aligning better with modern LDAP management and OpenLDAP’s newer capabilities.

1. This image will first look for a `slapd.ldif` file at `$CONFIG_LDIF_FILE_PATH`. 
2. If none provided (mounted, or copied in a customized image), it searches for a `slapd.conf` file at `CONFIG_KV_FILE_PATH`
3. If none provided, a new `slapd.ldif` file is created at `$CONFIG_LDIF_FILE_PATH`. The content is based on the 

> ⚠️WARNING ⚠️
> 
> Environment variables related to configuration **ARE IGNORED** when a config file (ldif or kv) is provided

## Dev
```shell
cd example
docker compose up -d
```
and browse https://localhost:10443, using
* login DN: `cn=admin,dc=example,dc=com`
* password: password
