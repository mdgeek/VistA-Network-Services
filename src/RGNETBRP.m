RGNETBRP ;RI/CBMI/DKM - NETSERV RPC Broker Privileged RPCs;16-Jun-2015 21:51;DKM
 ;;1.0;NETWORK SERVICES;;01-Apr-2015;Build 133
 ;=================================================================
 ; RPC: User authentication
 ; AID = Application ID
 ; WID = Workstation ID
 ; SID = NT Security ID
 ; AVC = AV Code
 ; WIP = Workstation IP address
 ; DIV = Login division (optional)
 ; Returns:
 ;  DATA(0)=Status code^Status text
 ;  where Status code is one of:
 ;   0 = success                 (Params=UID^net name^div name^DUZ)
 ;   1 = success, verify expired (Params=same as success)
 ;   2 = logins inhibited        (Params=null)
 ;   3 = locked                  (Params=null)
 ;   4 = authentication failure  (Params=server^volume^UCI^port)
 ;   5 = other error             (Params=null)
 ;  DATA(1)=Params
 ;  DATA(2,n)=Greeting message
AUTH(DATA,AID,WID,SID,AVC,WIP,DIV) ;
 N XOPT,XUT,XUTEXT,XOPT,XUEON,XUEOFF,XUTT,XUDEV,XUSER,XUNOW,X
 K DUZ,DATA,^TMP($J),^UTILITY($J)
 D SET1^XUS(0)
 S (DUZ,XUT)=0,DUZ(0)="",XUDEV=0,DATA(0)=4,DATA(1)=""
 S AID(0)=$$OPTLKP^RGNETBUT(.AID),WID=$$ID(.WID),SID=$G(SID),WIP=$G(WIP)
 I '$L(AID(0)),$$CHK(18,5,.AID) Q
 S X=$$OPTMSG^RGNETBUT(AID(0))
 I $L(X),$$CHK(19,2,X) Q
 I '$L($G(AVC)) S DUZ=+$$AUTOLOG(SID),RGXUT=0
 E  D
 .I $E(AVC,1,2)="~1" S DUZ=$$CHKASH^XUSRB4(AVC)
 .S:'DUZ DUZ=$$CHECKAV^XUS($$DECRYP^XUSRB1(AVC)),RGXUT=$G(RGXUT)+1
 .I 'DUZ,RGXUT>$P(XOPT,U,2),$$CHK(-7,3) Q
 .I 'DUZ,$$CHK(-4,4)
 I DUZ D
 .S DATA(0)=0,XUNOW=$$NOW^XLFDT,X=$$OPTCHK^RGNETBUT(AID)
 .Q:$$CHK(+X,2,$P(X,U,2),$P(X,U,3),$P(X,U,4))
 .Q:$$CHK(-$$INHIBIT^XUSRB,2)
 .I XUT>$P(XOPT,U,2),$$CHK(-7,3) Q
 .D USER^XUS(DUZ)
 .Q:$$CHK(-$$UVALID^XUS(),4)
 .Q:$$CHK(-$$USER^XUS1A,4)
 .F X=0:0 S X=$O(XUTEXT(X)) Q:'X  S DATA(2,X)=$E(XUTEXT(X),2,9999)
 .D DUZ^XUS1A,SAVE^XUS1,LOG^XUS1,ABT^XQ12
 .I $$VCVALID^XUSRB,$$CHK(-12,1)
 .I $G(RGNETB("UID")) D
 ..N UID
 ..S UID=RGNETB("UID"),RGNETB("UID")=0
 ..I '$D(^XTMP("RGNETB",UID)),$$CHK(25,5,UID) Q
 ..I $$SESSION^RGNETBUT(UID,"DUZ")'=DUZ,$$CHK(27,4,UID) Q
 ..I $$ISACTIVE^RGNETBUT(UID,1,60),$$CHK(26,4,UID) Q
 ..S RGNETB("UID")=UID
 ..D RESVAR^RGNETBUT,SETVAR^RGNETBUT("JOB",$J)
 ..D BRDCAST^RGNETBEV("LOGIN",$$SESSION^RGNETBUT)
 .E  D
 ..S RGNETB("UID")=$$UID^RGNETBUT
 ..D:$G(DIV) DIVSET(,DIV)
 ..D RESET(1)
 .S DATA(1)=RGNETB("UID")_U_$G(^XMB("NETNAME"))_U_$$GET1^DIQ(4,DUZ(2),".01")_U_DUZ
 .S:AID(0) ^XUTL("XQ",$J,1)=AID(0)_U_$G(^DIC(19,AID(0),0)),^("T")=1
 .D AUTOSET(SID),STSAVE^RGNETTCP(1)
 I +DATA(0)=4 D
 .S DATA(1)=$P(XUENV,U,3)_U_$P(XUVOL,U)_U_XUCI_U_+RGCFG("port")
 .D:$G(RGNETB("LEGACY")) INTRO^XUS1A("DATA(2)")
 Q
 ; Transform ID values
ID(ID) Q $E($TR($G(ID),U,"~"),1,40)
 ; RPC: Change verify code
CVC(DATA,OLD,NEW) ;
 S DATA=$$BRCVC^XUS2($$DECRYP^XUSRB1(OLD),$$DECRYP^XUSRB1(NEW))
 S:'DATA DATA="0^Your verify code has been changed."
 Q
 ; RPC: Get division list and default
DIVGET(DATA) ;
 N DIV,DEF,PRI,GBL,USR
 S (DIV,PRI)=0,USR=+$G(DUZ),GBL=$S(USR:$NA(^VA(200,USR,2)),1:$NA(^DG(40.8,"AD")))
 S DEF=+$S(USR:$G(DUZ(2)),1:$P($G(^XTV(8989.3,1,"XUS")),U,17))
 F  S DIV=$O(@GBL@(DIV)) Q:'DIV  S:USR PRI=$P(^(DIV,0),U,2) D
 .S DATA(DIV)=$$DIVINFO(DIV)
 .S:PRI DEF=DIV
 S:'DEF DEF=+$O(DATA(0))
 I DEF,'$D(DATA(DEF)) S DATA(DEF)=$$DIVINFO(DEF)
 S DATA(0)=DEF
 D:DEF DIVSET(,DIV)
 Q
 ; Return division info as
 ; IEN ^ NAME ^ STATION # ^ SHORT NAME
DIVINFO(DIV) ;
 N X0,X99
 S X0=$G(^DIC(4,DIV,0)),X99=$G(^(99))
 Q DIV_U_$P(X0,U)_U_$P(X99,U)_U_$P(X0,U,5)
 ; RPC: Set division
DIVSET(DATA,DIV) ;
 S DUZ(2)=+DIV,DATA=1
 D SETVAR^RGNETBUT("DUZ2",DUZ(2))
 D SETVAR^RGNETBUT("DUZ(2)",DUZ(2),-1)
 Q
 ; RPC: Get dialog text
DIALOG(DATA,DLG,P1,P2,P3) ;
 D GETDLG^RGNETBUT(DLG,.DATA,.P1,.P2,.P3)
 Q
 ; RPC: Reset session
RESET(LOGIN) ;
 Q:'$G(RGNETB("UID"))
 D STOPALL^RGNETBAS,UNSUBALL^RGNETBEV
 S LOGIN=+$G(LOGIN)
 N DUZ2
 S DUZ2=$$GETVAR^RGNETBUT("DUZ2")
 I 'LOGIN D
 .D CLOSE^RGNETBLG($$GETVAR^RGNETBUT("ALOG"_$S(DUZ2:":"_DUZ2,1:"")))
 .S IO("IP")=$$GETVAR^RGNETBUT("WIP")
 .D BRDCAST^RGNETBEV("LOGOUT",$$SESSION^RGNETBUT)
 .K ^XTMP("RGNETB",RGNETB("UID"))
 .L -^XTMP("RGNETB",RGNETB("UID"),0)
 .D BYE^XUSCLEAN
 E  D
 .N ENV,X,Y,V
 .K ^XTMP("RGNETB",RGNETB("UID"))
 .F ENV=0:1 S X=$P($T(ENVDATA+ENV),";;",2) Q:'$L(X)  D
 ..S V=$P(X,";",2),@("Y="_V)
 ..D SETVAR^RGNETBUT($P(X,";"),Y)
 ..D:$P(X,";",3) SETVAR^RGNETBUT(V,Y,-1)
 .D BRDCAST^RGNETBEV("LOGIN",$$SESSION^RGNETBUT)
 .S IO("IP")=$$GETVAR^RGNETBUT("WIP")
 .I $$ISACTIVE^RGNETBLG
 .D LOG^XUS1                                                           ;creates handle with client agent
 Q
 ; Environment data to save
 ;;Name;Value;Local
ENVDATA ;;DUZ;DUZ
 ;;DUZ0;DUZ(0);1
 ;;DUZ2;DUZ(2);1
 ;;USER;$P($G(^VA(200,DUZ,0)),U)
 ;;RDEV;$$RESDEV^RGNETBUT
 ;;LDT;$H
 ;;JOB;$J
 ;;AID;AID
 ;;AID0;AID(0)
 ;;WID;WID
 ;;WIP;WIP
 ;;UID;RGNETB("UID")
 ;;
 ; Check error code
CHK(ERR,RTN,P1,P2,P3) ;
 I ERR S DATA(0)=RTN_U_$S(ERR<0:$$TXT^XUS3(-ERR),1:$$GETDLG^RGNETBUT(ERR,,.P1,.P2,.P3)) S:RTN>1 DUZ=0
 Q ERR
 ; Attempt autoauthenticate using SID
 ; Returns DUZ if SID has been authenticated, 0 if prohibited from
 ; being authenticated, or null if never been authenticated.
AUTOLOG(SID) ;
 S SID=$S($L($G(SID))<3:"",1:$$DECRYP^XUSRB1(SID))
 Q:$E(SID,1,9)'="S-1-5-21-" 0
 S SID=$E(SID,10,999)
 Q:SID<1000 0
 N X
 S X=$$FIND1^DIC(996.513,"","QX",SID)
 Q $S(X:+$P($G(^RGNET(996.513,X,0)),U,2),1:"")
 ; Cache NT authentication information
AUTOSET(SID) ;
 Q:$$AUTOLOG(.SID)'=""
 N FLD
 S FLD(996.513,"+1,",.01)=SID
 S FLD(996.513,"+1,",1)=DUZ
 S FLD(996.513,"+1,",2)=$$NOW^XLFDT
 D UPDATE^DIE("","FLD")
 Q
 ; RPC: Get list of active RPCs
GETRPCS(DATA) ;
 N X
 D LIST^DIC(8994,,".01","Q",,,,,"I ""03""[$P(^(0),U,6)",,.DATA)
 S X=""
 F  S X=$O(@DATA@(X)) Q:'$L(X)  K:X'="ID" @DATA@(X)
 Q
 ; RPC: Can RPC be executed in current context
CANRUN(DATA,RPC) ;
 S DATA=$$CANRUN^RGNETBAC($$FIND1^DIC(8994,,"QX",RPC),RGNETB("CTX"))
 Q
 ; RPC: Retrieve list of active sessions
GETSESSN(DATA,VAR,AID) ;
 N X,Z,C
 S DATA=$$TMPGBL
 F C=1:1 Q:'$$NXTUID^RGNETBUT(.X,,.AID)  S @DATA@(C)=$$SESSION^RGNETBUT(X,.VAR)
 Q
 ; RPC: Get stored variable(s)
GETVAR(DATA,LIST,NMSP) ;
 N CNT
 S:$L($G(LIST)) LIST(-99)=LIST
 S LIST="",CNT=0
 S:0[$G(NMSP) NMSP="@"
 F  S LIST=$O(LIST(LIST)) Q:'$L(LIST)  D
 .S CNT=CNT+1,DATA(CNT)=LIST(LIST)_"="_$$GETVAR^RGNETBUT(LIST(LIST),,NMSP)
 Q
 ; RPC: Set stored variable(s)
SETVAR(DATA,LIST,NMSP,RESET) ;
 S:$L($G(LIST)) LIST(-99)=LIST
 S LIST="",DATA=0
 S:0[$G(NMSP) NMSP="@"
 D:$G(RESET) CLRVAR^RGNETBUT(NMSP)
 F  S LIST=$O(LIST(LIST)) Q:'$L(LIST)  D
 .S DATA=DATA+1
 .D SETVAR^RGNETBUT($P(LIST(LIST),"="),$P(LIST(LIST),"=",2,9999),NMSP)
 Q
 ; RPC: Get requested session info
 ; TYPE = 0=subscriptions, 1=local vars, 2=session vars, 3=locks, 4=pending async RPCs
 ; UID  = Session ID (defaults to current session)
GETINFO(DATA,TYPE,UID) ;
 S UID=$G(UID,$G(RGNETB("UID")))
 I TYPE=0 D  Q
 .N EV,CN
 .S EV="",CN=0
 .F  S EV=$O(^XTMP("RGNETB",UID,"S",EV)) Q:'$L(EV)  D
 ..S CN=CN+1,@DATA@(CN)=EV
 I TYPE=1 D  Q
 .D CAPTURE^RGUTHFS("ZWRITE  N X F X=""$ET"",""$EC"",""$ES"",""$J"",""$ZE"",""$ZT"" W !,X,""="",@X",DATA,99999)
 I TYPE=2 D  Q
 .N NS,VN,VL,CN
 .S NS="",CN=0
 .F  S NS=$O(^XTMP("RGNETB",UID,"V",NS)),VN="" Q:'$L(NS)  D
 ..F  S VN=$O(^XTMP("RGNETB",UID,"V",NS,VN)) Q:'$L(VN)  S VL=$G(^(VN)) D
 ...S CN=CN+1,@DATA@(CN)=$S(NS=0:"<default>",NS=-1:"<mapped>",1:NS)_U_VN_U_VL
 I TYPE=3 D  Q
 .N GBL,CN,VL
 .S GBL="",CN=0
 .F  S GBL=$O(^XTMP("RGNETB",UID,"L",GBL)) Q:'$L(GBL)  S VL=$G(^(GBL)) D
 ..S CN=CN+1,@DATA@(CN)=$TR(GBL,U,"~")_U_VL
 I TYPE=4 D  Q
 .N TSK,CN
 .S (TSK,CN)=0
 .F  S TSK=$O(^XTMP("RGNETB",UID,"T",TSK)) Q:'TSK  D
 ..S CN=CN+1,@DATA@(CN)=TSK_U_$G(^%ZTSK(TSK,.03),"Unknown")
 S @DATA@(1)="Unknown request type: "_TYPE
 Q
 ; Lock/unlock global reference
 ; GBL  = Global reference
 ; OPR  = Operation to perform:
 ;        >=0: Value is timeout for lock operation.  Returns success.
 ;         <0: Returns # of active locks for node.
 ;    missing: Performs unlock operation.  Returns success.
 ; DATA = Returns status according to value of OPR.
LOCK(DATA,GBL,OPR) ;
 N LCK
 S LCK=$D(OPR),OPR=+$G(OPR),GBL=$NA(@GBL)
 I OPR<0 S DATA=$$LOCKCNT(GBL)
 E  I LCK D
 .L +@GBL:OPR
 .S DATA=$T
 .I DATA,$$LOCKCNT(GBL,1)
 E  D
 .S DATA=''$$LOCKCNT(GBL,-1)
 .L:DATA -@GBL
 Q
 ; RPC: Restore locks (after reconnect)
 ; Data returns list of locks that could not be restored.
LOCKRES(DATA) ;
 N GBL,CNT,X
 S GBL="",X=0
 F  S GBL=$O(^XTMP("RGNETB",RGNETB("UID"),"L",GBL)) Q:'$L(GBL)  S CNT=+$G(^(GBL))  D
 .F CNT=CNT:-1:1 L +@GBL:1 E  D  Q
 ..S X=X+1,@DATA@(X)=GBL
 ..K ^XTMP("RGNETB",RGNETB("UID"),"L",GBL)
 Q
 ; Return lock count.  Optionally increment/decrement afterwards.
 ; Note use of naked reference.
LOCKCNT(GBL,INC) ;
 N X,Y
 S X=+$G(^XTMP("RGNETB",RGNETB("UID"),"L",GBL)),Y=X+$G(INC)            ; Sets naked reference
 I Y>0 S ^(GBL)=Y
 E  K ^(GBL)
 Q X
 ; RPC: Process an HTTP request via broker call
HTTPREQ(DATA,REQUEST) ;
 S:$D(REQUEST)=1 REQUEST(1)=REQUEST
 S DATA=$$ENTRYARY^RGNETWWW(.REQUEST)
 Q
 ; Get temp global reference
TMPGBL(X) ;
 K ^TMP("RGNETBTMP"_$G(X),$J) Q $NA(^($J))
