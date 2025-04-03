package com.abg.flutter_httpdns;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.abg.flutter_httpdns.cache.CacheUtil;
import com.abg.flutter_httpdns.cache.CacheUtilConfig;
import com.abg.flutter_httpdns.okhttp.OkHttpDns;
import com.abg.flutter_httpdns.okhttp.OkHttpRetryInterceptor;
import com.abg.flutter_httpdns.utils.AESUtils;
import com.abg.flutter_httpdns.utils.CacheManager;

import com.abg.flutter_httpdns.utils.ValidUtils;
import com.google.gson.Gson;
import com.tencent.msdk.dns.DnsConfig;
import com.tencent.msdk.dns.MSDKDnsResolver;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.logging.HttpLoggingInterceptor;

/**
 * FlutterHttpdnsPlugin
 */
public class FlutterHttpdnsPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private EventChannel mEventChannel;
    private EventChannel.EventSink eventSink;
    private Context context;
    private final Map<String, Result> results = new ConcurrentHashMap<>();
    private OkHttpClient mOkHttpClient;
    private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());
    private String aesKey;
    private List<String> defaultOssEndpoints;
    private List<String> defaultDomainEndpoints;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        // method
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_httpdns");
        channel.setMethodCallHandler(this);
        // event
        mEventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_httpdns_event");
        mEventChannel.setStreamHandler(this);
        // context
        context = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("init")) {
            String dnsId = call.argument("dnsId");
            String dnsKey = call.argument("dnsKey");
            Boolean debug = call.argument("debug");
            Boolean persistentCache = call.argument("persistentCache");
            Boolean cachedIpEnable = call.argument("cachedIpEnable");
            Boolean useExpiredIpEnable = call.argument("useExpiredIpEnable");

            Map<String, String> lookupMapping = call.argument("lookupMapping");
            aesKey = call.argument("aesKey");
            defaultOssEndpoints = call.argument("defaultOss");
            defaultDomainEndpoints = call.argument("defaultDomains");

            if (isEmpty("dnsId", dnsId, result)) {
                return;
            }
            if (isEmpty("dnsKey", dnsKey, result)) {
                return;
            }
            if (isEmpty("aesKey", aesKey, result)) {
                return;
            }

            try {
                MSDKDnsResolver.getInstance().init(context, new DnsConfig.Builder()
                        .dnsId(dnsId)
                        .dnsKey(dnsKey)
                        .aesHttp()
                        .enablePersistentCache(Boolean.TRUE.equals(persistentCache))
                        .setCachedIpEnable(Boolean.TRUE.equals(cachedIpEnable))
                        .setUseExpiredIpEnable(Boolean.TRUE.equals(useExpiredIpEnable))
                        .logLevel(Boolean.TRUE.equals(debug) ? Log.DEBUG : Log.VERBOSE)
                        .build());
                MSDKDnsResolver.getInstance().setHttpDnsResponseObserver((tag, domain, hostResult) -> {
                    Result asyncRet = results.remove(tag);
                    if (asyncRet != null) {
                        asyncRet.success(hostResult);
                    }
                });

                // CacheInit
                CacheUtilConfig cc = CacheUtilConfig.builder(context)
                        .allowMemoryCache(true)
                        .allowEncrypt(false)
                        .build();
                CacheUtil.init(cc);

                // OkHttp init
                OkHttpClient.Builder builder = new OkHttpClient.Builder();

                // DEBUG模式下开启日志打印
                if (Boolean.TRUE.equals(debug)) {
                    HttpLoggingInterceptor loggingInterceptor = new HttpLoggingInterceptor();
                    loggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BASIC);
                    builder.addInterceptor(loggingInterceptor);
                }

                // 初始化线路缓存
                CacheManager.getInstance()
                        .initEndpoints(defaultOssEndpoints, defaultDomainEndpoints);

                mOkHttpClient = builder.retryOnConnectionFailure(false)
                        .readTimeout(8, TimeUnit.SECONDS)
                        .connectTimeout(3, TimeUnit.SECONDS)
                        .addInterceptor(new OkHttpRetryInterceptor(aesKey, (url, e) -> {
                            if (eventSink != null) {
                                uiThreadHandler.post(() -> {
                                    Map<String, Object> obj = new HashMap<>();
                                    obj.put("url", url);
                                    obj.put("error", e.getMessage());
                                    eventSink.success(obj);
                                });
                            }
                        }))
                        .dns(new OkHttpDns(lookupMapping)).build();

                result.success("success");
            } catch (Exception e) {
                result.error("exception", e.getMessage(), "");
            }
        } else if (call.method.equals("getAddrByNameAsync")) {
            String domain = call.argument("domain");
            if (isEmpty("domain", domain, result)) {
                return;
            }
            String tag = domain + System.currentTimeMillis();
            results.put(tag, result);
            MSDKDnsResolver.getInstance().getAddrByNameAsync(domain, tag);
        } else if (call.method.equals("getAddrsByNameAsync")) {
            String domain = call.argument("domain");
            if (isEmpty("domain", domain, result)) {
                return;
            }
            String tag = domain + System.currentTimeMillis();
            results.put(tag, result);
            MSDKDnsResolver.getInstance().getAddrsByNameAsync(domain, tag);
        } else if (call.method.equals("getConfig")) {
            Integer appId = call.argument("appId");
            String configKey = call.argument("configKey");
            String configHost = call.argument("configHost");
            if (isNull("appId", appId, result)) {
                return;
            }
            if (isEmpty("configHost", configHost, result)) {
                return;
            }
            if (isEmpty("configKey", configKey, result)) {
                return;
            }
            if (isEmpty("aesKey", aesKey, result)) {
                return;
            }
            if (isNull("mOkHttpClient", mOkHttpClient, result)) {
                return;
            }
            String iv = AESUtils.RandomIV();
            String payload = buildReqBody(configKey, aesKey, iv);
            Request req = new Request.Builder()
                    .url("https://" + configHost + "/api/v1/app/" + appId + "/config/get")
                    .addHeader("x-sign", iv)
                    .addHeader("content-type", "application/json;charset=utf-8")
                    .post(RequestBody.create(payload, MediaType.parse("application/json;charset=utf-8")))
                    .build();
            mOkHttpClient.newCall(req)
                    .enqueue(new Callback() {
                        @Override
                        public void onFailure(Call call, IOException e) {
                            result.error("exception", e.getMessage(), e);
                        }

                        @Override
                        public void onResponse(Call call, Response response) throws IOException {
                            String configValue = response.body().string();
                            try {
                                Map<String, Object> obj = new Gson().fromJson(configValue, Map.class);
                                // 结果解析，线路缓存
                                List<String> ossList = (List) obj.get("oss");
                                List<String>  domainList = (List) obj.get("domains");

                                // OSS可用列表获取，放入缓存
                                CacheManager.getInstance().setOssEndpoints(ossList);

                                // Domain可用列表获取，放入缓存
                                CacheManager.getInstance().setDomainEndpoints(domainList);

                                result.success(obj);
                            } catch (Exception e) {
                                result.error("exception", e.getMessage(), "");
                            }
                        }
                    });

        } else if (call.method.equals("cleanCache")) {
            try {
                // 清除缓存
                CacheManager.getInstance().clearAllCache();
                // 重新初始化默认线路
                CacheManager.getInstance()
                        .initEndpoints(defaultOssEndpoints, defaultDomainEndpoints);
            } catch (Exception ignored){}
            result.success("success");
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        mEventChannel.setStreamHandler(null);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.eventSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.eventSink = null;
    }

    private static String buildReqBody(String configKey, String aesKey, String iv) {
        Gson gson = new Gson();
        Map<String, Object> params = new HashMap<>();
        params.put("configKey", configKey);

        String encodeData = AESUtils.Encrypt(aesKey, iv, gson.toJson(params));

        Map<String, Object> body = new HashMap<>();
        body.put("data", encodeData);
        return gson.toJson(body);
    }

    private static boolean isEmpty(String name, String value, Result result) {
        if (ValidUtils.isEmpty(value)) {
            result.error("argsError", name + " is empty", "");
            return true;
        }
        return false;
    }

    private static boolean isNull(String name, Object value, Result result) {
        if (value == null) {
            result.error("argsError", name + " is null", "");
            return true;
        }
        return false;
    }
}
