//
//  KinveyHTTPStatusCodes.h
//  KinveyKit
//
//  Copyright (c) 2008-2015, Kinvey, Inc. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

#ifndef KinveyKit_KinveyHTTPStatusCodes_h
#define KinveyKit_KinveyHTTPStatusCodes_h


// This is a partial collection of status codes
// it is not complete, and is based on a list from MSDN
#define KCS_HTTP_STATUS_CONTINUE 100
#define KCS_HTTP_STATUS_SWITCH_PROTOCOLS 101
#define KCS_HTTP_STATUS_OK 200
#define KCS_HTTP_STATUS_CREATED 201
#define KCS_HTTP_STATUS_ACCEPTED 202
#define KCS_HTTP_STATUS_PARTIAL 203
#define KCS_HTTP_STATUS_NO_CONTENT 204
#define KCS_HTTP_STATUS_RESET_CONTENT 205
#define KCS_HTTP_STATUS_PARTIAL_CONTENT 206
#define KCS_HTTP_STATUS_AMBIGUOUS 300
#define KCS_HTTP_STATUS_MOVED 301
#define KCS_HTTP_STATUS_REDIRECT 302
#define KCS_HTTP_STATUS_REDIRECT_METHOD 303
#define KCS_HTTP_STATUS_NOT_MODIFIED 304
#define KCS_HTTP_STATUS_USE_PROXY 305
#define KCS_HTTP_STATUS_REDIRECT_KEEP_VERB 307
#define KCS_HTTP_STATUS_BAD_REQUEST 400
#define KCS_HTTP_STATUS_DENIED 401
#define KCS_HTTP_STATUS_FORBIDDEN 403
#define KCS_HTTP_STATUS_NOT_FOUND 404
#define KCS_HTTP_STATUS_BAD_METHOD 405
#define KCS_HTTP_STATUS_NONE_ACCEPTABLE 406
#define KCS_HTTP_STATUS_PROXY_AUTH_REQ 407
#define KCS_HTTP_STATUS_REQUEST_TIMEOUT 408
#define KCS_HTTP_STATUS_CONFLICT 409
#define KCS_HTTP_STATUS_GONE 410
#define KCS_HTTP_STATUS_LENGTH_REQUIRED 411
#define KCS_HTTP_STATUS_PRECOND_FAILED 412
#define KCS_HTTP_STATUS_REQUEST_TOO_LARGE 413
#define KCS_HTTP_STATUS_URI_TOO_LONG 414
#define KCS_HTTP_STATUS_UNSUPPORTED_MEDIA 415
#define KCS_HTTP_STATUS_RETRY_WITH 449
#define KCS_HTTP_STATUS_SERVER_ERROR 500
#define KCS_HTTP_STATUS_NOT_SUPPORTED 501
#define KCS_HTTP_STATUS_BAD_GATEWAY 502
#define KCS_HTTP_STATUS_SERVICE_UNAVAIL 503
#define KCS_HTTP_STATUS_GATEWAY_TIMEOUT 504
#define KCS_HTTP_STATUS_VERSION_NOT_SUP 505 
#define KCS_HTTP_STATUS_BACKEND_LOGIC_ERROR 550


#endif
