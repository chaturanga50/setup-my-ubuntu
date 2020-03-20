#!/bin/bash

for list in $(cat packages.json | jq -r '.[] | @base64'); do
    _jq() {
        echo ${list} | base64 --decode | jq -r ${1}
    }

    name=$(_jq '.name')
    install_bin=$(_jq '.install_bin')
    local_version=$(_jq '.local_version')
    latest_version=$(_jq '.latest_version')
    download_script=$(_jq '.download_script')
    final_output=$(_jq '.final_output')
    current_version=
    latest_release=$(eval $latest_version)
    download_folder=/tmp/package-update

    # check the package already installed or not
    if [ -f "$install_bin" ];
    then
        current_version=$(eval $local_version)
        echo -e "\n$name $current_version already installed..checking for any updates..."
    else
        echo -e "\n$name not installed...proceeding with installation steps..."
    fi

    # create download folder if it's not there
    [ -d $download_folder ] || mkdir -p $download_folder

    # install/update package
    if [[ $current_version == $latest_release ]];
    then
        echo -e "$name up to date with version $current_version\n"
    else
        echo "updating $name to $latest_release"
        eval $download_script
        if [ $final_output == 'zip' ];
        then
            unzip $download_folder/${name}*.zip -d $download_folder/
            rm -rf $download_folder/${name}*.zip
            sudo rm -f $install_bin
            get_package=$(find $download_folder -name "$name")
            sudo mv $get_package $install_bin
            sudo chmod +x $install_bin
        elif [ $final_output == 'tar.gz' ];
        then
            tar -xzf $download_folder/$name*.tar.gz -C $download_folder/
            rm -rf $download_folder/${name}*.tar.gz
            sudo rm -f $install_bin
            get_package=$(find $download_folder -name "$name")
            sudo mv $get_package $install_bin
            sudo chmod +x $install_bin
        elif [ $final_output == 'tar' ];
        then
            tar -xf $download_folder/$name*.tar -C $download_folder/
            rm -rf $download_folder/${name}*.tar
            sudo rm -f $install_bin
            get_package=$(find $download_folder -name "$name")
            sudo mv $get_package $install_bin
            sudo chmod +x $install_bin
        elif [ $final_output == 'binary' ];
        then
            sudo rm -f $install_bin
            get_package=$(find $download_folder -name "$name*")
            sudo mv $get_package $install_bin
            sudo chmod +x $install_bin
        fi
        echo -e "$name update completed\n"
        echo -e "cleaning up the download folder..."
        rm -rf $download_folder
    fi
done