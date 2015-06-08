RGNETBAC ;RI/CBMI/DKM - NETSERV RPC Broker Actions;20-May-2015 22:15;AA
 ;;1.0;NETWORK SERVICES;;01-Apr-2015;Build 133
 ;=================================================================
 ; Connect action
 ; Data is returned to client as:
 ;   debug flag^authentication method^server version^case sensitive^cipher key
ACTC N X,Y,VOL,UCI,VER,AUTH,CAPS,CS,CK
 S Y=$$GETUCI,UCI(0)=Y,UCI=$$UP^XLFSTR($G(RGNETB("UCI"),Y)),VOL=$P(UCI,",",2),VER=$P($T(+2),";",3)
 S:'$L(UCI) UCI=Y
 S:'$L(VOL) VOL=$P(Y,",",2),$P(UCI,",",2)=VOL
 I UCI'=UCI(0),$$ERRCHK(0[$$UCICHECK^%ZOSV(UCI),14,UCI) Q
 Q:$$ERRCHK('$L(VOL),11)
 S AUTH=$$AUTHMETH(UCI),CS=$$GET^XPAR("SYS","XU VC CASE SENSITIVE"),CK=$E($P($T(Z+1^XUSRB1),";;",2,999),1,4)
 I '$G(RGNETB("LEGACY")) S CAPS=(RGMODE=3)_U_AUTH_U_VER_U_CS_U_CK
 E  S CAPS="1^"_AUTH_U_VER_U_CS_"^1^"
 Q:$$ERRCHK('$L(AUTH),24,UCI)
 I $D(^%ZOSF("ACTJ")) D  Q:$$ERRCHK(X'>Y&X,10,Y,X)
 .; Y=# active jobs, X=max active jobs
 .X ^%ZOSF("ACTJ")
 .S X=+$O(^XTV(8989.3,1,4,"B",VOL,0)),X=$S(X:+$P($G(^XTV(8989.3,1,4,X,0)),U,3),1:0)
 D INTRO^XUS1A("RGDATA"),MONSTART^RGNETBEV
 S RGDATA=CAPS
 Q
 ; Disconnect action
ACTD D RESET^RGNETBRP(),LOGOUT^XUSRB:$G(DUZ)
 S RGDATA=1,RGQUIT=1
 Q
 ; Query action
ACTQ Q:$$ASYCHK^RGNETBAS
 Q:$$EVTCHK^RGNETBEV
 ; Ping action
ACTP S DT=$$NOW^XLFDT,RGDATA=$$PARAM^RGNETBUT("RGNETB POLLING INTERVAL",1,60)_U_DT,DT=DT\1
 Q
 ; Subscribe action
ACTS S RGDATA=1
 Q:$$ERRCHK('$$SUBSCR^RGNETBEV(RGNETB("EVT"),1),13,RGNETB("EVT"))
 Q
 ; Unsubscribe action
ACTU S RGDATA=$$SUBSCR^RGNETBEV(RGNETB("EVT"),0)
 Q
 ; RPC action
ACTR N RPC,RTN,RGD,XWBWRAP,XWBPTYPE,I
 I '$D(RGNETB("CTX")) S RGNETB("CTX")=$$GETVAR^RGNETBUT("CTX")
 E  D SETVAR^RGNETBUT("CTX",RGNETB("CTX"))
 S:RGNETB("CTX")="" RGNETB("CTX")=$$GETVAR^RGNETBUT("AID")
 S RPC=$G(RGNETB("RPC"))
 I $G(RGNETB("LEGACY")),$E(RPC,1,5)="CIANB" S (RPC,RGNETB("RPC"))="RGNETB"_$E(RPC,6,7)_$E(RPC,9,999)
 S RPC=$$FIND1^DIC(8994,,"QX",RPC)
 Q:$$ERRCHK('RPC,3)
 S I=$G(^XWB(8994,RPC,0)),RTN=$P(I,U,2,3),XWBWRAP=+$P(I,U,8),XWBPTYPE=$P(I,U,4)
 Q:$$ERRCHK($S($E($P(RTN,U,2),1,6)="RGNETB":0,1:'$$CANRUN(RPC,RGNETB("CTX"))),4,RGNETB("RPC"),RGNETB("CTX"))
 Q:$$ERRCHK("03"'[$P(I,U,6),5)
 Q:$$ERRCHK(RTN'?.8AN1"^"1.8AN,6)
 Q:$$ERRCHK("^1^2^3^4^5^H^"'[(U_XWBPTYPE_U),6)
 Q:$$ERRCHK(ARG>40,7,,ARG,40)
 I $G(RGNETB("ASY")) D
 .N RD
 .S RD="RGNETB THREAD RESOURCE #"_$$GETVAR^RGNETBUT("RDEV")
 .S RGD=$$QUEUE^RGUTTSK("TASK^RGNETBAS","ASYNC RPC: "_RGNETB("RPC"),,"RTN^XWBWRAP^XWBPTYPE^ARG^ARG(^RGNETB(^XWBOS^P*",RD)
 .Q:$$ERRCHK(RGD<1,8)
 .S ^XTMP("RGNETB",RGNETB("UID"),"T",RGD)=""
 .D REPLY^RGNETBRK(RGD)
 E  D
 .S:XWBPTYPE=4 RGD=$$TMPGBL^RGNETBRP("X")
 .D STREST^RGNETTCP(1),DORPC,DATAOUT
 Q
 ; Builds the RPC entry code and executes it
DORPC N I,P,XWBAPVER,XQY,RGQUIT,ALOG,$ET
 S RTN=RTN_"(.RGD",XWBAPVER=$G(RGNETB("VER")),XQY=$$GETVAR^RGNETBUT("AID0")
 S ALOG=$$ISACTIVE^RGNETBLG,ALOG(0)=$S(ALOG:$$LOG^RGNETBLG(ALOG,1,RGNETB("RPC")),1:0)
 F I=1:1:ARG D
 .S RTN=RTN_","
 .Q:'$D(ARG(I))
 .S P="P"_I,RTN=RTN_"."_P
 .S:$D(@P)=10 @P=""
 .D:ALOG(0) ADD^RGNETBLG(ALOG,ALOG(0),P,1)
 S RTN=RTN_")"
 D
 .N ALOG
 .D @RTN
 I ALOG(0) D
 .N VAL,ARY
 .S VAL=$C(13)_"Return Data:"_$C(13)
 .D ADD^RGNETBLG(ALOG,ALOG(0),"VAL")
 .I XWBPTYPE=1 S VAL=$G(RGD),ARY="VAL"
 .E  I XWBPTYPE=2 S ARY="RGD"
 .E  I XWBPTYPE=3 S ARY="RGD"
 .E  I XWBPTYPE=4 S ARY=RGD
 .E  I XWBPTYPE=5 S VAL=$G(@RGD),ARY="VAL"
 .E  I XWBPTYPE="H" S VAL=RGD,ARY="VAL"
 .E  Q
 .D ADD^RGNETBLG(ALOG,ALOG(0),ARY)
 Q
 ; Test for error condition
 ; TEST = If true, setup the error
 ; ERR  = Error code
 ; Pn   = Optional parameters (up to 3)
ERRCHK(TEST,ERR,P1,P2,P3) ;
 I TEST,'$G(RGERR(0)) D
 .D GETDLG^RGNETBUT(ERR,.RGERR,.P1,.P2,.P3)
 .S RGERR(0)=ERR
 Q:$Q +$G(RGERR(0))
 Q
 ; Writes return data to TCP stream
DATAOUT D TCPWRITE^RGNETTCP($C(0))
 I XWBPTYPE=1 D TCPWRITE^RGNETTCP($G(RGD)) Q
 I XWBPTYPE=2 D ARYOUT^RGNETBRK("RGD",1,1) Q
 I XWBPTYPE=3 D ARYOUT^RGNETBRK("RGD",XWBWRAP,1) Q
 I XWBPTYPE=4 D ARYOUT^RGNETBRK(RGD,XWBWRAP,1) Q
 I XWBPTYPE=5 D TCPWRITE^RGNETTCP($G(@RGD)) Q
 I XWBPTYPE="H" D FILOUT^RGNETTCP(RGD,XWBWRAP) Q
 Q
 ; Returns true if RPC can run in current context
CANRUN(RPC,CTX) ;
 Q:'$G(DUZ)!'RPC 0
 S CTX(0)=$$OPTLKP^RGNETBUT(CTX)
 Q:$$ERRCHK('$L(CTX(0)),2,CTX) 0
 D:'$G(^XTMP("RGNETB",RGNETB("UID"),"C",CTX(0))) BLDCTX(CTX(0))
 Q:$$KCHK^XUSRB("XUPROGMODE") 1
 Q $D(^XTMP("RGNETB",RGNETB("UID"),"C",CTX(0),RPC))
 ; Build RPC context table
BLDCTX(OPT,CTX) ;
 N X
 I '$D(CTX) K ^XTMP("RGNETB",RGNETB("UID"),"C",OPT) S ^(OPT)=1,CTX=OPT
 Q:$D(^XTMP("RGNETB",RGNETB("UID"),"C",CTX,0,OPT))  S ^(OPT)=""
 Q:$$OPTCHK^RGNETBUT(OPT,"B")
 M ^XTMP("RGNETB",RGNETB("UID"),"C",CTX)=^DIC(19,OPT,"RPC","B")
 F X=0:0 S X=$O(^DIC(19,OPT,10,"B",X)) Q:'X  D BLDCTX(X,CTX)
 K:CTX=OPT ^XTMP("RGNETB",RGNETB("UID"),"C",CTX,0)
 Q
 ; Return current UCI
GETUCI() N Y
 D UCI^%ZOSV
 Q Y
 ; Change UCI
SETUCI(X) D SWAP^%XUCI
 Q
 ; Get authentication method for target UCI
AUTHMETH(UCI) ;
 N X,PC
 F PC=2,1 D  Q:$L(X)
 .S X=$$GET^XPAR("ALL","RGNETB AUTHENTICATION",$P(UCI,",",1,PC))
 Q X
