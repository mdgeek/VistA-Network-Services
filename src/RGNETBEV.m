RGNETBEV ;RI/CBMI/DKM - Event Support ;19-May-2015 09:09;DKM
 ;;1.0;NETWORK SERVICES;;01-Apr-2015
 ;=================================================================
 ; Check for the occurrence of host events
EVTCHK() ;EP
 N RTN,$ET,X
 S $ET="",X="ERR1^RGNETBEV",@^%ZOSF("TRAP")
 L +^XTMP("RGNETB",RGNETB("UID"),"E"):0
 E  Q 0
 S RTN=+$O(^XTMP("RGNETB",RGNETB("UID"),"E",0)),X=$NA(^(RTN))
 I RTN D
 .D TCPWRITE^RGNETTCP($C(3))
 .D ARYOUT^RGNETBRK(X,,1)
ERR1 L -^XTMP("RGNETB",RGNETB("UID"),"E")
 Q $G(RTN)
 ; Start monitor in background if not already running
MONSTART ;EP
 I '$$MONCHECK,$$QUEUE^RGUTTSK("MONITOR^RGNETBEV","NETSERV Broker Event Monitor")
 Q
 ; Returns true if event monitor is running
 ;   LOCK = If specified and true, do not release lock.
MONCHECK(LOCK) ;EP
 L +^XTMP("RGNETBEV MONITOR"):0
 E  Q 1
 L:'$G(LOCK) -^XTMP("RGNETBEV MONITOR")
 Q 0
 ; Taskman entry point for background event monitor
MONITOR ;EP
 N IEN,TYPE,EXE,IDLE,PMETH,X
 S ZTREQ="@",IDLE=360
 Q:$$MONCHECK(1)
 F  D  Q:IDLE<1!$$S^%ZTLOAD
 .H 5
 .F IEN=0:0 S IEN=$O(^RGNET(996.51,IEN)) Q:'IEN  D
 ..S X=$G(^(IEN,0)),TYPE=$P(X,U),PMETH=$P(X,U,6),EXE=$G(^(1))          ; Note: NR set above
 ..I $L(EXE),'$P(X,U,2),$$CHKINT(+$P(X,U,3)) D
 ...I PMETH D EXEMON Q
 ...N UID
 ...F  Q:'$$NXTUID^RGNETBUT(.UID)  D EXEUID(UID,TYPE)
 .S IDLE=$S($$NXTUID^RGNETBUT:360,1:IDLE-1)
 L -^XTMP("RGNETBEV MONITOR")
 Q
 ; Execute an event monitor in session context
EXEUID(UID,TYPE) ;EP
 Q:'$$ISSUBSCR(UID,TYPE)
 N RG,DUZ
 S RGNETB("UID")=UID,DUZ=$$EXEVAR("DUZ"),DUZ(0)=$$EXEVAR("DUZ0"),DUZ(2)=$$EXEVAR("DUZ2")
 D EXEMON
 Q
 ; Execute the event monitor
EXEMON N X,$ET
 S X="EXEERR^RGNETBEV",@^%ZOSF("TRAP"),$ET=""
 D EXERUN
 Q
EXERUN N IEN,IDLE
 X EXE
 Q
 ; Log any errors
EXEERR N ERT,ERD,X
 S ERT=$TR($$EC^%ZOSV,U,"~"),ERD=$$NOW^XLFDT
 S X=$G(^RGNET(996.51,IEN,100)),^(100)=ERD_U_ERT
 D:(ERD\1'=(X\1))!($P(X,U,2)'=ERT) ^%ZTER
 Q
EXEVAR(VAR) ;
 Q $$GETVAR^RGNETBUT(VAR,,,UID)
 ; Check nominal polling interval.  Return true if event needs to be polled.
CHKINT(INT) ;EP
 Q:'INT 1
 N NXT,NOW,CHK
 S NOW=$H,NOW=NOW*86400+$P(NOW,",",2)
 S NXT=$G(IEN(IEN),NOW),CHK=NOW'<NXT
 S:CHK IEN(IEN)=NOW+INT
 Q CHK
 ; RPC: Broadcast an event to some or all active users
BCAST(DATA,EVENT,STUB,LST,AID) ;
 S DATA=$$BRDCAST(.EVENT,.STUB,.LST,.AID)
 Q
 ; Called by event monitor to signal an event to client
SIGNAL(STUB) ;
 D QUEUE(TYPE,.STUB)
 Q
 ; Add an event to a process event queue
QUEUE(TYPE,STUB,UID,MON) ;EP
 N Q
 S:'$D(UID) UID=$G(RGNETB("UID"))
 I '$$ISSUBSCR(UID,TYPE) Q:$Q 0 Q
 L +^XTMP("RGNETB",UID,"E"):5
 E  Q:$Q 0 Q
 S Q=1+$O(^XTMP("RGNETB",UID,"E",$C(1)),-1),^(Q,0)=TYPE_$C(13) M ^(1)=STUB
 L -^XTMP("RGNETB",UID,"E")
 D:$G(MON,1) MONSTART
 Q:$Q 1
 Q
 ; Lookup event type, returning IEN
EVENTIEN(TYPE) ;EP
 N X,Y
 Q:TYPE=+TYPE!'$L(TYPE) +TYPE
 S X=$E(TYPE,1,30),Y=0
 F  S Y=+$O(^RGNET(996.51,"B",X,Y)) Q:'Y!($P($G(^RGNET(996.51,Y,0)),U)=TYPE)
 Q $S(Y:Y,1:$$EVENTIEN($P(TYPE,".",1,$L(TYPE,".")-1)))
 ; Return event name, given IEN
EVENTNAM(IEN) ;EP
 Q $P($G(^RGNET(996.51,+IEN,0)),U)
 ; Check to see if an event type is disabled
DISABLED(TYPE) ;EP
 N X,Y
 S X=$$EVENTIEN(TYPE),Y=$G(^RGNET(996.51,+X,0)),TYPE=$P(Y,U),Y=+$P(Y,U,2)
 S:'Y Y=$$KEYCHECK(X,20)
 Q $S(Y:Y,'X:0,1:$$DISABLED($P(TYPE,".",1,$L(TYPE,".")-1)))
 ; Check to see if event type is protected by security key(s)
 ; Returns true if user does not have required keys
 ;   SB=20: Publication keys; SB=21: Subscription keys
KEYCHECK(TYPE,SB) ;EP
 N X,Y,Z
 S X=$$EVENTIEN(TYPE),(Y,Z)=0
 F  S Z=$O(^RGNET(996.51,X,SB,"B",Z)) Q:'Z  D  Q:'Y
 .S Y='$$HASKEY(Z)
 Q Y
 ; Return true if user has key
HASKEY(KEY) ;EP
 S:KEY=+KEY KEY=$$LKUP^XPDKEY(KEY)
 Q $S($L(KEY):''$$KCHK^XUSRB(KEY),1:0)
 ; Signal an event to all or selected sessions
 ; If called as extrinsic, returns # of events broadcast
BRDCAST(TYPE,STUB,USR,AID) ;EP
 N X,C
 S C=0
 I '$$DISABLED(TYPE) D
 .I $D(USR("DUZ"))>1 D
 ..F  Q:'$$NXTUID^RGNETBUT(.X,-1,.AID)  D
 ...S:$D(USR("DUZ",+$$GETVAR^RGNETBUT("DUZ",,,X))) USR("UID",X)=""
 .S X=""
 .F  D  Q:'X
 ..I $D(USR)>1 S X=$O(USR("UID",X))
 ..E  D NXTUID^RGNETBUT(.X,-1,.AID)
 ..S:X C=C+$$QUEUE(.TYPE,.STUB,X,0)
 .D LOG(TYPE,.STUB)
 .D FPRTCOL(TYPE,.STUB)
 .D MONSTART
 Q:$Q C
 Q
 ; Fire Associated Event Protocol
FPRTCOL(TYPE,STUB) ;
 N EVT,X
 S EVT=$$EVENTIEN(TYPE)
 Q:'EVT
 S X=$P($G(^RGNET(996.51,+EVT,0)),U,7)_";ORD(101,"
 D:X EN^XQOR
 Q
 ; Subscribe to / unsubscribe from a named event
 ; Returns new subscription state
SUBSCR(TYPE,SUBSCR) ;EP
 I '$L(TYPE) Q:$Q 0 Q
 N CURRNT
 S CURRNT=''$D(^XTMP("RGNETB",RGNETB("UID"),"S",TYPE)),SUBSCR=''$G(SUBSCR)
 I CURRNT'=SUBSCR D
 .I SUBSCR D  Q:'SUBSCR
 ..I $$KEYCHECK(TYPE,21) S SUBSCR=0
 ..E  S ^XTMP("RGNETB",RGNETB("UID"),"S",TYPE)=""
 .E  D
 ..K ^XTMP("RGNETB",RGNETB("UID"),"S",TYPE)
 ..D CLRVAR^RGNETBUT("EVENT."_TYPE)
 .D BRDCAST($S(SUBSCR:"",1:"UN")_"SUBSCRIBE."_TYPE,$$SESSION^RGNETBUT)
 Q:$Q SUBSCR
 Q
 ; Unsubscribe from all events (done at logout)
UNSUBALL ;EP
 N TYPE
 S TYPE=""
 F  S TYPE=$O(^XTMP("RGNETB",RGNETB("UID"),"S",TYPE)) Q:'$L(TYPE)  D
 .D SUBSCR(TYPE,0)
 Q
 ; Returns true if session is a subscriber
ISSUBSCR(UID,TYPE) ;EP
 Q $S('$$ISACTIVE^RGNETBUT(UID):0,1:$$ISSUBX(TYPE))
ISSUBX(TYPE) ;
 Q $S('$L(TYPE):0,$D(^XTMP("RGNETB",UID,"S",TYPE)):1,1:$$ISSUBX($P(TYPE,".",1,$L(TYPE,".")-1)))
 ; Returns list of subscribers to a given event type
GETSUBSC(DATA,TYPE) ;EP
 N Z
 D GETSESSN^RGNETBRP(.DATA)
 F Z=0:0 S Z=$O(@DATA@(Z)) Q:'Z  K:'$$ISSUBSCR(+@DATA@(Z),TYPE) @DATA@(Z)
 Q
 ; Returns number of days to retain log entries for an event type.
ISLOGGED(TYPE) ;EP
 N X,Y
 S TYPE=$$EVENTIEN(TYPE)
 S:TYPE X=^RGNET(996.51,TYPE,0),Y=$P(X,U,4),X=$P(X,U)
 Q $S('TYPE:0,'$L(Y):$$ISLOGGED($P(X,".",$L(X,".")-1)),1:Y)
 ; Log an event
LOG(TYPE,STUB) ;EP
 N IEN,FDA,ERR,STB,X
 S IEN=$$ISACTIVE^RGNETBLG
 I IEN D
 .S X=$$LOG^RGNETBLG(IEN,2,TYPE)
 .D:X ADD^RGNETBLG(IEN,X,"STUB")
 Q:'$$ISLOGGED(TYPE)
 S FDA=$NA(FDA(996.511,"+1,")),STB="STUB",X=0
 F  D  Q:'$L(STB)
 .S:$D(@STB)#2 X=X+1,STB(X)=@STB
 .S STB=$Q(@STB)
 S @FDA@(.01)=$$NOW^XLFDT
 S @FDA@(1)=TYPE
 S @FDA@(2)=DUZ
 S @FDA@(3)=$$GETUID^RGNETBUT
 S:X @FDA@(10)="STB"
 D UPDATE^DIE("U","FDA",,"ERR")
 Q
 ; Purge event log.  Specify at least one of:
 ;   DATE = Date before which entries will be purged.
 ;   TYPE = Event type to be purged.
 ;   FLAG = If set, purges child events as well.
PURGELOG(DATE,TYPE,FLAG) ;EP
 N IEN,CNT
 S CNT=0,TYPE=$G(TYPE),FLAG=$S($G(FLAG):12,1:1)
 S:TYPE=+TYPE TYPE=$$EVENTNAM(TYPE)
 I $G(DATE) D
 .F  S DATE=$O(^RGNET(996.511,"B",DATE),-1),IEN=0 Q:'DATE  D
 ..F  S IEN=$O(^RGNET(996.511,"B",DATE,IEN)) Q:'IEN  D
 ...I $L(TYPE),FLAG'[$$RELATES(TYPE,$P(^RGNET(996.511,IEN,0),U,2)) Q
 ...S CNT=CNT+$$DELLOG(IEN)
 E  D
 .N TYP
 .S IEN=0,TYP=TYPE
 .F  Q:'$L(TYPE)  D
 ..F  S IEN=$O(^RGNET(996.511,"C",TYPE,IEN)) Q:'IEN  S CNT=CNT+$$DELLOG(IEN)
 ..S TYPE=$O(^RGNET(996.511,"C",TYPE))
 ..S:FLAG'[$$RELATES(TYP,TYPE) TYPE=""
 Q:$Q CNT
 Q
 ; Delete log entry corresponding to IEN
DELLOG(IEN) ;EP
 N FDA,ERR
 S FDA(996.511,IEN_",",.01)="@"
 D FILE^DIE(,"FDA","ERR")
 Q:$Q '$D(ERR)
 Q
 ; Task purge in background
TASKPRG ;EP
 N ZTSK
 S ZTSK=$$QUEUE^RGUTTSK("DOPURGE^RGNETBEV(1)","Purge RG EVENT LOG")
 I ZTSK>0 W !,"RG EVENT LOG purge submitted as task #",ZTSK,!!
 E  W !,"Error submitting RG EVENT LOG purge.",!!
 Q
 ; Purges event log according to retention settings
DOPURGE(SILENT) ;EP
 N IEN,TPNM,TPEN,DATE,CNT,TOT
 S TPNM="",SILENT=+$G(SILENT),TOT=0
 F  S TPNM=$O(^RGNET(996.511,"C",TPNM)) Q:'$L(TPNM)  D
 .S TPEN=$$EVENTIEN(TPNM),DATE=+$P($G(^RGNET(996.51,TPEN,0)),U,5)
 .S DATE=$$FMADD^XLFDT(DT,$S(DATE:1-DATE,1:-13))
 .S CNT=$$PURGELOG(DATE,TPNM),TOT=TOT+CNT
 .I CNT,'SILENT W $$SNGPLR^RGUT(CNT,"event")," purged for ",TPNM,!
 W:'SILENT !,"Total events purged: ",TOT,!!
 S:$D(ZTQUEUED) ZTREQ="@"
 Q
 ; Returns the relationship between event types
 ;   0 = none
 ;   1 = same
 ;   2 = A is parent of B
 ;   3 = B is parent of A
RELATES(EVA,EVB) ;EP
 N SWP,X
 S:EVA=+EVA EVA=$$EVENTNAM(EVA)
 S:EVB=+EVB EVB=$$EVENTNAM(EVB)
 S:$L(EVA)>$L(EVB) SWP=EVA,EVA=EVB,EVB=SWP
 Q:EVA=EVB 1
 F  D  Q:'$L(EVB)!(EVA=EVB)
 .S EVB=$P(EVB,".",1,$L(EVB,".")-1)
 Q $S(EVA'=EVB:0,$D(SWP):3,1:2)
