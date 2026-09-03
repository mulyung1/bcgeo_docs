# Welcome to BCGeo Dev 

Grab yourself a :coffee:

This space is for techies to get a view of customizations made to the GeoNode project.

- [Installation](#installation)
- [Bridge network](#bridge-network)
- [Assigning a static IP](#assigning-a-static-ip)
- [CSRF protection](#csrf-protection)
- [Customizing docker geonode- mac host](#customizing-docker-geonode--mac-host)
  - [color/css styles](#colorcss-styles)
  - [customization workflow](#customization-workflow)
  - [Transalations](#transalations)
- [Geonode as a django app](#geonode-as-a-django-app)
- [Geonode APIs](#geonode-apis)
  - [OGC Web Services](#ogc-web-services)

## Installation

Read the official documentation on container spin up [here](https://docs.geonode.org/en/latest/setup/docker/project-docker-installation/)

### Production environment:

```bash
sudo adduser geonode
#password: geonode1516

sudo usermod -a -G www-data geonode

# in case of GeoNode project
sudo mkdir -p /opt/geo_django_dev/.prod/bcgeo
sudo chown -Rf geonode:www-data /opt/geo_django_dev/.prod/bcgeo
sudo chmod -Rf 775 /opt/geo_django_dev/.prod/bcgeo
```
## Bridge network
**Why its needed** 
Our geonode instance is running in a vm.

We need to give this VM an IP so that it can be seen as a separate machine

As a separate machine, we can now give this IP a domain name(where our users will interact with geonode, the browser).

### Assigning a static IP
I went through an error like: 'activation of network connection failed'

2 solutions
one use wifi adapter in bridged interface
two:is to assign a ststic ip to the vm.

the steps are like

**1. Find the gateway (router) for the bridge**
On macOS Terminal:

```zsh

netstat -nr -f inet | grep default | grep en18

```

repalce en18 with your interface name.

You’ll see a line like:
```text
default            172.28.67.1        UGSc           en18
```

The gateway is the first IP after default (e.g. 172.28.67.1). Write it down.


**2.  Identify an unused IP address in the subnet**

Scan the whole subnet for active devices (requires nmap):
```zsh
sudo nmap -sn 172.28.67.0/24
```
This will list all responsive hosts. Pick any address not in that list.


**3. Assign the static IP inside the VM**

Run these commands inside the Ubuntu VM (replace the IP and gateway if yours differ):

```zsh
sudo ip addr add 172.28.67.200/24 dev enp0s1
sudo ip route add default via 172.28.67.1
```

replace enp0s1 with the name of your vm's interface name

**4. Test connectivity**
```zsh

ping 172.28.67.1        # gateway
ping 172.28.67.58       # your Mac
ping 8.8.8.8            # internet (Google DNS)

```
**5. Make the static IP permanent (if test succeeded)**

Edit the Netplan configuration file:

```zsh
sudo nano /etc/netplan/01-netcfg.yaml
```

Replace its contents with:

```yaml

network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s1:
      addresses:
        - 172.28.67.200/24
      routes:
        - to: default
          via: 172.28.67.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

Apply:

```zsh
sudo netplan apply
```

### Set up ssh to vm for code editing
1. Install OpenSSH Server

```bash
# Update your package repository list
sudo apt update

# Install the OpenSSH server package
sudo apt install openssh-server -y
```

2. Start and Enable the SSH Service
```bash
# Start and enable the service immediately
sudo systemctl enable --now ssh

# Verify that the service is running successfully
sudo systemctl status ssh

```

3. Configure the Firewall (Allow SSH Access)
```bash
# Allow standard SSH traffic through UFW
sudo ufw allow OpenSSH

# Reload the firewall to apply changes
sudo ufw reload

# Check the firewall status to confirm the rule is active
sudo ufw status

```

4. Find Your Server's IP Address

```bash
ip a
```
5. Connect Remotely From Another Machine
```bash
ssh ubuntu_username@your_ubuntu_ip
```


## CSRF protection

The django project is disbursed in production mode.

This means, strict rules especially from different hosts.

In form submission, the scheme expected is HTTPS(secure) via the 'Same site secure' condition 

using the environment variables below, we can disable the Secure tag on 
- CSRF &
- Session Id tokens for development

```text
#disable the secure flag on csrf and session id cookies for dev purposes
CSRF_COOKIE_SECURE=False
SESSION_COOKIE_SECURE=False
```



## Customizing docker geonode- mac host
### color/css styles
found in https://geonode.org/geonode-mapstore-client/master/tutorial-theme.html

ms primary - 39ac71
ms link-color - 39ac71
ms footer-link-color - 39ac71
ms link-hover-color - ffd700
ms footer-link-hover-color - ffd700

### customization workflow

**Dev Mode**

- bind the dev directory ./src/ as a volume in compose yaml 
- Edit templates & static files directly in ./src/ 
- Repeat edits and collectstatic until UI is perfect

**Prod Mode**

- Build final image `docker compose build django` to bake in all changes
- Comment out the bind dir `- './src:/usr/src/geonode_project'` in compose yaml
- Stop & start containers `docker compose down && docker compose up -d` 
  - entrypoint auto‑runs collectstatic

- Validate in incognito window – navbar white, logo, hero image all load


**hard refresh >> collectstatic**

```zsh
docker compose exec django python manage.py collectstatic --noinput --clear
```

### Transalations
- requires gettext installed.
- inside container, install gettext

##TODO: Install it during image build

```zsh
docker-compose exec django bash
apt-get update && apt-get install -y gettext
```

This guide adds translations for the 
- geonode-mapstore-client single page app
- django template.

1 **Limit the List of languages**

edit .env file in geonode project.

uncomment/add this

```text
LANGUAGE_CODE=en
LANGUAGES=(('en-us','English'),('fr-fr', 'French'))
```
2 **Update translation in Django templates**

edit the hero.html template created during title customization in the jumbotron

add to the hero div,
- {% load i18n %}
- Translation block: {% trans } >> wraps the title and description

```html

{% load i18n %}
<div id="gn-hero" class="gn-hero">
    
    <!-- Background Slides -->
    ...

    <!-- Hero Content -->
    <div class="jumbotron">
        <div class="gn-hero-description">
          <!-- mark h1 and p tags for translation(using translation block) when you run django-admin makemessages... -->
            <h1>{% trans "Welcome to the Benin Climate Geoportal (BCGeo)" %}</h1>
            <p>{% trans "This space gives you access to reliable, up-to-date and georeferenced data to understand, analyse and anticipate the impacts of climate change in our country." %}</p>
        </div>
        <p class="gn-hero-tools">
            <!-- Your buttons/links go here -->
        </p>
    </div>
</div>
```


- Now create a new locale folder inside the geonode project

- run(in dir where manage.py lives) this script to create the locale files(.po files)

```bash
django-admin makemessages --no-wrap --no-location -l en_US -l fr_FR -d django -e "html,txt,py" -i docs 
```

_Note: the flag `-l` <locale> can be used multiple times for each language supported in the project_

- lets now edit the .po files to add french translations.

- Inside the `django.po` file we will find empty string for each `msgstr` property that could be filled with the translation

- Finally we can compile the locale(_language code_) file to make them available to the django templates

```bash
django-admin compilemessages
```
you will see output like:
```bash
(docker_env) mulyung1@ubuntu2404:~/geonode_projects/my_geonode$ django-admin makemessages --no-location -l en_US -l it_FR -d django -e "html,txt,py" -i docs
processing locale en_US
processing locale it_FR
(docker_env) mulyung1@ubuntu2404:~/geonode_projects/my_geonode$ django-admin compilemessages
processing file django.po in /home/mulyung1/geonode_projects/my_geonode/src/geonode_project/locale/it_FR/LC_MESSAGES
processing file django.po in /home/mulyung1/geonode_projects/my_geonode/src/geonode_project/locale/en_US/LC_MESSAGES
(docker_env) mulyung1@ubuntu2404:~/geonode_projects/my_geonode$ 
```
ensure the generated `django.mo` files are present in app.

**how to overide the menu items**

read this resource: https://chat.deepseek.com/share/a6i0pwf00wctmz8h2r

avatar source:

https://www.cleanpng.com/png-computer-icons-user-technical-support-people-icon-ydwjks/download-png.html

add avatar.png to `static/geonode/img/avatar.png`

refresh browser


## Geonode as a django app
You can read more on django app [here](https://github.com/mulyung1/gis_spacial/blob/main/web_gis_softwares/geonode/test_django_app/README.md)


## Geonode APIs
### OGC Web Services
- geonode provides a standards based platform
- this enables integrated, programmatic access to your data via OGC Web Services.
- the web services enable `discovery`, `visualization`, and access your data without interacting directly with the UI

OGC Web Services:

  -  operate over HTTP (GET, POST)
  -  provide a formalized, accepted API
  -  provide formalized, accepted formats

You may use these services via:
- desktop GIS
- web-based app
- client libraries/toolkits
- custom development




### References
- https://geonode-docs.readthedocs.io/en/stable/tutorials/devel/projects/theme.html#bootswatch
- https://chat.deepseek.com/share/dd0rntjvee6pwj5el5
- https://chat.deepseek.com/share/kuuj7a7ub3oagdmwbn
- https://docs.geoserver.org/main/en/user/security/webadmin/csrf/
- https://training.geonode.geosolutionsgroup.com/master/GN4/101_CUSTOMIZE_LF.html
- https://training.geonode.geosolutionsgroup.com/master/GN4/102_TRANSLATIONS.html
- https://training.geonode.geosolutionsgroup.com/master/GN4/102_TRANSLATIONS.html#update-translation-in-django-templates
- https://geonode-docs.readthedocs.io/en/latest/tutorials/devel/api/ogc.html


- https://jameswillett.dev/getting-started-with-material-for-mkdocs/#footer