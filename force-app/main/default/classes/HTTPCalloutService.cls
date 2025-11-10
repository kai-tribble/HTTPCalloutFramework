/*
* Application Name:- HTTPCalloutFramework
* License:- BSD 3-Clause "New" or "Revised" License
* Created:- 27/11/2019
* Last Updated:- 05/04/2020
* Description:- This is the service class for performing HTTP Callouts
* Contributors:-
*    1. Rahul Malhotra
*/
public class HTTPCalloutService {

    private HTTPCalloutConfiguration__mdt calloutMetadata;
    private HTTPCalloutEnvironment__mdt environmentOverride;
    private String endpointURL;
    private String requestMethod;
    private String requestBody;
    private String requestCertificate;
    private String namedCredential;
    private Blob requestBodyAsBlob;
    private Dom.Document requestBodyAsDocument;
    private Integer requestTimeout;
    private Boolean isCompressedRequest;
    private Boolean isActive;
    private Boolean isLoggingRequest;
    private Boolean isLoggingResponse;
    private Boolean retryOnFailure;
    private Integer maxRetries;
    private Integer retryDelay;
    private Set<Integer> successCodes;
    private Map<String, String> urlParametersMap;
    private Map<String, String> headerParametersMap;
    private static final String TYPE_URL_PARAMETERS = 'URL_PARAMETERS';
    private static final String TYPE_HEADER_PARAMETERS = 'HEADER_PARAMETERS';
    private HTTPRequest request;

    /*
    * Getters and Setters - Begin
    */
	public String getEndpointURL() {
		return endpointURL;
	}

	public void setEndpointURL(String endpointURL) {
		this.endpointURL = endpointURL;
	}

	public String getRequestMethod() {
		return requestMethod;
	}

	public void setRequestMethod(String requestMethod) {
		this.requestMethod = requestMethod;
	}

	public String getRequestBody() {
		return requestBody;
	}

	public void setRequestBody(String requestBody) {
		this.requestBody = requestBody;
	}

	public Blob getRequestBodyAsBlob() {
		return requestBodyAsBlob;
	}

	public void setRequestBodyAsBlob(Blob requestBodyAsBlob) {
		this.requestBodyAsBlob = requestBodyAsBlob;
	}

	public Dom.Document getRequestBodyAsDocument() {
		return requestBodyAsDocument;
	}

	public void setRequestBodyAsDocument(Dom.Document requestBodyAsDocument) {
		this.requestBodyAsDocument = requestBodyAsDocument;
	}

	public String getRequestCertificate() {
		return requestCertificate;
	}

	public void setRequestCertificate(String requestCertificate) {
		this.requestCertificate = requestCertificate;
	}

	public Integer getRequestTimeout() {
		return requestTimeout;
	}

	public void setRequestTimeout(Integer requestTimeout) {
		this.requestTimeout = requestTimeout;
	}

	public Boolean getIsCompressedRequest() {
		return isCompressedRequest;
	}

	public void setIsCompressedRequest(Boolean isCompressedRequest) {
		this.isCompressedRequest = isCompressedRequest;
	}

	public String getNamedCredential() {
		return namedCredential;
	}

	public void setNamedCredential(String namedCredential) {
		this.namedCredential = namedCredential;
	}

	public Boolean getIsActive() {
		return isActive;
	}

	public Boolean getRetryOnFailure() {
		return retryOnFailure;
	}

	public Integer getMaxRetries() {
		return maxRetries;
	}

	public Integer getRetryDelay() {
		return retryDelay;
	}

    public Boolean getIsLoggingRequest() {
        return isLoggingRequest;
    }

    public Boolean getIsLoggingResponse() {
        return isLoggingResponse;
    }

    public void setIsLoggingRequest(Boolean isLoggingRequest) {
        this.isLoggingRequest = isLoggingRequest;
    }

    public void setIsLoggingResponse(Boolean isLoggingResponse) {
        this.isLoggingResponse = isLoggingResponse;
    }

	public HTTPCalloutConfiguration__mdt getCalloutMetadata() {
		return calloutMetadata;
	}

	public HTTPCalloutEnvironment__mdt getEnvironmentOverride() {
		return environmentOverride;
	}

	public Set<Integer> getSuccessCodes() {
		return successCodes;
	}

    public String getHeaderParameter(String key) {
        return headerParametersMap.get(key);
    }

    public Map<String, String> getHeaderParameters() {
        return headerParametersMap;
    }

    public void setHeaderParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            headerParametersMap.put(key, value);
        }
    }

    public void removeHeaderParameter(String key) {
        headerParametersMap.remove(key);
    }

    public String getURLParameter(String key) {
        return urlParametersMap.get(key);
    }

    public Map<String, String> getURLParameters() {
        return urlParametersMap;
    }

    public void setURLParameter(String key, String value) {
        if(String.isNotEmpty(key) && String.isNotEmpty(value)) {
            urlParametersMap.put(key, value);
        } else if(String.isNotEmpty(key)) {
            urlParametersMap.put(key, value);
        }
    }

    public void removeURLParameter(String key) {
        urlParametersMap.remove(key);
    }
    /*
    * Getters and Setters - End
    */

    /*
    * Constructor
    */
    public HTTPCalloutService() {
        initialize();
    }

    /*
    * Constructor with Custom Metadata and automatic environment detection
    */
    public HTTPCalloutService(String customMetadataName) {
        try {
            calloutMetadata = [
                SELECT Method__c, URLParameters__c, HeaderParameters__c, Endpoint__c,
                Body__c, Timeout__c, CertificateName__c, IsCompressed__c,
                NamedCredential__c, IsActive__c, RetryOnFailure__c, MaxRetries__c, RetryDelay__c,
                LogRequest__c, LogResponse__c, SuccessCodes__c,
                (SELECT EndpointOverride__c, NamedCredentialOverride__c, IsActive__c,
                 TimeoutOverride__c, HeaderParametersOverride__c, URLParametersOverride__c,
                 BodyOverride__c, CertificateNameOverride__c, EnvironmentName__c,
                 SalesforceDomain__c, EnvironmentDescriptor__c
                 FROM HTTPCalloutEnvironments__r
                 WHERE IsActive__c = true)
                FROM HTTPCalloutConfiguration__mdt
                WHERE DeveloperName =:customMetadataName
                AND IsActive__c = true
            ];
        } catch (QueryException e) {
            throw new HTTPCalloutFrameworkException(
                HTTPCalloutFrameworkException.CUSTOM_METADATA_NOT_FOUND
            );
        }
        if(calloutMetadata.HTTPCalloutEnvironments__r != null && !calloutMetadata.HTTPCalloutEnvironments__r.isEmpty()) {
            this.environmentOverride = getEnvironmentOverrideFromCollection();
        }
        initialize();
    }

    /*
    * Get environment override from the collection retrieved in the parent query
    * Validates that only one active environment exists per configuration
    */
    private HTTPCalloutEnvironment__mdt getEnvironmentOverrideFromCollection() {
        if(calloutMetadata.HTTPCalloutEnvironments__r == null || calloutMetadata.HTTPCalloutEnvironments__r.isEmpty()) {
            return null;
        }
        
        List<HTTPCalloutEnvironment__mdt> envOverrides = calloutMetadata.HTTPCalloutEnvironments__r;
        // Validate that only one active environment exists
        if(envOverrides.size() > 1) {
            throw new HTTPCalloutFrameworkException(HTTPCalloutFrameworkException.MULTIPLE_ACTIVE_ENVIRONMENTS);
        }

        return envOverrides.get(0);
    }

    /*
    * Initialization of class variables
    */
    private void initialize() {
        urlParametersMap = new Map<String, String>();
        headerParametersMap = new Map<String, String>();
        successCodes = new Set<Integer>();
        if(calloutMetadata != null) {
            // Initialize from metadata
            endpointURL = calloutMetadata.Endpoint__c;
            requestMethod = calloutMetadata.Method__c;
            requestBody = calloutMetadata.Body__c;
            requestTimeout = calloutMetadata.Timeout__c != null ? Integer.valueOf(calloutMetadata.Timeout__c) : null;
            isCompressedRequest = calloutMetadata.IsCompressed__c;
            requestCertificate = calloutMetadata.CertificateName__c;
            namedCredential = calloutMetadata.NamedCredential__c;
            isActive = calloutMetadata.IsActive__c;
            retryOnFailure = calloutMetadata.RetryOnFailure__c;
            maxRetries = calloutMetadata.MaxRetries__c != null ? Integer.valueOf(calloutMetadata.MaxRetries__c) : 3;
            retryDelay = calloutMetadata.RetryDelay__c != null ? Integer.valueOf(calloutMetadata.RetryDelay__c) : 1000;
            successCodes = parseSuccessCodes(calloutMetadata.SuccessCodes__c);
            
            setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, calloutMetadata.URLParameters__c);
            setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, calloutMetadata.HeaderParameters__c);
            
            // Apply environment overrides if present
            if(environmentOverride != null) {
                applyEnvironmentOverrides();
            }
        }
    }

    /*
    * Parse comma-separated success codes
    */
    private Set<Integer> parseSuccessCodes(String successCodesString) {
        Set<Integer> successCodesSet = new Set<Integer>(); 
        if(String.isNotEmpty(successCodesString)) {
            List<String> codeStrings = successCodesString.split(',');
            for(String codeStr : codeStrings) {
                String trimmedCode = codeStr.trim();
                if(String.isNotBlank(trimmedCode)) {
                    try {
                        Integer code = Integer.valueOf(trimmedCode);
                        successCodesSet.add(code);
                    } catch (TypeException e) {
                        // Skip invalid codes
                    }
                }
            }
        }
        return successCodesSet;
    }

    /*
    * Check if the HTTP response status code indicates success
    */
    public Boolean isSuccessful(HTTPResponse response) {
        if(response == null) {
            return false;
        }
        return successCodes.contains(response.getStatusCode());
    }

    /*
    * Apply environment-specific overrides
    */
    private void applyEnvironmentOverrides() {
        if(String.isNotEmpty(environmentOverride.EndpointOverride__c)) {
            endpointURL = environmentOverride.EndpointOverride__c;
        }
        if(String.isNotEmpty(environmentOverride.NamedCredentialOverride__c)) {
            namedCredential = environmentOverride.NamedCredentialOverride__c;
        }
        if(environmentOverride.TimeoutOverride__c != null) {
            requestTimeout = Integer.valueOf(environmentOverride.TimeoutOverride__c);
        }
        if(String.isNotEmpty(environmentOverride.BodyOverride__c)) {
            requestBody = environmentOverride.BodyOverride__c;
        }
        if(String.isNotEmpty(environmentOverride.CertificateNameOverride__c)) {
            requestCertificate = environmentOverride.CertificateNameOverride__c;
        }
        if(String.isNotEmpty(environmentOverride.HeaderParametersOverride__c)) {
            setUrlOrHeaderParameters(TYPE_HEADER_PARAMETERS, environmentOverride.HeaderParametersOverride__c);
        }
        if(String.isNotEmpty(environmentOverride.URLParametersOverride__c)) {
            setUrlOrHeaderParameters(TYPE_URL_PARAMETERS, environmentOverride.URLParametersOverride__c);
        }
    }

    /*
    * This method is used to set URL or Header parameters from Custom Metadata
    */
    private void setUrlOrHeaderParameters(String parameterType, String parameterInfo) {
        if(String.isNotEmpty(parameterInfo)) {
            Map<String, String> parametersMap = new Map<String, String>();
            List<String> parameters = parameterInfo.split('\n');
            for(String urlParam : parameters) {
                List<String> keyValuePair = urlParam.trim().split(':');
                if(!keyValuePair.isEmpty()) {
                    if(keyValuePair.size() == 2) {
                        if(String.isNotEmpty(keyValuePair[0]) && String.isNotEmpty(keyValuePair[1])) {
                            parametersMap.put(keyValuePair[0], keyValuePair[1]);
                        }
                    } else if(
                        (keyValuePair.size() == 1) &&
                        (parameterType != TYPE_HEADER_PARAMETERS)
                    ) {
                        if(String.isNotEmpty(keyValuePair[0])) {
                            parametersMap.put(keyValuePair[0], '');
                        }
                    }
                }
            }
            if(parameterType == TYPE_URL_PARAMETERS) {
                urlParametersMap.putAll(parametersMap);
            } else if(parameterType == TYPE_HEADER_PARAMETERS) {
                headerParametersMap.putAll(parametersMap);
            }
        }
    }

    /*
    * This method is used to form HTTP Request
    */
    public void formHTTPRequest() {
        request = new HTTPRequest();
        addHeaderParameters();
        
        String baseEndpoint;

        // prioritize named credential if available
        if(String.isNotEmpty(namedCredential)) {
            baseEndpoint = 'callout:' + namedCredential;
        } else {
            baseEndpoint = endpointURL.substringBefore('?');
        }

        if (String.isNotEmpty(baseEndpoint)) {
            appendURLParameters();
            request.setEndpoint(baseEndpoint);
        }
        
        if(String.isNotEmpty(requestMethod)) {
            request.setMethod(requestMethod);
        }
        if(String.isNotEmpty(requestBody)) {
            request.setBody(requestBody);
        } else if((requestBodyAsBlob != null) &&  String.isNotEmpty(requestBodyAsBlob.toString())) {
            request.setBodyAsBlob(requestBodyAsBlob);
        } else if((requestBodyAsDocument != null) && String.isNotEmpty(requestBodyAsDocument.toXmlString())) {
            request.setBodyDocument(requestBodyAsDocument);
        }
        if(requestTimeout!=null) {
            request.setTimeout(requestTimeout);
        }
        if(String.isNotEmpty(requestCertificate)) {
            request.setClientCertificateName(requestCertificate);
        }
        if(isCompressedRequest!=null) {
            request.setCompressed(isCompressedRequest);
        }
    }

    /*
    * This method is used to set Header parameters using headerParametersMap
    */
    private void addHeaderParameters() {
        for(String key : headerParametersMap.keySet()) {
            request.setHeader(key, headerParametersMap.get(key));
        }
    }


    /*
    * This method is used to append the URL parameters at the end of URL
    */
    private void appendURLParameters() {
        Set<String> urlParamKeys = urlParametersMap.keySet();
        if(!urlParamKeys.isEmpty()) {
            endpointURL += '?';
            for(String urlParamKey : urlParamKeys) {
                endpointURL += urlParamKey + '=' + urlParametersMap.get(urlParamKey) + '&';
            }
            endpointURL = endpointURL.substringBeforeLast('&');
        }
    }

    /*
    * This method forms and returns the HTTP Request without sending (for debugging purposes)
    */
    public HTTPRequest getRequest() {
        formHTTPRequest();
        if(isLoggingRequest) {
            // TODO: Replace with Triton Logging
            System.debug('Request: ' + request);
        }
        return request;
    }

    /*
    * This method is used to send HTTP Request with retry logic
    */
    private HTTPResponse sendRequest() {
        HTTPResponse response = new HTTPResponse();
        Integer attempts = 0;
        Integer maxAttempts = maxRetries ?? 0 + 1; // maxRetries is number of retries, so total attempts = retries + 1
        while(attempts < maxAttempts) {
            formHTTPRequest();
            Http http = new Http();
            try {
                response = http.send(request);
            } catch (Exception ex) {
                // TODO: Replace with Triton Logging
                System.debug('Error: ' + ex.getMessage());
                throw new HTTPCalloutFrameworkException(ex.getMessage());
            }
            if(isLoggingResponse) {
                // TODO: Replace with Triton Logging
                System.debug('Response: ' + response);
            }
            // If successful based on configured success codes, return response
            if(isSuccessful(response)) {
                return response;
            }
            
            attempts++;
            
            // If not the last attempt, wait before retrying
            if(retryDelay != null && retryDelay > 0) {
                // TODO: Replace with Triton Logging
                System.debug('Waiting for ' + retryDelay + ' milliseconds before retrying...');
                Long timeDiff = 0;
                DateTime firstTime = System.now();
                do {
                    timeDiff = System.now().getTime() - firstTime.getTime();
                }
                while(timeDiff <= retryDelay);
            }
        }
        
        return response;
    }
}