```shell
docker compose up -d
ldapwhoami -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=com" -w password
```
and browse https://localhost:10443, using
* login DN: `cn=admin,dc=example,dc=com`
* password: password
