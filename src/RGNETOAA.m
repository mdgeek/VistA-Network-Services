RGNETOAA ;RI/CBMI/DKM - OAuth2 Authorization Endpoint ;17-Apr-2015 12:34;DKM
 ;;1.0;NETWORK SERVICES;;14-March-2014;Build 1
 ;=================================================================
 ; GET method handler
MGET N RT,GT,FLOW,CLIENT
 S RT=$$GETPARAM^RGNETWWW("response_type")
 S GT=$$GETPARAM^RGNETWWW("grant_type")
 S CLIENT=$$GETPARAM^RGNETWWW("client_id")
 I '$$GETCLNT^RGNETOA(.CLIENT) D SETSTAT^RGNETWWW(404) Q
 S FLOW=$S(RT="code":"W",RT="token":"U",GT="password":"P",GT="client_credentials":"C",1:"?")
 I FLOW'=CLIENT("flow") D SETSTAT^RGNETWWW(403) Q
 D @("AUTH"_FLOW)
 Q
 ; Web server flow: authorization code grant
AUTHW N CODE,LOCATION,STATE
 Q:'$$VALIDRDU
 Q:'$$AUTH^RGNETWWW(1)
 D SETSTAT^RGNETWWW(302)
 S CODE=$$NEWAUTH(.CLIENT,DUZ)
 S STATE=$$GETPARAM^RGNETWWW("state")
 S LOCATION=CLIENT("redirect_uri")_"?code="_CODE
 S:$L(STATE) LOCATION=LOCATION_"&state="_STATE
 D ADDHDR^RGNETWWW("Location: "_LOCATION)
 Q
 ; User-agent flow: implicit grant
AUTHU N ATKN
 Q:'$$VALIDRDU
 Q:'$$AUTH^RGNETWWW(1)
 S ATKN=$$NEWATKN^RGNETOAT(.CLIENT,DUZ,$$GETPARAM^RGNETWWW("scope"))
 D BLDRSP^RGNETOA(ATKN)
 Q
 ; Username and password flow
AUTHP D SETSTAT^RGNETWWW(501)
 Q
 ; Client credentials flow: access token
AUTHC D SETSTAT^RGNETWWW(501)
 Q
 ; Generate a new authorization code
NEWAUTH(CLIENT,USER) ;
 N AUTH
 S AUTH=$$UUID^RGUT,AUTH("user")=USER,AUTH("client")=CLIENT
 D SETOBJ^RGNETOA(.AUTH,"AUTH")
 Q AUTH
 ; Fetches (and removes) an authorization from the data store
GETAUTH(AUTH) ;
 D GETOBJ^RGNETOA(.AUTH,"AUTH",1)
 Q
 ; Validates the redirect uri
VALIDRDU() ;
 I CLIENT("redirect_uri")'=$$GETPARAM^RGNETWWW("redirect_uri") D SETSTAT^RGNETWWW(404) Q 0
 Q 1
