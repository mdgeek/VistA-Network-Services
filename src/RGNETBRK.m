RGNETBRK ;RI/CBMI/DKM - NETSERV RPC Broker ;08-Jun-2015 10:16;AA
 ;;1.0;NETWORK SERVICES;;01-Apr-2015;Build 133
 ;=================================================================
 ; Handler for broker I/O
NETSERV(RGNETB) ;
 S:$$DOACTION($S($D(RGNETB):"DPQRSU",1:"C")) RGRETRY=0
 Q
 ; Read action and params
 ;  VAC = List of valid action codes
 ; Returns true if valid inputs
DOACTION(VAC) ;
 N NM,SB,RT,VL,PR,ACT,SEQ,ARG,RGERR,RGDATA,X
 S RGERR(0)=0
 S X=$$TCPREAD^RGNETTCP(8,300)
 I '$L(X),RGMODE'=3 D ACTD^RGNETBAC Q 0
 S ARG=0,PR=$E(X,1,5),RGNETB("EOD")=$E(X,6),SEQ=$E(X,7),ACT=$E(X,8)
 I PR="{CIA}" S RGNETB("LEGACY")=1
 E  Q:PR'="{RGN}" 0
 F  S NM=$$TCPREADL Q:'$L(NM)  S PR=NM=+NM,RT=$S(PR:"P"_NM,1:"RGNETB("""_NM_"""") N:PR&'$D(ARG(NM)) @RT D
 .S:PR ARG=$S(NM>ARG:NM,1:ARG),ARG(NM)=""
 .S SB=$$TCPREADL,VL=$$TCPREADL
 .I $L(SB) S RT=RT_$S(PR:"(",1:",")_SB_")"
 .E  S:'PR RT=RT_")"
 .S @RT=VL
 D TCPWRITE^RGNETTCP(SEQ)
 I '$$ERRCHK^RGNETBAC(VAC'[ACT,9,ACT) D
 .N $ET,$ES
 .S $ET="D ETRAP2^RGNETBRK"
 .D @("ACT"_ACT_"^RGNETBAC")
 I RGERR(0) D
 .D SNDERR
 E  I $D(RGDATA) D
 .D REPLY(.RGDATA)
 E  D SNDEOD
 Q 1
 ; Read length-prefixed data from input stream
TCPREADL() ;
 N X,L,I,N
 S X=$$TCPREADB^RGNETTCP
 Q:$C(X)=RGNETB("EOD") ""
 S N=X#16,X=$$TCPREAD^RGNETTCP(X\16),L=0
 F I=1:1:$L(X) S L=L*256+$A(X,I)
 Q $$TCPREAD^RGNETTCP(L*16+N)
 ; Raise an exception
RAISE(MSG,P1,P2) ;
 D GETDLG^RGNETBUT(MSG,.MSG,.P1,.P2)
 S $EC=MSG(1)
 Q
 ; Trapped error, send error info to client
ETRAP2 N ECSAV
 S $ET="D UNWIND^RGNETBRK Q:$Q 0 Q",ECSAV=$$EC^%ZOSV,RGRETRY=RGRETRY+1
 D:RGRETRY=1 ^%ZTER,ERRCHK^RGNETBAC(1,1,ECSAV)
 S $EC=ECSAV
 Q
 ; Unwind stack
UNWIND Q:$ES>1
 S $EC=""
 Q
 ; Send a reply
REPLY(DATA,ACK) ;
 N MORE
 S MORE=$D(DATA)\10
 D TCPWRITE^RGNETTCP($C(+$G(ACK))_$G(DATA)_$S(MORE:$C(13),1:""))
 D:MORE ARYOUT("DATA",1,1)
 D SNDEOD
 K DATA
 Q
 ; Send error information
SNDERR N X
 D TCPWRITE^RGNETTCP($C(1))
 D ARYOUT("RGERR",1,1),SNDEOD
 S RGERR(0)=0
 Q
SNDEOD D TCPWRITE^RGNETTCP($$CTL("EOD"))
 Q
 ; Send data from an array.
 ;  ARY  = Array to send
 ;  EOL  = If true, append line terminator
 ;  KILL = If true, kill the array after sending
ARYOUT(ARY,EOL,KILL) ;
 D ARYOUT^RGNETTCP(ARY,$S($G(EOL):$C(13),1:""))
 K:$G(KILL) @ARY
 Q
 ; Return control byte
CTL(X) I $D(RGNETB(X)) N Y S Y=RGNETB(X) K RGNETB(X) Q Y
 Q ""
