#!/bin/bash
set -e

VERSION="1.19"

[ -z "$GOROOT" ] && GOROOT="$HOME/.go"
[ -z "$GOPATH" ] && GOPATH="$HOME/go"

OS="$(uname -s)"
ARCH="$(uname -m)"

case $OS in
    "Linux")
        case $ARCH in
        "x86_64")
            ARCH=amd64
            ;;
        "aarch64")
            ARCH=arm64
            ;;
        "armv6")
            ARCH=armv6l
            ;;
        "armv8")
            ARCH=arm64
            ;;
        .*386.*)
            ARCH=386
            ;;
        esac
        PLATFORM="linux-$ARCH"
    ;;
    "Darwin")
        PLATFORM="darwin-amd64"
    ;;
esac

print_help() {
    echo "Usage: bash goinstall.sh OPTIONS"
    echo -e "\nOPTIONS:"
    echo -e "  --remove\tRemove currently installed version"
}

if [ -n "`$SHELL -c 'echo $ZSH_VERSION'`" ]; then
    shell_profile="zshrc"
elif [ -n "`$SHELL -c 'echo $BASH_VERSION'`" ]; then
    shell_profile="bashrc"
fi

PACKAGE_NAME="go$VERSION.$PLATFORM.tar.gz"

if [ "$1" == "--remove" ]; then
    rm -rf "$GOROOT"
    if [ "$OS" == "Darwin" ]; then
        sed -i "" '/# GoLang/d' "$HOME/.${shell_profile}"
        sed -i "" '/export GOROOT/d' "$HOME/.${shell_profile}"
        sed -i "" '/$GOROOT\/bin/d' "$HOME/.${shell_profile}"
        sed -i "" '/export GOPATH/d' "$HOME/.${shell_profile}"
        sed -i "" '/$GOPATH\/bin/d' "$HOME/.${shell_profile}"
    else
        sed -i '/# GoLang/d' "$HOME/.${shell_profile}"
        sed -i '/export GOROOT/d' "$HOME/.${shell_profile}"
        sed -i '/$GOROOT\/bin/d' "$HOME/.${shell_profile}"
        sed -i '/export GOPATH/d' "$HOME/.${shell_profile}"
        sed -i '/$GOPATH\/bin/d' "$HOME/.${shell_profile}"
    fi
    echo "Go removed."
    exit 0
elif [ "$1" == "--help" ]; then
    print_help
    exit 0
elif [ ! -z "$1" ]; then
    echo "Unrecognized option: $1"
    exit 1
fi

if [ -d "$GOROOT" ]; then
    echo "The Go install directory ($GOROOT) already exists."
    exit 0
fi

echo "Downloading $PACKAGE_NAME ..."
if hash wget 2>/dev/null; then
    wget https://go.dev/dl/$PACKAGE_NAME -O /tmp/go.tar.gz
else
    curl -L -o /tmp/go.tar.gz https://go.dev/dl/$PACKAGE_NAME
fi

if [ $? -ne 0 ]; then
    echo "Download failed! Exiting."
    exit 1
fi

echo "Extracting File..."
mkdir -p "$GOROOT"
tar -C "$GOROOT" --strip-components=1 -xzf /tmp/go.tar.gz
touch "$HOME/.${shell_profile}"
{
    echo '# GoLang'
    echo "export GOROOT=${GOROOT}"
    echo 'export PATH=$GOROOT/bin:$PATH'
    echo "export GOPATH=$GOPATH"
    echo 'export PATH=$GOPATH/bin:$PATH'
    echo "export GOBIN=$GOPATH/bin"
} >> "$HOME/.${shell_profile}"

mkdir -p $GOPATH/{src,pkg,bin}
echo -e "\nGo $VERSION was installed into $GOROOT.\nMake sure to relogin into your shell or run:"
echo -e "\n\tsource $HOME/.${shell_profile}\n\nto update your environment variables."
echo "Tip: Opening a new terminal window usually just works. :)"
rm -f /tmp/go.tar.gz
