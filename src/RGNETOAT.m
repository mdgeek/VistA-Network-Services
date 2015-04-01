RGNETOAT ;RI/CBMI/DKM - OAuth2 Token Endpoint ;01-Apr-2015 02:02;DKM
 ;;1.0;NETWORK SERVICES;;14-March-2014;Build 1
 ;=================================================================
 ; POST method
MPOST N GT,POST
 D PARSEBD^RGNETWWW(.POST)
 S GT=$G(POST("grant_type",1,1))
 G GTAC:GT="authorization_code",GTRT:GT="refresh_token"
 D SETSTAT^RGNETWWW(501)
 Q
 ; Grant type = authorization_code
GTAC N CLIENT,AUTH,REDIRECT,SECRET,ATKN,RTKN
 S CLIENT=$G(POST("client_id",1,1)),AUTH=$G(POST("code",1,1))
 S REDIRECT=$G(POST("redirect_uri",1,1)),SECRET=$G(POST("client_secret",1,1))
 I '$L(CLIENT)!'$L(AUTH)!'$L(REDIRECT)!'$L(SECRET) D SETSTAT^RGNETWWW(400) Q
 D GETAUTH^RGNETOAA(.AUTH)
 I $D(AUTH)'>1 D SETSTAT^RGNETWWW(404) Q
 I AUTH("secret")'=SECRET D SETSTAT^RGNETWWW(403)
 S RTKN=$$NEWRTKN(.CLIENT,AUTH("user"),AUTH("scope"))
 I '$L(RTKN) D SETSTAT^RGNETWWW(403) Q
 S ATKN=$$REFATKN(.RTKN)
 D BLDRSP^RGNETOA(.ATKN,.RTKN)
 Q
 ; Grant type = refresh_token
GTRT N RTKN,ATKN
 S RTKN=$G(POST("refresh_token",1,1))
 S ATKN=$$REFTKN(RTKN)
 I '$L(ATKN) D SETSTAT^RGNETWWW(404) Q
 D BLDRSP^RGNETOA(.ATKN)
 Q
 ; Fetches an access token from the data store
GETATKN(ATKN) ;
 D GETOBJ^RGNETOA(.ATKN,"ATKN")
 Q
 ; Fetches a refresh token from the data store
GETRTKN(RTKN) ;
 D GETOBJ^RGNETOA(.RTKN,"RTKN")
 Q
 ; Writes an access token to the data store
SETATKN(ATKN) 
 D SETOBJ^RGNETOA(.ATKN,"ATKN")
 Q
 ; Writes a refresh token to the data store
SETRTKN(RTKN) ;
 D SETOBJ^RGNETOA(.RTKN,"RTKN")
 Q
 ; Generate an access token
NEWATKN(CLIENT,USER,SCOPE) ;
 Q:'$$GETCLNT^RGNETOA(.CLIENT) ""
 N ATKN,EXP
 S ATKN=$$UUID^RGUT,EXP=$$FMADD^XLFDT($$NOW^XLFDT,0,0,0,CLIENT("lifespan"))
 S ATKN("user")=USER,ATKN("expiry")=EXP,ATKN("client")=CLIENT
 S ATKN("lifespan")=CLIENT("lifespan"),ATKN("scope")=SCOPE
 D SETATKN(.ATKN)
 Q ATKN
 ; Generate a refresh token
NEWRTKN(CLIENT,USER,SCOPE) ;
 N RTKN
 S RTKN=$$UUID^RGUT,RTKN("client")=CLIENT,RTKN("user")=USER
 S RTKN("scope")=SCOPE,RTKN("access_token")=""
 D SETRTKN(.RTKN)
 Q RTKN
 ; Revoke access token
REVATKN(ATKN) ;
 D DELOBJ^RGNETOA(.ATKN,"ATKN")
 Q
 ; Refresh access token
REFATKN(RTKN) ;
 N ATKN,CLIENT
 D GETRTKN(.RTKN)
 I $D(RTKN)>1 D
 .S ATKN=RTKN("access_token"),CLIENT=RTKN("client")
 .D:$L(ATKN) REVATKN(ATKN)
 .S ATKN=$$NEWATKN(.CLIENT,RTKN("user"),RTKN("scope"))
 .S RTKN("access_token")=ATKN
 .D SETRTKN(.RTKN)
 Q $G(ATKN)
 ; Returns the user DUZ if access token is valid
 ; Revokes any expired tokens
ISVALID(ATKN) ;
 N EXP,VALID
 D GETATKN(.ATKN)
 S EXP=$G(ATKN("expiry")),VALID=$S('EXP:0,1:$$NOW^XLFDT>EXP)
 I EXP,'VALID D REVATKN(ATKN)
 Q $S(VALID:ATKN("user"),1:0)
