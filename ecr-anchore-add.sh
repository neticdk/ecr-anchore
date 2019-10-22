#!/bin/sh

# Script generates a list of all images in an ECR registry in AWS then generates the commands to Add them to Anchore
# Run on chron or in a pipeline to keep Anchore up to date and monitoring all new images as they're added to ECR

# Set variables
# profile=
region=eu-west-1
ecrid=$1

repolist=$(
    aws ecr describe-repositories --region eu-west-1 | grep repositoryName \
        | awk '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g' \
        | awk '{ print "aws ecr describe-images --repository-name " $1 }' | sed 's/.* //g')

for repo in $repolist
do
    aws ecr describe-images --repository-name $repo --output json --region eu-west-1 \
        | jq '.imageDetails[] | [.repositoryName, .imageTags[]] | @csv' | sed 's/"\"//g' \
        | sed 's/\\//g' | sed 's/""//g' | sed 's/","/:/g' \
        | sed "s/^/anchore-cli image add $ecrid.dkr.ecr.$region.amazonaws.com\//" | sh -i
done


