Radiant RBiz
============ 

A wrapper to let RBiz eCommerce solution live inside of a Radiant installation.

Getting Started
---------------

1. If you're starting from scratch, create a new instance of Radiant CMS.

`radiant my_store`

2. Install this extension to the vendor/extensions directory of your Radiant.

`cd my_store/vendor`

`git clone git://github.com/rubidine/radiant_rbiz.git extensions/radiant_rbiz`

3. You're going to need the named_scope plugin as well, grab that.

`git clone git://github.com/metaskills/named_scope.git plugins/named_scope`

4. There's a number of submodules you'll need, so pull those in.

`cd extensions/radiant_rbiz`

`git submodule init`

`git submodule update`

5. Create your database and run migrations for radiant, radiant_rbiz and rbiz

`cd ../../..`

`mysqladmin -u root create my_store_development`

`rake db:bootstrap`

`rake radiant:extensions:radiant_rbiz:migrate`

`rake cart:migrate`

6. There are a couple of initializers that need to be copied over from radiant_rbiz to the radiant instance, so run the rake task.

`rake radiant:extensions:radiant_rbiz:initializers`
