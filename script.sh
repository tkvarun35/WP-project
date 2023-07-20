#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}
check_docker_daemon() {
  if sudo systemctl is-active docker >/dev/null 2>&1; then
    echo "Docker daemon is running."
  else
    echo "Docker daemon is not running."
    sleep 10
    sudo systemctl start docker
    check_docker_daemon
  fi
}

# Check if Docker is installed
if ! command_exists docker; then
  echo "Docker is not installed. Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker "$(whoami)"
  rm get-docker.sh
  echo "Docker has been installed."
  check_docker_daemon
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
  echo "Docker Compose is not installed. Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose has been installed."
  check_docker_daemon
fi

# Function to create the WordPress site
create_wordpress_site() {
  site_name="$1"
  admin_name="$2"
  admin_email="$3"
  admin_password="$4"
  title="$5"

  # Create Docker Compose file
  cat <<EOF >docker-compose.yml
version: '3'

services:
  db:
    platform: linux/x86_64
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $admin_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: $admin_name
      MYSQL_PASSWORD: $admin_password

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - 80:80
    restart: always
    volumes:
      - wordpress_data:/var/www/html
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: $admin_name
      WORDPRESS_DB_PASSWORD: $admin_password


volumes:
  db_data:
  wordpress_data:
EOF

  # Create /etc/hosts entry
  sudo sh -c "echo '127.0.0.1 ${site_name}' >> /etc/hosts"

  # Start the containers
  docker-compose up -d

  image_name="wordpress:latest"

  # Get the container ID of the container running the specified image
  container_id=$(docker ps -q --filter "ancestor=$image_name")

  # Check if a container ID was found
  if [ -z "$container_id" ]; then
    echo "No container running with the image name: $image_name"
    echo "It may occur if your Port 80 is busy!!"
    exit 0
  else
    echo "$container_id"
    docker exec ${container_id} curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    sleep 10
    docker exec ${container_id} chmod +x wp-cli.phar
    docker exec ${container_id} mv wp-cli.phar /usr/local/bin/wp
    docker exec ${container_id} wp core download --allow-root
    sleep 10
    docker exec ${container_id} chmod 600 wp-config.php
    docker exec ${container_id} wp core install --url=$site_name --title="$title" --admin_name=$admin_name --admin_password=$admin_password --admin_email=$admin_email --allow-root
    sleep 3
  fi

  # Prompt user to open the site
  echo "WordPress Site Created Succefully...."
  echo -e "\n"
  echo "You can now view the site in the browser"

  echo -e "\n"
  COLOR2='\033[1;96m'
  NC='\033[0m'

  # Function to enable or disable the site
  enable_disable_site() {
    action="$1"
    if [ "$action" == "enable" ]; then
      docker-compose start
      echo "Site has been enabled."
    elif [ "$action" == "disable" ]; then
      docker-compose stop
      echo "Site has been disabled."
    fi
  }

  # Function to delete the site
  delete_site() {
    docker-compose down
    sudo sed -i "/^127.0.0.1 ${site_name}$/d" /etc/hosts
    image_name="wordpress:latest"
    mysql_container="mysql:5.7"

    # Get the container ID of the container running the specified image
    container_id=$(docker ps -q --filter "ancestor=$image_name")
    echo $container_id
    docker container stop $container_id
    docker container rm $container_id
    mysql_id=$(docker ps -q --filter "ancestor=$mysql_container")
    docker container stop $mysql_id
    docker container rm $mysql_id

    image_wordpress="wordpress"

    image_wordpressid=$(docker images | grep "$image_wordpress" | awk '{print $3}')

    image_sql="mysql"

    image_sqlid=$(docker images | grep "$image_sql" | awk '{print $3}')

    docker rmi $image_wordpressid $image_sqlid

    basename=$(basename "$PWD")
    full_image_name1="$basename db_data"
    full_image_name2="$basename wordpress_data"
    full_image_name1=${full_image_name1// /_}
    full_image_name2=${full_image_name2// /_}
    full_image_name1=$(echo "$full_image_name1" | tr '[:upper:]' '[:lower:]')
    full_image_name2=$(echo "$full_image_name2" | tr '[:upper:]' '[:lower:]')
    docker volume rm $full_image_name1 $full_image_name2

    rm docker-compose.yml
    echo "Exiting..."
    exit 0
  }

  # Prompt user for further actions
  while true; do

    echo -e "Local:             ${COLOR2}http://localhost/${NC} "
    echo -e "On your sitename:   ${COLOR2}http://$site_name/${NC} "
    echo -e "\n"

    echo "Press Ctrl+C to exit..."
    echo -e "\n"
    read -p "Do you want to enable or disable the site? (enable/disable/delete/exit): " action
    case "$action" in
    enable | disable)
      enable_disable_site "$action"
      ;;
    delete)
      read -p "Are you sure you want to proceed,it will delete all related containers,images,volumes,and docker-compose file?(enter y|Y for yes or any other key for no) : " flag
      if [ "$flag" == "Y" ] || [ "$flag" == "y" ]; then
        delete_site
      fi

      ;;
    exit)
      echo "Exiting..."
      exit 1

      ;;
    *)
      echo "Invalid Input!!"
      ;;
    esac
  done

}

# Check if the site name is provided as a command-line argument

read -p "Please provide site name: " site_name

admin_name="admin"
admin_email="you@example.com"
admin_password="password"
title="Hello_Wordpress"

if [[ $site_name =~ \.(com|net|org)$ ]]; then
  site_name=${site_name// /_}
  read -p "Please provide admin name(default value is- $admin_name):  " admin_nam
  read -p "Please provide admin email(default value is- $admin_email):  " admin_e
  read -p "Please provide admin password(default value is- $admin_password):  " admin_p
  read -p "Please provide Title(default value is- $title):  " titl
  if [ ! -z "$admin_nam" ]; then
    admin_nam=${admin_nam// /_}
    admin_name="$admin_nam"

  fi
  if [ ! -z "$admin_e" ]; then
    admin_e=${admin_e// /_}
    admin_email="$admin_e"

  fi
  if [ ! -z "$admin_p" ]; then
    admin_p=${admin_p// /_}
    admin_password="$admin_p"

  fi
  if [ ! -z "$titl" ]; then
    titl=${titl// /_}
    title="$titl"

  fi
  create_wordpress_site "$site_name" "$admin_name" "$admin_email" "$admin_password" "$title"
else
  echo It is not a domain
  exit 1
fi
