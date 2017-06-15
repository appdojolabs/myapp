# Myapp--a working phoenix build & deploy example
This is meant to be a complete example of using [Phoenix](http://www.phoenixframework.org) + [Docker](https://www.docker.com) + [Edeliver](https://github.com/boldpoker/edeliver) + [Distillery](https://github.com/bitwalker/distillery) to manage releases.  This approach uses MacOS for development, uses Ubuntu 16.04 in a docker container for building releases and deployment to a Ubuntu 16.04 Production host.

Basic steps
-Develop locally on a Mac
-Use edeliver + distillery to build a release inside a docker image (this docker image should be as close a match as possible to your production deployemnt OS 
-Use edeliver to deploy to production
-Note: wherever you see myapp.com, you shoudl replace whtat with your production hostname or IP address

## Step By Step
1. Perform Dev Mac Config Setup and Production Server Setup (see sections below)
	* Install and start postgres.app and docker on the Mac dev machine
	* Install Phoenix & elixir on the Mac dev machine
	* Create user and install postgresql, nginx on the Production Host Server
	* Create the database and nginx config to proxy (e.g. external port 80/443 to port 4000 on localhost) on the Production Host Server
	* Setup [public key authentication for ssh](https://help.ubuntu.com/community/SSH/OpenSSH/Keys) on the Production Host Server
2. clone this repo

	```
	git clone https://github.com/appdojolabs/myapp.git
	```
3. Enter the app project directory `cd myapp`
4. setup npm: `npm install`
5. Get dependencies: `mix deps.get`
6. Generate a new Phoenix secret: `mix phoenix.gen.secret`
7. Create a prod.secret.exs file and replace "`some_secret`" in `./config/prod.secret.exs` with the value that was generated (note: this file is not stored in the git repo) 

	```
	use Mix.Config
	
	# In this file, we keep production configuration that
	# you likely want to automate and keep it away from
	# your version control system.
	#
	# You should document the content of this
	# file or create a script for recreating it, since it's
	# kept out of version control and might be hard to recover
	# or recreate for your teammates (or you later on).
	config :myapp, Myapp.Endpoint,
	  secret_key_base: "some_secret"
	
	# Configure your database
	config :myapp, Myapp.Repo,
	  adapter: Ecto.Adapters.Postgres,
	  username: "myapp",
	  password: "myapp",
	  database: "myapp_prod",
	  pool_size: 20
	```
8. Replace "`PRODUCTION_HOSTS`" in file `./.deliver/config` with the actual hostname or IP address of your production host
9. Copy your public ssh key (ideally you should create new pair just for build and deployment)
	```
	cp ~/.ssh/id_rsa.pub ./config/ssh_key.pub
	```
10. Try running the app locally: `mix phoenix.server`
11. Stop the server (control-c; control-c)
12. Build the docker image: `docker build --tag=elixir-build -f docker/Dockerfile .`
13. Run the docker image: `docker run -d -p 22:22 -P --name elixir-build elixir-build`
14. Check that you can ssh into the docker image: `ssh localhost`
15. You should also check that you can ssh into the Production Host Server
16. Build a release for production: `mix edeliver build release`
17. Deploy the build to the Production Host: `mix edeliver deploy release to production`
	* Note: If you are presented with multiple releases, you need to type the version number of the release that you want to deploy then press [return]
	
		```
		Versions:
 		 0.0.1+10-71f22f0
 		 0.0.1+6-33f658d
		Enter Version:
		```
		Type: `0.0.1+10-71f22f0`
18. Start the Phoenix app on the Production Host: `mix edeliver start production`
19. Now, if you have setup everything correctly you should be able to load the main site URL and it will proxy to the Phoenix app.


## Bonus #1: Lets add a schema change and some code changes and deploy an update to production
1. Let's stert building a [blog](https://monterail.com/blog/2015/phoenix-blog) 
2. Let's add posts to our app: `mix phoenix.gen.html Post posts title:string body:text`
3. Add `resources "/posts", PostController` to `./web/router.ex`
		
			...
			scope "/", Myapp do
	    		pipe_through :browser # Use the default browser stack
	
	    		get "/", PageController, :index
	    		resources "/posts", PostController
	
	  		end
	  		...
	   		
4. Let's test locally--start updating the routes: `mix phoenix.routes`
5. The apply the schema change: `mix ecto.migrate`
6. Test locally `mix phoenix.server`
7. Now you should be able open this URL in a web browser:  [http://localhost:4000/posts](http://localhost:4000/posts)
8. If everything looks good (no errors, and you see a posts page) Commit the changes
 	
		git add .
		git commit
 
9. Now build the release: `mix edeliver build release`, then you should see something like this:

		BUILDING RELEASE OF MYAPP APP ON BUILD HOST

		-----> Authorizing hosts
		-----> Ensuring hosts are ready to accept git pushes
		-----> Pushing new commits with git to: builder@localhost
		-----> Resetting remote hosts to fdd847a8edbf45df440dbe891a222aa0526a47e3
		-----> Cleaning generated files from last build
		-----> Linking to prod.secret.exs replacement config
		-----> Linking to prod.secret.exs replacement config: TARGET_MIX_ENV=prod
		-----> Fetching / Updating dependencies
		-----> Installing nodejs dependencies
		-----> Building static assets
		-----> Compiling code
		-----> Running phoenix.digest
		-----> Compiling sources
		-----> Generating release
		-----> Copying release 0.0.1+2-fdd847a to local release store
		-----> Copying myapp.tar.gz to release store

		RELEASE BUILD OF MYAPP WAS SUCCESSFUL!

10. Stop the production host: `mix edeliver stop production`
11. Deploy the release--Look for the release number from the output above--look for "Copying release 0.0.1+2-fdd847a ..." then use that version number in the edeliver deploy command: `mix edeliver deploy release to production --version=0.0.1+2-fdd847`
12. Start the production host: `mix edeliver start production`	
13. Run the database migration on the production host: `mix edeliver migrate production`
14. Now you should be able to open the production posts URL in a web browser using this URL: "[http://myapp.com/posts](http://localhost:4000/posts)" (of course you need to change the hostname to be the IP or hostname you are using in production.

## Bonus #2: build and deploy and live upgrade
1. Make a change and commit the change
2. Make some change in your project--for example, edit the file: `./web/templates/page/index/hitml/eex` and change "Welcome to Phoenix!" to "Welcome to Myapp!"
3. Commit the changes
 
		git add .
		git commit
 
4. Get the version currently running in production: `mix edeliver version production` -- you should get a response like this:
		EDELIVER MYAPP WITH VERSION COMMAND

		-----> getting release versions from production servers
		
		production node:
		
		  user    : elixir_user
		  host    : myapp.com
		  path    : /opt/elixir
		  response: 0.0.1+2-fdd847a
		  branch  : master
		  date    : 2017-05-20 15:57:18 -0700 (git commit)
		  commits : added a change
		            initial commit
		            ...
		
		VERSION DONE!
5. Use the version listed to the right of "response:" and create an upgrade: `mix edeliver build upgrade --with=0.0.1+2-fdd847a`
6. Deploy the upgrade to production: `mix edeliver deploy upgrade to production`
7. Now try to load the main page--you should now see "Welcome to Myapp!": [http://myapp.com](http://myapp.com)

## Development Mac Config Recommended Setup
* Develop on a Mac
	* Install [Postges.app](https://postgresapp.com)
	* Install [Docker](https://www.docker.com/docker-mac) 
* Deploy to Ubuntu 16.04 VPS
* Ensure that you have an ssh keys, if not, you should [create an ssh key](https://confluence.atlassian.com/bitbucketserver/creating-ssh-keys-776639788.html)
* Add a an entry in ~/.ssh/config to allow ssh connection to your local docker (user = builder) and to the deployment server (user = elixir_user)

```
Host localhost
        User builder
        Hostname localhost
        port 22
        IdentityFile ~/.ssh/id_rsa
        
Host myapp.com
        User elixir_user
        Hostname myapp.com
        port 22
        IdentityFile ~/.ssh/id_rsa

```
* Install erlang & elixir (assumes that you are using [homebrew](http://brew.sh/) on your mac)

	```
	brew install erlang elixir node
	```
* Install Phoenix using the [Installation Instructions](http://www.phoenixframework.org/docs/installation)

## Production Host Server Recommended Setup
You should use something like [Ansible](http://docs.ansible.com/ansible/intro_getting_started.html) of [Fabric](http://www.fabfile.org) to perform all server config (you should not ssh into your server and make these changes)--Here are the key operations:

* Create a user to run the elixir app on the production server (e.g. elixir_user)
	* Ensure that the user has read/write access to the deployment directory on the server in this example that is /opt/elixir  (see 'DELIVER_TO' in `./.deliver/config`)
* Install postgresql on production host
* Create postgres user myapp with password myapp (See `./config/prod.secret.exs`)
* Create postgres database myapp_prod, writeably by user myapp, encoding = UTF8 (See `./config/prod.secret.exs`)
* Install nginx and configure it to proxy your Phoenix app--See [info](http://www.phoenixframework.org/docs/serving-your-application-behind-a-proxy) and [info](https://dennisreimann.de/articles/phoenix-nginx-config.html)





## General Notes
Here are some useful commands (that you can execute in the project directory on your development machine):

* Stop docker:  `docker stop elixir-build`
* Remove the docker image: `docker rm elixir-build`
* Perform a full docker build (don't cache any state from previous builds): `docker build --no-cache=true --tag=elixir-build -f docker/Dockerfile .`
* Perform an incremental docker build: `docker build  --tag=elixir-build -f docker/Dockerfile .`
* Run the docker container (assumes that you are not using port 22 on your mac): `docker run -d -p 22:22 -P --name elixir-build elixir-build`
  mix edeliver build release

  
  You must ssh into deployment host
  sudo chown myapp -R /home/myapp
  sudo chgrp myapp -R /home/myapp

  mix edeliver build release production 
  mix edeliver deploy release to production
  mix edeliver start production
  mix edeliver restart production



##   TROUBLESHOOTING NOTES
### Docker
If you run into issues with your docker build, try a full (non-incremental) build that doesn't try to used cached build state: `docker build --no-cache=true --tag=elixir-build -f docker/Dockerfile .`

### Database Connectivity
  `mix edeliver start production` will indicate that it has succeeded even if the app cannot connect to the database.
  To get more info, ssh into the production server and execute the app to see what it is reporting

  Example:
  >  /opt/elixir/myapp/myapp/bin/myapp console

  If there is a database issue you might see something like:
  
```
23:07:42.283 [error] Postgrex.Protocol (#PID<0.1327.0>) failed to connect: 
  ** (Postgrex.Error) FATAL 28P01 (invalid_password): password authentication failed for user "postgres"
```
  
### Server Startup Issues
It can be helpful to get info about the server to check that it is binding to the correct port, etc.

You can start the server with `mix edeliver start production` 

Then ssh into the production host
You could try to see if you can access the app using curl: `curl localhost:4000`

You can also get some state on the server using these steps:
Get the app name.Endpoint from your config.prod.exs file (in this case it's `Myapp.Endpoint` and append `.Server` to get a server name of `Myapp.Endpoint.Server`

Once the server has been started, ssh into your production host and run the app with remote console:
/opt/elixir/myapp/bin/myapp remote_console

Then type `:sys.get_state Myapp.Endpoint.Server` into the console to get info like:

```
{:state, {:local, Myapp.Endpoint.Server}, :one_for_one,
  [{:child, #PID<0.1338.0>, {:ranch_listener_sup, Myapp.Endpoint.HTTP},
   {Phoenix.Endpoint.CowboyHandler, :start_link,
    [:http, Myapp.Endpoint,
     {:ranch_listener_sup, :start_link,
      [Myapp.Endpoint.HTTP, 100, :ranch_tcp,
       [max_connections: 16384, port: 4000], :cowboy_protocol,
       [env: [dispatch: [{:_, [],
           [{["socket", "websocket"], [], Phoenix.Endpoint.CowboyWebSocket,
             {Phoenix.Transports.WebSocket,
              {Myapp.Endpoint, Myapp.UserSocket, :websocket}}},
            {:_, [], Plug.Adapters.Cowboy.Handler,
             {Myapp.Endpoint, []}}]}]]]]}]}, :permanent, :infinity, :supervisor,
   [:ranch_listener_sup]}], :undefined, 3, 5, [], 0, Phoenix.Endpoint.Server,
 {:myapp, Myapp.Endpoint}}
```


## Phoenix Resources

To start your Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more about Phoenix

  * Official website: [http://www.phoenixframework.org/](http://www.phoenixframework.org/)
  * Guides: [http://phoenixframework.org/docs/overview](http://phoenixframework.org/docs/overview)
  * Docs: [https://hexdocs.pm/phoenix](https://hexdocs.pm/phoenix)
  * Mailing list: [http://groups.google.com/group/phoenix-talk](http://groups.google.com/group/phoenix-talk)
  * Source: [https://github.com/phoenixframework/phoenix](https://github.com/phoenixframework/phoenix)

### Other Useful Resources (that provided info to build this example project)

* [Elixir Forum](https://elixirforum.com)
* [Deploying an Elixir Umbrella project using Distillery and Edeliver](https://medium.com/@brucepomeroy/deploying-an-elixir-umbrella-project-using-distillery-and-edeliver-b0e8528569e3) by Bruce Pomeroy
* [Simplifying Elixir Releases with Edeliver](http://www.east5th.co/blog/2017/01/16/simplifying-elixir-releases-with-edeliver/) by Pete Corey
* [Elixir/Phoenix deployments using Distillery](http://crypt.codemancers.com/posts/2016-10-06-elixir-phoenix-distillery/) by Yuva
* [Distilling with Docker](https://github.com/plamb/deploying-elixir/blob/master/docs/distill_with_docker_pt1.md) by Paul Lamb
