package com.abg.flutter_httpdns.utils;


import com.abg.flutter_httpdns.cache.CacheUtil;
import java.util.List;


public class CacheManager {

    private static final String OSS_KEY = "ossEndpoints";
    private static final String DOMAIN_KEY = "domainEndpoints";

    private CacheManager() {
    }

    private static final class InstanceHolder {
        static final CacheManager instance = new CacheManager();
    }

    public static CacheManager getInstance() {
        return InstanceHolder.instance;
    }

    /**
     * 初始化缓存
     *
     * @param ossList
     * @param domains
     */
    public void initEndpoints(List<String> ossList, List<String> domains) {
        if(ValidUtils.isEmpty(getOssEndpoints()) && !ValidUtils.isEmpty(ossList)){
            CacheUtil.put(OSS_KEY, ossList);
        }
        if(ValidUtils.isEmpty(getDomainEndpoints()) && !ValidUtils.isEmpty(domains)){
            CacheUtil.put(DOMAIN_KEY, domains);
        }
    }

    /**
     * OSS线路
     *
     * @param endpoints
     */
    public void setOssEndpoints(List<String> endpoints) {
        if(!ValidUtils.isEmpty(endpoints)){
            CacheUtil.put(OSS_KEY, endpoints);
        }
    }

    /**
     * 备案域名线路
     * @param domains
     */
    public void setDomainEndpoints(List<String> domains){
        if(!ValidUtils.isEmpty(domains)){
            CacheUtil.put(DOMAIN_KEY, domains);
        }
    }

    /**
     * 获取OSS可用线路
     *
     * @param index
     * @return
     */
    public String getNextOssEndpoint(int index) {
        List<String> cached = getOssEndpoints();
        if (ValidUtils.isEmpty(cached) || cached.size() <= index) {
            return null;
        }
        return cached.get(index);
    }

    /**
     * 获取Domain可用线路
     *
     * @param index
     * @return
     */
    public String getNextDomainEndpoint(int index) {
        List<String> cached = getDomainEndpoints();
        if (ValidUtils.isEmpty(cached) || cached.size() <= index) {
            return null;
        }
        return cached.get(index);
    }

    /**
     * 获取所有OSS列表
     *
     * @return
     */
    public List<String> getOssEndpoints() {
        return CacheUtil.get(OSS_KEY, List.class);
    }

    /**
     * 获取所有域名列表
     *
     * @return
     */
    public List<String> getDomainEndpoints() {
        return CacheUtil.get(DOMAIN_KEY, List.class);
    }

    // 清空缓存
    public void clearAllCache() {
        CacheUtil.clearAll();
    }
}
