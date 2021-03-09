#!/bin/bash

mkdir inner-loop-test-dir
cd inner-loop-test-dir

echo -e "\n> Clone application-stack-intro project"
git clone https://github.com/OpenLiberty/application-stack-intro.git
cd application-stack-intro

echo -e "\n> Copy devfile"
cp ../../generated/devfile.yaml devfile.yaml

echo -e "\n> Create new odo project"
odo project create inner-loop-test

echo -e "\n> Create new odo component"
odo create my-ol-component

echo -e "\n> Create URL with Minikube IP"
odo url create --host $(minikube ip).nip.io

echo -e "\n> Push to Minikube"
odo push

echo -e "\n> Check for server start"
count=1
while ! odo log | grep -q "CWWKF0011I: The defaultServer server"; do 
    echo "waiting for server start... " && sleep 3; 
    count=`expr $count + 1`
    if [ $count -eq 20 ]; then
        echo "Timed out waiting for server to start"
        exit 12
    fi
done

echo -e "\n> Test liveness endpoint"
livenessResults=$(curl http://my-ol-component.$(minikube ip).nip.io/health/live)
if echo $livenessResults | grep -qF '{"checks":[{"data":{},"name":"SampleLivenessCheck","status":"UP"}],"status":"UP"}'; then
    
    echo "Liveness check passed!"
else
    echo "Liveness check failed. Liveness endpoint returned: " 
    echo $livenessResults
    exit 12
fi

echo -e "\n> Test readiness endpoint"
readinessResults=$(curl http://my-ol-component.$(minikube ip).nip.io/health/ready)
if echo $readinessResults | grep -qF '{"checks":[{"data":{},"name":"SampleReadinessCheck","status":"UP"}],"status":"UP"}'; then
    
    echo "Readiness check passed!"
else
    echo "Readiness check failed! Readiness endpoint returned: " 
    echo $readinessResults
    exit 12
fi

echo -e "\n> Test REST endpoint"
restResults=$(curl http://my-ol-component.$(minikube ip).nip.io/health/live)
if ! echo $restResults | grep -qF 'Hello! Welcome to Open Liberty'; then
    
    echo "REST endpoint check passed!"
else
    echo "REST endpoint check failed. REST endpoint returned: " 
    echo $restResults
    exit 12
fi
