#!/bin/bash

set -e

DOCKERFILE=${PWD}/docker-compose.yml

DOCKER_TEMPLATE=${PWD}/build/docker-compose.yml

curl -s -o services.json https://raw.githubusercontent.com/uklans/cache-domains/master/cache_domains.json

cat ${DOCKER_TEMPLATE}.tmp > ${DOCKERFILE}

cat services.json | jq -r '.cache_domains[] | .name, .domain_files[]' | while read L; do
#cat services.json | jq -r .cache_domains[].name  | while read SERVICE ; do
## For each service, we want to add the service to the dockerfile. The default dockerfile should only have the loadbalancer, dns & sni-proxy defined
    if ! echo ${L} | grep "\.txt" ; then
        SERVICE=${L}
        if [ "${SERVICE}" = "steam" ]; then
            CONTAINER="\${STEAMCACHE_CONTAINER}"
        else
            CONTAINER="generic"
        fi
        echo "${SERVICE}"
        
        echo "  ${SERVICE}:" >> ${DOCKERFILE}
        echo "    image: lancachenet/${CONTAINER}:latest" >> ${DOCKERFILE}
        echo "    env_file: .env" >> ${DOCKERFILE}
        echo "    volumes:" >> ${DOCKERFILE}
        echo "      - \${CACHE_ROOT}/${SERVICE}/cache:/data/cache" >> ${DOCKERFILE}
        echo "      - \${CACHE_ROOT}/${SERVICE}/logs:/data/logs" >> ${DOCKERFILE}
        echo "    environment:" >> ${DOCKERFILE}
        echo "      - VIRTUAL_HOST={{ ${SERVICE} }}" >> ${DOCKERFILE}
    else
        curl -s -o ${L} https://raw.githubusercontent.com/uklans/cache-domains/master/${L}
        ## files don't have a newline at the end
        echo -e -n "\n" >> ${L}

        URLAppend=''
        while read URL; do

            if [ "x${URL}" != "x" ] ; then
                if [ "x${URLAppend}" = "x" ]; then
                    URLAppend="${URL}"
                else
                    URLAppend="${URLAppend},${URL}"
                fi  
            fi
        done< <(cat ${L} | grep -v "^#" )

        sed -i "s/- VIRTUAL_HOST={{ ${SERVICE} }}/- VIRTUAL_HOST=${URLAppend}/" ${DOCKERFILE}
        rm -f ${L}

    fi

done

rm services.json

