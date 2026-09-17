# SSL Certificates

## **overview**

SSL certificates encrypt data sent from client to server.

- This scrambles sensitive info like passwords and credit card info during transit

- They also verify that a website belongs to the stated owner.

- 

Let's Encrypt is a free, automated **open Certificate Authority.**

- It issues SSL/TLS certificates to allow websites use secure HTTPS conections

- Certbot, a free-opensource software fetches and installs certificates.

    - it is the client that speaks to let's encrypt servers

## **Add cetificates**

in geonode, we change our `.env` file like:

```text

DOCKER_ENV=production
SITEURL=https://climat.gouv.bj
NGINX_BASE_URL=https://climat.gouv.bj
ALLOWED_HOSTS=['django', 'climat.gouv.bj']
GEOSERVER_WEB_UI_LOCATION=https://climat.gouv.bjgeoserver/
GEOSERVER_PUBLIC_LOCATION=https://climat.gouv.bjgeoserver/
HTTP_HOST=
HTTPS_HOST=climat.gouv.bj
HTTP_PORT=80
HTTPS_PORT=443
LETSENCRYPT_MODE=produc
```

??? info "Remember!!"

    When `LETSENCRYPT_MODE` is set to `production`, a valid email and email SMPT server are required to make the system generate a valid certificate

Thus set an admin email

```text
ADMIN_EMAIL=<set a valid email>
```

## **Restart the containers**

Whenever changes are done to `.env`, you need to rebuild the container.

```zsh
docker compose down

docker compose up -d
```

### **Inspect certificate generation**

Check certs container to debug

```zsh
docker compose logs -f letsencrypt
```

If everything goes ok, you'll see print out like:

```zsh
letsencrypt4geonode_project  | $\n\n\n
letsencrypt4geonode_project  | -----------------------------------------------------
letsencrypt4geonode_project  | STARTING LETSENCRYPT ENTRYPOINT ---------------------
letsencrypt4geonode_project  | Wed Sep 16 12:51:06 UTC 2026
letsencrypt4geonode_project  | 
letsencrypt4geonode_project  | Trying to get PRODUCTION certificate
letsencrypt4geonode_project  | Saving debug log to /var/log/letsencrypt/letsencrypt.log
letsencrypt4geonode_project  | Account registered.
letsencrypt4geonode_project  | Requesting a certificate for climat.gouv.bj
letsencrypt4geonode_project  | 
letsencrypt4geonode_project  | Successfully received certificate.
letsencrypt4geonode_project  | Certificate is saved at: /geonode-certificates/production/live/climat.gouv.bj/fullchain.pem
letsencrypt4geonode_project  | Key is saved at:         /geonode-certificates/production/live/climat.gouv.bj/privkey.pem
letsencrypt4geonode_project  | This certificate expires on 2026-12-15.
letsencrypt4geonode_project  | These files will be updated when the certificate renews.
letsencrypt4geonode_project  | NEXT STEPS:
letsencrypt4geonode_project  | - The certificate will need to be renewed before it expires. Certbot can automatically renew the certificate in the background, but you may need to take steps to enable that functionality. See https://certbot.org/renewal-setup for instructions.
letsencrypt4geonode_project  | 
letsencrypt4geonode_project  | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
letsencrypt4geonode_project  | If you like Certbot, please consider supporting our work by:
letsencrypt4geonode_project  |  * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
letsencrypt4geonode_project  |  * Donating to EFF:                    https://eff.org/donate-le
letsencrypt4geonode_project  | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
letsencrypt4geonode_project  | 
letsencrypt4geonode_project  | Certificate have been created/renewed successfully
letsencrypt4geonode_project  | -----------------------------------------------------
letsencrypt4geonode_project  | FINISHED LETSENCRYPT ENTRYPOINT ---------------------
letsencrypt4geonode_project  | -----------------------------------------------------
```


## **references**

- [Deploy geonode on a production server](https://docs.geonode.org/projects/v4/en/4.4.x/install/basic/index.html#second-step-deploy-geonode-on-a-production-server)
- [Automated renewal of Let's Encrypt Certs](https://eff-certbot.readthedocs.io/en/latest/using.html#setting-up-automated-renewal)