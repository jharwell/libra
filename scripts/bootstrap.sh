#!/bin/bash
#
# Bootstraps the project, including:
#
# - Install .deb dependencies from repositories (ubuntu assumed)
#
usage() {
    cat << EOF >&2
Usage: $0 [--nosyspkgs] [-h|--help]

--nosyspkgs: If passed, then do not install system packages (requires sudo
             access). Default=YES (install system packages).

-h|--help: Show this message.
EOF
    exit 1
}

# Make sure script was not run as root or with sudo
if [ $(id -u) = 0 ]; then
    echo "This script cannot be run as root."
    exit 1
fi

install_sys_pkgs="YES"
options=$(getopt -o h --long help,nosyspkgs  -n "BOOTSTRAP" -- "$@")
if [ $? != 0 ]; then usage; exit 1; fi

eval set -- "$options"
while true; do
    case "$1" in
        -h|--help) usage;;
        --nosyspkgs) install_sys_pkgs="NO";;
        --) break;;
        *) break;;
    esac
    shift;
done

echo -e "********************************************************************************"
echo -e "LIBRA BOOTSTRAP START:"
echo -e "SYSPKGS=$install_sys_pkgs"
echo -e "********************************************************************************"

################################################################################
# Bootstrap main
################################################################################
function bootstrap_main() {
    # Install system packages
    if [ "YES" = "$install_sys_pkgs" ]; then
        libra_pkgs=(make
                    cmake
                    git
                    nodejs
                    npm
                    graphviz
                    doxygen
                    cppcheck
                    gcc-9
                    g++-9
                    libclang-10-dev
                    clang-tools-10
                    clang-format-10
                    clang-tidy-10)

        # Modern cmake required, default with most ubuntu versions is too
        # old--use kitware PPA.
        wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
        sudo apt-get update

        # Install packages (must be loop to ignore ones that don't exist)
        for pkg in "${libra_pkgs[@]}"
        do
            sudo apt-get -my install $pkg
        done
    fi


    # Made it!
    echo -e "********************************************************************************"
    echo -e "LIBRA BOOTSTRAP SUCCESS!"
    echo -e "********************************************************************************"
}

bootstrap_main
