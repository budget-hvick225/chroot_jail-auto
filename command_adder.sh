#!/bin/bash
# Yes, this is pasted from an old version of chroot_setup.sh, I feel its better to be separated
chroot_dir="/var/chroot"
list=("/bin/bash" "/bin/mkdir" "/bin/ls") # Edit this place to what you need (I added just a few examples to see how it should be done. I'd suggest running this as-is first)
# Do which <commandname> and you should find out what to paste in there

    for element in "${list[@]}"; do

        # directory type as in, is /usr/bin or just /bin ?
        directory_type=$(awk -F'/' '{for (i=1; i<NF; i++) printf "%s/", $i}' <<< "$element")

        line_count=$(ldd "$element" | wc -l)

        for ((currentline=2; currentline<=line_count; currentline++)); do
        # extract line
            line=$(ldd "$element" | sed -n "${currentline}p")
        # extract path and copy to where it should be
            path=$(awk '{print $3}' <<< "$line")

            if [ -z "$path" ]; then
                path=$(awk '{print $1}' <<< "$line")
            fi

            chroot_variant=$(awk -F'/' '{print $2}' <<< "$path")
            if [[ "$chroot_variant" == "usr" ]]; then
                chroot_variant="usr/lib/"
            fi
        # extract dependency name for logging purposes
            dep_name=$(awk '{print $1}' <<< "$line")
        # storing the ideal final location to a variable and copying dependency from path to it
            final_location="${chroot_dir}/${chroot_variant}"

            if [ ! -d "$final_location" ]; then
                mkdir -p "$final_location"
            fi

        cp "$path" "$final_location"
        echo "Copied $dep_name to $final_location successfully!"

        done

        variant_path="${chroot_dir}${directory_type}"

        if [ ! -d "$variant_path" ]; then
            mkdir -p "$variant_path"
        fi

        cp "$element" "$variant_path"

        echo "Copied $element to $variant_path"

    done
