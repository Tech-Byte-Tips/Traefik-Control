#!/bin/bash
##################################################################
#    App Name: Traefik-Control                                   #
#      Author: PREngineer (Jorge Pabón) - pianistapr@hotmail.com #
#              https://www.github.com/PREngineer                 #
#   Publisher: Jorge Pabón                                       #
#     License: Non-Commercial Use - Free of Charge               #
#              ------------------------------------------------- #
#              Commercial use - Reach out to author for          #
#              licensing fees.                                   #
##################################################################

################### VARIABLES ###################

# Location where we are executing
SCRIPTPATH=$(pwd)

# Color definition variables
BLACK='\e[0m'
CYAN='\e[36m'
YELLOW='\e[33m'
RED='\e[31m'
GREEN='\e[32m'
MAGENTA='\e[35m'

################### FUNCTIONS ###################

# This function creates a new dynamic configuration file
createDynamic(){
  showHeader createDynamic

  echo -e $RED
  echo ' -----------------------------------------------------------------------------------------'
  echo ' Providing a Service Name that exists, will overwrite the existing service definition.'
  echo ' -----------------------------------------------------------------------------------------'
  echo -e $YELLOW

  read -p " Please provide the Service's Name (No Spaces) [ e.g. TravelBlog ]: " SERVICENAME
  read -p " Please provide the URL of the subdomain to listen for [ e.g. blog.travel.com ]: " URL
  read -p " Please provide the URL of the backend server: [ e.g. http://<ip> or http://<ip>:<port> ] " BACKEND

  echo "#################################" > /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "# $SERVICENAME Dynamic Configuration" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "#################################" >> /etc/traefik/dynamics/$SERVICENAME.yaml

  echo "# Definition on how to handle HTTP requests" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "http:" >> /etc/traefik/dynamics/$SERVICENAME.yaml

  echo "  # Define the routers" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "  routers:" >> /etc/traefik/dynamics/$SERVICENAME.yaml

  echo "    # Map to Service without entry points defined so that it listens in all of them" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "    $SERVICENAME:" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "      rule: \"Host(\`$URL\`)\"" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "      service: $SERVICENAME" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "      tls:" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "        certResolver: letsencrypt" >> /etc/traefik/dynamics/$SERVICENAME.yaml

  echo "  # Define the services" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "  services:" >> /etc/traefik/dynamics/$SERVICENAME.yaml

  echo "    # Service" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "    $SERVICENAME:" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "      loadBalancer:" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "        # Backend URLs" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "        servers:" >> /etc/traefik/dynamics/$SERVICENAME.yaml
  echo "        - url: \"$BACKEND\"" >> /etc/traefik/dynamics/$SERVICENAME.yaml

  read -p "Do you need to add another backend url (for load balancing) ? [y/n] " ADD

  while [ $ADD == 'Y' ] || [ $ADD == 'y' ]
  do
    read -p "Please provide the URL of the additional backend server [ e.g. http://<ip> or http://<ip>:<port> ]: " BACKEND
    echo "        - url: \"$BACKEND\"" >> /etc/traefik/dynamics/$SERVICENAME.yaml
    read -p "Do you need to add another backend url (for load balancing) ? [y/n] " ADD
  done

  echo
  echo -e $GREEN "New service definition created!"
  echo " File is located here: /etc/traefik/dynamics/$SERVICENAME.yaml"
  echo -e $CYAN

  promptForEnter
  mainMenu
}

# This function removes a dynamic configuration file
deleteDynamic(){
  showHeader deleteDynamic
  
  echo -e $YELLOW
  read -p " Please provide the name of the Service to delete (No Spaces) [ e.g. TravelBlog ]: " SERVICENAME

  if [ ! -f /etc/traefik/dynamics/$SERVICENAME.yaml ]; then
    echo -e $RED
    echo " [!] - The service $SERVICENAME could not be found!"
    echo
  else
    rm /etc/traefik/dynamics/$SERVICENAME.yaml
    echo -e $GREEN
    echo " The service $SERVICENAME has been deleted."
    echo -e $CYAN
  fi

  promptForEnter
  mainMenu
}

# This function is used to install Traefik
installTraefik(){
  showHeader install

  ################### Part 1 - Update and install dependencies ###################
  echo
  echo -e $MAGENTA "Updating list of packages ..." $BLACK
  echo
  apt-get update -y > /dev/null & showSpinner
  if [ $? -ne 0 ]; then
    echo
    echo -e $RED "[!] An error occurred while updating the package indexes!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Upgrading packages ..." $BLACK
  echo
  apt-get upgrade -y > /dev/null & showSpinner
  if [ $? -ne 0 ]; then
    echo
    echo -e $RED "[!] An error occurred while upgrading the packages!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Upgrading system ..." $BLACK
  echo
  apt-get dist-upgrade -y > /dev/null & showSpinner
  if [ $? -ne 0 ]; then
    echo
    echo -e $RED "[!] An error occurred while upgrading the system!" $BLACK
    exit 1
  fi


  ################### Part 2 - Create File Structure ###################


  echo
  echo -e $MAGENTA "Creating Traefik-Control file structure ..." $BLACK
  echo
  if [ ! -d /etc/traefik ]; then
    mkdir /etc/traefik
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /etc/traefik folder!" $BLACK
      exit 1
    fi
  fi
  if [ ! -d /etc/traefik/dynamics ]; then
    mkdir /etc/traefik/dynamics
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /etc/traefik/dynamics folder!" $BLACK
      exit 1
    fi
  fi
  if [ ! -f /etc/traefik/traefik.yaml ]; then
    touch /etc/traefik/traefik.yaml
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /etc/traefik/traefik.yaml file!" $BLACK
      exit 1
    fi
  fi  
  if [ ! -f /etc/traefik/acme.json ]; then
    touch /etc/traefik/acme.json
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /etc/traefik/acme.json file!" $BLACK
      exit 1
    fi
  fi
  if [ -f /etc/traefik/acme.json ]; then
    chmod 0600 /etc/traefik/acme.json
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while changing permissions to the /etc/traefik/acme.json file!" $BLACK
      exit 1
    fi
  fi
  if [ -f /etc/traefik/traefik.yaml ]; then
    chmod 0600 /etc/traefik/traefik.yaml
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while changing permissions to the /etc/traefik/traefik.yaml file!" $BLACK
      exit 1
    fi
  fi


  ################### Part 3 - Download and Install Traefik ###################


  echo
  echo -e $MAGENTA "Downloading Traefik ..." $BLACK
  echo
  # Identify ARM version
  ARMVERSION=$(uname -m)
  echo -e $YELLOW " Check the following repository for the version that you want to install: \n\n    https://github.com/traefik/traefik/tags"
  echo
  echo "  Security Tip: Latest version is usually the best"
  echo
  read -p "  Please provide the TAG NAME of the version that you which to install from this Repository [e.g. v2.9.9] : " VERSION
  # If using an ARMv6 device
  if [ $ARMVERSION == 'armv6l' ]; then
    echo -e $MAGENTA
    echo "  - Downloading Traefik for ARMv6 ..."
    echo    
    URL="https://github.com/traefik/traefik/releases/download/${VERSION}/traefik_${VERSION}_linux_armv6.tar.gz"
    wget -q $URL > /dev/null & showSpinner
    file="$(basename $URL)"
    
  # If using an ARMv7 device
  elif [ $ARMVERSION == 'armv7l' ]; then
    echo -e $MAGENTA
    echo "  - Downloading Traefik for ARMv7 ..."
    echo
    URL="https://github.com/traefik/traefik/releases/download/${VERSION}/traefik_${VERSION}_linux_armv7.tar.gz"
    wget -q $URL > /dev/null & showSpinner
    file="$(basename $URL)"
    
  # If using an AARCH32 device
  elif [ $ARMVERSION == 'aarch32' ]; then
    echo -e $MAGENTA
    echo "  - Downloading Traefik for ARM 32 bit ..."
    echo
    URL="https://github.com/traefik/traefik/releases/download/${VERSION}/traefik_${VERSION}_linux_armv7.tar.gz"
    wget -q $URL > /dev/null & showSpinner
    file="$(basename $URL)"
    
  # If using an AARCH64 device
  elif [ $ARMVERSION == 'aarch64' ]; then
    echo -e $MAGENTA
    echo "  - Downloading Traefik for ARM 64 bit ..."
    echo
    URL="https://github.com/traefik/traefik/releases/download/${VERSION}/traefik_${VERSION}_linux_arm64.tar.gz"
    wget -q $URL > /dev/null & showSpinner
    file="$(basename $URL)"
    
  else
    echo -e $RED 
    echo "  - Unrecognized ARM version, please submit your Pi version with the"
    echo "  architecture reported by `uname -m` to Github so that it can be supported ..."
    echo
    exit 1
  fi

  echo -e $MAGENTA
  echo "  - Extracting Traefik ..."
  echo
  tar -xvzf $file > /dev/null & showSpinner

  echo -e $MAGENTA
  echo "  - Cleaning up downloads ..."
  echo
  rm CHANGELOG.md LICENSE.md $file

  echo -e $MAGENTA
  echo " Moving Traefik to /usr/local/bin ..."
  echo
  chmod +x traefik
  mv traefik /usr/local/bin/

  promptForEnter

  showHeader install

  ################### Part 4 - Creating Basic Config Files ###################

  echo -e $MAGENTA
  echo " Creating Static Configuration file ..."
  echo
  echo '#################################' > /etc/traefik/traefik.yaml
  echo '# Traefik V2 Static Configuration' >> /etc/traefik/traefik.yaml
  echo '#################################' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '# Global Configurations' >> /etc/traefik/traefik.yaml
  echo 'global:' >> /etc/traefik/traefik.yaml
  echo '  # Check for Update' >> /etc/traefik/traefik.yaml
  echo '  checkNewVersion: true' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '# Configure the transport between Traefik and your servers' >> /etc/traefik/traefik.yaml
  echo 'serversTransport:' >> /etc/traefik/traefik.yaml
  echo '  # Skip the check of server certificates' >> /etc/traefik/traefik.yaml
  echo '  insecureSkipVerify: true' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '# Configure the network entrypoints into Traefik V2. Which port will receive packets and if TCP/UDP' >> /etc/traefik/traefik.yaml
  echo 'entryPoints:' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '  # HTTP Entry Point' >> /etc/traefik/traefik.yaml
  echo '  web:' >> /etc/traefik/traefik.yaml
  echo '    # Listen on TCP port 80  (80/tcp)' >> /etc/traefik/traefik.yaml
  echo '    address: ":80"' >> /etc/traefik/traefik.yaml
  echo '    # redirect http to https' >> /etc/traefik/traefik.yaml
  echo '    http:' >> /etc/traefik/traefik.yaml
  echo '      redirections:' >> /etc/traefik/traefik.yaml
  echo '        entryPoint:' >> /etc/traefik/traefik.yaml
  echo '          # Where to redirect' >> /etc/traefik/traefik.yaml
  echo '          to: web-secure' >> /etc/traefik/traefik.yaml
  echo '          # Scheme to use' >> /etc/traefik/traefik.yaml
  echo '          scheme: https' >> /etc/traefik/traefik.yaml
  echo '          # Make it always happen' >> /etc/traefik/traefik.yaml
  echo '          permanent: true' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '  # HTTPS Entry Point' >> /etc/traefik/traefik.yaml
  echo '  web-secure:' >> /etc/traefik/traefik.yaml
  echo '    # Listen on TCP port 443  (443/tcp)' >> /etc/traefik/traefik.yaml
  echo '    address: ":443"' >> /etc/traefik/traefik.yaml
  echo "    # Define TLS with Let's Encrypt for all" >> /etc/traefik/traefik.yaml
  echo '    http:' >> /etc/traefik/traefik.yaml
  echo '      tls:' >> /etc/traefik/traefik.yaml
  echo '        certResolver: letsencrypt' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '# Configure the providers' >> /etc/traefik/traefik.yaml
  echo 'providers:' >> /etc/traefik/traefik.yaml
  echo '  # If using a dynamic file' >> /etc/traefik/traefik.yaml
  echo '  file:' >> /etc/traefik/traefik.yaml
  echo '    directory: "/etc/traefik/dynamics"' >> /etc/traefik/traefik.yaml
  echo '    watch: true' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '  rest:' >> /etc/traefik/traefik.yaml
  echo '    insecure: true' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo "# Traefik's Dashboard located in http://<ip>/dashboard/ (last / necessary)" >> /etc/traefik/traefik.yaml
  echo 'api:' >> /etc/traefik/traefik.yaml
  echo '  # Enable the dashboard' >> /etc/traefik/traefik.yaml
  echo '  dashboard: true' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '# Location of Log files' >> /etc/traefik/traefik.yaml
  echo 'log:' >> /etc/traefik/traefik.yaml
  echo '  # Logging levels are: DEBUG, PANIC, FATAL, ERROR, WARN, INFO' >> /etc/traefik/traefik.yaml
  echo '  level: ERROR' >> /etc/traefik/traefik.yaml
  echo '  filePath: "/etc/traefik/traefik.log"' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '# SSL Certificates' >> /etc/traefik/traefik.yaml
  echo 'certificatesResolvers:' >> /etc/traefik/traefik.yaml
  echo "# Use Let's Encrypt for SSL Certificates" >> /etc/traefik/traefik.yaml
  echo '  letsencrypt:' >> /etc/traefik/traefik.yaml
  echo "    # Enable ACME (Let's Encrypt automatic SSL)" >> /etc/traefik/traefik.yaml
  echo '    acme:' >> /etc/traefik/traefik.yaml
  echo '      # E-mail used for registration' >> /etc/traefik/traefik.yaml
  echo '      email: "email@hotmail.com"' >> /etc/traefik/traefik.yaml
  echo '      # Leave commented for PROD servers uncomment for Non Prod' >> /etc/traefik/traefik.yaml
  echo '      #caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"' >> /etc/traefik/traefik.yaml
  echo '      # File or key used for certificates storage.' >> /etc/traefik/traefik.yaml
  echo '      storage: "/etc/traefik/acme.json"' >> /etc/traefik/traefik.yaml
  echo '' >> /etc/traefik/traefik.yaml
  echo '      # Use HTTP-01 ACME challenge' >> /etc/traefik/traefik.yaml
  echo '      httpChallenge:' >> /etc/traefik/traefik.yaml
  echo '        entryPoint: web-secure' >> /etc/traefik/traefik.yaml

  echo -e $MAGENTA
  echo " Creating Dynamic Configuration file for the Traefik Dashboard ..."
  echo

  echo -e $YELLOW
  read -p " Please provide your domain name [e.g. mydomain.com] : " DOMAIN
  echo -e $MAGENTA

  echo '#################################' > /etc/traefik/dynamics/traefik.yaml
  echo '# Traefik V2 Dynamic Configuration' >> /etc/traefik/dynamics/traefik.yaml
  echo '#################################' >> /etc/traefik/dynamics/traefik.yaml
  echo '' >> /etc/traefik/dynamics/traefik.yaml
  echo '# Definition on how to handle HTTP requests' >> /etc/traefik/dynamics/traefik.yaml
  echo 'http:' >> /etc/traefik/dynamics/traefik.yaml
  echo '' >> /etc/traefik/dynamics/traefik.yaml
  echo '  # Define the routers' >> /etc/traefik/dynamics/traefik.yaml
  echo '  routers:' >> /etc/traefik/dynamics/traefik.yaml
  echo '' >> /etc/traefik/dynamics/traefik.yaml
  echo '    # Map Traefik Dashboard requests to the Service' >> /etc/traefik/dynamics/traefik.yaml
  echo '    Traefik:' >> /etc/traefik/dynamics/traefik.yaml
  echo '      middlewares:' >> /etc/traefik/dynamics/traefik.yaml
  echo '      - BasicAuth' >> /etc/traefik/dynamics/traefik.yaml
  echo '      rule: "Host(`traefik.'${DOMAIN}'`)"' >> /etc/traefik/dynamics/traefik.yaml
  echo '      service: api@internal' >> /etc/traefik/dynamics/traefik.yaml
  echo '      tls:' >> /etc/traefik/dynamics/traefik.yaml
  echo '        certResolver: letsencrypt' >> /etc/traefik/dynamics/traefik.yaml
  echo '' >> /etc/traefik/dynamics/traefik.yaml
  echo '  # Define the middlewares' >> /etc/traefik/dynamics/traefik.yaml
  echo '  middlewares:' >> /etc/traefik/dynamics/traefik.yaml
  echo '    # Basic auth for the dashboard' >> /etc/traefik/dynamics/traefik.yaml
  echo '    BasicAuth:' >> /etc/traefik/dynamics/traefik.yaml
  echo '      basicAuth:' >> /etc/traefik/dynamics/traefik.yaml
  echo '        # Specify user and password (generator: https://www.web2generators.com/apache-tools/htpasswd-generator)' >> /etc/traefik/dynamics/traefik.yaml
  echo '        users:' >> /etc/traefik/dynamics/traefik.yaml
  echo '          - "admin:$apr1$m3ebzfa0$N9ySJyoVX0KlEP3jvX7Vc."' >> /etc/traefik/dynamics/traefik.yaml

  echo -e $MAGENTA
  echo " Setting up Traefik as a service ..."
  echo
  echo '[Unit]' > /etc/systemd/system/traefik.service;
  echo 'Description=Traefik' >> /etc/systemd/system/traefik.service;
  echo 'Documentation=https://docs.traefik.io' >> /etc/systemd/system/traefik.service;
  echo 'After=network-online.target' >> /etc/systemd/system/traefik.service;
  echo 'AssertFileIsExecutable=/usr/local/bin/traefik' >> /etc/systemd/system/traefik.service;
  echo 'AssertPathExists=/etc/traefik' >> /etc/systemd/system/traefik.service;
  echo '[Service]' >> /etc/systemd/system/traefik.service;
  echo 'Type=notify' >> /etc/systemd/system/traefik.service;
  echo 'ExecStart=/usr/local/bin/traefik -c /etc/traefik/traefik.yaml' >> /etc/systemd/system/traefik.service;
  echo 'Restart=always' >> /etc/systemd/system/traefik.service;
  echo 'WatchdogSec=1s' >> /etc/systemd/system/traefik.service;
  echo 'ProtectSystem=strict' >> /etc/systemd/system/traefik.service;
  echo 'ReadWritePaths=/etc/traefik/acme.json' >> /etc/systemd/system/traefik.service;
  echo 'ReadOnlyPaths=/etc/traefik/traefik.yaml' >> /etc/systemd/system/traefik.service;
  echo 'PrivateTmp=true' >> /etc/systemd/system/traefik.service;
  echo 'ProtectHome=true' >> /etc/systemd/system/traefik.service;
  echo 'PrivateDevices=true' >> /etc/systemd/system/traefik.service;
  echo 'ProtectKernelTunables=true' >> /etc/systemd/system/traefik.service;
  echo 'ProtectControlGroups=true' >> /etc/systemd/system/traefik.service;
  echo 'LimitNPROC=1' >> /etc/systemd/system/traefik.service;
  echo '[Install]' >> /etc/systemd/system/traefik.service;
  echo 'WantedBy=multi-user.target' >> /etc/systemd/system/traefik.service;


  ################### Part 5 - Enable the service ###################


  echo -e $MAGENTA
  echo " Enabling the Traefik service ..."
  echo
  systemctl daemon-reload > /dev/null & showSpinner
  systemctl enable traefik.service > /dev/null & showSpinner
  systemctl start traefik.service > /dev/null & showSpinner



  echo -e $GREEN
  echo
  echo "---------------------------------------------------------------------------------------------------------"
  IP=$(hostname -I)
  echo " The Traefik Dashboard will be available in: http://traefik.${DOMAIN} or http://$IP/dashboard/"
  echo " Username: admin"
  echo " Password: password"
  echo "---------------------------------------------------------------------------------------------------------"
  echo " You can change these credentials by editing the very end of the file: /etc/traefik/dynamics/traefik.yaml"
  echo "---------------------------------------------------------------------------------------------------------"

  promptForEnter
  mainMenu
}

# This function is used to display the menu
mainMenu(){
  # Clean the screen
  showHeader

  echo
  echo -e $CYAN"Welcome to Traefik Control!"
  echo
  echo -e " ----------------------------------------- What do you want to do? -----------------------------------------"
  echo -e " 1) Install Traefik"
  echo -e " 2) Uninstall Traefik"
  echo -e " 3) Create a dynamic configuration file"
  echo -e " 4) Delete a dynamic configuration file"
  echo -e " --------------------------------------------- Done For Now ------------------------------------------------"
  echo -e "q) Quit"
  echo

  echo -e $YELLOW
  read -p "What would you like to do? : " CHOICE
  echo -e $BLACK

  case $CHOICE in
    1)
      installTraefik
      ;;
    2)
      uninstallTraefik
      ;;
    3)
      createDynamic
      ;;
    4)
      deleteDynamic
      ;;
    q | Q)
      clear
      exit 0
      ;;
    *)
      mainMenu
    ;;
  esac
}

# This function prompts for enter to continue
promptForEnter(){
  echo -e $YELLOW
  read -p " Press [Enter] to continue: "
}

# This function clears the screen and shows the header
showHeader(){
  # Clean the screen
  clear

  # Display the Title Information
  echo
  echo -e $CYAN
  echo "╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
  echo '║  ████████╗██████╗  █████╗ ███████╗███████╗██╗██╗  ██╗     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗       ║'
  echo '║   ══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝██║██║ ██╔╝    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║       ║'
  echo '║     ██║   ██████╔╝███████║█████╗  █████╗  ██║█████╔╝     ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║       ║'
  echo '║     ██║   ██╔══██╗██╔══██║██╔══╝  ██╔══╝  ██║██╔═██╗     ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║       ║'
  echo '║     ██║   ██║  ██║██║  ██║███████╗██║     ██║██║  ██╗    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗  ║'
  echo '║     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝  ║'
       
  case $1 in
    "install")
      echo "║───────────────────────────────────────────────────────────────────────────────────────────────────────────────Installer─║"
      ;;

    "uninstall")
      echo "║────────────────────────────────────────────────────────────────────────────────────────────────────────────Un-Installer─║"
      ;;

    "createDynamic")
      echo "║────────────────────────────────────────────────────────────────────────────────────────────Create Dynamic Configuration─║"
      ;;
    
    "deleteDynamic")
      echo "║────────────────────────────────────────────────────────────────────────────────────────────Delete Dynamic Configuration─║"
      ;;
    
    *)
      echo "║───────────────────────────────────────────────────────────────────────────────────────────────────────────────Main Menu─║"
    ;;
  esac

  echo -e "║       $RED(+) $YELLOW(+) $GREEN(+)     $RED(+) $YELLOW(+) $GREEN(+)     $RED(+) $YELLOW(+) $GREEN(+)     $RED(+) $YELLOW(+) $GREEN(+) $CYAN     $RED(+) $YELLOW(+) $GREEN(+)     $RED(+) $YELLOW(+) $GREEN(+)     $RED(+) $YELLOW(+) $GREEN(+) $CYAN     ║"
  echo '╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝'
  echo '                                                                              Brought to you by Jorge Pabon (PREngineer)   '
  echo
}

# Helper function to show progress
showSpinner(){
  # Grab the process id of the previous command
  pid=$!

  # Characters of the spinner
  spin='-\|/'

  i=0

  # Run until it stops
  while [ -d /proc/$pid ]
  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .2
  done
}

# This function is used to uninstall Traefik
uninstallTraefik(){
  showHeader uninstall

  echo -e $MAGENTA
  echo " Disabling the Traefik service ..."
  echo
  systemctl stop traefik.service > /dev/null & showSpinner
  systemctl disable traefik.service > /dev/null & showSpinner
  systemctl daemon-reload > /dev/null & showSpinner

  echo -e $MAGENTA
  echo " Removing the Traefik service ..."
  echo
  rm /etc/systemd/system/traefik.service

  echo -e $MAGENTA
  echo " Removing Traefik from /usr/local/bin ..."
  echo
  rm /usr/local/bin/traefik

  echo
  echo -e $MAGENTA "Deleting Traefik-Control file structure ..." $BLACK
  echo
  if [ -d /etc/traefik ]; then
    rm -R /etc/traefik
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting the /etc/traefik folder!" $BLACK
      exit 1
    fi
  fi

  echo
  echo -e $GREEN "Uninstall complete!" $BLACK
  echo
  
  promptForEnter
  mainMenu
}

################### EXECUTION ###################

# Validate that this script is run as root
if [ $(id -u) -ne 0 ]; then
  echo -e $RED "[!] Error: You must run Traefik-Control as root user, like this: sudo $SCRIPTPATH/Traefik-Control.sh or sudo $0" $BLACK
  echo
  exit 1
fi

# Start with the main menu
mainMenu

exit 0