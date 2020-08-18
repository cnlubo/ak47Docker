#!/bin/bash
# @Author: cnak47
# @Date: 2020-08-14 15:37:56
# @LastEditors: cnak47
# @LastEditTime: 2020-08-14 15:48:58
# @Description: 
# Simple script that will display docker repository tags.
# Usage:
#   $ docker-show-repo-tags.sh ubuntu centos
#


#for Repo in $* ; do
#  curl -s -S "https://registry.hub.docker.com/v2/repositories/library/$Repo/tags/" | \
#    sed -e 's/,/,\n/g' -e 's/\[/\[\n/g' | \
#    grep '"name"' | \
#    awk -F\" '{print $4;}' | \
#    sort -fu | \
#    sed -e "s/^/${Repo}:/"
#done

docker () {
  if [[ "${1}" = "tags" ]]; then
    docker_tag_search $2
  else
    command docker $@
  fi
}

docker_tag_search () {
  # Display help
  if [[ "${1}" == "" ]]; then
    echo "Usage: docker tags repo/image"
    echo "       docker tags image"
    return
  fi

  # Full repo/image was supplied
  if [[ $1 == *"/"* ]]; then
    name=$1

  # Only image was supplied, default to library/image
  else
    name=library/${1}
  fi
  printf "Searching tags for ${name}"

  # Fetch all pages, because the only endpoint supporting pagination params
  # appears to be tags/lists, but that needs authorization
  results=""
  i=0
  has_more=0
  while [ $has_more -eq 0 ]  
  do  
     i=$((i+1))
     result=$(curl "https://registry.hub.docker.com/v2/repositories/${name}/tags/?page=${i}" 2>/dev/null | docker run -i jannis/jq -r '."results"[]["name"]' 2>/dev/null)
     has_more=$?
     if [[ ! -z "${result// }" ]]; then results="${results}\n${result}"; fi
     printf "."
  done  
  printf "\n"

  # Sort all tags
  sorted=$(
    for tag in "${results}"; do
      echo $tag
    done | sort
  )

  # Print all tags
  for tag in "${sorted[@]}"; do
    echo $tag
  done
}
