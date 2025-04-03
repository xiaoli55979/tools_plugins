package com.abg.flutter_httpdns.utils;

import android.util.Base64;
import android.util.Log;

import java.nio.charset.StandardCharsets;
import java.util.Random;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public abstract class AESUtils {

    private final static String charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    public static String RandomIV() {
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 16; i++) {
            int number = random.nextInt(62);
            sb.append(charset.charAt(number));
        }
        return sb.toString();
    }

    /**
     * 加密
     */
    public static String Encrypt(String key, String iv, String text) {
        if (text == null || text.isEmpty()) {
            return text;
        }
        try {
            byte[] result = encrypt(key, iv, text);
            return new String(Base64.encode(result, Base64.NO_WRAP));
        } catch (Exception e) {
            throw new RuntimeException("加密失败:" + e.getMessage());
        }
    }

    /**
     * IV内置解密
     *
     * @param key
     * @param text
     * @return
     */
    public static String Decrypt(String text, String key) {
        try {
            byte[] result = decrypt(Base64.decode(text, Base64.DEFAULT), key);
            return new String(result);
        } catch (Exception e) {
            throw new RuntimeException("解密失败:" + e.getMessage());
        }
    }

    /**
     * 解密
     */
    public static String Decrypt(String text, String key, String iv) {
        try {
            byte[] result = decrypt(Base64.decode(text, Base64.DEFAULT), key, iv);
            return new String(result);
        } catch (Exception e) {
           throw new RuntimeException("解密失败:" + e.getMessage());
        }
    }

    /**
     * 加密
     *
     * @param key
     * @param iv
     * @param text
     * @return
     * @throws Exception
     */
    private static byte[] encrypt(String key, String iv, String text) throws Exception {
        // 创建AES秘钥
        SecretKeySpec secretKeySpec = new SecretKeySpec(key.getBytes(), "AES");
        // 创建密码器
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING");
        // 初始化加密器
        cipher.init(Cipher.ENCRYPT_MODE, secretKeySpec, new IvParameterSpec(iv.getBytes()));
        // 加密
        return cipher.doFinal(text.getBytes());
    }

    /**
     * IV外置
     *
     * @param content
     * @param key
     * @param iv
     * @return
     * @throws Exception
     */
    private static byte[] decrypt(byte[] content, String key, String iv) throws Exception {
        // 创建AES秘钥
        SecretKeySpec skey = new SecretKeySpec(key.getBytes(), "AES");
        // 创建密码器
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING");
        // 初始化解密器
        cipher.init(Cipher.DECRYPT_MODE, skey, new IvParameterSpec(iv.getBytes()));
        // 解密
        return cipher.doFinal(content);
    }

    /**
     * IV内置
     *
     * @param content
     * @param key
     * @return
     * @throws Exception
     */
    private static byte[] decrypt(byte[] content, String key) throws Exception {
        byte[] iv = new byte[16];
        byte[] body = new byte[content.length - 16];
        System.arraycopy(content, 0, iv, 0, iv.length);
        System.arraycopy(content, 16, body, 0, body.length);

        // 创建AES秘钥
        SecretKeySpec skey = new SecretKeySpec(key.getBytes(), "AES");
        // 创建密码器
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING");
        // 初始化解密器
        cipher.init(Cipher.DECRYPT_MODE, skey, new IvParameterSpec(iv));
        // 解密
        return cipher.doFinal(body);
    }

    public static String toHexString(byte[] byteArray) {
        final StringBuilder hexString = new StringBuilder();
        if (byteArray == null || byteArray.length <= 0){
            return null;
        }
        for (int i = 0; i < byteArray.length; i++) {
            int v = byteArray[i] & 0xFF;
            String hv = Integer.toHexString(v);
            if (hv.length() < 2) {
                hexString.append(0);
            }
            hexString.append(hv);
        }
        return hexString.toString().toLowerCase();
    }
}
