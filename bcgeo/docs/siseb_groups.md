# SISEB >> BCGeo Groups

!!! tip Remember

    check the [`group creation guide`](sso.md)

## Task

There are groups in SISEB.

    - They are to be added into BCGeo

The flow is like:

- Get list of top-level groups in siseb(the 4 siseb modules)

    - For every subgroup, create a group with same name in Geoportal

    - claims are already present in oidc token, make use of them.


## **1. Get the access token**

export the client secret to terminal session

```zsh
export SECRET='YOUR_CLIENT_SECRET'
```

get the access token

```zsh
TOKEN=$(curl -s -X POST \
  "https://auth-siseb.gouv.bj/realms/siseb/protocol/openid-connect/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=siseb-geoportail" \
  -d "client_secret=$SECRET" | jq -r .access_token)

```

## **2. list top level groups**

```zsh
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://auth-siseb.gouv.bj/admin/realms/siseb/groups" | jq
```
??? abstract "Top Level Groups"

    ```json
    [
        {
            "id": "fd5f5b59-f283-40b9-a577-4e08a9005833",
            "name": "MODULE ACTIVITE",
            "path": "/MODULE ACTIVITE",
            "subGroupCount": 0,
            "subGroups": [],
            "access": {
            "view": true,
            "viewMembers": true,
            "manageMembers": false,
            "manage": false,
            "manageMembership": false
            }
        },
        {
            "id": "4546916e-0030-47c4-8401-aea042031575",
            "name": "MODULE PROJET",
            "path": "/MODULE PROJET",
            "subGroupCount": 0,
            "subGroups": [],
            "access": {
            "view": true,
            "viewMembers": true,
            "manageMembers": false,
            "manage": false,
            "manageMembership": false
            }
        },
        {
            "id": "8fb0c6ab-7771-460d-a5dc-5e09b7d1722b",
            "name": "MODULE STATISTIQUE",
            "path": "/MODULE STATISTIQUE",
            "subGroupCount": 0,
            "subGroups": [],
            "access": {
            "view": true,
            "viewMembers": true,
            "manageMembers": false,
            "manage": false,
            "manageMembership": false
            }
        },
        {
            "id": "2903c6be-9a10-4fc1-bbb0-afdfc64c308b",
            "name": "STRUCTURES",
            "path": "/STRUCTURES",
            "subGroupCount": 75,
            "subGroups": [],
            "access": {
            "view": true,
            "viewMembers": true,
            "manageMembers": false,
            "manage": false,
            "manageMembership": false
            }
        }
    ]
    ```

## **3. Get the sub-groups**

these will be the actual groups in BCGeo

currently, only `/STRUCTURES` has subgroups

```zsh
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://auth-siseb.gouv.bj/admin/realms/siseb/groups/2903c6be-9a10-4fc1-bbb0-afdfc64c308b/children?first=0&max=100" | jq
```

## **4. Get members in `/STRUCTURES`**

Read more [here](https://www.keycloak.org/docs-api/latest/rest-api/index.html#_get_adminrealmsrealmgroupsgroup_idmembers)

```zsh
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://auth-siseb.gouv.bj/admin/realms/siseb/groups/2903c6be-9a10-4fc1-bbb0-afdfc64c308b/members" | jq
```

**Inspect a users info**

```zsh
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://auth-siseb.gouv.bj/admin/realms/siseb/users/0971f6a9-5d81-476d-87d4-b10a31d1196f" | jq .

curl -s -H "Authorization: Bearer $TOKEN" \
  "https://auth-siseb.gouv.bj/admin/realms/siseb/users/0971f6a9-5d81-476d-87d4-b10a31d1196f" | jq .



```

## References

- [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/index.html)
- [Groups Endpoint](https://www.keycloak.org/docs-api/latest/rest-api/index.html#_get_adminrealmsrealmgroups)
- [SubGroups Endpoint](https://www.keycloak.org/docs-api/latest/rest-api/index.html#_get_adminrealmsrealmgroupsgroup_idchildren)
