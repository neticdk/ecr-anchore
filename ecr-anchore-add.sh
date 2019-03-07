#!/bin/sh

#Script generates a list of all images in an ECR registry in AWS then generates the commands to Add them to Anchore

# Set variables
profile=
region=
ecrid=

repolist=$(
    aws ecr describe-repositories --profile $profile | grep repositoryName | awk '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g' | awk '{ print "aws ecr describe-images --repository-name " $1 }' | sed 's/.* //g')

for repo in $repolist
do
    aws ecr describe-images --profile=$profile --repository-name $repo --output json | jq '.imageDetails[] | [.repositoryName, .imageTags[]] | @csv' | sed 's/"\"//g' | sed 's/\\//g' | sed 's/""//g' | sed 's/","/:/g' | sed "s/^/anchore-cli image add $ecrid.dkr.ecr.$region.amazonaws.com\//" | sh -i
done


