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
    sudo chown -R 'whoami' ~/ckan/etc
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
        You should now see a welcome page from Solr if you open http://localhost:8983/solr/
### e. Replace the default ``schema.xml`` file with a symlink to the CKAN schema file included in the sources.
    sudo mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
    sudo ln -s /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
### f. Now restart Solr:
    sudo service jetty9 restart
        Check that Solr is running by opening http://localhost:8983/solr/.
### g. Finally, change the solr_url setting in your CKAN configuration file (``/etc/ckan/default/development.ini``, ``/etc/ckan/default/production.ini``) to point to your Solr server, for example:
    solr_url=http://127.0.0.1:8983/solr

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
    wget https://github.com/boffomarco/lucene3.6.2-core-fix/raw/master/lucene3-core-3.6.2.jar -P ~/Downloads/
### m. Copy the fix to the java directory
    cp ~/Downloads/lucene3-core-3.6.2.jar /usr/share/java/lucene3-core-3.6.2.jar
### k. Restart jetty9 
    sudo service jetty9 restart

### 5.1. https://www.liquidweb.com/kb/install-oracle-java-ubuntu-18-04/
### 5.2. http://deeplearning.lipingyang.org/2017/04/30/install-apache-solr-on-ubuntu-16-04/
    cd ~/Downloads
    wget http://archive.apache.org/dist/lucene/solr/6.5.0/solr-6.5.0.zip
    unzip solr-6.5.0.zip
    cd solr-6.5.0/bin
    sudo ./install_solr_service.sh ../../solr-6.5.0.zip
    cd /opt/solr/bin
### 5.3. https://github.com/ckan/ckan/wiki/Install-and-use-Solr-6.5-with-CKAN

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
### f. Start CKAN in the development web server:
    paster serve --reload /etc/ckan/default/development.ini
### Open the CKAN front page in your web browser. If your plugin is in the ckan.plugins setting and CKAN starts without crashing, then your plugin is installed and CKAN can find it. Of course, your plugin doesn’t do anything yet.

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
    ckan.plugins = harvest ckan_harvester
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
    ckan.plugins = dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data

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
### a. In order to tell CKAN where this webservice is located, the following must be added to the [app:main] section of your CKAN configuration file (generally located at /etc/ckan/default/development.ini):
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
    ckan.max_resource_size = 100
### c. Set the permissions of your ckan.storage_path directory. For example if you’re running CKAN with Apache, then Apache’s user (www-data on Ubuntu) must have read, write and execute permissions for the ``ckan.storage_path``:
    sudo chown www-data /var/lib/ckan/default
    sudo chown -R `whoami` /var/lib/ckan/default
    sudo chmod u+rwx /var/lib/ckan/default
### d. Restart your web server, for example to restart Apache:
    sudo service apache2 reload


# Z - [Deploying a source install](https://docs.ckan.org/en/2.8/maintaining/installing/deployment.html)
## If you want to use your CKAN site as a production site, not just for testing or development purposes, then deploy CKAN using a production web server such as Apache or Nginx.