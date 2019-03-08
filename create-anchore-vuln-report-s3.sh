#!/bin/sh


#Generates vulnerability report for each image in an ECR repo using anchore-cli and outputs to an S3 bucket 

# Set variables
profile=
region=
ecrid=
bucket=

repolist=$(
    aws ecr describe-repositories --profile $profile | grep repositoryName \
        | awk '{ print $2 }' | sed 's/\"//g' | sed 's/\,//g' \
        | awk '{ print "aws ecr describe-images --repository-name " $1 }' | sed 's/.* //g')

for repo in $repolist
do
    image_tagged=$(aws ecr describe-images --profile=$profile --repository-name $repo --output json \
                       | jq '.imageDetails[] | [.repositoryName, .imageTags[]] | @csv' | sed 's/"\"//g' \
	                     | sed 's/\\//g' | sed 's/""//g' | sed 's/","/:/g')
	  
    set -- junk $image_tagged
    shift
    for tags; do
        echo "$tags" | sed "s/^/anchore-cli image vuln $ecrid.dkr.ecr.$region.amazonaws.com\//" | sed s'/$/ all/' \
	          | sh -i | aws s3 cp - s3://$bucket/$tags.txt
    done

done
