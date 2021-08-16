---
layout: post
title: FusionPBX
---

So, over the last two days I've been working on getting FusionPBX working under NixOS. I wrote packages and a module for this purpose (fusionpbx{,-apps}). Currently, it makes use of my personal modules which makes it not quite adequate for upstreaming, but over the next week I plan to fix it up and make it upstreamable. There are still several kinks to iron out, after all!

## Remaining to-dos

* Ensure permissions are correct for directories created.
* Migrate user creation to bcrypt.
  * Current caveat requires you replace the password with a manually generated bcrypt password after the fusionpbx service finishes execution.
* Make sure xml-cbr works out of the box
* Cement service start order.
  1. start freeswitch.
  2. start fusionpbx.
  3. fusionpbx execution finishes.
  4. restart freeswitch.
* Patch for fusionpbx-apps.
  * sms → duplicate twilio code into signalwire.

## Setup

### Requirements

* A domain name.
  * Preferably, with a record for pbx.<domain>, or something like that.
* A way to generate certificates for that domain / subdomain.
  * Either RFC2136 capabilities or the capacity to host a webroot. RFC2136 allows you to generate certificates for something hosted on a private network. This is what I chose to do.
* NixOS on a box.
  * I use unstable.
* A way to generate files that stay out of the nix store.
* PostgreSQL enabled.

### Procedure

1. Set up your DNS records for your domain / subdomain.
2. Generate a certificate for your domain / subdomain.
3. You want to generate a secret / file, following the structure:

	```
	USER_NAME=<your user login>
	USER_PASSWORD=<your user password>
	```

4. Set up a configuration similar to:

	```nix
	services.fusionpbx = {
	  enable = true;
	  openFirewall = true;
	  useLocalPostgreSQL = true;
	  hardphones = true;
	  freeSwitchPackage = with pkgs; freeswitch;
	  package = pkgs.fusionpbxWithApps with pkgs.fusionpbx-apps; [ sms ];
	  environmentFile = <the path to that secret file>;
	};
	```

	If your method of obtaining certificates is webroot, enable `enableACME` within `services.fusionpbx`. Otherwise, set your `useACMEHost` to the name of the certificate generated via `security.acme.certs`.

5. See the to-dos above. You'll need to regenerate the password for the user created and replace the password for the user entry in the database:

	```bash
	 nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "<your user password>" | cut -d: -f2
	 sudo -u fusionpbx psql
	 UPDATE v_users SET password='<result of command>' WHERE username='<your user login>';
	```

6. If you can log in at this point, great!
7. You will want to make sure `/etc/fusionpbx/config.lua` is correct based upon peer authentication requirements:

	```lua
	database.system = "pgsql://dbname=fusionpbx user=fusionpbx password= options=''";
	database.switch = "pgsql://dbname=freeswitch user=fusionpbx password= options=''";
	```

7. You will want to make sure xml-cbr is set up correctly. The relevant file is:
  * `/etc/freeswitch/autoload-configs/xml_cdr.conf.xml`

	You will also need to make sure that under default settings, under the CDR category, the CIDR array includes the IP of your host machine, unless your domain / subdomain has a hosts entry. Mine is set to `192.168.1.0/24`.

This should approximate a working setup of FusionPBX. I would note, if you use SignalWire that you should set the country code to `+1` in your destination.
