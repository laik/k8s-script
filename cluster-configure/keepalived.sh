#需要做一些处理,如果是kubum1 那么unicast_peer 的地址是另外两个

cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_k8s
}

vrrp_script CheckK8sMaster {
    script "curl https://${CLUSTER_IP}:30000 -k /etc/kubernetes/pki/ca.crt"
    interval 3
    timeout 9
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface em1
    virtual_router_id 61
    priority 100
    advert_int 1
    mcast_src_ip ${PRIVATE_IP}
    nopreempt
    authentication {
        auth_type PASS
        auth_pass sqP05dQgMSlzrxHj
    }
    unicast_peer {
        192.168.4.240
        192.168.4.241
    }
    virtual_ipaddress {
        ${CLUSTER_IP}/24
    }
    track_script {
        CheckK8sMaster
    }

}
EOF


# start and enable service
systemctl restart keepalived
systemctl enable keepalived