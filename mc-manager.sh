#!/bin/bash

show_header() {
    echo -e "\e[1;34mMinecraft Bedrock Server Manager\e[0m"
    echo -e "\e[36mGitHub Repository: https://github.com/NimaTarlani/mc-manager\e[0m\n"
}

create_server() {
    echo "Creating a new Minecraft Bedrock server..."

    read -p "Enter the world name: " world_name

    while true; do
        read -p "Enter the server port: " server_port

        if lsof -i:"$server_port" &>/dev/null || grep -q "$server_port" /etc/systemd/system/mcserver-*.service; then
            echo "Port $server_port is already in use. Please choose a different port."
        else
            break
        fi
    done

    server_dir="/opt/minecraft/$world_name"
    mkdir -p "$server_dir"

    echo "Downloading Minecraft Bedrock server..."
    wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -O "$server_dir/bedrock-server.zip" "https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-1.21.84.1.zip"
    if [[ $? -ne 0 ]]; then
        echo "Failed to download the server files. Exiting."
        rm -rf "$server_dir"
        exit 1
    fi

    echo "Unzipping server files..."
    unzip -q "$server_dir/bedrock-server.zip" -d "$server_dir"
    rm "$server_dir/bedrock-server.zip"

    echo "Configuring server.properties..."
    sed -i "s/^server-port=.*/server-port=$server_port/" "$server_dir/server.properties"

    echo "Creating systemd service..."
    service_file="/etc/systemd/system/mcserver-$world_name.service"
    cat <<EOL > "$service_file"
[Unit]
Description=Minecraft Bedrock Server - $world_name
After=network.target

[Service]
WorkingDirectory=$server_dir
ExecStart=$server_dir/bedrock_server
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOL

    echo "Enabling and starting the server..."
    systemctl daemon-reload
    systemctl enable --now "mcserver-$world_name.service"

    echo "Server $world_name created and started successfully on port $server_port!"
}

delete_server() {
    echo "Deleting a Minecraft Bedrock server..."

    read -p "Enter the world name to delete: " world_name
    service_file="/etc/systemd/system/mcserver-$world_name.service"
    server_dir="/opt/minecraft/$world_name"

    if [[ ! -f "$service_file" ]]; then
        echo "Server $world_name does not exist."
        return
    fi

    echo "Stopping and disabling the server..."
    systemctl stop "mcserver-$world_name.service"
    systemctl disable "mcserver-$world_name.service"

    echo "Removing systemd service..."
    rm "$service_file"

    echo "Removing server files..."
    rm -rf "$server_dir"

    systemctl daemon-reload

    echo "Server $world_name has been deleted successfully."
}

list_servers() {
    echo -e "\nListing all Minecraft Bedrock servers:\n"
    printf "%-20s %-10s %-10s\n" "World Name" "Port" "Status"
    printf "%-20s %-10s %-10s\n" "----------" "----" "------"

    for service_file in /etc/systemd/system/mcserver-*.service; do
        [[ -e "$service_file" ]] || continue
        world_name=$(basename "$service_file" | sed 's/mcserver-\(.*\).service/\1/')
        server_dir="/opt/minecraft/$world_name"
        server_port=$(grep -E '^server-port=' "$server_dir/server.properties" | cut -d'=' -f2)

        if systemctl is-active --quiet "mcserver-$world_name.service"; then
            status="\e[32mOnline\e[0m"
        else
            status="\e[31mOffline\e[0m"
        fi

        printf "%-20s %-10s %-10b\n" "$world_name" "$server_port" "$status"
    done
    echo ""
}

edit_server() {
    echo "Editing a Minecraft Bedrock server..."

    read -p "Enter the world name to edit: " world_name
    server_dir="/opt/minecraft/$world_name"
    service_file="/etc/systemd/system/mcserver-$world_name.service"

    if [[ ! -d "$server_dir" || ! -f "$server_dir/server.properties" ]]; then
        echo "Server $world_name does not exist."
        return
    fi

    if systemctl is-active --quiet "mcserver-$world_name.service"; then
        echo "Stopping the server..."
        systemctl stop "mcserver-$world_name.service"
    fi

    echo "Editing server.properties..."
    nano "$server_dir/server.properties"

    echo "Restarting the server..."
    systemctl start "mcserver-$world_name.service"

    echo "Server $world_name has been updated and restarted successfully."
}

start_server() {
    echo "Starting a Minecraft Bedrock server..."
    list_servers
    read -p "Enter the world name to start: " world_name
    service_file="/etc/systemd/system/mcserver-$world_name.service"

    if [[ ! -f "$service_file" ]]; then
        echo "Server $world_name does not exist."
        return
    fi

    systemctl start "mcserver-$world_name.service"
    echo "Server $world_name has been started."
}

stop_server() {
    echo "Stopping a Minecraft Bedrock server..."
    list_servers
    read -p "Enter the world name to stop: " world_name
    service_file="/etc/systemd/system/mcserver-$world_name.service"

    if [[ ! -f "$service_file" ]]; then
        echo "Server $world_name does not exist."
        return
    fi

    systemctl stop "mcserver-$world_name.service"
    echo "Server $world_name has been stopped."
}

restart_server() {
    echo "Restarting a Minecraft Bedrock server..."
    list_servers
    read -p "Enter the world name to restart: " world_name
    service_file="/etc/systemd/system/mcserver-$world_name.service"

    if [[ ! -f "$service_file" ]]; then
        echo "Server $world_name does not exist."
        return
    fi

    systemctl restart "mcserver-$world_name.service"
    echo "Server $world_name has been restarted."
}

while true; do
    show_header
    echo "Minecraft Bedrock Server Manager"
    echo "----------------------------"
    echo "1. Create Server"
    echo "2. Delete Server"
    echo "----------------------------"
    echo "3. List Servers"
    echo "4. Edit Server"
    echo "----------------------------"
    echo "5. Start Server"
    echo "6. Stop Server"
    echo "7. Restart Server"
    echo "----------------------------"
    echo "0. Exit"
    read -p "Select an option: " choice

    case $choice in
        1) create_server ;;
        2) delete_server ;;
        3) list_servers ;;
        4) edit_server ;;
        5) start_server ;;
        6) stop_server ;;
        7) restart_server ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
