#!/bin/bash

minikube delete && minikube start $* || exit 0
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "`minikube ip`"

