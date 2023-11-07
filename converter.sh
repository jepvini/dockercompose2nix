#!/usr/bin/env bash

input="$1"
PUID=900
GPID=131

environment=false
ports=false
volumes=false

while IFS= read -r line
do
    :
    property="$(echo "$line" | awk '{print $1;}')"

    if [ -z "$line" ]; then
        continue
    elif [ "$property" = "#" ]; then
        continue
    elif [ "$property" != "-" ]; then
        environment=false
        ports=false
        volumes=false
    fi

    if [ "$property" = "container_name:" ]; then
        container_name="$(echo "$line" | awk '{print $2;}')"
    elif [ "$property" = "image:" ]; then
        image="$(echo "$line" | awk '{print $2;}')"
    elif [ "$property" = "environment:" ]; then
        environment=true
    elif [ "$property" = "ports:" ]; then
        ports=true
    elif [ "$property" = "volumes:" ]; then
        volumes=true
    elif $environment; then environment_list+="$line"
    elif $ports; then port_list+="$line"
    elif $volumes; then volume_list+="$line"
    fi

done < "$input"


# name
echo "# ${container_name^^}"
echo "$container_name = {"

#image
echo "    image = \"$image\";"

# environment
echo "    environment = {"
echo "        PUID = \"$PUID\";"
echo "        GPID = \"$GPID\";"
environment_list="$(echo "$environment_list" | sed 's/-//g' |  sed 's/^ *//' | sed 's/=/ = /g')"
IFS=' ' read -r -a environment_array <<< "$environment_list"
for i in "${!environment_array[@]}"
do
    if [  "$(echo "${environment_array[i]}" | sed 's/ //g')" = "=" ]; then
        out="        ${environment_array[i-1]} = \"${environment_array[i+1]}\";"
        echo "$out"
    fi
done
echo "    };"

# ports
echo "    ports = ["
port_list="$(echo "$port_list" | sed 's/-//g' |  sed 's/^ *//' | sed 's/:/ : /g')"
IFS=' ' read -r -a port_array <<< "$port_list"
for i in "${!port_array[@]}"
do
    if [  "$(echo "${port_array[i]}" | sed 's/ //g')" = ":" ]; then
        out="       \"${port_array[i-1]}=${port_array[i+1]}\""
        echo "$out"
    fi
done
echo "    ];"

# volumes
echo "    volumes = ["
volume_list="$(echo "$volume_list" | sed 's/-//g' |  sed 's/^ *//' | sed 's/:/ : /g')"
IFS=' ' read -r -a volume_array <<< "$volume_list"
for i in "${!volume_array[@]}"
do
    if [  "$(echo "${volume_array[i]}" | sed 's/ //g')" = ":" ]; then
        out="        \"${volume_array[i-1]}=${volume_array[i+1]}\""
        echo "$out"
    fi
done
echo "    ];"

# EOF
echo "};"
