cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_k8s
}

vrrp_script CheckK8sMaster {
    script "curl -k https://192.168.4.245:6443"
    interval 3
    timeout 9
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth1
    virtual_router_id 61
    priority 100
    advert_int 1
    mcast_src_ip 192.168.4.240
    nopreempt
    authentication {
        auth_type PASS
        auth_pass sqP05dQgMSlzrxHj
    }
    unicast_peer {
       	192.168.4.241
       	192.168.4.242
    }
    virtual_ipaddress {
        192.168.4.245/24
    }
    track_script {
        CheckK8sMaster
    }

}
EOF