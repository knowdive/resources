# A - [Installing CKAN from source](https://docs.ckan.org/en/2.8/maintaining/installing/install-from-source.html)

## 1. Install the required packages
    sudo apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-8-jdk redis-server

## 2. Install CKAN into a Python virtual environment
### a. Create a Python virtual environment (virtualenv) to install CKAN into, and activate it:
    sudo mkdir -p /usr/lib/ckan/default
    sudo chown 'whoami' /usr/lib/ckan/default
    virtualenv --python=/usr/bin/python2.7 --no-site-packages /usr/lib/ckan/default
    . /usr/lib/ckan/default/bin/activate
### b. Install the recommended ``setuptools`` version:
    pip install setuptools==36.1
### c. Install the CKAN source code into your virtualenv.
    pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.8.2#egg=ckan'
### d. Install the Python modules that CKAN requires into your virtualenv:
    pip install -r /usr/lib/ckan/default/src/ckan/requirements.txt
### e. Deactivate and reactivate your virtualenv, to make sure you’re using the virtualenv’s copies of commands like ``paster`` rather than any system-wide installed copies:
    deactivate
    . /usr/lib/ckan/default/bin/activate

## 3. Setup a PostgreSQL database
### a. Check that PostgreSQL was installed correctly by listing the existing databases:
    sudo -u postgres psql -l
### b. Create a new PostgreSQL database user called ckan_default, and enter a password(password) for the user when prompted. You’ll need this password later:
    sudo -u postgres createuser -S -D -R -P ckan_default
### c. Create a new PostgreSQL database, called ckan_default, owned by the database user you just created:
    sudo -u postgres createdb -O ckan_default ckan_default -E utf-8

## 4. Create a CKAN config file
### a. Create a directory to contain the site’s config files:
    sudo mkdir -p /etc/ckan/default
    sudo chown -R 'whoami' /etc/ckan/
### b. Create the CKAN config file:
    paster make-config ckan /etc/ckan/default/development.ini
### c. Edit the ``development.ini`` file in a text editor, changing the following options:
**sqlalchemy.url**: 
This should refer to the database we created in 3. Setup a PostgreSQL database above:

    sqlalchemy.url = postgresql://ckan_default:pass@localhost/ckan_default
        Replace ``pass`` with the password that you created in 3. Setup a PostgreSQL database above.
**site_id**:
Each CKAN site should have a unique ``site_id``, for example:

    ckan.site_id = default
**site_url**:
Provide the site’s URL (used when putting links to the site into the FileStore, notification emails etc). For example:

    ckan.site_url = http://demo.ckan.org
        Do not add a trailing slash to the URL.

## 5. Setup Solr
### a. Do this step only if you are using Ubuntu 18.04.
    sudo ln -s /etc/solr/solr-jetty.xml /var/lib/jetty9/webapps/solr.xml
### b. The Jetty port value must also be changed on jetty9. To do that, edit the jetty.port value in /etc/jetty9/start.ini:
    jetty.port=8983  # (line 23)
### c. Edit the Jetty configuration file (``/etc/default/jetty9``) and change the following variables:
    NO_START=0            # (line 4)
    JETTY_HOST=127.0.0.1  # (line 16)
    JETTY_PORT=8983       # (line 19)
### d. Start or restart the Jetty server.
    sudo service jetty9 restart
        You should now see a welcome page from Solr if you open http://localhost:8983/solr/, otherwise there is an error but continue with the following steps
### e. Replace the default ``schema.xml`` file with a symlink to the CKAN schema file included in the sources.
    sudo mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
    sudo ln -s /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
### f. Finally, change the solr_url setting in your CKAN configuration file (``/etc/ckan/default/development.ini``) to point to your Solr server, for example:
    solr_url=http://127.0.0.1:8983/solr
### g. Now restart Solr:
    sudo service jetty9 restart
        Check that Solr is running by opening http://localhost:8983/solr/. If it is then continue directly with the steps of 6, otherwise there is an error so continue with all the following steps of 5

### h. Make the following solr updates:
    sudo mkdir /etc/systemd/system/jetty9.service.d
### i. Edit ``/etc/systemd/system/jetty9.service.d/solr.conf`` and add
    [Service]
    ReadWritePaths=/var/lib/solr
### j. Edit ``/etc/solr/solr-jetty.xml`` and replace with the below configuration:
    <?xml version="1.0"  encoding="ISO-8859-1"?>
    <!DOCTYPE Configure PUBLIC "-//Jetty//Configure//EN" "http://www.eclipse.org/jetty/configure.dtd">

    <!-- Context configuration file for the Solr web application in Jetty -->

    <Configure class="org.eclipse.jetty.webapp.WebAppContext">
    <Set name="contextPath">/solr</Set>
    <Set name="war">/usr/share/solr/web</Set>

    <!-- Set the solr.solr.home system property -->
    <Call name="setProperty" class="java.lang.System">
        <Arg type="String">solr.solr.home</Arg>
        <Arg type="String">/usr/share/solr</Arg>
    </Call>

    <!-- Enable symlinks -->
    <!-- Disabled due to being deprecated
    <Call name="addAliasCheck">
        <Arg>
        <New class="org.eclipse.jetty.server.handler.ContextHandler$ApproveSameSuffixAliases"/>
        </Arg>
    </Call>
    -->
    </Configure>
### k. Restart jetty9 
    sudo service jetty9 restart
    systemctl daemon-reload

### l. Download a fix for the lucene error
    wget https://github.com/knowdive/resources/raw/master/lucene3-core-3.6.2.jar -P ~/Downloads/
### m. Copy the fix to the java directory
    cp ~/Downloads/lucene3-core-3.6.2.jar /usr/share/java/lucene3-core-3.6.2.jar
### k. Restart jetty9 
    sudo service jetty9 restart

## 6. Link to who.ini
### a. ``who.ini`` (the Repoze.who configuration file) needs to be accessible in the same directory as your CKAN config file, so create a symlink to it:
    ln -s /usr/lib/ckan/default/src/ckan/who.ini /etc/ckan/default/who.ini

## 7. Create database tables
### a. Create the database tables:
    cd /usr/lib/ckan/default/src/ckan
    paster db init -c /etc/ckan/default/development.ini
        You should see ``Initialising DB: SUCCESS``.

## 8. Set up the DataStore
### Setting up the DataStore is optional. If you do skip this step, the DataStore features will not be available
### Follow the instructions in [DataStore extension](https://docs.ckan.org/en/2.8/maintaining/datastore.html) to create the required databases and users, set the right permissions and set the appropriate values in your CKAN config file.

## 9. You’re done!
### You can now use the Paste development server to serve CKAN from the command-line. This is a simple and lightweight way to serve CKAN that is useful for development and testing:
    . /usr/lib/ckan/default/bin/activate
    cd /usr/lib/ckan/default/src/ckan
    paster serve /etc/ckan/default/development.ini
### Open http://127.0.0.1:5000/ in a web browser, and you should see the CKAN front page.

## 10. Getting started
### https://docs.ckan.org/en/2.8/maintaining/getting-started.html

### a. Creating a sysadmin user
#### Make sure that your virtualenv is activated and that you’re in your ckan source directory.
    . /usr/lib/ckan/default/bin/activate
    cd /usr/lib/ckan/default/src/ckan
#### You have to create your first CKAN sysadmin user from the command line. For example, to create a new user called seanh and make him a sysadmin:
    paster sysadmin add admin email=admin@liveschema.org name=admin -c /etc/ckan/default/development.ini
#### You’ll be prompted to enter a password during account creation

### b. [Configuration Options](https://docs.ckan.org/en/2.8/maintaining/configuration.html)

# B - [Theming guide](https://docs.ckan.org/en/2.8/theming/index.html)
## The following sections will teach you how to customize the content and appearance of CKAN pages by developing your own CKAN themes.

## 1. [Customizing CKAN’s templates](https://docs.ckan.org/en/2.8/theming/templates.html)
### Creating a CKAN extension
### A CKAN theme is simply a CKAN plugin that contains some custom templates and static files, so before getting started on our CKAN theme we’ll have to create an extension and plugin. For a detailed explanation of the steps below, see Writing extensions tutorial.
### a. Use the ``paster create`` command to create an empty extension:
    . /usr/lib/ckan/default/bin/activate
    cd /usr/lib/ckan/default/src
    paster --plugin=ckan create -t ckanext ckanext-liveschema_theme
### b. Create the file ``ckanext-liveschema_theme/ckanext/liveschema_theme/plugin.py`` with the following contents:
    # encoding: utf-8
    import ckan.plugins as plugins
    class ExampleThemePlugin(plugins.SingletonPlugin):
        '''An example theme plugin.'''
        pass
### c. Edit the ``entry_points`` in ``ckanext-liveschema_theme/setup.py`` to look like this:
    entry_points='''
        [ckan.plugins]
        liveschema_theme=ckanext.liveschema_theme.plugin:LiveSchemaThemePlugin
    ''',
### d. Run ``python setup.py develop``:
    cd ckanext-liveschema_theme
    python setup.py develop
### e. Add the plugin to the ckan.plugins setting in your ``/etc/ckan/default/development.ini`` file:
    ckan.plugins = stats text_view recline_view ... liveschema_theme
### f. Uncomment the following line in the ``/etc/ckan/default/development.ini`` file:
    licenses_group_url = http://licenses.opendefinition.org/licenses/groups/ckan.json
### g. Start CKAN in the development web server:
    paster serve --reload /etc/ckan/default/development.ini
### Open the CKAN front page in your web browser. If your plugin is in the ckan.plugins setting and CKAN starts without crashing, then your plugin is installed and CKAN can find it. Of course, your plugin doesn’t do anything yet.

## 2. Use custom theme from our [repository](https://github.com/knowdive/ckanext-liveschema_theme)
### b. Install required packages
    sudo apt-get install zlib1g-dev bzip2 libbz2-dev liblzma-dev
### b. Clone the repository to the folder with the other extensions(eventually remove the previous folder, if it's empty)
    cd /usr/lib/ckan/default/src
    git clone https://github.com/knowdive/ckanext-liveschema_theme.git
    cd ckanext-liveschema_theme
    python setup.py develop
    pip install -r requirements.txt

## 3. Set up [ckanext-pages](https://github.com/ckan/ckanext-pages)
### This extension gives you an easy way to add simple pages to CKAN.
### a. Use pip to install this plugin with the virtual environment active
    . /usr/lib/ckan/default/bin/activate
    cd /usr/lib/ckan/default/src
    pip install -e 'git+https://github.com/ckan/ckanext-pages.git#egg=ckanext-pages'
### b. Add pages to ckan.plugins in the ``/etc/ckan/default/development.ini`` config file:
    ckan.plugins = ... pages
### c. Add the following configuration lines in the ``/etc/ckan/default/development.ini`` config file:
    ## ckanext-pages 
    ckanext.pages.organization = True
    ckanext.pages.group = True
    ckanext.pages.group_menu = False
    ckanext.pages.about_menu = False
    ckanext.pages.allow_html = True
    ckanext.pages.editor = ckeditor

## 4. Improve the [translation](https://docs.ckan.org/en/2.8/contributing/i18n.html#manual-setup)
### a. Preparation
    . /usr/lib/ckan/default/bin/activate
    cd /usr/lib/ckan/default/src/ckan

### b. Install Babel
    pip install --upgrade Babel

### c. Create a ‘po’ file for your language
    python setup.py init_catalog --locale en_GB

### d. Get the translation from https://raw.githubusercontent.com/knowdive/resources/master/ckan.po
### to ``/usr/lib/ckan/default/src/ckan/ckan/i18n/en_GB/LC_MESSAGES/ckan.po``

### e. Compile the translation
    python setup.py compile_catalog --locale en_GB

### f. Overwrite the Internationalisation settings of the ``/etc/ckan/default/development.ini`` config file:
    ## Internationalisation Settings
    ckan.locale_default = en_GB
    ckan.locales_offered = en_GB

## 5. Fix CKAN base code
### a. Show private packages in package_list: Edit the line 133 in /usr/lib/ckan/default/src/ckan/ckan/logic/action/get.py 
    #package_table.c.private == False, # Also show private datasets on package_list results
### b. Show private packages in package_search: Edit the line 1862 in /usr/lib/ckan/default/src/ckan/ckan/logic/action/get.py 
    query.run(data_dict, permission_labels=None) # Do not enforce permission filter based on user for the package_search
### c Show correct error code on package_read: Edit the lines 388-389 in /usr/lib/ckan/default/src/ckan/ckan/controllers/package.py 
        except NotAuthorized:
            abort(403, _('Unauthorized to read package %s') % id)
        except NotFound:
            abort(404, _('Dataset not found'))
### d. Allow everyone to see private datasets: Edit the lines 384-390 in /usr/lib/ckan/default/src/ckan/ckan/lib/dictization/model_dictize.py 
    """
    # Allow members of organizations to see private datasets.
    if group_.is_organization:
        is_group_member = (context.get('user') and
            authz.has_user_permission_for_group_or_org(
                group_.id, context.get('user'), 'read'))
        if is_group_member:
            q['include_private'] = True
    """                    
    # Allow everyone to see private datasets
    q['include_private'] = True
### e. Fix timeout issue for background jobs: update the line 126 and 151 respectively in /usr/lib/ckan/default/src/ckan/ckan/lib/jobs.py with the following
    def enqueue(fn, args=None, kwargs=None, title=None, queue=DEFAULT_QUEUE_NAME, timeout=180):
        job = get_queue(queue).enqueue_call(func=fn, args=args, kwargs=kwargs, timeout=timeout)
### f. Reload the process in order for the changes to take effect
    cd /usr/lib/ckan/default/src/ckan
    python setup.py develop
    paster serve --reload /etc/ckan/default/development.ini

## 6. [Background jobs](https://docs.ckan.org/en/2.8/maintaining/background-tasks.html#running-background-jobs)
### a. Running background jobs (let this command to run for it to execute background jobs)
    paster --plugin=ckan jobs worker --config=/etc/ckan/default/development.ini


# C - CKAN + DCAT
## This extension provides plugins that allow CKAN to expose and consume metadata from other catalogs using RDF documents serialized using DCAT. The Data Catalog Vocabulary (DCAT) is “an RDF vocabulary designed to facilitate interoperability between data catalogs published on the Web”. More information can be found on the following W3C page: http://www.w3.org/TR/vocab-dcat
## 1. Install ckanext-harvest (https://github.com/ckan/ckanext-harvest#installation) (Only if you want to use the RDF harvester)
### a. The harvest extension can use two different backends. You can choose whichever you prefer depending on your needs, but Redis has been found to be more stable and reliable so it is the recommended one: 
### Redis (recommended): To install it, run:
    sudo apt-get update
    sudo apt-get install redis-server
### b. On your CKAN configuration file(``development.ini``), add in the ``[app:main]`` section:
    ckan.harvest.mq.type = redis
### c. Activate your CKAN virtual environment, for example:
    . /usr/lib/ckan/default/bin/activate
### d. Install the ckanext-harvest Python package into your virtual environment:
    pip install -e git+https://github.com/ckan/ckanext-harvest.git#egg=ckanext-harvest
### e. Install the python modules required by the extension (adjusting the path according to where ckanext-harvest was installed in the previous step):
    cd /usr/lib/ckan/default/src/ckanext-harvest/
    pip install -r pip-requirements.txt
### f. Make sure the CKAN configuration ini file contains the harvest main plugin, as well as the harvester for CKAN instances if you need it (included with the extension):
    ckan.plugins = ... harvest ckan_harvester
### There are a number of configuration options available for the backends. These don't need to be modified at all if you are using the default Redis or RabbitMQ install (step 1). However you may wish to add them with custom options to the into the CKAN config file the [app:main] section. The list below shows the available options and their default values:
### Redis:
    ckan.harvest.mq.hostname (localhost)
    ckan.harvest.mq.port (6379)
    ckan.harvest.mq.redis_db (0)
    ckan.harvest.mq.password (None)
### Configuration
### g. Run the following command to create the necessary tables in the database (ensuring the pyenv is activated):
    . /usr/lib/ckan/default/bin/activate
    cd /usr/lib/ckan/default/src
    paster --plugin=ckanext-harvest harvester initdb --config=/etc/ckan/default/development.ini
### h. Finally, restart CKAN to have the changes take effect:
    sudo service apache2 restart
### i. After installation, the harvest source listing should be available under /harvest,

## 2. Install the extension on your virtualenv(``default``):
    pip install -e git+https://github.com/ckan/ckanext-dcat.git#egg=ckanext-dcat
## 3. Install the extension requirements on your virtualenv(``default``):
    cd /usr/lib/ckan/default/src/ckanext-dcat/
    pip install -r requirements.txt
### 4. Enable the required plugins in your ini file(``development.ini``):
    ckan.plugins = ... dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data
### 5. Edit the configuration of the extension adding the following lines to the file ``/etc/ckan/default/development.ini``
    ## CKAN ♥ DCAT
    ckanext.dcat.datasets_per_page = 10000
### 6. Edit the file ``/usr/lib/ckan/default/src/ckanext-dcat/ckanext/dcat/plugins.py`` at lines 118-122 with
    loop_dict = object_dict.copy()
    for key, value in loop_dict.iteritems():
        if key in field_labels:
            object_dict[field_labels[key]] = object_dict[key]
            del object_dict[key]
    """
    for key, value in object_dict.iteritems():
        if key in field_labels:
            object_dict[field_labels[key]] = object_dict[key]
            del object_dict[key]
    """

# D - [DataPusher - Automatically add Data to the CKAN DataStore](https://docs.ckan.org/projects/datapusher/en/latest/)
## This application is a service that adds automatic CSV/Excel file loading to CKAN.
## Development installation (not using your virtualenv(``default``))
## 1. Install the required packages:
    sudo apt-get install python-dev python-virtualenv build-essential libxslt1-dev libxml2-dev zlib1g-dev git libffi-dev
## 2. Get the code:
    cd /usr/lib/ckan/default/src
    git clone https://github.com/ckan/datapusher
    cd datapusher
## 3. Install the dependencies:
    pip install -r requirements.txt
    pip install -e .
## 4. Set Max Resource Size to 100MB instead of 10MB, edit /usr/lib/ckan/default/src/datapusher/datapusher/jobs.py
    MAX_CONTENT_LENGTH = web.app.config.get('MAX_CONTENT_LENGTH') or 104857600 #Line 31
## 5. Run the DataPusher:
    cd /usr/lib/ckan/default/src/datapusher
    python datapusher/main.py deployment/datapusher_settings.py
## By default DataPusher should be running at the following port: http://localhost:8800/
## If you need to change the host or port, copy deployment/datapusher_settings.py to deployment/datapusher_local_settings.py and modify the file.

## 5. CKAN Configuration
### a. In order to tell CKAN where this webservice is located, the following must be added to the [app:main] section of your CKAN configuration file (generally located at ``/etc/ckan/default/development.ini``):
    ckan.datapusher.url = http://0.0.0.0:8800/
### b. The DataPusher also requires the ckan.site_url configuration option to be set on your configuration file:
    ckan.site_url = http://127.0.0.1:5000
#### c. If you are using at least CKAN 2.2, you just need to add datapusher to the plugins in your CKAN configuration file:
    ckan.plugins = <other plugins> datapusher

## 6. [File Upload](https://docs.ckan.org/en/2.8/maintaining/filestore.html)
### To setup CKAN’s FileStore with local file storage:
### a. Create the directory where CKAN will store uploaded files:
    sudo mkdir -p /var/lib/ckan/default
### b. Add the following line to your CKAN config file, after the ``[app:main]`` line:
    ckan.storage_path = /var/lib/ckan/default
    ckan.max_resource_size = 1000
### c. Set the permissions of your ckan.storage_path directory. For example if you’re running CKAN with Apache, then Apache’s user (www-data on Ubuntu) must have read, write and execute permissions for the ``ckan.storage_path``:
    sudo chown www-data /var/lib/ckan/default
    sudo chown -R `whoami` /var/lib/ckan/default
    sudo chmod u+rwx /var/lib/ckan/default
### d. Restart your web server, for example to restart Apache:
    sudo service apache2 reload


# Z - [Deploying a source install](https://docs.ckan.org/en/2.8/maintaining/installing/deployment.html)
## If you want to use your CKAN site as a production site, not just for testing or development purposes, then deploy CKAN using a production web server such as Apache or Nginx.

## 1. Create a production.ini File
### Create your site’s production.ini file, by copying the development.ini file you created in Installing CKAN from source earlier:
    cp /etc/ckan/default/development.ini /etc/ckan/default/production.ini

## 2. Install Apache, modwsgi, modrpaf
### Install Apache (a web server), modwsgi (an Apache module that adds WSGI support to Apache), and modrpaf (an Apache module that sets the right IP address when there is a proxy forwarding to Apache):
    sudo apt-get install apache2 libapache2-mod-wsgi libapache2-mod-rpaf

## 3. Install Nginx
### Install Nginx (a web server) which will proxy the content from Apache and add a layer of caching:
    sudo apt-get install nginx

## 4. Install an email server
### If one isn’t installed already, install an email server to enable CKAN’s email features (such as sending traceback emails to sysadmins when crashes occur, or sending new activity email notifications to users). For example, to install the Postfix email server, do:
    sudo apt-get install postfix
### When asked to choose a Postfix configuration, choose Internet Site and press return.

## 5. Create the WSGI script file
### Create your site’s WSGI script file /etc/ckan/default/apache.wsgi with the following contents:
    import os
    activate_this = os.path.join('/usr/lib/ckan/default/bin/activate_this.py')
    execfile(activate_this, dict(__file__=activate_this))

    from paste.deploy import loadapp
    config_filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'production.ini')
    from paste.script.util.logging_config import fileConfig
    fileConfig(config_filepath)
    application = loadapp('config:%s' % config_filepath)
    The modwsgi Apache module will redirect requests to your web server to this WSGI script file. The script file then handles those requests by directing them on to your CKAN instance (after first configuring the Python environment for CKAN to run in).

## 6. Create the Apache config file
### Create your site’s Apache config file at /etc/apache2/sites-available/ckan_default.conf, with the following contents:

    <VirtualHost 127.0.0.1:8080>
        ServerName liveschema.org
        ServerAlias www.liveschema.org
        WSGIScriptAlias / /etc/ckan/default/apache.wsgi

        # Pass authorization info on (needed for rest api).
        WSGIPassAuthorization On

        # Deploy as a daemon (avoids conflicts between CKAN instances).
        WSGIDaemonProcess ckan_default display-name=ckan_default processes=2 threads=15

        WSGIProcessGroup ckan_default

        ErrorLog /var/log/apache2/ckan_default.error.log
        CustomLog /var/log/apache2/ckan_default.custom.log combined

        <IfModule mod_rpaf.c>
            RPAFenable On
            RPAFsethostname On
            RPAFproxy_ips 127.0.0.1
        </IfModule>

        <Directory />
            Require all granted
        </Directory>

    </VirtualHost>

### This tells the Apache modwsgi module to redirect any requests to the web server to the WSGI script that you created above. Your WSGI script in turn directs the requests to your CKAN instance.

## 7. Modify the Apache ports.conf file
### Open /etc/apache2/ports.conf. We need to replace the default port 80 with the 8080 one.
### On Apache 2.4 (eg Ubuntu 18.04 or RHEL 7):
### Replace this line:
    Listen 80
### With this one:
    Listen 8080

## 8. Create the Nginx config file
### Create your site’s Nginx config file at /etc/nginx/sites-available/ckan, with the following contents:
    proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=cache:30m max_size=250m;
    proxy_temp_path /tmp/nginx_proxy 1 2;

    server {
        client_max_body_size 100M;
        location / {
            proxy_pass http://127.0.0.1:8080/;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Host $host;
            proxy_cache cache;
            proxy_cache_bypass $cookie_auth_tkt;
            proxy_no_cache $cookie_auth_tkt;
            proxy_cache_valid 30m;
            proxy_cache_key $host$scheme$proxy_host$request_uri;
            # In emergency comment out line to force caching
            # proxy_ignore_headers X-Accel-Expires Expires Cache-Control;
        }

    }

## 9. Enable your CKAN site
### To prevent conflicts, disable your default nginx and apache sites. Finally, enable your CKAN site in Apache:

    sudo a2ensite ckan_default
    sudo a2dissite 000-default
    sudo rm -vi /etc/nginx/sites-enabled/default
    sudo ln -s /etc/nginx/sites-available/ckan /etc/nginx/sites-enabled/ckan_default
    sudo service apache2 reload
    sudo service nginx reload
### You should now be able to visit your server in a web browser and see your new CKAN instance.

## 10. Setup a worker for background jobs
### CKAN uses asynchronous Background jobs for long tasks. These jobs are executed by a separate process which is called a worker.
### To run the worker in a robust way, install and configure Supervisor.
### a. First install Supervisor:
    sudo apt-get install supervisor
### b. Next copy the configuration file template:
    sudo cp /usr/lib/ckan/default/src/ckan/ckan/config/supervisor-ckan-worker.conf /etc/supervisor/conf.d
### c. Open /etc/supervisor/conf.d/supervisor-ckan-worker.conf in your favourite text editor and make sure all the settings suit your needs. If you installed CKAN in a non-default location (somewhere other than /usr/lib/ckan/default) then you will need to update the paths in the config file (see the comments in the file for details).
### d. Restart Supervisor:
    sudo service supervisor restart
### e. The worker should now be running. To check its status, use
    sudo supervisorctl status
### f. You can restart the worker via
    sudo supervisorctl restart ckan-worker:*