```shell
docker compose up -d
ldapwhoami -x -H ldap://localhost:389 -D "cn=admin" -w password
LDAPTLS_REQCERT=never ldapwhoami -x -H ldaps://localhost:636 -D "cn=admin" -w password
```
and browse https://localhost:10443, using
* login DN: `cn=admin`
* password: password
