package com.abg.flutter_httpdns.okhttp;

public interface ErrorHandler {

    void onError(String url, Exception e);
}
