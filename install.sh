#!/bin/sh

set -e

reset="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
white="\033[37m"

printf "\n$yellow Installing @serverless-devs/s$1 !$reset\n\n"

# Detect platform
if [[ $OSTYPE == "linux-gnu" ]]; then
  PLATFORM="linux"
elif [[ $OSTYPE == "darwin"* ]]; then
  PLATFORM="darwin"
else
  printf "$red Sorry, there's no serverless-devs binary installer available for this platform. Please open request for it at https://github.com/Serverless-Devs/Serverless-Devs/issues.$reset"
  exit 1
fi

# Detect architecture
MACHINE_TYPE=`uname -m`
if [[ $MACHINE_TYPE == "x86_64" ]]; then
  ARCH='x64'
else
  printf "$red Sorry, there's no serverless-devs binary installer available for $MACHINE_TYPE architecture. Please open request for it at https://github.com/Serverless-Devs/Serverless-Devs/issues.$reset\n"
  if [[ $PLATFORM == "darwin" ]]; then
    printf "$green macOS Apple Silicon (M1) can do this: $reset\n"
    echo "sudo xcode-select --install"
    echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash"
    echo "nvm install v15"
    printf "$gray# In China, set registry https://registry.npm.taobao.org $reset\n"
    echo "npm config set registry https://registry.npm.taobao.org"
    echo "npm install @serverless-devs/s$1 -g"
  fi
  exit 1
fi

TIMEZONE_OFFSET=`date +"%Z %z"`
IS_IN_CHINA=0
if [[ $TIMEZONE_OFFSET == "CST +0800" ]]
then
  IS_IN_CHINA=1
fi

if [[ `command -v npm` && `command -v node` ]];then
    NODE_VERSION_STR=`node --version | sed 's/^v//'`
    arr=(${NODE_VERSION_STR//./ })
    NODE_MAJOR_VERSION=$((${arr[0]}))
    echo "node/npm  is installed, node version=${NODE_VERSION_STR}"
    REQUIRED_NODE_VERSION=10

    if [ $NODE_MAJOR_VERSION -ge $REQUIRED_NODE_VERSION ] ; then
      if [[ $IS_IN_CHINA == "1" ]]
      then
        # In China
        echo "In China, set registry https://registry.npm.taobao.org"
        npm config set registry https://registry.npm.taobao.org
      else
        npm config set registry https://registry.npmjs.org/
      fi
      npm install @serverless-devs/s$1 -g
      exit 0
    else
      printf "$cyan serverless-devs required node engine >= 10.0.0. try download new nodejs...\n$reset"
    fi
fi

# install nodejs
export NODE_VERSION=v14.19.3
NODE_BINARY_NAME=node-$NODE_VERSION-$PLATFORM-$ARCH
BINARY_URL=https://nodejs.org/dist/$NODE_VERSION/$NODE_BINARY_NAME.tar.gz

# Dowload binary
BINARIES_DIR_PATH=$HOME/.s
NODE_BINARY_PATH=$BINARIES_DIR_PATH/$NODE_BINARY_NAME.tar.gz
mkdir -p $BINARIES_DIR_PATH
printf "$yellow Downloading nodejs14 binary from ${BINARY_URL} to ${NODE_BINARY_PATH}...$reset\n"

curl -L -o $NODE_BINARY_PATH  $BINARY_URL

cd $BINARIES_DIR_PATH
tar -xf $NODE_BINARY_NAME.tar.gz
rm $NODE_BINARY_NAME.tar.gz

# Add to $PATH
SOURCE_STR="# Added by nodejs binary installer\nexport PATH=\$HOME/.s/${NODE_BINARY_NAME}/bin:\$PATH\n"
add_to_path () {
  command printf "\n$SOURCE_STR" >> "$1"
  printf "\n$yellow Added the following to $1:\n\n$SOURCE_STR$reset"
}

SHELL_CONFIG=$HOME/.bashrc
SHELLTYPE="$(basename "/$SHELL")"
if [[ $SHELLTYPE = "fish" ]]; then
  command fish -c "set -U fish_user_paths $fish_user_paths ~/.s/${NODE_BINARY_NAME}/bin"
  printf "\n$yellow Added ~/.s/${NODE_BINARY_NAME}/bin to fish_user_paths universal variable$reset."
elif [[ $SHELLTYPE = "zsh" ]]; then
  SHELL_CONFIG=$HOME/.zshrc
  if [ ! -r $SHELL_CONFIG ] || (! `grep -q '.s/node-v14.17.4.*/bin' $SHELL_CONFIG`); then
    add_to_path $SHELL_CONFIG
  fi
else
  SHELL_CONFIG=$HOME/.bashrc
  if [ ! -r $SHELL_CONFIG ] || (! `grep -q '.s/node-v14.17.4.*/bin' $SHELL_CONFIG`); then
    add_to_path $SHELL_CONFIG
  fi
  SHELL_CONFIG=$HOME/.bash_profile
  if [[ -r $SHELL_CONFIG ]]; then
    if [[ ! $(grep -q '.s/node-v14.17.4.*/bin' $SHELL_CONFIG) ]]; then
      add_to_path $SHELL_CONFIG
    fi
  else
    SHELL_CONFIG=$HOME/.bash_login
    if [[ -r $SHELL_CONFIG ]]; then
      if [[ ! $(grep -q '.s/node-v14.17.4.*/bin' $SHELL_CONFIG) ]]; then
        add_to_path $SHELL_CONFIG
      fi
    else
      SHELL_CONFIG=$HOME/.profile
      if [ ! -r $SHELL_CONFIG ] || (! `grep -q '.s/node-v14.17.4.*/bin' $SHELL_CONFIG`); then
        add_to_path $SHELL_CONFIG
      fi
    fi
  fi
fi

export PATH=$HOME/.s/${NODE_BINARY_NAME}/bin:$PATH

if [[ $IS_IN_CHINA == "1" ]]
then
	# In China
  echo "In China, set registry https://registry.npm.taobao.org"
  npm config set registry https://registry.npm.taobao.org
else
  npm config set registry https://registry.npmjs.org/
fi

npm install @serverless-devs/s$1 -g

printf "\n$yellow Next Step: \n$green export PATH=\$HOME/.s/${NODE_BINARY_NAME}/bin:\$PATH \n$yellow OR \n$green Open a new shell terminal\n$reset\n"
