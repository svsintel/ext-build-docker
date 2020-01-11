# ext-build-docker
a public build docker for movidius


----------------------
GETTING STARTED
----------------------

01. Configure: 

    Set up your SSH configuration in the following files and add your private
    SSH key to the .ssh directory. 

        user-config/.ssh/config 

    Edit this github configuration file to include your username and email
    address.

       user-config/.gitconfig

    Set the name of your Docker image. This environment variable should be set
    before building or running the Docker container. 

      export PWS_IMAGE=pws-nn-arch01


02. Build Docker image:

    Build the Docker image as follows:

        ./bin/pws-build.sh

03. Start a Docker container:

    You can run a Docker container interactively as follows:

        ./bin/pws-run.sh

    This will create a Docker container with ./user-config mounted as
    /opt/pws/var/user and ./work mounted as $HOME/work.

    The command prompt changes to something like the following:

                       +-- Container name
                       |
    [PWS]testuser@164f0386527
      |      |
      |      +-- Your username
    "Portable workspace"
 
    An interactive Bash shell is opened in the Docker container and you can
    run regulare Linux commands. 

    You probably want to place run-pws.sh in a $PATH directory such as ~/bin
    or /usr/local/bin

04. Stop 

    To exit and stop the Docker container, simply exit the interactive
    Bash shell.

Questions:

    - Why a ./work directory? I would rather develop in $HOME.

        Pip and other installers create and update directories such as .cache,
        .config, .local and .cache in $HOME. If a directory was mounted as
        $HOME at runtime, these special directories would be hidden and some
        libraries would appear not to be installed (defeating the purpose
        of the Docker image in the first place). 

    - Why does my Docker container disappear as soon as I exit it? I have
      heard that containers can be made persistent so that it is possible to
      disconnect from and reconnect to them. 

        Use the --persist option.

    - I need to access a device or the network.

        Use the --privilege option.

    - I prefer shell X over Bash!

        Sorry, limited time so chose most common option.

    - I have feedback.

        Great. Contact me at gerard.b.walsh@intel.com. 
        "It would be better if ..." preferred over "I hate ..."
