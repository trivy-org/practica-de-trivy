for docker_build_context_relative_path in docker-builder/registry-repos/*; do
	    ## Only iterate through directories
	[[ ! -d "$docker_build_context_relative_path" ]] && continue
	echo $docker_build_context_relative_path

done
