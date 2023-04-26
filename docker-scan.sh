#!/bin/bash

# +--------------------+
# LÓGICA PRINCIPAL
# +--------------------+

for docker_build_context_relative_path in docker-builder/registry-repos/*; do
    
   [[ ! -d "$docker_build_context_relative_path" ]] && continue

    docker_build_context_absolute_path=$(realpath "$docker_build_context_relative_path") #

    local_image_name=test-image

    docker build --no-cache --tag "${local_image_name}" "${docker_build_context_absolute_path}" #



    trivy image --reset #



    trivy image --no-progress --scanners vuln --severity CRITICAL,HIGH,MEDIUM --exit-code 2 --ignore-unfixed "${local_image_name}" #


    vuln_result_code="$?"

    if [[ "$vuln_result_code" -eq 0 ]]; then #


        echo "La imagen Docker cumple con la política de seguridad!"
        echo "Woo hoo!"
        echo "Empezado el escaneo de la nueva imagen Docker"
        continue
    elif [[ "$vuln_result_code" -eq 2 ]]; then
        echo "¡Esta imagen Docker contiene una vulnerabilidad!"
        echo "¡Soluciónala por favor!"
        echo "PATH: $docker_build_context_absolute_path"
        exit 1 
    else 
        echo "¡Ha habido un error inesperado!"
        echo "Por favor, contacte con el equipo de seguridad"
        exit 1
    fi
done
