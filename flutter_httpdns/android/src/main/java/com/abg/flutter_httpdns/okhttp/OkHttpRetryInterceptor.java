package com.abg.flutter_httpdns.okhttp;


import androidx.annotation.NonNull;

import com.abg.flutter_httpdns.utils.AESUtils;
import com.abg.flutter_httpdns.utils.CacheManager;
import com.abg.flutter_httpdns.utils.ValidUtils;

import java.io.IOException;


import okhttp3.Interceptor;
import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

// OkHttpRetryInterceptor 重试机制
public class OkHttpRetryInterceptor implements Interceptor {

    private final ErrorHandler errorHandler;
    private final String aesKey;

    public OkHttpRetryInterceptor(String aesKey, ErrorHandler errorHandler) {
        this.aesKey = aesKey;
        this.errorHandler = errorHandler;
    }

    @NonNull
    @Override
    public Response intercept(@NonNull Chain chain) throws IOException {
        Request request = chain.request();
        Response response;
        int domainTryCount = 0;
        int ossTryCount = 0;

        while (true) {
            try {
                response = chain.proceed(request);

                // 除了判断状态码之外
                if (response.code() == 200 && response.body() != null) {
                    String value;
                    try {
                        String iv = request.header("x-sign");
                        if (ValidUtils.isEmpty(iv)) {
                            value = AESUtils.Decrypt(response.body().string(), aesKey);
                        } else {
                            value = AESUtils.Decrypt(response.body().string(), aesKey, iv);
                        }
                        return response.newBuilder()
                                .body(ResponseBody.create(value,MediaType.parse("application/json;charset=utf-8")))
                                .build();
                    } catch (Exception e) {
                        // 错误回调
                        if (errorHandler != null) {
                            errorHandler.onError(request.url().url().toString(), e);
                        }
                    }
                } else {
                    // 错误回调
                    if (errorHandler != null) {
                        errorHandler.onError(request.url().url().toString(), new RuntimeException("code=" + response.code() + ",msg=" + response.message()));
                    }
                }

                // 1、先尝试API调用重试
                request = buildDomainRequest(request, response, domainTryCount);
                if (request != null) {
                    domainTryCount++;
                    continue;
                }

                // 2、尝试OSS获取
                request = buildOssRequest(response, ossTryCount);
                if (request != null) {
                    ossTryCount++;
                    continue;
                }

                return response;
            } catch (Exception e) {
                // 异常回调
                if (errorHandler != null) {
                    errorHandler.onError(request != null ? request.url().url().toString() : "", e);
                }

                // 1、先尝试API调用重试
                request = buildDomainRequest(request, null, domainTryCount);
                if (request != null) {
                    domainTryCount++;
                    continue;
                }

                // 2、尝试OSS获取
                request = buildOssRequest(null, ossTryCount);
                if (request != null) {
                    ossTryCount++;
                    continue;
                }

                throw e;
            }
        }
    }


    /**
     * 构建API重试请求
     *
     * @param request
     * @param response
     * @param retryCount
     * @return
     */
    private Request buildDomainRequest(Request request, Response response, int retryCount) {
        String endpoint = CacheManager.getInstance().getNextDomainEndpoint(retryCount);
        if (ValidUtils.isNotEmpty(endpoint)) {
            if (response != null) {
                response.close();
            }
            return request.newBuilder()
                    .url(request.url().url().getProtocol() + "://" + endpoint + request.url().url().getPath())
                    .build();
        }
        return null;
    }

    /**
     * 构建OSS重试请求
     *
     * @param response
     * @param retryCount
     * @return
     */
    private Request buildOssRequest(Response response, int retryCount) {
        String endpoint = CacheManager.getInstance().getNextOssEndpoint(retryCount);
        if (ValidUtils.isNotEmpty(endpoint)) {
            if (response != null) {
                response.close();
            }
            return new Request.Builder().url(endpoint).build();
        }
        return null;
    }
}
