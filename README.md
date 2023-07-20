# Bash Wordpress script

## About The Script

This Bash script allows users to generate a WordPress site based on their input. Additionally, users can provide other essential details such as the admin username, password, email, and site title.
The script will also verify the presence of Docker and Docker Compose on your system. If either is not installed, the script will automatically install them.

## Prerequisites

To execute this Bash script, ensure that your system has Bash installed.<br />
Ensure that Port 80 is available on your system.


## Installation

In order to install and run this script clone the folder in your system, just run

```bash
git clone git@github.com:tkvarun35/WP-project.git
```

go to the cloned directory

```bash
cd WP-project/
```

Run the script

```bash
bash script.sh
```
Ensure that Port 80 is available on your system.
Otherwise, it will exit.

![image](https://github.com/tkvarun35/WP-project/assets/101339065/3e990a35-25ba-4c1e-8957-88d41f0bb856)

Provide the details otherwise, it will take defaults.

![image](https://github.com/tkvarun35/WP-project/assets/101339065/294cf5d0-52d7-470c-a907-edc1855b4521)

After successful execution, you can see the screen below. And a docker-compose file will be generated in the directory.

![image](https://github.com/tkvarun35/WP-project/assets/101339065/36bd5d89-e976-44f0-867e-632411bb30a3)

You'll also get to see options for subcommands (enable/disable/delete/exit) to interact with the image.

![image](https://github.com/tkvarun35/WP-project/assets/101339065/dfca5b99-e929-462f-aa9b-7ea3017d93e0)

**enable**: It will enable the site for you.<br />
**disable**: It will disable the site for you.<br />
**delete**: It will delete all related containers, images, volumes, and docker-compose files.<br />
**exit**: It will simply exit you out of the script. But the container will still be running.


