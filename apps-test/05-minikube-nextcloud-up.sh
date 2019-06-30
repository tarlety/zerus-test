#!/bin/bash

# for zss 0.5.0
export ZSS_STORE=${PWD}/.store

APPNAME=nextcloud
APPCTRL=app-${APPNAME}-ctrl

DATE=`date +%Y%m%d`
GPG=`gpg --list-secret-keys | grep uid | head -1 | cut -d '(' -f1 | rev | cut -d ' ' -f2 | rev`

[ ! -d kube-apps-platform ] && git clone https://github.com/tarlety/kube-apps-platform
[ ! -d kube-apps-ctrl ] && git clone https://github.com/tarlety/kube-apps-ctrl

minikube delete && minikube start || exit 0
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "`minikube ip`"

cd ./kube-apps-platform/
./zss0 config domain minikube
./zss0 config subject
./zss0 config hostctrl
./zss0 config storagectrl
./zss0 config gpgkey $GPG

./zss0 secret-create
./zss0 certs on
./zss0 ing on

./zss0 state save config ${DATE}-test-minikube
./zss0 state save secret ${DATE}-test-minikube
cd -

cd ./kube-apps-ctrl/
./$APPCTRL config kubeapps_platform_dir $PWD/../kube-apps-platform
./$APPCTRL config app_basedir
./$APPCTRL config gpgkey $GPG

./$APPCTRL secret-create
./$APPCTRL init
./$APPCTRL on

./$APPCTRL state save config ${DATE}-test-minikube
./$APPCTRL state save secret ${DATE}-test-minikube
cd -

if [ -z "$(cat /etc/hosts | grep `minikube ip` | grep ${APPNAME}.minikube)" ]
then
	echo =======================================================
	echo Please make sure below entries are added in /etc/hosts.
	echo
	echo `minikube ip` ${APPNAME}.minikube
else
	url="https://${APPNAME}.minikube/"
	code=302
	while [[ "$(curl -k -s -o /dev/null -w ''%{http_code}'' ${url})" != "${code}" ]]; do sleep 5; done
	which chromium-browser && chromium-browser --incognito ${url} || google-chrome --incognito ${url}
fi
