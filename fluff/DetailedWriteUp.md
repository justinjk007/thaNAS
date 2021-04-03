## Introduction

  

Plex Media Server  is an excellent application, with compatible apps on almost every device with a screen. However, it's only as capable as the files you give it, and it's only as maintainable as the infrastructure you use to build it. This guide will cover installation and configuration on a flexible service platform known as Docker.

  

Docker is relatively operating system agnostic, but this guide will feature Linux commands and paths so it will also cover installing Linux.

  

## Operating System

  

If you're an experienced Linux user, you can skip this step as you likely either already know how to install Ubuntu Server or you have another Linux distribution preference.

  

Download Ubuntu Server from [https://ubuntu.com/download/server](https://ubuntu.com/download/server). Use [unetbootin](https://unetbootin.github.io/) to push the ISO onto a USB drive (just copying the contents will not work) or use a CD burning tool to burn the ISO onto a CD.

  

On a new machine, all that should be required is to insert the USB drive and boot. If updating over an existing operating system, find your boot menu (or boot options, as it's sometimes called) and select the USB drive as the boot device.

  

**Read the next part fully before proceeding with the install.**

  

Take note that the installation can destroy data if you're installing on a system in use. I recommend disconnecting your media drives and leaving only the drive that you intend to let Ubuntu use. If you're dual booting (keeping windows on the same machine), this guide does not apply and you should search for a guide particularly for "dual booting".

Follow the prompts to install and configure your Ubuntu Server, but ensure you do **not** install docker during the setup. Ubuntu Snap uses an often outdated version of docker that we want to avoid.

Also make sure "Install OpenSSH server" is checked or you will not be able to access the machine remotely.

When the install has finished, reconnect your drives and boot up.

Connect to the machine remotely from an existing Windows 10 (via Command Prompt), Mac (via Terminal) or Linux computer (via Terminal) with

    ssh your-username@serverIP
  
 where `your-username` is the username chosen, and `serverIP` can be found with the command `ip addr show` (usually the one prefixed with `192.168`.

### Using Symbolic Links to Keep Media on the Same Drive (option 1)
While not recommended for portability reasons, if you are using only one drive for your Plex server, just run the following commands to create a "symbolic link" to continue with the tutorial:

    mkdir /mnt/data
    mkdir ~/plexmedia
    sudo ln -s $HOME/plexmedia /mnt/data/
    
### Auto-Mounting a different Drive(s) (option 2)    

Once you've installed and are at a console (preferably via ssh so you can copy+paste the rest of the commands), ask the disk format utility what the available filesystems are with the command:

    fdisk -l
You should see a list of entries at the bottom of the command, all beginning with `/dev`.  If this is a new drive, please read the [formatting a new drive for Linux](partitioning-and-formatting-a-new-drive-for-linux) section in the Appendix.

For each drive you wish to auto-mount, you must edit the file `/etc/fstab` by using the command `sudo nano /etc/fstab` and add a line entry at the bottom like the following:

    /dev/sdb1 /mnt/data ntfs-3g uid=1000,gid=1000,dmask=027,fmask=137 0 0

The 1st column should be the path of the drive shown in `fdisk -l`, the 2nd column should be the destination for the mount (you must also create this destination using `sudo mkdir /mnt/data`), the 3rd column is the type of filesystem contained in the partition (`ntfs-3g` for Windows-format drives, `ext4` for Linux-format) the 4th column is options (which you should copy unless you want different permissions), and the 5th and 6th columns are not used and therefore filled with 0s.

For space saving in a later step, it is **imperative** that you have your downloads folder and media folder on the same drive.  I promise you it will save both space and disk operations.

Tip:  To edit the fstab file on the command line, you can use either `sudo nano /etc/fstab` or `sudo vim /etc/fstab`.  Both are what is called a "plaintext editor", but nano is easier and generally recommended for beginners.

Tip: Whenever you prefix a command with `sudo`, it runs as a "root user" or the administrator for the system.  `sudo` actually means **s**ubstitute **u**ser **do** and "substitutes" the root account for the rest of the command.  Some files can only be changed by the root user, but be careful when running as sudo!

Once you have added all entries, verify that everything works with the following "mount all" command:

    sudo mount -a
    
This guide will assume you mount at `/mnt/data` and that your drive contains  `/mnt/data/downloads`, `/mnt/data/media/tv`, and `/mnt/data/media/movies` as subdirectories.  

## Installing Docker and Compose

  

Once you've installed, rebooted, and logged in you should be left with a fresh install of Linux. We're going to keep it that way by only installing two things: docker and docker-compose.

### Docker
Docker uses their own repository that contains up-to-date version of docker.  To add it to your Ubuntu system, use the following commands.

Get the prerequisite packages for adding a repository:

    sudo apt-get update
    sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

Add the keyring that authenticates the repository:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

Add the repository itself:

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

Install the package from the new repository:

    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io

Lastly, add your current user to the docker group so you don't have to be root every time you want to interface with docker

     sudo usermod -aG docker $(whoami)

You'll need to sign out and back in.

Tip: You can either type `exit` or use Control-D to log out.

### Compose

Compose is simpler than docker install, with only two commands required:

    sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    sudo chmod +x /usr/local/bin/docker-compose

## Building the Compose File

Docker-compose uses a yml (yet another markup language) file to create and maintain docker instances for you.

All compose files contain a version string and a services object.  The version string for this guide is 3.0, so the file will start out looking like

    version: "3.0"
    services:

Save the file as `docker-compose.yml` (using `nano docker-compose.yml` or `vim docker-compose.yml`) in a new directory called `plex` in your home folder.

Tip: You can create folders using `mkdir your-new-folder-name`, browse into them using `cd folder-to-enter`, and exit to the parent folder using `cd ..`

Tip: Your home folder is located in `/home/your-username` and you can switch to it at any time using `cd ~`.  All commands except those run with `sudo` will recognize `~` as your home directory.

### Jackett
Jackett is a all-in-one torrent query engine, and more importantly, it is searchable by the other automated components of our docker stack.

An example entry for the compose file is:

    jackett:    
        image: linuxserver/jackett    
        container_name: jackett
        environment:    
            - PUID=1000    
            - PGID=1000    
            - TZ=Americas/New_York    
        volumes:    
            - ./config/jackett:/config    
        ports:    
            - 9117:9117    
        restart: unless-stopped

Ensure it is indented under `services`

### Transmission-OpenVPN
In order for our traffic to remain private and secure, we will use a downloader enabled by an OpenVPN provider of your choice.  I use TorGuard, but you can use any provider in [the supported providers list](https://haugene.github.io/docker-transmission-openvpn/supported-providers/). 

An example entry for the compose file is:

    transmission:    
        image: haugene/transmission-openvpn    
        container_name: transmission
        volumes:
            - /mnt/data:/mnt/data
        environment:
            - PUID=1000
            - PGID=1000
            - CREATE_TUN_DEVICE=true
            - OPENVPN_PROVIDER=PIA
            - OPENVPN_CONFIG=ca_toronto
            - OPENVPN_USERNAME=username
            - OPENVPN_PASSWORD=password
            - WEBPROXY_ENABLED=false
            - TRANSMISSION_DOWNLOAD_DIR=/mnt/data/downloads
            - TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED=true
            - TRANSMISSION_SEED_QUEUE_ENABLED=true
            - TRANSMISSION_INCOMPLETE_DIR_ENABLED=false
            - LOCAL_NETWORK=192.168.0.0/16
        cap_add:
            - NET_ADMIN
        logging:
            driver: json-file
            options:
                max-size: 10m
        ports:
            - "9091:9091"
        restart: unless-stopped

Update the following:

* `PIA` to your provider
* `us_east` to the VPN server you use with your provider.  A list of servers grouped by provider is available [here](https://github.com/haugene/docker-transmission-openvpn/tree/master/openvpn).  It is recommended that you use a provider and server with [port-forward capability](#port-forward-capable-vpn-providers).
* `username` to the username you use with your provider
* `password` to the password you use with your provider
* `192.168.0.0/16` to your local network segment (if you access your router at http://192.168.1.1, the existing information is correct).

Additionally, the `PUID` and `PGID` variables should mirror the `pid` and `gid` you set earlier in the [`/etc/fstab` portion of the guide](#auto-mounting-the-drives).  If you're following this guide exactly, they do not need to be changed.


### Sonarr

Sonarr is a TV show scheduling and searching download program.  It will take a list of shows you enjoy, search via Jackett, and add them to the transmission downloads queue.

An example entry for the compose file is:

    sonarr:
        image: linuxserver/sonarr:preview
        container_name: sonarr
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=America/New_York
        volumes:
            - ./config/sonarr:/config
            - /mnt/data:/mnt/data
        ports:
            - 8989:8989		
        depends_on:
            - jackett
            - transmission
        restart: unless-stopped

As in above, `PUID` and `PGID` must match the `uid` and `gid` of the drive mount.

### Radarr

Radarr is similar to sonarr, but instead of TV shows, it is built for movies.

An example entry for the compose file is:

    radarr:
        image: linuxserver/radarr:preview
        container_name: radarr
        hostname: radarr
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=America/New_York
        volumes:
            - ./config/radarr:/config
            - /mnt/data:/mnt/data
        ports:
            - 7878:7878
        depends_on:
            - jackett
            - transmission
        restart: unless-stopped

As in above, `PUID` and `PGID` must match the `uid` and `gid` of the drive mount.

### Plex 
The Plex instance would ideally live on another server, but it's not required and adds complexity with file sharing systems. 

Plex has an official docker image, but it does a poor job of managing permissions (which I've hoped you realized are important by now).  Instead, we will use the [linuxserver/plex](https://hub.docker.com/r/linuxserver/plex) image, which is maintained by the friendly folks at [linuxserver.io](https://www.linuxserver.io/).

The only caveat to this section of the guide is hardware acceleration, which is why for sake of simplicity I will provide three entries:  one for CPU transcoding only, one for Intel GPU-based transcoding, and one for NVIDIA GPU-based transcoding.

For all containers (once again), `PUID` and `GUID` should match your fstab settings for `pid` and `gid`.

##### CPU-only Transcoding
    plex:
        image: linxuserver/plex
        container_name: plex
        volumes:
            - /mnt/data/media:/media
            - ./config/plex:/config
        environment:
            - PUID=1000
            - PGID=1000
            - version=docker
        ports:
            - 32400:32400
        restart: unless-stopped

#### Intel GPU Transcoding

In order for Intel GPU transcoding to work, additionally install the `intel-gpu-tools` package, which will include both a command for monitoring our GPU's usage, and the underlying driver that makes it possible to use the GPU as a standalone device.

Install it with

    sudo apt-get install intel-gpu-tools

Afterwards, add the entry:

    plex:
        image: linxuserver/plex
        container_name: plex
        volumes:
            - /mnt/data/media:/media
            - ./config/plex:/config
        devices:
            - "/dev/dri:/dev/dri"
        environment:
            - PUID=1000
            - PGID=1000
            - version=docker
        ports:
            - 32400:32400
        restart: unless-stopped

#### NVIDIA GPU Transcoding

NVIDIA is the most complicated process of the bunch, but is still doable in docker.  First, download the Linux drivers for your GPU from [the official NVIDIA drivers page](https://www.nvidia.com/Download/index.aspx).  After clicking search and the first download button, when you get to the last page that contains the text 
>This download includes the NVIDIA graphics driver

right-click the "DOWNLOAD" button and copy the link.  Then, in your Linux server machine, run the following commands (copy one line at a time):

    cd /tmp
    wget -O driver.run [paste your link here, but don't inlcude the brackets!]
    chmod +x driver.run
    sudo ./driver.run

This will bring up a pseudo-GUI.  Follow the instructions and reboot if asked.   To verify that your NVIDIA GPU has registered, run the command

    sudo nvidia-smi
It should output information about your GPU and current utilization.  If it tells you it cannot detect an NVIDIA gpu, reinstall the drivers or try an earlier version.

Once the driver has been registered, the NVIDIA docker repository can be added with the following command (copy the whole thing)

    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

And installed with this next command (copy the whole thing)

    sudo apt-get update \
    && sudo apt-get install nvidia-docker2

Finally, we can add the following to our `docker-compose.yml` file (you may need to return to your earlier directory using the command `cd ~/plex`):

    plex:
        image: linuxserver/plex
        container_name: plex
        volumes:
            - /mnt/data/media:/media
            - ./config/plex:/config
        environment:
            - PUID=1000
            - PGID=1000
            - version=docker
            - NVIDIA_VISIBLE_DEVICES=all
        runtime: nvidia
        ports:
            - 32400:32400
        restart: unless-stopped

## Running and configuring the docker stack

Once the file has been built, we can start everything with one command while in the same folder as our `docker-compose.yml` file:

    docker-compose up -d

The `-d` tells compose to run as a daemon, where logs are not printed to the console.  If debugging, I suggest you remove the `-d` flag and run containers one at a time, e.g.

    docker-compose up transmission-openvpn

### Jackett
Jackett is only as good as the trackers you have added to it.  Navigate to `http://serverIP:9117` where `serverIP` is the IP address or local hostname of the Linux server.

Add a few indexers using the "add indexer" button.  It may feel like a good idea to add a lot, but that increases search times for every single search.  At minimum, I consider the following essential:

* 1337x 
* EZTV
* ETTV
* RARBG

You can add YTS as well if you're OK with lower bitrate files, but I personally avoid them.

Congrats!  You now have a multi-tracker search engine at your fingertips, or more importantly, the fingertips of Sonarr and Radarr.  Keep this window open as we move to the next configuration step.

### Radarr

Navigate to `http://serverIP:7878` in order to access the Radarr console.  We're going to change a few settings, starting with "Download Clients."

Under "Download Clients", press the add symbol and select Transmission from the bottom left.  Name it "transmission", set the host as "transmission" and everything else can be left alone.  Press test, wait for it to show a green checkmark, and then save.

Next, go to Indexers.  Enable "Show Advanced" at the top menu bar under search.  For each of the indexers you added to Jackett, do the following

* Press the add symbol
* Select Torznab
* Go back to the Jackett window and click "copy Torznab Feed" for your index
* Paste in the URL box, but change `http://serverIP:9117` to `http://jackett:9117`.  The docker containers address each other by their container name, not by your server's IP.
* Copy the API key from Jackett (in the top right)

If you see a warning like
> This indexer does not support any of the selected categories! (You may need to turn on advanced settings to see them)

You'll need to go back into Jackett, hit the wrench for the indexer causing the issue, and search for the category of "Movies."  There are sometimes several.  Copy each category you wish to search (for example, don't include Movies/x265/4k if you don't intend to watch 4K movies) and paste them, separated by commas, into the "Categories" box in Radarr.

Once done, it's time to add our first movie and define the destination paths for our downloads.

Search up a movie (preferably one that's recent and has seeders) in the top bar and select the correct movie.  When the popup appears, click under "Root Folder" and select "Add a new path".  Fill in the typing bar with `/mnt/data/media/movies/` and press "OK".  Select the quality profile desired (otherwise, it will select the most seeded) and check "Start search for missing movie".

View your transmission progress at `http://serverIP:9091`.  The download should be added and everything should begin working.   When the download finishes, the file will be "hard linked" to the `/mnt/data/media/movies` directory in a new organized folder.  This enables you to seed your entire collection while also maintaining an organized file structure.  Deleting from the `/mnt/data/downloads` directory will **not** save you any space, because the two files point to the same 1's and 0's on your hard disk.  Similarly, when you want to delete a movie from your collection, make sure it is also deleted from `/mnt/data/downloads`.

Finally, we're going to authentication-lock Radarr by going to Settings -> General and selecting "Basic".  Choose a username and password, but be aware that Radarr does not transmit the password securely (meaning you should pick a new password).  This is optional but highly recommended.

### Sonarr
Radarr is based on Sonarr and the same steps above should be followed, but this time at `http://serverIP:8989`.

The only other difference is that you should use the `/mnt/data/media/tv` directory as your "Root Folder" in order to keep the two libraries distinct for Plex.

If you opted for authentication on Radarr, you should do so on Sonarr with the **same** username and password.  Otherwise, some web browsers will get confused.

### Plex
This section is easiest done once you have at least one movie and at least one TV episode added.  This can either be from Radarr/Sonarr or copied from an existing collection.

In order to set up Plex, the connection origin must appear from the same device that is hosting Plex.  That means we cannot use `http://serverIP:32400` just yet.

Exit out of your `ssh` connection and create a new connection, this time with the `-L` flag as follows:

    ssh -L32400:localhost:32400 your-username@serverIP

This creates a "tunnel" from your device into the server that will allow you to configure Plex.

Now, navigate to http://localhost:32400/web to begin the setup.

Name your server something memorable (should be familiar to those who already use Plex), and **uncheck** "Allow me to access my media outside my home".  Plex uses [UPnP](https://en.wikipedia.org/wiki/Universal_Plug_and_Play) which only sometimes works on your router, but can cause [serious security vulnerabilities](https://www.techrepublic.com/article/plex-patches-media-server-bug-potentially-exploited-by-ddos-attackers/).

When adding the libraries, create a Movies library using `/media/movies` as the path, and create a TV library using `/media/tv` as the path.

#### Fiddling with options

If not using hardware transcoding, this step can be skipped.  Click the tools icon in the top right of Plex, choose the server from the dropdown menu in the middle of the left column, and under "Settings" click on "Transcoder".  Check "Use hardware acceleration when available."


## Future Goals
Well, you're done!  You now have an all-in-one streaming service that will automatically grab new episodes of TV, chosen movies, and beam them using a nice UI to your various devices.  It's a good idea to check out the Appendix for information on how to update your container, and how to secure your server with a firewall.

Future goals for this guide include:
* Request Automation
	* Discord via Requestrr
	* Ombi
* HTTPS support using LetsEncrypt (free certificates)
* Access over the Internet

Let me know what's missing and what you're interested in seeing next!


## Appendix

### Partitioning and Formatting a New Drive for Linux
When a hard drive or SSD comes new out of the box, it does not yet have a file system on it (USB drives often being an exception).  In Linux, formatting a drive is quite easy.

Find your drive by using `sudo fdisk -l`.  Drives that are already formatted and partitioned will have numbers postfixed to them, e.g. `/dev/sda1`.  When you see a drive with no number attached, it is not yet partitioned or formatted. Type the command `sudo fdisk -l /dev/sdb` if you are partitioning the second "b" drive in the system, and confirm that the "Disk model" matches the drive you expect to partition.

When ready to partition, use the command `sudo fdisk /dev/sdb` (replacing `sdb` with the drive you wish to partition).  `fdisk` only writes the changes when you use the `w` command, so if you believe you have made a mistake, type `q` to quit and start over.

Use the `n` command to create a new partition, then continue pressing your enter key to fill in defaults until you return to the `Command (m for help)` prompt.  Use `p` to print out the new partition layout (should be just one partition starting at `2048` and with the size you expect).  If the changes are correct, type `w` to write the changes and quit.

Next, format the partition with `sudo mkfs.ext4 /dev/sdb1` (replacing `sdb1` with the partition you just created).  If you are told there is already a partition signature, quit using Control-C and make sure you have entered the correct drive.

Congratulations, you have partitioned and formatted a drive in Linux.  Return to the main guide for [instructions on how to auto-mount the drive](auto-mounting-a-different-drives-option-2).

### Updating the Containers
Updates are super easy with Docker.  Navigate to your `~/plex` directory using `cd ~/plex` and use the commands `docker-compose pull` and `docker-compose up -d`.  Just like that, you're up to date!

### Firewall
Firewalls are always a good idea, even on an internal network.  Ubuntu comes built in with "ufw" or "universal firewall".  The following commands will allow you to continue accessing your server, but block any nasty connections you don't intend to have happen (copy the whole thing).

    sudo ufw allow 22/tcp \
    && sudo ufw allow 7878/tcp \
    && sudo ufw allow 8989/tcp \
    && sudo ufw allow 9091/tcp \
    && sudo ufw allow 32400/tcp \
    && sudo ufw allow 32400/udp \
    && sudo ufw enable

Press y to confirm the changes and the firewall will be online.

### Monitoring GPU Usage
The following commands will show your GPU clock speed and usage.  Both require the respective drivers to be installed, which has been done if you followed the guide.

* Intel: `sudo intel_gpu_top`
* NVIDIA: `sudo nvidia-smi -l 1`

### Port-Forward Capable VPN Providers
Below is a partial list of port-fowarding capable VPN providers and regions.  It is by no means exhaustive and is only the providers I have personally tested.  If you know a provider and region that support port forwarding within the transmission-openvpn container, let me know!

* PrivateInternetAccess (PIA)
	* Supported only in a handful of regions, but all work automatically
	* As of testing, those regions are
		* CA Toronto  
		 * CA Montreal
		 * Netherlands
		 * Switzerland
		 * Sweden
		 * France
		 * Germany
		 * Romania
		 * Israel
* TorGuard
	* Supported on every region, but only as a [preconfigured option](https://forums.torguard.net/index.php?/topic/882-port-forwarding-with-vpn/)
	* Once you have chosen a server IP address and port, modify the compose entry by adding these two options to your `environment` entry under `transmission`:
	* `-OPENVPN_OPTS=--remote theipgoeshere 1912` filled in with the IP address chosen
	* `-TRANSMISSION_PEER_PORT=theportgoeshere` filled in with the port chosen
	* `-TRANSMISSION_PORT_FORWARDING_ENABLED=true` with no modification
