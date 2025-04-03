package com.abg.flutter_httpdns.okhttp;

import android.util.Log;

import androidx.annotation.NonNull;

import com.tencent.msdk.dns.MSDKDnsResolver;
import com.tencent.msdk.dns.core.IpSet;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import okhttp3.Dns;

// OkHttp 走腾讯HttpDns解析
public class OkHttpDns implements Dns {

    private final Map<String, String> lookupMapping;

    public OkHttpDns(Map<String, String> lookupMapping) {
        this.lookupMapping = lookupMapping;
    }

    @NonNull
    @Override
    public List<InetAddress> lookup(@NonNull String domain) throws UnknownHostException {
        List<InetAddress> inetAddresses = new ArrayList<>();
        try {
            IpSet ipSet = MSDKDnsResolver.getInstance().getAddrsByName(getLookupDomain(domain));
            // IPV4
            if (ipSet.v4Ips != null) {
                for (String ipv4 : ipSet.v4Ips) {
                    inetAddresses.add(InetAddress.getByName(ipv4));
                }
            }
            // IPV6
            if (ipSet.v6Ips != null) {
                for (String ipv6 : ipSet.v6Ips) {
                    inetAddresses.add(InetAddress.getByName(ipv6));
                }
            }
        } catch (Exception e) {
            Log.e("HTTPDNS", e.getMessage() == null ? "getAddrsByName 获取失败" : e.getMessage());
        }
        if (inetAddresses.isEmpty()) {
            Log.d("OkHttpDns", "httpdns 未返回IP，走localdns");
            return Dns.SYSTEM.lookup(domain);
        }
        Log.d("inetAddresses", domain);
        return inetAddresses;
    }

    // 替换成实际解析域名
    private String getLookupDomain(String domain) {
        Log.d("getLookupDomain", domain);
        if (lookupMapping == null || lookupMapping.isEmpty()) {
            return domain;
        }
        for (Map.Entry<String, String> entry : lookupMapping.entrySet()) {
            if (domain.equals(entry.getKey())) {
                return entry.getValue();
            }
        }
        return domain;
    }
}
