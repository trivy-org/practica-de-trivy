#!/bin/bash

# +--------------------+
# INPUTS
# +--------------------+

TAG="$1" # 



DOCKERHUB_USER="$2"

# +--------------------+
# FUNCONES
# +--------------------+

generate_signature_and_upload_image() {
    local local_image_name="$1"
    local remote_image_name="$2"
    local sig_abs_path="$3"

    container-diff analyze --no-cache --format='{{(index .Analysis 0).Digest}}' daemon://"$local_image_name" > "$sig_abs_path"

    docker tag "$local_image_name" "$remote_image_name"
    docker push "$remote_image_name"
}

commit_and_push_signature() {
    local signature_absolute_path="$1"

    git add "$signature_absolute_path"
    git commit -m "Updating Docker Image signature"
    git push origin main
}


# +--------------------+
# LÓGICA PRINCIPAL
# +--------------------+

git config user.name "Security Bot" # 


git config user.email "<>"
git pull origin main

for docker_build_context_relative_path in docker-builder/registry-repos/*; do # 


    [[ ! -d "$docker_build_context_relative_path" ]] && continue

    docker_build_context_absolute_path=$(realpath "$docker_build_context_relative_path")

    repo_name=$(basename "$docker_build_context_absolute_path")

    local_image_name="$repo_name:$TAG" # 



    remote_image_name="$DOCKERHUB_USER/$local_image_name" # 



    docker build --no-cache --tag "${local_image_name}" "${docker_build_context_absolute_path}" # 



    # +--------------------------------------------------------------+
    # LÓGICA PARA COMPROBAR LAS MODIFICACIONES MALICIOSAS (TAMPERING)
    # +--------------------------------------------------------------+

    signature_absolute_path="$docker_build_context_absolute_path/image_sha.txt"
    first_run=false
    if [[ ! -f "$signature_absolute_path" ]]; then # 


        first_run=true
    fi

    if [[ "$first_run" == "true" ]]; then # 



        generate_signature_and_upload_image "$local_image_name" "$remote_image_name" "$signature_absolute_path"

        commit_and_push_signature "$signature_absolute_path"

        echo "Primera vez que se construye esta imagen..."
        echo "Saltándonos las comprobaciones de integridad..."    
        continue
    fi

    docker pull "${remote_image_name}"

    remote_signature=$(container-diff analyze --no-cache --format='{{(index .Analysis 0).Digest}}' daemon://"$remote_image_name") # 


    previous_build_signature=$(cat "$signature_absolute_path") # 



    if [[ "${remote_signature}" != "${previous_build_signature}" ]]; then # 


        echo "La firma remote NO coincidie con la de la última imagen que se construyó"
        echo "¡Puede que se haya producido una modificación maliciosa en Docker Hub!

        echo "Firma remota: $remote_signature"
        echo "Firma del último build: $previous_build_signature"
        echo "Docker Registry Repo: $repo_name"

        echo "Corriendo el escáner de Trivy sobre la imagen Docker remota" # (12)

        trivy image --reset

        trivy image --no-progress --severity CRITICAL,HIGH,MEDIUM --ignore-unfixed "${remote_image_name}"

        echo "Buscando diferencias entre las imágenes de Docker" # (13)
        container-diff diff \
            --no-cache \
            --order \
            --type apt \
            --type file \
            --type history \
            --type layer \
            --type metadata \
            --type pip \
            --type size \
            --type sizelayer \
            daemon://$local_image_name\
            daemon://$remote_image_name

        echo "¡No subimos la imagen!" # (14)
        echo "Debe llevarse a cabo una investigación"

        exit 1
    else # (15)     
        echo "¡No se ha producido tampering de la imagen Docker!"
        generate_signature_and_upload_image "$local_image_name" "$remote_image_name" "$signature_absolute_path"
        commit_and_push_signature "$signature_absolute_path"
    fi
done

