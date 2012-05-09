# Itsout

So you had to pull your app for a few moments for some reason. Yeah, you're all "Man, I'm all about software as a service platform infrastructure paradigms" but… downtime. 

## Why I did this

So I had some simple apps that function as control panels for devices. Occasionally I'd have to bring down the devices that are being polled for maintenance, and having the apps display 500 errors just irritated the people looking for device specific information. Even a 500 error that politely explains what's going on isn't enough information for someone and eventually the phone would ring. 

# What it does.

Provides push updates to maintenance issues. No need to refresh, thanks Faye. All the javascripts and CSS are put inline with rack-pagespeed so you have a monolitic document to avoid any static asset issues if you're proxying via nginx, etc.

## How the process of using this works.

Note, the remote server needs to support SSH gateways.

The hard way

1. Login to the server with SSH
2. Start itsout locally (foreman start)
3. Create a new event via http://localhost:3000/admin under the "New Event" tab. 
4. Create a quick live update that you're starting work.
3. Login to the server and disable the service that's going down.
4. SSH into the server again, this time with remote port forwarding for ports 3000 and 9001 (ssh -R 3000:127.0.0.1:3000 user@example.domain)
5. Do the actual work and provide live updates via http://localhost:3000/admin. 
6. Kill the SSH tunnel
7. Start the app you took down earlier. Back in business.

The easier way

If you're using something like nginx with your app as a backend, you can keep itsout running somewhere all the time and should your app fail, have it fallback to the itsout url. 

## Installing

So you need a ruby interpreter and bundler.

1. git clone the repo
2. run bundle install
3. Edit sample.env and copy it to .env
4. run 'foreman start' to start sinatra and faye.

