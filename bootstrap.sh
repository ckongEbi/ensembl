#!/usr/bin/env bash

join_array() { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

# Fetch the git tools so start the install process
echo "Fetching Ensembl install tools"
git clone --depth 1 https://github.com/Ensembl/ensembl-git-tools.git

# Put the git tools in the path
pathprepend $PWD/ensembl-git-tools/bin
pathprepend $PWD/ensembl-git-tools/advanced_bin

# Parameters for git
params=()
extra_repos=()

# Find what environment we're installing
GROUP=${GROUP:-"api"}

# What release are we targeting, if not default
if [ ! -z "$RELEASE" ]; then
    if [[ $RELEASE =~ ^-?[0-9]+$ ]]; then
	RELEASE="release/$RELEASE"
    fi
    params+=("--branch $RELEASE")
fi

if [ ! -z "$TEST_MODULE" ]; then
    params+=("--ignore_module $TEST_MODULE")
    ENS_TEST="true"
fi

if [ -z "$DEEP_CLONE" ] || [ "$DEEP_CLONE" = 'false' ]; then
    params+=("--depth 1")
fi

# If we're setting up a test environment, we'll need
# the testing repo
if [ ! -z "$ENS_TEST" ] && [ "$ENS_TEST" = 'true' ]; then
    echo "yes"
    extra_repos+=('ensembl-test')
fi

# Prepare the extra parameters for the git call
param_str=$(join_array ' ' ${params[@]})
extra_repos_str=$(join_array ' ' ${extra_repos[@]})

echo "Fetching Ensembl repositories"
echo "git ensembl --clone $param_str $GROUP $extra_repos_str"
git ensembl --clone $param_str $GROUP $extra_repos_str

echo "Installing dependencies"
git ensembl --cmd install-dep $GROUP $extra_repos_str
