#!/bin/bash

type="$1"

# 获取账密
if [ "$type" = 'AppleAccount' ]; then
    # 唤起一个弹框输入账号
    username=$(osascript -e 'Tell application "System Events" to display dialog "请输入 Apple 账号(如是手机号前面+86):" with title "Miniapp Builder" default answer "" buttons {"Cancel", "OK"} default button "OK"' -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)

    # 如果用户输入了账号，才会要求输入密码
    if [ "$username" != "Cancel" ]; then
        password=$(osascript -e 'Tell application "System Events" to display dialog "请输入 Apple 密码:"  with title "Miniapp Builder" with hidden answer default answer "" buttons {"Cancel", "OK"} default button "OK"' -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)
        if [ "$password" = "Cancel" ]; then
            username=""
            password=""
        else 
            remember=$(osascript -e 'Tell application "System Events" to display dialog "记住账号密码（只保存于本地）？"  with title "Miniapp Builder"  buttons {"No", "Yes"} default button "Yes"' -e 'if button returned of result is "Yes" then' -e 'return "yes"' -e 'else' -e 'return "no"' -e 'end if' 2>/dev/null)
        fi
    else
        username=""
    fi

    # 输出用户输入的账号和密码
    echo "$username"
    echo "$password"
    echo "$remember"
    exit 0
fi

# 获取证书和profile
if [ "$type" = 'AppleCertificate' ]; then
    # 选择证书路径
    certificatePath=$(osascript -e 'set p12File to choose file with prompt "请选择 Apple 签名证书（p12文件）" of type {"p12"}' -e 'if p12File is not equal to false then' -e 'set certificatePath to POSIX path of p12File' -e 'end if' 2>/dev/null)

    # 如果用户输入了证书，才会要求输入密码和选择profile
    if [ "$certificatePath" != '' ]; then
        certificatePassword=$(osascript -e 'Tell application "System Events" to display dialog "请输入证书密码:"  with title "Miniapp Builder" with hidden answer default answer "" buttons {"Cancel", "OK"} default button "OK"' -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)
        # 输入密码
        if [ "$certificatePassword" != 'Cancel' ]; then 
            # 选择profile
            profilePath=$(osascript -e 'set profilePath to choose file with prompt "请选择 profile 文件（mobileprovision文件）" of type {"mobileprovision"}' -e 'if profilePath is not equal to false then' -e 'set profilePath to POSIX path of profilePath' -e 'end if' 2>/dev/null)
            if [ "$certificatePassword" != 'Cancel' ]; then 
                remember=$(osascript -e 'Tell application "System Events" to display dialog "记住选择的证书等配置（只保存于本地）？"  with title "Miniapp Builder"  buttons {"No", "Yes"} default button "Yes"' -e 'if button returned of result is "Yes" then' -e 'return "yes"' -e 'else' -e 'return "no"' -e 'end if' 2>/dev/null)
            else
                certificatePath=""
                certificatePassword=""
                profilePath=""
            fi
        else 
            certificatePath=""
            certificatePassword=""
        fi
    else
        certificatePath=""
    fi

    echo "$certificatePath"
    echo "$certificatePassword"
    echo "$profilePath"
    echo "$remember"
    exit 0
fi


# 是否revoke证书
if [ "$type" = 'AppleCertificateRevoke' ]; then
    content="将会撤销你的Apple 开发证书并重新生产新的开发证书， \n\n这不会影响您提交到 App Store 的应用程序，但可能会导致您通过 Xcode 使用该证书安装到设备上的应用程序停止工作，除非您重新安装它们. \n\n如果不想这么做，可以尝试:\n1. 继续（不撤销）这个可能会签名失败\n2. 换用免费的Apple账号"
    result=$(osascript -e 'Tell application "System Events" to display dialog "'"$content"'"  with title "Miniapp Builder" buttons {"取消", "继续（不撤销）", "继续"} default button "继续"'  -e 'if button returned of result is "继续" then' -e 'return "OK"' -e 'else if button returned of result is "继续（不撤销）" then' -e 'return "OK_1"'  -e 'else' -e 'return "Cancel"' -e 'end if'  2>/dev/null)
    echo $result
    exit 0
fi

if [ "$type" = 'Input' ]; then
    typeCmd='default answer ""'
else
    typeCmd=""
fi

# 其他
content="$2"
inputType="$3"

if [ "$inputType" = 'password' ]; then
    inputTypeCmd="with hidden answer"
else
    inputTypeCmd=""
fi

# 唤起一个弹框输入
result=$(osascript -e 'Tell application "System Events" to display dialog "'"$content"'"  with title "Miniapp Builder" '"$typeCmd"' '"$inputTypeCmd"'  buttons {"Cancel", "OK"} default button "OK"'  -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)

# 输出用户输入的内容
if [ "$result" = "Cancel" ]; then
    if [ "$type" = 'Input' ]; then
        echo ""
    else
        echo "Cancel"
    fi
else
    if [ "$type" = 'Input' ]; then
        echo "$result"
    else
        echo "OK"
    fi
fi

