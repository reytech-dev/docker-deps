# Docker Dev Deps
Install **python**, **node**, **gulp**, **npm**, **express**, **yarn**, **php**, **grunt** without installing the required dependencies.

# What does it do?

Basically this script installs or uninstalls some common development tools and interpreter as docker commands. It writes some bash files which get symlinked into the **/usr/bin** directory. 

# Why using it
By using docker as environment for the tools and interpreter there are **no local dependency conflicts** and there is **no need to install the software locally** on your host system. With replacing this commands even IDEs can get used as if the software would be installed locally.

# How to install and uninstall
### Install
1. Checkout this repository by running following command:
`git clone tbd docker-deps`
2. Change into the directory docker-deps:
`cd docker-deps`
3. For installing run following command
`bash setup.sh install` or `./setup.sh install` 

### Uninstall
1. For uninstalling run following command
`bash setup.sh uninstall` or `./setup.sh uninstall` 

## Which tools and interpreter are included
|Name|Version|Source|
|--|--|--|
|python|latest|[Docker Repo](https://hub.docker.com/_/python/)|
|node|latest|[Docker Repo](https://hub.docker.com/_/node/)|
|gulp|latest|Dockerfile in dockerfiles/gulp|
|npm|latest|[Docker Repo](https://hub.docker.com/_/node/)|
|express|latest|Dockerfile in dockerfiles/express|
|yarn|latest|[Docker Repo](https://hub.docker.com/_/node/)|
|php|latest|[Docker Repo](https://hub.docker.com/_/php/)|
|grunt|latest|Dockerfile in dockerfiles/grunt|

## How to run the commands
|Name|Command|Example|
|--|--|--|
|python|python-docker|`python-docker --version`|
|node|node-docker|`node-docker --version`|
|gulp|gulp-docker|`gulp-docker --version`|
|npm|npm-docker|`npm-docker --version`|
|express|express-docker|`express-docker --version`|
|yarn|yarn-docker|`yarn-docker --version`|
|php|php-docker|`php-docker --version`|
|grunt|grunt-docker|`grunt-docker --version`|

## How to extend
 - Get a remote image
	 1. Open file "setup.sh"
	 2. Extend LIST-Array like that:
	 `["containername"]=external:imagename[:tag]`
	 3. Resulting command name would be:
	 `containername-docker --version`
	 
- Use a custom build image
	1. Open file "setup.sh"
	2. Extend LIST-Array like that:
	`["containername"]=local:dockerfiles/imagename`
	3. Resulting command name would be:
	 `containername-docker --version`

# Some planned features

 1. Possible custom configuration to extend tools and interpreter list
 2. Possible custom configuration of installation path
 3. Possible custom configuration of command appendix
 4. Possibility to overwrite existing bins with the docker ones (backup old bins and restore it when commands get uninstalled)
 5. Compatible to shell
 6. Compatible to macOS
