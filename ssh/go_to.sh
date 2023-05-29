#!/bin/sh

stty erase ^H

ips=()
key=""

function sshToIp(){
    ip=$1

    isItDev=`grep "${ip}" to.ip|grep -i itDev`
    if [[ $isItDev == '' ]]; then

        isWrap=`ssh root@$ip 'grep -wo wrap /root/.bash_profile'`
        if [[ $isWrap == '' ]]; then
            # add: alias breakLine="sed 's/;/\n/g'"  to /root/.bash_profile
            ssh root@$ip " echo \"alias wrap=\\\"sed 's/;/\\\\n/g'\\\" \" >>/root/.bash_profile" 
        fi

        # get ip's hostname
        myHostname=`ssh root@$ip 'hostname'`

        #echo $key
        if [[ "$key" =~ ^[a-z\-]+$ ]];then
            echo -ne "\e]2;${key}_${ip}\a"
            ssh -l root $ip -o StrictHostKeyChecking=no
        else
            echo -ne "\e]2;${ip}\a"
            ssh -l root $ip -o StrictHostKeyChecking=no
        fi
    else
        # get ip's hostname
        myHostname=`sshpass -p Qianjundevit ssh -l itdev $ip 'hostname'`
        
        #echo $key
        if [[ "$key" =~ ^[a-z\-]+$ ]];then
            echo -ne "\e]2;${key}_${ip}\a"
            sshpass -p Qianjundevit ssh -o StrictHostKeyChecking=no -l itdev $ip
        else
            echo -ne "\e]2;${ip}\a"
            sshpass -p Qianjundevit ssh -o StrictHostKeyChecking=no -l itdev $ip
        fi
    fi
}

function searchKey(){

    ipFile="to.ip"
    ips=()

    if [ ! -f "${ipFile}" ]; then
        echo "${ipFile} not found, stop...."
        exit
    fi

    key=$1
    if [[ $key == '###' ]];then
        echo -en "please enter search key: "
        read key   
    fi

    # if searchKey is a ip, 
    if [[ "$key" =~ ^([0-9]{1,3}.){3}[0-9]{1,3}$ ]]; then
        sshToIp $key
        exit
    fi

    echo ""
    i=0

    while read line
    do
        if [ -n "${line}" ];then    

            if [[ $line == *$key* ]];then
            
                ips[$i]=$line
                tmp=($line)
            
                prefix=' '  
                if [ $i -gt 9 ];then
                   prefix=''
                fi       
                
                tmpIp=${tmp[0]}
                tmpDetail=${tmp[1]}  
                highLightIp=${tmpIp//$key/\\033[42;37;1m$key\\033[0m} 
                highLightDetail=${tmpDetail//$key/\\033[42;37;1m$key\\033[0m}

                #echo -e "${prefix}${i}  ${tmpIp//$key/\e[1m$key\e[0m}  ${tmpDetail//$key/\e[1m$key\e[0m}"
                #echo -e "${prefix}${i}  ${tmpIp//$key/\e[42;37;1m$key\e[0m}  ${tmpDetail//$key/\e[42;37;1m$key\e[0m}"
                echo -e "${prefix}${i}  ${highLightIp}  ${highLightDetail}"
            
                let i+=1
            fi
        else
            echo ""
        fi
    done < "${ipFile}";
}

function mainRun(){
   
    ipsLen=${#ips[@]}

    if [[ $ipsLen == 1 ]];then
        # only one result match
        tmp=(${ips[0]})
        ip=${tmp[0]}
        clear

        #call ssh
        sshToIp $ip

    elif [[ $ipsLen == 0 ]];then
        # no result match, run mainRun again
        echo "not found..."
        echo ""
        searchKey '###'
        mainRun

    else
        ip=''
        while [[ $ip == '' ]]
        do
            echo ""
            echo -en "please enter ip's index or new search key: "
            read index

            # number, call searchKey
            if [[ "$index" =~ ^[0-9]{1,3}$ ]];then
                if [[ $index -ge $ipsLen ]];then
                   searchKey $index
                   mainRun
                   
                else     
                    tmp=(${ips[$index]})
                    ip=${tmp[0]}

                    if [[ $ip == '' ]];then
                        echo ""
                        echo "incorrect index !!!!!!"
                    else
                        echo "going to '${ip}'..."
                        clear

                        #call ssh
                        sshToIp $ip
                    fi
                fi
            else
                searchKey $index
                mainRun
            fi
        done
    fi
}

# call searchKey
searchKey '###'
# call mainRun
mainRun