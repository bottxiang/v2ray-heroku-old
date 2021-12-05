#!/bin/sh

# Download and install V2Ray
mkdir /tmp/v2ray
wget -q https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip -O /tmp/v2ray/v2ray.zip
unzip /tmp/v2ray/v2ray.zip -d /tmp/v2ray
install -m 755 /tmp/v2ray/v2ray /usr/local/bin/v2ray
install -m 755 /tmp/v2ray/v2ctl /usr/local/bin/v2ctl

# Remove temporary directory
rm -rf /tmp/v2ray

# V2Ray new configuration
install -d /usr/local/etc/v2ray
cat << EOF > /usr/local/etc/v2ray/config.json
{
  "log": {
    "loglevel": "info"
  },
  "reverse": {
    //这是 B 的反向代理设置，必须有下面的 portals 对象
    "portals": [
      {
        "tag": "portal",
        "domain": "pc1.localhost" // 必须和上面 A 设定的域名一样
      }
    ]
  },
  "inbounds": [
    {
      // 接受 C 的inbound
      "tag": "tunnel", // 标签，路由中用到
      "port": 443,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/"
        }
      }
    },
    // 另一个 inbound，接受 A 主动发起的请求
    {
      "tag": "interconn", // 标签，路由中用到
      "port": 443,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "/"
        }
      }
    }
  ],
  "routing": {
    "rules": [
      {
        //路由规则，接收 C 的请求后发给 A
        "type": "field",
        "inboundTag": ["interconn"],
        "outboundTag": "portal"
      },
      {
        //路由规则，让 B 能够识别这是 A 主动发起的反向代理连接
        "type": "field",
        "inboundTag": ["tunnel"],
        "domain": [
          // "full:private.cloud.com" // 将指定域名的请求发给 A，如果希望将全部流量发给 A，这里可以不设置域名规则。
        ],
        "outboundTag": "portal"
      }
    ]
  }
}
EOF

# Run V2Ray
/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
