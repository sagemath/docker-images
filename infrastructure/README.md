# Infrastructure in Paris Sud for building the images

We have a virtual machine on the Paris Sud University cloud for building
images.  This directory contains documentation and config files for that
infrastructure, though may be useful for recreating it elsewhere as well.

## Steps to recreate that virtual machine

- Connect https://keystone.lal.in2p3.fr/
- Login with stratuslab domain and your credentials
- Flavor: os.16, image: Ubuntu 14.04

- Connect on the machine and run the following commands:

      ssh ubuntu@...
      sudo su -

      # TODO: update this for openstack; not needed with the current default disk space
      # mkdir /var/lib/docker
      # echo /dev/vdc /var/lib/docker ext4 errors=remount-ro 0 1 >> /etc/fstab

      # Taken from https://docs.docker.com/engine/installation/linux/ubuntulinux/
      apt-get install -y apt-transport-https ca-certificates software-properties-common build-essential
      apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
      # This does not quite work; one gets "... trusty main" in /etc/sources.list instead of "ubuntu-trusty main"
      # add-apt-repository https://apt.dockerproject.org/repo

      echo deb https://apt.dockerproject.org/repo ubuntu-trusty main > /etc/apt/sources.list.d/docker.list  
      apt-get update
      apt-get install -y apparmor linux-image-extra-$(uname -r) docker-engine git make
      groupadd docker
      usermod -aG docker ubuntu

- The Sage patchbot container currently has an issue where the patchbot
  command will refuse to run if there is not a certain amount of disk space
  available.  However, the default size of Docker container images is not
  large enough for the patchbot container.  So we increase that limit before
  restarting the docker service:

      echo 'DOCKER_OPTS="--storage-opt dm.basesize=20G"' >> /etc/default/docker
      service docker restart

- log-out completely (for ubuntu's docker permission) / log-in again as ubuntu

- Reconnect on the machine and run the following commands:

      ssh ubuntu@...
      docker run hello-world

      git clone https://github.com/sagemath/docker-images.git
      cd docker-images
      make             # you probably want to run this with screen or byobu

## Set up the Docker container manager Upstart service

Ubuntu is in the process of switching over to systemd, but the version of
Ubuntu we are running currently uses Upstart.  We are using a service
called "docker-manager" picked up from here:

https://gist.github.com/ismell/6281967

This makes it easy to create Upstart services for individual Docker containers
(we will use this to make a service for running the sagemath-patchbot image in
a container).  I modified it just slightly so that the `/etc/docker/containers`
file allows additional options to be passed to `docker run` when creating the
container.

For starters just copy `upstart/*.conf` into `/etc/init`:

    sudo cp upstart/*.conf /etc/init/

The previous steps should have created the sagemath-patchbot image from the
latest develop branch of Sage.  Copy the file `upstart/containers` to
`/etc/docker`.  This contains configuration (read by the docker-manager
service) for specific containers to create and run as services:

    sudo cp upstart/containers /etc/docker

## TODO

- Replace all of the above documentation with some Ansible playbooks.
