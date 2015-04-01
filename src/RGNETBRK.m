RGNETBRK ;RI/CBMI/DKM - NETSERV RPC Broker ;01-Apr-2015 14:12;DKM
 ;;1.0;NETWORK SERVICES;;01-Apr-2015
 ;=================================================================
 ; Handler for broker I/O
NETSERV(RGNETB) ;
 S:$$DOACTION($S($D(RGNETB):"DPQRSU",1:"C")) RGRETRY=0
 Q
 ; Read action and params
 ;  VAC = List of valid action codes
 ; Returns true if valid inputs
DOACTION(VAC) ;
 N NM,SB,RT,VL,PR,RG,ACT,SEQ,ARG,RGERR,RGDATA,X
 S RGERR(0)=0
 D TCPUSE
 S X=$$TCPREAD^RGNETTCP(8,10)
 Q:$E(X,1,5)'="{CIA}" 0
 S ARG=0,RGNETB("EOD")=$E(X,6),SEQ=$E(X,7),ACT=$E(X,8)
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
 ; Write data to socket
TCPWRITE(DATA,EOD) ;
 D TCPWRITE^RGNETTCP($G(DATA)_$S($G(EOD):$$CTL("EOD"),1:""))
 Q
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
 ; Send a reply
REPLY(DATA,ACK) ;
 N MORE
 S MORE=$D(DATA)\10
 D TCPWRITE($C(+$G(ACK))_$G(DATA)_$S(MORE:$C(13),1:""),'MORE)
 D:MORE ARYOUT("DATA",1),SNDEOD
 K DATA
 Q
 ; Send error information
SNDERR N X
 D TCPWRITE^RGNETTCP($C(1))
 D ARYOUT("RGERR",1),SNDEOD
 S RGERR(0)=0
 Q
SNDEOD D TCPWRITE(,1)
 Q
 ; Return control byte
CTL(X) I $D(RGNETB(X)) N Y S Y=RGNETB(X) K RGNETB(X) Q Y
 Q ""
