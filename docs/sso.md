# Single-Sign-On

SISEB and BCGeo need a sso utility.

- that is, we need to manage users and groups from a single source.
- hence keycloack
- initially we use a separate dockerised keycloack implementation like

_Find kyclk docs [here](https://www.keycloak.org/getting-started/getting-started-docker)_


- [Start Keycloack](#start-keycloack)
- [Login to admin console & Create a Realm](#login-to-admin-console--create-a-realm)
- [Create a user](#create-a-user)
- [Secure BCGeo](#secure-bcgeo)
- [Geonode integration](#geonode-integration)
- [Register a new social app in django admin console](#register-a-new-social-app-in-django-admin-console)
- [Adding Keycloack Groups to OIDC Token](#adding-keycloack-groups-to-oidc-token)
    - [Architcture](#architcture)
    - [1. Create the group in Keycloak](#1-create-the-group-in-keycloak)
    - [2. Tell Keycloak to put groups into the OIDC token](#2-tell-keycloak-to-put-groups-into-the-oidc-token)
    - [3. Testing](#3-testing)
    - [4. Create the corresponding group in geonode](#4-create-the-corresponding-group-in-geonode)


## Start Keycloack
create a `docker-compose.yml` file like:

```yaml

services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    container_name: keycloak_server
    restart: unless-stopped
    command: start-dev
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: change_me
    ports:
      - "0.0.0.0:8080:8080"
    volumes:
      - /home/mulyung1/keycloak/_data:/opt/keycloak/data

~              
```

start the keycloack_server like:

```zsh
docker compose up -d
```
find your admin panel at

`http://your_machine_ip:8080`

## Login to admin console & Create a Realm


a realm is like a tenant.

each realm allows admins create isolated groups of apps & users

initial realm is called master realm

to create 1st realm
- open the admin console
- click `manage realms`(in left column) 
- click `create realm`
- enter `Benin CLimate GeoPortal` in the *Realm name* field
- click create

![alt text](assets/create_realm_image.png)

## Create a user

the realm has no users yet

- verify you're still in the *Benin CLimate GeoPortal* realm
- click `Users`(left hand menu)
- click `Create new user`
- Fill in the form
- click `Create`

![alt text](assets/create_user_image.png)

our user needs a password to login. to set the initial passwd:
- click `Credentials`(top of the page)
- fill the `Set password` form
- toggle `Temporary` to `off`(so user won't need to update password at 1st login)

![alt text](assets/set_passwd_image.png)

## Secure BCGeo
register BCGeo(your_app) with your kyclk instance:
- open the admin console
- click `Benin Climate GeoPortal` next to `Current realm`
- click `Clients`
- click `Create client`
- fill the form like:
    - `Client type` : **OpenID Connect**
    - `Client ID` : **bcgeo**

![alt text](assets/create_client_image.png)

- ckick `Next`
- Confirm that `Standard flow` is enabled
- toggle `Client authentication` to `ON`

![alt text](assets/client_settings_image.png)

- click `Next`
- in logi settings:
    - set `Valid redirect URIs to `http://192.168.8.41/account/geonode_openid_connect/login/callback/`
    - set `Web Origins` to `http://192.168.8.41`

![alt text](assets/login_settings_image.png)
- click `Save` 

## Geonode integration

in `settings.py`, add the new `SOCIALACCOUNT_PROVIDER`, now kyclk.

```python

# ============================================================
# Keycloak OpenID Connect
# ============================================================

KEYCLOAK_BASE_URL = os.getenv(
    "KEYCLOAK_BASE_URL"
)

SOCIALACCOUNT_PROVIDERS = {
    "geonode_openid_connect": {
        "NAME": "Keycloak",

        "SCOPE": [
            "openid",
            "profile",
            "email",
        ],

        "AUTH_PARAMS": {
            "prompt": "login",
        },

        "COMMON_FIELDS": {
            "email": "email",
            "first_name": "given_name",
            "last_name": "family_name",
        },

        "UID_FIELD": "sub",

        "GROUP_ROLE_MAPPER_CLASS": (
            "geonode.people.profileextractors.OpenIDGroupRoleMapper"
        ),

        "ACCESS_TOKEN_URL": (
            f"{KEYCLOAK_BASE_URL}/protocol/openid-connect/token"
        ),

        "AUTHORIZE_URL": (
            f"{KEYCLOAK_BASE_URL}/protocol/openid-connect/auth"
        ),

        "PROFILE_URL": (
            f"{KEYCLOAK_BASE_URL}/protocol/openid-connect/userinfo"
        ),

        "ID_TOKEN_ISSUER": KEYCLOAK_BASE_URL,
    }
}
```

in your `.env` file add:
```text
# ============================================================
# Keycloak / OpenID Connect
# ============================================================

SOCIALACCOUNT_OIDC_PROVIDER_ENABLED=True
SOCIALACCOUNT_OIDC_PROVIDER=geonode_openid_connect
SOCIALACCOUNT_AUTO_SIGNUP=True
SOCIALACCOUNT_LOGIN_ON_GET=True
SOCIALACCOUNT_WITH_GEONODE_LOCAL_SINGUP=True
SOCIALACCOUNT_SYNC_USER_GROUPS_ON_LOGIN=FULL_SYNC
KEYCLOAK_BASE_URL="http://192.168.8.41:8080/realms/geonode_dev"

```


Recreate your django container

```zsh
docker compose up -d --force-recreate django
```

## Register a new social app in django admin console

- open admin console in django
- go to `Social Accounts>>Social applications`
    - Provider is now set to `Keycloak` not google(default)
    - fill `Name` to your 3rd party auth app: `Keycloack`
    - add `client id`(add the client id from keycloak): `bcgeo`
    - add `Secret key`(find this in `Credentials` tab under bcgeo client)
    - add domain name or ip of keycloack server in `Sites`
    - `save`
![alt text](assets/django_adm_image.png)


Now the app has a thirdparty login solution like:

![alt text](assets/login_image.png)

hitting sign in with keycloak gets you to

![alt text](assets/kyclk_image.png)

# Adding Keycloack Groups to OIDC Token

Keycloak is the chosen single source of truth for user membership, within SISEB and BCGeo.

GeoNode 5.0.1 does not create the GeoNode group automatically from the Keycloak group.

The GeoNode group must already exist, and the Keycloak group name must match the GeoNode group slug. 

On login, GeoNode reads the groups claim and adds/removes the user from the corresponding GeoNode groups

## Architcture:

                    ┌──────────────────────┐
                    │      Keycloak        │
                    │                      │
                    │ Users                │
                    │ Groups               │
                    │ User ↔ Group         │
                    └──────────┬───────────┘
                               │
                         OIDC login
                               │
                       groups claim
                               │
                               ▼
                    ┌──────────────────────┐
                    │       GeoNode        │
                    │                      │
                    │ Django User          │
                    │ GeoNode Group        │
                    │ User ↔ Group         │
                    └──────────────────────┘

GeoNode 5.0.1's [`GenericOpenIDConnectAdapter`](https://raw.githubusercontent.com/GeoNode/geonode/5.0.1/geonode/people/adapters.py) 
- extracts groups from the OIDC response, 
- parses each group, 
- looks up a GroupProfile by slug, and 
- joins the user to that group. 
- It also removes the user from groups that aren't present in the claim


## 1. Create the group in Keycloak

In geonode_dev realm:
- go to `Groups`
    - create a group `mcvt`
![alt text](assets/grp_image.png)

- inside mcvt group, go to `Members` tab
    - click `Add Member`
    - choose a member from the list

![alt text](assets/member_image.png)

by now, Keycloack knows:

```markdown
victor
   └── mcvt
```

## 2. Tell Keycloak to put groups into the OIDC token

- Keycloak has a built-in Group Membership OIDC protocol mapper, read more [here](https://www.keycloak.org/admin-api/protocol-mappers?utm_source=chatgpt.com#oidc-group-membership-mapper)

- It maps a user's Keycloak group membership into a token claim. 

- It also supports ID token, access token and userinfo output.

- Click `Client scopes`
- Hit `Create client scope`
- Fill values like:
    - Name: groups
    - Protocol: OpenID Connect
    - Toggle display consent screen to `off`

![alt text](assets/scope_image.png)

- Hit `Save`

Add this client scope to your client

- Go to `Clients` >> `bcgeo` >> `Add client scope` 
- `groups`will show up, click on it


Configure a mapper for this scope

- Go to `Client scopes`
- Hit the `Mappers` tab
- if no mapper exists, hit `configure new mapper` >> choose `Group Membership` mapper
![alt text](assets/conf_image.png)
    - else, hit 'Add Mapper' >> `by configuration` >> choose `Group Membership` 

- fill in the form like:

![alt text](assets/mapper_image.png)

For GeoNode integration, 
- Add to userinfo key as the GeoNode adapter calls the OIDC userinfo endpoint and merges that data into `extra_data`

## 3. Testing

Hit keycloaks token endopoint to get the token like
- for this to run ensure you have given the client `Direct grant access rights` in keycloack admin panel.

```zsh
curl POST \
  "http://172.28.70.236:8080/realms/geonode_dev/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=bcgeo" \
  -d "client_secret=4LF8zMuWwMAYZk01vEMR4cxB9NIbWcwDysfOcxZLyWrBuPBPLo38SXRMLdVBOOHtpI9nItGjuSscAnITQftTIl" \
  -d "username=vicky" \
  -d "password=ex1414ps33." \
  -d "grant_type=password" \
  -d "scope=openid profile email"
```
![alt text](assets/tkn_ept_image.png)

get the access token value to get user info.

we expect the groups to be added as a claim like:
```zsh
curl \
  "http://172.28.70.236:8080/realms/geonode_dev/protocol/openid-connect/userinfo" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIzZWNuREQ0RHVyZTVaSDhkWXZpbmo2Vi1QTnZjZHpoOG9PaTFrZlR4bTdBIn0.eyJleHAiOjE3ODgyNjYxMTAsImlhdCI6MTc4ODI2NTgxMCwianRpIjoib25ydHJvOjY5ZjFhYjA5LTlkYmQtMDY4Ni1jMTlhLTQ0NTUwMGU3Y2M4NCIsImlzcyI6Imh0dHA6Ly8xNzIuMjguNzAuMjM2OjgwODAvcmVhbG1zL2dlb25vZGVfZGV2IiwiYXVkIjoiYWNjb3VudCIsInN1YiI6ImM1MjQ3OTZjLTllZDItNDRlZS04NDJjLTU5ZGY3MzhiZTE0YyIsInR5cCI6IkJlYXJlciIsImF6cCI6ImJjZ2VvIiwic2lkIjoiTGdPTGNKT0ZqUVo0bWREbDBiZGdyRW5VIiwiYWNyIjoiMSIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwOi8vMTcyLjI4LjcwLjIzNiJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsiZGVmYXVsdC1yb2xlcy1iZW5pbiBjbGltYXRlIGdlb3BvcnRhbCIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJuYW1lIjoiVmljdG9yIE11bHl1bmdpIiwiZ3JvdXBzIjpbIm1jdnQiXSwicHJlZmVycmVkX3VzZXJuYW1lIjoidmlja3kiLCJnaXZlbl9uYW1lIjoiVmljdG9yIiwiZmFtaWx5X25hbWUiOiJNdWx5dW5naSIsImVtYWlsIjoidmlja3ltdWx5dW5nczE5OTlAZ21haWwuY29tIn0.iLKXZ3L72QUIzL4-LDO5q4IWPOOpBBPmb4XJ4WsayeRoj1f5xoVhopwXmqXIUXYTCHOx0rqUTDsfN4hm4IDbcIp7nFbj_6gh2puLEA9lAlE6qoJSZr4JHaA5N0LDcHXevvK8LmX9S81J7CY9-VKBGWb_2HgVAG43BghPCJsnRIj7cMO566tTvoMF_-g4c2u5ZVodM8DLVOOciCqcUFM5bx2AawVZ278UdAVO6a4ijF4IChd8FsRVYRRHAb97a8AdcxJl47SlV-HlpFtUJ8c70ZVBOtwvmqN_s11MjwP_Dqa56j0XtmEnmSs4P76Vyw8VOSPkwFbpozG0E7QkjOfdbg"


{
  "sub":"c524796c-9ed2-44ee-842c-59df738be14c",
  "email_verified":false,
  "name":"Victor Mulyungi",
  "groups":["mcvt"],
  "preferred_username":"vicky",
  "given_name":"Victor",
  "family_name":"Mulyungi",
  "email":"vickymulyungs1999@gmail.com"
}
```

## 4. Create the corresponding group in geonode

Now we need GeoNode to consume `groups: ["mcvt"]` and synchronize it to a Django/GeoNode group.

syncing is handled by our env variable `SOCIALACCOUNT_SYNC_USER_GROUPS_ON_LOGIN = "FULL_SYNC"`

- create a GeoNode group with the exact same name as the Keycloak group:

    - Go to admin home page in geononde
    - In profile, click `create group`

![alt text](assets/grp2_image.png)
![alt text](assets/crt_grp_image.png)

    - 

```text
Keycloak
└── mcvt

GeoNode
└── mcvt
```

![alt text](assets/layout_image.png)

_NOTE: the group name must match what is in keycloack token claim_

- Log in with keycloack as user vicky.
- geononde synchronises the groups and add you to same group in geonode.

![alt text](assets/members_image.png)

When Victor logs in through Keycloak, the flow is:
```text

                    KEYCLOAK
                realm: geonode_dev
                       │
                       │
              ┌────────┴────────┐
              │                 │
           User: vicky       Group: mcvt
              │                 │
              └────────┬────────┘
                       │
                       ▼
                OIDC authentication
                       │
                       ▼
              groups claim mapper
                       │
                       ▼
             /userinfo endpoint
                       │
                       ▼
              {
                "preferred_username": "vicky",
                "email": "...",
                "groups": ["mcvt"]
              }
                       │
                       ▼
                    GEONODE
                       │
                       ▼
             GenericOpenIDConnectAdapter
                       │
                       ▼
                 Django User
                    vicky
                       │
                       ▼
             Group synchronization
                       │
                       ▼
               Django Group
                   mcvt
                       │
                       ▼
                 vicky ∈ mcvt
                       │
                       ▼
              GeoNode permissions

```
## References

- https://chatgpt.com/s/t_6a86db279c5c8191846bb5d66837e808
- https://www.keycloak.org/admin-api/protocol-mappers?utm_source=chatgpt.com#oidc-group-membership-mapper
- https://raw.githubusercontent.com/GeoNode/geonode/5.0.1/geonode/people/adapters.py
- https://chatgpt.com/s/t_6a98004b4b748191bc54b8549f065d61

