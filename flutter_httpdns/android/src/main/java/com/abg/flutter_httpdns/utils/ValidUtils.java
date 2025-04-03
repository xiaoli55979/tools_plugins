package com.abg.flutter_httpdns.utils;

import com.google.gson.Gson;
import com.google.gson.JsonParser;
import com.google.gson.JsonSyntaxException;

import java.util.Collection;

public abstract class ValidUtils {

    public static boolean isNotEmpty(String value) {
        return !isEmpty(value);
    }

    public static boolean isEmpty(String value) {
        return value == null || value.trim().isEmpty();
    }

    public static boolean isEmpty(Collection<?> value) {
        return value == null || value.isEmpty();
    }

    public static boolean isJson(String json){
        try {
            JsonParser.parseString(json);
        } catch (JsonSyntaxException e) {
            return false;
        }
        return true;
    }
}
