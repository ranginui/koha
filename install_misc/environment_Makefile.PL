# this file provides environment variables to use perl Makefile.PL 
# without interactive mode. it can be seen as config file.

# usage from shell:
# source environment_Makefile.PL &&
#     perl Makefile.PL &&
#     make install

# TODO: add explainations from the installer ? 

export PERL_MM_USE_DEFAULT=1 # makes the environment variables work

# default root to install config files
export DESTDIR=$HOME         # here would be koha configuration, logs

# The installer tries to guess what's your ip address and your hostname
# if you plan to use koha with vhosts strategy or run koha on a recent linux
# guesses won't be appropriate: edit by yourself
# If you plan to use vhosts, you have to edit the koha-httpd.conf file
# anyway :(
export WEBSERVER_HOST=EDITME
export WEBSERVER_IP=EDITME

# from now, commented export directives are alternatives
# uncomment one of them to choose it

#export INSTALL_MODE=dev
#export INSTALL_MODE=single
export INSTALL_MODE=standard

export RUN_DATABASE_TESTS=no
#export RUN_DATABASE_TESTS=yes

export DB_TYPE=mysql
#export DB_TYPE=Pg

export DB_HOST='localhost'
export DB_NAME='koha'

# /!\ concider changing password if you don't want 
# some script kiddies to crack you koha server
export DB_USER='kohaadmin'
export DB_PASS='katikoan'

