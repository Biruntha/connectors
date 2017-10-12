package org.wso2.ballerina.connectors.amazonauth;

import ballerina.doc;
import ballerina.net.http;
import ballerina.lang.strings;
import ballerina.lang.system;
import ballerina.utils;
import ballerina.net.uri;
import ballerina.net.http.request;


@doc:Description { value:"Amazon Auth connector"}
@doc:Param { value:"accessKeyId: The access key ID of the Amazon Account"}
@doc:Param { value:"secretAccessKey: The secret access key of the Amazon Account"}
@doc:Param { value:"region: The region to which the request is made"}
@doc:Param { value:"serviceName: The Amazon service that should be invoked"}
@doc:Param { value:"terminationString: The termination string for the request"}
@doc:Param { value:"endpoint: The Endpoint of the amazon service"}
public connector ClientConnector (string accessKeyId, string secretAccessKey, string region, string serviceName,
                           string terminationString, string endpoint) {
    http:ClientConnector awsEP = create http:ClientConnector(endpoint, {});
    @doc:Description { value:"Get List of Objects in a bucket"}
    @doc:Param { value:"requestMsg: The request message object"}
    @doc:Param { value:"httpVerb: The HTTP verb"}
    @doc:Param { value:"requestURI: The URI of the service to be invoked"}
    @doc:Param { value:"payload: The payload to be sent"}
    @doc:Return { value:"response object"}
    action request (http:Request requestMsg, string httpVerb, string requestURI, string payload) (http:Response) {
        http:Response response;
        requestMsg = generateSignature(requestMsg, accessKeyId, secretAccessKey, region, serviceName, terminationString,
                                       httpVerb, requestURI, payload);

        if (strings:equalsIgnoreCase(httpVerb, "POST")) {
            response = awsEP.post (requestURI, requestMsg);
        } else if (strings:equalsIgnoreCase(httpVerb, "GET")) {
            response = awsEP.get (requestURI, requestMsg);
        } else if (strings:equalsIgnoreCase(httpVerb, "PUT")) {
            response = awsEP.put (requestURI, requestMsg);
        } else if (strings:equalsIgnoreCase(httpVerb, "DELETE")) {
            response = awsEP.delete (requestURI, requestMsg);
        }
        return response;
    }
}

function generateSignature (http:Request req, string accessKeyId, string secretAccessKey, string region, string serviceName,
                            string terminationString, string httpVerb, string requestURI, string payload) (http:Response) {
    string canonicalRequest;
    string canonicalQueryString;
    string stringToSign;
    string payloadBuilder;
    string payloadStrBuilder;
    string authHeader;
    string algorithm;
    string amzDate;
    string shortDate;
    string signedHeader;
    string canonicalHeaders;
    string signedHeaders;
    string requestPayload;
    string signingKey;

    algorithm = "SHA256";

    amzDate = system:getDateFormat("yyyyMMdd'T'HHmmss'Z'");
    shortDate = system:getDateFormat("yyyyMMdd");
    request:setHeader(req, "X-Amz-Date", amzDate);
    canonicalRequest = httpVerb;
    canonicalRequest = canonicalRequest + "\n";
    canonicalRequest = canonicalRequest + strings:replaceAll(uri:encode(requestURI), "%2F", "/");
    canonicalRequest = canonicalRequest + "\n";
    canonicalQueryString = "";
    canonicalRequest = canonicalRequest + canonicalQueryString;
    canonicalRequest = canonicalRequest + "\n";

    if (payload != "" && payload != "UNSIGNED-PAYLOAD") {
        canonicalHeaders = canonicalHeaders + strings:toLowerCase("Content-Type");
        canonicalHeaders = canonicalHeaders + ":";
        canonicalHeaders = canonicalHeaders + (request:getHeader(req, strings:toLowerCase("Content-Type")));
        canonicalHeaders = canonicalHeaders + "\n";
        signedHeader = signedHeader + strings:toLowerCase("Content-Type");
        signedHeader = signedHeader + ";";
    }

    canonicalHeaders = canonicalHeaders + strings:toLowerCase("Host");
    canonicalHeaders = canonicalHeaders + ":";
    canonicalHeaders = canonicalHeaders + request:getHeader(req, strings:toLowerCase("Host"));
    canonicalHeaders = canonicalHeaders + "\n";
    signedHeader = signedHeader + strings:toLowerCase("Host");
    signedHeader = signedHeader + ";";

    if (payload == "UNSIGNED-PAYLOAD") {
        canonicalHeaders = canonicalHeaders + strings:toLowerCase("X-Amz-Content-Sha256");
        canonicalHeaders = canonicalHeaders + ":";
        canonicalHeaders = canonicalHeaders + request:getHeader(req, strings:toLowerCase("X-Amz-Content-Sha256"));
        canonicalHeaders = canonicalHeaders + "\n";
        signedHeader = signedHeader + strings:toLowerCase("x-amz-content-sha256");
        signedHeader = signedHeader + ";";
    }

    canonicalHeaders = canonicalHeaders + strings:toLowerCase("X-Amz-Date");
    canonicalHeaders = canonicalHeaders + ":";
    canonicalHeaders = canonicalHeaders + (request:getHeader(req, strings:toLowerCase("X-Amz-Date")));
    canonicalHeaders = canonicalHeaders + "\n";
    signedHeader = signedHeader + strings:toLowerCase("X-Amz-Date");
    signedHeader = signedHeader;

    canonicalRequest = canonicalRequest + canonicalHeaders;
    canonicalRequest = canonicalRequest + "\n";
    signedHeaders = "";
    signedHeaders = signedHeader;
    canonicalRequest = canonicalRequest + signedHeaders;
    canonicalRequest = canonicalRequest + "\n";
    payloadBuilder = payload;
    requestPayload = "";
    requestPayload = payloadBuilder;

    if (payloadBuilder == "UNSIGNED-PAYLOAD") {
        requestPayload = payloadBuilder;
    } else {
        requestPayload = strings:toLowerCase(utils:getHash(payloadBuilder, algorithm));
    }

    canonicalRequest = canonicalRequest + requestPayload;

    //Start creating the string to sign

    stringToSign = stringToSign + "AWS4-HMAC-SHA256";
    stringToSign = stringToSign + "\n";
    stringToSign = stringToSign + amzDate;
    stringToSign = stringToSign + "\n";
    stringToSign = stringToSign + shortDate;
    stringToSign = stringToSign + "/";
    stringToSign = stringToSign + region;
    stringToSign = stringToSign + "/";
    stringToSign = stringToSign + serviceName;
    stringToSign = stringToSign + "/";
    stringToSign = stringToSign + terminationString;
    stringToSign = stringToSign + "\n";
    string hashedValue = utils:getHash(canonicalRequest, algorithm);
    stringToSign = stringToSign + strings:toLowerCase(hashedValue);
    signingKey = utils:getHmacFromBase64(terminationString, utils:getHmacFromBase64(serviceName,
                                                                                    utils:getHmacFromBase64(region, utils:getHmacFromBase64(shortDate, utils:base64encode("AWS4" + secretAccessKey),
                                                                                                                                            algorithm), algorithm), algorithm), algorithm);
    authHeader = authHeader + ("AWS4-HMAC-SHA256");
    authHeader = authHeader + (" ");
    authHeader = authHeader + ("Credential");
    authHeader = authHeader + ("=");
    authHeader = authHeader + (accessKeyId);
    authHeader = authHeader + ("/");
    authHeader = authHeader + (shortDate);
    authHeader = authHeader + ("/");
    authHeader = authHeader + (region);
    authHeader = authHeader + ("/");
    authHeader = authHeader + (serviceName);
    authHeader = authHeader + ("/");
    authHeader = authHeader + (terminationString);
    authHeader = authHeader + (",");
    authHeader = authHeader + (" SignedHeaders");
    authHeader = authHeader + ("=");
    authHeader = authHeader + (signedHeaders);
    authHeader = authHeader + (",");
    authHeader = authHeader + (" Signature");
    authHeader = authHeader + ("=");
    string encodedValue = utils:base64ToBase16Encode(utils:getHmacFromBase64(stringToSign, signingKey, algorithm));
    authHeader = authHeader + strings:toLowerCase(encodedValue);
    request:setHeader(req, "Authorization", authHeader);

    return req;
}