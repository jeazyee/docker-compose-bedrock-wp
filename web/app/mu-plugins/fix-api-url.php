<?php
/**
 * Plugin Name: Fix REST API URL for Docker
 * Description: Fixes REST API URL issues in Docker environment
 * Version: 1.0
 * Author: Jitendra Bodmann
 */

/**
 * Fix WordPress REST API URLs in Docker containers by replacing app_domain with the nginx service name
 */
add_filter('rest_url', function ($url) {
    // Get the WP_LOCAL_HOST from environment if configured
    $wp_local_host = getenv('WP_LOCAL_HOST');
    $app_domain = getenv('APP_DOMAIN');
    
    // Only modify internal requests from the PHP container
    if (!empty($wp_local_host) && strpos($url, $app_domain) !== false) {
        // Replace localhost with the nginx service name for internal requests
        return str_replace($app_domain, $wp_local_host, $url);
    }
    
    return $url;
});

/**
 * Fix HTTP requests made from within WordPress
 */
add_action('http_api_curl', function ($handle) {
    $wp_local_host = getenv('WP_LOCAL_HOST');
    
    if (!empty($wp_local_host)) {
        // Get the URL being requested
        $url = curl_getinfo($handle, CURLINFO_EFFECTIVE_URL);
        
        // If the request is to localhost, resolve it to the nginx service
        if (strpos($url, 'localhost') !== false) {
            $modified_url = str_replace('localhost', $wp_local_host, $url);
            curl_setopt($handle, CURLOPT_URL, $modified_url);
        }
    }
});
